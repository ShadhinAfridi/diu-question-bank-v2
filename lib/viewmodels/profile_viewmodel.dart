import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../data/departments.dart';
import '../models/department_model.dart' as app_models;
import 'auth_viewmodel.dart';
import 'home_viewmodel.dart';

class ProfileViewModel extends ChangeNotifier {
  final HomeViewModel _homeViewModel;
  final AuthViewModel _authViewModel;

  ProfileViewModel(this._homeViewModel, this._authViewModel) {
    _selectedDepartment = allDepartments.firstWhere(
          (d) => d.id == _homeViewModel.userDepartmentId,
      orElse: () => allDepartments.first,
    );

    // Initialize notification settings with default values
    _notificationSettings = {
      'appUpdates': true,
      'announcements': true,
      'newQuestions': true,
      'examSchedules': true,
      'resultNotifications': true,
      'messageNotifications': true,
      'groupNotifications': true,
      'sound': true,
      'vibration': true,
      'led': false,
    };

    // FIX: Listen for changes in HomeViewModel to keep the UI in sync.
    _homeViewModel.addListener(_onHomeViewModelChanged);
  }

  // FIX: This method is called whenever HomeViewModel updates.
  void _onHomeViewModelChanged() {
    // Notify listeners of this ProfileViewModel so that widgets like the
    // rewards card will rebuild with the latest data.
    notifyListeners();
  }

  @override
  void dispose() {
    // FIX: It's crucial to remove the listener when the ViewModel is disposed
    // to prevent memory leaks.
    _homeViewModel.removeListener(_onHomeViewModelChanged);
    super.dispose();
  }


  app_models.Department? _selectedDepartment;
  app_models.Department? get selectedDepartment => _selectedDepartment;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  Map<String, bool> _notificationSettings = {};
  Map<String, bool> get notificationSettings => _notificationSettings;

  // User data properties
  String get userName => _homeViewModel.userName;
  String get userEmail => _authViewModel.user?.email ?? '';
  String get userPhone => _homeViewModel.userPhone ?? '';
  String? get profilePictureUrl => _homeViewModel.profilePictureUrl;

  // Earning and level properties
  int get userPoints => _homeViewModel.userPoints;
  int get userLevel => _homeViewModel.userLevel;
  double get levelProgress => _homeViewModel.levelProgress;

  // Profile image handling
  File? _selectedProfileImage;
  File? get selectedProfileImage => _selectedProfileImage;

  HomeViewModel getHomeViewModel() => _homeViewModel;

  void selectDepartment(app_models.Department? department) {
    if (department != null) {
      _selectedDepartment = department;
      notifyListeners();
    }
  }

  Future<void> updateDepartment() async {
    if (_selectedDepartment == null || _isSaving) return;

    _isSaving = true;
    notifyListeners();

    try {
      await _homeViewModel.updateUserDepartment(_selectedDepartment!.id);
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile(String name, String email, String phone) async {
    if (_authViewModel.user == null) return false;
    _isSaving = true;
    notifyListeners();

    try {
      String? newImageUrl;
      // If there's a new profile image, upload it
      if (_selectedProfileImage != null) {
        newImageUrl = await _uploadProfileImage();
      }

      final userId = _authViewModel.user!.uid;
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(userId);

      // Create a map of data to update.
      final Map<String, dynamic> userDataToUpdate = {
        'name': name,
        'phone': phone,
      };

      // Only add the profile picture URL to the map if it was updated
      if (newImageUrl != null) {
        userDataToUpdate['profilePictureUrl'] = newImageUrl;
      }

      // Atomically update the document in Firestore.
      await userDocRef.update(userDataToUpdate);

      // Manually update the local state of HomeViewModel.
      _homeViewModel.updateLocalUserData(
        name: name,
        phone: phone,
        profilePictureUrl: newImageUrl,
      );


      return true;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return false;
    } finally {
      _isSaving = false;
      _selectedProfileImage = null; // Clear selected image after saving
      notifyListeners();
    }
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    _isSaving = true;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 2));
      return true;
    } catch (e) {
      debugPrint('Error changing password: $e');
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
      quality: 70, // Adjust quality as needed
      minWidth: 800,
      minHeight: 800,
    );

    if (result == null) {
      return file;
    }
    return File(result.path);
  }


  Future<void> removeProfileImage() async {
    if (_authViewModel.user == null) return;
    _selectedProfileImage = null;

    try {
      final userId = _authViewModel.user!.uid;
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(userId);
      // Set the URL to null in Firestore
      await userDocRef.update({'profilePictureUrl': FieldValue.delete()});

      // Manually update the local state to ensure UI consistency
      _homeViewModel.updateLocalUserData(profilePictureUrl: '');


    } catch (e) {
      debugPrint('Error removing profile image: $e');
    } finally {
      notifyListeners();
    }
  }

  Future<String?> _uploadProfileImage() async {
    if (_selectedProfileImage == null || _authViewModel.user == null) return null;

    try {
      final userId = _authViewModel.user!.uid;
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_profiles')
          .child('$userId.jpg');

      await storageRef.putFile(_selectedProfileImage!);
      final imageUrl = await storageRef.getDownloadURL();
      return imageUrl;

    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      throw e;
    }
  }


  Future<bool> saveNotificationSettings() async {
    _isSaving = true;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 1));
      return true;
    } catch (e) {
      debugPrint('Error saving notification settings: $e');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void changeTheme(String themeMode) {
    debugPrint('Changing theme to: $themeMode');
  }

  Future<void> signOut(BuildContext context) async {
    await _authViewModel.signOut(context);
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
