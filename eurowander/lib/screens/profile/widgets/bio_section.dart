import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class BioSection extends StatelessWidget {
  final String bio;

  const BioSection({super.key, required this.bio});

  @override
  Widget build(BuildContext context) {
    if (bio.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Text(
        bio,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.6,
              color: AppColors.lightTextSecondary,
            ),
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class TravelTagsRow extends StatelessWidget {
  final List<String> tags;

  const TravelTagsRow({super.key, required this.tags});

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: tags.map((tag) {
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: AppColors.brandPrimary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: AppColors.brandPrimary.withOpacity(0.15),
              ),
            ),
            child: Text(
              tag,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.brandPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
