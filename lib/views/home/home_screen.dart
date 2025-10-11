import 'dart:math';
import 'package:diuquestionbank/views/question/question_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/task_model.dart';
import '../../services/notification_service.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../profile/profile_screen.dart';
import '../task_manager/task_manager_screen.dart';
import '../widgets/home_slider.dart';
import 'department_secelction_screen.dart';
import 'search_screen.dart';

//==============================================================================
// Main Home Screen
//==============================================================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Defer initialization until after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<HomeViewModel>().init();
        _requestNotificationPermission();
      }
    });
  }

  /// Asynchronously requests notification permissions from the user.
  Future<void> _requestNotificationPermission() async {
    try {
      await NotificationService().requestPermissions();
    } catch (e) {
      debugPrint("Failed to request notification permission: $e");
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.background,
      body: Consumer<HomeViewModel>(
        builder: (context, viewModel, child) {
          // Check for errors first (using errorMessage instead of hasError)
          if (viewModel.errorMessage != null && !viewModel.isInitializing) {
            return _buildErrorState(viewModel);
          }

          // Display shimmer loading effect while data is being initialized
          if (viewModel.isInitializing) {
            return const _HomeScreenShimmer();
          }

          // If user hasn't selected a department, show selection screen
          if (viewModel.userDepartmentId == null ||
              viewModel.userDepartmentId!.isEmpty) {
            return const DepartmentSelectionScreen();
          }

          // Main content when initialized and department is selected
          return SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: () => viewModel.refreshData(),
              backgroundColor: colors.surfaceContainerHighest,
              color: colors.secondary,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  const SliverToBoxAdapter(child: _Header()),
                  const SliverToBoxAdapter(child: _SearchBar()),
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                  const SliverToBoxAdapter(child: PremiumHomeSlider()),
                  const SliverToBoxAdapter(child: SizedBox(height: 28)),
                  SliverToBoxAdapter(child: _StatsGrid(viewModel: viewModel)),
                  const SliverToBoxAdapter(child: _HowItWorksSection()),
                  _buildSection(
                    context,
                    title: 'Recent Questions',
                    actionText: 'View All',
                    onAction: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const QuestionScreen()),
                    ),
                    content: _RecentQuestionsList(viewModel: viewModel),
                  ),
                  _buildSection(
                    context,
                    title: 'My Study Plan',
                    actionText: 'Manage',
                    onAction: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const TaskManagerScreen()),
                    ),
                    content: _StudyPlanView(viewModel: viewModel),
                  ),
                  _buildSection(
                    context,
                    title: 'Daily Tip',
                    content: _DailyTipView(viewModel: viewModel),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Helper method to build section widgets consistently
  Widget _buildSection(
      BuildContext context, {
        required String title,
        String? actionText,
        VoidCallback? onAction,
        required Widget content,
      }) {
    return SliverToBoxAdapter(
      child: _Section(
        title: title,
        actionText: actionText,
        onAction: onAction,
        content: content,
      ),
    );
  }

  /// Builds error state for top-level errors
  Widget _buildErrorState(HomeViewModel viewModel) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                viewModel.errorMessage ?? 'An unexpected error occurred',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: viewModel.refreshData,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  // Force re-initialization
                  context.read<HomeViewModel>().init();
                },
                child: const Text('Restart App'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//==============================================================================
// Shimmer Placeholders
//==============================================================================

class _AppShimmer extends StatelessWidget {
  final Widget child;
  const _AppShimmer({required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: colors.surfaceContainerHighest,
      highlightColor: colors.outlineVariant,
      child: child,
    );
  }
}

class _HomeScreenShimmer extends StatelessWidget {
  const _HomeScreenShimmer();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SkeletonLoader(width: 120, height: 20),
                      SizedBox(height: 8),
                      _SkeletonLoader(width: 180, height: 28),
                    ],
                  ),
                  _SkeletonLoader(width: 50, height: 50, isCircle: true),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _SkeletonLoader(
                  width: double.infinity, height: 56, borderRadius: 30),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: _SkeletonLoader(
                  width: double.infinity, height: 180, borderRadius: 12),
            ),
          ),
          SliverToBoxAdapter(
            child: _ShimmerSection(
              child: GridView(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.8,
                ),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  _SkeletonLoader(height: 80, borderRadius: 12),
                  _SkeletonLoader(height: 80, borderRadius: 12),
                  _SkeletonLoader(height: 80, borderRadius: 12),
                  _SkeletonLoader(height: 80, borderRadius: 12),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: _ShimmerSection(
              child: _HorizontalListSkeleton(
                  itemWidth: 150, height: 180, spacing: 12),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

class _ShimmerSection extends StatelessWidget {
  final Widget child;
  const _ShimmerSection({required this.child});

  @override
  Widget build(BuildContext context) {
    return _AppShimmer(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SkeletonLoader(width: 150, height: 24),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _SkeletonLoader extends StatelessWidget {
  final double height;
  final double width;
  final double borderRadius;
  final bool isCircle;

  const _SkeletonLoader({
    this.height = 20,
    this.width = 200,
    this.borderRadius = 12.0,
    this.isCircle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: isCircle ? null : BorderRadius.circular(borderRadius),
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
      ),
    );
  }
}

class _HorizontalListSkeleton extends StatelessWidget {
  final int count;
  final double itemWidth;
  final double height;
  final double spacing;

  const _HorizontalListSkeleton({
    this.count = 3,
    required this.itemWidth,
    required this.height,
    this.spacing = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: count,
        itemBuilder: (context, index) => Padding(
          padding: EdgeInsets.only(right: spacing),
          child: _SkeletonLoader(
              height: height, width: itemWidth, borderRadius: 16),
        ),
      ),
    );
  }
}

//==============================================================================
// Primary UI Components
//==============================================================================

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Selector<HomeViewModel, (String, String?)>(
      selector: (context, vm) => (vm.userName, vm.profilePictureUrl),
      builder: (context, data, child) {
        final (userName, profilePictureUrl) = data;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: textTheme.titleMedium
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                    Text(
                      userName,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.onBackground,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ClickableAvatar(
                profilePictureUrl: profilePictureUrl,
                userName: userName,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SearchScreen()),
        ),
        child: AbsorbPointer(
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search past questions...',
              hintStyle: TextStyle(color: colors.onSurfaceVariant),
              prefixIcon: Icon(Icons.search, color: colors.onSurfaceVariant),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: colors.surfaceContainer,
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onAction;
  final Widget content;

  const _Section({
    required this.title,
    this.actionText,
    this.onAction,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final String? localActionText = actionText;

    return Padding(
      padding: const EdgeInsets.only(top: 28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (localActionText != null && onAction != null)
                  TextButton(
                    onPressed: onAction,
                    child: Text(
                      localActionText,
                      style: textTheme.labelLarge?.copyWith(
                        color: colors.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }
}

//==============================================================================
// Stats and How It Works Sections
//==============================================================================

class _StatsGrid extends StatelessWidget {
  final HomeViewModel viewModel;
  const _StatsGrid({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<({
    IconData icon,
    String value,
    String label,
    Color color,
    List<Color> gradient
    })> stats = [
      (
      icon: Icons.picture_as_pdf_outlined,
      value: '${viewModel.totalQuestions}+',
      label: 'PDF Questions',
      color: isDark ? const Color(0xFF4C6EF5) : const Color(0xFF4263EB),
      gradient: isDark
          ? [const Color(0xFF4C6EF5), const Color(0xFF3B5BDB)]
          : [const Color(0xFF4263EB), const Color(0xFF364FC7)]
      ),
      (
      icon: Icons.school_outlined,
      value: '${viewModel.totalCourses}+',
      label: 'Courses',
      color: isDark ? const Color(0xFF12B886) : const Color(0xFF0CA678),
      gradient: isDark
          ? [const Color(0xFF12B886), const Color(0xFF0CA678)]
          : [const Color(0xFF0CA678), const Color(0xFF099268)]
      ),
      (
      icon: Icons.corporate_fare_outlined,
      value: '${viewModel.totalDepartments}+',
      label: 'Departments',
      color: isDark ? const Color(0xFFFD7E14) : const Color(0xFFF76707),
      gradient: isDark
          ? [const Color(0xFFFD7E14), const Color(0xFFF76707)]
          : [const Color(0xFFF76707), const Color(0xFFE8590C)]
      ),
    ];

    return Container(
      margin: const EdgeInsets.only(top: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16.0, bottom: 20),
            child: Text(
              'Resources Overview',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
          ),
          SizedBox(
            height: 210,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding:
              const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
              itemCount: stats.length,
              separatorBuilder: (context, index) => const SizedBox(width: 20),
              itemBuilder: (context, index) {
                final stat = stats[index];
                return _StatCard(
                  icon: stat.icon,
                  value: stat.value,
                  label: stat.label,
                  color: stat.color,
                  gradient: stat.gradient,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatefulWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final List<Color> gradient;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.gradient,
  });

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _isHovered = false;

  void _handleHover(bool hover) {
    if (mounted) {
      setState(() {
        _isHovered = hover;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardShadow = _isHovered
        ? widget.color.withOpacity(0.4)
        : widget.color.withOpacity(0.2);
    final cardScale = _isHovered ? 1.03 : 1.0;
    final cardBorder = _isHovered
        ? Border.all(color: widget.color.withOpacity(0.3), width: 1)
        : null;

    return MouseRegion(
      onEnter: (_) => _handleHover(true),
      onExit: (_) => _handleHover(false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: 160,
        transform: Matrix4.identity()..scale(cardScale),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade900.withOpacity(0.6) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: cardBorder,
          boxShadow: [
            BoxShadow(
              color: cardShadow,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, color: Colors.white, size: 24),
              ),
              const Spacer(),
              Text(
                widget.value,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.onSurface,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.label,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HowItWorksSection extends StatelessWidget {
  const _HowItWorksSection();

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Simple & Easy',
      content: SizedBox(
        height: 150,
        child: ListView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          children: const [
            _StepCard(
              icon: Icons.upload_file_outlined,
              title: 'Upload PDF',
              description: 'Share your exam questions with relevant details.',
              step: '1',
            ),
            SizedBox(width: 12),
            _StepCard(
              icon: Icons.verified_user_outlined,
              title: 'Get Credit',
              description: 'Your contribution is recognized with your name.',
              step: '2',
            ),
            SizedBox(width: 12),
            _StepCard(
              icon: Icons.download_for_offline_outlined,
              title: 'Help Others',
              description:
              'Fellow students can easily find and download questions.',
              step: '3',
            ),
          ],
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String step;

  const _StepCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.step,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outline.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 32, color: colors.secondary),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: colors.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    step,
                    style: TextStyle(
                      color: colors.onSecondaryContainer,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

//==============================================================================
// Section Content Widgets
//==============================================================================

class _RecentQuestionsList extends StatelessWidget {
  final HomeViewModel viewModel;
  const _RecentQuestionsList({required this.viewModel});

  List<Color> _generateGradientColors(String seed) {
    final random = Random(seed.hashCode);
    final List<List<Color>> colorPairs = [
      [const Color(0xFF64B5F6), const Color(0xFF1976D2)],
      [const Color(0xFF81C784), const Color(0xFF388E3C)],
      [const Color(0xFFFFB74D), const Color(0xFFF57C00)],
      [const Color(0xFFBA68C8), const Color(0xFF7B1FA2)],
      [const Color(0xFF4DB6AC), const Color(0xFF00796B)],
      [const Color(0xFFF06292), const Color(0xFFC2185B)],
    ];
    return colorPairs[random.nextInt(colorPairs.length)];
  }

  @override
  Widget build(BuildContext context) {
    if (viewModel.isInitializing && viewModel.recentQuestions.isEmpty) {
      return const _AppShimmer(
        child: _HorizontalListSkeleton(itemWidth: 150, height: 180, spacing: 12),
      );
    }
    if (viewModel.errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: _ErrorMessage(
          message: viewModel.errorMessage!,
          onRetry: viewModel.refreshData,
        ),
      );
    }
    if (viewModel.recentQuestions.isEmpty) {
      return const _EmptyStateMessage(
        message: "No recent questions found.",
        height: 180,
        icon: Icons.search_off,
      );
    }
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: viewModel.recentQuestions.length,
        itemBuilder: (context, index) {
          final question = viewModel.recentQuestions[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: _QuestionCard(
              title: question.courseName,
              subtitle: question.examIdentifier,
              uploadDate: question.formattedDate,
              gradientColors: _generateGradientColors(question.id),
            ),
          );
        },
      ),
    );
  }
}

class _StudyPlanView extends StatelessWidget {
  final HomeViewModel viewModel;
  const _StudyPlanView({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: viewModel.isInitializing && viewModel.upcomingTasks.isEmpty
          ? const _AppShimmer(
        child: _SkeletonLoader(
            height: 88, width: double.infinity, borderRadius: 12),
      )
          : viewModel.errorMessage != null
          ? _ErrorMessage(
        message: viewModel.errorMessage!,
        onRetry: viewModel.refreshData,
      )
          : _StudyPlanCard(tasks: viewModel.upcomingTasks),
    );
  }
}

class _DailyTipView extends StatelessWidget {
  final HomeViewModel viewModel;
  const _DailyTipView({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: viewModel.isInitializing && viewModel.dailyTip == null
          ? const _AppShimmer(
        child: _SkeletonLoader(
            height: 90, width: double.infinity, borderRadius: 12),
      )
          : viewModel.errorMessage != null
          ? _ErrorMessage(
        message: viewModel.errorMessage!,
        onRetry: viewModel.refreshData,
      )
          : viewModel.dailyTip == null
          ? const _EmptyStateMessage(
        message: 'No tip available today.',
        height: 90,
      )
          : Card(
        elevation: 0,
        color: colors.surfaceContainer,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.lightbulb_outline,
                  color: colors.secondary, size: 30),
              const SizedBox(width: 16.0),
              Expanded(
                child: Text(
                  viewModel.dailyTip!.text,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//==============================================================================
// Reusable Display Cards
//==============================================================================

class _QuestionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String uploadDate;
  final List<Color> gradientColors;

  const _QuestionCard({
    required this.title,
    required this.subtitle,
    required this.uploadDate,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).primaryTextTheme;
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.0),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: textTheme.titleMedium,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subtitle,
                style: textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(uploadDate, style: textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _StudyPlanCard extends StatelessWidget {
  final List<Task> tasks;
  const _StudyPlanCard({required this.tasks});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final tasksToday = tasks.length;
    final hasTasks = tasks.isNotEmpty;
    return Card(
      elevation: 0,
      color: colors.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              hasTasks ? Icons.checklist_rtl_rounded : Icons.add_task_rounded,
              color: colors.secondary,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasTasks
                        ? "$tasksToday task${tasksToday == 1 ? '' : 's'} for today"
                        : "No tasks scheduled",
                    style: textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasTasks
                        ? "Next: ${tasks.first.title}"
                        : "Tap 'Manage' to add a new task.",
                    style: textTheme.bodyMedium
                        ?.copyWith(color: colors.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios,
                size: 16, color: colors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

//==============================================================================
// Helper Widgets
//==============================================================================

class _ErrorMessage extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const _ErrorMessage({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.errorContainer,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: colors.onErrorContainer,
              size: 32,
            ),
            const SizedBox(height: 12.0),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colors.onErrorContainer,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16.0),
              ElevatedButton.icon(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.error,
                  foregroundColor: colors.onError,
                ),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyStateMessage extends StatelessWidget {
  final String message;
  final double height;
  final IconData? icon;
  const _EmptyStateMessage({
    required this.message,
    required this.height,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 32, color: colors.onSurfaceVariant),
              const SizedBox(height: 8),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//==============================================================================
// ClickableAvatar Widget
//==============================================================================

class ClickableAvatar extends StatelessWidget {
  final String? profilePictureUrl;
  final String userName;
  final VoidCallback onTap;
  final double radius;
  final bool showBorder;

  const ClickableAvatar({
    super.key,
    required this.profilePictureUrl,
    required this.userName,
    required this.onTap,
    this.radius = 25,
    this.showBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = profilePictureUrl != null && profilePictureUrl!.isNotEmpty;

    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      splashColor: theme.colorScheme.primary.withOpacity(0.2),
      highlightColor: theme.colorScheme.primary.withOpacity(0.1),
      child: Container(
        decoration: showBorder
            ? BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: theme.colorScheme.primary,
            width: 2,
          ),
        )
            : null,
        child: CircleAvatar(
          radius: radius,
          backgroundColor: theme.colorScheme.secondaryContainer,
          child: hasImage
              ? ClipOval(
            child: Image.network(
              profilePictureUrl!,
              fit: BoxFit.cover,
              width: radius * 2,
              height: radius * 2,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return _buildFallbackAvatar(theme);
              },
              errorBuilder: (context, error, stackTrace) {
                return _buildFallbackAvatar(theme);
              },
            ),
          )
              : _buildFallbackAvatar(theme),
        ),
      ),
    );
  }

  Widget _buildFallbackAvatar(ThemeData theme) {
    return Text(
      _getInitials(userName),
      style: theme.textTheme.titleMedium?.copyWith(
        color: theme.colorScheme.onSecondaryContainer,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';

    final nameParts =
    name.trim().split(' ').where((part) => part.isNotEmpty).toList();
    if (nameParts.isEmpty) return '?';

    if (nameParts.length == 1) {
      return nameParts[0][0].toUpperCase();
    } else {
      return '${nameParts[0][0]}${nameParts.last[0]}'.toUpperCase();
    }
  }
}
