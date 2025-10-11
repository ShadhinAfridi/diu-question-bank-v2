import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/task_model.dart';

/// A custom, premium-styled card widget for displaying a [Task].
///
/// This widget provides a rich visual representation of a task, including its
/// title, completion status, due date, and priority, with a modern and clean design.
/// It now includes a live countdown for upcoming and ongoing tasks.
class PremiumTaskCard extends StatefulWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final ValueChanged<bool> onCompleted;

  const PremiumTaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onDelete,
    required this.onCompleted,
  });

  @override
  State<PremiumTaskCard> createState() => _PremiumTaskCardState();
}

class _PremiumTaskCardState extends State<PremiumTaskCard> {
  Timer? _timer;
  String _remainingTime = '';

  @override
  void initState() {
    super.initState();
    _startTimerIfNeeded();
  }

  @override
  void didUpdateWidget(covariant PremiumTaskCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the task has changed, we might need to restart or stop the timer.
    if (widget.task.id != oldWidget.task.id ||
        widget.task.status != oldWidget.task.status ||
        widget.task.isCompleted != oldWidget.task.isCompleted) {
      _timer?.cancel();
      _startTimerIfNeeded();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimerIfNeeded() {
    // Only start a timer for tasks that are not yet completed and are either upcoming or ongoing.
    if (!widget.task.isCompleted &&
        (widget.task.status == TaskStatus.upcoming || widget.task.status == TaskStatus.ongoing)) {
      _updateRemainingTime(); // Set initial value immediately
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateRemainingTime());
    } else {
      // Ensure remaining time is cleared if no timer is needed
      if (mounted) {
        setState(() {
          _remainingTime = '';
        });
      }
    }
  }

  void _updateRemainingTime() {
    if (!mounted) {
      _timer?.cancel();
      return;
    }

    final now = DateTime.now();
    String newRemainingTime = '';
    bool shouldStopTimer = false;

    if (widget.task.status == TaskStatus.upcoming) {
      final scheduleTime = widget.task.time ?? widget.task.dueDate;
      if (scheduleTime.isAfter(now)) {
        final duration = scheduleTime.difference(now);
        newRemainingTime = '${_formatDuration(duration)} to start';
      } else {
        // This state is transient, as the ViewModel will soon update the status to 'ongoing'.
        newRemainingTime = 'Starting...';
      }
    } else if (widget.task.status == TaskStatus.ongoing) {
      final endOfDueDate = DateTime(widget.task.dueDate.year, widget.task.dueDate.month, widget.task.dueDate.day, 23, 59, 59);
      if (endOfDueDate.isAfter(now)) {
        final duration = endOfDueDate.difference(now);
        newRemainingTime = '${_formatDuration(duration)} left';
      } else {
        // This state is transient, as the ViewModel will soon update the status to 'completed'.
        newRemainingTime = 'Overdue';
        shouldStopTimer = true;
      }
    } else {
      // Task is completed or in a state that doesn't need a countdown.
      shouldStopTimer = true;
    }

    if (shouldStopTimer) {
      _timer?.cancel();
      newRemainingTime = ''; // Clear the text when timer stops
    }

    // Only call setState if the value has changed to avoid unnecessary rebuilds.
    if (_remainingTime != newRemainingTime) {
      setState(() {
        _remainingTime = newRemainingTime;
      });
    }
  }

  String _formatDuration(Duration d) {
    if (d.isNegative) return '...';

    final days = d.inDays;
    final hours = d.inHours.remainder(24);
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);

    if (days > 0) return '${days}d ${hours}h';
    if (hours > 0) return '${hours}h ${minutes}m';
    if (minutes > 0) return '${minutes}m ${seconds}s';
    if (seconds >= 0) return '${seconds}s';
    return '';
  }

  // Helper method to get the color associated with a task's priority.
  Color _getPriorityColor(BuildContext context, Priority priority) {
    switch (priority) {
      case Priority.high:
        return Colors.red.shade400;
      case Priority.medium:
        return Colors.orange.shade600;
      case Priority.low:
        return Colors.blue.shade500;
      default:
        return Theme.of(context).disabledColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final task = widget.task;
    final isCompleted = task.isCompleted;
    final priorityColor = _getPriorityColor(context, task.priority);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Custom Checkbox
              GestureDetector(
                onTap: () => widget.onCompleted(!isCompleted),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isCompleted ? priorityColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isCompleted ? Colors.transparent : theme.dividerColor,
                      width: 2,
                    ),
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              // Task Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                        color: isCompleted ? theme.disabledColor : null,
                      ),
                    ),
                    if (task.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        task.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isCompleted ? theme.disabledColor : null,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      runSpacing: 4.0,
                      children: [
                        // Date and Time info
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _InfoChip(
                              icon: Icons.calendar_today_rounded,
                              text: DateFormat.yMMMd().format(task.dueDate),
                              color: isCompleted ? theme.disabledColor : theme.colorScheme.onSurface,
                            ),
                            if (task.time != null) ...[
                              const SizedBox(width: 8),
                              _InfoChip(
                                icon: Icons.access_time_rounded,
                                text: DateFormat.jm().format(task.time!),
                                color: isCompleted ? theme.disabledColor : theme.colorScheme.onSurface,
                              ),
                            ],
                          ],
                        ),
                        // Status and Priority info
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_remainingTime.isNotEmpty)
                              _InfoChip(
                                icon: Icons.hourglass_top_rounded,
                                text: _remainingTime,
                                color: isCompleted ? theme.disabledColor : theme.colorScheme.primary,
                                isBold: true,
                              ),
                            if (_remainingTime.isNotEmpty) const SizedBox(width: 8),
                            _InfoChip(
                              icon: Icons.flag_rounded,
                              text: task.priority.displayName,
                              color: isCompleted ? theme.disabledColor : priorityColor,
                              isBold: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small, reusable chip for displaying task metadata like date or priority.
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final bool isBold;

  const _InfoChip({
    required this.icon,
    required this.text,
    required this.color,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

