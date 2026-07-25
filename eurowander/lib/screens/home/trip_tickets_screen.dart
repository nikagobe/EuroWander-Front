// ignore_for_file: unused_element, unused_local_variable
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../models/saved_trip.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/widgets.dart';

class TripTicketsScreen extends StatefulWidget {
  final SavedTrip trip;

  const TripTicketsScreen({super.key, required this.trip});

  @override
  State<TripTicketsScreen> createState() => _TripTicketsScreenState();
}

class _TripTicketsScreenState extends State<TripTicketsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoadingBooking = false;
  List<TripMember> _members = [];
  late SavedTrip _trip;

  @override
  void initState() {
    super.initState();
    _trip = widget.trip;
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    try {
      final members = await _apiService.getTripMembers(token: token, tripId: _trip.id);
      if (mounted) setState(() => _members = members);
    } catch (_) {}
  }

  Future<void> _reloadTrip() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    try {
      final trips = await _apiService.getTrips(token: token);
      final updated = trips.where((t) => t.id == _trip.id).firstOrNull;
      if (updated != null && mounted) {
        setState(() => _trip = updated);
      }
    } catch (_) {}
  }

  Future<void> _openBookingLink(String flightType) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    setState(() => _isLoadingBooking = true);
    try {
      final url = await _apiService.getBookingLink(
        token: token,
        tripId: _trip.id,
        flight: flightType,
      );
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to get booking link: $e'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoadingBooking = false);
    }
  }

  void _showMarkPaidSheet(String flightType, dynamic flight) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MarkPaidSheet(
        members: _members,
        tripId: _trip.id,
        flightType: flightType,
        suggestedAmount: flight.price,
        onDone: _reloadTrip,
      ),
    );
  }

  void _showEditPaidSheet(String flightType, dynamic flight) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MarkPaidSheet(
        members: _members,
        tripId: _trip.id,
        flightType: flightType,
        suggestedAmount: flight.actualPaidAmount ?? flight.price,
        onDone: _reloadTrip,
        isEditing: true,
        initialCurrency: flight.paidCurrency ?? flight.currency ?? 'EUR',
        initialPaidBy: flight.paidBy,
        initialEligibleMemberIds: List<String>.from(flight.eligibleMemberIds ?? []),
      ),
    );
  }

  Future<void> _unmarkPaid(String flightType) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    try {
      await _apiService.unmarkFlightPaid(token: token, tripId: _trip.id, flightType: flightType);
      _reloadTrip();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red.shade600),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: Column(
        children: [
          const EWAppBar(title: 'Tickets'),
          Expanded(
            child: SingleChildScrollView(
              padding: AppSpacing.paddingHorizontalXl,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.md),
                  if (_trip.outboundFlight != null) ...[
                    _buildSectionLabel(context, 'Outbound Flight', Icons.flight_takeoff_rounded),
                    const SizedBox(height: AppSpacing.sm),
                    _buildFlightCard(context, _trip.outboundFlight!, 'outbound'),
                  ],
                  if (_trip.busJourney != null) ...[
                    const SizedBox(height: AppSpacing.xl),
                    _buildSectionLabel(context, 'Bus Transit', Icons.directions_bus_rounded),
                    const SizedBox(height: AppSpacing.sm),
                    _buildBusCard(context),
                  ],
                  if (_trip.returnFlight != null) ...[
                    const SizedBox(height: AppSpacing.xl),
                    _buildSectionLabel(context, 'Return Flight', Icons.flight_land_rounded),
                    const SizedBox(height: AppSpacing.sm),
                    _buildFlightCard(context, _trip.returnFlight!, 'return'),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  _buildPriceSummary(context),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.brandPrimary),
        const SizedBox(width: AppSpacing.xs),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }

  Widget _buildFlightCard(BuildContext context, dynamic flight, String flightType) {
    final ew = context.ew;
    final theme = Theme.of(context);
    final legs = flight.legs as List;
    if (legs.isEmpty) return const SizedBox.shrink();

    final firstLeg = legs.first;
    final lastLeg = legs.last;
    final bool isPaid = flight.isPaid == true;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: ew.cardColor,
        borderRadius: AppRadius.borderXl,
        border: isPaid ? Border.all(color: Colors.green.shade300, width: 1.5) : null,
        boxShadow: [
          BoxShadow(color: AppColors.brandPrimary.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Payment status badge
          if (isPaid)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded, size: 16, color: Colors.green.shade600),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Paid · ${flight.paidCurrency ?? '€'}${flight.paidCurrency != null && flight.paidCurrency != 'EUR' ? ' ' : ''}${flight.actualPaidAmount?.toStringAsFixed(2) ?? ''}',
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green.shade700),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showEditPaidSheet(flightType, flight),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_rounded, size: 12, color: Colors.green.shade700),
                          const SizedBox(width: AppSpacing.xxs),
                          Text('Edit', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.green.shade700)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Airline row
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  flight.airlineLogo,
                  width: 32,
                  height: 32,
                  errorBuilder: (_, __, ___) => Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.flight, size: 16),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(firstLeg.airline, style: theme.textTheme.labelLarge),
                    Text(firstLeg.flightNumber, style: theme.textTheme.labelSmall),
                  ],
                ),
              ),
              Text(
                '€${flight.price.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.brandPrimary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Route
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_formatFlightTime(flight.departureTime), style: theme.textTheme.headlineSmall),
                    Text(_formatShortDate(flight.departureTime), style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.brandPrimary)),
                    Text(flight.departureAirportId, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.brandPrimary)),
                    Text(
                      flight.departureAirportName.isNotEmpty ? flight.departureAirportName : firstLeg.departureAirportName,
                      style: GoogleFonts.poppins(fontSize: 10, color: ew.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Column(
                  children: [
                    Text('${flight.totalDuration ~/ 60}h ${flight.totalDuration % 60}m', style: theme.textTheme.labelSmall),
                    const SizedBox(height: AppSpacing.xxs),
                    Container(width: 50, height: 2, decoration: BoxDecoration(color: AppColors.brandPrimary.withOpacity(0.3), borderRadius: BorderRadius.circular(1))),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      flight.stops == 0 ? 'Direct' : '${flight.stops} stop(s)',
                      style: GoogleFonts.poppins(fontSize: 10, color: flight.stops == 0 ? Colors.green.shade600 : Colors.orange.shade700, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_formatFlightTime(flight.arrivalTime), style: theme.textTheme.headlineSmall),
                    Text(_formatShortDate(flight.arrivalTime), style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.brandPrimary)),
                    Text(flight.arrivalAirportId, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.brandPrimary)),
                    Text(
                      flight.arrivalAirportName.isNotEmpty ? flight.arrivalAirportName : lastLeg.arrivalAirportName,
                      style: GoogleFonts.poppins(fontSize: 10, color: ew.textSecondary), textAlign: TextAlign.end, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Date + actions
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppColors.lightSurfaceVariant, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.brandPrimary),
                    const SizedBox(width: 6),
                    Text(_formatFullDate(firstLeg.departureTime), style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.brandPrimary)),
                  ],
                ),
              ),
              const Spacer(),
              if (!isPaid)
                GestureDetector(
                  onTap: () => _showMarkPaidSheet(flightType, flight),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline_rounded, size: 14, color: Colors.green.shade600),
                        const SizedBox(width: AppSpacing.xxs),
                        Text('Mark as Paid', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.green.shade700)),
                      ],
                    ),
                  ),
                ),
              const SizedBox(width: AppSpacing.xs),
              GestureDetector(
                onTap: _isLoadingBooking ? null : () => _openBookingLink(flightType),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.brandPrimary, Color(0xFF8B5CF6)]),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: AppColors.brandPrimary.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: _isLoadingBooking
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.open_in_new_rounded, size: 14, color: Colors.white),
                            const SizedBox(width: 6),
                            Text('Book', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBusCard(BuildContext context) {
    final ew = context.ew;
    final theme = Theme.of(context);
    final bus = _trip.busJourney!;
    final bool isPaid = bus.isPaid == true;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: ew.cardColor,
        borderRadius: AppRadius.borderXl,
        border: isPaid ? Border.all(color: Colors.green.shade300, width: 1.5) : null,
        boxShadow: [BoxShadow(color: AppColors.brandPrimary.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          // Payment status badge
          if (isPaid)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded, size: 16, color: Colors.green.shade600),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Paid · ${bus.paidCurrency ?? '€'}${bus.paidCurrency != null && bus.paidCurrency != 'EUR' ? ' ' : ''}${bus.actualPaidAmount?.toStringAsFixed(2) ?? ''}',
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green.shade700),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showEditPaidSheet('bus', bus),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_rounded, size: 12, color: Colors.green.shade700),
                          const SizedBox(width: AppSpacing.xxs),
                          Text('Edit', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.green.shade700)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.directions_bus, size: 14, color: AppColors.success),
                    const SizedBox(width: AppSpacing.xxs),
                    Text('BUS', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.success)),
                  ],
                ),
              ),
              const Spacer(),
              Text('€${bus.price.toStringAsFixed(2)}', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.brandPrimary)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_formatFlightTime(bus.depTime), style: theme.textTheme.headlineSmall),
                    Text(_formatShortDate(bus.depTime), style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.brandPrimary)),
                    Text(bus.depName, style: theme.textTheme.labelSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Column(
                  children: [
                    Text(bus.duration, style: theme.textTheme.labelSmall),
                    const SizedBox(height: AppSpacing.xxs),
                    Container(width: 50, height: 2, decoration: BoxDecoration(color: AppColors.brandAmber.withOpacity(0.4), borderRadius: BorderRadius.circular(1))),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      bus.changeovers == 0 ? 'Direct' : '${bus.changeovers} change(s)',
                      style: GoogleFonts.poppins(fontSize: 10, color: bus.changeovers == 0 ? Colors.green.shade600 : Colors.orange.shade700, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_formatFlightTime(bus.arrTime), style: theme.textTheme.headlineSmall),
                    Text(_formatShortDate(bus.arrTime), style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.brandPrimary)),
                    Text(bus.arrName, style: theme.textTheme.labelSmall, textAlign: TextAlign.end, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppColors.lightSurfaceVariant, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.brandPrimary),
                    const SizedBox(width: 6),
                    Text(_formatFullDate(bus.depTime), style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.brandPrimary)),
                  ],
                ),
              ),
              const Spacer(),
              if (!isPaid)
                GestureDetector(
                  onTap: () => _showMarkPaidSheet('bus', bus),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline_rounded, size: 14, color: Colors.green.shade600),
                        const SizedBox(width: AppSpacing.xxs),
                        Text('Mark as Paid', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.green.shade700)),
                      ],
                    ),
                  ),
                ),
              if (!isPaid) const SizedBox(width: AppSpacing.xs),
              if (bus.deeplink.isNotEmpty)
                GestureDetector(
                  onTap: () async {
                    final uri = Uri.parse(bus.deeplink);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppColors.success, Color(0xFF66BB6A)]),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [BoxShadow(color: AppColors.success.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3))],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.open_in_new_rounded, size: 14, color: Colors.white),
                        const SizedBox(width: 6),
                        Text('Buy Ticket', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSummary(BuildContext context) {
    final outPrice = _trip.outboundFlight?.price ?? 0;
    final retPrice = _trip.returnFlight?.price ?? 0;
    final busPrice = _trip.busJourney?.price ?? 0;
    final total = outPrice + retPrice + busPrice;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.brandPrimary, AppColors.brandSecondary]),
        borderRadius: AppRadius.borderXl,
        boxShadow: [BoxShadow(color: AppColors.brandPrimary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Price', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.9))),
              Text(
                '${_trip.returnFlight != null ? "Round trip" : "One way"}${_trip.busJourney != null ? " + bus" : ""}',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.white.withOpacity(0.7)),
              ),
            ],
          ),
          Text('€${total.toStringAsFixed(0)}', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }

  String _formatFlightTime(String dateTimeStr) {
    try {
      final dt = DateTime.parse(dateTimeStr.replaceAll(' ', 'T'));
      return DateFormat('HH:mm').format(dt);
    } catch (_) {
      return dateTimeStr;
    }
  }

  String _formatShortDate(String dateTimeStr) {
    try {
      final dt = DateTime.parse(dateTimeStr.replaceAll(' ', 'T'));
      return DateFormat('MMM d').format(dt);
    } catch (_) {
      return '';
    }
  }

  String _formatFullDate(String dateTimeStr) {
    try {
      final dt = DateTime.parse(dateTimeStr.replaceAll(' ', 'T'));
      return DateFormat('EEE, MMM d yyyy').format(dt);
    } catch (_) {
      return dateTimeStr;
    }
  }
}

// ─── Mark Flight Paid Sheet ──────────────────────────────────────────

class _MarkPaidSheet extends StatefulWidget {
  final List<TripMember> members;
  final String tripId;
  final String flightType;
  final double suggestedAmount;
  final VoidCallback onDone;
  final bool isEditing;
  final String? initialCurrency;
  final String? initialPaidBy;
  final List<String>? initialEligibleMemberIds;

  const _MarkPaidSheet({
    required this.members,
    required this.tripId,
    required this.flightType,
    required this.suggestedAmount,
    required this.onDone,
    this.isEditing = false,
    this.initialCurrency,
    this.initialPaidBy,
    this.initialEligibleMemberIds,
  });

  @override
  State<_MarkPaidSheet> createState() => _MarkPaidSheetState();
}

class _MarkPaidSheetState extends State<_MarkPaidSheet> {
  late final TextEditingController _amountController;
  String _currency = 'EUR';
  String? _paidBy;
  final Set<String> _selectedMembers = {};
  bool _isSaving = false;

  final _currencies = ['EUR', 'USD', 'GBP', 'GEL', 'CHF', 'CZK', 'PLN', 'HUF', 'SEK', 'NOK', 'DKK'];

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.suggestedAmount.toStringAsFixed(2));
    if (widget.initialCurrency != null) {
      _currency = widget.initialCurrency!;
    }
    if (widget.isEditing && widget.initialPaidBy != null) {
      _paidBy = widget.initialPaidBy;
    }
    if (widget.isEditing && widget.initialEligibleMemberIds != null && widget.initialEligibleMemberIds!.isNotEmpty) {
      _selectedMembers.addAll(widget.initialEligibleMemberIds!);
    } else {
      for (final m in widget.members) {
        _selectedMembers.add(m.userId);
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amountStr = _amountController.text.trim();
    if (amountStr.isEmpty || _paidBy == null || _selectedMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields', style: GoogleFonts.poppins()), backgroundColor: Colors.orange, behavior: SnackBarBehavior.floating),
      );
      return;
    }
    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) return;

    setState(() => _isSaving = true);
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    try {
      await ApiService().markFlightPaid(
        token: token,
        tripId: widget.tripId,
        flightType: widget.flightType,
        actualPaidAmount: amount,
        paidBy: _paidBy!,
        eligibleMemberIds: _selectedMembers.toList(),
        currency: _currency,
      );
      if (!mounted) return;
      widget.onDone();
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red.shade600),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ew = context.ew;
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
      decoration: BoxDecoration(
        color: ew.cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(left: AppSpacing.xl, right: AppSpacing.xl, top: AppSpacing.md, bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Mark as Paid', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              widget.isEditing
                  ? 'Edit ${widget.flightType[0].toUpperCase()}${widget.flightType.substring(1)}${widget.flightType == 'bus' ? '' : ' flight'} payment'
                  : '${widget.flightType[0].toUpperCase()}${widget.flightType.substring(1)}${widget.flightType == 'bus' ? '' : ' flight'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            // Amount + currency
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: GoogleFonts.poppins(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Amount paid',
                      hintStyle: GoogleFonts.poppins(color: ew.textSecondary, fontSize: 14),
                      prefixIcon: const Icon(Icons.attach_money_rounded, size: 20, color: AppColors.brandPrimary),
                      filled: true,
                      fillColor: AppColors.lightSurfaceVariant,
                      border: OutlineInputBorder(borderRadius: AppRadius.borderLg, borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: AppColors.lightSurfaceVariant, borderRadius: AppRadius.borderLg),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _currency,
                        isExpanded: true,
                        style: GoogleFonts.poppins(fontSize: 14, color: ew.textPrimary),
                        items: _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (v) => setState(() => _currency = v ?? 'EUR'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            // Paid by
            Text('Who paid?', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: ew.textPrimary)),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: widget.members.map((m) {
                final selected = _paidBy == m.userId;
                return GestureDetector(
                  onTap: () => setState(() => _paidBy = m.userId),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.brandPrimary : AppColors.lightSurfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(m.displayName, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: selected ? Colors.white : ew.textPrimary)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Paid for
            Text('Paid for', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: ew.textPrimary)),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: widget.members.map((m) {
                final selected = _selectedMembers.contains(m.userId);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (selected) {
                        _selectedMembers.remove(m.userId);
                      } else {
                        _selectedMembers.add(m.userId);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.success : AppColors.lightSurfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (selected) ...[
                          const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                          const SizedBox(width: AppSpacing.xxs),
                        ],
                        Text(m.displayName, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: selected ? Colors.white : ew.textPrimary)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.borderLg),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(widget.isEditing ? 'Update Payment' : 'Confirm Payment', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}




