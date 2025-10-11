import 'package:flutter/material.dart';

class PageIndicator extends StatelessWidget {
  final int pageCount;
  final int currentPage;

  const PageIndicator({
    super.key,
    required this.pageCount,
    required this.currentPage,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageCount, (index) {
        bool isSelected = index == currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: isSelected ? 28 : 10,
          height: 10,
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.onSurface.withOpacity(0.35),
            borderRadius: BorderRadius.circular(5),
          ),
        );
      }),
    );
  }
}
