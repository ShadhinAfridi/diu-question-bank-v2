import 'dart:io';
import 'dart:typed_data'; // Import for Uint8List
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart'; // Import for debugPrint
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/course_model.dart';
import '../models/department_model.dart';
import '../data/departments.dart';

class UploadViewModel extends ChangeNotifier {
  // --- Dependencies ---
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Box _formCacheBox = Hive.box('form_cache');

  // --- State Properties ---
  List<Department> _departments = [];
  Department? _selectedDepartment;
  List<Course> _courses = [];
  Course? _selectedCourse;
  String? _selectedExamType;
  int _selectedYear = DateTime.now().year;
  String _selectedSemester = 'Spring';
  final TextEditingController teacherNameController = TextEditingController();
  List<File> _selectedImages = [];
  File? _selectedPdf;
  bool _isUploading = false;
  bool _isCoursesLoading = false;
  String? _lastUploadError;
  bool _uploadSuccess = false;

  // --- Public Getters ---
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
  bool get isUploading => _isUploading;
  bool get isCoursesLoading => _isCoursesLoading;
  String? get lastUploadError => _lastUploadError;
  bool get uploadSuccess => _uploadSuccess;

  // --- Constructor ---
  UploadViewModel() {
    _loadDepartments();
    _loadFormFromCache();
    _selectedSemester = _determineCurrentSemester();
  }

  // --- Form State Management ---

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

  // --- File Picking ---
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

  // --- Upload Logic ---
  Future<void> uploadQuestion() async {
    _lastUploadError = null;
    _uploadSuccess = false;

    // Check if user is authenticated
    final user = _auth.currentUser;
    if (user == null) {
      _lastUploadError = 'You must be logged in to upload questions.';
      notifyListeners();
      return;
    }

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
      File fileToUpload;
      if (_selectedPdf != null) {
        fileToUpload = _selectedPdf!;
      } else {
        // This now calls the improved method
        fileToUpload = await _createPdfFromImages(_selectedImages);
      }

      final fileName = '${const Uuid().v4()}.pdf';
      final storageRef = _storage.ref('questions/${_selectedDepartment!.id}/$fileName');
      final uploadTask = await storageRef.putFile(fileToUpload);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      final questionData = {
        'department': _selectedDepartment!.name,
        'departmentId': _selectedDepartment!.id,
        'courseName': _selectedCourse!.name,
        'courseCode': _selectedCourse!.code,
        'examType': _selectedExamType,
        'examYear': _selectedYear.toString(),
        'semester': _selectedSemester,
        'teacherName': teacherNameController.text,
        'pdfUrl': downloadUrl,
        'uploadedBy': user.uid,
        'uploadedByEmail': user.email,
        'status': 'unapproved',
        'uploadedAt': FieldValue.serverTimestamp(),
        'processedAt': null,
        'approvedBy': null,
      };

      await _firestore.collection('questions').add(questionData);

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

  // --- Helper Methods ---

  /// --- [ NEW | IMPROVED METHOD ] ---
  /// Creates a PDF from a list of image files efficiently.
  /// - Processes images in parallel.
  /// - Ensures images fit correctly on an A4 page.
  /// - Handles compression errors gracefully.
  Future<File> _createPdfFromImages(List<File> images) async {
    final pdf = pw.Document();

    // 1. Process all image compressions in parallel for speed.
    final imageFutures = images.map((file) async {
      try {
        return await FlutterImageCompress.compressWithFile(
          file.absolute.path,
          minWidth: 800,
          quality: 80,
        );
      } catch (e) {
        debugPrint('Failed to compress image ${file.path}: $e');
        return null; // Return null if compression fails
      }
    }).toList();

    final List<Uint8List?> compressedImages = await Future.wait(imageFutures);

    // 2. Filter out any images that failed to compress.
    final validImages = compressedImages.whereType<Uint8List>().toList();

    // 3. Add a robust check to prevent creating an empty PDF.
    if (validImages.isEmpty) {
      throw Exception('Image processing failed. Could not create PDF.');
    }

    for (final imageBytes in validImages) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            // 4. Use FittedBox to ensure the image scales to fit the page.
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
    notifyListeners(); // Also notify listeners to rebuild UI if needed
  }

  // --- Caching Logic ---
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
}