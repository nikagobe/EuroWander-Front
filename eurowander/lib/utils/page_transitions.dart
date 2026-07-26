import 'package:flutter/material.dart';

/// Smooth page route with slide + fade transition.
/// Use instead of MaterialPageRoute for polished navigation.
///
/// ```dart
/// Navigator.push(context, EWPageRoute(page: MyScreen()));
/// ```
class EWPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  EWPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 350),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );

            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.08, 0),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation),
                child: child,
              ),
            );
          },
        );
}

/// Scale + fade transition for modal-like presentations.
class EWScaleRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  EWScaleRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
              reverseCurve: Curves.easeInCubic,
            );

            return ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1.0).animate(curvedAnimation),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOut),
                ),
                child: child,
              ),
            );
          },
        );
}

/// A staggered animation helper for lists.
/// Wraps a child with a delayed slide+fade animation.
class StaggeredItem extends StatelessWidget {
  final int index;
  final Widget child;
  final Duration baseDelay;
  final Duration duration;

  const StaggeredItem({
    super.key,
    required this.index,
    required this.child,
    this.baseDelay = const Duration(milliseconds: 80),
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration + baseDelay * index,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
