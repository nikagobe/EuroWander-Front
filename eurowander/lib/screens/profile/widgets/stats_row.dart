import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/profile.dart';

class StatsRow extends StatelessWidget {
  final TravelStats stats;

  const StatsRow({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.brandPrimary.withOpacity(0.05),
            AppColors.brandSecondary.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: AppColors.brandPrimary.withOpacity(0.12),
        ),
        boxShadow: AppShadows.sm(AppColors.brandPrimary),
      ),
      child: Row(
        children: [
          _StatTile(
            icon: Icons.flight_takeoff_rounded,
            value: stats.tripsCompleted.toString(),
            label: 'Trips',
            color: AppColors.brandPrimary,
          ),
          _buildDivider(),
          _StatTile(
            icon: Icons.location_city_rounded,
            value: stats.citiesCount.toString(),
            label: 'Cities',
            color: AppColors.brandSecondary,
          ),
          _buildDivider(),
          _StatTile(
            icon: Icons.straighten_rounded,
            value: _formatDistance(stats.totalDistanceKm),
            label: 'km',
            color: AppColors.success,
          ),
          _buildDivider(),
          _StatTile(
            icon: Icons.favorite_rounded,
            value: stats.favoriteDestination.isNotEmpty
                ? stats.favoriteDestination
                : '--',
            label: 'Favorite',
            color: AppColors.error,
            isText: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            AppColors.lightBorder.withOpacity(0.5),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  String _formatDistance(double km) {
    if (km >= 1000) {
      return '${(km / 1000).toStringAsFixed(1)}k';
    }
    if (km == 0) return '0';
    return km.toInt().toString();
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool isText;

  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.isText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: isText ? 11 : 16,
                  color: AppColors.lightTextPrimary,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.lightTextTertiary,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}
