import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomGlassDropdown<T> extends StatelessWidget {
  final T? value;
  final String label;
  final String hint;
  final List<T> items;
  final String Function(T) displayText;
  final void Function(T?)? onChanged;
  final bool isLoading;
  final Color dropdownColor;
  final String? disabledHint;

  const CustomGlassDropdown({
    super.key,
    required this.value,
    required this.label,
    required this.hint,
    required this.items,
    required this.displayText,
    required this.onChanged,
    this.isLoading = false,
    this.dropdownColor = const Color(0xFF0A2463),
    this.disabledHint,
  });

  @override
  Widget build(BuildContext context) {
    bool isEnabled = onChanged != null && !isLoading;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14),
        ),
        const SizedBox(height: AppSpacing.s8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isEnabled
                  ? Colors.white.withOpacity(0.4)
                  : Colors.white.withOpacity(0.25),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: DropdownButton<T>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: dropdownColor,
            icon: isLoading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Icon(Icons.arrow_drop_down_rounded,
                color: Colors.white),
            hint: Text(
              isLoading
                  ? 'Loading...'
                  : (isEnabled ? hint : disabledHint ?? hint),
              style: TextStyle(color: Colors.white.withOpacity(0.75)),
            ),
            items: items.map((T item) {
              return DropdownMenuItem<T>(
                value: item,
                child: Text(
                  displayText(item),
                  style: const TextStyle(color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: isEnabled ? onChanged : null,
          ),
        ),
      ],
    );
  }
}
