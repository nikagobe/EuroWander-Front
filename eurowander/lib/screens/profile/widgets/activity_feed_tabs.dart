import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/profile.dart';

class ActivityFeedTabs extends StatelessWidget {
  final ActivityFeed activityFeed;
  final bool isLoading;
  final void Function(String tripId)? onTripTap;

  const ActivityFeedTabs({
    super.key,
    required this.activityFeed,
    this.isLoading = false,
    this.onTripTap,
  });

  /// All trips combined and deduplicated
  List<ActivityTripSummary> get _allTrips {
    final all = [...activityFeed.recentCompleted, ...activityFeed.upcoming];
    final seen = <String>{};
    return all.where((t) => seen.add(t.tripId)).toList();
  }

  /// The effective date used to categorize a trip.
  /// Prefers startDate from API, falls back to createdAt.
  static DateTime _tripDate(ActivityTripSummary t) =>
      t.startDate ?? t.createdAt;

  /// Recent: trips whose effective date is today or in the past (including currently active)
  List<ActivityTripSummary> get _recentTrips {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final recent = _allTrips.where((t) {
      final date = _tripDate(t);
      return !date.isAfter(today);
    }).toList();
    recent.sort((a, b) => _tripDate(b).compareTo(_tripDate(a))); // newest first
    return recent;
  }

  /// Upcoming: trips whose effective date is in the future
  List<ActivityTripSummary> get _upcomingTrips {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final upcoming = _allTrips.where((t) {
      final date = _tripDate(t);
      return date.isAfter(today);
    }).toList();
    upcoming.sort((a, b) => _tripDate(a).compareTo(_tripDate(b))); // soonest first
    return upcoming;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Row(
              children: [
                Icon(
                  Icons.timeline_rounded,
                  size: 20,
                  color: AppColors.brandPrimary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'My Trips',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Tab bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.lightSurfaceVariant,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: TabBar(
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: AppColors.brandPrimary,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                boxShadow: AppShadows.sm(AppColors.brandPrimary),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.lightTextSecondary,
              labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              unselectedLabelStyle:
                  Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
              tabs: [
                Tab(
                  height: 36,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.history_rounded, size: 14),
                      const SizedBox(width: 4),
                      Text('Recent (${_recentTrips.length})'),
                    ],
                  ),
                ),
                Tab(
                  height: 36,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.upcoming_rounded, size: 14),
                      const SizedBox(width: 4),
                      Text('Upcoming (${_upcomingTrips.length})'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Tab views
          SizedBox(
            height: _calculateTabViewHeight(),
            child: TabBarView(
              children: [
                _buildTripList(
                  context,
                  _recentTrips,
                  'No recent trips yet',
                  'Complete a trip to see it here',
                  Icons.flight_land_rounded,
                ),
                _buildTripList(
                  context,
                  _upcomingTrips,
                  'No upcoming trips',
                  'Plan your next adventure!',
                  Icons.flight_takeoff_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _calculateTabViewHeight() {
    final recentCount = _recentTrips.length;
    final upcomingCount = _upcomingTrips.length;
    final maxCount =
        recentCount > upcomingCount ? recentCount : upcomingCount;
    if (maxCount == 0) return 140;
    return (maxCount * 88.0) + 16;
  }

  Widget _buildTripList(
    BuildContext context,
    List<ActivityTripSummary> trips,
    String emptyTitle,
    String emptySubtitle,
    IconData emptyIcon,
  ) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.brandPrimary,
          strokeWidth: 2,
        ),
      );
    }

    if (trips.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.brandPrimary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                emptyIcon,
                size: 32,
                color: AppColors.brandPrimary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              emptyTitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.lightTextPrimary,
                  ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              emptySubtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.lightTextTertiary,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      itemCount: trips.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
      itemBuilder: (context, index) {
        return _ActivityTripCard(
          trip: trips[index],
          onTap: () => onTripTap?.call(trips[index].tripId),
        );
      },
    );
  }
}

class _ActivityTripCard extends StatelessWidget {
  final ActivityTripSummary trip;
  final VoidCallback? onTap;

  const _ActivityTripCard({required this.trip, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            color: AppColors.lightSurface,
            border: Border.all(
              color: AppColors.lightBorder.withOpacity(0.4),
            ),
            boxShadow: AppShadows.sm(Colors.black),
          ),
          child: Row(
            children: [
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.name,
                      style:
                          Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.place_rounded,
                          size: 12,
                          color: AppColors.lightTextTertiary,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            trip.destination.isNotEmpty
                                ? trip.destination
                                : 'No destination set',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: AppColors.lightTextSecondary,
                                  fontSize: 11,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              // Date
              Text(
                trip.startDate != null
                    ? DateFormat('MMM d').format(trip.startDate!)
                    : DateFormat('MMM d').format(trip.createdAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: AppColors.lightTextTertiary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
