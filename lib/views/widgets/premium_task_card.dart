// views/widgets/premium_task_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PremiumTaskCard extends StatelessWidget {
  final String title;
  final String description;
  final DateTime dueDate;
  final DateTime? time;
  final bool isCompleted;
  final String priority;
  final String status;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final ValueChanged<bool> onCompleted;
  final String? countdownText;

  const PremiumTaskCard({
    super.key,
    required this.title,
    required this.description,
    required this.dueDate,
    this.time,
    required this.isCompleted,
    required this.priority,
    required this.status,
    required this.onTap,
    required this.onDelete,
    required this.onCompleted,
    this.countdownText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.1)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCheckbox(context),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitle(context),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _buildDescription(context),
                    ],
                    const SizedBox(height: 12),
                    _buildMetadata(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckbox(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => onCompleted(!isCompleted),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: isCompleted ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isCompleted ? Colors.transparent : theme.colorScheme.outline,
            width: 2,
          ),
        ),
        child: isCompleted
            ? Icon(Icons.check_rounded, color: theme.colorScheme.onPrimary, size: 16)
            : null,
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        decoration: isCompleted ? TextDecoration.lineThrough : null,
        color: isCompleted ? theme.colorScheme.outline : theme.colorScheme.onSurface,
      ),
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

  Widget _buildMetadata(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _MetadataChip(
          icon: Icons.calendar_today_rounded,
          text: DateFormat.MMMd().format(dueDate),
        ),
        if (time != null)
          _MetadataChip(
            icon: Icons.access_time_rounded,
            text: DateFormat.jm().format(time!),
          ),
        _MetadataChip(
          icon: Icons.flag_rounded,
          text: priority,
          isEmphasized: true,
        ),
        if (countdownText != null)
          _MetadataChip(
            icon: Icons.timer_outlined,
            text: countdownText!,
            isEmphasized: true,
          ),
      ],
    );
  }
}

class _MetadataChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isEmphasized;

  const _MetadataChip({
    required this.icon,
    required this.text,
    this.isEmphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isEmphasized
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isEmphasized
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: isEmphasized ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}