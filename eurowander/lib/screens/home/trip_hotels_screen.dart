import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../models/saved_trip.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import 'hotel_detail_screen.dart';
import 'hotel_search_screen.dart';

class TripHotelsScreen extends StatefulWidget {
  final SavedTrip trip;

  const TripHotelsScreen({super.key, required this.trip});

  @override
  State<TripHotelsScreen> createState() => _TripHotelsScreenState();
}

class _TripHotelsScreenState extends State<TripHotelsScreen> {
  final ApiService _apiService = ApiService();
  List<TripMember> _members = [];
  late SavedTrip _trip;
  bool _isLoadingBooking = false;

  @override
  void initState() {
    super.initState();
    _trip = widget.trip;
    _loadMembers();
    _reloadTrip();
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

  void _showMarkPaidSheet(SavedHotel hotel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HotelMarkPaidSheet(
        members: _members,
        tripId: _trip.id,
        hotelId: hotel.hotelId,
        suggestedAmount: hotel.priceTotal,
        suggestedCurrency: hotel.currency,
        onDone: _reloadTrip,
      ),
    );
  }

  void _showEditPaidSheet(SavedHotel hotel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HotelMarkPaidSheet(
        members: _members,
        tripId: _trip.id,
        hotelId: hotel.hotelId,
        suggestedAmount: hotel.actualPaidAmount ?? hotel.priceTotal,
        suggestedCurrency: hotel.paidCurrency ?? hotel.currency,
        onDone: _reloadTrip,
        isEditing: true,
        initialPaidBy: hotel.paidBy,
        initialEligibleMemberIds: hotel.eligibleMemberIds != null
            ? List<String>.from(hotel.eligibleMemberIds!)
            : null,
      ),
    );
  }

  Future<void> _removeHotel(SavedHotel hotel) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    try {
      await _apiService.removeHotelFromTrip(token: token, tripId: _trip.id, hotelId: hotel.hotelId);
      _reloadTrip();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red.shade600),
      );
    }
  }

  Future<void> _openBookingLink(SavedHotel hotel) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    setState(() => _isLoadingBooking = true);
    try {
      final url = await _apiService.getHotelBookingLink(
        token: token,
        tripId: _trip.id,
        hotelId: hotel.hotelId,
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoadingBooking = false);
    }
  }

  void _navigateToSearch() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => HotelSearchScreen(trip: _trip)),
    );
    if (result == true) {
      _reloadTrip();
    }
  }

  void _navigateToDetails(SavedHotel hotel) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HotelDetailScreen(
          hotelId: hotel.hotelId,
          arrivalDate: hotel.checkinDate,
          departureDate: hotel.checkoutDate,
          trip: _trip,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF8F5FF), Color(0xFFEDE7F6), Color(0xFFF3E5F5)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  _buildAppBar(context),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          if (_trip.hotels.isNotEmpty) ...[
                            _buildSectionLabel('Saved Hotels', Icons.hotel_rounded),
                            const SizedBox(height: 12),
                            ...List.generate(_trip.hotels.length, (i) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildHotelCard(_trip.hotels[i]),
                            )),
                          ] else ...[
                            _buildEmptyState(),
                          ],
                          const SizedBox(height: 24),
                          _buildSearchButton(),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppTheme.textPrimary),
            ),
          ),
          const SizedBox(width: 16),
          Text('Hotels', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Text(title, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.hotel_rounded, size: 64, color: AppTheme.primaryColor.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'No hotel saved yet',
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Search and save a hotel for your trip',
            style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildHotelCard(SavedHotel hotel) {
    final bool isPaid = hotel.isPaid;

    return GestureDetector(
      onTap: () => _navigateToDetails(hotel),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: isPaid ? Border.all(color: Colors.green.shade300, width: 1.5) : null,
          boxShadow: [
            BoxShadow(color: AppTheme.primaryColor.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Paid · ${hotel.paidCurrency ?? hotel.currency}${hotel.actualPaidAmount?.toStringAsFixed(2) ?? ''}',
                        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green.shade700),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showEditPaidSheet(hotel),
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
                            const SizedBox(width: 4),
                            Text('Edit', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.green.shade700)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Hotel photo + info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: hotel.photoUrl.isNotEmpty
                      ? Image.network(
                          hotel.photoUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                        )
                      : _buildPlaceholderImage(),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hotel.name,
                        style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (hotel.stars > 0) ...[
                            ...List.generate(hotel.stars, (_) => const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFB800))),
                            const SizedBox(width: 8),
                          ],
                          if (hotel.reviewScore > 0) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _reviewColor(hotel.reviewScore),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                hotel.reviewScore.toStringAsFixed(1),
                                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              hotel.city,
                              style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${hotel.currency == 'EUR' ? '€' : hotel.currency}${hotel.priceTotal.toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                    ),
                    Text('total', style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Dates + actions
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFFF8F5FF), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 13, color: AppTheme.primaryColor),
                      const SizedBox(width: 6),
                      Text(
                        '${hotel.checkinDate} → ${hotel.checkoutDate}',
                        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.primaryColor),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isPaid)
                      GestureDetector(
                        onTap: () => _showMarkPaidSheet(hotel),
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
                              const SizedBox(width: 4),
                              Text('Mark as Paid', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.green.shade700)),
                            ],
                          ),
                        ),
                      ),
                    if (!isPaid) const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _isLoadingBooking ? null : () => _openBookingLink(hotel),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AppTheme.primaryColor, Color(0xFF8B5CF6)]),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3))],
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
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.hotel_rounded, size: 32, color: AppTheme.primaryColor.withOpacity(0.4)),
    );
  }

  Widget _buildSearchButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _navigateToSearch,
        icon: const Icon(Icons.search_rounded, color: Colors.white),
        label: Text('Search Hotels', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),
    );
  }

  Color _reviewColor(double score) {
    if (score >= 9) return const Color(0xFF1B5E20);
    if (score >= 8) return const Color(0xFF2E7D32);
    if (score >= 7) return const Color(0xFF558B2F);
    if (score >= 6) return const Color(0xFFF9A825);
    return Colors.grey;
  }
}

// ─── Mark Hotel Paid Sheet ───────────────────────────────────────────

class _HotelMarkPaidSheet extends StatefulWidget {
  final List<TripMember> members;
  final String tripId;
  final int hotelId;
  final double suggestedAmount;
  final String suggestedCurrency;
  final VoidCallback onDone;
  final bool isEditing;
  final String? initialPaidBy;
  final List<String>? initialEligibleMemberIds;

  const _HotelMarkPaidSheet({
    required this.members,
    required this.tripId,
    required this.hotelId,
    required this.suggestedAmount,
    required this.suggestedCurrency,
    required this.onDone,
    this.isEditing = false,
    this.initialPaidBy,
    this.initialEligibleMemberIds,
  });

  @override
  State<_HotelMarkPaidSheet> createState() => _HotelMarkPaidSheetState();
}

class _HotelMarkPaidSheetState extends State<_HotelMarkPaidSheet> {
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
    _currency = widget.suggestedCurrency;
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
      await ApiService().markHotelPaid(
        token: token,
        tripId: widget.tripId,
        hotelId: widget.hotelId,
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
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(left: 24, right: 24, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 20),
            Text('Mark as Paid', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 4),
            Text(
              widget.isEditing ? 'Edit hotel payment' : 'Hotel accommodation',
              style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 20),
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
                      hintStyle: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 14),
                      prefixIcon: const Icon(Icons.attach_money_rounded, size: 20, color: AppTheme.primaryColor),
                      filled: true,
                      fillColor: const Color(0xFFF8F5FF),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: const Color(0xFFF8F5FF), borderRadius: BorderRadius.circular(14)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _currency,
                        isExpanded: true,
                        style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textPrimary),
                        items: _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (v) => setState(() => _currency = v ?? 'EUR'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Paid by
            Text('Who paid?', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.members.map((m) {
                final selected = _paidBy == m.userId;
                return GestureDetector(
                  onTap: () => setState(() => _paidBy = m.userId),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.primaryColor : const Color(0xFFF8F5FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(m.displayName, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: selected ? Colors.white : AppTheme.textPrimary)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            // Paid for
            Text('Paid for', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
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
                      color: selected ? const Color(0xFF4CAF50) : const Color(0xFFF8F5FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (selected) ...[
                          const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                        ],
                        Text(m.displayName, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: selected ? Colors.white : AppTheme.textPrimary)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
