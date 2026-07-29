import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Horizontal scrolling travel stats strip showing trip summary metrics.
/// Creates gamification and personal engagement.
class TravelStatsStrip extends StatelessWidget {
  const TravelStatsStrip({
    super.key,
    required this.totalTrips,
    required this.totalCountries,
    required this.totalPlaces,
    required this.totalNights,
  });

  final int totalTrips;
  final int totalCountries;
  final int totalPlaces;
  final int totalNights;

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatData(Icons.public_rounded, '$totalCountries', 'Destinations', const Color(0xFF3B82F6)),
      _StatData(Icons.flight_takeoff_rounded, '$totalTrips', 'Trips', AppColors.brandPrimary),
      _StatData(Icons.place_rounded, '$totalPlaces', 'Places', const Color(0xFFEC4899)),
      _StatData(Icons.nights_stay_rounded, '$totalNights', 'Nights', const Color(0xFFF59E0B)),
    ];

    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        itemCount: stats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) => TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 500 + (index * 100)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 12 * (1 - value)),
              child: child,
            ),
          ),
          child: _StatPill(data: stats[index]),
        ),
      ),
    );
  }
}

class _StatData {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _StatData(this.icon, this.value, this.label, this.color);
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.data});
  final _StatData data;

  @override
  Widget build(BuildContext context) {
    final ew = context.ew;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: ew.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: data.color.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: data.color.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: data.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icon, size: 18, color: data.color),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                data.value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: ew.textPrimary,
                ),
              ),
              Text(
                data.label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: ew.textTertiary,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
