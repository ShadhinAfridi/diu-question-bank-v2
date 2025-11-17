// views/widgets/home_slider.dart
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class PremiumHomeSlider extends StatelessWidget {
  final List<String> imageUrls;
  final ValueChanged<int>? onPageChanged;
  final int currentIndex;

  const PremiumHomeSlider({
    super.key,
    required this.imageUrls,
    this.onPageChanged,
    this.currentIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (imageUrls.isEmpty) {
      return _buildPlaceholder(theme);
    }

    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: imageUrls.length,
          itemBuilder: (context, index, realIndex) {
            return _buildSliderItem(imageUrls[index], theme);
          },
          options: CarouselOptions(
            aspectRatio: 16 / 9,
            viewportFraction: 0.9,
            autoPlay: true,
            enlargeCenterPage: true,
            onPageChanged: (index, reason) {
              onPageChanged?.call(index);
            },
          ),
        ),
        if (imageUrls.length > 1) ...[
          const SizedBox(height: 12),
          _buildIndicators(imageUrls.length, currentIndex, theme),
        ],
      ],
    );
  }

  Widget _buildSliderItem(String imageUrl, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surfaceContainer,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildErrorState(theme);
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildLoadingState(theme);
          },
        ),
      ),
    );
  }

  Widget _buildIndicators(int count, int currentIndex, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isSelected = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isSelected ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Icon(
          Icons.photo_library_outlined,
          size: 48,
          color: theme.colorScheme.outline,
        ),
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainer,
      child: Center(
        child: CircularProgressIndicator(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainer,
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          size: 48,
          color: theme.colorScheme.outline,
        ),
      ),
    );
  }
}