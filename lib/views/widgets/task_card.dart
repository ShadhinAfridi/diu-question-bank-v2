// views/widgets/task_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TaskCard extends StatelessWidget {
  final String title;
  final String description;
  final DateTime dueDate;
  final DateTime? time;
  final bool isCompleted;
  final String priority;
  final List<String> labels;
  final ValueChanged<bool?> onCompleted;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final String? countdownText;

  const TaskCard({
    super.key,
    required this.title,
    required this.description,
    required this.dueDate,
    this.time,
    required this.isCompleted,
    required this.priority,
    required this.labels,
    required this.onCompleted,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.countdownText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildDescription(context),
              ],
              const SizedBox(height: 12),
              _buildFooter(context),
              if (labels.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildLabels(context),
              ],
              if (countdownText != null) ...[
                const SizedBox(height: 8),
                _buildCountdown(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: isCompleted,
          onChanged: onCompleted,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              decoration: isCompleted ? TextDecoration.lineThrough : null,
              color: isCompleted ? theme.colorScheme.outline : theme.colorScheme.onSurface,
            ),
          ),
        ),
        if (onEdit != null || onDelete != null) ...[
          PopupMenuButton(
            icon: Icon(Icons.more_vert_rounded, color: theme.colorScheme.outline),
            itemBuilder: (context) => [
              if (onEdit != null)
                PopupMenuItem(
                  child: const Text('Edit'),
                  onTap: onEdit,
                ),
              if (onDelete != null)
                PopupMenuItem(
                  child: Text(
                    'Delete',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  onTap: onDelete,
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDescription(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      description,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        decoration: isCompleted ? TextDecoration.lineThrough : null,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildFooter(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _InfoChip(
          icon: Icons.calendar_today_outlined,
          text: DateFormat.yMMMd().format(dueDate),
          color: theme.colorScheme.onSurfaceVariant,
        ),
        if (time != null)
          _InfoChip(
            icon: Icons.access_time_outlined,
            text: DateFormat.jm().format(time!),
            color: theme.colorScheme.onSurfaceVariant,
          ),
        _PriorityChip(priority: priority),
      ],
    );
  }

  Widget _buildLabels(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: labels.map((label) {
        return Chip(
          label: Text(label),
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
      }).toList(),
    );
  }

  Widget _buildCountdown(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerRight,
      child: Chip(
        avatar: Icon(Icons.timer_outlined, size: 16),
        label: Text(
          countdownText!,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
        ),
      ],
    );
  }
}

class _PriorityChip extends StatelessWidget {
  final String priority;

  const _PriorityChip({required this.priority});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (color, backgroundColor) = _getPriorityColors(priority, theme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        priority,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  (Color, Color) _getPriorityColors(String priority, ThemeData theme) {
    switch (priority.toLowerCase()) {
      case 'high':
        return (theme.colorScheme.onErrorContainer, theme.colorScheme.errorContainer);
      case 'medium':
        return (theme.colorScheme.onPrimaryContainer, theme.colorScheme.primaryContainer);
      case 'low':
        return (theme.colorScheme.onSecondaryContainer, theme.colorScheme.secondaryContainer);
      default:
        return (theme.colorScheme.onSurfaceVariant, theme.colorScheme.surfaceVariant);
    }
  }
}