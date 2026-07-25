import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// A styled card container replacing inline `Container(decoration: BoxDecoration(...))`.
///
/// Supports optional colored left accent border, icon leading, and
/// customizable padding/radius.
///
/// Usage:
/// ```dart
/// EWCard(
///   child: Text('Hello'),
/// )
///
/// EWCard(
///   accentColor: AppColors.flight,
///   child: Row(...),
/// )
/// ```
class EWCard extends StatelessWidget {
  const EWCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.accentColor,
    this.backgroundColor,
    this.borderRadius,
    this.shadow = EWCardShadow.md,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? accentColor;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final EWCardShadow shadow;

  @override
  Widget build(BuildContext context) {
    final ew = context.ew;
    final radius = borderRadius ?? AppRadius.borderXl;
    final bgColor = backgroundColor ?? ew.cardColor;

    final List<BoxShadow> boxShadow = switch (shadow) {
      EWCardShadow.none => [],
      EWCardShadow.sm => AppShadows.sm(AppColors.brandPrimary),
      EWCardShadow.md => AppShadows.md(AppColors.brandPrimary),
      EWCardShadow.lg => AppShadows.lg(AppColors.brandPrimary),
    };

    Widget content = Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.md),
      margin: margin,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: radius,
        boxShadow: boxShadow,
        border: accentColor != null
            ? Border(left: BorderSide(color: accentColor!, width: 3))
            : null,
      ),
      child: child,
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: content,
        ),
      );
    }

    return content;
  }
}

enum EWCardShadow { none, sm, md, lg }
