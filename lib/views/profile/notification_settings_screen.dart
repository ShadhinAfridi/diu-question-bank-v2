import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/notifications_viewmodel.dart';
import '../widgets/state_indicators.dart';

/// A premium screen for managing notification preferences.
///
/// Key Improvements:
/// - **Clean, Modern Layout:** Uses a `CustomScrollView` and a `SliverAppBar`
///   for a professional look and feel.
/// - **Robust State Handling:** Clearly shows loading and error states, preventing
///   a blank or unresponsive screen.
/// - **Custom Components:** Employs custom `_SettingsCategoryCard` and
///   `_SettingsSwitchTile` widgets for a unique, polished, and consistent UI.
/// - **Instant Feedback:** The UI updates instantly when a switch is toggled,
///   and a subtle saving indicator appears in the app bar, providing excellent
///   user feedback.
class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<UnifiedNotificationViewModel>(context, listen: false);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('Notification Settings'),
            pinned: true,
            actions: [
              if (viewModel.isSavingSettings)
                const Padding(
                  padding: EdgeInsets.only(right: 16.0),
                  child: Center(
                    child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                ),
            ],
          ),
          _buildBody(context, viewModel),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, UnifiedNotificationViewModel viewModel) {
    switch (viewModel.settingsStatus) {
      case ViewStatus.loading:
        return const SliverFillRemaining(child: CenteredLoadingIndicator());
      case ViewStatus.error:
        return SliverFillRemaining(
          child: ErrorDisplay(
            message: viewModel.settingsError,
            onRetry: () {
              final userId = viewModel.auth.currentUser?.uid;
              if (userId != null) {
                viewModel.loadSettings(userId);
              }
            },
          ),
        );
      case ViewStatus.success:
        return Consumer<UnifiedNotificationViewModel>(
          builder: (context, viewModel, _) {
            return SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate.fixed([
                  _SettingsCategoryCard(
                    icon: Icons.alarm_on_outlined,
                    title: 'Reminders',
                    children: [
                      _SettingsSwitchTile(
                        title: 'Task Reminders',
                        subtitle: 'For your study plan and to-dos.',
                        value: viewModel.settings.taskReminders,
                        onChanged: (v) => viewModel.updateSettingAndSave((s) => s.taskReminders = v),
                      ),
                      _SettingsSwitchTile(
                        title: 'Event Reminders',
                        subtitle: 'For upcoming classes and events.',
                        value: viewModel.settings.eventReminders,
                        onChanged: (v) => viewModel.updateSettingAndSave((s) => s.eventReminders = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SettingsCategoryCard(
                    icon: Icons.school_outlined,
                    title: 'Academics',
                    children: [
                      _SettingsSwitchTile(
                        title: 'Exam Schedules',
                        subtitle: 'Notifications for upcoming exams.',
                        value: viewModel.settings.examSchedules,
                        onChanged: (v) => viewModel.updateSettingAndSave((s) => s.examSchedules = v),
                      ),
                      _SettingsSwitchTile(
                        title: 'Results Published',
                        subtitle: 'Get notified when results are available.',
                        value: viewModel.settings.resultNotifications,
                        onChanged: (v) => viewModel.updateSettingAndSave((s) => s.resultNotifications = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SettingsCategoryCard(
                    icon: Icons.smartphone_rounded,
                    title: 'Device Preferences',
                    children: [
                      _SettingsSwitchTile(
                        title: 'Do Not Disturb',
                        subtitle: 'Silence all notifications from this app.',
                        value: viewModel.settings.doNotDisturb,
                        onChanged: (v) => viewModel.updateSettingAndSave((s) => s.doNotDisturb = v),
                      ),
                      _SettingsSwitchTile(
                        title: 'Sound',
                        subtitle: 'Play a sound for notifications.',
                        value: viewModel.settings.sound,
                        onChanged: (v) => viewModel.updateSettingAndSave((s) => s.sound = v),
                      ),
                      _SettingsSwitchTile(
                        title: 'Vibrate',
                        subtitle: 'Vibrate the device on notification.',
                        value: viewModel.settings.vibration,
                        onChanged: (v) => viewModel.updateSettingAndSave((s) => s.vibration = v),
                      ),
                    ],
                  ),
                ]),
              ),
            );
          },
        );
    }
  }
}

class _SettingsCategoryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _SettingsCategoryCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(title, style: theme.textTheme.titleLarge),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }
}