// dashboard_viewmodel.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../data/departments.dart';
import '../logger/app_logger.dart';
import '../models/daily_tip_model.dart';
import '../models/question_access.dart';
import '../models/question_model.dart';
import '../models/slider_model.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';
import '../repositories/interfaces/point_transaction_repository.dart';
import '../repositories/interfaces/question_repository.dart';
import '../repositories/interfaces/slider_repository.dart';
import '../repositories/interfaces/subscription_repository.dart';
import '../repositories/interfaces/user_repository.dart';
import '../services/analytics_service.dart';
import '../services/connectivity_service.dart';
import 'base_viewmodel.dart';

// Import provider files
import '../providers/repository_providers.dart';
import '../providers/service_providers.dart';

class DashboardState {
  final bool isLoading;
  final String? errorMessage;
  final ViewModelState viewModelState;
  final UserModel? currentUser;
  final List<Question> recentQuestions;
  final List<Question> popularQuestions;
  final List<SliderItem> sliderItems;
  final List<Task> upcomingTasks;
  final DailyTip? dailyTip;
  final int currentSliderIndex;
  final int totalQuestions;
  final int totalCourses;
  final int totalDepartments;
  final int totalPointsEarned;
  final int totalPointsSpent;
  final bool hasActiveSubscription;

  const DashboardState({
    this.isLoading = false,
    this.errorMessage,
    this.viewModelState = ViewModelState.initial,
    this.currentUser,
    this.recentQuestions = const [],
    this.popularQuestions = const [],
    this.sliderItems = const [],
    this.upcomingTasks = const [],
    this.dailyTip,
    this.currentSliderIndex = 0,
    this.totalQuestions = 0,
    this.totalCourses = 0,
    this.totalDepartments = 0,
    this.totalPointsEarned = 0,
    this.totalPointsSpent = 0,
    this.hasActiveSubscription = false,
  });

  // User convenience getters
  int get currentBalance => currentUser?.points ?? 0;
  String get userName => currentUser?.name ?? 'Guest';
  String get userEmail => currentUser?.email ?? 'Email Address';
  String? get profilePictureUrl => currentUser?.profilePictureUrl;
  String? get userDepartmentId => currentUser?.department;
  int get userPoints => currentUser?.points ?? 0;
  int get userLevel => currentUser?.level ?? 1;
  double get levelProgress => currentUser?.levelProgress ?? 0.0;
  bool get isPremiumUser => currentUser?.isPremium ?? false;
  bool get isUserAuthenticated => currentUser != null;

  DashboardState copyWith({
    bool? isLoading,
    String? errorMessage,
    ViewModelState? viewModelState,
    UserModel? currentUser,
    List<Question>? recentQuestions,
    List<Question>? popularQuestions,
    List<SliderItem>? sliderItems,
    List<Task>? upcomingTasks,
    DailyTip? dailyTip,
    int? currentSliderIndex,
    int? totalQuestions,
    int? totalCourses,
    int? totalDepartments,
    int? totalPointsEarned,
    int? totalPointsSpent,
    bool? hasActiveSubscription,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      viewModelState: viewModelState ?? this.viewModelState,
      currentUser: currentUser ?? this.currentUser,
      recentQuestions: recentQuestions ?? this.recentQuestions,
      popularQuestions: popularQuestions ?? this.popularQuestions,
      sliderItems: sliderItems ?? this.sliderItems,
      upcomingTasks: upcomingTasks ?? this.upcomingTasks,
      dailyTip: dailyTip ?? this.dailyTip,
      currentSliderIndex: currentSliderIndex ?? this.currentSliderIndex,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      totalCourses: totalCourses ?? this.totalCourses,
      totalDepartments: totalDepartments ?? this.totalDepartments,
      totalPointsEarned: totalPointsEarned ?? this.totalPointsEarned,
      totalPointsSpent: totalPointsSpent ?? this.totalPointsSpent,
      hasActiveSubscription: hasActiveSubscription ?? this.hasActiveSubscription,
    );
  }
}

class DashboardViewModel extends BaseViewModel {
  final IQuestionRepository _questionRepository;
  final IUserRepository _userRepository;
  final IPointTransactionRepository _pointTransactionRepository;
  final ISubscriptionRepository _subscriptionRepository;
  final ISliderRepository _sliderRepository;
  final ConnectivityService _connectivityService;
  final AnalyticsService _analyticsService;

  DashboardState _state = const DashboardState();
  Timer? _searchDebounceTimer;

  DashboardState get state => _state;
  bool get hasNetworkConnection => _connectivityService.isConnected;
  bool get isOnline => _connectivityService.isConnected && _connectivityService.isInitialized;

  // Constructor now accepts Ref and uses it to get dependencies
  DashboardViewModel(Ref ref)
      : _questionRepository = ref.watch(questionRepositoryProvider),
        _userRepository = ref.watch(userRepositoryProvider),
        _pointTransactionRepository = ref.watch(pointTransactionRepositoryProvider),
        _subscriptionRepository = ref.watch(subscriptionRepositoryProvider),
        _sliderRepository = ref.watch(sliderRepositoryProvider),
        _connectivityService = ref.watch(connectivityServiceProvider),
        _analyticsService = ref.watch(analyticsServiceProvider) {
    debugPrint('DashboardViewModel: Constructor called');
    _initialize();
  }

  // FIXED: Improved initialization with better error handling
  Future<void> _initialize() async {
    final stopwatch = Stopwatch()..start();

    try {
      _setState(_state.copyWith(
        isLoading: true,
        viewModelState: ViewModelState.loading,
      ));

      await _analyticsService.trackScreenView('dashboard_screen');

      // Wait a bit for other services to initialize
      await Future.delayed(const Duration(milliseconds: 100));

      debugPrint('DashboardViewModel: Starting data loading...');

      // Load current user
      await _loadCurrentUser();

      if (_state.currentUser != null) {
        debugPrint('DashboardViewModel: User authenticated, loading full dashboard');
        await _loadDashboardData();
        _setupRealtimeListeners();
        await _updateUserLastLogin();

        await _analyticsService.trackEvent('dashboard_initialized_authenticated', parameters: {
          'user_id': _state.currentUser!.id,
          'department': _state.currentUser!.department,
        });
      } else {
        debugPrint('DashboardViewModel: No user, loading guest data');
        await _loadGuestData();
        await _analyticsService.trackEvent('dashboard_initialized_guest');
      }

      _setState(_state.copyWith(
        isLoading: false,
        viewModelState: ViewModelState.loaded,
      ));

      debugPrint('DashboardViewModel: Initialization completed successfully');
      _analyticsService.trackPerformance('dashboard_initialization', stopwatch.elapsedMilliseconds);
    } catch (error, stackTrace) {
      debugPrint('DashboardViewModel: Initialization error: $error');
      // FIXED: More graceful error handling - don't break the app
      _setState(_state.copyWith(
        isLoading: false,
        viewModelState: ViewModelState.loaded, // Still set to loaded even on error
        errorMessage: 'Failed to load dashboard data. Please pull to refresh.',
      ));
      _handleError('Dashboard initialization failed', error, stackTrace);
    }
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  // ============ DASHBOARD FUNCTIONALITY ============

  Future<void> loadDashboardData() async {
    _setState(_state.copyWith(isLoading: true, errorMessage: null));

    try {
      // REFACTORED: Check cache validity from the main repository
      final bool isCacheStale = !(await _questionRepository.isCacheValid());

      if (isCacheStale) {
        await _loadFreshData();
      } else {
        await _loadCachedData();
      }
    } catch (e) {
      _setState(_state.copyWith(
        errorMessage: "Failed to load dashboard data: ${e.toString()}",
      ));
    } finally {
      _setState(_state.copyWith(isLoading: false));
    }
  }

  Future<void> _loadFreshData() async {
    await Future.wait([
      _loadUserData(),
      _loadQuestionsData(),
      _loadPointsData(),
      _loadSubscriptionData(),
      _loadSliderItems(),
      _loadDashboardStats(),
      _loadDailyTip(),
      _loadUpcomingTasks(),
    ]);
  }

  Future<void> _loadCachedData() async {
    final users = await _userRepository.getAll();
    final currentUser = users.isNotEmpty ? users.first : null;

    final recentQuestions = await _questionRepository.getRecentQuestions(limit: 5);
    final popularQuestions = await _questionRepository.getPopularQuestions(limit: 5);
    final totalPointsEarned = await _pointTransactionRepository.getTotalPointsEarned();
    final totalPointsSpent = await _pointTransactionRepository.getTotalPointsSpent();
    final hasActiveSubscription = await _subscriptionRepository.hasActiveSubscription();
    final sliders = await _sliderRepository.getAll();
    final dailyTip = DailyTip(text: _getRandomDailyTip());

    _setState(_state.copyWith(
      currentUser: currentUser,
      recentQuestions: recentQuestions,
      popularQuestions: popularQuestions,
      totalPointsEarned: totalPointsEarned,
      totalPointsSpent: totalPointsSpent,
      hasActiveSubscription: hasActiveSubscription,
      sliderItems: sliders,
      dailyTip: dailyTip,
    ));
  }

  Future<void> refreshDashboard() async {
    await _loadFreshData();
  }

  Future<void> earnPointsFromAd() async {
    if (_state.currentUser == null) return;

    try {
      await _pointTransactionRepository.addEarnedPoints(
        points: 5,
        description: 'Watched advertisement',
        category: 'ad_watch',
      );

      final updatedUser = _state.currentUser!.copyWith(
        points: _state.currentUser!.points + 5,
        updatedAt: DateTime.now(),
        version: _state.currentUser!.version + 1,
      );
      await _userRepository.save(updatedUser);

      await _loadPointsData();
      _setState(_state.copyWith(currentUser: updatedUser));
    } catch (e) {
      _setState(_state.copyWith(
        errorMessage: "Failed to earn points: ${e.toString()}",
      ));
    }
  }

  // ============ DATA LOADING METHODS ============

  Future<void> _loadCurrentUser() async {
    try {
      debugPrint('Dashboard: Loading current user from repository...');
      final users = await _userRepository.getAll();
      debugPrint('Dashboard: Found ${users.length} users in repository');

      if (users.isNotEmpty) {
        _setState(_state.copyWith(currentUser: users.first));
        AppLogger.debug('Current user loaded: ${_state.currentUser!.name}', tag: 'DASHBOARD');
      } else {
        debugPrint('Dashboard: No users found in local storage');
      }
    } catch (error, stackTrace) {
      debugPrint('Dashboard: Error loading current user: $error');
      AppLogger.error('Error loading current user', tag: 'DASHBOARD', error: error, stackTrace: stackTrace);
    }
  }

  Future<void> _loadDashboardData() async {
    final tasks = <Future>[
      _loadUserData(),
      _loadQuestionsData(),
      _loadPointsData(),
      _loadSubscriptionData(),
      _loadSliderItems(),
      _loadDashboardStats(),
      _loadDailyTip(),
      _loadUpcomingTasks(),
    ];

    try {
      await Future.wait(tasks, eagerError: true);
      AppLogger.debug('Dashboard data loaded successfully', tag: 'DASHBOARD');
    } catch (error, stackTrace) {
      AppLogger.error('Error in dashboard data loading', tag: 'DASHBOARD', error: error, stackTrace: stackTrace);
    }
  }

  Future<void> _loadGuestData() async {
    final tasks = <Future>[
      _loadSliderItems(),
      _loadPublicQuestions(),
      _loadDailyTip(),
    ];

    try {
      await Future.wait(tasks, eagerError: true);
      AppLogger.debug('Guest data loaded successfully', tag: 'DASHBOARD');
    } catch (error, stackTrace) {
      AppLogger.error('Error loading guest data', tag: 'DASHBOARD', error: error, stackTrace: stackTrace);
    }
  }

  Future<void> _loadUserData() async {
    final users = await _userRepository.getAll();
    if (users.isNotEmpty) {
      _setState(_state.copyWith(currentUser: users.first));
    }
  }

  Future<void> _loadQuestionsData() async {
    try {
      List<Question> recentQuestions;
      List<Question> popularQuestions;

      if (_state.currentUser?.department != null) {
        final departmentName = getDepartmentNameById(_state.currentUser!.department!);
        final questions = await _questionRepository.getByDepartment(departmentName);
        recentQuestions = questions.take(5).toList();
      } else {
        recentQuestions = await _questionRepository.getRecentQuestions(limit: 5);
      }

      popularQuestions = await _questionRepository.getPopularQuestions(limit: 5);

      _setState(_state.copyWith(
        recentQuestions: recentQuestions,
        popularQuestions: popularQuestions,
      ));

      AppLogger.debug('Loaded ${recentQuestions.length} recent and ${popularQuestions.length} popular questions', tag: 'DASHBOARD');
    } catch (error, stackTrace) {
      AppLogger.error('Error loading questions data', tag: 'DASHBOARD', error: error, stackTrace: stackTrace);
      _setState(_state.copyWith(
        recentQuestions: const [],
        popularQuestions: const [],
      ));
    }
  }

  Future<void> _loadPublicQuestions() async {
    try {
      final questions = await _questionRepository.getRecentQuestions(limit: 5);
      _setState(_state.copyWith(recentQuestions: questions));
      AppLogger.debug('Loaded ${questions.length} public questions', tag: 'DASHBOARD');
    } catch (error, stackTrace) {
      AppLogger.error('Error loading public questions', tag: 'DASHBOARD', error: error, stackTrace: stackTrace);
      _setState(_state.copyWith(recentQuestions: const []));
    }
  }

  Future<void> _loadSliderItems() async {
    try {
      final sliders = await _sliderRepository.getAll();
      _setState(_state.copyWith(sliderItems: sliders));
      AppLogger.debug('Loaded ${sliders.length} slider items', tag: 'DASHBOARD');
    } catch (error, stackTrace) {
      AppLogger.error('Error loading slider items', tag: 'DASHBOARD', error: error, stackTrace: stackTrace);
      _setState(_state.copyWith(sliderItems: const []));
    }
  }

  Future<void> _loadDashboardStats() async {
    try {
      final allQuestions = await _questionRepository.getAll();
      final totalQuestions = allQuestions.length;

      final uniqueCourses = allQuestions.map((q) => q.courseCode).toSet();
      final totalCourses = uniqueCourses.length;

      final uniqueDepartments = allQuestions.map((q) => q.department).toSet();
      final totalDepartments = uniqueDepartments.length;

      _setState(_state.copyWith(
        totalQuestions: totalQuestions,
        totalCourses: totalCourses,
        totalDepartments: totalDepartments,
      ));

      AppLogger.debug('Dashboard stats loaded: $totalQuestions questions, $totalCourses courses, $totalDepartments departments', tag: 'DASHBOARD');
    } catch (error, stackTrace) {
      AppLogger.error('Error loading dashboard stats', tag: 'DASHBOARD', error: error, stackTrace: stackTrace);
      _setState(_state.copyWith(
        totalQuestions: 0,
        totalCourses: 0,
        totalDepartments: 0,
      ));
    }
  }

  Future<void> _loadPointsData() async {
    try {
      final totalPointsEarned = await _pointTransactionRepository.getTotalPointsEarned();
      final totalPointsSpent = await _pointTransactionRepository.getTotalPointsSpent();
      _setState(_state.copyWith(
        totalPointsEarned: totalPointsEarned,
        totalPointsSpent: totalPointsSpent,
      ));
    } catch (error, stackTrace) {
      AppLogger.error('Error loading points data', tag: 'DASHBOARD', error: error, stackTrace: stackTrace);
    }
  }

  Future<void> _loadSubscriptionData() async {
    try {
      final hasActiveSubscription = await _subscriptionRepository.hasActiveSubscription();
      _setState(_state.copyWith(hasActiveSubscription: hasActiveSubscription));
    } catch (error, stackTrace) {
      AppLogger.error('Error loading subscription data', tag: 'DASHBOARD', error: error, stackTrace: stackTrace);
    }
  }

  Future<void> _loadDailyTip() async {
    try {
      final dailyTip = DailyTip(text: _getRandomDailyTip());
      _setState(_state.copyWith(dailyTip: dailyTip));
      AppLogger.debug('Daily tip loaded', tag: 'DASHBOARD');
    } catch (error, stackTrace) {
      AppLogger.error('Error loading daily tip', tag: 'DASHBOARD', error: error, stackTrace: stackTrace);
      _setState(_state.copyWith(dailyTip: DailyTip(text: 'Stay focused and keep learning!')));
    }
  }

  Future<void> _loadUpcomingTasks() async {
    try {
      // Implement actual task loading logic
      _setState(_state.copyWith(upcomingTasks: const []));
      AppLogger.debug('Upcoming tasks loaded', tag: 'DASHBOARD');
    } catch (error, stackTrace) {
      AppLogger.error('Error loading upcoming tasks', tag: 'DASHBOARD', error: error, stackTrace: stackTrace);
      _setState(_state.copyWith(upcomingTasks: const []));
    }
  }

  Future<void> _updateUserLastLogin() async {
    if (_state.currentUser != null) {
      try {
        await _userRepository.updateLastLogin(_state.currentUser!.id);
        AppLogger.debug('User last login updated', tag: 'DASHBOARD');
      } catch (error, stackTrace) {
        AppLogger.error('Error updating last login', tag: 'DASHBOARD', error: error, stackTrace: stackTrace);
      }
    }
  }

  // ============ REAL-TIME LISTENERS ============

  void _setupRealtimeListeners() {
    // Listen for question updates
    addSubscription(
      _questionRepository.watchAll().listen((questions) {
        List<Question> recentQuestions;
        if (_state.currentUser?.department != null) {
          final departmentName = getDepartmentNameById(_state.currentUser!.department!);
          recentQuestions = questions
              .where((q) => q.department == departmentName)
              .take(5)
              .toList();
        } else {
          recentQuestions = questions.take(5).toList();
        }
        _setState(_state.copyWith(recentQuestions: recentQuestions));
      }, onError: (error, stackTrace) {
        AppLogger.error('Question stream error', tag: 'DASHBOARD', error: error, stackTrace: stackTrace);
      }),
    );

    // Listen for slider updates
    addSubscription(
      _sliderRepository.watchAll().listen((sliders) {
        _setState(_state.copyWith(sliderItems: sliders));
      }, onError: (error, stackTrace) {
        AppLogger.error('Slider stream error', tag: 'DASHBOARD', error: error, stackTrace: stackTrace);
      }),
    );

    // Listen for user updates
    addSubscription(
      _userRepository.watchAll().listen((users) {
        if (users.isNotEmpty) {
          final previousUser = _state.currentUser;
          _setState(_state.copyWith(currentUser: users.first));

          if (previousUser?.department != _state.currentUser?.department) {
            _loadQuestionsData();
          }
        }
      }, onError: (error, stackTrace) {
        AppLogger.error('User stream error', tag: 'DASHBOARD', error: error, stackTrace: stackTrace);
      }),
    );

    // Listen for connectivity changes
    addSubscription(
      _connectivityService.connectionStream.listen((isConnected) {
        if (isConnected && _connectivityService.isInitialized) {
          _performSilentRefresh();
        }
        notifyListeners();
      }, onError: (error, stackTrace) {
        AppLogger.error('Connectivity stream error', tag: 'DASHBOARD', error: error, stackTrace: stackTrace);
      }),
    );
  }

  // ============ REFRESH & SYNC ============

  Future<void> refreshData({bool showLoading = true}) async {
    if (_state.viewModelState == ViewModelState.refreshing) return;

    final stopwatch = Stopwatch()..start();

    try {
      if (showLoading) {
        _setState(_state.copyWith(viewModelState: ViewModelState.refreshing));
      }

      await _analyticsService.trackEvent('dashboard_refresh_triggered');

      await Future.wait([
        _questionRepository.syncWithRemote(),
        _sliderRepository.syncWithRemote(),
        _userRepository.syncWithRemote(),
        if (_state.currentUser != null) _subscriptionRepository.syncWithRemote(),
      ], eagerError: true);

      await _loadDashboardData();
      _setState(_state.copyWith(viewModelState: ViewModelState.loaded));

      await _analyticsService.trackEvent('dashboard_refresh_completed', parameters: {
        'duration_ms': stopwatch.elapsedMilliseconds,
      });
    } catch (error, stackTrace) {
      _handleError('Dashboard refresh failed', error, stackTrace);
      await _analyticsService.trackError('dashboard_refresh_failed', error: error, stackTrace: stackTrace);
    }
  }

  Future<void> _performSilentRefresh() async {
    try {
      AppLogger.debug('Performing silent refresh', tag: 'DASHBOARD');

      await Future.wait([
        _questionRepository.syncWithRemote(),
        _sliderRepository.syncWithRemote(),
        if (_state.currentUser != null) _userRepository.syncWithRemote(),
      ], eagerError: false);

      await _loadDashboardData();

      AppLogger.debug('Silent refresh completed', tag: 'DASHBOARD');
    } catch (error, stackTrace) {
      AppLogger.error('Silent refresh failed', tag: 'DASHBOARD', error: error, stackTrace: stackTrace);
    }
  }

  // ============ USER MANAGEMENT ============

  Future<void> updateUserProfile({
    required String name,
    String? phone,
    String? profilePictureUrl,
    String? department,
  }) async {
    if (_state.currentUser != null) {
      try {
        final previousDepartment = _state.currentUser!.department;
        final updatedUser = _state.currentUser!.copyWith(
          name: name,
          phone: phone,
          profilePictureUrl: profilePictureUrl,
          department: department,
        );

        await _userRepository.save(updatedUser);
        _setState(_state.copyWith(currentUser: updatedUser));

        if (department != null && department != previousDepartment) {
          await _loadQuestionsData();
          await _loadDashboardStats();
        }

        await _analyticsService.trackEvent('profile_updated', parameters: {
          'field_updated': 'profile',
          'department_changed': department != previousDepartment,
        });
      } catch (error, stackTrace) {
        _handleError('Profile update failed', error, stackTrace);
      }
    }
  }

  Future<void> addUserPoints(int points) async {
    if (_state.currentUser != null && points > 0) {
      try {
        await _userRepository.addPoints(_state.currentUser!.id, points);
        await _analyticsService.trackEvent('points_added', parameters: {
          'points': points,
          'new_balance': _state.currentUser!.points + points,
        });
      } catch (error, stackTrace) {
        AppLogger.error('Error adding user points', tag: 'DASHBOARD', error: error, stackTrace: stackTrace);
      }
    }
  }

  Future<void> recordQuestionAccess(String questionId) async {
    if (_state.currentUser != null) {
      try {
        await _userRepository.addAccessedQuestion(_state.currentUser!.id, questionId);
        await _questionRepository.incrementViewCount(questionId);
        await addUserPoints(1);

        await _analyticsService.trackEvent('question_accessed', parameters: {
          'question_id': questionId,
        });
      } catch (error, stackTrace) {
        AppLogger.error('Error recording question access', tag: 'DASHBOARD', error: error, stackTrace: stackTrace);
      }
    }
  }

  Future<void> recordQuestionDownload(String questionId) async {
    if (_state.currentUser != null) {
      try {
        await _questionRepository.incrementDownloadCount(questionId);
        await addUserPoints(2);

        await _analyticsService.trackEvent('question_downloaded', parameters: {
          'question_id': questionId,
        });
      } catch (error, stackTrace) {
        AppLogger.error('Error recording question download', tag: 'DASHBOARD', error: error, stackTrace: stackTrace);
      }
    }
  }

  Future<void> recordAdWatched() async {
    if (_state.currentUser != null) {
      try {
        await _userRepository.incrementAdsWatched(_state.currentUser!.id);
        await _analyticsService.trackEvent('ad_watched');
      } catch (error, stackTrace) {
        AppLogger.error('Error recording ad watch', tag: 'DASHBOARD', error: error, stackTrace: stackTrace);
      }
    }
  }

  Future<void> updateUserDepartment(String departmentId) async {
    try {
      if (_state.currentUser != null) {
        final updatedUser = _state.currentUser!.copyWith(department: departmentId);
        await _userRepository.save(updatedUser);
        _setState(_state.copyWith(currentUser: updatedUser));

        await _loadQuestionsData();
        await _loadDashboardStats();

        await _analyticsService.trackEvent('department_updated', parameters: {
          'department_id': departmentId,
        });
      }
    } catch (error, stackTrace) {
      _handleError('Failed to update department', error, stackTrace);
    }
  }

  // ============ UI INTERACTIONS ============

  void updateSliderIndex(int index) {
    if (_state.currentSliderIndex != index && index >= 0 && index < _state.sliderItems.length) {
      _setState(_state.copyWith(currentSliderIndex: index));
    }
  }

  void navigateToQuestion(Question question) {
    recordQuestionAccess(question.id);
    _analyticsService.trackEvent('question_navigated', parameters: {
      'question_id': question.id,
      'course': question.courseName,
    });
  }

  // Search with debouncing
  void searchQuestions(String query) {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query);
    });
    addTimer(_searchDebounceTimer!);
  }

  void _performSearch(String query) {
    _analyticsService.trackUserEngagement('search', target: 'questions', value: query.length);
  }

  // ============ UTILITY METHODS ============

  bool canAccessQuestion(Question question) {
    if (_state.currentUser == null) {
      return question.access == QuestionAccess.free;
    }
    return question.canAccess(_state.currentUser!);
  }

  String getDepartmentDisplayName(String? departmentId) {
    if (departmentId == null) return 'Not Set';
    return getDepartmentNameById(departmentId);
  }

  void retry() {
    clearError();
    _initialize();
  }

  void clearError() {
    _setState(_state.copyWith(errorMessage: null));
    if (_state.viewModelState == ViewModelState.error) {
      _setState(_state.copyWith(viewModelState: ViewModelState.loaded));
    }
  }

  // ============ PRIVATE METHODS ============

  void _setState(DashboardState newState) {
    if (_state != newState) {
      _state = newState;
      notifyListeners();
    }
  }

  void _handleError(String message, dynamic error, StackTrace stackTrace) {
    _setState(_state.copyWith(
      errorMessage: message,
      viewModelState: ViewModelState.error,
    ));

    AppLogger.error(message, tag: 'DASHBOARD', error: error, stackTrace: stackTrace);
    _analyticsService.trackError('dashboard_viewmodel_error', error: error, stackTrace: stackTrace, context: message);
  }

  String _getRandomDailyTip() {
    final tips = [
      'Consistent practice beats occasional cramming!',
      'Take breaks to maintain focus and productivity.',
      'Teaching others is a great way to reinforce your own learning.',
      'Set specific goals for each study session.',
      'Review previous material regularly to strengthen memory.',
      'Stay hydrated and take care of your physical health for better mental performance.',
    ];
    return tips[DateTime.now().millisecondsSinceEpoch % tips.length];
  }

  bool get isLoading => _state.isLoading;
  String? get errorMessage => _state.errorMessage;
  ViewModelState get viewModelState => _state.viewModelState;
}