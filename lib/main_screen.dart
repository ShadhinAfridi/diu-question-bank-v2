import 'package:animations/animations.dart';
import 'package:diuquestionbank/views/question/question_screen.dart';
import 'package:diuquestionbank/views/task_manager/task_manager_screen.dart';
import 'package:flutter/material.dart';
import './views/home/home_screen.dart';
import './views/upload/question_upload_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late List<AnimationController> _animationControllers;
  late List<Animation<double>> _animations;

  static final List<Widget> _pages = <Widget>[
    const HomeScreen(key: ValueKey('HomeScreen')),
    const QuestionScreen(key: ValueKey('QuestionScreen')),
    const QuestionUploadScreen(key: ValueKey('QuestionUploadScreen')),
    const TaskManagerScreen(key: ValueKey('TaskManagerScreen')),
  ];

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers for each tab
    _animationControllers = List.generate(
      _pages.length,
          (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      ),
    );

    _animations = _animationControllers.map(
          (controller) => Tween<double>(begin: 0.9, end: 1.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeOut,
        ),
      ),
    ).toList();

    // Start animation for initial tab
    _animationControllers[_selectedIndex].forward();
  }

  @override
  void dispose() {
    for (var controller in _animationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    // Reverse previous animation
    _animationControllers[_selectedIndex].reverse();

    setState(() {
      _selectedIndex = index;
    });

    // Start new animation
    _animationControllers[index].forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageTransitionSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
          return SharedAxisTransition(
            animation: primaryAnimation,
            secondaryAnimation: secondaryAnimation,
            transitionType: SharedAxisTransitionType.horizontal,
            child: child,
          );
        },
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: _SmartBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        animations: _animations,
      ),
    );
  }
}

class _SmartBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<Animation<double>> animations;

  const _SmartBottomNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.animations,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: [
        _buildNavItem(
          icon: Icons.home_outlined,
          activeIcon: Icons.home,
          label: 'Home',
          index: 0,
        ),
        _buildNavItem(
          icon: Icons.quiz_outlined,
          activeIcon: Icons.quiz,
          label: 'Question',
          index: 1,
        ),
        _buildNavItem(
          icon: Icons.upload_outlined,
          activeIcon: Icons.upload,
          label: 'Upload',
          index: 2,
        ),
        _buildNavItem(
          icon: Icons.schedule_outlined,
          activeIcon: Icons.schedule,
          label: 'Study Plan',
          index: 3,
        ),
      ],
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Theme.of(context).colorScheme.secondary,
      unselectedItemColor: Theme.of(context).textTheme.bodySmall?.color,
      showUnselectedLabels: true,
    );
  }

  BottomNavigationBarItem _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    return BottomNavigationBarItem(
      icon: ScaleTransition(
        scale: animations[index],
        child: Icon(icon),
      ),
      activeIcon: ScaleTransition(
        scale: animations[index],
        child: Icon(activeIcon),
      ),
      label: label,
    );
  }
}