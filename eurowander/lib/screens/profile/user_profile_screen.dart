import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import 'widgets/badges_section.dart';
import 'widgets/bio_section.dart';
import 'widgets/collaborators_row.dart';
import 'widgets/stats_row.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  FullProfile? _profile;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await context.read<ProfileProvider>().fetchUserProfile(
            token: token,
            userId: widget.userId,
          );
      if (mounted) {
        setState(() {
          _profile = context.read<ProfileProvider>().viewedProfile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
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
              final profile = provider.viewedProfile ?? _profile;
              final loading = _isLoading && profile == null;
              final error = provider.error ?? _error;

              if (loading) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.brandPrimary,
                    strokeWidth: 2.5,
                  ),
                );
              }

              if (error != null && profile == null) {
                return _buildErrorState(error);
              }

              if (profile == null) {
                return _buildErrorState('Profile not available');
              }

              return RefreshIndicator(
                color: AppColors.brandPrimary,
                onRefresh: _loadUserProfile,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    // Cover photo with overlaid back button
                    SliverToBoxAdapter(
                      child: _buildCoverSection(profile),
                    ),

                    // Name and location
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
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
                        child: StatsRow(stats: profile.stats),
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

                    const SliverToBoxAdapter(
                      child: SizedBox(height: AppSpacing.huge),
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

  Widget _buildCoverSection(FullProfile profile) {
    final coverUrl = profile.profile.coverPhotoUrl;
    final profileUrl = profile.profile.profilePhotoUrl;
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

          // Gradient scrim at bottom
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
            child: Material(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
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
