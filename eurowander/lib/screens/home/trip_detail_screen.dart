import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../models/saved_trip.dart';
import '../../models/schedule.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/widgets.dart';
import 'hotel_search_screen.dart';
import 'trip_activities_screen.dart';
import 'trip_documents_screen.dart';
import 'trip_finances_screen.dart';
import 'trip_hotels_screen.dart';
import 'trip_members_screen.dart';
import 'trip_photos_screen.dart';
import 'trip_schedule_screen.dart';
import 'trip_tickets_screen.dart';

class TripDetailScreen extends StatefulWidget {
  final SavedTrip trip;

  const TripDetailScreen({super.key, required this.trip});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  final ApiService _apiService = ApiService();
  List<TripMember> _members = [];
  bool _membersLoading = true;
  FullSchedule? _schedule;
  bool _scheduleLoading = true;
  bool _scheduleExpanded = false;

  SavedTrip get trip => widget.trip;

  @override
  void initState() {
    super.initState();
    _loadMembers();
    _loadSchedule();
  }

  Future<void> _loadMembers() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    try {
      final members = await _apiService.getTripMembers(token: token, tripId: trip.id);
      if (mounted) setState(() { _members = members; _membersLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _membersLoading = false);
    }
  }

  Future<void> _loadSchedule() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    try {
      final schedule = await _apiService.getTripSchedule(token: token, tripId: trip.id);
      if (mounted) setState(() { _schedule = schedule; _scheduleLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _scheduleLoading = false);
    }
  }

  Future<void> _openDayOnMap(String dayDate) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    try {
      final result = await _apiService.getDayMapUrl(token: token, tripId: trip.id, dayDate: dayDate);
      final uri = Uri.parse(result.mapUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  /// Get today's or the next upcoming day from the schedule
  ScheduleDay? get _todayOrNextDay {
    if (_schedule == null || _schedule!.days.isEmpty) return null;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    // Try exact today
    for (final day in _schedule!.days) {
      if (day.date == today) return day;
    }
    // Try next upcoming day
    for (final day in _schedule!.days) {
      if (day.date.compareTo(today) > 0) return day;
    }
    // Fallback to first day
    return _schedule!.days.first;
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: CustomScrollView(
        slivers: [
          // Compact header with gradient + trip info
          SliverToBoxAdapter(child: _buildCompactHeader(context)),
          // Participants
          SliverToBoxAdapter(child: _buildParticipants(context)),
          // Today's Schedule (top priority)
          SliverToBoxAdapter(child: _buildSchedulePreview(context)),
          // Activities (right after schedule)
          SliverToBoxAdapter(child: _buildSectionTitle(context, 'Activities & Dining')),
          SliverToBoxAdapter(child: _buildActivitiesPreview(context)),
          // Flight preview (if available)
          if (trip.outboundFlight != null)
            SliverToBoxAdapter(child: _buildSectionTitle(context, 'Transport')),
          if (trip.outboundFlight != null)
            SliverToBoxAdapter(child: _buildFlightPreview(context)),
          // Hotels preview (always visible)
          SliverToBoxAdapter(child: _buildSectionTitle(context, 'Accommodation')),
          SliverToBoxAdapter(
            child: trip.hotels.isNotEmpty
                ? _buildHotelsPreview(context)
                : _buildFindAccommodation(context),
          ),
          // More sections
          SliverToBoxAdapter(child: _buildMoreSections(context)),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxxl)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 0),
      child: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: context.ew.textSecondary,
        letterSpacing: 0.5,
      )),
    );
  }

  // ────────────────────────────────────────────────────────────
  // Compact Header — refined, not a giant photo
  // ────────────────────────────────────────────────────────────

  Widget _buildCompactHeader(BuildContext context) {
    final ew = context.ew;
    final depDate = _parseDateSafe(trip.outboundFlight?.departureTime);
    final retDate = _parseDateSafe(trip.returnFlight?.arrivalTime);
    final destination = trip.outboundFlight?.arrivalCityName.isNotEmpty == true
        ? trip.outboundFlight!.arrivalCityName
        : trip.outboundFlight?.legs.isNotEmpty == true
            ? trip.outboundFlight!.legs.last.arrivalCityName
            : '';
    final days = depDate != null && retDate != null ? retDate.difference(depDate).inDays : null;
    final hasPhoto = trip.destinationPhotoUrl != null && trip.destinationPhotoUrl!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: Stack(
        children: [
          // Subtle background photo with heavy overlay (not dominant)
          if (hasPhoto)
            Positioned.fill(
              child: Opacity(
                opacity: 0.2,
                child: Image.network(
                  trip.destinationPhotoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
          // Content
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nav row
                  Row(
                    children: [
                      _buildGlassButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Destination label
                  if (destination.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on_rounded, size: 13, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text(destination, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white)),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  // Trip name
                  Text(
                    trip.name,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white, height: 1.15),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  // Date row
                  Row(
                    children: [
                      if (depDate != null) ...[
                        const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.white60),
                        const SizedBox(width: 6),
                        Text(
                          retDate != null
                              ? '${DateFormat('MMM d').format(depDate)} – ${DateFormat('MMM d').format(retDate)}'
                              : DateFormat('MMM d, yyyy').format(depDate),
                          style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
                        ),
                      ],
                      if (days != null) ...[
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          width: 4, height: 4,
                          decoration: BoxDecoration(color: Colors.white38, shape: BoxShape.circle),
                        ),
                        Text('$days days', style: const TextStyle(fontSize: 13, color: Colors.white70)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Icon(icon, color: Colors.white, size: 17),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // Participants — avatars + names
  // ────────────────────────────────────────────────────────────

  Widget _buildParticipants(BuildContext context) {
    final ew = context.ew;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => TripMembersScreen(trip: trip)),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ew.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppShadows.sm(Colors.black),
        ),
        child: Row(
          children: [
            // Stacked avatars
            if (_membersLoading)
              SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: ew.textSecondary),
              )
            else ...[
              SizedBox(
                width: _members.length > 4 ? 90 : (_members.length * 26 + 10).toDouble(),
                height: 36,
                child: Stack(
                  children: List.generate(
                    _members.take(4).length,
                    (i) => Positioned(
                      left: i * 22.0,
                      child: _buildMemberAvatar(_members[i], ew),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _members.length == 1
                          ? _members.first.displayName
                          : '${_members.length} travelers',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (_members.length > 1)
                      Text(
                        _members.take(3).map((m) => m.firstName.isNotEmpty ? m.firstName : 'Member').join(', ') +
                            (_members.length > 3 ? ' +${_members.length - 3}' : ''),
                        style: TextStyle(fontSize: 12, color: ew.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
            Icon(Icons.chevron_right_rounded, size: 20, color: ew.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberAvatar(TripMember member, EuroWanderTheme ew) {
    final initials = '${member.firstName.isNotEmpty ? member.firstName[0] : ''}${member.lastName.isNotEmpty ? member.lastName[0] : ''}'.toUpperCase();
    final colors = [AppColors.brandPrimary, AppColors.hotel, AppColors.flight, AppColors.budget, AppColors.restaurant];
    final color = colors[member.displayName.length % colors.length];

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: ew.cardColor, width: 2.5),
      ),
      child: Center(
        child: Text(initials, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // Flight Preview Card
  // ────────────────────────────────────────────────────────────

  Widget _buildFlightPreview(BuildContext context) {
    final ew = context.ew;
    final flight = trip.outboundFlight!;
    final depTime = _parseDateSafe(flight.departureTime);
    final airline = flight.airline;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => TripTicketsScreen(trip: trip)),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ew.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.flight.withOpacity(0.15)),
          boxShadow: AppShadows.sm(Colors.black),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.flight.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.flight_rounded, size: 18, color: AppColors.flight),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Outbound Flight', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                      if (airline.isNotEmpty)
                        Text(airline, style: TextStyle(fontSize: 12, color: ew.textSecondary)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, size: 20, color: ew.textTertiary),
              ],
            ),
            const SizedBox(height: 14),
            // Flight route visualization
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        flight.departureAirportId.isNotEmpty ? flight.departureAirportId : '---',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        flight.departureCityName.isNotEmpty ? flight.departureCityName : 'Departure',
                        style: TextStyle(fontSize: 11, color: ew.textSecondary),
                      ),
                    ],
                  ),
                ),
                // Flight path indicator
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        flight.stops == 0 ? 'Direct' : '${flight.stops} stop${flight.stops > 1 ? 's' : ''}',
                        style: TextStyle(fontSize: 10, color: ew.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(height: 1, color: AppColors.flight.withOpacity(0.3)),
                          const Icon(Icons.flight_rounded, size: 16, color: AppColors.flight),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (depTime != null)
                        Text(DateFormat('MMM d, HH:mm').format(depTime), style: TextStyle(fontSize: 10, color: ew.textSecondary)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        flight.arrivalAirportId.isNotEmpty ? flight.arrivalAirportId : '---',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        flight.arrivalCityName.isNotEmpty ? flight.arrivalCityName : 'Arrival',
                        style: TextStyle(fontSize: 11, color: ew.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // Hotels Preview
  // ────────────────────────────────────────────────────────────

  String _formatHotelDates(String checkin, String checkout) {
    try {
      final inDate = DateTime.parse(checkin);
      final outDate = DateTime.parse(checkout);
      final nights = outDate.difference(inDate).inDays;
      final inStr = DateFormat('MMM d').format(inDate);
      final outStr = inDate.year == outDate.year
          ? DateFormat('MMM d').format(outDate)
          : DateFormat('MMM d, yyyy').format(outDate);
      final nightLabel = nights == 1 ? '1 night' : '$nights nights';
      return '$inStr – $outStr  ·  $nightLabel';
    } catch (_) {
      return '$checkin → $checkout';
    }
  }

  Widget _buildHotelsPreview(BuildContext context) {
    final ew = context.ew;
    final hotel = trip.hotels.first;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => TripHotelsScreen(trip: trip)),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 0),
        decoration: BoxDecoration(
          color: ew.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.hotel.withOpacity(0.15)),
          boxShadow: AppShadows.sm(Colors.black),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hotel photo
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: Stack(
                children: [
                  hotel.photoUrl.isNotEmpty
                      ? Image.network(
                          hotel.photoUrl,
                          height: 110,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            height: 110,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [AppColors.hotel.withOpacity(0.3), AppColors.hotel.withOpacity(0.1)]),
                            ),
                            child: const Center(child: Icon(Icons.hotel_rounded, size: 32, color: AppColors.hotel)),
                          ),
                        )
                      : Container(
                          height: 110,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [AppColors.hotel.withOpacity(0.3), AppColors.hotel.withOpacity(0.1)]),
                          ),
                          child: const Center(child: Icon(Icons.hotel_rounded, size: 32, color: AppColors.hotel)),
                        ),
                  // Gradient scrim
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withOpacity(0.4)],
                        ),
                      ),
                    ),
                  ),
                  // Stars on photo
                  if (hotel.stars > 0)
                    Positioned(
                      bottom: 8, left: 12,
                      child: Row(
                        children: List.generate(
                          hotel.stars.clamp(0, 5),
                          (_) => const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFC107)),
                        ),
                      ),
                    ),
                  // Hotel count badge
                  if (trip.hotels.length > 1)
                    Positioned(
                      top: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${trip.hotels.length} hotels',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hotel.name,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 12, color: ew.textTertiary),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                _formatHotelDates(hotel.checkinDate, hotel.checkoutDate),
                                style: TextStyle(fontSize: 12, color: ew.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right_rounded, size: 20, color: ew.textTertiary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFindAccommodation(BuildContext context) {
    final ew = context.ew;
    // Try to extract destination city and dates from flight
    final destination = trip.outboundFlight?.arrivalCityName ?? '';
    DateTime? checkin;
    DateTime? checkout;
    try {
      final depStr = trip.outboundFlight?.arrivalTime;
      if (depStr != null && depStr.isNotEmpty) checkin = DateTime.parse(depStr.replaceAll(' ', 'T'));
      final retStr = trip.returnFlight?.departureTime;
      if (retStr != null && retStr.isNotEmpty) checkout = DateTime.parse(retStr.replaceAll(' ', 'T'));
    } catch (_) {}

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => HotelSearchScreen(
            trip: trip,
            prefillCity: destination.isNotEmpty ? destination : null,
            prefillCheckin: checkin,
            prefillCheckout: checkout,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ew.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.hotel.withOpacity(0.2), style: BorderStyle.solid),
          boxShadow: AppShadows.sm(Colors.black),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: AppColors.hotel.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.hotel_rounded, size: 22, color: AppColors.hotel),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Find Accommodation',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    destination.isNotEmpty ? 'Search hotels in $destination' : 'Search for hotels & stays',
                    style: TextStyle(fontSize: 12, color: ew.textSecondary),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.hotel.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_rounded, size: 18, color: AppColors.hotel),
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // Schedule Card — prominent CTA
  // ────────────────────────────────────────────────────────────

  // ────────────────────────────────────────────────────────────
  // Schedule Preview — today's plan with expand + Show on Map
  // ────────────────────────────────────────────────────────────

  Widget _buildSchedulePreview(BuildContext context) {
    final ew = context.ew;

    if (_scheduleLoading) {
      return Container(
        margin: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 0),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: ew.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppShadows.sm(Colors.black),
        ),
        child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }

    final day = _todayOrNextDay;
    if (day == null) {
      // No schedule — show CTA to create one
      return Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 0),
        child: Material(
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => TripScheduleScreen(trip: trip)),
            ),
            child: Ink(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF0891B2)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(11)),
                    child: const Icon(Icons.calendar_month_rounded, size: 20, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Create Schedule', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                        Text('Plan your day-by-day itinerary', style: TextStyle(fontSize: 12, color: Colors.white70)),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, size: 15, color: Colors.white.withOpacity(0.6)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // We have a schedule day to show
    final date = DateTime.tryParse(day.date);
    final isToday = day.date == DateFormat('yyyy-MM-dd').format(DateTime.now());
    final dayLabel = isToday ? 'Today' : (date != null ? DateFormat('EEEE, MMM d').format(date) : day.date);
    final items = day.items;
    final visibleItems = _scheduleExpanded ? items : items.take(4).toList();
    final hasPlaces = items.any((i) => i.itemType == 'attraction' || i.itemType == 'restaurant');

    return Container(
      margin: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 0),
      decoration: BoxDecoration(
        color: ew.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.transport.withOpacity(0.15)),
        boxShadow: AppShadows.sm(Colors.black),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => TripScheduleScreen(trip: trip)),
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF0891B2)]),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_rounded, size: 18, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Schedule · $dayLabel', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                        Text('${items.length} items planned', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7))),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white.withOpacity(0.6)),
                ],
              ),
            ),
          ),
          // Schedule items
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('No activities planned for this day', style: TextStyle(fontSize: 13, color: ew.textSecondary)),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Column(
                children: visibleItems.map((item) => _buildScheduleItemRow(context, item)).toList(),
              ),
            ),
            // Expand/collapse
            if (items.length > 4)
              GestureDetector(
                onTap: () => setState(() => _scheduleExpanded = !_scheduleExpanded),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _scheduleExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        size: 18, color: AppColors.transport,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _scheduleExpanded ? 'Show less' : 'Show ${items.length - 4} more',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.transport),
                      ),
                    ],
                  ),
                ),
              ),
          ],
          // Show on Map button
          if (hasPlaces)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Material(
                borderRadius: BorderRadius.circular(10),
                color: AppColors.transport.withOpacity(0.08),
                child: InkWell(
                  onTap: () => _openDayOnMap(day.date),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.map_rounded, size: 16, color: AppColors.transport),
                        const SizedBox(width: 6),
                        Text(
                          'Show ${items.where((i) => i.itemType == 'attraction' || i.itemType == 'restaurant').length} stops on Map',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.transport),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScheduleItemRow(BuildContext context, ScheduleItem item) {
    final ew = context.ew;
    final color = _getItemColor(item.itemType);
    final icon = _getItemIcon(item.itemType);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Time dot
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                if (item.subtitle.isNotEmpty)
                  Text(item.subtitle, style: TextStyle(fontSize: 11, color: ew.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _formatTimeSlot(item.timeSlot),
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: ew.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Color _getItemColor(String type) {
    switch (type) {
      case 'attraction': return AppColors.attraction;
      case 'restaurant': return AppColors.restaurant;
      case 'flight': return AppColors.flight;
      case 'hotel': return AppColors.hotel;
      case 'bus': return AppColors.transport;
      default: return AppColors.brandPrimary;
    }
  }

  IconData _getItemIcon(String type) {
    switch (type) {
      case 'attraction': return Icons.place_rounded;
      case 'restaurant': return Icons.restaurant_rounded;
      case 'flight': return Icons.flight_rounded;
      case 'hotel': return Icons.hotel_rounded;
      case 'bus': return Icons.directions_bus_rounded;
      default: return Icons.event_rounded;
    }
  }

  String _formatTimeSlot(String slot) {
    switch (slot) {
      case 'morning': return 'AM';
      case 'midday': return 'Noon';
      case 'evening': return 'PM';
      case 'night': return 'Night';
      default: return slot;
    }
  }

  // ────────────────────────────────────────────────────────────
  // Activities Preview
  // ────────────────────────────────────────────────────────────

  Widget _buildActivitiesPreview(BuildContext context) {
    final ew = context.ew;
    final allActivities = [...trip.attractions.take(3)];
    final totalCount = trip.attractions.length + trip.restaurants.length;
    final isEmpty = totalCount == 0;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => TripActivitiesScreen(trip: trip)),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ew.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.restaurant.withOpacity(0.15)),
          boxShadow: AppShadows.sm(Colors.black),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.restaurant.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.explore_rounded, size: 18, color: AppColors.restaurant),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(isEmpty ? 'Add Activities' : 'Activities & Dining', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                ),
                if (!isEmpty) ...[
                  Text('$totalCount places', style: TextStyle(fontSize: 12, color: ew.textSecondary)),
                  const SizedBox(width: 4),
                ],
                Icon(Icons.chevron_right_rounded, size: 20, color: ew.textTertiary),
              ],
            ),
            if (isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Find attractions & restaurants to visit', style: TextStyle(fontSize: 12, color: ew.textSecondary)),
              ),
            if (allActivities.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...allActivities.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: a.photoUrl.isNotEmpty
                            ? DecorationImage(image: NetworkImage(a.photoUrl), fit: BoxFit.cover)
                            : null,
                        color: a.photoUrl.isEmpty ? AppColors.attraction.withOpacity(0.1) : null,
                      ),
                      child: a.photoUrl.isEmpty ? const Icon(Icons.place_rounded, size: 14, color: AppColors.attraction) : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                          if (a.category.isNotEmpty)
                            Text(a.category, style: TextStyle(fontSize: 11, color: ew.textSecondary)),
                        ],
                      ),
                    ),
                    if (a.rating > 0)
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.star_rounded, size: 12, color: Color(0xFFFFC107)),
                        const SizedBox(width: 2),
                        Text(a.rating.toStringAsFixed(1), style: TextStyle(fontSize: 11, color: ew.textSecondary)),
                      ]),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // More Sections — compact list tiles
  // ────────────────────────────────────────────────────────────

  Widget _buildMoreSections(BuildContext context) {
    final ew = context.ew;
    final sections = [
      _ModuleItem(icon: Icons.account_balance_wallet_rounded, label: 'Finances', subtitle: 'Budget & expenses', color: AppColors.budget, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TripFinancesScreen(trip: trip)))),
      _ModuleItem(icon: Icons.description_rounded, label: 'Documents', subtitle: 'Passports, visas & bookings', color: AppColors.info, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TripDocumentsScreen(trip: trip)))),
      _ModuleItem(icon: Icons.photo_library_rounded, label: 'Photos', subtitle: 'Trip memories & gallery', color: AppColors.attraction, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TripPhotosScreen(trip: trip)))),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('More', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              color: ew.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppShadows.sm(Colors.black),
            ),
            child: Column(
              children: sections.asMap().entries.map((entry) {
                final i = entry.key;
                final item = entry.value;
                return Column(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: item.onTap,
                        borderRadius: i == 0
                            ? const BorderRadius.vertical(top: Radius.circular(16))
                            : i == sections.length - 1
                                ? const BorderRadius.vertical(bottom: Radius.circular(16))
                                : BorderRadius.zero,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              Container(
                                width: 38, height: 38,
                                decoration: BoxDecoration(
                                  color: item.color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(item.icon, size: 18, color: item.color),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.label, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 1),
                                    Text(item.subtitle, style: TextStyle(fontSize: 12, color: ew.textSecondary)),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded, size: 20, color: ew.textTertiary),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (i < sections.length - 1)
                      Divider(height: 1, indent: 68, color: Colors.grey.withOpacity(0.1)),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // Helpers
  // ────────────────────────────────────────────────────────────

  DateTime? _parseDateSafe(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      return DateTime.parse(dateStr.replaceAll(' ', 'T'));
    } catch (_) {
      return null;
    }
  }
}

class _ModuleItem {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ModuleItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}
