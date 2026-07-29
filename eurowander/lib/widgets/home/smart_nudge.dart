import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/saved_trip.dart';

/// Smart contextual nudge cards that appear based on the user's trip state.
/// e.g. "Your trip to Paris is in 5 days!", passport reminders, weather, etc.
class SmartNudges extends StatelessWidget {
  const SmartNudges({
    super.key,
    required this.trips,
    this.onTripTap,
  });

  final List<SavedTrip> trips;
  final void Function(SavedTrip trip)? onTripTap;

  @override
  Widget build(BuildContext context) {
    final nudges = _generateNudges(context);
    if (nudges.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        itemCount: nudges.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) => TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 400 + (index * 150)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.scale(
              scale: 0.9 + (0.1 * value),
              child: child,
            ),
          ),
          child: _NudgeCard(
            nudge: nudges[index],
            onTap: nudges[index].trip != null && onTripTap != null
                ? () => onTripTap!(nudges[index].trip!)
                : null,
          ),
        ),
      ),
    );
  }

  List<_NudgeData> _generateNudges(BuildContext context) {
    final now = DateTime.now();
    final nudges = <_NudgeData>[];

    for (final trip in trips) {
      final depStr = trip.outboundFlight?.departureTime;
      if (depStr == null || depStr.isEmpty) continue;

      DateTime depDate;
      try {
        depDate = DateTime.parse(depStr.replaceAll(' ', 'T'));
      } catch (_) {
        continue;
      }

      final daysUntil = depDate.difference(now).inDays;
      final destination = trip.outboundFlight?.arrivalCityName ?? '';

      // Active trip nudge
      final retStr = trip.returnFlight?.arrivalTime;
      DateTime? retDate;
      if (retStr != null && retStr.isNotEmpty) {
        try {
          retDate = DateTime.parse(retStr.replaceAll(' ', 'T'));
        } catch (_) {}
      }

      final endDate = retDate ?? depDate.add(const Duration(days: 7));
      final isActive = !depDate.isAfter(now) && endDate.isAfter(now);

      if (isActive) {
        final daysLeft = endDate.difference(now).inDays;
        nudges.add(_NudgeData(
          icon: Icons.sunny,
          title: 'Enjoying ${destination.isNotEmpty ? destination : "your trip"}!',
          subtitle: daysLeft > 0 ? '$daysLeft days remaining' : 'Last day — make it count!',
          gradient: const [Color(0xFFFF9800), Color(0xFFFFC107)],
          trip: trip,
        ));
      } else if (daysUntil >= 0 && daysUntil <= 7) {
        // Trip within a week
        nudges.add(_NudgeData(
          icon: Icons.flight_takeoff_rounded,
          title: destination.isNotEmpty ? '$destination in $daysUntil days!' : 'Trip in $daysUntil days!',
          subtitle: 'Departing ${DateFormat('EEEE, MMM d').format(depDate)}',
          gradient: const [Color(0xFF6C3CE0), Color(0xFF8B5CF6)],
          trip: trip,
        ));
      } else if (daysUntil > 7 && daysUntil <= 30) {
        // Trip within a month
        nudges.add(_NudgeData(
          icon: Icons.event_rounded,
          title: '${destination.isNotEmpty ? destination : "Trip"} in $daysUntil days',
          subtitle: 'Start planning your itinerary',
          gradient: const [Color(0xFF10B981), Color(0xFF34D399)],
          trip: trip,
        ));
      }

      if (nudges.length >= 3) break; // Limit nudges
    }

    // Always add an inspiration nudge if we have space
    if (nudges.length < 3) {
      final hour = now.hour;
      if (hour >= 20 || hour < 6) {
        nudges.add(const _NudgeData(
          icon: Icons.auto_awesome,
          title: 'Dream your next trip',
          subtitle: 'Browse templates for inspiration',
          gradient: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
        ));
      } else {
        nudges.add(const _NudgeData(
          icon: Icons.explore_rounded,
          title: 'Discover new places',
          subtitle: 'Explore community playlists',
          gradient: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
        ));
      }
    }

    return nudges;
  }
}

class _NudgeData {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final SavedTrip? trip;

  const _NudgeData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    this.trip,
  });
}

class _NudgeCard extends StatelessWidget {
  const _NudgeCard({required this.nudge, this.onTap});
  final _NudgeData nudge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      width: 260,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: nudge.gradient,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: nudge.gradient.first.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(nudge.icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  nudge.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  nudge.subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.85),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: Colors.white.withOpacity(0.6),
          ),
        ],
      ),
    ),
    );
  }
}
