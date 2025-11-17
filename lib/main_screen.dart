// main_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/view_model_providers.dart';

class MainScreen extends ConsumerStatefulWidget {
  final Widget child;

  const MainScreen({super.key, required this.child});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update the selected index when the route changes
    _updateSelectedIndexFromRoute();
  }

  void _updateSelectedIndexFromRoute() {
    final location = GoRouterState.of(context).uri.toString();
    debugPrint('MainScreen: Current route: $location');
    final newIndex = _getIndexFromRoute(location);

    if (newIndex != _selectedIndex) {
      setState(() {
        _selectedIndex = newIndex;
      });
      debugPrint('MainScreen: Selected index updated to: $_selectedIndex');
    }
  }

  int _getIndexFromRoute(String location) {
    if (location.startsWith('/questions')) return 1;
    if (location.startsWith('/upload')) return 2;
    if (location.startsWith('/tasks')) return 3;
    // Default to home
    return 0;
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    // This is the only place we navigate from here
    _navigateToRoute(index);
  }

  void _navigateToRoute(int index) {
    final routes = ['/', '/questions', '/upload', '/tasks'];
    if (index >= 0 && index < routes.length) {
      context.go(routes[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('MainScreen: Building with user guaranteed');

    return Scaffold(
      // FIXED: Add error boundary for the dashboard
      body: SafeArea(
        child: Column(
          children: [
            // Global error banner
            Consumer(
              builder: (context, ref, child) {
                final globalError = ref.watch(globalErrorProvider);

                if (globalError != null && globalError.isNotEmpty) {
                  return _buildErrorBanner(globalError, ref);
                }
                return const SizedBox.shrink();
              },
            ),
            // Main content
            Expanded(child: widget.child),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildErrorBanner(String error, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8.0),
      color: Colors.orangeAccent.withOpacity(0.1),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: Colors.orange[700], size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error.length > 100 ? '${error.substring(0, 100)}...' : error,
              style: TextStyle(color: Colors.orange[800], fontSize: 12),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 16, color: Colors.orange[700]),
            onPressed: () {
              ref.read(globalErrorProvider.notifier).state = null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    // Using Material 3 NavigationBar
    return NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: _onItemTapped,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.quiz_outlined),
          selectedIcon: Icon(Icons.quiz),
          label: 'Questions',
        ),
        NavigationDestination(
          icon: Icon(Icons.upload_outlined),
          selectedIcon: Icon(Icons.upload),
          label: 'Upload',
        ),
        NavigationDestination(
          icon: Icon(Icons.schedule_outlined),
          selectedIcon: Icon(Icons.schedule),
          label: 'Study Plan',
        ),
      ],
    );
  }
}