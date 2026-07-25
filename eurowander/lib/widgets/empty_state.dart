import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// A designed empty state with icon, title, and optional subtitle + action button.
/// Replaces bare `Icon + Text` empty state patterns.
///
/// Usage:
/// ```dart
/// EmptyState(
///   icon: Icons.luggage_outlined,
///   title: 'No trips yet',
///   subtitle: 'Plan your first European adventure!',
///   actionLabel: 'Create Trip',
///   onAction: () => ...,
/// )
/// ```
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.iconColor,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ew = context.ew;
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: AppSpacing.paddingHorizontalXl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: compact ? 64 : 80,
              height: compact ? 64 : 80,
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.brandPrimary).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: compact ? 28 : 36,
                color: iconColor ?? ew.textTertiary,
              ),
            ),
            SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: ew.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: ew.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
