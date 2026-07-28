import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/saved_trip.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/page_transitions.dart';
import '../../widgets/widgets.dart';
import '../plan/city_selection_screen.dart';
import '../playlists/playlist_discovery_screen.dart';
import '../profile/profile_screen.dart';
import '../templates/template_discovery_screen.dart';
import 'trip_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  List<SavedTrip> _trips = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTrips();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTrips() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    try {
      final trips = await _apiService.getTrips(token: token);
      if (mounted) {
        setState(() {
          _trips = trips;
          _isLoading = false;
        });
        _autoSelectTab();
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _autoSelectTab() {
    if (_upcomingTrips.isNotEmpty) {
      _tabController.index = 0;
    } else if (_previousTrips.isNotEmpty) {
      _tabController.index = 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Padding(
                padding: AppSpacing.paddingHorizontalXl,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.xl),
                    _buildHeader(context),
                    const SizedBox(height: AppSpacing.lg),
                    _buildPlanButton(context),
                    const SizedBox(height: AppSpacing.sm),
                    _buildQuickActions(context),
                    const SizedBox(height: AppSpacing.lg),
                    if (!_isLoading) _buildFeaturedTrip(),
                    if (!_isLoading && _featuredTrip != null) const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _buildTripTabs(),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.md),
            ),
          ];
        },
        body: _buildTripsTabView(),
      ),
    );
  }

  /// The featured trip is the first active trip, or the first upcoming trip if none are active.
  SavedTrip? get _featuredTrip {
    if (_activeTrips.isNotEmpty) return _activeTrips.first;
    if (_upcomingTrips.isNotEmpty) return _upcomingTrips.first;
    return null;
  }

  /// Upcoming trips excluding the featured one (to avoid duplication in the tab).
  List<SavedTrip> get _remainingUpcomingTrips {
    final featured = _featuredTrip;
    if (featured == null) return _upcomingTrips;
    return _upcomingTrips.where((t) => t != featured).toList();
  }

  Widget _buildFeaturedTrip() {
    final trip = _featuredTrip;
    if (trip == null) return const SizedBox.shrink();
    return _buildFeaturedTripCard(trip);
  }

  Widget _buildFeaturedTripCard(SavedTrip trip) {
    final ew = context.ew;
    final theme = Theme.of(context);
    final depDate = _getDepartureDate(trip);
    final retDate = _getReturnDate(trip);
    final destination = trip.outboundFlight?.arrivalCityName.isNotEmpty == true
        ? trip.outboundFlight!.arrivalCityName
        : trip.outboundFlight?.legs.isNotEmpty == true
            ? trip.outboundFlight!.legs.last.arrivalCityName
            : '';
    final origin = trip.outboundFlight?.departureCityName.isNotEmpty == true
        ? trip.outboundFlight!.departureCityName
        : '';
    final days = depDate != null && retDate != null ? retDate.difference(depDate).inDays : null;
    final isActive = _activeTrips.contains(trip);

    return Material(
      color: ew.cardColor,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          await Navigator.of(context).push(EWPageRoute(page: TripDetailScreen(trip: trip)));
          _loadTrips();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.success.withOpacity(0.6), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.success.withOpacity(0.1),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo
              if (trip.destinationPhotoUrl != null && trip.destinationPhotoUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                  child: Stack(
                    children: [
                      Image.network(
                        trip.destinationPhotoUrl!,
                        height: 130,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 130,
                            color: Colors.grey.withOpacity(0.1),
                            child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                          );
                        },
                        errorBuilder: (_, _, _) => Container(
                          height: 130,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(colors: [AppColors.success, Color(0xFF66BB6A)]),
                          ),
                          child: Center(child: Icon(Icons.location_city_rounded, size: 36, color: Colors.white.withOpacity(0.5))),
                        ),
                      ),
                      // Scrim
                      Positioned(
                        bottom: 0, left: 0, right: 0,
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black.withOpacity(0.5)],
                            ),
                          ),
                        ),
                      ),
                      // Status badge
                      Positioned(
                        top: 10, left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isActive ? AppColors.success : AppColors.brandPrimary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(
                              isActive ? Icons.flight_takeoff_rounded : Icons.upcoming_rounded,
                              size: 12, color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isActive ? 'Active Now' : 'Next Trip',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                          ]),
                        ),
                      ),
                      // Countdown badge
                      if (depDate != null)
                        Positioned(
                          top: 10, right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: _buildCompactCountdown(depDate, retDate, isActive, false),
                          ),
                        ),
                      // Destination on photo
                      if (destination.isNotEmpty)
                        Positioned(
                          bottom: 10, left: 12,
                          child: Text(
                            destination,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white, shadows: [Shadow(blurRadius: 4, color: Colors.black54)]),
                          ),
                        ),
                    ],
                  ),
                )
              else
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                    gradient: const LinearGradient(colors: [AppColors.success, Color(0xFF66BB6A)]),
                  ),
                ),
              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trip.name,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              if (origin.isNotEmpty || destination.isNotEmpty) ...[
                                Icon(Icons.flight_takeoff_rounded, size: 14, color: ew.textSecondary),
                                const SizedBox(width: 5),
                                if (origin.isNotEmpty)
                                  Text(origin, style: TextStyle(fontSize: 12, color: ew.textSecondary)),
                                if (origin.isNotEmpty && destination.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Icon(Icons.arrow_forward_rounded, size: 12, color: ew.textSecondary),
                                  ),
                                if (destination.isNotEmpty)
                                  Text(destination, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success)),
                              ],
                            ],
                          ),
                          if (depDate != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              days != null
                                  ? '${DateFormat('MMM d').format(depDate)} – ${DateFormat('MMM d').format(retDate!)} · $days days'
                                  : DateFormat('MMM d, yyyy').format(depDate),
                              style: TextStyle(fontSize: 11, color: ew.textSecondary),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_forward_rounded, size: 18, color: AppColors.success),
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

  // ────────────────────────────────────────────────────────────
  // Header
  // ────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    final ew = context.ew;
    final user = context.watch<AuthProvider>().user;
    final firstName = user?.firstName ?? '';
    final initials = '${user?.firstName.isNotEmpty == true ? user!.firstName[0] : ''}${user?.lastName.isNotEmpty == true ? user!.lastName[0] : ''}';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting(),
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: ew.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                firstName.isNotEmpty ? 'Hey, $firstName!' : 'Welcome back!',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).push(
            EWPageRoute(page: const ProfileScreen()),
          ),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials.toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _showAccountSheet(BuildContext context) {
    final ew = context.ew;
    final user = context.read<AuthProvider>().user;
    showModalBottomSheet(
      context: context,
      backgroundColor: ew.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: AppSpacing.xl),
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    '${user?.firstName[0] ?? ''}${user?.lastName[0] ?? ''}'.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(user?.fullName ?? '', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(user?.email ?? '', style: TextStyle(fontSize: 13, color: ew.textSecondary)),
              const SizedBox(height: AppSpacing.xxl),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    context.read<AuthProvider>().logout();
                  },
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Log Out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: AppColors.error.withOpacity(0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // CTA Button
  // ────────────────────────────────────────────────────────────

  Widget _buildPlanButton(BuildContext context) {
    return GradientButton(
      label: 'Plan New Trip',
      icon: Icons.add_circle_outline_rounded,
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CitySelectionScreen()),
        );
        _loadTrips();
      },
    );
  }

  // ────────────────────────────────────────────────────────────
  // Quick Action Grid
  // ────────────────────────────────────────────────────────────

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlineActionButton(
            label: 'Playlists',
            icon: Icons.explore_rounded,
            color: AppColors.brandPrimary,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PlaylistDiscoveryScreen()),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: OutlineActionButton(
            label: 'Templates',
            icon: Icons.compass_calibration_rounded,
            color: AppColors.brandAmber,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TemplateDiscoveryScreen()),
            ),
          ),
        ),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────
  // Trip Categorization
  // ────────────────────────────────────────────────────────────

  DateTime? _getDepartureDate(SavedTrip trip) {
    final depStr = trip.outboundFlight?.departureTime;
    if (depStr == null || depStr.isEmpty) return null;
    try { return DateTime.parse(depStr.replaceAll(' ', 'T')); } catch (_) { return null; }
  }

  DateTime? _getReturnDate(SavedTrip trip) {
    final retStr = trip.returnFlight?.arrivalTime;
    if (retStr == null || retStr.isEmpty) return null;
    try { return DateTime.parse(retStr.replaceAll(' ', 'T')); } catch (_) { return null; }
  }

  List<SavedTrip> get _activeTrips {
    final now = DateTime.now();
    return _trips.where((t) {
      final dep = _getDepartureDate(t);
      final ret = _getReturnDate(t);
      if (dep == null) return false;
      final end = ret ?? dep.add(const Duration(days: 7));
      return !dep.isAfter(now) && end.isAfter(now);
    }).toList();
  }

  List<SavedTrip> get _upcomingTrips {
    final now = DateTime.now();
    return _trips.where((t) {
      final dep = _getDepartureDate(t);
      if (dep == null) return true; // No flight yet = upcoming/planning
      return dep.isAfter(now);
    }).toList()
      ..sort((a, b) {
        final da = _getDepartureDate(a);
        final db = _getDepartureDate(b);
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return da.compareTo(db);
      });
  }

  List<SavedTrip> get _previousTrips {
    final now = DateTime.now();
    return _trips.where((t) {
      final dep = _getDepartureDate(t);
      final ret = _getReturnDate(t);
      if (dep == null) return false;
      final end = ret ?? dep.add(const Duration(days: 7));
      return !end.isAfter(now);
    }).toList()
      ..sort((a, b) {
        final da = _getDepartureDate(a);
        final db = _getDepartureDate(b);
        if (da == null || db == null) return 0;
        return db.compareTo(da); // Most recent first
      });
  }

  // ────────────────────────────────────────────────────────────
  // Trip Tabs
  // ────────────────────────────────────────────────────────────

  Widget _buildTripTabs() {
    final ew = context.ew;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      decoration: BoxDecoration(
        color: ew.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.12)),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.brandPrimary,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerHeight: 0,
        labelColor: Colors.white,
        unselectedLabelColor: ew.textSecondary,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        labelPadding: EdgeInsets.zero,
        padding: const EdgeInsets.all(3),
        tabs: [
          Tab(text: 'Upcoming (${_remainingUpcomingTrips.length})'),
          Tab(text: 'Previous (${_previousTrips.length})'),
        ],
      ),
    );
  }

  Widget _buildTripsTabView() {
    if (_isLoading) {
      return const ShimmerList(itemCount: 3);
    }

    if (_trips.isEmpty) {
      return EmptyState(
        icon: Icons.luggage_outlined,
        title: 'No trips yet',
        subtitle: 'Plan your first European adventure!',
        actionLabel: 'Get Started',
        onAction: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CitySelectionScreen()),
          );
          _loadTrips();
        },
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildTripGrid(_remainingUpcomingTrips, emptyIcon: Icons.upcoming_rounded, emptyTitle: 'No upcoming trips', emptySubtitle: 'Plan a new trip to get started!', showCta: true),
        _buildTripGrid(_previousTrips, emptyIcon: Icons.photo_album_rounded, emptyTitle: 'No past trips', emptySubtitle: 'Your completed adventures will live here', showCta: true),
      ],
    );
  }

  Widget _buildTripGrid(List<SavedTrip> trips, {required IconData emptyIcon, required String emptyTitle, required String emptySubtitle, bool showCta = false}) {
    if (trips.isEmpty) {
      return Center(
        child: EmptyState(
          icon: emptyIcon,
          title: emptyTitle,
          subtitle: emptySubtitle,
          actionLabel: showCta ? 'Plan a Trip' : null,
          onAction: showCta
              ? () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CitySelectionScreen()),
                  );
                  _loadTrips();
                }
              : null,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTrips,
      color: AppColors.brandPrimary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.xl),
        itemCount: trips.length,
        itemBuilder: (context, index) => TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 400 + (index * 100)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(offset: Offset(0, 16 * (1 - value)), child: child),
          ),
          child: _buildTripCard(trips[index], isHero: index == 0),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // Trip Card
  // ────────────────────────────────────────────────────────────

  Widget _buildTripCard(SavedTrip trip, {bool isHero = false}) {
    final ew = context.ew;
    final theme = Theme.of(context);
    final depDate = _getDepartureDate(trip);
    final retDate = _getReturnDate(trip);
    final destination = trip.outboundFlight?.arrivalCityName.isNotEmpty == true
        ? trip.outboundFlight!.arrivalCityName
        : trip.outboundFlight?.legs.isNotEmpty == true
            ? trip.outboundFlight!.legs.last.arrivalCityName
            : '';
    final origin = trip.outboundFlight?.departureCityName.isNotEmpty == true
        ? trip.outboundFlight!.departureCityName
        : '';

    final days = depDate != null && retDate != null ? retDate.difference(depDate).inDays : null;
    final isActive = _activeTrips.contains(trip);
    final isPast = _previousTrips.contains(trip);
    final photoHeight = isHero ? 140.0 : 100.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: ew.cardColor,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () async {
            await Navigator.of(context).push(EWPageRoute(page: TripDetailScreen(trip: trip)));
            _loadTrips();
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: isActive ? Border.all(color: AppColors.brandPrimary.withOpacity(0.4), width: 1.5) : null,
              boxShadow: [
                BoxShadow(
                  color: isActive ? AppColors.brandPrimary.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                  blurRadius: isActive ? 16 : 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Destination photo or gradient bar
                if (trip.destinationPhotoUrl != null && trip.destinationPhotoUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Stack(
                      children: [
                        Image.network(
                          trip.destinationPhotoUrl!,
                          height: photoHeight,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: photoHeight,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: ew.cardColor,
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.grey.withOpacity(0.1),
                                    Colors.grey.withOpacity(0.2),
                                    Colors.grey.withOpacity(0.1),
                                  ],
                                ),
                              ),
                              child: Center(
                                child: SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.brandPrimary.withOpacity(0.5),
                                  ),
                                ),
                              ),
                            );
                          },
                          errorBuilder: (_, _, _) => Container(
                            height: photoHeight,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isActive
                                    ? [AppColors.brandPrimary, AppColors.brandSecondary]
                                    : isPast
                                        ? [Colors.grey.shade400, Colors.grey.shade300]
                                        : [const Color(0xFFFF9800), const Color(0xFFFFC107)],
                              ),
                            ),
                            child: Center(child: Icon(Icons.location_city_rounded, size: 36, color: Colors.white.withOpacity(0.5))),
                          ),
                        ),
                        // Gradient scrim at bottom for readability
                        Positioned(
                          bottom: 0, left: 0, right: 0,
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black.withOpacity(0.4)],
                              ),
                            ),
                          ),
                        ),
                        // Destination name on photo
                        if (destination.isNotEmpty)
                          Positioned(
                            bottom: 8, left: 12,
                            child: Text(
                              destination,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white, shadows: [Shadow(blurRadius: 4, color: Colors.black54)]),
                            ),
                          ),
                        // Countdown badge on hero card
                        if (isHero && depDate != null)
                          Positioned(
                            top: 10, right: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: _buildCompactCountdown(depDate, retDate, isActive, isPast),
                            ),
                          ),
                      ],
                    ),
                  )
                else
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      gradient: isActive
                          ? const LinearGradient(colors: [AppColors.brandPrimary, AppColors.brandSecondary])
                          : isPast
                              ? LinearGradient(colors: [Colors.grey.shade400, Colors.grey.shade300])
                              : const LinearGradient(colors: [Color(0xFFFF9800), Color(0xFFFFC107)]),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title + status badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              trip.name,
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle)),
                                const SizedBox(width: 4),
                                const Text('Active', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF4CAF50))),
                              ]),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Route + date combined row
                      Row(
                        children: [
                          if (origin.isNotEmpty || destination.isNotEmpty) ...[
                            Icon(Icons.flight_takeoff_rounded, size: 15, color: ew.textSecondary),
                            const SizedBox(width: 6),
                            if (origin.isNotEmpty) ...[
                              Text(origin, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: ew.textPrimary)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Icon(Icons.arrow_forward_rounded, size: 14, color: ew.textSecondary),
                              ),
                            ],
                            if (destination.isNotEmpty)
                              Text(destination, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.brandPrimary)),
                          ],
                          const Spacer(),
                          if (depDate != null)
                            Text(
                              days != null ? '${DateFormat('MMM d').format(depDate)} · $days days' : DateFormat('MMM d').format(depDate),
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: ew.textSecondary),
                            ),
                        ],
                      ),

                      // Countdown (only if no hero badge already showing it)
                      if (depDate != null && !isHero) ...[
                        const SizedBox(height: 10),
                        _buildCountdown(depDate, retDate, isActive, isPast),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactCountdown(DateTime depDate, DateTime? retDate, bool isActive, bool isPast) {
    final now = DateTime.now();
    if (isActive) {
      final daysLeft = (retDate ?? depDate.add(const Duration(days: 7))).difference(now).inDays;
      return Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.sunny, size: 12, color: Color(0xFFFFC107)),
        const SizedBox(width: 4),
        Text(daysLeft > 0 ? '$daysLeft days left' : 'Last day!', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
      ]);
    } else if (isPast) {
      final daysAgo = now.difference(retDate ?? depDate).inDays;
      return Text(
        daysAgo < 30 ? '$daysAgo days ago' : '${(daysAgo / 30).floor()}mo ago',
        style: const TextStyle(fontSize: 11, color: Colors.white70),
      );
    } else {
      final daysUntil = depDate.difference(now).inDays;
      return Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.schedule_rounded, size: 12, color: Colors.white),
        const SizedBox(width: 4),
        Text(daysUntil <= 1 ? 'Tomorrow!' : 'In $daysUntil days', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
      ]);
    }
  }



  Widget _buildCountdown(DateTime depDate, DateTime? retDate, bool isActive, bool isPast) {
    final now = DateTime.now();
    final ew = context.ew;

    if (isActive) {
      final daysLeft = (retDate ?? depDate.add(const Duration(days: 7))).difference(now).inDays;
      return Row(children: [
        const Icon(Icons.sunny, size: 14, color: Color(0xFFFF9800)),
        const SizedBox(width: 4),
        Text(
          daysLeft > 0 ? '$daysLeft days remaining' : 'Last day!',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFFFF9800)),
        ),
      ]);
    } else if (isPast) {
      final daysAgo = now.difference(retDate ?? depDate).inDays;
      return Row(children: [
        Icon(Icons.history_rounded, size: 14, color: ew.textSecondary),
        const SizedBox(width: 4),
        Text(
          daysAgo < 30 ? '$daysAgo days ago' : '${(daysAgo / 30).floor()} months ago',
          style: TextStyle(fontSize: 12, color: ew.textSecondary),
        ),
      ]);
    } else {
      final daysUntil = depDate.difference(now).inDays;
      return Row(children: [
        const Icon(Icons.schedule_rounded, size: 14, color: AppColors.brandPrimary),
        const SizedBox(width: 4),
        Text(
          daysUntil <= 1 ? 'Tomorrow!' : 'In $daysUntil days',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.brandPrimary),
        ),
      ]);
    }
  }

}
