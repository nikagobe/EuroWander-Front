import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/profile.dart';

class BadgesSection extends StatelessWidget {
  final List<TravelBadge> badges;

  const BadgesSection({super.key, required this.badges});

  static const Map<String, IconData> _badgeIcons = {
    'first_trip': Icons.flight_takeoff_rounded,
    'countries_5': Icons.public_rounded,
    'countries_10': Icons.public_rounded,
    'countries_20': Icons.public_rounded,
    'frequent_flyer': Icons.airlines_rounded,
    'bus_explorer': Icons.directions_bus_rounded,
    'planner_pro': Icons.event_available_rounded,
    'collaborator': Icons.people_rounded,
  };

  static const Map<String, Color> _badgeColors = {
    'first_trip': AppColors.brandPrimary,
    'countries_5': Color(0xFF059669),
    'countries_10': Color(0xFF0891B2),
    'countries_20': Color(0xFF7C3AED),
    'frequent_flyer': AppColors.brandAmber,
    'bus_explorer': Color(0xFFDC2626),
    'planner_pro': Color(0xFF2563EB),
    'collaborator': AppColors.brandSecondary,
  };

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Text(
            'Badges',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 88,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            itemCount: badges.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final badge = badges[index];
              return _BadgeChip(
                badge: badge,
                icon: _badgeIcons[badge.badge] ?? Icons.star_rounded,
                color: _badgeColors[badge.badge] ?? AppColors.brandPrimary,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BadgeChip extends StatelessWidget {
  final TravelBadge badge;
  final IconData icon;
  final Color color;

  const _BadgeChip({
    required this.badge,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
        horizontal: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 6),
          Text(
            badge.label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
