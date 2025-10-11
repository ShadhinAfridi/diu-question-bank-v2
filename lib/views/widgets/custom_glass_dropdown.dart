import 'package:flutter/material.dart';

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
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isEnabled
                  ? Colors.white.withOpacity(0.3)
                  : Colors.white.withOpacity(0.2),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButton<T>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(), // Hides the default underline
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
                : const Icon(Icons.arrow_drop_down, color: Colors.white),
            hint: Text(
              isLoading
                  ? 'Loading...'
                  : (isEnabled ? hint : disabledHint ?? hint),
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
              // FIX 1: Add overflow handling to the hint text for safety.
              overflow: TextOverflow.ellipsis,
            ),
            // FIX 2: Use `selectedItemBuilder` for robust overflow handling of the *selected* item.
            // This widget is what's displayed on the button when it's closed.
            selectedItemBuilder: (context) {
              return items.map((item) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    displayText(item),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }).toList();
            },
            items: items.map((T item) {
              // This is the widget for the items in the dropdown list itself.
              return DropdownMenuItem<T>(
                value: item,
                child: Text(
                  displayText(item),
                  style: const TextStyle(color: Colors.white),
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