import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Replaces the repeated pattern of:
/// ```dart
/// Scaffold(
///   body: Container(
///     decoration: BoxDecoration(gradient: surfaceGradient),
///     child: SafeArea(
///       child: Center(
///         child: ConstrainedBox(
///           constraints: BoxConstraints(maxWidth: 480),
/// ```
///
/// Usage:
/// ```dart
/// AppScaffold(
///   child: Column(...),
/// )
/// ```
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.child,
    this.maxWidth = 480,
    this.useSafeArea = true,
    this.floatingActionButton,
    this.bottomNavigationBar,
  });

  final Widget child;
  final double maxWidth;
  final bool useSafeArea;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    final ew = context.ew;

    Widget body = Container(
      decoration: BoxDecoration(gradient: ew.surfaceGradient),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    );

    if (useSafeArea) {
      body = Container(
        decoration: BoxDecoration(gradient: ew.surfaceGradient),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: child,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      backgroundColor: Colors.transparent,
    );
  }
}
