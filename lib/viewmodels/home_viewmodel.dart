import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:diuquestionbank/data/departments.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/daily_tip_model.dart';
import '../models/question_model.dart' as app_question;
import '../models/slider_model.dart';
import '../models/task_model.dart';

/// Manages the state for the HomeScreen.
///
/// This ViewModel follows a "cache-first" strategy. It first loads data from
/// the local Hive database to quickly display content on the UI. Then, it fetches
/// the latest data from Firebase and updates the Hive cache, which in turn
/// updates the UI via listeners.
class HomeViewModel extends ChangeNotifier {
  // --- Dependencies ---
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  // --- Hive Boxes ---
  late Box<app_question.Question> _questionsBox;
  late Box<DailyTip> _dailyTipBox;
  late Box<SliderItem> _sliderItemsBox;
  late Box<Task> _tasksBox;

  // --- Stream Subscriptions ---
  StreamSubscription? _sliderSubscription;
  StreamSubscription? _questionsSubscription;
  StreamSubscription? _tasksSubscription;
  StreamSubscription? _userSubscription; // For real-time user data

  // --- State Management ---
  bool _isInitializing = true;
  bool _isRefreshing = false;
  String? _errorMessage;

  // --- User Data ---
  String _userName = 'Guest';
  String _userEmail = 'Email Address';
  String? _profilePictureUrl;
  String? _userDepartmentId;
  String? _userPhone;
  int _userPoints = 0;
  int _userLevel = 1;
  double _levelProgress = 0.0;

  // --- UI State ---
  List<app_question.Question> _recentQuestions = [];
  DailyTip? _dailyTip;
  List<SliderItem> _sliderItems = [];
  List<Task> _upcomingTasks = [];
  int _currentSliderIndex = 0;

  // --- Dashboard Stats ---
  int _totalQuestions = 0;
  int _totalCourses = 0;
  int _totalDepartments = 0;

  // --- Public Getters ---
  bool get isInitializing => _isInitializing;
  bool get isRefreshing => _isRefreshing;
  String? get errorMessage => _errorMessage;
  String get userName => _userName;
  String get userEmail => _userEmail;
  String? get profilePictureUrl => _profilePictureUrl;
  String? get userDepartmentId => _userDepartmentId;
  String? get userPhone => _userPhone;
  int get userPoints => _userPoints;
  int get userLevel => _userLevel;
  double get levelProgress => _levelProgress;
  List<app_question.Question> get recentQuestions => _recentQuestions;
  DailyTip? get dailyTip => _dailyTip;
  List<SliderItem> get sliderItems => _sliderItems;
  List<Task> get upcomingTasks => _upcomingTasks;
  int get currentSliderIndex => _currentSliderIndex;

  // --- Dashboard Stats Getters ---
  int get totalQuestions => _totalQuestions;
  int get totalCourses => _totalCourses;
  int get totalDepartments => _totalDepartments;

  HomeViewModel() {
    init();
  }

  /// Initializes the ViewModel with an optimized loading strategy.
  Future<void> init() async {
    _isInitializing = true;
    notifyListeners();

    try {
      await _openHiveBoxes();
      final user = _auth.currentUser;
      if (user != null) {
        // Fetch user data first, as it's needed for other fetches.
        await _fetchUserData(user.uid);

        // Fetch all other remote data in parallel.
        await Future.wait([
          _fetchRecentQuestions(),
          _fetchDailyTip(),
          _fetchSliderItems(),
          _fetchDashboardStats(),
        ]);

        // Load all data from the now-updated cache once.
        _loadDataFromCache();
        _setupListeners(); // Set up listeners after initial load.
      } else {
        _errorMessage = "User not authenticated.";
      }
    } catch (e, st) {
      debugPrint('HomeViewModel Init Error: $e\n$st');
      _errorMessage = 'An error occurred during initialization.';
      // Attempt to load from cache even if network fetch fails.
      _loadDataFromCache();
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  /// Handles the pull-to-refresh action.
  Future<void> refreshData() async {
    if (_isRefreshing) return;

    _isRefreshing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.wait([
        _fetchRecentQuestions(force: true),
        _fetchDailyTip(force: true),
        _fetchSliderItems(force: true),
        _fetchDashboardStats(), // Also refresh stats
      ]);
    } catch (e, st) {
      debugPrint('Refresh Error: $e\n$st');
      _errorMessage = "Failed to refresh data.";
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  /// Opens all necessary Hive boxes.
  Future<void> _openHiveBoxes() async {
    _questionsBox = await _openBox<app_question.Question>('questions');
    _dailyTipBox = await _openBox<DailyTip>('daily_tips');
    _sliderItemsBox = await _openBox<SliderItem>('slider_items');
    _tasksBox = await _openBox<Task>('tasks');
  }

  Future<Box<T>> _openBox<T>(String name) async {
    return Hive.isBoxOpen(name) ? Hive.box<T>(name) : await Hive.openBox<T>(name);
  }

  /// Loads all data from the Hive cache into the ViewModel's state.
  void _loadDataFromCache() {
    final departmentName = getDepartmentNameById(_userDepartmentId);

    final cachedQuestions = _questionsBox.values
        .where((q) => q.department == departmentName)
        .toList();
    cachedQuestions.sort((a, b) => b.processedAt.compareTo(a.processedAt));
    _recentQuestions = cachedQuestions.take(5).toList();

    _dailyTip = _dailyTipBox.get('current_tip');

    final cachedSliders = _sliderItemsBox.values.toList();
    cachedSliders.sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
    _sliderItems = cachedSliders;

    final allTasks = _tasksBox.values.toList();
    _upcomingTasks = allTasks
        .where((task) => !task.isCompleted && task.dueDate.isAfter(DateTime.now()))
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    _upcomingTasks = _upcomingTasks.take(3).toList();

    notifyListeners();
  }

  /// Sets up all real-time data listeners.
  void _setupListeners() {
    _listenToUser();
    _listenToQuestions();
    _listenToSliders();
    _listenToTasks();
  }

  /// Listens for real-time updates to the user document.
  void _listenToUser() {
    final user = _auth.currentUser;
    if (user == null) return;
    _userSubscription?.cancel();
    _userSubscription = _firestore.collection('users').doc(user.uid).snapshots().listen((doc) {
      if (doc.exists) {
        _parseUserData(doc.data()!);
        notifyListeners();
      }
    }, onError: (e) => debugPrint("User listener error: $e"));
  }

  /// Listens for real-time updates to questions in Firestore.
  void _listenToQuestions() {
    if (_userDepartmentId == null) return;
    _questionsSubscription?.cancel();

    final departmentName = getDepartmentNameById(_userDepartmentId);

    _questionsSubscription = _firestore
        .collection('question-info')
        .where('department', isEqualTo: departmentName)
        .orderBy('processedAt', descending: true)
        .limit(10)
        .snapshots()
        .listen((snapshot) async {
      final Map<String, app_question.Question> questionsMap = {
        for (var doc in snapshot.docs) doc.id: app_question.Question.fromFirestore(doc)
      };
      await _questionsBox.putAll(questionsMap);
      _loadDataFromCache();
    }, onError: (e) => debugPrint("Question listener error: $e"));
  }

  /// Listens for real-time updates to sliders in Firestore.
  void _listenToSliders() {
    _sliderSubscription?.cancel();
    _sliderSubscription = _firestore
        .collection('slider_images')
        .orderBy('order')
        .snapshots()
        .listen((snapshot) async {
      final Map<String, SliderItem> slidersMap = {
        for (var doc in snapshot.docs) doc.id: SliderItem.fromFirestore(doc)
      };
      await _sliderItemsBox.putAll(slidersMap);
      _loadDataFromCache();
    }, onError: (e) => debugPrint("Slider listener error: $e"));
  }

  /// Listens for local changes to the tasks Hive box.
  void _listenToTasks() {
    _tasksSubscription?.cancel();
    _tasksSubscription = _tasksBox.watch().listen((_) {
      _loadDataFromCache();
    });
  }

  /// Fetches aggregate data for the dashboard overview.
  Future<void> _fetchDashboardStats() async {
    try {
      final querySnapshot = await _firestore.collection('stats').limit(1).get();

      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data();
        _totalQuestions = (data['totalQuestions'] ?? 0) as int;
        _totalCourses = (data['totalCourses'] ?? 0) as int;
        _totalDepartments = (data['totalDepartments'] ?? 0) as int;
      } else {
        _totalQuestions = 0;
        _totalCourses = 0;
        _totalDepartments = 0;
        debugPrint("No stats document found in Firestore.");
      }
    } catch (e, st) {
      debugPrint('Failed to fetch dashboard stats: $e\n$st');
      _totalQuestions = 0;
      _totalCourses = 0;
      _totalDepartments = 0;
    }
    // No notifyListeners() here, will be called by the calling method.
  }


  /// Fetches the latest questions from Firestore.
  Future<void> _fetchRecentQuestions({bool force = false}) async {
    if (!force && _questionsBox.values.where((q) => q.department == getDepartmentNameById(_userDepartmentId)).isNotEmpty) return;
    if (_userDepartmentId == null) return;

    final departmentName = getDepartmentNameById(_userDepartmentId);

    final querySnapshot = await _firestore
        .collection('question-info')
        .where('department', isEqualTo: departmentName)
        .orderBy('processedAt', descending: true)
        .limit(10)
        .get();

    final Map<String, app_question.Question> questionsMap = {
      for (var doc in querySnapshot.docs) doc.id: app_question.Question.fromFirestore(doc)
    };
    await _questionsBox.putAll(questionsMap);
  }

  /// Fetches the latest slider items from Firestore.
  Future<void> _fetchSliderItems({bool force = false}) async {
    if (!force && _sliderItemsBox.isNotEmpty) return;
    final querySnapshot = await _firestore.collection('slider_images').orderBy('order').get();
    final Map<String, SliderItem> slidersMap = {
      for (var doc in querySnapshot.docs) doc.id: SliderItem.fromFirestore(doc)
    };
    await _sliderItemsBox.putAll(slidersMap);
  }

  /// Fetches the daily tip from the Realtime Database.
  Future<void> _fetchDailyTip({bool force = false}) async {
    if (!force && _dailyTipBox.isNotEmpty) return;
    final snapshot = await _database.ref('daily_tip').get();
    if (snapshot.exists && snapshot.value is Map) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final tip = DailyTip.fromRealtimeDatabase(data);
      await _dailyTipBox.put('current_tip', tip);
    }
  }

  /// Fetches the current user's data from Firestore.
  Future<void> _fetchUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _parseUserData(doc.data()!);
      }
    } catch (e) {
      debugPrint('User data fetch error: $e');
      _errorMessage = "Failed to load user profile.";
    }
  }

  /// Parses user data from a map and updates the state.
  void _parseUserData(Map<String, dynamic> data) {
    _userName = data['name'] ?? 'User';
    _userEmail = data['email'] ?? 'Email Address';
    _profilePictureUrl = data['profilePictureUrl'] ?? data['profilePicture'];
    _userDepartmentId = data['departmentId'] ?? data['department'];
    _userPhone = data['phone'] ?? data['phoneNumber'];
    _userPoints = (data['points'] ?? 0).toInt();
    _userLevel = (data['level'] ?? 1).toInt();
    _levelProgress = (data['levelProgress'] ?? 0.0).toDouble();
  }

  /// Updates local state without writing to the database.
  void updateLocalUserData({
    String? name,
    String? phone,
    String? profilePictureUrl,
  }) {
    if (name != null) _userName = name;
    if (phone != null) _userPhone = phone;
    if (profilePictureUrl != null) {
      _profilePictureUrl = profilePictureUrl.isEmpty ? null : profilePictureUrl;
    }
    notifyListeners();
  }

  /// Updates the user's department in Firestore and refreshes all data.
  Future<void> updateUserDepartment(String departmentId) async {
    final user = _auth.currentUser;
    if (user == null) {
      _errorMessage = "Authentication error.";
      notifyListeners();
      return;
    }
    try {
      await _firestore.collection('users').doc(user.uid).set(
        {'departmentId': departmentId},
        SetOptions(merge: true),
      );
      // The snapshot listener will automatically handle the local update.
      // We trigger a full refresh to get department-specific content.
      await refreshData();
    } catch (e) {
      _errorMessage = "Failed to update department.";
      notifyListeners();
      rethrow;
    }
  }

  void updateSliderIndex(int index) {
    if (_currentSliderIndex != index) {
      _currentSliderIndex = index;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sliderSubscription?.cancel();
    _questionsSubscription?.cancel();
    _tasksSubscription?.cancel();
    _userSubscription?.cancel();
    super.dispose();
  }
}
