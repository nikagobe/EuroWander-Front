import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/city.dart';
import '../../models/flight.dart';
import '../../widgets/widgets.dart';
import 'regional_search_screen.dart';
import 'city_selection_screen.dart';

class ReturnFlightOptionsScreen extends StatelessWidget {
  final City origin;
  final City destination;
  final DateTime departureDate;
  final FlightOffer firstFlight;
  final int adults;

  const ReturnFlightOptionsScreen({
    super.key,
    required this.origin,
    required this.destination,
    required this.departureDate,
    required this.firstFlight,
    this.adults = 1,
  });

  @override
  Widget build(BuildContext context) {
    final arrivalLeg = firstFlight.legs.last;
    final arrivalCity = arrivalLeg.arrivalAirportName;
    final arrivalCountry = destination.country;
    final ew = context.ew;
    final theme = Theme.of(context);

    return AppScaffold(
      child: Column(
        children: [
          EWAppBar(title: 'Return Flight'),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.xxl),
                  // Trip summary card
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: ew.cardColor,
                      borderRadius: AppRadius.borderXl,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brandPrimary.withOpacity(0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.brandPrimary, AppColors.brandSecondary],
                            ),
                            borderRadius: AppRadius.borderLg,
                          ),
                          child: const Icon(
                            Icons.flight_takeoff_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Outbound flight booked',
                                style: theme.textTheme.labelLarge?.copyWith(color: ew.textPrimary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${origin.name} → ${destination.name} · €${firstFlight.price.toStringAsFixed(0)}',
                                style: theme.textTheme.bodySmall?.copyWith(color: ew.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE8F5E9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  Text(
                    'How would you like\nto find your return?',
                    style: theme.textTheme.headlineMedium?.copyWith(height: 1.2),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Arriving in $arrivalCity, $arrivalCountry',
                    style: theme.textTheme.bodySmall?.copyWith(color: ew.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  // Option 1: Regional cheap flights
                  _buildOptionCard(
                    context,
                    icon: Icons.local_offer_rounded,
                    title: 'Suggest Cheap Return\nFlights Nearby',
                    subtitle: 'Find affordable flights from airports across ${destination.country}',
                    gradientColors: [AppColors.brandPrimary, const Color(0xFF8B5CF6)],
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => RegionalSearchScreen(
                            arrivalCountry: destination.country,
                            defaultDestination: origin,
                            firstFlight: firstFlight,
                            origin: origin,
                            destination: destination,
                            outboundDate: departureDate,
                            adults: adults,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Option 2: Manual search
                  _buildOptionCard(
                    context,
                    icon: Icons.edit_rounded,
                    title: 'Choose Return Flight\nManually',
                    subtitle: 'Search with exact departure and arrival cities',
                    gradientColors: [AppColors.brandSecondary, const Color(0xFFE91E63)],
                    onTap: () {
                      // Navigate to city selection with pre-filled swapped cities
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CitySelectionScreen(
                            prefillFrom: destination,
                            prefillTo: origin,
                            isReturn: true,
                            firstFlight: firstFlight,
                            outboundDestinationCity: destination,
                            adults: adults,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    final ew = context.ew;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: ew.cardColor,
          borderRadius: AppRadius.borderXl,
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradientColors),
                borderRadius: AppRadius.borderLg,
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: ew.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(color: ew.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
