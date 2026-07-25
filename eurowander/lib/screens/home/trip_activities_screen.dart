// ignore_for_file: unused_element, unused_local_variable
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/widgets.dart';
import '../../models/saved_trip.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../playlists/playlist_discovery_screen.dart';
import 'activity_search_screen.dart';
import 'attraction_detail_screen.dart';
import 'restaurant_detail_screen.dart';

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
    return AppScaffold(
      child: Column(
        children: [
          EWAppBar(title: 'Activities'),
          _buildSearchBar(),
          const SizedBox(height: AppSpacing.xs),
          _buildImportPlaylistButton(),
          const SizedBox(height: AppSpacing.sm),
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
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => ActivitySearchScreen(trip: _trip)));
          _reloadTrip();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.brandPrimary, const Color(0xFF8B5CF6)],
            ),
            borderRadius: AppRadius.borderLg,
            boxShadow: [
              BoxShadow(
                color: AppColors.brandPrimary.withOpacity(0.3),
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
                  borderRadius: AppRadius.borderMd,
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
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(color: Colors.white),
                    ),
                    Text(
                      'Search attractions & restaurants',
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.white.withOpacity(0.8)),
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

  Widget _buildImportPlaylistButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlaylistDiscoveryScreen())),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppRadius.borderLg,
            border: Border.all(color: const Color(0xFF9C27B0).withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF9C27B0).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.playlist_play_rounded, color: Color(0xFF9C27B0), size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Import from Playlist', style: Theme.of(context).textTheme.labelLarge!.copyWith(color: context.ew.textPrimary)),
                    Text('Browse community itineraries', style: Theme.of(context).textTheme.labelSmall!.copyWith(color: context.ew.textSecondary)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: context.ew.textSecondary),
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
            const SizedBox(height: AppSpacing.lg),
            Text('What are you looking for?', style: Theme.of(context).textTheme.titleMedium!),
            const SizedBox(height: AppSpacing.md),
            _buildSearchOption(
              icon: Icons.attractions_rounded,
              label: 'Search Attractions',
              subtitle: 'Things to do & see',
              color: AppColors.restaurant,
              onTap: () {
                Navigator.pop(ctx);
                _navigateToAttractionSearch();
              },
            ),
            const SizedBox(height: AppSpacing.sm),
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
            const SizedBox(height: AppSpacing.md),
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
          borderRadius: AppRadius.borderLg,
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: AppRadius.borderMd,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.titleMedium!.copyWith(color: context.ew.textPrimary)),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall!.copyWith(color: context.ew.textSecondary)),
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
      MaterialPageRoute(builder: (_) => ActivitySearchScreen(trip: _trip, initialTab: 0)),
    );
    _reloadTrip();
  }

  void _navigateToRestaurantSearch() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ActivitySearchScreen(trip: _trip, initialTab: 1)),
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

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.borderMd,
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.brandPrimary,
          borderRadius: BorderRadius.circular(10),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: context.ew.textSecondary,
        labelStyle: Theme.of(context).textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: Theme.of(context).textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w500),
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
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
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
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
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
          borderRadius: AppRadius.borderLg,
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
            borderRadius: AppRadius.borderLg,
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
                borderRadius: AppRadius.borderMd,
                child: attraction.photoUrl.isNotEmpty
                    ? Image.network(
                        attraction.photoUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
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
            const SizedBox(width: AppSpacing.sm),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attraction.name,
                    style: Theme.of(context).textTheme.labelLarge!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  if (attraction.category.isNotEmpty)
                    Text(
                      attraction.category,
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(color: context.ew.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: AppSpacing.xxs),
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
                            style: Theme.of(context).textTheme.labelSmall!.copyWith(color: Colors.green.shade700, fontWeight: FontWeight.w500),
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
                                  style: Theme.of(context).textTheme.labelSmall!.copyWith(fontWeight: FontWeight.w600, color: Colors.green.shade700),
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
          borderRadius: AppRadius.borderLg,
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
            borderRadius: AppRadius.borderLg,
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
                borderRadius: AppRadius.borderMd,
                child: restaurant.photoUrl.isNotEmpty
                    ? Image.network(
                        restaurant.photoUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
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
            const SizedBox(width: AppSpacing.sm),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    style: Theme.of(context).textTheme.labelLarge!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  if (restaurant.cuisine.isNotEmpty)
                    Text(
                      restaurant.cuisine,
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(color: context.ew.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: AppSpacing.xxs),
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
                            style: Theme.of(context).textTheme.labelSmall!.copyWith(color: Colors.green.shade700, fontWeight: FontWeight.w500),
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
                                  style: Theme.of(context).textTheme.labelSmall!.copyWith(fontWeight: FontWeight.w600, color: Colors.green.shade700),
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
        color: AppColors.brandPrimary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall!.copyWith(fontWeight: FontWeight.w500, color: AppColors.brandPrimary),
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
            Icon(icon, size: 56, color: AppColors.brandPrimary.withOpacity(0.4)),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium!.copyWith(color: context.ew.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(color: context.ew.textSecondary),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.search_rounded, size: 18),
                label: Text(actionLabel, style: Theme.of(context).textTheme.labelLarge!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
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
          content: Text('Please fill all fields', style: Theme.of(context).textTheme.bodyMedium!),
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
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Mark as Paid',
              style: Theme.of(context).textTheme.headlineMedium!,
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              widget.itemName,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(color: context.ew.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
                    decoration: BoxDecoration(
                      color: AppColors.lightSurfaceVariant,
                      borderRadius: AppRadius.borderLg,
                    ),
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
            // Who paid
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
                    child: Text(
                      m.displayName,
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w500, color: selected ? Colors.white : context.ew.textPrimary),
                    ),
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
                        Text(
                          m.displayName,
                          style: Theme.of(context).textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w500, color: selected ? Colors.white : context.ew.textPrimary),
                        ),
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
                    : Text('Confirm Payment', style: Theme.of(context).textTheme.titleMedium!.copyWith(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

