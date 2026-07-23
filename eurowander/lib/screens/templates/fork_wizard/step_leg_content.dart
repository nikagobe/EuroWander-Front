import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/template.dart';
import '../../../models/flight.dart';
import '../../../models/bus.dart';
import '../../../models/hotel.dart';
import '../../../providers/fork_wizard_provider.dart';
import '../../../widgets/templates/author_tip_box.dart';
import '../../../widgets/templates/tier_badge.dart';
import '../../../widgets/templates/availability_indicator.dart';

class StepLegContent extends StatefulWidget {
  final ForkGuideLeg leg;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const StepLegContent({
    super.key,
    required this.leg,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<StepLegContent> createState() => _StepLegContentState();
}

class _StepLegContentState extends State<StepLegContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ForkWizardProvider>();
      if (widget.leg.flightSearch != null) {
        provider.searchFlightsForLeg(widget.leg.order);
      }
      if (widget.leg.transportSearch != null) {
        provider.searchTransportForLeg(widget.leg.order);
      }
      if (widget.leg.hotelSearch != null) {
        provider.searchHotelsForLeg(widget.leg.order);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ForkWizardProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Leg header
                    Text(
                      'Leg ${widget.leg.order}: ${widget.leg.city}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      '${widget.leg.dateRange.start} – ${widget.leg.dateRange.end} (${widget.leg.days} days)',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),

                    // Flight section
                    if (widget.leg.flightSearch != null)
                      _buildFlightSection(provider),

                    // Transport section
                    if (widget.leg.transportSearch != null)
                      _buildTransportSection(provider),

                    // Hotel section
                    if (widget.leg.hotelSearch != null)
                      _buildHotelSection(provider),

                    // Playlist & restaurants
                    if (widget.leg.playlistId != null ||
                        widget.leg.restaurantIds.isNotEmpty)
                      _buildAutoContent(),

                    // Author notes
                    if (widget.leg.authorNotes.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('📝 ',
                                style: TextStyle(fontSize: 16)),
                            Expanded(
                              child: Text(
                                widget.leg.authorNotes,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Navigation
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onBack,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textSecondary,
                        side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('← Back'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: widget.onNext,
                    child: const Text('Skip for now',
                        style: TextStyle(color: AppTheme.textSecondary)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: widget.onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Next →'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ─── Flight Section ────────────────────────────────────────────────

  Widget _buildFlightSection(ForkWizardProvider provider) {
    final search = widget.leg.flightSearch!;
    final isLoading = provider.isLoadingFlights(widget.leg.order);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '✈️ CHOOSE FLIGHT',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.textSecondary,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${search.originCity} (${search.originIata}) → ${search.destinationCity} (${search.destinationIata})',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        Text(
          'Date: ${search.date}',
          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
        if (search.authorTip.isNotEmpty)
          AuthorTipBox(tip: search.authorTip),
        const SizedBox(height: 12),

        if (isLoading)
          _buildSkeletonLoader()
        else
          _buildFlightTiers(provider),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildFlightTiers(ForkWizardProvider provider) {
    final tiers = provider.getFlightTiers(widget.leg.order);
    final selected = provider.selectedFlights[widget.leg.order];
    final topPick = tiers['top_pick'] ?? [];
    final recommended = tiers['recommended'] ?? [];
    final others = tiers['others'] ?? [];

    if (topPick.isEmpty && recommended.isEmpty && others.isEmpty) {
      return _buildEmptyState('No flights found for this route.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (topPick.isNotEmpty) ...[
          const TierBadge(label: "AUTHOR'S TOP PICK", isTopPick: true),
          const SizedBox(height: 8),
          ...topPick.map((f) => _buildFlightCard(f, provider, selected)),
        ],
        if (recommended.isNotEmpty) ...[
          const SizedBox(height: 12),
          const TierBadge(label: 'ALSO RECOMMENDED'),
          const SizedBox(height: 8),
          ...recommended.map((f) => _buildFlightCard(f, provider, selected)),
        ],
        if (others.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text(
            'OTHER OPTIONS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          ...others.take(5).map((f) => _buildFlightCard(f, provider, selected)),
        ],
      ],
    );
  }

  Widget _buildFlightCard(
      FlightOffer flight, ForkWizardProvider provider, FlightOffer? selected) {
    final isSelected = selected == flight;
    final airline =
        flight.legs.isNotEmpty ? flight.legs.first.airline : 'Unknown';
    final flightNum =
        flight.legs.isNotEmpty ? flight.legs.first.flightNumber : '';
    final depTime = flight.topDepartureTime;
    final arrTime = flight.topArrivalTime;

    return GestureDetector(
      onTap: () => provider.selectFlight(widget.leg.order, flight),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$airline $flightNum',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$depTime → $arrTime • ${flight.stops == 0 ? "Direct" : "${flight.stops} stop(s)"}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${flight.currency} ${flight.price.toInt()}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle,
                      color: AppTheme.primaryColor, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Transport Section ─────────────────────────────────────────────

  Widget _buildTransportSection(ForkWizardProvider provider) {
    final search = widget.leg.transportSearch!;
    final isLoading = provider.isLoadingTransport(widget.leg.order);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🚌 CHOOSE TRANSPORT',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.textSecondary,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${search.fromCity} → ${search.toCity}',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        Text(
          'Date: ${search.date} • Mode: ${search.mode}',
          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
        if (search.authorTip.isNotEmpty)
          AuthorTipBox(tip: search.authorTip),
        const SizedBox(height: 12),

        if (isLoading)
          _buildSkeletonLoader()
        else
          _buildTransportTiers(provider),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTransportTiers(ForkWizardProvider provider) {
    final tiers = provider.getTransportTiers(widget.leg.order);
    final selected = provider.selectedTransport[widget.leg.order];
    final topPick = tiers['top_pick'] ?? [];
    final others = tiers['others'] ?? [];

    if (topPick.isEmpty && others.isEmpty) {
      return _buildEmptyState('No transport options found for this route.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (topPick.isNotEmpty) ...[
          const TierBadge(label: "RECOMMENDED", isTopPick: true),
          const SizedBox(height: 8),
          ...topPick.map((b) => _buildBusCard(b, provider, selected)),
        ],
        if (others.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text(
            'OTHER OPTIONS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          ...others.take(5).map((b) => _buildBusCard(b, provider, selected)),
        ],
      ],
    );
  }

  Widget _buildBusCard(
      BusOffer bus, ForkWizardProvider provider, BusOffer? selected) {
    final isSelected = selected == bus;

    return GestureDetector(
      onTap: () => provider.selectTransport(widget.leg.order, bus),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bus.segments.isNotEmpty ? bus.segments.first.product : 'Transport',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${bus.depTime} → ${bus.arrTime} • ${bus.duration}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${bus.currency} ${bus.price.toInt()}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle,
                      color: AppTheme.primaryColor, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Hotel Section ─────────────────────────────────────────────────

  Widget _buildHotelSection(ForkWizardProvider provider) {
    final search = widget.leg.hotelSearch!;
    final isLoading = provider.isLoadingHotels(widget.leg.order);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🏨 CHOOSE HOTEL',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.textSecondary,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${search.city} • ${search.checkin} → ${search.checkout}',
          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 12),

        if (isLoading)
          _buildSkeletonLoader()
        else
          _buildHotelPicks(provider, search),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildHotelPicks(ForkWizardProvider provider, ForkHotelSearch search) {
    final availability =
        provider.primaryPickAvailability[widget.leg.order] ?? {};
    final selected = provider.selectedHotels[widget.leg.order];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (search.primaryPicks.isNotEmpty) ...[
          const TierBadge(label: "AUTHOR'S PICKS", isTopPick: true),
          const SizedBox(height: 8),
          ...search.primaryPicks.map((pick) {
            final hotelOffer = availability[pick.bookingHotelId];
            final isAvailable = hotelOffer != null;
            final isSelected = selected?.hotelId == pick.bookingHotelId;

            return _buildHotelPickCard(
              pick: pick,
              hotelOffer: hotelOffer,
              isAvailable: isAvailable,
              isSelected: isSelected,
              onTap: isAvailable
                  ? () => provider.selectHotel(widget.leg.order, hotelOffer)
                  : null,
            );
          }),
        ],
        // Fallback options would go here if we had general search results
      ],
    );
  }

  Widget _buildHotelPickCard({
    required ForkHotelPick pick,
    HotelOffer? hotelOffer,
    required bool isAvailable,
    required bool isSelected,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isAvailable ? Colors.white : Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : isAvailable
                    ? Colors.grey.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Photo
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: pick.photoUrl.isNotEmpty
                      ? Image.network(
                          pick.photoUrl,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildHotelPlaceholder(),
                        )
                      : _buildHotelPlaceholder(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${pick.name} ${'★' * pick.stars}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isAvailable
                              ? AppTheme.textPrimary
                              : AppTheme.textSecondary,
                        ),
                      ),
                      if (pick.authorReview.isNotEmpty)
                        Text(
                          '"${pick.authorReview}"',
                          style: const TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: AppTheme.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 2),
                      if (pick.pricePaid != null)
                        Text(
                          'Author paid: ${pick.currency}${pick.pricePaid!.toInt()}/night',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle,
                      color: AppTheme.primaryColor, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            AvailabilityIndicator(
              isAvailable: isAvailable,
              priceText: hotelOffer != null
                  ? '${hotelOffer.currency}${hotelOffer.pricePerNight.toInt()}/night'
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHotelPlaceholder() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.hotel, color: AppTheme.primaryColor, size: 24),
    );
  }

  // ─── Auto-copied Content ───────────────────────────────────────────

  Widget _buildAutoContent() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.leg.playlistId != null) ...[
            const Row(
              children: [
                Text('🎵 ', style: TextStyle(fontSize: 16)),
                Text(
                  'Attractions Playlist',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const Text(
              '✅ Will be added to your trip',
              style: TextStyle(fontSize: 11, color: Color(0xFF4CAF50)),
            ),
            const SizedBox(height: 8),
          ],
          if (widget.leg.restaurantIds.isNotEmpty) ...[
            Row(
              children: [
                const Text('🍽 ', style: TextStyle(fontSize: 16)),
                Text(
                  '${widget.leg.restaurantIds.length} restaurants',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const Text(
              '✅ Will be added to your trip',
              style: TextStyle(fontSize: 11, color: Color(0xFF4CAF50)),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────

  Widget _buildSkeletonLoader() {
    return Column(
      children: List.generate(
        3,
        (i) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.orange, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13, color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }
}
