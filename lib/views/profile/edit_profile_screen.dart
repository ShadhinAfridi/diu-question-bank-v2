import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../theme/app_theme.dart'; // Assuming you have this for styling

class EditProfileScreen extends StatefulWidget {
  // FIX: Reverted to accepting viewModel as a parameter to resolve the Provider error.
  // The root cause is that the Provider for ProfileViewModel is not available
  // in the widget tree above this screen. The ideal solution is to wrap the
  // route that leads to this screen with a ChangeNotifierProvider.
  final ProfileViewModel viewModel;

  const EditProfileScreen({super.key, required this.viewModel});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with data from the passed viewModel
    _nameController = TextEditingController(text: widget.viewModel.userName);
    _emailController = TextEditingController(text: widget.viewModel.userEmail);
    _phoneController = TextEditingController(text: widget.viewModel.userPhone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // We get the view model from the widget now, so we don't need a Consumer.
    // However, we listen to changes to rebuild the UI when saving state changes.
    final viewModel = widget.viewModel;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 1,
        actions: [
          // We need to listen to the viewModel to update the saving indicator
          ChangeNotifierProvider.value(
            value: viewModel,
            child: Consumer<ProfileViewModel>(
              builder: (context, vm, child) {
                if (vm.isSaving) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                } else {
                  return IconButton(
                    icon: const Icon(Icons.save),
                    onPressed: () => _saveProfile(viewModel),
                  );
                }
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Listen to changes for the profile picture section
              ChangeNotifierProvider.value(
                value: viewModel,
                child: Consumer<ProfileViewModel>(
                  builder: (context, vm, child) {
                    return _buildProfilePictureSection(theme, vm);
                  },
                ),
              ),
              const SizedBox(height: 24.0),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  prefixIcon: const Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  prefixIcon: const Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32.0),
              ElevatedButton(
                onPressed: () => _saveProfile(viewModel),
                child: const Text('SAVE CHANGES'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePictureSection(ThemeData theme, ProfileViewModel viewModel) {
    ImageProvider? backgroundImage;
    if (viewModel.selectedProfileImage != null) {
      backgroundImage = FileImage(viewModel.selectedProfileImage!);
    } else if (viewModel.profilePictureUrl != null &&
        viewModel.profilePictureUrl!.isNotEmpty) {
      backgroundImage = NetworkImage(viewModel.profilePictureUrl!);
    }

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: theme.colorScheme.primaryContainer,
              backgroundImage: backgroundImage,
              child: backgroundImage == null
                  ? Text(
                viewModel.getInitials(viewModel.userName),
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              )
                  : null,
            ),
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.surface,
                  width: 2,
                ),
              ),
              child: IconButton(
                icon: const Icon(Icons.camera_alt, size: 20),
                color: theme.colorScheme.onPrimary,
                onPressed: () => _changeProfilePicture(viewModel),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8.0),
        TextButton(
          onPressed: () => _changeProfilePicture(viewModel),
          child: const Text('Change Profile Picture'),
        ),
      ],
    );
  }

  void _changeProfilePicture(ProfileViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  viewModel.pickProfileImage(fromCamera: false);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  viewModel.pickProfileImage(fromCamera: true);
                },
              ),
              if (viewModel.profilePictureUrl != null &&
                  viewModel.profilePictureUrl!.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    viewModel.removeProfileImage();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _saveProfile(ProfileViewModel viewModel) async {
    if (_formKey.currentState!.validate()) {
      final success = await viewModel.updateProfile(
        _nameController.text,
        _emailController.text,
        _phoneController.text,
      );
      if (mounted) { // Check if the widget is still in the tree
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Profile updated successfully' : 'Failed to update profile'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        if (success) {
          Navigator.pop(context);
        }
      }
    }
  }
}
