// ignore_for_file: unused_element, unused_local_variable
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/widgets.dart';
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
          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
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
    return AppScaffold(
      child: Column(
        children: [
          EWAppBar(title: 'Hotels'),
          Expanded(
            child: SingleChildScrollView(
              padding: AppSpacing.paddingHorizontalXl,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.md),
                  if (_trip.hotels.isNotEmpty) ...[
                    _buildSectionLabel('Saved Hotels', Icons.hotel_rounded),
                    const SizedBox(height: AppSpacing.sm),
                    ...List.generate(_trip.hotels.length, (i) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _buildHotelCard(_trip.hotels[i]),
                    )),
                  ] else ...[
                    _buildEmptyState(),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  _buildSearchButton(),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.brandPrimary),
        const SizedBox(width: AppSpacing.xs),
        Text(title, style: Theme.of(context).textTheme.titleMedium!.copyWith(color: context.ew.textPrimary)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.hotel_rounded, size: 64, color: AppColors.brandPrimary.withOpacity(0.3)),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No hotel saved yet',
            style: Theme.of(context).textTheme.titleMedium!.copyWith(color: context.ew.textPrimary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Search and save a hotel for your trip',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(color: context.ew.textSecondary),
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
          borderRadius: AppRadius.borderXl,
          border: isPaid ? Border.all(color: Colors.green.shade300, width: 1.5) : null,
          boxShadow: [
            BoxShadow(color: AppColors.brandPrimary.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 4)),
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
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'Paid · ${hotel.paidCurrency ?? hotel.currency}${hotel.actualPaidAmount?.toStringAsFixed(2) ?? ''}',
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w600, color: Colors.green.shade700),
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
                            const SizedBox(width: AppSpacing.xxs),
                            Text('Edit', style: Theme.of(context).textTheme.labelSmall!.copyWith(fontWeight: FontWeight.w600, color: Colors.green.shade700)),
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
                  borderRadius: AppRadius.borderMd,
                  child: hotel.photoUrl.isNotEmpty
                      ? Image.network(
                          hotel.photoUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _buildPlaceholderImage(),
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
                        style: Theme.of(context).textTheme.titleMedium!.copyWith(color: context.ew.textPrimary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Row(
                        children: [
                          if (hotel.stars > 0) ...[
                            ...List.generate(hotel.stars, (_) => const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFB800))),
                            const SizedBox(width: AppSpacing.xs),
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
                                style: Theme.of(context).textTheme.labelSmall!.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 14, color: context.ew.textSecondary),
                          const SizedBox(width: AppSpacing.xxs),
                          Expanded(
                            child: Text(
                              hotel.city,
                              style: Theme.of(context).textTheme.bodySmall!.copyWith(color: context.ew.textSecondary),
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
                      style: Theme.of(context).textTheme.headlineSmall!.copyWith(color: AppColors.brandPrimary),
                    ),
                    Text('total', style: Theme.of(context).textTheme.labelSmall!.copyWith(color: context.ew.textSecondary)),
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
                  decoration: BoxDecoration(color: AppColors.lightSurfaceVariant, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.brandPrimary),
                      const SizedBox(width: 6),
                      Text(
                        '${hotel.checkinDate} → ${hotel.checkoutDate}',
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w500, color: AppColors.brandPrimary),
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
                              const SizedBox(width: AppSpacing.xxs),
                              Text('Mark as Paid', style: Theme.of(context).textTheme.labelSmall!.copyWith(fontWeight: FontWeight.w600, color: Colors.green.shade700)),
                            ],
                          ),
                        ),
                      ),
                    if (!isPaid) const SizedBox(width: AppSpacing.xs),
                    GestureDetector(
                      onTap: _isLoadingBooking ? null : () => _openBookingLink(hotel),
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
                                  Text('Book', style: Theme.of(context).textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w600, color: Colors.white)),
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
        color: AppColors.lightSurfaceVariant,
        borderRadius: AppRadius.borderMd,
      ),
      child: Icon(Icons.hotel_rounded, size: 32, color: AppColors.brandPrimary.withOpacity(0.4)),
    );
  }

  Widget _buildSearchButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _navigateToSearch,
        icon: const Icon(Icons.search_rounded, color: Colors.white),
        label: Text('Search Hotels', style: Theme.of(context).textTheme.titleMedium!.copyWith(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandPrimary,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderLg),
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
        SnackBar(content: Text('Please fill all fields', style: const TextStyle()), backgroundColor: Colors.orange, behavior: SnackBarBehavior.floating),
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
            const SizedBox(height: AppSpacing.lg),
            Text('Mark as Paid', style: Theme.of(context).textTheme.headlineMedium!),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              widget.isEditing ? 'Edit hotel payment' : 'Hotel accommodation',
              style: Theme.of(context).textTheme.bodySmall!.copyWith(color: context.ew.textSecondary),
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
                    style: Theme.of(context).textTheme.bodyMedium!,
                    decoration: InputDecoration(
                      hintText: 'Amount paid',
                      hintStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(color: context.ew.textSecondary),
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
                        style: Theme.of(context).textTheme.bodyMedium!,
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
            Text('Who paid?', style: Theme.of(context).textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w600, color: context.ew.textPrimary)),
            const SizedBox(height: AppSpacing.xs),
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
                      color: selected ? AppColors.brandPrimary : AppColors.lightSurfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(m.displayName, style: Theme.of(context).textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w500, color: selected ? Colors.white : context.ew.textPrimary)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Paid for
            Text('Paid for', style: Theme.of(context).textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w600, color: context.ew.textPrimary)),
            const SizedBox(height: AppSpacing.xs),
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
                        Text(m.displayName, style: Theme.of(context).textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w500, color: selected ? Colors.white : context.ew.textPrimary)),
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
                    : Text(widget.isEditing ? 'Update Payment' : 'Confirm Payment', style: Theme.of(context).textTheme.titleMedium!.copyWith(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

