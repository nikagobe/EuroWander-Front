import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// A shimmer loading skeleton placeholder.
/// Replaces generic `CircularProgressIndicator` with content-shaped placeholders.
///
/// Usage:
/// ```dart
/// // Single line placeholder
/// ShimmerBox(width: 120, height: 16)
///
/// // Card-shaped placeholder
/// ShimmerBox(width: double.infinity, height: 80, borderRadius: AppRadius.borderLg)
///
/// // Full-screen list loading
/// ShimmerList(itemCount: 5)
/// ```
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius,
  });

  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ew = context.ew;
    final baseColor = ew.cardColor;
    final highlightColor = ew.borderSubtle;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? AppRadius.borderSm,
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [
                (_animation.value - 0.3).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.3).clamp(0.0, 1.0),
              ],
              colors: [baseColor, highlightColor, baseColor],
            ),
          ),
        );
      },
    );
  }
}

/// A pre-built shimmer card skeleton matching the trip card layout.
class ShimmerCard extends StatelessWidget {
  const ShimmerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: context.ew.cardColor,
          borderRadius: AppRadius.borderXl,
        ),
        child: Row(
          children: [
            ShimmerBox(
              width: 48,
              height: 48,
              borderRadius: AppRadius.borderMd,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShimmerBox(width: 140, height: 14),
                  const SizedBox(height: AppSpacing.xs),
                  ShimmerBox(
                    width: 90,
                    height: 12,
                    borderRadius: AppRadius.borderSm,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A list of shimmer card skeletons for loading states.
class ShimmerList extends StatelessWidget {
  const ShimmerList({
    super.key,
    this.itemCount = 5,
    this.padding,
  });

  final int itemCount;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? AppSpacing.paddingHorizontalXl,
      child: Column(
        children: List.generate(
          itemCount,
          (_) => const ShimmerCard(),
        ),
      ),
    );
  }
}
