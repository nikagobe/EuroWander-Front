import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/profile.dart';

class ProfileHeader extends StatelessWidget {
  final UserProfile profile;
  final bool showEditButton;
  final VoidCallback? onEditTap;
  final String? resolvedProfilePhotoUrl;
  final String? resolvedCoverPhotoUrl;

  const ProfileHeader({
    super.key,
    required this.profile,
    this.showEditButton = false,
    this.onEditTap,
    this.resolvedProfilePhotoUrl,
    this.resolvedCoverPhotoUrl,
  });

  String get _effectiveProfileUrl =>
      resolvedProfilePhotoUrl ?? profile.profilePhotoUrl;
  String get _effectiveCoverUrl =>
      resolvedCoverPhotoUrl ?? profile.coverPhotoUrl;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return SizedBox(
      height: 280,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Cover photo
          Container(
            height: 200,
            width: screenWidth,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.brandPrimary.withOpacity(0.8),
                  AppColors.brandSecondary.withOpacity(0.6),
                ],
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              child: _effectiveCoverUrl.isNotEmpty
                  ? Image.network(
                      _effectiveCoverUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildCoverPlaceholder(),
                    )
                  : _buildCoverPlaceholder(),
            ),
          ),

          // Edit button
          if (showEditButton)
            Positioned(
              top: AppSpacing.md,
              right: AppSpacing.md,
              child: Material(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: InkWell(
                  onTap: onEditTap,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(
                      Icons.edit_outlined,
                      size: 20,
                      color: AppColors.brandPrimary,
                    ),
                  ),
                ),
              ),
            ),

          // Profile photo + name overlay
          Positioned(
            bottom: 0,
            left: AppSpacing.xl,
            right: AppSpacing.xl,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Avatar
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: AppShadows.md(Colors.black),
                  ),
                  child: CircleAvatar(
                    radius: 44,
                    backgroundColor: AppColors.lightSurfaceVariant,
                    backgroundImage: _effectiveProfileUrl.isNotEmpty
                        ? NetworkImage(_effectiveProfileUrl)
                        : null,
                    child: _effectiveProfileUrl.isEmpty
                        ? Text(
                            _getInitials(),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                              color: AppColors.brandPrimary,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // Name and info
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          profile.fullName.isNotEmpty
                              ? profile.fullName
                              : 'Traveler',
                          style: Theme.of(context).textTheme.headlineSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (profile.homeCity.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: AppColors.lightTextSecondary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  profile.homeCity,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppColors.lightTextSecondary,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.brandPrimary,
            AppColors.brandSecondary.withOpacity(0.7),
            AppColors.brandAccent.withOpacity(0.5),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.flight_takeoff_rounded,
          size: 48,
          color: Colors.white.withOpacity(0.3),
        ),
      ),
    );
  }

  String _getInitials() {
    final first = profile.firstName.isNotEmpty ? profile.firstName[0] : '';
    final last = profile.lastName.isNotEmpty ? profile.lastName[0] : '';
    return '$first$last'.toUpperCase();
  }
}
