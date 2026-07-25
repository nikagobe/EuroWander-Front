import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/saved_trip.dart';
import '../../widgets/widgets.dart';
import 'trip_activities_screen.dart';
import 'trip_documents_screen.dart';
import 'trip_finances_screen.dart';
import 'trip_hotels_screen.dart';
import 'trip_members_screen.dart';
import 'trip_photos_screen.dart';
import 'trip_schedule_screen.dart';
import 'trip_tickets_screen.dart';

class TripDetailScreen extends StatelessWidget {
  final SavedTrip trip;

  const TripDetailScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: Column(
        children: [
          EWAppBar(
            title: 'Trip Details',
            trailing: [
              EWIconButton(
                icon: Icons.group_rounded,
                iconColor: AppColors.brandPrimary,
                iconSize: 20,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => TripMembersScreen(trip: trip)),
                ),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: AppSpacing.paddingHorizontalXl,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.md),
                  _buildTripHeader(context),
                  const SizedBox(height: AppSpacing.xxl),
                  SectionHeader(title: 'Trip Modules'),
                  const SizedBox(height: AppSpacing.md),
                  _buildModuleGrid(context),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // Trip Header Card
  // ────────────────────────────────────────────────────────────

  Widget _buildTripHeader(BuildContext context) {
    final ew = context.ew;
    final theme = Theme.of(context);

    return EWCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            trip.name,
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          _buildTripDatesRow(context),
          const SizedBox(height: AppSpacing.xxs + 2),
          Text(
            'Created ${_formatDateTime(trip.createdAt)}',
            style: theme.textTheme.bodySmall?.copyWith(color: ew.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildTripDatesRow(BuildContext context) {
    String? departureDate;
    String? returnDate;

    if (trip.outboundFlight != null) {
      try {
        final dt = DateTime.parse(trip.outboundFlight!.departureTime.replaceAll(' ', 'T'));
        departureDate = DateFormat('MMM d, yyyy').format(dt);
      } catch (_) {}
    }
    if (trip.returnFlight != null) {
      try {
        final dt = DateTime.parse(trip.returnFlight!.arrivalTime.replaceAll(' ', 'T'));
        returnDate = DateFormat('MMM d, yyyy').format(dt);
      } catch (_) {}
    }

    if (departureDate == null && returnDate == null) return const SizedBox.shrink();

    return StatusChip(
      icon: Icons.calendar_today_rounded,
      label: returnDate != null ? '$departureDate – $returnDate' : departureDate!,
      color: AppColors.brandPrimary,
    );
  }

  // ────────────────────────────────────────────────────────────
  // Module Grid
  // ────────────────────────────────────────────────────────────

  Widget _buildModuleGrid(BuildContext context) {
    final modules = [
      _ModuleItem(
        icon: Icons.confirmation_number_rounded,
        label: 'Tickets',
        subtitle: 'Flights & buses',
        color: AppColors.flight,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => TripTicketsScreen(trip: trip)),
        ),
      ),
      _ModuleItem(
        icon: Icons.description_rounded,
        label: 'Documents',
        subtitle: 'Passports & visas',
        color: AppColors.info,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => TripDocumentsScreen(trip: trip)),
        ),
      ),
      _ModuleItem(
        icon: Icons.hotel_rounded,
        label: 'Hotels',
        subtitle: 'Accommodations',
        color: AppColors.hotel,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => TripHotelsScreen(trip: trip)),
        ),
      ),
      _ModuleItem(
        icon: Icons.explore_rounded,
        label: 'Activities',
        subtitle: 'Places to visit & eat',
        color: AppColors.restaurant,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => TripActivitiesScreen(trip: trip)),
        ),
      ),
      _ModuleItem(
        icon: Icons.account_balance_wallet_rounded,
        label: 'Finances',
        subtitle: 'Budget & expenses',
        color: AppColors.budget,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => TripFinancesScreen(trip: trip)),
        ),
      ),
      _ModuleItem(
        icon: Icons.photo_library_rounded,
        label: 'Photos',
        subtitle: 'Trip memories',
        color: AppColors.hotel,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => TripPhotosScreen(trip: trip)),
        ),
      ),
      _ModuleItem(
        icon: Icons.calendar_month_rounded,
        label: 'Schedule',
        subtitle: 'Day-by-day plan',
        color: AppColors.transport,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => TripScheduleScreen(trip: trip)),
        ),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.0,
      ),
      itemCount: modules.length,
      itemBuilder: (context, index) => _buildModuleButton(context, modules[index]),
    );
  }

  Widget _buildModuleButton(BuildContext context, _ModuleItem module) {
    final ew = context.ew;
    final theme = Theme.of(context);

    return Material(
      color: ew.cardColor,
      borderRadius: AppRadius.borderXxl,
      child: InkWell(
        onTap: module.onTap,
        borderRadius: AppRadius.borderXxl,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppRadius.borderXxl,
            boxShadow: [
              BoxShadow(
                color: module.color.withOpacity(0.10),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              ...AppShadows.sm(Colors.black),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      module.color,
                      module.color.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: AppRadius.borderLg,
                  boxShadow: AppShadows.md(module.color),
                ),
                child: Icon(module.icon, size: 28, color: Colors.white),
              ),
              const SizedBox(height: AppSpacing.sm + 2),
              Text(
                module.label,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                module.subtitle,
                style: theme.textTheme.labelSmall?.copyWith(color: ew.textTertiary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return DateFormat('MMM d, yyyy').format(dt);
  }
}

class _ModuleItem {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ModuleItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}
