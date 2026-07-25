import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/saved_trip.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
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

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  List<SavedTrip> _trips = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrips();
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
                SectionHeader(
                  title: 'My Trips',
                  subtitle: _trips.isNotEmpty
                      ? '${_trips.length} adventure${_trips.length == 1 ? '' : 's'}'
                      : null,
                ),
                const SizedBox(height: AppSpacing.xxs),
              ],
            ),
          ),
          Expanded(child: _buildTripsList()),
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
  // Trips List
  // ────────────────────────────────────────────────────────────

  Widget _buildTripsList() {
    if (_isLoading) {
      return const ShimmerList(itemCount: 4);
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

    return RefreshIndicator(
      onRefresh: _loadTrips,
      color: AppColors.brandPrimary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.xs,
        ),
        itemCount: _trips.length,
        itemBuilder: (context, index) => _buildTripCard(_trips[index]),
      ),
    );
  }

  Widget _buildTripCard(SavedTrip trip) {
    final ew = context.ew;
    final destination = trip.outboundFlight?.legs.last.arrivalAirport ?? '';
    final departureDate = _formatDate(trip.outboundFlight?.legs.first.departureTime);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: EWCard(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => TripDetailScreen(trip: trip)),
          );
        },
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.brandPrimary.withOpacity(0.10),
                borderRadius: AppRadius.borderMd,
              ),
              child: const Icon(
                Icons.flight_takeoff_rounded,
                color: AppColors.brandPrimary,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.name,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xxxs),
                  Row(
                    children: [
                      if (destination.isNotEmpty) ...[
                        Icon(Icons.location_on_outlined, size: 13, color: ew.textSecondary),
                        const SizedBox(width: AppSpacing.xxxs),
                        Text(
                          destination,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      if (departureDate != null) ...[
                        Icon(Icons.calendar_today_outlined, size: 12, color: ew.textSecondary),
                        const SizedBox(width: AppSpacing.xxxs),
                        Text(
                          departureDate,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(Icons.chevron_right_rounded, color: ew.textTertiary, size: 20),
          ],
        ),
      ),
    );
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
