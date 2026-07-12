import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../models/attraction.dart';
import '../../models/playlist.dart';
import '../../models/restaurant.dart';
import '../../services/api_service.dart';

class PlaylistItemPickerScreen extends StatefulWidget {
  final int dayNumber;
  final int totalDays;
  final String timeSlot;
  final String? initialCity;

  const PlaylistItemPickerScreen({
    super.key,
    required this.dayNumber,
    this.totalDays = 1,
    this.timeSlot = 'morning',
    this.initialCity,
  });

  @override
  State<PlaylistItemPickerScreen> createState() => _PlaylistItemPickerScreenState();
}

class _PlaylistItemPickerScreenState extends State<PlaylistItemPickerScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  Timer? _debounce;

  // Destination search
  List<AttractionDestination> _destinations = [];
  AttractionDestination? _selectedDestination;
  bool _isSearchingDestinations = false;

  // Attractions
  List<AttractionResponse> _attractions = [];
  bool _isLoadingAttractions = false;
  int _attractionPage = 1;
  int _attractionTotalPages = 1;
  int? _expandedAttractionIndex;

  // Restaurants
  List<RestaurantResponse> _restaurants = [];
  bool _isLoadingRestaurants = false;
  int _restaurantPage = 1;
  int _restaurantTotalPages = 1;
  String _updateToken = '';
  int? _expandedRestaurantIndex;

  // Selection state
  int _selectedDay = 1;
  String _timeSlot = 'morning';
  List<PlaylistItem> _addedItems = [];

  // Custom item
  final _customNameController = TextEditingController();
  final _customCategoryController = TextEditingController();
  final _customNoteController = TextEditingController();
  int _customDuration = 60;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _timeSlot = widget.timeSlot;
    _selectedDay = widget.dayNumber;
    if (widget.initialCity != null && widget.initialCity!.isNotEmpty) {
      _searchController.text = widget.initialCity!;
      _searchDestinations(widget.initialCity!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _debounce?.cancel();
    _customNameController.dispose();
    _customCategoryController.dispose();
    _customNoteController.dispose();
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
    _loadAttractions(refresh: true);
    _loadRestaurants(refresh: true);
  }

  Future<void> _loadAttractions({bool refresh = false}) async {
    if (_selectedDestination == null) return;
    if (refresh) {
      _attractionPage = 1;
      _attractions = [];
      _expandedAttractionIndex = null;
    }
    setState(() => _isLoadingAttractions = true);
    try {
      final now = DateTime.now();
      final result = await _apiService.searchAttractions(
        geoId: _selectedDestination!.geoId,
        startDate: '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
        endDate: '${now.year}-${(now.month + 1).toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
        page: _attractionPage,
      );
      if (mounted) {
        setState(() {
          _attractions.addAll(result.data);
          _attractionTotalPages = result.totalPages;
          _isLoadingAttractions = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingAttractions = false);
    }
  }

  Future<void> _loadRestaurants({bool refresh = false}) async {
    if (_selectedDestination == null) return;
    if (refresh) {
      _restaurantPage = 1;
      _restaurants = [];
      _updateToken = '';
      _expandedRestaurantIndex = null;
    }
    setState(() => _isLoadingRestaurants = true);
    try {
      final result = await _apiService.searchRestaurants(
        geoId: _selectedDestination!.geoId,
        page: _restaurantPage,
        updateToken: _updateToken.isNotEmpty ? _updateToken : null,
      );
      if (mounted) {
        setState(() {
          _restaurants.addAll(result.data);
          _restaurantTotalPages = result.totalPages;
          _updateToken = result.updateToken;
          _isLoadingRestaurants = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingRestaurants = false);
    }
  }

  void _addAttraction(AttractionResponse attraction) {
    final item = PlaylistItem(
      itemType: 'attraction',
      name: attraction.name,
      dayNumber: _selectedDay,
      timeSlot: _timeSlot,
      order: 0,
      locationId: attraction.locationId,
      category: attraction.category,
      photoUrl: attraction.photoUrl,
      latitude: attraction.latitude,
      longitude: attraction.longitude,
      rating: attraction.rating,
      numReviews: attraction.numReviews,
      priceIndicator: attraction.ticketPrice,
    );
    setState(() => _addedItems.add(item));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added "${attraction.name}" to Day $_selectedDay'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green.shade600,
      ),
    );
  }

  void _addRestaurant(RestaurantResponse restaurant) {
    final item = PlaylistItem(
      itemType: 'restaurant',
      name: restaurant.name,
      dayNumber: _selectedDay,
      timeSlot: _timeSlot,
      order: 0,
      locationId: restaurant.locationId,
      category: restaurant.cuisine,
      photoUrl: restaurant.photoUrl,
      rating: restaurant.rating,
      numReviews: restaurant.numReviews,
      priceIndicator: restaurant.priceLevel,
    );
    setState(() => _addedItems.add(item));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added "${restaurant.name}" to Day $_selectedDay'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green.shade600,
      ),
    );
  }

  void _addCustomItem() {
    if (_customNameController.text.isEmpty) return;
    final item = PlaylistItem(
      itemType: 'custom',
      name: _customNameController.text,
      dayNumber: _selectedDay,
      timeSlot: _timeSlot,
      order: 0,
      category: _customCategoryController.text,
      note: _customNoteController.text,
      suggestedDurationMinutes: _customDuration,
    );
    setState(() {
      _addedItems.add(item);
      _customNameController.clear();
      _customCategoryController.clear();
      _customNoteController.clear();
      _customDuration = 60;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added "${item.name}" to Day $_selectedDay'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green.shade600,
      ),
    );
  }

  void _goBack() {
    Navigator.pop(context, _addedItems);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goBack();
      },
      child: Scaffold(
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
                    _buildSearchSection(),
                    _buildDayAndTimeRow(),
                    TabBar(
                      controller: _tabController,
                      labelColor: AppTheme.primaryColor,
                      unselectedLabelColor: AppTheme.textSecondary,
                      tabs: const [
                        Tab(text: 'Attractions'),
                        Tab(text: 'Restaurants'),
                        Tab(text: 'Custom'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildAttractionsList(),
                          _buildRestaurantsList(),
                          _buildCustomTab(),
                        ],
                      ),
                    ),
                  ],
                ),
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
            onTap: _goBack,
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
              'Add Items',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
            ),
          ),
          if (_addedItems.isNotEmpty)
            GestureDetector(
              onTap: _goBack,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Done (${_addedItems.length})',
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search city...',
              prefixIcon: const Icon(Icons.location_city, color: AppTheme.textSecondary),
              suffixIcon: _isSearchingDestinations
                  ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: _onSearchChanged,
          ),
          if (_destinations.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8)],
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _destinations.length,
                itemBuilder: (_, i) {
                  final dest = _destinations[i];
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.location_on_outlined, size: 18, color: AppTheme.primaryColor),
                    title: Text(dest.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    subtitle: Text(dest.secondaryText, style: const TextStyle(fontSize: 12)),
                    onTap: () => _selectDestination(dest),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDayAndTimeRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Day selector
          Row(
            children: [
              Text('Day:', style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary)),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.totalDays,
                    itemBuilder: (_, i) {
                      final day = i + 1;
                      final isSelected = _selectedDay == day;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedDay = day),
                          child: Container(
                            width: 36, height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primaryColor : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300),
                            ),
                            child: Text(
                              '$day',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : AppTheme.textSecondary),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Time slot selector
          Row(
            children: [
              Text('Time:', style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary)),
              const SizedBox(width: 8),
              ...['morning', 'midday', 'evening', 'night'].map((slot) {
                final isSelected = _timeSlot == slot;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => setState(() => _timeSlot = slot),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryColor : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300),
                      ),
                      child: Text(
                        slot[0].toUpperCase() + slot.substring(1),
                        style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : AppTheme.textSecondary),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttractionsList() {
    if (_selectedDestination == null) {
      return _buildEmptyPrompt('Search for a city to browse attractions');
    }
    if (_isLoadingAttractions && _attractions.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
    }
    if (_attractions.isEmpty) {
      return _buildEmptyPrompt('No attractions found');
    }
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.pixels >= notification.metrics.maxScrollExtent - 200 &&
            !_isLoadingAttractions &&
            _attractionPage < _attractionTotalPages) {
          _attractionPage++;
          _loadAttractions();
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _attractions.length + (_attractionPage < _attractionTotalPages ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _attractions.length) {
            return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)));
          }
          return _buildAttractionCard(_attractions[index], index);
        },
      ),
    );
  }

  Widget _buildRestaurantsList() {
    if (_selectedDestination == null) {
      return _buildEmptyPrompt('Search for a city to browse restaurants');
    }
    if (_isLoadingRestaurants && _restaurants.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
    }
    if (_restaurants.isEmpty) {
      return _buildEmptyPrompt('No restaurants found');
    }
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.pixels >= notification.metrics.maxScrollExtent - 200 &&
            !_isLoadingRestaurants &&
            _restaurantPage < _restaurantTotalPages) {
          _restaurantPage++;
          _loadRestaurants();
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _restaurants.length + (_restaurantPage < _restaurantTotalPages ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _restaurants.length) {
            return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)));
          }
          return _buildRestaurantCard(_restaurants[index], index);
        },
      ),
    );
  }

  Widget _buildCustomTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add Custom Item', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Add a custom spot that isn\'t in our database', style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary)),
          const SizedBox(height: 16),
          TextField(
            controller: _customNameController,
            decoration: const InputDecoration(labelText: 'Name *', prefixIcon: Icon(Icons.push_pin_outlined, size: 20)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _customCategoryController,
            decoration: const InputDecoration(labelText: 'Category (e.g. Park, Museum, Cafe...)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _customNoteController,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Note (tips, directions...)'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Duration:', style: GoogleFonts.poppins(fontSize: 13)),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 22),
                onPressed: () { if (_customDuration > 15) setState(() => _customDuration -= 15); },
              ),
              Text('${_customDuration} min', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 22),
                onPressed: () => setState(() => _customDuration += 15),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _addCustomItem,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Custom Item'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          ),
          if (_addedItems.where((i) => i.itemType == 'custom').isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Added custom items:', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            ..._addedItems.where((i) => i.itemType == 'custom').map((item) => Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.push_pin_rounded, size: 16, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item.name, style: const TextStyle(fontSize: 13))),
                  Text('Day ${item.dayNumber}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildAttractionCard(AttractionResponse a, int index) {
    final isExpanded = _expandedAttractionIndex == index;
    final isAdded = _addedItems.any((i) => i.locationId == a.locationId && i.itemType == 'attraction');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _expandedAttractionIndex = isExpanded ? null : index),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 56, height: 56,
                      child: a.photoUrl.isNotEmpty
                          ? Image.network(a.photoUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholderIcon(Icons.attractions_rounded, Colors.deepOrange))
                          : _placeholderIcon(Icons.attractions_rounded, Colors.deepOrange),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.name, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(a.category, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Row(
                          children: [
                            const Icon(Icons.star, size: 12, color: Colors.amber),
                            Text(' ${a.rating}', style: const TextStyle(fontSize: 11)),
                            Text(' (${a.numReviews})', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: AppTheme.textSecondary),
                ],
              ),
            ),
          ),
          if (isExpanded) _buildAttractionDetails(a, isAdded),
        ],
      ),
    );
  }

  Widget _buildAttractionDetails(AttractionResponse a, bool isAdded) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 10),
          // Photo
          if (a.photoUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(a.photoUrl, height: 140, width: double.infinity, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink()),
            ),
          const SizedBox(height: 10),
          // Details
          if (a.category.isNotEmpty)
            _detailRow(Icons.category_outlined, a.category),
          if (a.ticketPrice.isNotEmpty)
            _detailRow(Icons.confirmation_number_outlined, a.ticketPrice),
          _detailRow(Icons.star_rounded, '${a.rating} rating (${a.numReviews} reviews)'),
          if (a.neighborhood.isNotEmpty)
            _detailRow(Icons.location_on_outlined, a.neighborhood),
          const SizedBox(height: 10),
          // Add button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isAdded ? null : () => _addAttraction(a),
              icon: Icon(isAdded ? Icons.check : Icons.add, size: 18),
              label: Text(isAdded ? 'Added' : 'Add to Day $_selectedDay'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isAdded ? Colors.grey.shade300 : AppTheme.primaryColor,
                foregroundColor: isAdded ? AppTheme.textSecondary : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantCard(RestaurantResponse r, int index) {
    final isExpanded = _expandedRestaurantIndex == index;
    final isAdded = _addedItems.any((i) => i.locationId == r.locationId && i.itemType == 'restaurant');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _expandedRestaurantIndex = isExpanded ? null : index),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 56, height: 56,
                      child: r.photoUrl.isNotEmpty
                          ? Image.network(r.photoUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholderIcon(Icons.restaurant_rounded, Colors.green))
                          : _placeholderIcon(Icons.restaurant_rounded, Colors.green),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.name, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(r.cuisine, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Row(
                          children: [
                            const Icon(Icons.star, size: 12, color: Colors.amber),
                            Text(' ${r.rating}', style: const TextStyle(fontSize: 11)),
                            Text(' (${r.numReviews})', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: AppTheme.textSecondary),
                ],
              ),
            ),
          ),
          if (isExpanded) _buildRestaurantDetails(r, isAdded),
        ],
      ),
    );
  }

  Widget _buildRestaurantDetails(RestaurantResponse r, bool isAdded) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 10),
          if (r.photoUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(r.photoUrl, height: 140, width: double.infinity, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink()),
            ),
          const SizedBox(height: 10),
          if (r.cuisine.isNotEmpty)
            _detailRow(Icons.restaurant_menu, r.cuisine),
          if (r.priceLevel.isNotEmpty)
            _detailRow(Icons.attach_money, r.priceLevel),
          _detailRow(Icons.star_rounded, '${r.rating} rating (${r.numReviews} reviews)'),
          if (r.neighborhood.isNotEmpty)
            _detailRow(Icons.location_on_outlined, r.neighborhood),
          if (r.badge.isNotEmpty)
            _detailRow(Icons.workspace_premium, '${r.badge} ${r.badgeYear}'),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isAdded ? null : () => _addRestaurant(r),
              icon: Icon(isAdded ? Icons.check : Icons.add, size: 18),
              label: Text(isAdded ? 'Added' : 'Add to Day $_selectedDay'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isAdded ? Colors.grey.shade300 : AppTheme.primaryColor,
                foregroundColor: isAdded ? AppTheme.textSecondary : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary))),
        ],
      ),
    );
  }

  Widget _buildEmptyPrompt(String text) {
    return Center(
      child: Text(text, style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textSecondary)),
    );
  }

  Widget _placeholderIcon(IconData icon, Color color) {
    return Container(color: color.withOpacity(0.1), child: Icon(icon, color: color, size: 28));
  }
}
