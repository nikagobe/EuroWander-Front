import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/hotel.dart';
import '../../../models/template.dart';
import '../../../providers/fork_wizard_provider.dart';
import '../../../services/api_service.dart';
import '../../../widgets/templates/hotel_pick_card.dart';
import '../../../widgets/templates/author_tip_box.dart';

/// Embedded hotel search section for the fork wizard.
/// Shows recommended picks first, with option to search for more.
class WizardHotelSection extends StatefulWidget {
  final ForkGuideLeg leg;

  const WizardHotelSection({super.key, required this.leg});

  @override
  State<WizardHotelSection> createState() => _WizardHotelSectionState();
}

class _WizardHotelSectionState extends State<WizardHotelSection> {
  final ApiService _apiService = ApiService();

  // Full hotel search state
  List<HotelOffer> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  bool _showSearch = false;
  String? _searchError;

  // Resolved destination ID for hotel search
  String? _destId;
  bool _isResolvingDest = false;

  @override
  void initState() {
    super.initState();
    // Start checking recommended picks
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ForkWizardProvider>().checkHotelsForLeg(widget.leg.order);
    });
  }

  Future<void> _resolveDestAndSearch() async {
    setState(() {
      _isResolvingDest = true;
      _showSearch = true;
    });

    try {
      // Get dest_id for hotel search
      final destinations = await _apiService.searchHotelDestinations(
        query: widget.leg.city,
      );
      if (destinations.isNotEmpty && mounted) {
        _destId = destinations.first.destId;
        await _searchHotels();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchError = 'Failed to resolve destination: $e';
          _isResolvingDest = false;
        });
      }
    }
  }

  Future<void> _searchHotels() async {
    if (_destId == null) return;

    final search = widget.leg.hotelSearch;
    final checkin = search?.checkin ?? '';
    final checkout = search?.checkout ?? '';

    if (checkin.isEmpty || checkout.isEmpty) {
      // Fall back to leg dates from provider
      final provider = context.read<ForkWizardProvider>();
      final start = provider.legStartDate(widget.leg.order);
      final end = provider.legEndDate(widget.leg.order);
      if (start == null || end == null) return;
      final checkinStr = DateFormat('yyyy-MM-dd').format(start);
      final checkoutStr = DateFormat('yyyy-MM-dd').format(end);
      await _doSearch(checkinStr, checkoutStr);
    } else {
      await _doSearch(checkin, checkout);
    }
  }

  Future<void> _doSearch(String checkin, String checkout) async {
    setState(() {
      _isSearching = true;
      _hasSearched = true;
      _searchError = null;
      _isResolvingDest = false;
    });

    try {
      final results = await _apiService.searchHotels(
        destId: _destId!,
        arrivalDate: checkin,
        departureDate: checkout,
      );
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchError = 'Failed to search hotels: $e';
          _isSearching = false;
        });
      }
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

            // ── Recommended picks ──────────────────────────────────────
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

            const SizedBox(height: 12),

            // ── Search for more hotels ─────────────────────────────────
            if (!_showSearch)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _resolveDestAndSearch,
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text('Search for more hotels'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.brandPrimary,
                    side: const BorderSide(color: AppColors.brandPrimary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              )
            else ...[
              const Text(
                '🔍 MORE HOTELS',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.lightTextSecondary, letterSpacing: 1),
              ),
              const SizedBox(height: 8),

              if (_isResolvingDest || _isSearching)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator(color: AppColors.brandPrimary)),
                )
              else if (_searchError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(_searchError!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                )
              else if (_hasSearched && _searchResults.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: Text('No additional hotels found.', style: TextStyle(color: ew.textSecondary))),
                )
              else
                ..._searchResults.map((hotel) => _buildHotelCard(hotel, selected, provider)),
            ],

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

  Widget _buildHotelCard(HotelOffer hotel, HotelOffer? selected, ForkWizardProvider provider) {
    final isSelected = selected?.hotelId == hotel.hotelId;

    return GestureDetector(
      onTap: () => provider.selectHotel(widget.leg.order, hotel),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.brandPrimary : Colors.grey.withOpacity(0.15),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? AppColors.brandPrimary.withOpacity(0.1) : Colors.black.withOpacity(0.03),
              blurRadius: isSelected ? 12 : 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: hotel.photoUrl.isNotEmpty
                  ? Image.network(hotel.photoUrl, width: 60, height: 60, fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _photoPlaceholder())
                  : _photoPlaceholder(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hotel.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text('${'★' * hotel.stars}', style: const TextStyle(fontSize: 12, color: Color(0xFFFF9800))),
                      if (hotel.reviewScore > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(color: AppColors.brandPrimary, borderRadius: BorderRadius.circular(4)),
                          child: Text('${hotel.reviewScore}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                        const SizedBox(width: 4),
                        Text(hotel.reviewScoreWord, style: const TextStyle(fontSize: 11, color: AppColors.lightTextSecondary)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '€${hotel.pricePerNight.toStringAsFixed(0)}/night · €${hotel.priceTotal.toStringAsFixed(0)} total',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.brandPrimary),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.brandPrimary, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _photoPlaceholder() {
    return Container(
      width: 60, height: 60,
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
      child: const Icon(Icons.hotel, size: 24, color: Colors.grey),
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
