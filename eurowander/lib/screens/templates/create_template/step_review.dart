import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/template.dart';

class StepReview extends StatelessWidget {
  final String title;
  final String description;
  final String coverPhotoUrl;
  final List<String> tags;
  final List<CreateTemplateLeg> legs;
  final String currency;
  final double? budgetMin;
  final double? budgetMax;
  final VoidCallback onSaveDraft;
  final VoidCallback onPublish;
  final VoidCallback onBack;

  const StepReview({
    super.key,
    required this.title,
    required this.description,
    required this.coverPhotoUrl,
    required this.tags,
    required this.legs,
    required this.currency,
    this.budgetMin,
    this.budgetMax,
    required this.onSaveDraft,
    required this.onPublish,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final totalDays = legs.fold<int>(0, (sum, leg) => sum + leg.days);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Review your template',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),

          // Preview card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isNotEmpty ? title : '(No title)',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                if (description.isNotEmpty) ...[
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    _buildChip('$totalDays days'),
                    const SizedBox(width: 8),
                    if (budgetMin != null)
                      _buildChip(
                          '$currency ${budgetMin!.toInt()}–${budgetMax?.toInt() ?? ''}'),
                  ],
                ),
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: tags
                        .map((t) => Chip(
                              label: Text(t, style: const TextStyle(fontSize: 11)),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Route summary
          Text('Route', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...legs.map((leg) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Text('📍 ', style: TextStyle(fontSize: 16)),
                    Expanded(
                      child: Text(
                        'Leg ${leg.order}: ${leg.city}, ${leg.country} — ${leg.days} days',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    if (leg.flightRecommendation != null)
                      const Text('✈️', style: TextStyle(fontSize: 14)),
                    if (leg.transportRecommendation != null)
                      const Text('🚌', style: TextStyle(fontSize: 14)),
                  ],
                ),
              )),

          const SizedBox(height: 32),

          // Action buttons
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: onSaveDraft,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save as Draft'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                side: const BorderSide(color: AppTheme.primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _canPublish ? onPublish : null,
              icon: const Icon(Icons.rocket_launch),
              label: const Text('Publish Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: Colors.grey.withOpacity(0.3),
              ),
            ),
          ),
          if (!_canPublish) ...[
            const SizedBox(height: 8),
            const Text(
              'To publish, you need a title and at least 1 leg.',
              style: TextStyle(fontSize: 12, color: Colors.red),
            ),
          ],
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: onBack,
              child: const Text('← Go back and edit'),
            ),
          ),
        ],
      ),
    );
  }

  bool get _canPublish => title.isNotEmpty && legs.isNotEmpty;

  Widget _buildChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
      ),
    );
  }
}
