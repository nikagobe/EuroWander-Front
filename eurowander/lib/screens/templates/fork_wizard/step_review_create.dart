import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/flight.dart';
import '../../../models/bus.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/fork_wizard_provider.dart';
import '../../../services/api_service.dart';

class StepReviewCreate extends StatelessWidget {
  final String templateId;
  final VoidCallback onBack;

  const StepReviewCreate({
    super.key,
    required this.templateId,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ForkWizardProvider>(
      builder: (context, provider, _) {
        final guide = provider.forkGuide;
        if (guide == null) {
          return const Center(child: Text('No fork guide loaded'));
        }

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Review Your Trip',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '"${guide.title}"',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),

                    // Selected items summary
                    ...guide.legs.map((leg) {
                      return _buildLegSummary(context, provider, leg);
                    }),

                    const SizedBox(height: 16),

                    // Estimated total
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Estimated total:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${guide.currency} ${provider.estimatedTotal.toInt()}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Skipped items warning
                    if (provider.skippedLegs.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Items you skipped:',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(height: 4),
                            ...provider.skippedLegs.map((legOrder) {
                              final leg = guide.legs.firstWhere(
                                  (l) => l.order == legOrder);
                              return Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  '⚠️ Leg $legOrder: ${leg.city} (you can add later)',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange,
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],

                    // Flight warning
                    if (!_hasBothFlights(provider)) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.3),
                          ),
                        ),
                        child: const Text(
                          '⚠️ You need to select both an outbound and return flight '
                          'to create your trip. Missing flights can be added later.',
                          style: TextStyle(fontSize: 12, color: Colors.red),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom action
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => _createTrip(context, provider),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          '🚀  CREATE MY TRIP',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: onBack,
                      child: const Text('← Go back and edit selections'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLegSummary(
      BuildContext context, ForkWizardProvider provider, dynamic leg) {
    final flight = provider.selectedFlights[leg.order];
    final transport = provider.selectedTransport[leg.order];
    final hotel = provider.selectedHotels[leg.order];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Leg ${leg.order}: ${leg.city}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          if (flight != null) ...[
            _buildSummaryRow(
              '✈️',
              '${flight.departureAirport} → ${flight.arrivalAirport}: '
              '${flight.legs.isNotEmpty ? flight.legs.first.airline : ""} '
              '— ${flight.currency}${flight.price.toInt()}',
            ),
          ],
          if (transport != null) ...[
            _buildSummaryRow(
              '🚌',
              '${transport.depName} → ${transport.arrName}: '
              '${transport.segments.isNotEmpty ? transport.segments.first.product : "Transport"} '
              '— ${transport.currency}${transport.price.toInt()}',
            ),
          ],
          if (hotel != null) ...[
            _buildSummaryRow(
              '🏨',
              '${hotel.name} — ${hotel.currency}${hotel.priceTotal.toInt()} total',
            ),
          ],
          if (flight == null && transport == null && hotel == null)
            const Text(
              '(no selections)',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AppTheme.textSecondary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasBothFlights(ForkWizardProvider provider) {
    final flights =
        provider.selectedFlights.values.where((f) => f != null).toList();
    return flights.length >= 2;
  }

  Future<void> _createTrip(
      BuildContext context, ForkWizardProvider provider) async {
    final token = context.read<AuthProvider>().token ?? '';
    final guide = provider.forkGuide!;

    // Map selections to flat trip structure
    final flights =
        provider.selectedFlights.values.whereType<FlightOffer>().toList();
    final buses =
        provider.selectedTransport.values.whereType<BusOffer>().toList();

    final outboundFlight = flights.isNotEmpty ? flights.first : null;
    final returnFlight = flights.length > 1 ? flights.last : null;
    final busJourney = buses.isNotEmpty ? buses.first : null;

    if (outboundFlight == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least an outbound flight'),
          ),
        );
      }
      return;
    }

    try {
      final apiService = ApiService();
      await apiService.saveTrip(
        token: token,
        name: guide.title,
        outboundFlight: outboundFlight,
        returnFlight: returnFlight,
        busOffer: busJourney,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trip created successfully!')),
        );
        // Navigate back to home
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create trip: $e')),
        );
      }
    }
  }
}
