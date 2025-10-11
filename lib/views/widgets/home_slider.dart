import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/slider_model.dart';
import '../../viewmodels/home_viewmodel.dart';

/// A premium, customizable carousel slider widget for home screens.
///
/// This widget listens to a [HomeViewModel] to display a list of slider items.
/// It gracefully handles loading, error, and empty states.
class PremiumHomeSlider extends StatefulWidget {
  const PremiumHomeSlider({super.key});

  @override
  State<PremiumHomeSlider> createState() => _PremiumHomeSliderState();
}

class _PremiumHomeSliderState extends State<PremiumHomeSlider> {
  // Corrected the controller type to match the version used in the project.
  final CarouselSliderController _carouselController =
      CarouselSliderController();

  @override
  Widget build(BuildContext context) {
    // Use a Consumer to listen for changes in the HomeViewModel.
    return Consumer<HomeViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isInitializing && viewModel.sliderItems.isEmpty) {
          return _buildShimmerLoader();
        }

        if (viewModel.errorMessage != null && viewModel.sliderItems.isEmpty) {
          // Pass the viewModel to allow the retry button to function.
          return _buildErrorWidget(viewModel);
        }

        if (viewModel.sliderItems.isEmpty) {
          return const SizedBox.shrink(); // Don't show anything if there are no items.
        }

        return _buildSliderWithIndicators(viewModel);
      },
    );
  }

  /// Builds the main slider widget and its page indicators.
  Widget _buildSliderWithIndicators(HomeViewModel viewModel) {
    return Column(
      children: [
        CarouselSlider.builder(
          carouselController: _carouselController,
          itemCount: viewModel.sliderItems.length,
          itemBuilder: (context, index, realIndex) {
            final item = viewModel.sliderItems[index];
            return _buildSliderItem(item);
          },
          options: CarouselOptions(
            aspectRatio: 16 / 9,
            viewportFraction: 0.9,
            autoPlay: true,
            enlargeCenterPage: true,
            onPageChanged: (index, reason) {
              viewModel.updateSliderIndex(index);
            },
          ),
        ),
        // Only show indicators if there is more than one slide.
        if (viewModel.sliderItems.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: _buildCustomIndicators(
              itemCount: viewModel.sliderItems.length,
              currentIndex: viewModel.currentSliderIndex,
              onTap: (index) => _carouselController.animateToPage(index),
            ),
          ),
      ],
    );
  }

  /// Builds a single item for the carousel.
  Widget _buildSliderItem(SliderItem item) {
    return GestureDetector(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 0),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(12.0)),
          child: CachedNetworkImage(
            imageUrl: item.imageUrl,
            fit: BoxFit.cover,
            width: 1000.0,
            placeholder: (context, url) => _buildImagePlaceholder(),
            errorWidget: (context, url, error) => _buildImageError(),
          ),
        ),
      ),
    );
  }

  /// Builds the animated page indicators below the slider.
  Widget _buildCustomIndicators({
    required int itemCount,
    required int currentIndex,
    required ValueChanged<int> onTap,
  }) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(itemCount, (index) {
        final bool isSelected = currentIndex == index;
        return GestureDetector(
          onTap: () => onTap(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            width: isSelected ? 24.0 : 8.0,
            height: 8.0,
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withOpacity(0.3),
            ),
          ),
        );
      }),
    );
  }

  /// A shimmer placeholder for the slider while loading.
  Widget _buildShimmerLoader() {
    final theme = Theme.of(context);
    return Shimmer.fromColors(
      baseColor: theme.colorScheme.surfaceContainer,
      highlightColor: theme.colorScheme.surfaceContainerHighest,
      child: Container(
        // The aspect ratio should match the carousel options.
        height: MediaQuery.of(context).size.width / (16 / 9) * 0.9,
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// A placeholder for individual images while they are loading.
  Widget _buildImagePlaceholder() {
    final theme = Theme.of(context);
    return Shimmer.fromColors(
      baseColor: theme.colorScheme.surfaceContainer,
      highlightColor: theme.colorScheme.surfaceContainerHighest,
      child: Container(color: theme.colorScheme.surface),
    );
  }

  /// A widget to display when an image fails to load.
  Widget _buildImageError() {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surfaceContainer,
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          size: 40,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  /// A widget to display when there's an error fetching slider data.
  Widget _buildErrorWidget(HomeViewModel viewModel) {
    final theme = Theme.of(context);
    return Container(
      height: 180,
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 40,
              color: theme.colorScheme.onErrorContainer,
            ),
            const SizedBox(height: 12),
            Text(
              'Failed to Load Sliders',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: viewModel.refreshData,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
