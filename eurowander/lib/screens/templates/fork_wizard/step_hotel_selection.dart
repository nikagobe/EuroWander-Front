import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../../../models/template.dart';
import '../../../providers/fork_wizard_provider.dart';
import '../../../widgets/widgets.dart';
import '../../../widgets/templates/hotel_pick_card.dart';
import '../../../widgets/templates/author_tip_box.dart';

class StepHotelSelection extends StatefulWidget {
  final ForkGuideLeg leg;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const StepHotelSelection({super.key, required this.leg, required this.onNext, required this.onBack});

  @override
  State<StepHotelSelection> createState() => _StepHotelSelectionState();
}

class _StepHotelSelectionState extends State<StepHotelSelection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ForkWizardProvider>().checkHotelsForLeg(widget.leg.order);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ForkWizardProvider>(
      builder: (context, provider, _) {
        final search = widget.leg.hotelSearch;
        final isLoading = provider.isLoadingHotels(widget.leg.order);
        final availability = provider.pickAvailability[widget.leg.order] ?? {};
        final selected = provider.selectedHotels[widget.leg.order];

        return Column(children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('🏨 ${widget.leg.city}', style: Theme.of(context).textTheme.titleLarge),
                Text('${widget.leg.dateRange.start} – ${widget.leg.dateRange.end} (${widget.leg.days} nights)', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 16),

                if (widget.leg.authorNotes.isNotEmpty) AuthorTipBox(tip: widget.leg.authorNotes),

                if (search == null)
                  Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: Text('No hotel recommendations for this city.', style: TextStyle(color: context.ew.textSecondary)))
                else if (isLoading)
                  ..._buildSkeletons()
                else ...[
                  // Author's picks
                  if (search.primaryPicks.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFFF9800))),
                      child: const Text('⭐ AUTHOR\'S PICKS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFE65100), letterSpacing: 0.5)),
                    ),
                    const SizedBox(height: 10),
                    ...search.primaryPicks.map((pick) {
                      final hotelOffer = availability[pick.bookingHotelId];
                      final isAvailable = hotelOffer != null;
                      final isSelected = selected?.hotelId == pick.bookingHotelId;

                      return HotelPickCard(
                        name: pick.name, stars: pick.stars, photoUrl: pick.photoUrl,
                        authorReview: pick.authorReview, authorPricePaid: pick.pricePaid,
                        currency: pick.currency, isAvailable: isAvailable,
                        currentPrice: hotelOffer?.pricePerNight, isSelected: isSelected,
                        onTap: () => provider.selectHotel(widget.leg.order, hotelOffer),
                      );
                    }),
                  ],

                  // More options header
                  if (search.fallbackParams != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    const Text('🔍 MORE OPTIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.lightTextSecondary, letterSpacing: 1)),
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: context.ew.cardColor, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.withOpacity(0.15))),
                      child: Text(
                        'Search for more hotels in ${search.fallbackParams!.neighborhood.isNotEmpty ? search.fallbackParams!.neighborhood : search.city} from your trip page after creating.',
                        style: TextStyle(fontSize: 13, color: context.ew.textSecondary),
                      ),
                    ),
                  ],
                ],

                // Playlist & restaurants info
                if (widget.leg.playlistId != null && widget.leg.playlistId!.isNotEmpty || widget.leg.restaurantIds.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.green.withOpacity(0.2))),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      if (widget.leg.playlistId != null && widget.leg.playlistId!.isNotEmpty) ...[
                        const Row(children: [Text('🎵 ', style: TextStyle(fontSize: 16)), Text('Attractions playlist', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500))]),
                        const Text('✅ Will be added to your trip', style: TextStyle(fontSize: 11, color: Color(0xFF4CAF50))),
                        const SizedBox(height: 6),
                      ],
                      if (widget.leg.restaurantIds.isNotEmpty) ...[
                        Row(children: [const Text('🍽 ', style: TextStyle(fontSize: 16)), Text('${widget.leg.restaurantIds.length} restaurants', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))]),
                        const Text('✅ Will be added to your trip', style: TextStyle(fontSize: 11, color: Color(0xFF4CAF50))),
                      ],
                    ]),
                  ),
                ],
              ]),
            ),
          ),

          // Navigation
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(children: [
              Expanded(child: OutlinedButton(onPressed: widget.onBack, style: OutlinedButton.styleFrom(foregroundColor: context.ew.textSecondary, side: BorderSide(color: Colors.grey.withOpacity(0.3)), shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd), padding: const EdgeInsets.symmetric(vertical: 14)), child: const Text('← Back'))),
              const SizedBox(width: AppSpacing.xs),
              TextButton(onPressed: widget.onNext, child: TextStyle(color: context.ew.textSecondary) == const TextStyle() ? const Text('Skip hotel') : Text('Skip hotel', style: TextStyle(color: context.ew.textSecondary))),
              const SizedBox(width: AppSpacing.xs),
              Expanded(child: ElevatedButton(onPressed: widget.onNext, style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandPrimary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd), padding: const EdgeInsets.symmetric(vertical: 14)), child: const Text('Next city →'))),
            ]),
          ),
        ]);
      },
    );
  }

  List<Widget> _buildSkeletons() => List.generate(3, (i) => Container(margin: const EdgeInsets.only(bottom: 8), height: 80, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(10))));
}

