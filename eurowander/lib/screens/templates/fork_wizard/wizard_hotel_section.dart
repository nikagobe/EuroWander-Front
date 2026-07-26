import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/hotel.dart';
import '../../../models/template.dart';
import '../../../providers/fork_wizard_provider.dart';
import '../../../widgets/templates/hotel_pick_card.dart';
import '../../../widgets/templates/author_tip_box.dart';
import '../../home/hotel_search_screen.dart';

/// Hotel section for the fork wizard.
/// Shows recommended picks from the template and a button to open
/// the classic hotel search page in pick mode.
class WizardHotelSection extends StatefulWidget {
  final ForkGuideLeg leg;

  const WizardHotelSection({super.key, required this.leg});

  @override
  State<WizardHotelSection> createState() => _WizardHotelSectionState();
}

class _WizardHotelSectionState extends State<WizardHotelSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ForkWizardProvider>().checkHotelsForLeg(widget.leg.order);
    });
  }

  Future<void> _openHotelSearch() async {
    final provider = context.read<ForkWizardProvider>();
    final checkin = provider.legStartDate(widget.leg.order);
    final checkout = provider.legEndDate(widget.leg.order);

    // Gather available recommended picks as HotelOffer list
    final availability = provider.pickAvailability[widget.leg.order] ?? {};
    final recommendedPicks = <HotelOffer>[];
    for (final offer in availability.values) {
      if (offer != null) recommendedPicks.add(offer);
    }

    final result = await Navigator.of(context).push<HotelOffer>(
      MaterialPageRoute(
        builder: (_) => HotelSearchScreen(
          pickMode: true,
          prefillCity: widget.leg.city,
          prefillCheckin: checkin,
          prefillCheckout: checkout,
          recommendedPicks: recommendedPicks,
        ),
      ),
    );

    if (result != null && mounted) {
      provider.selectHotel(widget.leg.order, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ew = context.ew;

    return Consumer<ForkWizardProvider>(
      builder: (context, provider, _) {
        final search = widget.leg.hotelSearch;
        final isLoading = provider.isLoadingHotels(widget.leg.order);
        final availability = provider.pickAvailability[widget.leg.order] ?? {};
        final selected = provider.selectedHotels[widget.leg.order];

        // If a hotel is already selected, show summary
        if (selected != null) {
          return _buildSelectedCard(selected, provider);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dates info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ew.cardColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: AppColors.brandPrimary),
                  const SizedBox(width: 10),
                  Text(
                    '${widget.leg.dateRange.start} – ${widget.leg.dateRange.end} (${widget.leg.days} nights)',
                    style: TextStyle(fontSize: 13, color: ew.textPrimary),
                  ),
                ],
              ),
            ),

            // Author tips
            if (widget.leg.authorNotes.isNotEmpty) ...[
              const SizedBox(height: 8),
              AuthorTipBox(tip: widget.leg.authorNotes),
            ],

            const SizedBox(height: 12),

            // ── Recommended picks (inline quick select) ────────────────
            if (search == null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text('No hotel recommendations for this city.', style: TextStyle(color: ew.textSecondary)),
              )
            else if (isLoading)
              ..._buildSkeletons()
            else if (search.primaryPicks.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFF9800)),
                ),
                child: const Text(
                  '⭐ AUTHOR\'S PICKS',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFE65100), letterSpacing: 0.5),
                ),
              ),
              const SizedBox(height: 10),
              ...search.primaryPicks.map((pick) {
                final hotelOffer = availability[pick.bookingHotelId];
                final isAvailable = hotelOffer != null;
                final isSelected = selected?.hotelId == pick.bookingHotelId;

                return HotelPickCard(
                  name: pick.name,
                  stars: pick.stars,
                  photoUrl: pick.photoUrl,
                  authorReview: pick.authorReview,
                  authorPricePaid: pick.pricePaid,
                  currency: pick.currency,
                  isAvailable: isAvailable,
                  currentPrice: hotelOffer?.pricePerNight,
                  isSelected: isSelected,
                  onTap: () => provider.selectHotel(widget.leg.order, hotelOffer),
                );
              }),
            ],

            const SizedBox(height: 16),

            // ── Search for more button → opens classic hotel search page
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _openHotelSearch,
                icon: const Icon(Icons.search, size: 20),
                label: const Text('Search Hotels', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),

            // Playlist & restaurants info
            if (widget.leg.playlistId != null && widget.leg.playlistId!.isNotEmpty || widget.leg.restaurantIds.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.leg.playlistId != null && widget.leg.playlistId!.isNotEmpty) ...[
                      const Row(children: [
                        Text('🎵 ', style: TextStyle(fontSize: 16)),
                        Text('Attractions playlist', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      ]),
                      const Text('✅ Will be added to your trip', style: TextStyle(fontSize: 11, color: Color(0xFF4CAF50))),
                      const SizedBox(height: 6),
                    ],
                    if (widget.leg.restaurantIds.isNotEmpty) ...[
                      Row(children: [
                        const Text('🍽 ', style: TextStyle(fontSize: 16)),
                        Text('${widget.leg.restaurantIds.length} restaurants', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      ]),
                      const Text('✅ Will be added to your trip', style: TextStyle(fontSize: 11, color: Color(0xFF4CAF50))),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSelectedCard(HotelOffer hotel, ForkWizardProvider provider) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: hotel.photoUrl.isNotEmpty
                    ? Image.network(hotel.photoUrl, width: 56, height: 56, fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(width: 56, height: 56, color: Colors.grey.shade100, child: const Icon(Icons.hotel)))
                    : Container(width: 56, height: 56, color: Colors.grey.shade100, child: const Icon(Icons.hotel)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(hotel.name, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(
                      '€${hotel.pricePerNight.toStringAsFixed(0)}/night · €${hotel.priceTotal.toStringAsFixed(0)} total',
                      style: GoogleFonts.poppins(fontSize: 12, color: AppColors.lightTextSecondary),
                    ),
                  ],
                ),
              ),
              Text('${'★' * hotel.stars}', style: const TextStyle(fontSize: 14, color: Color(0xFFFF9800))),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openHotelSearch,
              icon: const Icon(Icons.swap_horiz, size: 18),
              label: const Text('Change Hotel'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.brandPrimary,
                side: const BorderSide(color: AppColors.brandPrimary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSkeletons() {
    return List.generate(3, (i) => Container(
      margin: const EdgeInsets.only(bottom: 8),
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
    ));
  }
}
