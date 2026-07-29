import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/playlist.dart';
import '../../models/saved_trip.dart';
import '../../models/template.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/playlist_service.dart';
import '../../services/template_service.dart';
import '../../utils/page_transitions.dart';
import '../../widgets/home/destination_spotlight.dart';
import '../../widgets/home/hero_banner.dart';
import '../../widgets/home/smart_nudge.dart';
import '../../widgets/home/travel_separator.dart';
import '../../widgets/home/travel_stats_strip.dart';
import '../../widgets/widgets.dart';
import '../plan/city_selection_screen.dart';
import '../playlists/playlist_builder_screen.dart';
import '../playlists/playlist_detail_screen.dart';
import '../playlists/playlist_discovery_screen.dart';
import '../profile/profile_screen.dart';
import '../templates/create_template/create_template_screen.dart';
import '../templates/template_detail_screen.dart';
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

  // Popular data for carousels
  List<TemplateListItem> _popularTemplates = [];
  List<PlaylistSummary> _popularPlaylists = [];
  bool _isLoadingPopular = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTrips();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPopularContent());
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

  Future<void> _loadPopularContent() async {
    final token = context.read<AuthProvider>().token;

    // Load templates (no auth required)
    try {
      final templates = await TemplateService().getTemplates(
        sortBy: 'most_liked',
        limit: 8,
      );
      if (mounted) setState(() => _popularTemplates = templates);
    } catch (e) {
      debugPrint('[Home] Failed to load popular templates: $e');
    }

    // Load playlists (needs auth)
    if (token != null) {
      try {
        final playlists = await PlaylistService().searchPlaylists(
          token: token,
          sortBy: 'popular',
          limit: 8,
        );
        if (mounted) setState(() => _popularPlaylists = playlists);
      } catch (e) {
        debugPrint('[Home] Failed to load popular playlists: $e');
      }
    }

    if (mounted) setState(() => _isLoadingPopular = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final firstName = user?.firstName ?? '';
    final initials = '${user?.firstName.isNotEmpty == true ? user!.firstName[0] : ''}${user?.lastName.isNotEmpty == true ? user!.lastName[0] : ''}';

    // Collect destination photos from trips for the hero banner
    final tripPhotos = _trips
        .where((t) => t.destinationPhotoUrl != null && t.destinationPhotoUrl!.isNotEmpty)
        .map((t) => t.destinationPhotoUrl!)
        .take(5)
        .toList();

    return AppScaffold(
      floatingActionButton: _buildContextualFab(context),
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // 1. Hero Banner (replaces old header + plan button)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, 0),
                child: HeroBanner(
                  greeting: _getGreeting(),
                  userName: firstName,
                  onPlanTrip: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CitySelectionScreen()),
                    );
                    _loadTrips();
                  },
                  onProfileTap: () => Navigator.of(context).push(
                    EWPageRoute(page: const ProfileScreen()),
                  ),
                  profileInitials: initials,
                  destinationPhotos: tripPhotos,
                ),
              ),
            ),

            // 2. Smart Nudges (contextual trip suggestions)
            if (!_isLoading && _trips.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.lg),
                  child: SmartNudges(
                    trips: _trips,
                    onTripTap: (trip) async {
                      await Navigator.of(context).push(EWPageRoute(page: TripDetailScreen(trip: trip)));
                      _loadTrips();
                    },
                  ),
                ),
              ),

            // 3. Travel Stats Strip
            if (!_isLoading && _trips.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.lg),
                  child: TravelStatsStrip(
                    totalTrips: _trips.length,
                    totalCountries: _countUniqueCountries(),
                    totalPlaces: _countTotalPlaces(),
                    totalNights: _countTotalNights(),
                  ),
                ),
              ),

            // separator
            const SliverToBoxAdapter(
              child: TravelSeparator(style: TravelSeparatorStyle.flightPath),
            ),

            // 4. Featured Trip Card (if any)
            if (!_isLoading)
              SliverToBoxAdapter(
                child: Padding(
                  padding: AppSpacing.paddingHorizontalXl,
                  child: _buildFeaturedTrip(),
                ),
              ),
            if (!_isLoading && _featuredTrip != null)
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

            // 5. Popular Templates carousel (redesigned)
            SliverToBoxAdapter(child: _buildTemplatesCarousel()),

            // separator
            const SliverToBoxAdapter(
              child: TravelSeparator(style: TravelSeparatorStyle.dots),
            ),

            // 6. Destination Spotlight
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: DestinationSpotlight.seasonal(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TemplateDiscoveryScreen()),
                  ),
                ),
              ),
            ),

            // separator
            const SliverToBoxAdapter(
              child: TravelSeparator(style: TravelSeparatorStyle.wave),
            ),

            // 7. Popular Playlists carousel (redesigned)
            SliverToBoxAdapter(child: _buildPlaylistsCarousel()),

            // 8. Trip Tabs
            SliverToBoxAdapter(child: _buildTripTabs()),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
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
  // Stats Helpers
  // ────────────────────────────────────────────────────────────

  int _countUniqueCountries() {
    final cities = <String>{};
    for (final trip in _trips) {
      final city = trip.outboundFlight?.arrivalCityName;
      if (city != null && city.isNotEmpty) cities.add(city);
    }
    return cities.length;
  }

  int _countTotalPlaces() {
    int places = 0;
    for (final trip in _trips) {
      places += trip.attractions.length + trip.restaurants.length;
    }
    return places;
  }

  int _countTotalNights() {
    int nights = 0;
    for (final trip in _trips) {
      final dep = _getDepartureDate(trip);
      final ret = _getReturnDate(trip);
      if (dep != null && ret != null) {
        nights += ret.difference(dep).inDays;
      }
    }
    return nights;
  }

  // ────────────────────────────────────────────────────────────
  // Greeting
  // ────────────────────────────────────────────────────────────

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  // ────────────────────────────────────────────────────────────
  // Contextual FAB (smart floating action button)
  // ────────────────────────────────────────────────────────────

  Widget _buildContextualFab(BuildContext context) {
    final hasActiveTrip = _activeTrips.isNotEmpty;

    if (hasActiveTrip) {
      // Active trip: show quick-actions radial
      return _buildActiveTripFab(context);
    }
    return _buildCreateFab(context);
  }

  Widget _buildActiveTripFab(BuildContext context) {
    final activeTrip = _activeTrips.first;
    return PopupMenuButton<String>(
      onSelected: (value) {
        switch (value) {
          case 'view':
            Navigator.push(context, EWPageRoute(page: TripDetailScreen(trip: activeTrip)));
          case 'template':
            Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateTemplateScreen()));
          case 'playlist':
            Navigator.push(context, MaterialPageRoute(builder: (_) => const PlaylistBuilderScreen()));
        }
      },
      offset: const Offset(0, -180),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: context.ew.cardColor,
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'view',
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: AppColors.success.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.map_rounded, size: 18, color: AppColors.success),
            ),
            const SizedBox(width: 10),
            const Text('View Active Trip', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ]),
        ),
        PopupMenuItem(
          value: 'template',
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: AppColors.brandAmber.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.auto_awesome, size: 18, color: AppColors.brandAmber),
            ),
            const SizedBox(width: 10),
            const Text('Create Template', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ]),
        ),
        PopupMenuItem(
          value: 'playlist',
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: AppColors.brandPrimary.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.queue_music_rounded, size: 18, color: AppColors.brandPrimary),
            ),
            const SizedBox(width: 10),
            const Text('Create Playlist', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ]),
        ),
      ],
      child: Container(
        width: 56, height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.success, Color(0xFF34D399)]),
          shape: BoxShape.circle,
          boxShadow: AppShadows.glow(AppColors.success),
        ),
        child: const Icon(Icons.explore_rounded, color: Colors.white, size: 26),
      ),
    );
  }

  Widget _buildCreateFab(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'template') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateTemplateScreen()));
        } else if (value == 'playlist') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const PlaylistBuilderScreen()));
        }
      },
      offset: const Offset(0, -120),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: context.ew.cardColor,
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'template',
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: AppColors.brandAmber.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.map_rounded, size: 18, color: AppColors.brandAmber),
            ),
            const SizedBox(width: 10),
            const Text('Create Template', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ]),
        ),
        PopupMenuItem(
          value: 'playlist',
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: AppColors.brandPrimary.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.queue_music_rounded, size: 18, color: AppColors.brandPrimary),
            ),
            const SizedBox(width: 10),
            const Text('Create Playlist', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ]),
        ),
      ],
      child: Container(
        width: 56, height: 56,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: AppShadows.glow(AppColors.brandPrimary),
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // Popular Templates Carousel
  // ────────────────────────────────────────────────────────────

  Widget _buildTemplatesCarousel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.brandAmber.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.compass_calibration_rounded, size: 16, color: AppColors.brandAmber),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Popular Templates', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    Text('Community-crafted itineraries', style: TextStyle(fontSize: 11, color: context.ew.textTertiary)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TemplateDiscoveryScreen())),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.brandAmber.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('See All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.brandAmber)),
                    SizedBox(width: 2),
                    Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.brandAmber),
                  ]),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 220,
          child: _isLoadingPopular
              ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brandAmber)))
              : _popularTemplates.isEmpty
                  ? Center(child: Text('No templates yet', style: TextStyle(color: context.ew.textSecondary)))
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                      itemCount: _popularTemplates.length,
                      itemBuilder: (context, index) {
                        final t = _popularTemplates[index];
                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: Duration(milliseconds: 400 + (index * 80)),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) => Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(20 * (1 - value), 0),
                              child: child,
                            ),
                          ),
                          child: _buildTemplateTile(t, index),
                        );
                      },
                    ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  Widget _buildTemplateTile(TemplateListItem t, int index) {
    final ew = context.ew;
    // Subtle rotation for "postcard stack" effect
    final rotation = (index % 3 == 0) ? -0.01 : (index % 3 == 1) ? 0.01 : 0.0;

    return GestureDetector(
      onTap: () => Navigator.push(context, EWPageRoute(page: TemplateDetailScreen(templateId: t.id))),
      child: Transform.rotate(
        angle: rotation,
        child: Container(
          width: 200,
          margin: const EdgeInsets.only(right: 14),
          decoration: BoxDecoration(
            color: ew.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.brandAmber.withOpacity(0.15)),
            boxShadow: [
              BoxShadow(color: AppColors.brandAmber.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 6)),
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover with gradient overlay
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(
                  children: [
                    t.coverPhotoUrl.isNotEmpty
                        ? Image.network(t.coverPhotoUrl, height: 100, width: 200, fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _templateTilePlaceholder(t))
                        : _templateTilePlaceholder(t),
                    // Bottom scrim
                    Positioned(
                      bottom: 0, left: 0, right: 0,
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black.withOpacity(0.5)],
                          ),
                        ),
                      ),
                    ),
                    // Route on image
                    Positioned(
                      bottom: 6, left: 8, right: 8,
                      child: Text(
                        t.legCities.join(' → '),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white, shadows: [Shadow(blurRadius: 4, color: Colors.black54)]),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Days badge
                    Positioned(
                      top: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.brandAmber,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('${t.totalDays}d', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(children: [
                      // Fork count with icon
                      _buildMiniStat(Icons.fork_right_rounded, '${t.forkCount}', ew.textSecondary),
                      const SizedBox(width: 10),
                      _buildMiniStat(Icons.favorite_rounded, '${t.likeCount}', Colors.red.shade300),
                      const Spacer(),
                      // Budget indicator
                      if (t.estimatedBudgetMin != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '€${t.estimatedBudgetMin!.toInt()}+',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.success),
                          ),
                        ),
                    ]),
                    // Tags
                    if (t.tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: t.tags.take(3).map((tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.brandPrimary.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(tag, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: ew.textSecondary)),
                        )).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }

  Widget _templateTilePlaceholder(TemplateListItem t) {
    return Container(
      height: 90, width: 200,
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.brandPrimary, AppColors.brandSecondary]),
      ),
      child: Center(
        child: Text(
          t.legCities.isNotEmpty ? t.legCities.first : 'Trip',
          style: TextStyle(fontSize: 18, color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // Popular Playlists Carousel
  // ────────────────────────────────────────────────────────────

  Widget _buildPlaylistsCarousel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.explore_rounded, size: 16, color: AppColors.brandPrimary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Popular Playlists', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    Text('Curated city guides', style: TextStyle(fontSize: 11, color: context.ew.textTertiary)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlaylistDiscoveryScreen())),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('See All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.brandPrimary)),
                    SizedBox(width: 2),
                    Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.brandPrimary),
                  ]),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 160,
          child: _isLoadingPopular
              ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brandPrimary)))
              : _popularPlaylists.isEmpty
                  ? Center(child: Text('No playlists yet', style: TextStyle(color: context.ew.textSecondary)))
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                      itemCount: _popularPlaylists.length,
                      itemBuilder: (context, index) {
                        final p = _popularPlaylists[index];
                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: Duration(milliseconds: 400 + (index * 80)),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) => Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(20 * (1 - value), 0),
                              child: child,
                            ),
                          ),
                          child: _buildPlaylistTile(p),
                        );
                      },
                    ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  Widget _buildPlaylistTile(PlaylistSummary p) {
    final ew = context.ew;
    final vibeCol = _vibeColor(p.vibe);

    return GestureDetector(
      onTap: () => Navigator.push(context, EWPageRoute(page: PlaylistDetailScreen(playlistId: p.id))),
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: ew.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: vibeCol.withOpacity(0.12)),
          boxShadow: [
            BoxShadow(color: vibeCol.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: Row(
          children: [
            // Album art style cover
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              child: p.coverPhotoUrl.isNotEmpty
                  ? Image.network(p.coverPhotoUrl, width: 110, height: 160, fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _playlistAlbumArt(p, vibeCol))
                  : _playlistAlbumArt(p, vibeCol),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Vibe chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: vibeCol.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(p.vibe, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: vibeCol)),
                    ),
                    const SizedBox(height: 8),
                    // Title
                    Text(p.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    // City, Country
                    Row(children: [
                      Icon(Icons.location_on_rounded, size: 12, color: ew.textTertiary),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          '${p.city}, ${p.country}',
                          style: TextStyle(fontSize: 11, color: ew.textSecondary),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ]),
                    const Spacer(),
                    // Rating + imports
                    Row(children: [
                      if (p.averageRating > 0) ...[
                        const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFF9800)),
                        const SizedBox(width: 2),
                        Text(p.averageRating.toStringAsFixed(1), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ew.textPrimary)),
                        const SizedBox(width: 10),
                      ],
                      Icon(Icons.download_rounded, size: 13, color: ew.textTertiary),
                      const SizedBox(width: 3),
                      Text('${p.importCount}', style: TextStyle(fontSize: 11, color: ew.textSecondary)),
                      const Spacer(),
                      Text('${p.itemCount} places', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: ew.textTertiary)),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _playlistAlbumArt(PlaylistSummary p, Color vibeCol) {
    return Container(
      width: 110,
      height: 160,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [vibeCol, vibeCol.withOpacity(0.6)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.queue_music_rounded, size: 32, color: Colors.white.withOpacity(0.6)),
          const SizedBox(height: 6),
          Text(
            p.city,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(0.8)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _vibeColor(String vibe) {
    switch (vibe.toLowerCase()) {
      case 'adventure': return const Color(0xFFE65100);
      case 'romantic': return const Color(0xFFE91E63);
      case 'cultural': return const Color(0xFF7B1FA2);
      case 'foodie': return const Color(0xFFF57C00);
      case 'luxury': return const Color(0xFFFF9800);
      case 'budget': return const Color(0xFF4CAF50);
      case 'party': return const Color(0xFFE040FB);
      default: return AppColors.brandPrimary;
    }
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
    final photoHeight = isHero ? 140.0 : 110.0;

    // Trip detail counts
    final hotelCount = trip.hotels.length;
    final attractionCount = trip.attractions.length;
    final restaurantCount = trip.restaurants.length;
    final hasFlight = trip.outboundFlight != null;
    final hasDetails = hotelCount > 0 || attractionCount > 0 || restaurantCount > 0;

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
                        // Status badge (top left)
                        if (isActive)
                          Positioned(
                            top: 10, left: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(Icons.flight_takeoff_rounded, size: 11, color: Colors.white),
                                SizedBox(width: 4),
                                Text('Active', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
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
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row
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
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: (isActive ? AppColors.success : AppColors.brandPrimary).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 14,
                              color: isActive ? AppColors.success : AppColors.brandPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Route row
                      if (origin.isNotEmpty || destination.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Icon(Icons.flight_takeoff_rounded, size: 14, color: ew.textSecondary),
                              const SizedBox(width: 6),
                              if (origin.isNotEmpty) ...[
                                Text(origin, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: ew.textPrimary)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 5),
                                  child: Icon(Icons.arrow_forward_rounded, size: 12, color: ew.textSecondary),
                                ),
                              ],
                              if (destination.isNotEmpty)
                                Text(destination, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.brandPrimary)),
                              const Spacer(),
                              if (depDate != null)
                                Text(
                                  days != null ? '${DateFormat('MMM d').format(depDate)} · $days days' : DateFormat('MMM d').format(depDate),
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: ew.textSecondary),
                                ),
                            ],
                          ),
                        ),

                      // Trip detail chips (hotels, attractions, restaurants)
                      if (hasDetails || hasFlight)
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (hasFlight)
                              _buildDetailChip(Icons.flight_rounded, 'Flight', AppColors.flight),
                            if (hotelCount > 0)
                              _buildDetailChip(Icons.hotel_rounded, '$hotelCount ${hotelCount == 1 ? 'Hotel' : 'Hotels'}', AppColors.hotel),
                            if (attractionCount > 0)
                              _buildDetailChip(Icons.attractions_rounded, '$attractionCount ${attractionCount == 1 ? 'Place' : 'Places'}', AppColors.attraction),
                            if (restaurantCount > 0)
                              _buildDetailChip(Icons.restaurant_rounded, '$restaurantCount ${restaurantCount == 1 ? 'Restaurant' : 'Restaurants'}', AppColors.restaurant),
                          ],
                        ),
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

  Widget _buildDetailChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
        ],
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

}
