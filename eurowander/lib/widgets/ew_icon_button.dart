import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// A 42×42 icon button with surface background, subtle shadow, and rounded corners.
/// Replaces the repeated GestureDetector + Container pattern used for
/// back buttons, action buttons, etc.
///
/// Usage:
/// ```dart
/// EWIconButton(
///   icon: Icons.arrow_back_ios_new_rounded,
///   onTap: () => Navigator.pop(context),
/// )
/// ```
class EWIconButton extends StatelessWidget {
  const EWIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 42,
    this.iconSize = 18,
    this.iconColor,
    this.backgroundColor,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final Color? iconColor;
  final Color? backgroundColor;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final ew = context.ew;

    final button = Material(
      color: backgroundColor ?? ew.cardColor,
      borderRadius: AppRadius.borderMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderMd,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: AppRadius.borderMd,
            boxShadow: AppShadows.sm(Colors.black),
          ),
          child: Icon(
            icon,
            size: iconSize,
            color: iconColor ?? ew.textPrimary,
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}

/// Standard app bar row with back button, title, and optional trailing actions.
/// Replaces the repeated Padding + Row + back-button pattern.
class EWAppBar extends StatelessWidget {
  const EWAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.trailing,
  });

  final String title;
  final VoidCallback? onBack;
  final List<Widget>? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          EWIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: onBack ?? () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailing != null) ...trailing!.expand((w) => [
            const SizedBox(width: AppSpacing.xs),
            w,
          ]),
        ],
      ),
    );
  }
}
