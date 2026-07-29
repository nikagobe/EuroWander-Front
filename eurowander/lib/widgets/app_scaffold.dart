import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Scroll behavior that enables mouse-drag scrolling (needed for web).
class EWScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.trackpad,
  };
}

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

    Widget content = child;

    // Place FAB inside the constrained area so it aligns with content
    if (floatingActionButton != null) {
      content = Stack(
        children: [
          child,
          Positioned(
            right: 16,
            bottom: 16,
            child: floatingActionButton!,
          ),
        ],
      );
    }

    Widget body = Container(
      decoration: BoxDecoration(gradient: ew.surfaceGradient),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: content,
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
              child: content,
            ),
          ),
        ),
      );
    }

    return ScrollConfiguration(
      behavior: EWScrollBehavior(),
      child: Scaffold(
        body: body,
        bottomNavigationBar: bottomNavigationBar,
        backgroundColor: Colors.transparent,
      ),
    );
  }
}

/// For screens that need to use Scaffold directly (e.g. with SliverAppBar)
/// but still want consistent width constraints and scroll behavior.
/// Wrap the Scaffold's body in this.
class EWConstrainedBody extends StatelessWidget {
  const EWConstrainedBody({
    super.key,
    required this.child,
    this.maxWidth = 480,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final ew = context.ew;
    return ScrollConfiguration(
      behavior: EWScrollBehavior(),
      child: Container(
        decoration: BoxDecoration(gradient: ew.surfaceGradient),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: child,
          ),
        ),
      ),
    );
  }
}
