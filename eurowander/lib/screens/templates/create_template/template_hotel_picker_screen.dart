import 'dart:async';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/hotel.dart';
import '../../../models/template.dart';
import '../../../services/api_service.dart';
import 'template_hotel_detail_screen.dart';

/// Full-screen hotel search for template creation.
/// Auto-searches on open with pre-filled city & dates.
/// Returns List<HotelPick> on pop.
class TemplateHotelPickerScreen extends StatefulWidget {
  final String city;
  final int days;
  final List<HotelPick> existingPicks;

  const TemplateHotelPickerScreen({
    super.key,
    required this.city,
    this.days = 2,
    this.existingPicks = const [],
  });

  @override
  State<TemplateHotelPickerScreen> createState() => _TemplateHotelPickerScreenState();
}

class _TemplateHotelPickerScreenState extends State<TemplateHotelPickerScreen> {
  final ApiService _apiService = ApiService();
  final MapController _mapController = MapController();
  final ScrollController _listScrollController = ScrollController();

  List<HotelOffer> _hotels = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  int? _selectedHotelIndex;
  int _currentPage = 1;
  bool _hasMorePages = true;

  // Hotel name search
  final TextEditingController _nameController = TextEditingController();
  Timer? _nameDebounce;
  String? _nameFilter;

  // Pre-filled search params
  late DateTime _arrivalDate;
  late DateTime _departureDate;
  HotelDestination? _destination;

  // Picks
  final Map<int, HotelPick> _pickedHotels = {};

  @override
  void initState() {
    super.initState();
    _arrivalDate = DateTime.now().add(const Duration(days: 14));
    _departureDate = _arrivalDate.add(Duration(days: widget.days));

    for (final pick in widget.existingPicks) {
      _pickedHotels[pick.bookingHotelId] = pick;
    }

    // Auto-search immediately
    _autoSearch();
  }

  Future<void> _autoSearch() async {
    final dests = await _apiService.searchHotelDestinations(query: widget.city);
    if (dests.isNotEmpty && mounted) {
      _destination = dests.first;
      _searchHotels();
    }
  }

  @override
  void dispose() {
    _listScrollController.dispose();
    _nameController.dispose();
    _nameDebounce?.cancel();
    super.dispose();
  }

  Future<void> _searchHotels({int page = 1}) async {
    if (_destination == null && (_nameFilter == null || _nameFilter!.length < 2)) return;
    setState(() { _isSearching = true; _hasSearched = true; _currentPage = page; _selectedHotelIndex = null; });

    try {
      List<HotelOffer> results;
      if (_nameFilter != null && _nameFilter!.length >= 2) {
        // Name search — dedicated endpoint
        final cityPrefix = _destination?.cityName ?? widget.city;
        results = await _apiService.searchHotelsByName(
          query: '$cityPrefix ${_nameFilter!}'.trim(),
          arrivalDate: _formatDate(_arrivalDate),
          departureDate: _formatDate(_departureDate),
        );
      } else {
        // Browse mode
        results = await _apiService.searchHotels(
          destId: _destination!.destId,
          arrivalDate: _formatDate(_arrivalDate),
          departureDate: _formatDate(_departureDate),
          pageNumber: page,
        );
      }
      if (mounted) setState(() { _hotels = results; _hasMorePages = _nameFilter == null && results.length >= 20; });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Search failed: $e'), backgroundColor: Colors.red.shade600, behavior: SnackBarBehavior.floating));
    }
    if (mounted) setState(() => _isSearching = false);
  }

  String _formatDate(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _togglePick(HotelOffer hotel) {
    setState(() {
      if (_pickedHotels.containsKey(hotel.hotelId)) {
        _pickedHotels.remove(hotel.hotelId);
      } else {
        _pickedHotels[hotel.hotelId] = HotelPick(
          bookingHotelId: hotel.hotelId, name: hotel.name, city: widget.city,
          neighborhood: '', stars: hotel.stars, photoUrl: hotel.photoUrl,
          authorReview: '', priority: _pickedHotels.length + 1,
          pricePaid: hotel.pricePerNight, currency: hotel.currency,
        );
      }
    });
  }

  void _openDetail(HotelOffer hotel) async {
    final picked = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => TemplateHotelDetailScreen(
        hotelId: hotel.hotelId,
        arrivalDate: _formatDate(_arrivalDate),
        departureDate: _formatDate(_departureDate),
        isPicked: _pickedHotels.containsKey(hotel.hotelId),
      )),
    );
    if (picked == true && !_pickedHotels.containsKey(hotel.hotelId)) {
      _togglePick(hotel);
    } else if (picked == false && _pickedHotels.containsKey(hotel.hotelId)) {
      _togglePick(hotel);
    }
  }

  List<HotelPick> _buildFinalPicks() {
    int priority = 1;
    return _pickedHotels.values.map((p) => HotelPick(
      bookingHotelId: p.bookingHotelId, name: p.name, city: p.city,
      neighborhood: p.neighborhood, stars: p.stars, photoUrl: p.photoUrl,
      authorReview: p.authorReview, priority: priority++,
      pricePaid: p.pricePaid, currency: p.currency,
    )).toList();
  }

  Color _reviewColor(double score) {
    if (score >= 9) return const Color(0xFF1B5E20);
    if (score >= 8) return const Color(0xFF2E7D32);
    if (score >= 7) return const Color(0xFF558B2F);
    if (score >= 6) return const Color(0xFFF9A825);
    return Colors.grey;
  }

  void _scrollToHotel(int index) {
    const cardHeight = 172.0;
    _listScrollController.animateTo(index * cardHeight, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _buildFinalPicks());
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFF8F5FF), Color(0xFFEDE7F6), Color(0xFFF3E5F5)])),
          child: SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                if (_pickedHotels.isNotEmpty) _buildPickedBar(),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context, _buildFinalPicks()),
            child: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))]),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppTheme.textPrimary),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text('Hotels in ${widget.city}', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary))),
        ],
      ),
    );
  }

  Widget _buildPickedBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFFF9800).withOpacity(0.4))),
      child: Row(
        children: [
          const Text('⭐', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(child: Text('${_pickedHotels.length} hotel${_pickedHotels.length == 1 ? '' : 's'} recommended', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFE65100)))),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (!_hasSearched) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
    }

    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Column(children: [
            // Hotel name search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: TextField(
                controller: _nameController,
                style: GoogleFonts.poppins(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search by hotel name...',
                  hintStyle: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary),
                  prefixIcon: const Icon(Icons.search, size: 18, color: AppTheme.textSecondary),
                  suffixIcon: _nameFilter != null && _nameFilter!.isNotEmpty
                      ? GestureDetector(
                          onTap: () { _nameController.clear(); setState(() => _nameFilter = null); _searchHotels(); },
                          child: const Icon(Icons.close, size: 18, color: AppTheme.textSecondary),
                        )
                      : null,
                  filled: true, fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  isDense: true,
                ),
                onChanged: (v) {
                  _nameDebounce?.cancel();
                  _nameDebounce = Timer(const Duration(milliseconds: 400), () {
                    setState(() => _nameFilter = v.isEmpty ? null : v);
                    _searchHotels();
                  });
                },
              ),
            ),
            // Hotel list or loading/empty state
            Expanded(
              child: _isSearching
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                  : _hotels.isEmpty
                      ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.hotel_rounded, size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 8),
                          Text('No hotels found', style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textSecondary)),
                          const SizedBox(height: 4),
                          Text('Try a different name or filters', style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary)),
                        ]))
                      : ListView.builder(
                          controller: _listScrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: _hotels.length,
                          itemBuilder: (_, i) => _buildHotelCard(i),
                        ),
            ),
            _buildPagination(),
          ]),
        ),
        Expanded(flex: 5, child: _buildMap()),
      ],
    );
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, -2))]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _pageBtn(Icons.chevron_left_rounded, _currentPage > 1 ? () => _searchHotels(page: _currentPage - 1) : null),
          const SizedBox(width: 16),
          Text('Page $_currentPage', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          const SizedBox(width: 16),
          _pageBtn(Icons.chevron_right_rounded, _hasMorePages ? () => _searchHotels(page: _currentPage + 1) : null),
        ],
      ),
    );
  }

  Widget _pageBtn(IconData icon, VoidCallback? onTap) {
    final ok = onTap != null;
    return GestureDetector(onTap: onTap, child: Container(width: 36, height: 36, decoration: BoxDecoration(color: ok ? AppTheme.primaryColor : Colors.grey.shade200, borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 22, color: ok ? Colors.white : Colors.grey.shade400)));
  }

  Widget _buildMap() {
    final bounds = _calcBounds();
    return ClipRRect(
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(initialCenter: bounds.center, initialZoom: 12, onTap: (_, __) => setState(() => _selectedHotelIndex = null)),
        children: [
          TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.eurowander.app'),
          MarkerLayer(
            markers: _hotels.asMap().entries.map((entry) {
              final i = entry.key; final h = entry.value;
              final sel = i == _selectedHotelIndex;
              final picked = _pickedHotels.containsKey(h.hotelId);
              return Marker(
                point: LatLng(h.latitude, h.longitude), width: sel ? 48 : 36, height: sel ? 48 : 36,
                child: GestureDetector(
                  onTap: () { setState(() => _selectedHotelIndex = i); _mapController.move(LatLng(h.latitude, h.longitude), 14); _scrollToHotel(i); },
                  child: Container(
                    decoration: BoxDecoration(
                      color: picked ? const Color(0xFFFF9800) : sel ? AppTheme.primaryColor : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: picked ? const Color(0xFFFF9800) : sel ? AppTheme.primaryColor : Colors.orange.shade400, width: 2),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 2))],
                    ),
                    child: Center(child: picked ? const Icon(Icons.star_rounded, size: 16, color: Colors.white) : Text('€${h.pricePerNight.toInt()}', style: GoogleFonts.poppins(fontSize: sel ? 10 : 8, fontWeight: FontWeight.w700, color: sel ? Colors.white : Colors.orange.shade700))),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  LatLngBounds _calcBounds() {
    if (_hotels.isEmpty) return LatLngBounds(LatLng(48.8, 2.3), LatLng(48.9, 2.4));
    double minLat = _hotels.first.latitude, maxLat = minLat, minLng = _hotels.first.longitude, maxLng = minLng;
    for (final h in _hotels) { if (h.latitude < minLat) minLat = h.latitude; if (h.latitude > maxLat) maxLat = h.latitude; if (h.longitude < minLng) minLng = h.longitude; if (h.longitude > maxLng) maxLng = h.longitude; }
    return LatLngBounds(LatLng(minLat - 0.01, minLng - 0.01), LatLng(maxLat + 0.01, maxLng + 0.01));
  }

  Widget _buildHotelCard(int index) {
    final hotel = _hotels[index];
    final isSel = index == _selectedHotelIndex;
    final isPicked = _pickedHotels.containsKey(hotel.hotelId);

    return GestureDetector(
      onTap: () { setState(() => _selectedHotelIndex = index); _mapController.move(LatLng(hotel.latitude, hotel.longitude), 14); },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: isSel ? Border.all(color: AppTheme.primaryColor, width: 1.5) : isPicked ? Border.all(color: const Color(0xFFFF9800).withOpacity(0.6), width: 1.5) : null,
          boxShadow: [BoxShadow(color: isSel ? AppTheme.primaryColor.withOpacity(0.12) : Colors.black.withOpacity(0.04), blurRadius: isSel ? 16 : 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(hotel.photoUrl, width: 100, height: 100, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 100, height: 100, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)), child: Icon(Icons.hotel_rounded, size: 32, color: Colors.grey.shade400))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(hotel.name, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  if (hotel.stars > 0) Row(children: List.generate(hotel.stars, (_) => const Icon(Icons.star_rounded, size: 14, color: Colors.amber))),
                  const SizedBox(height: 4),
                  if (hotel.reviewScore > 0) Row(children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: _reviewColor(hotel.reviewScore), borderRadius: BorderRadius.circular(4)), child: Text(hotel.reviewScore.toStringAsFixed(1), style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white))),
                    const SizedBox(width: 6),
                    Expanded(child: Text('${hotel.reviewScoreWord} · ${hotel.reviewCount} reviews', style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Text('€${hotel.pricePerNight.toStringAsFixed(0)}', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                    Text(' / night', style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary)),
                  ]),
                  if (hotel.priceExcluded > 0) Padding(padding: const EdgeInsets.only(top: 2), child: Text('+ €${hotel.priceExcluded.toStringAsFixed(2)} taxes', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500))),
                  const SizedBox(height: 10),
                  // Two buttons: Details + Recommend
                  Row(children: [
                    Expanded(
                      child: SizedBox(height: 32, child: OutlinedButton(
                        onPressed: () => _openDetail(hotel),
                        style: OutlinedButton.styleFrom(foregroundColor: AppTheme.primaryColor, side: const BorderSide(color: AppTheme.primaryColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: EdgeInsets.zero),
                        child: Text('Details', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                      )),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(height: 32, child: ElevatedButton.icon(
                        onPressed: () => _togglePick(hotel),
                        icon: Icon(isPicked ? Icons.star_rounded : Icons.star_border_rounded, size: 14),
                        label: Text(isPicked ? 'Recommended' : 'Recommend', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(backgroundColor: isPicked ? const Color(0xFFFF9800) : AppTheme.primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0, padding: EdgeInsets.zero),
                      )),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
