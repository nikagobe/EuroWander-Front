import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/saved_trip.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import 'attraction_detail_screen.dart';
import 'attraction_search_screen.dart';
import 'restaurant_detail_screen.dart';
import 'restaurant_search_screen.dart';

class TripActivitiesScreen extends StatefulWidget {
  final SavedTrip trip;

  const TripActivitiesScreen({super.key, required this.trip});

  @override
  State<TripActivitiesScreen> createState() => _TripActivitiesScreenState();
}

class _TripActivitiesScreenState extends State<TripActivitiesScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;
  late SavedTrip _trip;
  List<TripMember> _members = [];

  @override
  void initState() {
    super.initState();
    _trip = widget.trip;
    _tabController = TabController(length: 2, vsync: this);
    _reloadTrip();
    _loadMembers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  void _showMarkAttractionPaidSheet(SavedAttraction attraction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ActivityMarkPaidSheet(
        members: _members,
        tripId: _trip.id,
        locationId: attraction.locationId,
        itemType: 'attraction',
        itemName: attraction.name,
        onDone: _reloadTrip,
      ),
    );
  }

  void _showMarkRestaurantPaidSheet(SavedRestaurant restaurant) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ActivityMarkPaidSheet(
        members: _members,
        tripId: _trip.id,
        locationId: restaurant.locationId,
        itemType: 'restaurant',
        itemName: restaurant.name,
        onDone: _reloadTrip,
      ),
    );
  }

  Future<void> _removeAttraction(SavedAttraction attraction) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    try {
      await _apiService.removeAttractionFromTrip(
        token: token,
        tripId: _trip.id,
        locationId: attraction.locationId,
      );
      _reloadTrip();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove: $e')),
        );
      }
    }
  }

  Future<void> _removeRestaurant(SavedRestaurant restaurant) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    try {
      await _apiService.removeRestaurantFromTrip(
        token: token,
        tripId: _trip.id,
        locationId: restaurant.locationId,
      );
      _reloadTrip();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove: $e')),
        );
      }
    }
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
                  _buildSearchBar(),
                  const SizedBox(height: 12),
                  _buildTabBar(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildAttractionsList(),
                        _buildRestaurantsList(),
                      ],
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: _showSearchOptions,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryColor, const Color(0xFF8B5CF6)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.search_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Discover new places',
                      style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                    Text(
                      'Search attractions & restaurants',
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.white.withOpacity(0.8)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showSearchOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            Text('What are you looking for?', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            _buildSearchOption(
              icon: Icons.attractions_rounded,
              label: 'Search Attractions',
              subtitle: 'Things to do & see',
              color: const Color(0xFFFF5722),
              onTap: () {
                Navigator.pop(ctx);
                _navigateToAttractionSearch();
              },
            ),
            const SizedBox(height: 12),
            _buildSearchOption(
              icon: Icons.restaurant_rounded,
              label: 'Search Restaurants',
              subtitle: 'Places to eat',
              color: const Color(0xFF795548),
              onTap: () {
                Navigator.pop(ctx);
                _navigateToRestaurantSearch();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                  Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color),
          ],
        ),
      ),
    );
  }

  void _navigateToAttractionSearch() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AttractionSearchScreen(trip: _trip)),
    );
    _reloadTrip();
  }

  void _navigateToRestaurantSearch() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RestaurantSearchScreen(trip: _trip)),
    );
    _reloadTrip();
  }

  void _openAttractionDetail(SavedAttraction attraction) {
    String startDate = '';
    String endDate = '';
    if (_trip.outboundFlight != null) {
      try {
        final dt = DateTime.parse(_trip.outboundFlight!.arrivalTime.replaceAll(' ', 'T'));
        startDate = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      } catch (_) {}
    }
    if (_trip.returnFlight != null) {
      try {
        final dt = DateTime.parse(_trip.returnFlight!.departureTime.replaceAll(' ', 'T'));
        endDate = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      } catch (_) {}
    }
    if (startDate.isEmpty) startDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (endDate.isEmpty) endDate = DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 7)));

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AttractionDetailScreen(
          contentId: attraction.locationId,
          startDate: startDate,
          endDate: endDate,
          trip: _trip,
        ),
      ),
    );
  }

  void _openRestaurantDetail(SavedRestaurant restaurant) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RestaurantDetailScreen(
          contentId: restaurant.locationId,
          trip: _trip,
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
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Activities',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(10),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.textSecondary,
        labelStyle: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerHeight: 0,
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.attractions_rounded, size: 16),
                const SizedBox(width: 6),
                Text('Attractions (${_trip.attractions.length})'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.restaurant_rounded, size: 16),
                const SizedBox(width: 6),
                Text('Restaurants (${_trip.restaurants.length})'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttractionsList() {
    if (_trip.attractions.isEmpty) {
      return _buildEmptyState(
        icon: Icons.attractions_rounded,
        message: 'No attractions saved yet',
        subtitle: 'Find and add attractions to your trip',
        actionLabel: 'Search Attractions',
        onAction: _navigateToAttractionSearch,
      );
    }
    return RefreshIndicator(
      onRefresh: _reloadTrip,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _trip.attractions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _buildAttractionCard(_trip.attractions[index]),
      ),
    );
  }

  Widget _buildRestaurantsList() {
    if (_trip.restaurants.isEmpty) {
      return _buildEmptyState(
        icon: Icons.restaurant_rounded,
        message: 'No restaurants saved yet',
        subtitle: 'Find and add restaurants to your trip',
        actionLabel: 'Search Restaurants',
        onAction: _navigateToRestaurantSearch,
      );
    }
    return RefreshIndicator(
      onRefresh: _reloadTrip,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _trip.restaurants.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _buildRestaurantCard(_trip.restaurants[index]),
      ),
    );
  }

  Widget _buildAttractionCard(SavedAttraction attraction) {
    return Dismissible(
      key: Key('attraction_${attraction.locationId}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Remove attraction'),
            content: Text('Remove "${attraction.name}" from this trip?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove')),
            ],
          ),
        );
      },
      onDismissed: (_) => _removeAttraction(attraction),
      child: GestureDetector(
        onTap: () => _openAttractionDetail(attraction),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Photo
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: attraction.photoUrl.isNotEmpty
                    ? Image.network(
                        attraction.photoUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.attractions_rounded, color: Colors.grey),
                        ),
                      )
                    : Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.attractions_rounded, color: Colors.grey),
                      ),
              ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attraction.name,
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  if (attraction.category.isNotEmpty)
                    Text(
                      attraction.category,
                      style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildScheduleBadge(attraction.dayDate, attraction.timeSlot),
                      const Spacer(),
                      if (attraction.isPaid)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Paid',
                            style: GoogleFonts.poppins(fontSize: 11, color: Colors.green.shade700, fontWeight: FontWeight.w500),
                          ),
                        )
                      else
                        GestureDetector(
                          onTap: () => _showMarkAttractionPaidSheet(attraction),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_outline_rounded, size: 12, color: Colors.green.shade600),
                                const SizedBox(width: 3),
                                Text(
                                  'Mark Paid',
                                  style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.green.shade700),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildRestaurantCard(SavedRestaurant restaurant) {
    return Dismissible(
      key: Key('restaurant_${restaurant.locationId}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Remove restaurant'),
            content: Text('Remove "${restaurant.name}" from this trip?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove')),
            ],
          ),
        );
      },
      onDismissed: (_) => _removeRestaurant(restaurant),
      child: GestureDetector(
        onTap: () => _openRestaurantDetail(restaurant),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Photo
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: restaurant.photoUrl.isNotEmpty
                    ? Image.network(
                        restaurant.photoUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.restaurant_rounded, color: Colors.grey),
                        ),
                      )
                    : Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.restaurant_rounded, color: Colors.grey),
                      ),
              ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  if (restaurant.cuisine.isNotEmpty)
                    Text(
                      restaurant.cuisine,
                      style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildScheduleBadge(restaurant.dayDate, restaurant.timeSlot),
                      const Spacer(),
                      if (restaurant.isPaid)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Paid',
                            style: GoogleFonts.poppins(fontSize: 11, color: Colors.green.shade700, fontWeight: FontWeight.w500),
                          ),
                        )
                      else
                        GestureDetector(
                          onTap: () => _showMarkRestaurantPaidSheet(restaurant),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_outline_rounded, size: 12, color: Colors.green.shade600),
                                const SizedBox(width: 3),
                                Text(
                                  'Mark Paid',
                                  style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.green.shade700),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildScheduleBadge(String dayDate, String timeSlot) {
    String label = '';
    if (dayDate.isNotEmpty) {
      try {
        final dt = DateTime.parse(dayDate);
        label = DateFormat('MMM d').format(dt);
      } catch (_) {
        label = dayDate;
      }
    }
    final slotLabel = _capitalizeSlot(timeSlot);
    if (label.isNotEmpty && slotLabel.isNotEmpty) {
      label = '$label • $slotLabel';
    } else if (slotLabel.isNotEmpty) {
      label = slotLabel;
    }
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  String _capitalizeSlot(String slot) {
    if (slot.isEmpty) return '';
    return slot[0].toUpperCase() + slot.substring(1);
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppTheme.primaryColor.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(
              message,
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.search_rounded, size: 18),
                label: Text(actionLabel, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Mark Activity Paid Sheet ───────────────────────────────────────────

class _ActivityMarkPaidSheet extends StatefulWidget {
  final List<TripMember> members;
  final String tripId;
  final String locationId;
  final String itemType; // 'attraction' or 'restaurant'
  final String itemName;
  final VoidCallback onDone;

  const _ActivityMarkPaidSheet({
    required this.members,
    required this.tripId,
    required this.locationId,
    required this.itemType,
    required this.itemName,
    required this.onDone,
  });

  @override
  State<_ActivityMarkPaidSheet> createState() => _ActivityMarkPaidSheetState();
}

class _ActivityMarkPaidSheetState extends State<_ActivityMarkPaidSheet> {
  final TextEditingController _amountController = TextEditingController();
  String _currency = 'EUR';
  String? _paidBy;
  final Set<String> _selectedMembers = {};
  bool _isSaving = false;

  final _currencies = ['EUR', 'USD', 'GBP', 'GEL', 'CHF', 'CZK', 'PLN', 'HUF', 'SEK', 'NOK', 'DKK'];

  @override
  void initState() {
    super.initState();
    for (final m in widget.members) {
      _selectedMembers.add(m.userId);
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
        SnackBar(
          content: Text('Please fill all fields', style: GoogleFonts.poppins()),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) return;

    setState(() => _isSaving = true);
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    try {
      final api = ApiService();
      if (widget.itemType == 'attraction') {
        await api.markAttractionPaid(
          token: token,
          tripId: widget.tripId,
          locationId: widget.locationId,
          actualPaidAmount: amount,
          paidBy: _paidBy!,
          eligibleMemberIds: _selectedMembers.toList(),
          currency: _currency,
        );
      } else {
        await api.markRestaurantPaid(
          token: token,
          tripId: widget.tripId,
          locationId: widget.locationId,
          actualPaidAmount: amount,
          paidBy: _paidBy!,
          eligibleMemberIds: _selectedMembers.toList(),
          currency: _currency,
        );
      }
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
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Mark as Paid',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              widget.itemName,
              style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F5FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
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
            // Who paid
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
                    child: Text(
                      m.displayName,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: selected ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
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
                        Text(
                          m.displayName,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: selected ? Colors.white : AppTheme.textPrimary,
                          ),
                        ),
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
                    : Text('Confirm Payment', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
