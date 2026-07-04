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
import 'restaurant_detail_screen.dart';

class RestaurantSearchScreen extends StatefulWidget {
  final SavedTrip trip;

  const RestaurantSearchScreen({super.key, required this.trip});

  @override
  State<RestaurantSearchScreen> createState() => _RestaurantSearchScreenState();
}

class _RestaurantSearchScreenState extends State<RestaurantSearchScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  // Search state
  List<AttractionDestination> _destinations = [];
  AttractionDestination? _selectedDestination;
  bool _isSearchingDestinations = false;
  Timer? _debounce;

  // Results
  List<RestaurantResponse> _restaurants = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  int _currentPage = 1;
  int _totalPages = 1;
  String _updateToken = '';
  String _sortBy = 'POPULARITY';

  final List<Map<String, String>> _sortOptions = [
    {'id': 'POPULARITY', 'title': 'Most Popular'},
    {'id': 'RELEVANCE', 'title': 'Most Relevant'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

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
  }

  Future<void> _searchRestaurants({int page = 1}) async {
    if (_selectedDestination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a city', style: GoogleFonts.poppins()),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = true;
      _currentPage = page;
    });

    try {
      final results = await _apiService.searchRestaurants(
        geoId: _selectedDestination!.geoId,
        page: page,
        sort: _sortBy,
        updateToken: page > 1 ? _updateToken : null,
      );
      if (mounted) {
        setState(() {
          _restaurants = results.data;
          _totalPages = results.totalPages;
          _updateToken = results.updateToken;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Search failed: $e', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    if (mounted) setState(() => _isSearching = false);
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
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: _hasSearched ? _buildResultsView() : _buildSearchForm(),
              ),
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
                  _restaurants = [];
                  _currentPage = 1;
                  _updateToken = '';
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
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppTheme.textPrimary),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              _hasSearched ? 'Restaurants in ${_selectedDestination?.name ?? ''}' : 'Find Restaurants',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

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
              Text('City', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
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
                      : (_selectedDestination != null ? Icon(Icons.check_circle_rounded, color: Colors.green.shade600, size: 20) : null),
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
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _destinations.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                    itemBuilder: (context, index) {
                      final dest = _destinations[index];
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
              const SizedBox(height: 24),
              // Sort option
              Text('Sort by', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _sortBy,
                    isExpanded: true,
                    style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textPrimary),
                    items: _sortOptions.map((opt) => DropdownMenuItem(value: opt['id'], child: Text(opt['title']!))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _sortBy = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Search button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _selectedDestination != null ? () => _searchRestaurants() : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text('Search Restaurants', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsView() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
    }
    if (_restaurants.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.restaurant_rounded, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('No restaurants found', style: GoogleFonts.poppins(fontSize: 16, color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;
        final mapWidget = SizedBox(
          height: isWide ? double.infinity : 220,
          child: FlutterMap(
            options: MapOptions(
              initialCenter: const LatLng(48.8566, 2.3522),
              initialZoom: 11,
            ),
            children: [
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
            ],
          ),
        );

        final listWidget = ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _restaurants.length + 1,
          itemBuilder: (context, index) {
            if (index == _restaurants.length) {
              return _buildPaginationControls();
            }
            return _buildRestaurantCard(index);
          },
        );

        if (isWide) {
          return Row(
            children: [
              Expanded(child: mapWidget),
              Expanded(child: listWidget),
            ],
          );
        } else {
          return Column(
            children: [
              mapWidget,
              Expanded(child: listWidget),
            ],
          );
        }
      },
    );
  }

  Widget _buildRestaurantCard(int index) {
    final restaurant = _restaurants[index];

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RestaurantDetailScreen(
              contentId: restaurant.locationId,
              trip: widget.trip,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: restaurant.photoUrl.isNotEmpty
                  ? Image.network(restaurant.photoUrl, width: 80, height: 80, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(width: 80, height: 80, color: Colors.grey.shade200, child: const Icon(Icons.restaurant_rounded)))
                  : Container(width: 80, height: 80, color: Colors.grey.shade200, child: const Icon(Icons.restaurant_rounded)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (restaurant.badge.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${restaurant.badge.replaceAll('_', ' ')} ${restaurant.badgeYear}',
                        style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.amber.shade800),
                      ),
                    ),
                  Text(
                    restaurant.name,
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    restaurant.cuisine,
                    style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star_rounded, size: 14, color: Colors.amber.shade600),
                      const SizedBox(width: 2),
                      Text('${restaurant.rating}', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 4),
                      Text('(${restaurant.numReviews})', style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary)),
                      if (restaurant.priceLevel.isNotEmpty) ...[
                        const Spacer(),
                        Text(restaurant.priceLevel, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.green.shade700)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppTheme.primaryColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationControls() {
    if (_totalPages <= 1) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_currentPage > 1)
            TextButton.icon(
              onPressed: () => _searchRestaurants(page: _currentPage - 1),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: Text('Previous', style: GoogleFonts.poppins(fontSize: 13)),
            ),
          const SizedBox(width: 16),
          Text('Page $_currentPage of $_totalPages', style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary)),
          const SizedBox(width: 16),
          if (_currentPage < _totalPages)
            TextButton.icon(
              onPressed: () => _searchRestaurants(page: _currentPage + 1),
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: Text('Next', style: GoogleFonts.poppins(fontSize: 13)),
            ),
        ],
      ),
    );
  }
}
