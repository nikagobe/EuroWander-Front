import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// A full-width gradient CTA button with glow shadow.
/// Replaces the repeated GestureDetector + gradient Container pattern.
///
/// Usage:
/// ```dart
/// GradientButton(
///   label: 'Plan New Trip',
///   icon: Icons.add_circle_outline_rounded,
///   onTap: () => ...,
/// )
/// ```
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.gradient,
    this.height = 56,
    this.borderRadius,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final LinearGradient? gradient;
  final double height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppRadius.borderXl;

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Ink(
          height: height,
          decoration: BoxDecoration(
            gradient: gradient ?? AppColors.primaryGradient,
            borderRadius: radius,
            boxShadow: AppShadows.glow(AppColors.brandPrimary),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A secondary outlined button for less prominent actions.
///
/// Usage:
/// ```dart
/// OutlineActionButton(
///   label: 'Playlists',
///   icon: Icons.explore_rounded,
///   color: AppColors.brandPrimary,
///   onTap: () => ...,
/// )
/// ```
class OutlineActionButton extends StatelessWidget {
  const OutlineActionButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.color,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ew = context.ew;
    final effectiveColor = color ?? AppColors.brandPrimary;

    return Material(
      color: ew.cardColor,
      borderRadius: AppRadius.borderMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderMd,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
          decoration: BoxDecoration(
            borderRadius: AppRadius.borderMd,
            border: Border.all(color: effectiveColor.withOpacity(0.25)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: effectiveColor, size: 18),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: effectiveColor,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
