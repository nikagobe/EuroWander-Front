import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_theme.dart';
import '../../models/attraction.dart';
import '../../models/restaurant.dart';
import '../../models/saved_trip.dart';
import '../../services/api_service.dart';
import 'attraction_detail_screen.dart';
import 'restaurant_detail_screen.dart';

class ActivitySearchScreen extends StatefulWidget {
  final SavedTrip trip;
  final int initialTab; // 0 = attractions, 1 = restaurants

  const ActivitySearchScreen({super.key, required this.trip, this.initialTab = 0});

  @override
  State<ActivitySearchScreen> createState() => _ActivitySearchScreenState();
}

class _ActivitySearchScreenState extends State<ActivitySearchScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _queryController = TextEditingController();
  final MapController _mapController = MapController();
  late TabController _tabController;
  Timer? _debounce;
  Timer? _queryDebounce;

  // Destination search
  List<AttractionDestination> _destinations = [];
  AttractionDestination? _selectedDestination;
  bool _isSearchingDestinations = false;

  // Attractions
  List<AttractionResponse> _attractions = [];
  bool _isLoadingAttractions = false;
  int _attractionPage = 1;
  int _attractionTotalPages = 1;
  int? _selectedAttractionIndex;
  String _attractionSort = 'TRAVELER_FAVORITE_V2';

  // Restaurants
  List<RestaurantResponse> _restaurants = [];
  bool _isLoadingRestaurants = false;
  int _restaurantPage = 1;
  int _restaurantTotalPages = 1;
  String _updateToken = '';
  int? _selectedRestaurantIndex;
  String _restaurantSort = 'POPULARITY';

  // Trip dates
  String _startDate = '';
  String _endDate = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    _prefillDatesFromTrip();
  }

  void _prefillDatesFromTrip() {
    if (widget.trip.outboundFlight != null) {
      try {
        final dt = DateTime.parse(widget.trip.outboundFlight!.arrivalTime.replaceAll(' ', 'T'));
        _startDate = _fmtDate(dt);
      } catch (_) {}
    }
    if (widget.trip.returnFlight != null) {
      try {
        final dt = DateTime.parse(widget.trip.returnFlight!.departureTime.replaceAll(' ', 'T'));
        _endDate = _fmtDate(dt);
      } catch (_) {}
    }
    if (_startDate.isEmpty) _startDate = _fmtDate(DateTime.now().add(const Duration(days: 1)));
    if (_endDate.isEmpty) _endDate = _fmtDate(DateTime.now().add(const Duration(days: 7)));
  }

  String _fmtDate(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _searchController.dispose();
    _queryController.dispose();
    _tabController.dispose();
    _debounce?.cancel();
    _queryDebounce?.cancel();
    super.dispose();
  }

  // ─── Destination search ────────────────────────────────────────────

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.length < 2) {
      setState(() => _destinations = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _searchDestinations(query));
  }

  Future<void> _searchDestinations(String query) async {
    setState(() => _isSearchingDestinations = true);
    try {
      final results = await _apiService.searchAttractionDestinations(query: query);
      if (mounted) setState(() => _destinations = results);
    } catch (_) {}
    if (mounted) setState(() => _isSearchingDestinations = false);
  }

  void _selectDestination(AttractionDestination dest) {
    setState(() {
      _selectedDestination = dest;
      _searchController.text = dest.name;
      _destinations = [];
    });
    _loadAttractions(refresh: true);
    _loadRestaurants(refresh: true);
  }

  // ─── Attractions ───────────────────────────────────────────────────

  Future<void> _loadAttractions({bool refresh = false, int? page}) async {
    if (_selectedDestination == null) return;
    if (refresh) {
      _attractionPage = 1;
      _attractions = [];
      _selectedAttractionIndex = null;
    }
    if (page != null) _attractionPage = page;
    setState(() => _isLoadingAttractions = true);
    try {
      final result = await _apiService.searchAttractions(
        geoId: _selectedDestination!.geoId,
        startDate: _startDate,
        endDate: _endDate,
        page: _attractionPage,
        sort: _attractionSort,
        query: _queryController.text.length >= 2 ? _queryController.text : null,
      );
      if (mounted) {
        setState(() {
          if (refresh || page != null) _attractions = result.data;
          else _attractions.addAll(result.data);
          _attractionTotalPages = result.totalPages;
          _isLoadingAttractions = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingAttractions = false);
    }
  }

  // ─── Restaurants ───────────────────────────────────────────────────

  Future<void> _loadRestaurants({bool refresh = false, int? page}) async {
    if (_selectedDestination == null) return;
    if (refresh) {
      _restaurantPage = 1;
      _restaurants = [];
      _updateToken = '';
      _selectedRestaurantIndex = null;
    }
    if (page != null) _restaurantPage = page;
    setState(() => _isLoadingRestaurants = true);
    try {
      final result = await _apiService.searchRestaurants(
        geoId: _selectedDestination!.geoId,
        page: _restaurantPage,
        sort: _restaurantSort,
        updateToken: _restaurantPage > 1 && _updateToken.isNotEmpty ? _updateToken : null,
        query: _queryController.text.length >= 2 ? _queryController.text : null,
      );
      if (mounted) {
        setState(() {
          if (refresh || page != null) _restaurants = result.data;
          else _restaurants.addAll(result.data);
          _restaurantTotalPages = result.totalPages;
          _updateToken = result.updateToken;
          _isLoadingRestaurants = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingRestaurants = false);
    }
  }

  // ─── Map markers ──────────────────────────────────────────────────

  List<Marker> _buildMarkers() {
    // Always show attraction markers on the map regardless of active tab
    return _attractions.asMap().entries.map((entry) {
      final i = entry.key;
      final a = entry.value;
      final isSelected = _tabController.index == 0 && _selectedAttractionIndex == i;
      return Marker(
        point: LatLng(a.latitude, a.longitude),
        width: isSelected ? 44 : 36,
        height: isSelected ? 44 : 36,
        child: GestureDetector(
          onTap: () {
            setState(() {
              _selectedAttractionIndex = i;
              if (_tabController.index != 0) _tabController.animateTo(0);
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor : Colors.deepOrange,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4)],
            ),
            child: const Icon(Icons.attractions_rounded, color: Colors.white, size: 18),
          ),
        ),
      );
    }).toList();
  }

  LatLng _getMapCenter() {
    if (_attractions.isNotEmpty) {
      return LatLng(_attractions.first.latitude, _attractions.first.longitude);
    }
    // Default European center when no attractions loaded yet
    return const LatLng(48.8566, 2.3522);
  }

  // ─── Build ─────────────────────────────────────────────────────────

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
                  _buildAppBar(),
                  _buildCitySearch(),
                  if (_selectedDestination != null) ...[
                    _buildQuerySearch(),
                    _buildMap(),
                    _buildSortRow(),
                    _buildTabs(),
                    Expanded(child: _buildTabContent()),
                  ] else
                    Expanded(child: _buildEmptyState()),
                ],
              ),
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
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppTheme.textPrimary),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              _selectedDestination != null ? 'Explore ${_selectedDestination!.name}' : 'Discover Places',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCitySearch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            style: GoogleFonts.poppins(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search city...',
              hintStyle: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 14),
              prefixIcon: const Icon(Icons.location_city_rounded, size: 20, color: AppTheme.primaryColor),
              suffixIcon: _isSearchingDestinations
                  ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor)))
                  : (_selectedDestination != null
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _selectedDestination = null;
                              _attractions = [];
                              _restaurants = [];
                            });
                          },
                        )
                      : null),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5)),
            ),
          ),
          if (_destinations.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 4),
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _destinations.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                itemBuilder: (_, i) {
                  final dest = _destinations[i];
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.place_rounded, size: 20, color: AppTheme.primaryColor),
                    title: Text(dest.name, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
                    subtitle: Text(dest.secondaryText, style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary)),
                    onTap: () => _selectDestination(dest),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuerySearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: TextField(
        controller: _queryController,
        style: GoogleFonts.poppins(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search by name...',
          hintStyle: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppTheme.primaryColor),
          suffixIcon: _queryController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _queryController.clear();
                    _loadAttractions(refresh: true);
                    _loadRestaurants(refresh: true);
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (query) {
          _queryDebounce?.cancel();
          setState(() {}); // update suffix icon
          _queryDebounce = Timer(const Duration(milliseconds: 500), () {
            _loadAttractions(refresh: true);
            _loadRestaurants(refresh: true);
          });
        },
        onSubmitted: (_) {
          _loadAttractions(refresh: true);
          _loadRestaurants(refresh: true);
        },
      ),
    );
  }

  Widget _buildMap() {
    final markers = _buildMarkers();
    final center = _getMapCenter();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 180,
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 12,
            ),
            children: [
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
              if (markers.isNotEmpty) MarkerLayer(markers: markers),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortRow() {
    final isAttractions = _tabController.index == 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Text('Sort:', style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary)),
          const SizedBox(width: 8),
          if (isAttractions) ...[
            _sortChip('Popular', 'TRAVELER_FAVORITE_V2', _attractionSort, (v) {
              setState(() => _attractionSort = v);
              _loadAttractions(refresh: true);
            }),
            const SizedBox(width: 6),
            _sortChip('Top Rated', 'TRAVELER_RANKED', _attractionSort, (v) {
              setState(() => _attractionSort = v);
              _loadAttractions(refresh: true);
            }),
          ] else ...[
            _sortChip('Popular', 'POPULARITY', _restaurantSort, (v) {
              setState(() => _restaurantSort = v);
              _loadRestaurants(refresh: true);
            }),
            const SizedBox(width: 6),
            _sortChip('Relevant', 'RELEVANCE', _restaurantSort, (v) {
              setState(() => _restaurantSort = v);
              _loadRestaurants(refresh: true);
            }),
          ],
        ],
      ),
    );
  }

  Widget _sortChip(String label, String value, String current, void Function(String) onTap) {
    final isSelected = current == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: isSelected ? Colors.white : AppTheme.textSecondary)),
      ),
    );
  }

  Widget _buildTabs() {
    return TabBar(
      controller: _tabController,
      labelColor: AppTheme.primaryColor,
      unselectedLabelColor: AppTheme.textSecondary,
      indicatorColor: AppTheme.primaryColor,
      labelStyle: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
      unselectedLabelStyle: GoogleFonts.poppins(fontSize: 13),
      tabs: const [
        Tab(text: 'Attractions'),
        Tab(text: 'Restaurants'),
      ],
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildAttractionsList(),
        _buildRestaurantsList(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.travel_explore_rounded, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('Search for a city to explore', style: GoogleFonts.poppins(fontSize: 15, color: AppTheme.textSecondary)),
          Text('attractions and restaurants', style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  // ─── Attraction list ───────────────────────────────────────────────

  Widget _buildAttractionsList() {
    if (_isLoadingAttractions && _attractions.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
    }
    if (_attractions.isEmpty) {
      return Center(child: Text('No attractions found', style: GoogleFonts.poppins(color: AppTheme.textSecondary)));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _attractions.length + (_attractionPage < _attractionTotalPages ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _attractions.length) {
          return _buildPageControls(
            current: _attractionPage, total: _attractionTotalPages,
            onPrev: () => _loadAttractions(page: _attractionPage - 1),
            onNext: () => _loadAttractions(page: _attractionPage + 1),
          );
        }
        return _buildAttractionCard(index);
      },
    );
  }

  Widget _buildAttractionCard(int index) {
    final a = _attractions[index];
    final isSelected = _selectedAttractionIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedAttractionIndex = index);
        if (a.latitude != 0 && a.longitude != 0) {
          _mapController.move(LatLng(a.latitude, a.longitude), 14);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: isSelected ? Border.all(color: AppTheme.primaryColor, width: 2) : null,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 72, height: 72,
                child: a.photoUrl.isNotEmpty
                    ? Image.network(a.photoUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder(Icons.attractions_rounded, Colors.deepOrange))
                    : _placeholder(Icons.attractions_rounded, Colors.deepOrange),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (a.badge.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 3),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(4)),
                      child: Text(a.badge.replaceAll('_', ' '), style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.amber.shade800)),
                    ),
                  Text(a.name, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                  Text(a.category, style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.star_rounded, size: 14, color: Colors.amber.shade600),
                      const SizedBox(width: 2),
                      Text('${a.rating}', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                      Text(' (${a.numReviews})', style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary)),
                      if (a.ticketPrice.isNotEmpty) ...[
                        const Spacer(),
                        Flexible(child: Text(a.ticketPrice, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w500, color: AppTheme.primaryColor), overflow: TextOverflow.ellipsis)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => AttractionDetailScreen(contentId: a.locationId, startDate: _startDate, endDate: _endDate, trip: widget.trip),
              )),
              child: Container(
                width: 34, height: 34,
                decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.primaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Restaurant list ───────────────────────────────────────────────

  Widget _buildRestaurantsList() {
    if (_isLoadingRestaurants && _restaurants.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
    }
    if (_restaurants.isEmpty) {
      return Center(child: Text('No restaurants found', style: GoogleFonts.poppins(color: AppTheme.textSecondary)));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _restaurants.length + (_restaurantPage < _restaurantTotalPages ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _restaurants.length) {
          return _buildPageControls(
            current: _restaurantPage, total: _restaurantTotalPages,
            onPrev: () => _loadRestaurants(page: _restaurantPage - 1),
            onNext: () => _loadRestaurants(page: _restaurantPage + 1),
          );
        }
        return _buildRestaurantCard(index);
      },
    );
  }

  Widget _buildRestaurantCard(int index) {
    final r = _restaurants[index];
    final isSelected = _selectedRestaurantIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedRestaurantIndex = index);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: isSelected ? Border.all(color: Colors.green, width: 2) : null,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 72, height: 72,
                child: r.photoUrl.isNotEmpty
                    ? Image.network(r.photoUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder(Icons.restaurant_rounded, Colors.green))
                    : _placeholder(Icons.restaurant_rounded, Colors.green),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (r.badge.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 3),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(4)),
                      child: Text('${r.badge} ${r.badgeYear}'.trim(), style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.amber.shade800)),
                    ),
                  Text(r.name, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                  Text(r.cuisine, style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.star_rounded, size: 14, color: Colors.amber.shade600),
                      const SizedBox(width: 2),
                      Text('${r.rating}', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                      Text(' (${r.numReviews})', style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary)),
                      if (r.priceLevel.isNotEmpty) ...[
                        const Spacer(),
                        Text(r.priceLevel, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.green.shade700)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => RestaurantDetailScreen(contentId: r.locationId, trip: widget.trip),
              )),
              child: Container(
                width: 34, height: 34,
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.green),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Shared widgets ────────────────────────────────────────────────

  Widget _buildPageControls({required int current, required int total, required VoidCallback onPrev, required VoidCallback onNext}) {
    if (total <= 1) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (current > 1)
            TextButton.icon(
              onPressed: onPrev,
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: Text('Previous', style: GoogleFonts.poppins(fontSize: 13)),
            ),
          const SizedBox(width: 16),
          Text('Page $current of $total', style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary)),
          const SizedBox(width: 16),
          if (current < total)
            TextButton.icon(
              onPressed: onNext,
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: Text('Next', style: GoogleFonts.poppins(fontSize: 13)),
            ),
        ],
      ),
    );
  }

  Widget _placeholder(IconData icon, Color color) {
    return Container(color: color.withOpacity(0.1), child: Icon(icon, color: color, size: 28));
  }
}
