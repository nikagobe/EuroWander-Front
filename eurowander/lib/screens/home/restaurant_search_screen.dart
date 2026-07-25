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
import '../../widgets/widgets.dart';
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
    return AppScaffold(
      maxWidth: double.infinity,
      child: Column(
        children: [
          EWAppBar(
            title: _hasSearched ? 'Restaurants in ${_selectedDestination?.name ?? ''}' : 'Find Restaurants',
            onBack: () {
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
          ),
          Expanded(
            child: _hasSearched ? _buildResultsView() : _buildSearchForm(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchForm() {
    final ew = context.ew;
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: AppSpacing.paddingHorizontalXl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.md),
              Text('City', style: theme.textTheme.labelLarge!.copyWith(color: ew.textPrimary)),
              const SizedBox(height: AppSpacing.xs),
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
                    separatorBuilder: (_, _) => Divider(height: 1, color: Colors.grey.shade100),
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
              const SizedBox(height: AppSpacing.xl),
              // Sort option
              Text('Sort by', style: theme.textTheme.labelLarge!.copyWith(color: ew.textPrimary)),
              const SizedBox(height: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppRadius.borderLg,
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
              const SizedBox(height: AppSpacing.xxl),
              // Search button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _selectedDestination != null ? () => _searchRestaurants() : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.borderLg),
                    elevation: 0,
                  ),
                  child: Text('Search Restaurants', style: theme.textTheme.titleMedium!.copyWith(color: Colors.white)),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsView() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator(color: AppColors.brandPrimary));
    }
    if (_restaurants.isEmpty) {
      return const EmptyState(
        icon: Icons.restaurant_rounded,
        title: 'No restaurants found',
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
    final theme = Theme.of(context);
    final ew = context.ew;

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
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: ew.cardColor,
          borderRadius: AppRadius.borderLg,
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
                      errorBuilder: (_, _, _) => Container(width: 80, height: 80, color: Colors.grey.shade200, child: const Icon(Icons.restaurant_rounded)))
                  : Container(width: 80, height: 80, color: Colors.grey.shade200, child: const Icon(Icons.restaurant_rounded)),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (restaurant.badge.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.xxs),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      child: Text(
                        '${restaurant.badge.replaceAll('_', ' ')} ${restaurant.badgeYear}',
                        style: theme.textTheme.labelSmall!.copyWith(fontWeight: FontWeight.w600, color: Colors.amber.shade800, fontSize: 9),
                      ),
                    ),
                  Text(
                    restaurant.name,
                    style: theme.textTheme.labelLarge!.copyWith(color: ew.textPrimary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    restaurant.cuisine,
                    style: theme.textTheme.labelSmall!.copyWith(color: ew.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Row(
                    children: [
                      Icon(Icons.star_rounded, size: 14, color: Colors.amber.shade600),
                      const SizedBox(width: 2),
                      Text('${restaurant.rating}', style: theme.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(width: AppSpacing.xxs),
                      Text('(${restaurant.numReviews})', style: theme.textTheme.labelSmall!.copyWith(color: ew.textSecondary)),
                      if (restaurant.priceLevel.isNotEmpty) ...[
                        const Spacer(),
                        Text(restaurant.priceLevel, style: theme.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w500, color: Colors.green.shade700)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.brandPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.brandPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationControls() {
    if (_totalPages <= 1) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_currentPage > 1)
            TextButton.icon(
              onPressed: () => _searchRestaurants(page: _currentPage - 1),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: Text('Previous', style: Theme.of(context).textTheme.bodySmall),
            ),
          const SizedBox(width: AppSpacing.md),
          Text('Page $_currentPage of $_totalPages', style: Theme.of(context).textTheme.bodySmall!.copyWith(color: context.ew.textSecondary)),
          const SizedBox(width: AppSpacing.md),
          if (_currentPage < _totalPages)
            TextButton.icon(
              onPressed: () => _searchRestaurants(page: _currentPage + 1),
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: Text('Next', style: Theme.of(context).textTheme.bodySmall),
            ),
        ],
      ),
    );
  }
}
