import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/hotel.dart';
import '../../../services/api_service.dart';

/// Hotel detail screen for template creation.
/// Same as HotelDetailScreen but with "Recommend This Hotel" button.
/// Pops with true/false to toggle the pick state in the picker.
class TemplateHotelDetailScreen extends StatefulWidget {
  final int hotelId;
  final String arrivalDate;
  final String departureDate;
  final bool isPicked;
  final int adults;
  final int rooms;

  const TemplateHotelDetailScreen({
    super.key,
    required this.hotelId,
    required this.arrivalDate,
    required this.departureDate,
    this.isPicked = false,
    this.adults = 1,
    this.rooms = 1,
  });

  @override
  State<TemplateHotelDetailScreen> createState() => _TemplateHotelDetailScreenState();
}

class _TemplateHotelDetailScreenState extends State<TemplateHotelDetailScreen> {
  final ApiService _apiService = ApiService();
  HotelDetails? _details;
  bool _isLoading = true;
  late bool _isPicked;

  @override
  void initState() {
    super.initState();
    _isPicked = widget.isPicked;
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final details = await _apiService.getHotelDetails(
      hotelId: widget.hotelId,
      arrivalDate: widget.arrivalDate,
      departureDate: widget.departureDate,
      adults: widget.adults,
      roomQty: widget.rooms,
    );
    if (mounted) setState(() { _details = details; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFF8F5FF), Color(0xFFEDE7F6), Color(0xFFF3E5F5)])),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
              : _details == null
                  ? _buildError()
                  : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.error_outline_rounded, size: 56, color: Colors.grey.shade400),
      const SizedBox(height: 12),
      Text('Failed to load hotel details', style: GoogleFonts.poppins(fontSize: 16, color: AppTheme.textSecondary)),
      const SizedBox(height: 16),
      TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Go Back', style: GoogleFonts.poppins(color: AppTheme.primaryColor))),
    ]));
  }

  Widget _buildContent() {
    final hotel = _details!;
    return Column(children: [
      // App bar
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(width: 42, height: 42, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))]), child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppTheme.textPrimary)),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(hotel.name, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
      ),
      Expanded(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildPhotoGallery(hotel),
              Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _buildHeader(hotel),
                const SizedBox(height: 20),
                _buildPriceCard(hotel),
                const SizedBox(height: 20),
                _buildInfoSection(hotel),
                const SizedBox(height: 20),
                _buildMap(hotel),
                if (hotel.facilities.isNotEmpty) ...[const SizedBox(height: 20), _buildFacilities(hotel)],
                if (hotel.rooms.isNotEmpty) ...[const SizedBox(height: 20), _buildRooms(hotel)],
                const SizedBox(height: 100),
              ])),
            ])),
          ),
        ),
      ),
      // Bottom bar with "Recommend This Hotel"
      _buildBottomBar(hotel),
    ]);
  }

  Widget _buildPhotoGallery(HotelDetails hotel) {
    if (hotel.photos.isEmpty) return Container(height: 220, color: Colors.grey.shade200, child: Center(child: Icon(Icons.hotel_rounded, size: 56, color: Colors.grey.shade400)));
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal, physics: const BouncingScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: hotel.photos.length, separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.network(hotel.photos[i], width: 300, height: 220, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 300, height: 220, color: Colors.grey.shade200, child: Icon(Icons.broken_image_rounded, size: 48, color: Colors.grey.shade400)))),
      ),
    );
  }

  Widget _buildHeader(HotelDetails hotel) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(hotel.name, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
      const SizedBox(height: 6),
      if (hotel.stars > 0) Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: List.generate(hotel.stars, (_) => const Icon(Icons.star_rounded, size: 18, color: Colors.amber)))),
      Row(children: [
        Icon(Icons.place_rounded, size: 16, color: AppTheme.textSecondary), const SizedBox(width: 4),
        Expanded(child: Text([hotel.address, hotel.district, hotel.city, hotel.country].where((s) => s.isNotEmpty).join(', '), style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis)),
      ]),
      if (hotel.distanceToCenterKm > 0) ...[const SizedBox(height: 6), Row(children: [Icon(Icons.straighten_rounded, size: 16, color: AppTheme.textSecondary), const SizedBox(width: 4), Text('${hotel.distanceToCenterKm.toStringAsFixed(1)} km from centre', style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary))])],
      if (hotel.reviewScore > 0) ...[const SizedBox(height: 10), Row(children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: _reviewColor(hotel.reviewScore), borderRadius: BorderRadius.circular(6)), child: Text(hotel.reviewScore.toStringAsFixed(1), style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white))),
        const SizedBox(width: 8), Text('${hotel.reviewScoreWord} · ${hotel.reviewCount} reviews', style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary)),
      ])],
      if (hotel.description.isNotEmpty) ...[const SizedBox(height: 14), Text(hotel.description, style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary, height: 1.5), maxLines: 5, overflow: TextOverflow.ellipsis)],
    ]);
  }

  Widget _buildPriceCard(HotelDetails hotel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))]),
      child: Column(children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Price per night', style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(height: 2),
            Text('€${hotel.pricePerNight.toStringAsFixed(2)}', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
          ])),
          Container(width: 1, height: 48, color: Colors.grey.shade200), const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Total stay', style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(height: 2),
            Text('€${hotel.priceTotal.toStringAsFixed(2)}', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          ])),
        ]),
        if (hotel.priceExcluded > 0) ...[const SizedBox(height: 8), Row(children: [Icon(Icons.info_outline_rounded, size: 14, color: Colors.grey.shade500), const SizedBox(width: 6), Text('+ €${hotel.priceExcluded.toStringAsFixed(2)} taxes & fees', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500))])],
      ]),
    );
  }

  Widget _buildInfoSection(HotelDetails hotel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))]),
      child: Column(children: [
        _infoRow(Icons.apartment_rounded, 'Type', hotel.accommodationType),
        if (hotel.availableRooms > 0) _infoRow(Icons.meeting_room_rounded, 'Available rooms', '${hotel.availableRooms}'),
        _infoRow(Icons.breakfast_dining_rounded, 'Breakfast', hotel.breakfastIncluded ? 'Included' : 'Not included'),
        _infoRow(Icons.login_rounded, 'Check-in', '${hotel.checkinFrom}${hotel.checkinUntil.isNotEmpty ? ' – ${hotel.checkinUntil}' : ''}'),
        _infoRow(Icons.logout_rounded, 'Check-out', '${hotel.checkoutFrom.isNotEmpty ? '${hotel.checkoutFrom} – ' : ''}${hotel.checkoutUntil}'),
      ]),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [Icon(icon, size: 18, color: AppTheme.primaryColor), const SizedBox(width: 12), Text(label, style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary)), const Spacer(), Text(value, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textPrimary))]));

  Widget _buildFacilities(HotelDetails hotel) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Facilities', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: hotel.facilities.map((f) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.08), borderRadius: BorderRadius.circular(20)), child: Text(f, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.primaryColor)))).toList()),
    ]);
  }

  Widget _buildMap(HotelDetails hotel) {
    if (hotel.latitude == 0 && hotel.longitude == 0) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Location', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
      const SizedBox(height: 12),
      ClipRRect(borderRadius: BorderRadius.circular(16), child: SizedBox(height: 180, child: FlutterMap(
        options: MapOptions(initialCenter: LatLng(hotel.latitude, hotel.longitude), initialZoom: 15, interactionOptions: const InteractionOptions(flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag)),
        children: [
          TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.eurowander.app'),
          MarkerLayer(markers: [Marker(point: LatLng(hotel.latitude, hotel.longitude), width: 40, height: 40, child: Container(decoration: BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))]), child: const Icon(Icons.hotel_rounded, size: 18, color: Colors.white)))]),
        ],
      ))),
    ]);
  }

  Widget _buildRooms(HotelDetails hotel) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Rooms', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
      const SizedBox(height: 12),
      ...hotel.rooms.map((room) => Container(
        margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(room.description, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          if (room.roomSurfaceM2 > 0) ...[const SizedBox(height: 4), Text('${room.roomSurfaceM2.toStringAsFixed(0)} m²', style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary))],
          if (room.bedConfigurations.isNotEmpty) ...[const SizedBox(height: 8), Wrap(spacing: 6, runSpacing: 4, children: room.bedConfigurations.map((bed) => Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.bed_rounded, size: 14, color: AppTheme.textSecondary), const SizedBox(width: 4), Text(bed, style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary))])).toList())],
          if (room.highlights.isNotEmpty) ...[const SizedBox(height: 8), Wrap(spacing: 6, runSpacing: 4, children: room.highlights.map((h) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)), child: Text(h.name, style: GoogleFonts.poppins(fontSize: 11, color: Colors.green.shade700)))).toList())],
          if (room.photos.isNotEmpty) ...[const SizedBox(height: 10), SizedBox(height: 80, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: room.photos.length, separatorBuilder: (_, __) => const SizedBox(width: 8), itemBuilder: (_, i) => ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(room.photos[i], width: 100, height: 80, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 100, height: 80, color: Colors.grey.shade200)))))],
        ]),
      )),
    ]);
  }

  Widget _buildBottomBar(HotelDetails hotel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -4))]),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text('€${hotel.priceTotal.toStringAsFixed(2)}', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
              Text('total', style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary)),
            ]),
            const SizedBox(width: 20),
            Expanded(child: SizedBox(height: 50, child: ElevatedButton.icon(
              onPressed: () {
                setState(() => _isPicked = !_isPicked);
                Navigator.of(context).pop(_isPicked);
              },
              icon: Icon(_isPicked ? Icons.star_rounded : Icons.star_border_rounded, size: 20),
              label: Text(_isPicked ? 'Recommended ✓' : 'Recommend This Hotel', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: _isPicked ? const Color(0xFFFF9800) : AppTheme.primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
            ))),
          ]),
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
