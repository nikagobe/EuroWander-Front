import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/saved_trip.dart';
import 'attraction_search_screen.dart';
import 'restaurant_search_screen.dart';
import 'trip_documents_screen.dart';
import 'trip_finances_screen.dart';
import 'trip_hotels_screen.dart';
import 'trip_members_screen.dart';
import 'trip_photos_screen.dart';
import 'trip_tickets_screen.dart';

class TripDetailScreen extends StatelessWidget {
  final SavedTrip trip;

  const TripDetailScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF8F5FF),
              Color(0xFFEDE7F6),
              Color(0xFFF3E5F5),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  _buildAppBar(context),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          _buildTripHeader(),
                          const SizedBox(height: 32),
                          Text(
                            'Trip Modules',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildModuleGrid(context),
                          const SizedBox(height: 32),
                        ],
                      ),
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
              'Trip Details',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TripMembersScreen(trip: trip),
                ),
              );
            },
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
                Icons.group_rounded,
                size: 20,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            trip.name,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          _buildTripDatesRow(),
          const SizedBox(height: 6),
          Text(
            'Created ${_formatDateTime(trip.createdAt)}',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripDatesRow() {
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

    return Row(
      children: [
        Icon(Icons.calendar_today_rounded, size: 14, color: AppTheme.primaryColor),
        const SizedBox(width: 6),
        Text(
          returnDate != null ? '$departureDate – $returnDate' : departureDate!,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildModuleGrid(BuildContext context) {
    final modules = [
      _ModuleItem(
        icon: Icons.confirmation_number_rounded,
        label: 'Tickets',
        subtitle: 'Flights & buses',
        gradientColors: [AppTheme.primaryColor, const Color(0xFF8B5CF6)],
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TripTicketsScreen(trip: trip),
            ),
          );
        },
      ),
      _ModuleItem(
        icon: Icons.description_rounded,
        label: 'Documents',
        subtitle: 'Passports & visas',
        gradientColors: [const Color(0xFF2196F3), const Color(0xFF42A5F5)],
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TripDocumentsScreen(trip: trip),
            ),
          );
        },
      ),
      _ModuleItem(
        icon: Icons.hotel_rounded,
        label: 'Hotels',
        subtitle: 'Accommodations',
        gradientColors: [const Color(0xFFFF9800), const Color(0xFFFFB74D)],
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TripHotelsScreen(trip: trip),
            ),
          );
        },
      ),
      _ModuleItem(
        icon: Icons.attractions_rounded,
        label: 'Attractions',
        subtitle: 'Things to do',
        gradientColors: [const Color(0xFFFF5722), const Color(0xFFFF8A65)],
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AttractionSearchScreen(trip: trip),
            ),
          );
        },
      ),
      _ModuleItem(
        icon: Icons.restaurant_rounded,
        label: 'Restaurants',
        subtitle: 'Where to eat',
        gradientColors: [const Color(0xFF795548), const Color(0xFFA1887F)],
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RestaurantSearchScreen(trip: trip),
            ),
          );
        },
      ),
      _ModuleItem(
        icon: Icons.account_balance_wallet_rounded,
        label: 'Finances',
        subtitle: 'Budget & expenses',
        gradientColors: [const Color(0xFF4CAF50), const Color(0xFF66BB6A)],
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TripFinancesScreen(trip: trip),
            ),
          );
        },
      ),
      _ModuleItem(
        icon: Icons.photo_library_rounded,
        label: 'Photos',
        subtitle: 'Trip memories',
        gradientColors: [const Color(0xFFE91E63), const Color(0xFFEC407A)],
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TripPhotosScreen(trip: trip),
            ),
          );
        },
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.0,
      ),
      itemCount: modules.length,
      itemBuilder: (context, index) => _buildModuleButton(modules[index]),
    );
  }

  Widget _buildModuleButton(_ModuleItem module) {
    return GestureDetector(
      onTap: module.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: module.gradientColors[0].withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
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
                  colors: module.gradientColors,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: module.gradientColors[0].withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                module.icon,
                size: 28,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              module.label,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              module.subtitle,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
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
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _ModuleItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.gradientColors,
    required this.onTap,
  });
}
