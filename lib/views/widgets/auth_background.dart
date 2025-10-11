// lib/src/ui/widgets/auth_background.dart

import 'package:flutter/material.dart';
import 'dart:ui';

class AuthBackground extends StatelessWidget {
  final Widget child;
  final bool showBackButton;

  const AuthBackground({
    Key? key,
    required this.child,
    this.showBackButton = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/auth_background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.black.withOpacity(0.4)
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: showBackButton
                    ? IconButton(
                  icon: Icon(Icons.arrow_back, color: colorScheme.onPrimary),
                  onPressed: () => Navigator.of(context).pop(),
                )
                    : null,
              ),
              body: SafeArea(
                child: Center(
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
