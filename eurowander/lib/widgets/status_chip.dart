import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// A pill-shaped chip for displaying status, category, or metadata.
///
/// Usage:
/// ```dart
/// StatusChip(label: '3 days', icon: Icons.calendar_today)
/// StatusChip(label: 'Budget', color: AppColors.budget)
/// StatusChip.travel(category: TravelCategory.flight, label: 'Direct')
/// ```
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.backgroundColor,
    this.onTap,
  });

  final String label;
  final IconData? icon;
  final Color? color;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  /// Convenience factory for travel category chips.
  factory StatusChip.travel({
    Key? key,
    required TravelCategory category,
    required String label,
    VoidCallback? onTap,
  }) {
    return StatusChip(
      key: key,
      label: label,
      icon: category.icon,
      color: category.color,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.brandPrimary;
    final bgColor = backgroundColor ?? effectiveColor.withOpacity(0.10);

    final chip = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs + 2,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.borderPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: effectiveColor),
            const SizedBox(width: AppSpacing.xxs + 2),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: effectiveColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: chip);
    }
    return chip;
  }
}

/// Travel categories with associated colors and icons.
enum TravelCategory {
  flight(AppColors.flight, Icons.flight_rounded),
  hotel(AppColors.hotel, Icons.hotel_rounded),
  restaurant(AppColors.restaurant, Icons.restaurant_rounded),
  attraction(AppColors.attraction, Icons.place_rounded),
  transport(AppColors.transport, Icons.directions_bus_rounded),
  budget(AppColors.budget, Icons.account_balance_wallet_rounded);

  const TravelCategory(this.color, this.icon);
  final Color color;
  final IconData icon;
}
