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
import '../playlists/my_playlists_screen.dart';
import '../templates/template_discovery_screen.dart';
import '../templates/my_templates_screen.dart';
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
    _tabController = TabController(length: 3, vsync: this);
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
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: AppSpacing.paddingHorizontalXl,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.xl),
                _buildHeader(context),
                const SizedBox(height: AppSpacing.xl),
                _buildPlanButton(context),
                const SizedBox(height: AppSpacing.sm),
                _buildQuickActions(context),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
          // Trip tabs
          _buildTripTabs(),
          Expanded(child: _buildTripsTabView()),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // Header
  // ────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    final ew = context.ew;

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: AppRadius.borderMd,
          ),
          child: const Icon(Icons.public_rounded, color: Colors.white, size: 24),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            'EuroWander',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
        ),
        EWIconButton(
          icon: Icons.logout_rounded,
          iconColor: ew.textSecondary,
          size: 40,
          tooltip: 'Log out',
          onTap: () => context.read<AuthProvider>().logout(),
        ),
      ],
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
    return Column(
      children: [
        Row(
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
                label: 'My Playlists',
                icon: Icons.playlist_play_rounded,
                color: AppColors.brandSecondary,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyPlaylistsScreen()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
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
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OutlineActionButton(
                label: 'My Templates',
                icon: Icons.dashboard_customize_rounded,
                color: AppColors.brandDeepOrange,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyTemplatesScreen()),
                ),
              ),
            ),
          ],
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
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        labelPadding: EdgeInsets.zero,
        padding: const EdgeInsets.all(3),
        tabs: [
          Tab(text: 'Active (${_activeTrips.length})'),
          Tab(text: 'Upcoming (${_upcomingTrips.length})'),
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
        _buildTripGrid(_activeTrips, emptyIcon: Icons.flight_takeoff_rounded, emptyTitle: 'No active trips', emptySubtitle: 'Your ongoing adventures will appear here'),
        _buildTripGrid(_upcomingTrips, emptyIcon: Icons.upcoming_rounded, emptyTitle: 'No upcoming trips', emptySubtitle: 'Plan a new trip to get started!'),
        _buildTripGrid(_previousTrips, emptyIcon: Icons.photo_album_rounded, emptyTitle: 'No past trips', emptySubtitle: 'Your completed adventures will live here'),
      ],
    );
  }

  Widget _buildTripGrid(List<SavedTrip> trips, {required IconData emptyIcon, required String emptyTitle, required String emptySubtitle}) {
    if (trips.isEmpty) {
      return Center(child: EmptyState(icon: emptyIcon, title: emptyTitle, subtitle: emptySubtitle));
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
          child: _buildTripCard(trips[index]),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // Trip Card
  // ────────────────────────────────────────────────────────────

  Widget _buildTripCard(SavedTrip trip) {
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

    return GestureDetector(
      onTap: () async {
        await Navigator.of(context).push(EWPageRoute(page: TripDetailScreen(trip: trip)));
        _loadTrips();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: ew.cardColor,
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
                      height: 100,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        height: 100,
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

                  // Route
                  if (origin.isNotEmpty || destination.isNotEmpty)
                    Row(
                      children: [
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
                    ),
                  const SizedBox(height: 10),

                  // Info chips
                  Row(
                    children: [
                      if (depDate != null)
                        _tripInfoChip(Icons.calendar_today_rounded, DateFormat('MMM d').format(depDate), ew),
                      if (days != null) ...[
                        const SizedBox(width: 8),
                        _tripInfoChip(Icons.timelapse_rounded, '$days days', ew),
                      ],
                      if (trip.hotels.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        _tripInfoChip(Icons.hotel_rounded, '${trip.hotels.length}', ew),
                      ],
                      if (trip.attractions.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        _tripInfoChip(Icons.attractions_rounded, '${trip.attractions.length}', ew),
                      ],
                    ],
                  ),

                  // Days remaining / ago
                  if (depDate != null) ...[
                    const SizedBox(height: 10),
                    _buildCountdown(depDate, retDate, isActive, isPast),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tripInfoChip(IconData icon, String text, EuroWanderTheme ew) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: ew.textSecondary),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: ew.textSecondary)),
      ]),
    );
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

  String? _formatDate(String? dateStr) {
    if (dateStr == null) return null;
    try {
      final dt = DateTime.parse(dateStr.replaceAll(' ', 'T'));
      return DateFormat('MMM d, yyyy').format(dt);
    } catch (_) {
      return null;
    }
  }
}
