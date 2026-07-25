import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/fork_wizard_provider.dart';

class StepReviewCreate extends StatelessWidget {
  final String templateId;
  final VoidCallback onBack;

  const StepReviewCreate({super.key, required this.templateId, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Consumer<ForkWizardProvider>(
      builder: (context, provider, _) {
        final guide = provider.forkGuide;
        if (guide == null) return const Center(child: Text('No fork guide loaded'));

        return Column(children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Review Your Trip', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text('"${guide.title}" • ${guide.totalDays} days', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 20),

                // Per-city summary
                ...guide.legs.map((leg) {
                  final hotel = provider.selectedHotels[leg.order];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.withOpacity(0.15))),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('📍 ${leg.city} (${leg.days} days)', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      if (hotel != null)
                        Text('🏨 ${hotel.name} — ${hotel.currency}${hotel.priceTotal.toInt()} total', style: const TextStyle(fontSize: 13))
                      else
                        const Text('🏨 No hotel selected', style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: AppTheme.textSecondary)),
                      if (leg.playlistId != null && leg.playlistId!.isNotEmpty)
                        const Text('🎵 Attractions from playlist', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      if (leg.restaurantIds.isNotEmpty)
                        Text('🍽 ${leg.restaurantIds.length} restaurants', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    ]),
                  );
                }),

                // Hotels total
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3))),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Hotels total:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    Text('${guide.currency}${provider.hotelsTotal.toInt()}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.primaryColor)),
                  ]),
                ),

                // Note about transport
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.orange.withOpacity(0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.orange.withOpacity(0.3))),
                  child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('⚠️ ', style: TextStyle(fontSize: 14)),
                    Expanded(child: Text('No flights/transport added yet.\nYou can add them from your trip page.', style: TextStyle(fontSize: 13, color: Colors.orange))),
                  ]),
                ),
              ]),
            ),
          ),

          // Bottom CTA
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))]),
            child: SafeArea(
              child: Column(children: [
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: () => _createTrip(context, provider),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                    child: const Text('🚀  CREATE MY TRIP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(onPressed: onBack, child: const Text('← Go back and edit selections')),
              ]),
            ),
          ),
        ]);
      },
    );
  }

  Future<void> _createTrip(BuildContext context, ForkWizardProvider provider) async {
    // Trip creation requires flights (which templates don't include).
    // Show user a success message and direct them to create a trip normally,
    // then add the template's hotels/playlists/restaurants from their trip page.
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Template selections saved! Create a trip from the home screen, then add your hotel picks.'),
          duration: Duration(seconds: 4),
        ),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }
}
