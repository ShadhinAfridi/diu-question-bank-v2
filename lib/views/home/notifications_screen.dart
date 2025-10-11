import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/notification_model.dart';
import '../../viewmodels/notifications_viewmodel.dart';
import '../profile/notification_settings_screen.dart';
import '../widgets/state_indicators.dart';

/// A premium screen for displaying user notifications.
///
/// Key Improvements:
/// - **Modern Layout:** Uses a `CustomScrollView` with a `SliverAppBar` for a
///   dynamic, professional look.
/// - **Robust State Handling:** Manages and displays `loading`, `success`,
///   `error`, and `empty` states clearly.
/// - **Custom Components:** Uses a custom `_NotificationCard` for a polished
///   and consistent list item design.
/// - **Enhanced UX:** Adds a confirmation dialog before deleting notifications
///   to prevent accidental actions. List items fade in smoothly.
/// - **Navigation:** Includes a clear entry point to the Notification Settings screen.
class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<UnifiedNotificationViewModel>(
        builder: (context, viewModel, _) {
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                title: const Text('Notifications'),
                pinned: true,
                actions: [
                  if (viewModel.unreadCount > 0)
                    TextButton(
                      onPressed: viewModel.markAllAsRead,
                      child: const Text('Mark All Read'),
                    ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NotificationSettingsScreen()),
                      );
                    },
                    tooltip: 'Notification Settings',
                  ),
                ],
              ),
              _buildBody(context, viewModel),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, UnifiedNotificationViewModel viewModel) {
    switch (viewModel.notificationStatus) {
      case ViewStatus.loading:
        return const SliverFillRemaining(child: CenteredLoadingIndicator());
      case ViewStatus.error:
        return SliverFillRemaining(
          child: ErrorDisplay(
            message: viewModel.notificationError,
            onRetry: viewModel.refreshData,
          ),
        );
      case ViewStatus.success:
        if (viewModel.notifications.isEmpty) {
          return const SliverFillRemaining(
            child: EmptyState(
              icon: Icons.notifications_off_outlined,
              message: 'All Caught Up!',
              details: 'You have no new notifications.',
            ),
          );
        }
        return _NotificationList(
          notifications: viewModel.notifications,
          viewModel: viewModel,
        );
    }
  }
}

class _NotificationList extends StatelessWidget {
  final List<AppNotification> notifications;
  final UnifiedNotificationViewModel viewModel;

  const _NotificationList({required this.notifications, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final notification = notifications[index];
          // Use PageTransitionSwitcher for a nice fade-in animation
          return OpenContainer(
            closedColor: Theme.of(context).scaffoldBackgroundColor,
            openColor: Theme.of(context).scaffoldBackgroundColor,
            closedElevation: 0,
            openElevation: 0,
            transitionType: ContainerTransitionType.fade,
            transitionDuration: const Duration(milliseconds: 400),
            closedBuilder: (context, action) {
              return _NotificationCard(
                notification: notification,
                onTap: () {
                  if (!notification.isRead) viewModel.markAsRead(notification.id);
                  action(); // Opens the container, can navigate to a detail screen
                },
                onDelete: () => _confirmDelete(context, notification.id),
              );
            },
            openBuilder: (context, action) {
              // Replace with a detailed view of the notification if needed
              return Scaffold(appBar: AppBar(), body: Center(child: Text(notification.body)));
            },
          );
        },
        childCount: notifications.length,
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, String notificationId) async {
    final bool? didConfirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notification?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
    if (didConfirm ?? false) {
      viewModel.deleteNotification(notificationId);
    }
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isUnread = !notification.isRead;

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        color: theme.colorScheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Icon(Icons.delete_forever_rounded, color: theme.colorScheme.onErrorContainer),
      ),
      child: Material(
        color: isUnread ? theme.colorScheme.primary.withOpacity(0.05) : Colors.transparent,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: isUnread ? theme.colorScheme.primary : theme.colorScheme.secondaryContainer,
            child: Icon(
              _getIconForType(notification.type),
              color: isUnread ? theme.colorScheme.onPrimary : theme.colorScheme.onSecondaryContainer,
            ),
          ),
          title: Text(
            notification.title,
            style: TextStyle(fontWeight: isUnread ? FontWeight.bold : FontWeight.normal),
          ),
          subtitle: Text(
            '${notification.body}\n${timeago.format(notification.receivedAt)}',
          ),
          isThreeLine: true,
          onTap: onTap,
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'taskReminder': return Icons.task_alt_rounded;
      case 'eventReminder': return Icons.event_available_rounded;
      case 'announcement': return Icons.campaign_rounded;
      default: return Icons.notifications_rounded;
    }
  }
}