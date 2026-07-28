import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/profile.dart';

class CollaboratorsRow extends StatelessWidget {
  final List<FrequentCollaborator> collaborators;
  final void Function(String userId)? onCollaboratorTap;

  const CollaboratorsRow({
    super.key,
    required this.collaborators,
    this.onCollaboratorTap,
  });

  @override
  Widget build(BuildContext context) {
    if (collaborators.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Text(
            'Frequent Collaborators',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            itemCount: collaborators.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) {
              final collaborator = collaborators[index];
              return _CollaboratorAvatar(
                collaborator: collaborator,
                onTap: () => onCollaboratorTap?.call(collaborator.userId),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CollaboratorAvatar extends StatelessWidget {
  final FrequentCollaborator collaborator;
  final VoidCallback? onTap;

  const _CollaboratorAvatar({
    required this.collaborator,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.brandPrimary.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.lightSurfaceVariant,
                backgroundImage: collaborator.profilePhotoUrl.isNotEmpty
                    ? NetworkImage(collaborator.profilePhotoUrl)
                    : null,
                child: collaborator.profilePhotoUrl.isEmpty
                    ? Text(
                        _getInitials(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.brandPrimary,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              collaborator.firstName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            Text(
              '${collaborator.sharedTripCount} trips',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: AppColors.lightTextTertiary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials() {
    final first =
        collaborator.firstName.isNotEmpty ? collaborator.firstName[0] : '';
    final last =
        collaborator.lastName.isNotEmpty ? collaborator.lastName[0] : '';
    return '$first$last'.toUpperCase();
  }
}
