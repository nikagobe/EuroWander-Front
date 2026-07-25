import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/hotel.dart';
import '../../../models/template.dart';
import '../../../services/api_service.dart';

/// Full-screen hotel search for template creation.
/// Mirrors the main HotelSearchScreen UI exactly, but with
/// "☆ Pick" / "★ Picked" toggle instead of "View Details".
/// Returns List<HotelPick> on pop.
class TemplateHotelPickerScreen extends StatefulWidget {
  final String city;
  final List<HotelPick> existingPicks;

  const TemplateHotelPickerScreen({
    super.key,
    required this.city,
    this.existingPicks = const [],
  });

  @override
  State<TemplateHotelPickerScreen> createState() =>
      _TemplateHotelPickerScreenState();
}

class _TemplateHotelPickerScreenState extends State<TemplateHotelPickerScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();
  final ScrollController _listScrollController = ScrollController();
  Timer? _debounce;

  // Search state
  List<HotelDestination> _destinations = [];
  HotelDestination? _selectedDestination;
  bool _isSearchingDestinations = false;

  // Options
  DateTime _arrivalDate = DateTime.now().add(const Duration(days: 30));
  DateTime _departureDate = DateTime.now().add(const Duration(days: 32));
  int _adults = 1;
  int _rooms = 1;
  String _sortBy = 'popularity';

  // Results
  List<HotelOffer> _hotels = [];
  bool _isSearchingHotels = false;
  bool _hasSearched = false;
  int? _selectedHotelIndex;
  int _currentPage = 1;
  bool _hasMorePages = true;

  // Picks
  final Map<int, HotelPick> _pickedHotels = {};
  final Map<int, TextEditingController> _reviewControllers = {};

  final List<Map<String, String>> _sortOptions = [
    {'id': 'popularity', 'title': 'Popularity'},
    {'id': 'price', 'title': 'Price (lowest first)'},
    {'id': 'bayesian_review_score', 'title': 'Best reviewed first'},
    {'id': 'class_descending', 'title': 'Star rating (highest first)'},
    {'id': 'class_ascending', 'title': 'Star rating (lowest first)'},
    {'id': 'distance', 'title': 'Distance from city centre'},
  ];

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.city;
    for (final pick in widget.existingPicks) {
      _pickedHotels[pick.bookingHotelId] = pick;
      _reviewControllers[pick.bookingHotelId] =
          TextEditingController(text: pick.authorReview);
    }
    // Auto-search destination for the city
    _searchDestinations(widget.city);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _listScrollController.dispose();
    _debounce?.cancel();
    for (final c in _reviewControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ─── Search logic (identical to HotelSearchScreen) ─────────────

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.length < 2) {
      setState(() => _destinations = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _searchDestinations(query);
    });
  }

  Future<void> _searchDestinations(String query) async {
    setState(() => _isSearchingDestinations = true);
    try {
      final results = await _apiService.searchHotelDestinations(query: query);
      if (mounted) {
        setState(() {
          _destinations = results;
          _isSearchingDestinations = false;
        });
        if (results.isNotEmpty && _selectedDestination == null) {
          _selectDestination(results.first);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isSearchingDestinations = false);
    }
  }

  void _selectDestination(HotelDestination dest) {
    setState(() {
      _selectedDestination = dest;
      _searchController.text = dest.cityName;
      _destinations = [];
    });
  }

  Future<void> _pickArrivalDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _arrivalDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
            colorScheme:
                const ColorScheme.light(primary: AppTheme.primaryColor)),
        child: child!,
      ),
    );
    if (date != null) {
      setState(() {
        _arrivalDate = date;
        if (_departureDate.isBefore(date.add(const Duration(days: 1)))) {
          _departureDate = date.add(const Duration(days: 1));
        }
      });
    }
  }

  Future<void> _pickDepartureDate() async {
    final minDate = _arrivalDate.add(const Duration(days: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: _departureDate,
      firstDate: minDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
            colorScheme:
                const ColorScheme.light(primary: AppTheme.primaryColor)),
        child: child!,
      ),
    );
    if (date != null) setState(() => _departureDate = date);
  }

  Future<void> _searchHotels({int page = 1}) async {
    if (_selectedDestination == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please select a destination',
            style: GoogleFonts.poppins()),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }

    setState(() {
      _isSearchingHotels = true;
      _hasSearched = true;
      _selectedHotelIndex = null;
      _currentPage = page;
    });

    try {
      final results = await _apiService.searchHotels(
        destId: _selectedDestination!.destId,
        arrivalDate: _formatDate(_arrivalDate),
        departureDate: _formatDate(_departureDate),
        adults: _adults,
        roomQty: _rooms,
        sortBy: _sortBy,
        pageNumber: page,
      );
      if (mounted) {
        setState(() {
          _hotels = results;
          _hasMorePages = results.length >= 20;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Search failed: $e', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
    if (mounted) setState(() => _isSearchingHotels = false);
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _formatDisplayDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  // ─── Pick logic ────────────────────────────────────────────────

  void _togglePick(HotelOffer hotel) {
    setState(() {
      if (_pickedHotels.containsKey(hotel.hotelId)) {
        _pickedHotels.remove(hotel.hotelId);
        _reviewControllers[hotel.hotelId]?.dispose();
        _reviewControllers.remove(hotel.hotelId);
      } else {
        _pickedHotels[hotel.hotelId] = HotelPick(
          bookingHotelId: hotel.hotelId,
          name: hotel.name,
          city: widget.city,
          neighborhood: '',
          stars: hotel.stars,
          photoUrl: hotel.photoUrl,
          authorReview: '',
          priority: _pickedHotels.length + 1,
          pricePaid: hotel.pricePerNight,
          currency: hotel.currency,
        );
        _reviewControllers[hotel.hotelId] = TextEditingController();
      }
    });
  }

  List<HotelPick> _buildFinalPicks() {
    int priority = 1;
    return _pickedHotels.entries.map((e) {
      final review = _reviewControllers[e.key]?.text ?? '';
      return HotelPick(
        bookingHotelId: e.value.bookingHotelId,
        name: e.value.name,
        city: e.value.city,
        neighborhood: e.value.neighborhood,
        stars: e.value.stars,
        photoUrl: e.value.photoUrl,
        authorReview: review,
        priority: priority++,
        pricePaid: e.value.pricePaid,
        currency: e.value.currency,
      );
    }).toList();
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
    _listScrollController.animateTo(
      index * cardHeight,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // ─── Build ─────────────────────────────────────────────────────

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
          child: Column(
            children: [
              _buildAppBar(),
              // Picked bar
              if (_pickedHotels.isNotEmpty) _buildPickedBar(),
              Expanded(
                child:
                    _hasSearched ? _buildResultsView() : _buildSearchForm(),
              ),
              // Done button
              if (_hasSearched) _buildDoneButton(),
            ],
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
            onTap: () {
              if (_hasSearched) {
                setState(() {
                  _hasSearched = false;
                  _hotels = [];
                  _currentPage = 1;
                });
              } else {
                Navigator.of(context).pop();
              }
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 18, color: AppTheme.textPrimary),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              _hasSearched
                  ? 'Hotels in ${_selectedDestination?.cityName ?? widget.city}'
                  : 'Pick Hotels — ${widget.city}',
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickedBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFF9800).withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Text('⭐', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${_pickedHotels.length} hotel${_pickedHotels.length == 1 ? '' : 's'} picked',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE65100)),
            ),
          ),
          GestureDetector(
            onTap: _showReviewSheet,
            child: const Text('Review picks',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor)),
          ),
        ],
      ),
    );
  }

  // ─── Search form (mirrors HotelSearchScreen._buildSearchForm) ──

  Widget _buildSearchForm() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Destination search
              Text('Destination',
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search city...',
                  hintStyle: GoogleFonts.poppins(
                      color: AppTheme.textSecondary, fontSize: 14),
                  prefixIcon: const Icon(Icons.location_city_rounded,
                      size: 20, color: AppTheme.primaryColor),
                  suffixIcon: _isSearchingDestinations
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.primaryColor)))
                      : (_selectedDestination != null
                          ? Icon(Icons.check_circle_rounded,
                              color: Colors.green.shade600, size: 20)
                          : null),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: AppTheme.primaryColor, width: 1.5)),
                ),
              ),
              if (_destinations.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _destinations.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: Colors.grey.shade100),
                    itemBuilder: (_, i) {
                      final dest = _destinations[i];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.place_rounded,
                            size: 18, color: AppTheme.primaryColor),
                        title: Text(dest.label,
                            style: GoogleFonts.poppins(
                                fontSize: 13, color: AppTheme.textPrimary)),
                        onTap: () => _selectDestination(dest),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 24),
              // Dates
              Text('Dates',
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                      child: _buildDateButton(
                          'Check-in', _arrivalDate, _pickArrivalDate)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _buildDateButton(
                          'Check-out', _departureDate, _pickDepartureDate)),
                ],
              ),
              const SizedBox(height: 24),
              // Adults & rooms
              Text('Guests & Rooms',
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                      child: _buildCounterField(
                          'Adults', _adults, (v) => setState(() => _adults = v))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _buildCounterField(
                          'Rooms', _rooms, (v) => setState(() => _rooms = v))),
                ],
              ),
              const SizedBox(height: 24),
              // Sort
              Text('Sort by',
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _sortBy,
                    isExpanded: true,
                    style: GoogleFonts.poppins(
                        fontSize: 14, color: AppTheme.textPrimary),
                    items: _sortOptions
                        .map((opt) => DropdownMenuItem(
                            value: opt['id'],
                            child: Text(opt['title']!)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _sortBy = v ?? 'popularity'),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Search button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _searchHotels,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.search_rounded,
                          color: Colors.white, size: 22),
                      const SizedBox(width: 8),
                      Text('Search Hotels',
                          style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateButton(String label, DateTime date, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded,
                size: 16, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _formatDisplayDate(date),
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounterField(
      String label, int value, ValueChanged<int> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: AppTheme.textSecondary)),
                Text('$value',
                    style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary)),
              ],
            ),
          ),
          Column(
            children: [
              GestureDetector(
                onTap: () => onChanged(value + 1),
                child: Icon(Icons.add_circle_outline_rounded,
                    size: 22, color: AppTheme.primaryColor),
              ),
              const SizedBox(height: 2),
              GestureDetector(
                onTap: () {
                  if (value > 1) onChanged(value - 1);
                },
                child: Icon(Icons.remove_circle_outline_rounded,
                    size: 22,
                    color:
                        value > 1 ? Colors.red.shade400 : Colors.grey.shade300),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Results view (split list + map) ────────────────────────────

  Widget _buildResultsView() {
    if (_isSearchingHotels) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor));
    }
    if (_hotels.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hotel_rounded, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('No hotels found',
                style: GoogleFonts.poppins(
                    fontSize: 16, color: AppTheme.textSecondary)),
            const SizedBox(height: 4),
            Text('Try different dates or destination',
                style: GoogleFonts.poppins(
                    fontSize: 13, color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    return Row(
      children: [
        // Hotel list
        Expanded(
          flex: 5,
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _listScrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: _hotels.length,
                  itemBuilder: (context, index) => _buildHotelCard(index),
                ),
              ),
              _buildPagination(),
            ],
          ),
        ),
        // Map
        Expanded(
          flex: 5,
          child: _buildMap(),
        ),
      ],
    );
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, -2))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildPageButton(
            icon: Icons.chevron_left_rounded,
            onTap: _currentPage > 1
                ? () => _searchHotels(page: _currentPage - 1)
                : null,
          ),
          const SizedBox(width: 16),
          Text('Page $_currentPage',
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary)),
          const SizedBox(width: 16),
          _buildPageButton(
            icon: Icons.chevron_right_rounded,
            onTap: _hasMorePages
                ? () => _searchHotels(page: _currentPage + 1)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildPageButton({required IconData icon, VoidCallback? onTap}) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled ? AppTheme.primaryColor : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon,
            size: 22,
            color: enabled ? Colors.white : Colors.grey.shade400),
      ),
    );
  }

  Widget _buildMap() {
    final bounds = _calculateBounds();
    return ClipRRect(
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: bounds.center,
          initialZoom: 12,
          onTap: (_, __) => setState(() => _selectedHotelIndex = null),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.eurowander.app',
          ),
          MarkerLayer(
            markers: _hotels.asMap().entries.map((entry) {
              final index = entry.key;
              final hotel = entry.value;
              final isSelected = index == _selectedHotelIndex;
              final isPicked = _pickedHotels.containsKey(hotel.hotelId);
              return Marker(
                point: LatLng(hotel.latitude, hotel.longitude),
                width: isSelected ? 48 : 36,
                height: isSelected ? 48 : 36,
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedHotelIndex = index);
                    _mapController.move(
                        LatLng(hotel.latitude, hotel.longitude), 14);
                    _scrollToHotel(index);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isPicked
                          ? const Color(0xFFFF9800)
                          : isSelected
                              ? AppTheme.primaryColor
                              : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: isPicked
                              ? const Color(0xFFFF9800)
                              : isSelected
                                  ? AppTheme.primaryColor
                                  : Colors.orange.shade400,
                          width: 2),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2))
                      ],
                    ),
                    child: Center(
                      child: isPicked
                          ? const Icon(Icons.star_rounded,
                              size: 16, color: Colors.white)
                          : Text(
                              '€${hotel.pricePerNight.toInt()}',
                              style: GoogleFonts.poppins(
                                fontSize: isSelected ? 10 : 8,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.orange.shade700,
                              ),
                            ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  LatLngBounds _calculateBounds() {
    if (_hotels.isEmpty) {
      return LatLngBounds(LatLng(48.8, 2.3), LatLng(48.9, 2.4));
    }
    double minLat = _hotels.first.latitude;
    double maxLat = _hotels.first.latitude;
    double minLng = _hotels.first.longitude;
    double maxLng = _hotels.first.longitude;
    for (final h in _hotels) {
      if (h.latitude < minLat) minLat = h.latitude;
      if (h.latitude > maxLat) maxLat = h.latitude;
      if (h.longitude < minLng) minLng = h.longitude;
      if (h.longitude > maxLng) maxLng = h.longitude;
    }
    return LatLngBounds(LatLng(minLat - 0.01, minLng - 0.01),
        LatLng(maxLat + 0.01, maxLng + 0.01));
  }

  // ─── Hotel card (same as main, but with pick toggle) ───────────

  Widget _buildHotelCard(int index) {
    final hotel = _hotels[index];
    final isSelected = index == _selectedHotelIndex;
    final isPicked = _pickedHotels.containsKey(hotel.hotelId);

    return GestureDetector(
      onTap: () {
        setState(() => _selectedHotelIndex = index);
        _mapController.move(LatLng(hotel.latitude, hotel.longitude), 14);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: AppTheme.primaryColor, width: 1.5)
              : isPicked
                  ? Border.all(
                      color: const Color(0xFFFF9800).withOpacity(0.6),
                      width: 1.5)
                  : null,
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppTheme.primaryColor.withOpacity(0.12)
                  : Colors.black.withOpacity(0.04),
              blurRadius: isSelected ? 16 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                hotel.photoUrl,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.hotel_rounded,
                      size: 32, color: Colors.grey.shade400),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hotel.name,
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (hotel.stars > 0)
                    Row(
                      children: List.generate(
                          hotel.stars,
                          (_) => const Icon(Icons.star_rounded,
                              size: 14, color: Colors.amber)),
                    ),
                  const SizedBox(height: 4),
                  if (hotel.reviewScore > 0)
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _reviewColor(hotel.reviewScore),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            hotel.reviewScore.toStringAsFixed(1),
                            style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${hotel.reviewScoreWord} · ${hotel.reviewCount} reviews',
                            style: GoogleFonts.poppins(
                                fontSize: 11, color: AppTheme.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '€${hotel.pricePerNight.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor),
                      ),
                      Text(' / night',
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: AppTheme.textSecondary)),
                    ],
                  ),
                  if (hotel.priceExcluded > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '+ €${hotel.priceExcluded.toStringAsFixed(2)} taxes',
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ),
                  const SizedBox(height: 10),
                  // Pick button (instead of "View Details")
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: ElevatedButton.icon(
                      onPressed: () => _togglePick(hotel),
                      icon: Icon(
                          isPicked ? Icons.star_rounded : Icons.star_border_rounded,
                          size: 16),
                      label: Text(isPicked ? 'Picked' : 'Pick this hotel',
                          style: GoogleFonts.poppins(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isPicked
                            ? const Color(0xFFFF9800)
                            : AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Done button ────────────────────────────────────────────────

  Widget _buildDoneButton() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -4))
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context, _buildFinalPicks()),
            style: ElevatedButton.styleFrom(
              backgroundColor: _pickedHotels.isNotEmpty
                  ? AppTheme.primaryColor
                  : Colors.grey.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text(
              _pickedHotels.isNotEmpty
                  ? 'Done — ${_pickedHotels.length} hotel${_pickedHotels.length == 1 ? '' : 's'}'
                  : 'Skip hotels',
              style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Review bottom sheet ────────────────────────────────────────

  void _showReviewSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 16),
                Text('Your picks (${_pickedHotels.length})',
                    style: GoogleFonts.poppins(
                        fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                const Text('Add a review for each hotel',
                    style: TextStyle(
                        fontSize: 13, color: AppTheme.textSecondary)),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: _pickedHotels.entries.map((e) {
                      final pick = e.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(10)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('⭐ ',
                                    style: TextStyle(fontSize: 14)),
                                Expanded(
                                  child: Text(
                                      '${pick.name} ${'★' * pick.stars}',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600)),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _pickedHotels.remove(e.key);
                                      _reviewControllers[e.key]?.dispose();
                                      _reviewControllers.remove(e.key);
                                    });
                                    Navigator.pop(context);
                                  },
                                  child: const Icon(Icons.close,
                                      size: 18,
                                      color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                            if (pick.pricePaid != null)
                              Text(
                                  '${pick.currency}${pick.pricePaid!.toInt()}/night',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _reviewControllers[e.key],
                              decoration: InputDecoration(
                                hintText: 'Your review...',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                              ),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
