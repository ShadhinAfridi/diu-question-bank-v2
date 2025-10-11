import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/task_model.dart';
import '../theme/app_theme.dart';


class TaskCard extends StatefulWidget {
  final Task task;
  final ValueChanged<bool?> onCompleted;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.onCompleted,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  Timer? _timer;
  Duration? _remainingTime;
  DateTime? _countdownTargetTime;

  @override
  void initState() {
    super.initState();
    _initializeTimer();
  }

  @override
  void didUpdateWidget(covariant TaskCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the task has changed (e.g., its status), re-initialize the timer.
    if (widget.task.status != oldWidget.task.status) {
      _timer?.cancel();
      _initializeTimer();
    }
  }

  void _initializeTimer() {
    _countdownTargetTime = widget.task.time ?? DateTime(widget.task.dueDate.year, widget.task.dueDate.month, widget.task.dueDate.day);

    if (widget.task.status != TaskStatus.completed) {
      _updateRemainingTime();
      if (_countdownTargetTime!.isAfter(DateTime.now())) {
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          _updateRemainingTime();
        });
      }
    }
  }

  void _updateRemainingTime() {
    if (!mounted || _countdownTargetTime == null) return;
    final remaining = _countdownTargetTime!.difference(DateTime.now());
    if (mounted) {
      setState(() {
        _remainingTime = remaining;
      });
    }
    if (remaining.isNegative) {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    if (duration.isNegative) return 'Overdue';
    if (duration.inHours > 23) {
      final days = duration.inDays;
      final hours = duration.inHours.remainder(24);
      return '${days}d ${hours}h left';
    }
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompleted = widget.task.status == TaskStatus.completed;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2.0,
      shadowColor: theme.colorScheme.shadow.withOpacity(0.1),
      child: InkWell(
        onTap: widget.onTap,
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMainContent(context),
              const Divider(height: AppSpacing.s24),
              _buildFooter(context),
              if (widget.task.labels.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s12),
                _buildLabels(context),
              ],
              // Animated switcher for status display
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: _buildStatusIndicator(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(BuildContext context) {
    if (widget.task.status == TaskStatus.completed) {
      // Return an empty container when completed to hide the timer.
      return const SizedBox.shrink();
    }

    if (widget.task.status == TaskStatus.ongoing) {
      return _buildOngoingChip(context);
    }

    // Default to showing the countdown timer for upcoming tasks.
    if (_remainingTime != null) {
      return _buildCountdownTimer(context);
    }

    return const SizedBox.shrink();
  }

  Widget _buildOngoingChip(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      key: const ValueKey('ongoing'),
      alignment: Alignment.centerRight,
      child: Chip(
        avatar: Icon(Icons.sync, size: 18, color: theme.colorScheme.secondary),
        label: Text(
          'Ongoing',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.colorScheme.secondary.withOpacity(0.1),
        side: BorderSide.none,
      ),
    );
  }

  Widget _buildCountdownTimer(BuildContext context) {
    final theme = Theme.of(context);
    final isOverdue = _remainingTime!.isNegative;
    return Align(
      key: const ValueKey('countdown'),
      alignment: Alignment.centerRight,
      child: Chip(
        avatar: Icon(
          Icons.timer_outlined,
          size: 18,
          color: isOverdue ? theme.colorScheme.error : theme.colorScheme.primary,
        ),
        label: Text(
          _formatDuration(_remainingTime!),
          style: theme.textTheme.labelLarge?.copyWith(
            color: isOverdue ? theme.colorScheme.error : theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: (isOverdue ? theme.colorScheme.error : theme.colorScheme.primary).withOpacity(0.1),
        side: BorderSide.none,
      ),
    );
  }

  // Other build methods like _buildMainContent, _buildFooter, etc. remain the same
  Widget _buildMainContent(BuildContext context) {
    final theme = Theme.of(context);
    final isCompleted = widget.task.isCompleted;
    final titleColor = isCompleted ? theme.colorScheme.onSurface.withOpacity(0.5) : theme.colorScheme.onSurface;
    final descriptionColor = isCompleted ? theme.colorScheme.onSurfaceVariant.withOpacity(0.5) : theme.colorScheme.onSurfaceVariant;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: isCompleted,
          onChanged: widget.onCompleted,
          activeColor: theme.colorScheme.primary,
        ),
        const SizedBox(width: AppSpacing.s8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.task.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
              if (widget.task.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.s4),
                  child: Text(
                    widget.task.description,
                    style: theme.textTheme.bodyMedium?.copyWith(color: descriptionColor),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
        if (widget.onEdit != null)
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: widget.onEdit,
            tooltip: 'Edit Task',
          ),
        if (widget.onDelete != null)
          IconButton(
            icon: Icon(Icons.delete_outline, size: 20, color: theme.colorScheme.error),
            onPressed: widget.onDelete,
            tooltip: 'Delete Task',
          ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Row(
      children: [
        _buildInfoChip(
          context,
          Icons.calendar_today_outlined,
          DateFormat.yMMMd().format(widget.task.dueDate),
        ),
        const Spacer(),
        if (widget.task.time != null)
          _buildInfoChip(
            context,
            Icons.access_time_outlined,
            DateFormat.jm().format(widget.task.time!),
          ),
        const SizedBox(width: AppSpacing.s12),
        _buildPriorityChip(context, widget.task.priority),
      ],
    );
  }

  Widget _buildLabels(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.s8,
      runSpacing: AppSpacing.s4,
      children: widget.task.labels
          .map((label) => Chip(
        label: Text(label),
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8),
      ))
          .toList(),
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.s8),
        Text(text, style: theme.textTheme.bodyMedium),
      ],
    );
  }

  Widget _buildPriorityChip(BuildContext context, Priority priority) {
    final theme = Theme.of(context);
    final (backgroundColor, foregroundColor, label) = switch (priority) {
      Priority.high => (theme.colorScheme.errorContainer, theme.colorScheme.onErrorContainer, 'High'),
      Priority.medium => (theme.colorScheme.secondaryContainer, theme.colorScheme.onSecondaryContainer, 'Medium'),
      Priority.low => (theme.colorScheme.tertiaryContainer, theme.colorScheme.onTertiaryContainer, 'Low'),
    };

    return Chip(
      label: Text(label),
      labelStyle: theme.textTheme.labelSmall?.copyWith(
        color: foregroundColor,
        fontWeight: FontWeight.bold,
      ),
      backgroundColor: backgroundColor,
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8),
      visualDensity: VisualDensity.compact,
    );
  }
}
