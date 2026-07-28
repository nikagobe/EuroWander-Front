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
import 'widgets/profile_header.dart';
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
    final ew = context.ew;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: AppColors.lightTextPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Profile',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        centerTitle: true,
      ),
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

          return RefreshIndicator(
            color: AppColors.brandPrimary,
            onRefresh: _loadProfile,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.md),
                    // Header with cover + avatar
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md),
                      child: ProfileHeader(
                        profile: profile.profile,
                        showEditButton: true,
                        onEditTap: () => _navigateToEdit(profile),
                        resolvedProfilePhotoUrl: provider.profilePhotoUrl,
                        resolvedCoverPhotoUrl: provider.coverPhotoUrl,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Bio
                    BioSection(bio: profile.profile.bio),
                    if (profile.profile.bio.isNotEmpty)
                      const SizedBox(height: AppSpacing.md),

                    // Travel style tags
                    TravelTagsRow(tags: profile.profile.travelStyleTags),
                    if (profile.profile.travelStyleTags.isNotEmpty)
                      const SizedBox(height: AppSpacing.xl),

                    // Stats
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl),
                      child: StatsRow(stats: profile.stats),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // Badges
                    BadgesSection(badges: profile.badges),
                    if (profile.badges.isNotEmpty)
                      const SizedBox(height: AppSpacing.xxl),

                    // Collaborators
                    CollaboratorsRow(
                      collaborators: profile.collaborators,
                      onCollaboratorTap: _navigateToUserProfile,
                    ),
                    if (profile.collaborators.isNotEmpty)
                      const SizedBox(height: AppSpacing.xxl),

                    // Activity Feed
                    if (provider.activityFeed != null)
                      ActivityFeedTabs(
                        activityFeed: provider.activityFeed!,
                        isLoading: provider.isActivityLoading,
                        onTripTap: _navigateToTrip,
                      ),

                    const SizedBox(height: AppSpacing.xxxl),

                    // Logout button
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _handleLogout,
                          icon: const Icon(Icons.logout_rounded, size: 18),
                          label: const Text('Sign Out'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.lightTextSecondary,
                            side: BorderSide(
                              color:
                                  AppColors.lightBorder.withOpacity(0.6),
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
                    const SizedBox(height: AppSpacing.huge),
                  ],
              ),
            ),
          );
        },
      ),
          ),
        ),
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
