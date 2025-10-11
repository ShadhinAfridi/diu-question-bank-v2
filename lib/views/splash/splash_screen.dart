import 'package:diuquestionbank/auth_wrapper.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.elasticOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuad,
    ));

    _controller.forward();

    // Precache potential assets for AuthWrapper
    Future.delayed(const Duration(milliseconds: 500), () {
      precacheImage(const AssetImage('assets/auth_background.png'), context);
    });

    // Navigate after animation completes
    Timer(
      const Duration(seconds: 3),
          () => _navigateToAuth(context),
    );
  }

  Future<void> _navigateToAuth(BuildContext context) async {
    // Wait for the animation to complete if it's still running
    if (_controller.isAnimating) {
      await _controller.duration;
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const AuthWrapper(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutQuart;

          var tween = Tween(begin: begin, end: end)
              .chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      body: Stack(
        children: [
          // Background gradient with subtle animation
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                      Colors.blueGrey[900]!,
                      Colors.black,
                      Colors.blueGrey[900]!,
                    ]
                        : [
                      Colors.blue[50]!,
                      Colors.white,
                      Colors.blue[50]!,
                    ],
                    stops: [0.0, _controller.value, 1.0],
                  ),
                ),
              );
            },
          ),

          // Animated content
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _opacityAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Premium icon with gradient and shadow
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  theme.colorScheme.primary,
                                  theme.colorScheme.secondary,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.primary
                                      .withOpacity(0.4),
                                  blurRadius: 20 * _controller.value,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/splash_logo.png',
                              width: 80,
                              height: 80,
                            ),
                          ),

                          const SizedBox(height: 30),

                          // App name with elegant typography
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'DIU ',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w300,
                                    color: theme.colorScheme.primary,
                                    fontFamily: 'Montserrat',
                                  ),
                                ),
                                TextSpan(
                                  text: 'Question Bank',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                    color: theme.colorScheme.primary,
                                    fontFamily: 'Montserrat',
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Tagline with fade-in effect
                          Opacity(
                            opacity: _controller.value > 0.5 ? 1.0 : 0.0,
                            child: Text(
                              'Premium Academic Resources',
                              style: TextStyle(
                                fontSize: 14,
                                color: theme.colorScheme.secondary,
                                letterSpacing: 1.2,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                          ),

                          const SizedBox(height: 50),

                          // Custom progress indicator with growing width
                          SizedBox(
                            width: 100 + (50 * _controller.value),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                minHeight: 8,
                                backgroundColor:
                                isDark ? Colors.grey[800] : Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.colorScheme.primary,
                                ),
                                value: _controller.value > 0.7
                                    ? 1.0
                                    : _controller.value / 0.7,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Footer with delayed appearance
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: _controller.value > 0.7 ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Center(
                child: Text(
                  'Daffodil International University',
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 12,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}