import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import 'widgets/activity_feed_tabs.dart';
import 'widgets/badges_section.dart';
import 'widgets/bio_section.dart';
import 'widgets/collaborators_row.dart';
import 'widgets/profile_header.dart';
import 'widgets/stats_row.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    await context.read<ProfileProvider>().fetchUserProfile(
          token: token,
          userId: widget.userId,
        );
  }

  @override
  void dispose() {
    // Don't clear in dispose to avoid rebuild issues
    super.dispose();
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
          if (provider.isLoading && provider.viewedProfile == null) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.brandPrimary,
                strokeWidth: 2.5,
              ),
            );
          }

          if (provider.error != null && provider.viewedProfile == null) {
            return _buildErrorState(provider.error!);
          }

          final profile = provider.viewedProfile;
          if (profile == null) {
            return _buildErrorState('Profile not available');
          }

          return RefreshIndicator(
            color: AppColors.brandPrimary,
            onRefresh: _loadUserProfile,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.md),
                  // Header - no edit button for other users
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md),
                    child: ProfileHeader(
                      profile: profile.profile,
                      showEditButton: false,
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
              Icons.person_off_outlined,
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
              onPressed: _loadUserProfile,
              child: const Text('Try Again'),
            ),
          ],
        ),
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
}
