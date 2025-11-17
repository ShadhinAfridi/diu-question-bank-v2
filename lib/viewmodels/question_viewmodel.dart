import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart';
import '../models/question_model.dart';
import '../models/question_filter.dart';
import '../models/course_model.dart';
import '../models/department_model.dart';
import '../models/base_model.dart';
import '../models/question_access.dart';
import '../models/question_status.dart';
import '../data/departments.dart';
import '../providers/cache_providers.dart';
import '../providers/view_model_providers.dart';
import '../repositories/interfaces/question_repository.dart';
import '../repositories/interfaces/point_transaction_repository.dart';
import 'base_viewmodel.dart';
import '../providers/repository_providers.dart';


class QuestionViewModel extends BaseViewModel {
  // Dependencies
  final IQuestionRepository _questionRepository;
  final IPointTransactionRepository _pointTransactionRepository;
  // final CacheManager _cacheManager; // REFACTORED: Removed CacheManager
  final Box _formCacheBox;
  final String? _userDepartmentId;
  final String _uploaderId; // Store uploaderId

  // ... (state management, data storage, etc. remain the same) ...
  bool _isLoading = false;
  bool _isSearching = false;
  bool _isUploading = false;
  bool _isCoursesLoading = false;
  String? _errorMessage;
  List<Question> _allQuestions = []; // REFACTORED: This might be redundant now
  List<Question> _filteredQuestions = []; // This is the list the UI should watch
  List<Question> _cachedQuestions = []; // This is the main source of truth from repo
  List<Question> _searchResults = [];
  List<Department> _departments = [];
  List<Course> _courses = [];
  String _searchQuery = '';
  String _lastQuery = '';
  QuestionFilter? _currentFilter;
  String? _currentExamTypeFilter;
  Department? _selectedDepartment;
  Course? _selectedCourse;
  String? _selectedExamType;
  int _selectedYear = DateTime.now().year;
  String _selectedSemester = 'Spring';
  final TextEditingController teacherNameController = TextEditingController();
  List<File> _selectedImages = [];
  File? _selectedPdf;
  String? _lastUploadError;
  bool _uploadSuccess = false;
  // static const String cachedQuestionsKey = 'cached_questions'; // REFACTORED: Unused
  // REFACTORED: Unused
  // String get _departmentQuestionsKey => 'questions_${getDepartmentNameById(_userDepartmentId)}';
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  bool get isUploading => _isUploading;
  bool get isCoursesLoading => _isCoursesLoading;
  String? get errorMessage => _errorMessage;
  // REFACTORED: Point to the filtered list
  List<Question> get filteredQuestions => _filteredQuestions;
  List<Question> get cachedQuestions => _cachedQuestions; // Main source
  List<Question> get allQuestions => _cachedQuestions; // Point to cache
  List<Question> get searchResults => _searchResults;
  QuestionFilter? get currentFilter => _currentFilter;
  String? get currentExamTypeFilter => _currentExamTypeFilter;
  List<Department> get departments => _departments;
  Department? get selectedDepartment => _selectedDepartment;
  List<Course> get courses => _courses;
  Course? get selectedCourse => _selectedCourse;
  String? get selectedExamType => _selectedExamType;
  int get selectedYear => _selectedYear;
  String get selectedSemester => _selectedSemester;
  List<String> get examTypes => ['Midterm', 'Final'];
  List<int> get yearList => List<int>.generate(10, (i) => DateTime.now().year - i);
  List<String> get semesterList => ['Spring', 'Summer', 'Fall'];
  List<File> get selectedImages => _selectedImages;
  File? get selectedPdf => _selectedPdf;
  String? get lastUploadError => _lastUploadError;
  bool get uploadSuccess => _uploadSuccess;
  String get lastQuery => _lastQuery;

  // Constructor now accepts Ref and uses it to get dependencies
  QuestionViewModel(Ref ref)
      : _questionRepository = ref.watch(questionRepositoryProvider),
        _pointTransactionRepository = ref.watch(pointTransactionRepositoryProvider),
  // _cacheManager = ref.watch(cacheManagerProvider), // REFACTORED: Removed
        _formCacheBox = ref.watch(formCacheBoxProvider),
        _userDepartmentId = ref.watch(userDepartmentIdProvider),
        _uploaderId = ref.watch(userIdProvider) {
    _initialize();
  }

  // ... (rest of QuestionViewModel methods remain the same) ...
  Future<void> _initialize() async {
    _loadDepartments();
    _loadFormFromCache();
    _selectedSemester = _determineCurrentSemester();

    if (_userDepartmentId == null || _userDepartmentId!.isEmpty) {
      _errorMessage = "Please set your department in your profile to view questions.";
      _isLoading = false;
      notifyListeners();
      return;
    }

    // REFACTORED: Start cache watcher first, then trigger load/sync
    await _initializeCacheWatcher();
    await loadQuestions(); // This will check validity and sync if needed
  }

  Future<void> _initializeCacheWatcher() async {
    addSubscription(
      _questionRepository.watchAll().listen((questions) {
        _cachedQuestions = questions; // Update the main source
        // REFACTORED: Apply filters whenever cache updates
        _applyCachedFilters(); // This will update _filteredQuestions and notify
      }, onError: (error) {
        _errorMessage = 'Failed to watch cached questions: $error';
        notifyListeners();
      }),
    );
  }

  // ============ MAIN QUESTIONS FUNCTIONALITY ============

  Future<void> loadQuestions({bool forceRefresh = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // REFACTORED: Simplified logic.
      // 1. Check if cache is valid (delegated to repository)
      final bool isCacheStillValid = await _questionRepository.isCacheValid();

      // 2. Sync if it's a forced refresh OR if the cache is invalid
      if (forceRefresh || !isCacheStillValid) {
        await _questionRepository.syncWithRemote();
        // The real-time listener will automatically update
        // _cachedQuestions from the Hive box.
        // No need to set sync time, repository handles it.
      }
      // 3. If cache IS valid and not force-refreshing, do nothing.
      // The _initializeCacheWatcher has already loaded data from Hive.

      // REFACTORED: This logic is now handled by _applyCachedFilters
      // _applyFilters();
    } catch (e) {
      _errorMessage = "Failed to load questions: ${e.toString()}";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void filterQuestions(QuestionFilter? filter) {
    _currentFilter = filter;
    // REFACTORED: Use the single cache filter method
    _applyCachedFilters();
    // notifyListeners(); // _applyCachedFilters calls notifyListeners
  }

  void searchQuestions(String query) {
    _searchQuery = query.toLowerCase().trim();
    // REFACTORED: Use the single cache filter method
    _applyCachedFilters();
    // notifyListeners(); // _applyCachedFilters calls notifyListeners
  }

  // REFACTORED: This method is no longer needed, merged with _applyCachedFilters
  // void _applyFilters() {
  //   ...
  // }

  // ============ CACHED QUESTIONS FUNCTIONALITY ============

  // REFACTORED: This is no longer needed, logic is in loadQuestions
  // Future<void> loadCachedQuestions() async {
  //   ...
  // }

  void filterCachedQuestions(String? examType) {
    _currentExamTypeFilter = examType;
    _applyCachedFilters();
  }

  void searchCachedQuestions(String query) {
    _searchQuery = query;
    _applyCachedFilters();
  }

  // REFACTORED: Renamed from _applyFilters and combined logic
  void _applyCachedFilters() {
    // Start from the full list provided by the watcher
    List<Question> filtered = List.from(_cachedQuestions); // Start with a copy

    // Apply search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((q) =>
      q.courseName.toLowerCase().contains(query) ||
          q.courseCode.toLowerCase().contains(query)
      ).toList();
    }

    // Apply legacy filter
    if (_currentFilter != null) {
      filtered = filtered
          .where((q) => q.examType.toLowerCase() == _currentFilter!.displayName.toLowerCase())
          .toList();
    }

    // Apply exam type filter
    if (_currentExamTypeFilter != null) {
      filtered = filtered.where((q) => q.examType == _currentExamTypeFilter).toList();
    }

    // REFACTORED: Update the list that the UI is watching
    _filteredQuestions = filtered;

    notifyListeners();
  }

  // ============ SEARCH FUNCTIONALITY ============

  Future<void> performSearch({
    required String query,
    String? department,
    String? examType,
    String? semester,
    int limit = 20,
  }) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isSearching = true;
    _errorMessage = null;
    _lastQuery = query;
    notifyListeners();

    try {
      _searchResults = await _questionRepository.searchQuestions(
        query: query,
        department: department,
        examType: examType,
        semester: semester,
        limit: limit,
      );
    } catch (e) {
      _errorMessage = "Search failed: ${e.toString()}";
      _searchResults = [];
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  Future<void> searchByCourse(String courseCode) async {
    _isSearching = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _searchResults = await _questionRepository.getQuestionsByCourse(courseCode);
    } catch (e) {
      _errorMessage = "Search failed: ${e.toString()}";
      _searchResults = [];
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _searchResults = [];
    _lastQuery = '';
    _errorMessage = null;
    notifyListeners();
  }

  // ============ UPLOAD FUNCTIONALITY ============

  Future<void> _loadDepartments() async {
    _departments = allDepartments;
    notifyListeners();
  }

  Future<void> fetchCoursesForDepartment(Department department) async {
    _selectedDepartment = department;
    _selectedCourse = null;
    _courses = [];
    _isCoursesLoading = true;
    notifyListeners();

    try {
      _courses = getCourseList(department.id);
    } catch (e) {
      _lastUploadError = "Failed to fetch courses.";
      debugPrint("Course fetch error: $e");
    } finally {
      _isCoursesLoading = false;
      await _cacheFormState();
      notifyListeners();
    }
  }

  void selectCourse(Course? course) {
    _selectedCourse = course;
    _cacheFormState();
    notifyListeners();
  }

  void selectExamType(String? type) {
    _selectedExamType = type;
    _cacheFormState();
    notifyListeners();
  }

  void selectYear(int? year) {
    if (year == null) return;
    _selectedYear = year;
    _cacheFormState();
    notifyListeners();
  }

  void selectSemester(String? semester) {
    if (semester == null) return;
    _selectedSemester = semester;
    _cacheFormState();
    notifyListeners();
  }

  Future<void> pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(imageQuality: 80);
    if (pickedFiles.isNotEmpty) {
      _selectedImages = pickedFiles.map((file) => File(file.path)).toList();
      _selectedPdf = null;
      notifyListeners();
    }
  }

  Future<void> pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      _selectedPdf = File(result.files.single.path!);
      _selectedImages = [];
      notifyListeners();
    }
  }

  void clearFiles() {
    _selectedImages = [];
    _selectedPdf = null;
    notifyListeners();
  }

  Future<void> uploadQuestion() async {
    _lastUploadError = null;
    _uploadSuccess = false;

    if (_selectedDepartment == null ||
        _selectedCourse == null ||
        _selectedExamType == null ||
        (_selectedImages.isEmpty && _selectedPdf == null)) {
      _lastUploadError = 'Please fill all required fields and select a file.';
      notifyListeners();
      return;
    }

    _isUploading = true;
    notifyListeners();

    try {
      // TODO: Handle file upload logic (images to PDF, PDF upload)
      // This example assumes file upload logic is part of repository.save()
      // or a separate file upload service.
      String uploadedPdfUrl = '';
      if (_selectedPdf != null) {
        // uploadedPdfUrl = await _fileUploadService.uploadPdf(_selectedPdf);
      } else if (_selectedImages.isNotEmpty) {
        // File pdf = await _createPdfFromImages(_selectedImages);
        // uploadedPdfUrl = await _fileUploadService.uploadPdf(pdf);
      }

      // Create question model
      final question = Question(
        id: const Uuid().v4(),
        courseCode: _selectedCourse!.code,
        courseName: _selectedCourse!.name,
        department: _selectedDepartment!.name,
        examType: _selectedExamType!,
        examYear: _selectedYear.toString(),
        semester: _selectedSemester,
        teacherName: teacherNameController.text,
        pdfUrl: uploadedPdfUrl, // Use the actual uploaded URL
        uploadedBy: _uploaderId, // Use the ID fetched from the provider
        access: QuestionAccess.points,
        pointsRequired: 10,
        status: QuestionStatus.unapproved,
        rating: 0,
        totalRatings: 0,
        downloadCount: 0,
        viewCount: 0,
        thumbnailUrl: '',
        fileHash: '', // TODO: Generate hash of the file
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.pending,
        version: 0,
      );

      // Save question (repository handles firestore/cache)
      await _questionRepository.save(question);

      // Award points for upload
      await _pointTransactionRepository.addEarnedPoints(
        points: 50, // Points for uploading
        description: 'Uploaded question: ${_selectedCourse!.name}',
        referenceId: question.id,
        category: 'question_upload',
      );

      _uploadSuccess = true;
      _resetForm();
    } catch (e) {
      _lastUploadError = 'Upload failed: ${e.toString()}';
      _uploadSuccess = false;
      debugPrint("Upload error: $e");
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  Future<File> _createPdfFromImages(List<File> images) async {
    final pdf = pw.Document();

    final imageFutures = images.map((file) async {
      try {
        return await FlutterImageCompress.compressWithFile(
          file.absolute.path,
          minWidth: 800,
          quality: 80,
        );
      } catch (e) {
        debugPrint('Failed to compress image ${file.path}: $e');
        return null;
      }
    }).toList();

    final List<Uint8List?> compressedImages = await Future.wait(imageFutures);
    final validImages = compressedImages.whereType<Uint8List>().toList();

    if (validImages.isEmpty) {
      throw Exception('Image processing failed. Could not create PDF.');
    }

    for (final imageBytes in validImages) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.FittedBox(
                child: pw.Image(pw.MemoryImage(imageBytes)),
                fit: pw.BoxFit.contain,
              ),
            );
          },
        ),
      );
    }

    final dir = await getTemporaryDirectory();
    final pdfFile = File('${dir.path}/exam_${const Uuid().v4()}.pdf');
    await pdfFile.writeAsBytes(await pdf.save());
    return pdfFile;
  }

  void _resetForm() {
    _selectedDepartment = null;
    _selectedCourse = null;
    _selectedExamType = null;
    _selectedYear = DateTime.now().year;
    _selectedSemester = _determineCurrentSemester();
    teacherNameController.clear();
    _courses = [];
    _selectedImages = [];
    _selectedPdf = null;
    _formCacheBox.clear();
  }

  String _determineCurrentSemester() {
    final month = DateTime.now().month;
    if (month >= 1 && month <= 4) return 'Spring';
    if (month >= 5 && month <= 8) return 'Summer';
    return 'Fall';
  }

  void resetUploadSuccess() {
    _uploadSuccess = false;
    notifyListeners();
  }

  void _loadFormFromCache() {
    final cachedDeptId = _formCacheBox.get('departmentId');
    if (cachedDeptId != null && _departments.any((d) => d.id == cachedDeptId)) {
      final dept = _departments.firstWhere((d) => d.id == cachedDeptId);
      fetchCoursesForDepartment(dept).then((_) {
        final cachedCourseCode = _formCacheBox.get('courseCode');
        if (cachedCourseCode != null && _courses.any((c) => c.code == cachedCourseCode)) {
          _selectedCourse = _courses.firstWhere((c) => c.code == cachedCourseCode);
          notifyListeners();
        }
      });
    }
    _selectedExamType = _formCacheBox.get('examType');
    _selectedYear = _formCacheBox.get('year') ?? DateTime.now().year;
    _selectedSemester = _formCacheBox.get('semester') ?? _determineCurrentSemester();
    teacherNameController.text = _formCacheBox.get('teacherName') ?? '';
    notifyListeners();
  }

  Future<void> _cacheFormState() async {
    await _formCacheBox.put('departmentId', _selectedDepartment?.id);
    await _formCacheBox.put('courseCode', _selectedCourse?.code);
    await _formCacheBox.put('examType', _selectedExamType);
    await _formCacheBox.put('year', _selectedYear);
    await _formCacheBox.put('semester', _selectedSemester);
    await _formCacheBox.put('teacherName', teacherNameController.text);
  }

  // ============ COMMON FUNCTIONALITY ============

  // QuestionListViewModel functionality
  void initializeWithQuestions(List<Question> questions) {
    _allQuestions = questions;
    // REFACTORED: Use the single cache filter method
    _applyCachedFilters();
    // notifyListeners(); // _applyCachedFilters calls notifyListeners
  }

  // Analytics methods
  Future<void> incrementViewCount(String questionId) async {
    try {
      await _questionRepository.incrementViewCount(questionId);
    } catch (e) {
      debugPrint('Error incrementing view count: $e');
    }
  }

  Future<void> incrementDownloadCount(String questionId) async {
    try {
      await _questionRepository.incrementDownloadCount(questionId);
    } catch (e) {
      debugPrint('Error incrementing download count: $e');
    }
  }

  // Cache management
  Future<void> refreshQuestions() async {
    await loadQuestions(forceRefresh: true);
  }

  Future<void> refreshCachedQuestions() async {
    await _questionRepository.syncWithRemote();
    // REFACTORED: Removed cache manager call
    // await _cacheManager.setLastSyncTime(cachedQuestionsKey, DateTime.now());
  }

  Future<void> clearCache() async {
    await _questionRepository.clearCache();
    // REFACTORED: Removed cache manager call
    // await _cacheManager.setLastSyncTime(cachedQuestionsKey, DateTime.now());

    // REFACTORED: The watcher will automatically update the list to be empty
    // _cachedQuestions.clear();
    // notifyListeners();
  }

  Future<bool> isCacheValid() async {
    return await _questionRepository.isCacheValid();
  }

  // Additional utility methods using the merged repository

  Stream<List<Question>> watchFilteredQuestions({
    String? searchQuery,
    String? examType,
    String? courseCode,
  }) {
    return _questionRepository.watchFiltered(
      searchQuery: searchQuery,
      examType: examType,
      courseCode: courseCode,
    );
  }

  Future<List<Question>> getQuestionsWithPagination({
    int limit = 20,
    int offset = 0,
  }) async {
    return await _questionRepository.getQuestions(
      limit: limit,
      offset: offset,
    );
  }

  Future<DateTime?> getLastSyncTime() async {
    return await _questionRepository.getLastSyncTime();
  }

  @override
  void dispose() {
    _questionRepository.dispose();
    teacherNameController.dispose();
    super.dispose();
  }
}