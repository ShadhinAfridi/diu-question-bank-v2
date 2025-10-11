import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/departments.dart';
import '../../models/department_model.dart' as app_models;
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../theme/app_theme.dart';
import './edit_profile_screen.dart';
import './change_password_screen.dart';
import './notification_settings_screen.dart';
import './rewards_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final homeViewModel = context.watch<HomeViewModel>();
    final authViewModel = context.read<AuthViewModel>();

    return ChangeNotifierProvider(
      create: (_) => ProfileViewModel(homeViewModel, authViewModel),
      child: Consumer<ProfileViewModel>(
        builder: (context, profileViewModel, child) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Profile'),
              backgroundColor: theme.colorScheme.surface,
              elevation: 1,
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () async => await authViewModel.signOut(context),
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: AppSpacing.pagePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProfileHeader(
                    name: homeViewModel.userName,
                    email: authViewModel.user?.email ?? 'No email available',
                    avatarUrl: homeViewModel.profilePictureUrl,
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  _EarningsSection(
                    profileViewModel: profileViewModel,
                  ),
                  const SizedBox(height: AppSpacing.s32),
                  _ProfileSection(
                    title: 'Account',
                    children: [
                      _ProfileMenuItem(
                        icon: Icons.edit_outlined,
                        title: 'Edit Profile',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChangeNotifierProvider.value(
                                value: profileViewModel,
                                child: const EditProfileScreen(),
                              ),
                            ),
                          );
                        },
                      ),
                      _ProfileMenuItem(
                        icon: Icons.lock_outline,
                        title: 'Change Password',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChangeNotifierProvider.value(
                                value: profileViewModel,
                                child: const ChangePasswordScreen(),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s24),
                  _ProfileSection(
                    title: 'Preferences',
                    children: [
                      _ProfileMenuItem(
                        icon: Icons.school_outlined,
                        title: 'Update Department',
                        onTap: () => _showDepartmentDialog(context, profileViewModel),
                      ),
                      _ProfileMenuItem(
                        icon: Icons.palette_outlined,
                        title: 'Appearance',
                        onTap: () => _showThemeDialog(context, profileViewModel),
                      ),
                      _ProfileMenuItem(
                        icon: Icons.notifications_outlined,
                        title: 'Notifications',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              // FIX: This screen provides its own ViewModel.
                              builder: (context) => const NotificationSettingsScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showDepartmentDialog(BuildContext context, ProfileViewModel viewModel) {
    return showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Update Department'),
          content: DropdownButtonFormField<app_models.Department>(
            decoration: InputDecoration(
              labelText: 'Choose your department',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            value: viewModel.selectedDepartment,
            isExpanded: true,
            items: allDepartments.map((department) {
              return DropdownMenuItem<app_models.Department>(
                value: department,
                child: Text(department.name),
              );
            }).toList(),
            onChanged: (newValue) {
              viewModel.selectDepartment(newValue);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: viewModel.isSaving
                  ? null
                  : () async {
                await viewModel.updateDepartment();
                if (context.mounted) Navigator.of(dialogContext).pop();
              },
              child: viewModel.isSaving
                  ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showThemeDialog(BuildContext context, ProfileViewModel viewModel) {
    return showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Select Theme'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.brightness_auto),
                  title: const Text('System Default'),
                  onTap: () {
                    viewModel.changeTheme('system');
                    Navigator.of(dialogContext).pop();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.light_mode),
                  title: const Text('Light'),
                  onTap: () {
                    viewModel.changeTheme('light');
                    Navigator.of(dialogContext).pop();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.dark_mode),
                  title: const Text('Dark'),
                  onTap: () {
                    viewModel.changeTheme('dark');
                    Navigator.of(dialogContext).pop();
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

class _EarningsSection extends StatelessWidget {
  final ProfileViewModel profileViewModel;

  const _EarningsSection({
    required this.profileViewModel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // FIX: Access the HomeViewModel correctly from the context.
    final homeViewModel = context.watch<HomeViewModel>();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: AppBorderRadius.lg,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'EARNINGS & REWARDS',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _EarningItem(
                  value: profileViewModel.userPoints.toString(),
                  label: 'Points',
                  icon: Icons.emoji_events,
                  color: theme.colorScheme.primary,
                ),
                _EarningItem(
                  value: 'Level ${profileViewModel.userLevel}',
                  label: 'Current Level',
                  icon: Icons.star,
                  color: Colors.amber,
                ),
                _EarningItem(
                  value: '${(profileViewModel.levelProgress * 100).toInt()}%',
                  label: 'Next Level',
                  icon: Icons.trending_up,
                  color: theme.colorScheme.secondary,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Progress to Level ${profileViewModel.userLevel + 1}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: profileViewModel.levelProgress,
              backgroundColor: theme.colorScheme.surfaceVariant,
              color: theme.colorScheme.primary,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChangeNotifierProvider.value(
                        // FIX: Provide the HomeViewModel instance from the context.
                        value: homeViewModel,
                        child: const RewardsScreen(),
                      ),
                    ),
                  );
                },
                child: const Text('VIEW REWARDS'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EarningItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _EarningItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String email;
  final String? avatarUrl;

  const _ProfileHeader({
    required this.name,
    required this.email,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        _buildAvatar(theme),
        const SizedBox(height: AppSpacing.s16),
        Text(
          name,
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.s4),
        Text(
          email,
          style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAvatar(ThemeData theme) {
    if (avatarUrl == null || avatarUrl!.isEmpty) {
      return CircleAvatar(
        radius: 50,
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Text(
          _getInitials(name),
          style: theme.textTheme.headlineLarge?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: 50,
      backgroundColor: theme.colorScheme.primaryContainer,
      child: ClipOval(
        child: Image.network(
          avatarUrl!,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildInitialsFallback(theme, name);
          },
        ),
      ),
    );
  }

  Widget _buildInitialsFallback(ThemeData theme, String name) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _getInitials(name),
          style: theme.textTheme.headlineLarge?.copyWith(
            color: theme.colorScheme.onSecondaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _getInitials(String userName) {
    if (userName.isEmpty) return '?';

    final nameParts = userName.trim().split(' ');
    if (nameParts.length == 1) {
      return nameParts[0][0].toUpperCase();
    } else {
      return '${nameParts[0][0]}${nameParts[nameParts.length - 1][0]}'.toUpperCase();
    }
  }
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _ProfileSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: AppBorderRadius.md,
            side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.5)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
      title: Text(title, style: theme.textTheme.bodyLarge),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}

// Assuming EditProfileScreen and ChangePasswordScreen are defined to accept
// a ProfileViewModel through a constructor or can access it via Provider.
class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    // Access the ProfileViewModel from the provider
    final profileViewModel = context.watch<ProfileViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Center(child: Text('Editing profile for ${profileViewModel.userName}')),
    );
  }
}

class ChangePasswordScreen extends StatelessWidget {
  const ChangePasswordScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Password')),
      body: const Center(child: Text('Change password form goes here.')),
    );
  }
}
