import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import 'edit_profile_screen.dart';
import 'user_profile_screen.dart';
import 'widgets/activity_feed_tabs.dart';
import 'widgets/badges_section.dart';
import 'widgets/bio_section.dart';
import 'widgets/collaborators_row.dart';
import 'widgets/stats_row.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    final provider = context.read<ProfileProvider>();
    await provider.fetchMyProfile(token: token);
    if (mounted) {
      await Future.wait([
        provider.fetchActivity(token: token),
        provider.fetchPhotoUrls(token: token),
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Consumer<ProfileProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading && provider.myProfile == null) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.brandPrimary,
                    strokeWidth: 2.5,
                  ),
                );
              }

              if (provider.error != null && provider.myProfile == null) {
                return _buildErrorState(provider.error!);
              }

              final profile = provider.myProfile;
              if (profile == null) {
                return _buildErrorState('Profile not available');
              }

              // Compute fallback stats from activity feed
              final effectiveStats = _computeEffectiveStats(
                profile.stats,
                provider.activityFeed,
              );

              return RefreshIndicator(
                color: AppColors.brandPrimary,
                onRefresh: _loadProfile,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    // Cover photo with overlaid back/edit buttons
                    SliverToBoxAdapter(
                      child: _buildCoverSection(profile, provider),
                    ),

                    // Profile info section
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Name
                            Text(
                              profile.profile.fullName.isNotEmpty
                                  ? profile.profile.fullName
                                  : 'Traveler',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                              textAlign: TextAlign.center,
                            ),
                            if (profile.profile.homeCity.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.xxs),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 14,
                                    color: AppColors.lightTextSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    profile.profile.homeCity,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppColors.lightTextSecondary,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Bio
                    if (profile.profile.bio.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.md),
                          child: BioSection(bio: profile.profile.bio),
                        ),
                      ),

                    // Travel style tags
                    if (profile.profile.travelStyleTags.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.md),
                          child: TravelTagsRow(
                            tags: profile.profile.travelStyleTags,
                          ),
                        ),
                      ),

                    // Stats
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          top: AppSpacing.xl,
                          left: AppSpacing.xl,
                          right: AppSpacing.xl,
                        ),
                        child: StatsRow(stats: effectiveStats),
                      ),
                    ),

                    // Badges
                    if (profile.badges.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xxl),
                          child: BadgesSection(badges: profile.badges),
                        ),
                      ),

                    // Collaborators
                    if (profile.collaborators.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xxl),
                          child: CollaboratorsRow(
                            collaborators: profile.collaborators,
                            onCollaboratorTap: _navigateToUserProfile,
                          ),
                        ),
                      ),

                    // Activity Feed
                    if (provider.activityFeed != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xxl),
                          child: ActivityFeedTabs(
                            activityFeed: provider.activityFeed!,
                            isLoading: provider.isActivityLoading,
                            onTripTap: _navigateToTrip,
                          ),
                        ),
                      ),

                    // Sign out button
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.xl,
                          AppSpacing.xxxl,
                          AppSpacing.xl,
                          AppSpacing.huge,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _handleLogout,
                            icon: const Icon(Icons.logout_rounded, size: 18),
                            label: const Text('Sign Out'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.lightTextSecondary,
                              side: BorderSide(
                                color: AppColors.lightBorder.withOpacity(0.6),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCoverSection(FullProfile profile, ProfileProvider provider) {
    final coverUrl = provider.coverPhotoUrl ?? profile.profile.coverPhotoUrl;
    final profileUrl =
        provider.profilePhotoUrl ?? profile.profile.profilePhotoUrl;
    final topPadding = MediaQuery.of(context).padding.top;
    final coverHeight = 200.0 + topPadding;
    const avatarOverflow = 40.0;

    return SizedBox(
      height: coverHeight + avatarOverflow,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Cover photo
          Container(
            height: coverHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.brandPrimary,
                  AppColors.brandSecondary.withOpacity(0.8),
                  AppColors.brandAccent.withOpacity(0.6),
                ],
              ),
            ),
            child: coverUrl.isNotEmpty
                ? Image.network(
                    coverUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildCoverGradientOverlay(),
                  )
                : _buildCoverGradientOverlay(),
          ),

          // Gradient scrim at bottom for smooth transition
          Positioned(
            bottom: avatarOverflow,
            left: 0,
            right: 0,
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Theme.of(context).colorScheme.surface.withOpacity(0.8),
                    Theme.of(context).colorScheme.surface,
                  ],
                ),
              ),
            ),
          ),

          // Back button
          Positioned(
            top: topPadding + AppSpacing.sm,
            left: AppSpacing.md,
            child: _buildFloatingButton(
              icon: Icons.arrow_back_rounded,
              onTap: () => Navigator.pop(context),
            ),
          ),

          // Edit button
          Positioned(
            top: topPadding + AppSpacing.sm,
            right: AppSpacing.md,
            child: _buildFloatingButton(
              icon: Icons.edit_outlined,
              onTap: () => _navigateToEdit(profile),
            ),
          ),

          // Avatar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.surface,
                    width: 4,
                  ),
                  boxShadow: AppShadows.lg(Colors.black),
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.lightSurfaceVariant,
                  backgroundImage:
                      profileUrl.isNotEmpty ? NetworkImage(profileUrl) : null,
                  child: profileUrl.isEmpty
                      ? Text(
                          _getInitials(profile.profile),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w600,
                            color: AppColors.brandPrimary,
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.black.withOpacity(0.3),
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 20, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildCoverGradientOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.brandPrimary.withOpacity(0.3),
            AppColors.brandSecondary.withOpacity(0.1),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.travel_explore_rounded,
          size: 48,
          color: Colors.white.withOpacity(0.3),
        ),
      ),
    );
  }

  String _getInitials(UserProfile profile) {
    final first = profile.firstName.isNotEmpty ? profile.firstName[0] : '';
    final last = profile.lastName.isNotEmpty ? profile.lastName[0] : '';
    return '$first$last'.toUpperCase();
  }

  /// Computes effective stats by using backend stats if they're non-zero,
  /// otherwise falls back to computing from activity feed data.
  TravelStats _computeEffectiveStats(
    TravelStats backendStats,
    ActivityFeed? activityFeed,
  ) {
    // If backend has meaningful data, use it
    if (backendStats.tripsCompleted > 0 || backendStats.citiesVisited.isNotEmpty) {
      return backendStats;
    }

    // Fallback: compute from activity feed
    if (activityFeed == null) return backendStats;

    final allTrips = [
      ...activityFeed.recentCompleted,
      ...activityFeed.upcoming,
    ];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final pastTrips = allTrips
        .where((t) => !(t.startDate ?? t.createdAt).isAfter(today))
        .toList();

    final destinations = allTrips
        .where((t) => t.destination.isNotEmpty)
        .map((t) => t.destination)
        .toSet()
        .toList();

    // Find most frequent destination
    String favoriteDestination = '';
    if (destinations.isNotEmpty) {
      final destCounts = <String, int>{};
      for (final trip in allTrips) {
        if (trip.destination.isNotEmpty) {
          destCounts[trip.destination] =
              (destCounts[trip.destination] ?? 0) + 1;
        }
      }
      favoriteDestination = destCounts.entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;
    }

    return TravelStats(
      tripsCompleted:
          pastTrips.isNotEmpty ? pastTrips.length : allTrips.length,
      citiesVisited: destinations,
      totalDistanceKm: backendStats.totalDistanceKm,
      favoriteDestination: favoriteDestination,
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.lightTextTertiary.withOpacity(0.5),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextButton(
              onPressed: _loadProfile,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToEdit(FullProfile profile) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(currentProfile: profile.profile),
      ),
    );
  }

  void _navigateToUserProfile(String userId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(userId: userId),
      ),
    );
  }

  void _navigateToTrip(String tripId) {
    // Navigate to existing trip detail screen
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      context.read<AuthProvider>().logout();
    }
  }
}
