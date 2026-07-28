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

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Text(
              'Activity',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Tab bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.lightSurfaceVariant,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: TabBar(
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: AppColors.brandPrimary,
                borderRadius: BorderRadius.circular(AppRadius.md),
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
              tabs: const [
                Tab(text: 'Recent', height: 36),
                Tab(text: 'Upcoming', height: 36),
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
                  activityFeed.recentCompleted,
                  'No recent trips yet',
                ),
                _buildTripList(
                  context,
                  activityFeed.upcoming,
                  'No upcoming trips',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _calculateTabViewHeight() {
    final recentCount = activityFeed.recentCompleted.length;
    final upcomingCount = activityFeed.upcoming.length;
    final maxCount =
        recentCount > upcomingCount ? recentCount : upcomingCount;
    if (maxCount == 0) return 120;
    return (maxCount * 84.0) + 16;
  }

  Widget _buildTripList(
    BuildContext context,
    List<ActivityTripSummary> trips,
    String emptyMessage,
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
            Icon(
              Icons.luggage_outlined,
              size: 36,
              color: AppColors.lightTextTertiary.withOpacity(0.5),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              emptyMessage,
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
      color: AppColors.lightSurface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: AppColors.lightBorder.withOpacity(0.5),
            ),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getStatusColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  _getStatusIcon(),
                  size: 20,
                  color: _getStatusColor(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
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
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.place_outlined,
                          size: 12,
                          color: AppColors.lightTextTertiary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            trip.destination,
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
              // Date & status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    DateFormat('MMM d').format(trip.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: AppColors.lightTextTertiary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      _getStatusLabel(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (trip.status.toLowerCase()) {
      case 'completed':
        return AppColors.success;
      case 'active':
      case 'in_progress':
        return AppColors.brandPrimary;
      case 'upcoming':
      case 'planned':
        return AppColors.brandAmber;
      default:
        return AppColors.lightTextSecondary;
    }
  }

  IconData _getStatusIcon() {
    switch (trip.status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle_outline_rounded;
      case 'active':
      case 'in_progress':
        return Icons.flight_rounded;
      case 'upcoming':
      case 'planned':
        return Icons.schedule_rounded;
      default:
        return Icons.trip_origin_rounded;
    }
  }

  String _getStatusLabel() {
    return trip.status.replaceAll('_', ' ').toUpperCase();
  }
}
