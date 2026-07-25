import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// A consistent section header with title and optional trailing action.
///
/// Usage:
/// ```dart
/// SectionHeader(title: 'My Trips')
/// SectionHeader(
///   title: 'ITINERARY',
///   uppercase: true,
///   trailing: TextButton(onPressed: ..., child: Text('See All')),
/// )
/// ```
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.uppercase = false,
    this.padding,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool uppercase;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayTitle = uppercase ? title.toUpperCase() : title;

    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayTitle,
                  style: uppercase
                      ? theme.textTheme.labelMedium?.copyWith(
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w700,
                          color: context.ew.textTertiary,
                        )
                      : theme.textTheme.headlineMedium,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
