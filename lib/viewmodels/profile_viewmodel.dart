import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../repositories/interfaces/user_repository.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../data/departments.dart';
import '../models/department_model.dart' as app_models;
// import '../di/di.dart'; // REMOVED
import 'base_viewmodel.dart';

// Import provider files
import '../providers/repository_providers.dart';
import '../providers/service_providers.dart';

class ProfileViewModel extends BaseViewModel {
  final IUserRepository _userRepository;
  final AuthService _authService;

  app_models.Department? _selectedDepartment;
  bool _isSaving = false;
  File? _selectedProfileImage;
  UserModel? _currentUser;

  app_models.Department? get selectedDepartment => _selectedDepartment;
  bool get isSaving => _isSaving;
  File? get selectedProfileImage => _selectedProfileImage;
  UserModel? get currentUser => _currentUser;

  String get userName => _currentUser?.name ?? 'User';
  String get userEmail => _currentUser?.email ?? '';
  String get userPhone => _currentUser?.phone ?? '';
  String? get profilePictureUrl => _currentUser?.profilePictureUrl;
  int get userPoints => _currentUser?.points ?? 0;
  int get userLevel => _currentUser?.level ?? 1;
  double get levelProgress => _currentUser?.levelProgress ?? 0.0;

  // Constructor now accepts Ref and uses it to get dependencies
  ProfileViewModel(Ref ref)
      : _userRepository = ref.watch(userRepositoryProvider),
        _authService = ref.watch(authServiceProvider) {
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final users = await _userRepository.getAll();
      if (users.isNotEmpty) {
        _currentUser = users.first;
        _selectedDepartment = allDepartments.firstWhere(
              (d) => d.id == _currentUser!.department,
          orElse: () => allDepartments.first,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  void selectDepartment(app_models.Department? department) {
    if (department != null) {
      _selectedDepartment = department;
      notifyListeners();
    }
  }

  Future<void> updateDepartment() async {
    if (_selectedDepartment == null || _isSaving || _currentUser == null) return;

    _isSaving = true;
    notifyListeners();

    try {
      final updatedUser = _currentUser!.copyWith(
        department: _selectedDepartment!.id,
        updatedAt: DateTime.now(),
        version: _currentUser!.version + 1,
      );
      await _userRepository.save(updatedUser);
      _currentUser = updatedUser;
    } catch (e) {
      debugPrint('Error updating department: $e');
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile(String name, String phone) async {
    if (_currentUser == null) return false;
    _isSaving = true;
    notifyListeners();

    try {
      String? newImageUrl;
      if (_selectedProfileImage != null) {
        newImageUrl = await _uploadProfileImage();
      }

      final updatedUser = _currentUser!.copyWith(
        name: name,
        phone: phone,
        profilePictureUrl: newImageUrl ?? _currentUser!.profilePictureUrl,
        updatedAt: DateTime.now(),
        version: _currentUser!.version + 1,
      );

      await _userRepository.save(updatedUser);
      _currentUser = updatedUser;
      _selectedProfileImage = null;

      return true;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> pickProfileImage({required bool fromCamera}) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      );

      if (image != null) {
        final compressedImage = await _compressImage(File(image.path));
        _selectedProfileImage = compressedImage;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<File> _compressImage(File file) async {
    final dir = await getTemporaryDirectory();
    final targetPath = p.join(dir.absolute.path, "${DateTime.now().millisecondsSinceEpoch}.jpg");

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 70,
      minWidth: 800,
      minHeight: 800,
    );

    return result != null ? File(result.path) : file;
  }

  Future<void> removeProfileImage() async {
    if (_currentUser == null) return;

    try {
      final updatedUser = _currentUser!.copyWith(
        profilePictureUrl: null,
        updatedAt: DateTime.now(),
        version: _currentUser!.version + 1,
      );
      await _userRepository.save(updatedUser);
      _currentUser = updatedUser;
      _selectedProfileImage = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error removing profile image: $e');
    }
  }

  Future<String?> _uploadProfileImage() async {
    if (_selectedProfileImage == null || _currentUser == null) return null;

    try {
      // Placeholder for actual upload logic
      await Future.delayed(const Duration(seconds: 1));
      return 'https://example.com/profile.jpg';
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      throw e;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  String getInitials(String name) {
    if (name.isEmpty) return '?';

    final nameParts = name.trim().split(' ');
    if (nameParts.length == 1) {
      return nameParts[0][0].toUpperCase();
    } else {
      return '${nameParts[0][0]}${nameParts[nameParts.length - 1][0]}'.toUpperCase();
    }
  }
}