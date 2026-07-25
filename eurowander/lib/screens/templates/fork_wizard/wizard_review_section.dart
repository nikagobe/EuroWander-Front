import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/fork_wizard_provider.dart';

/// Final review section of the fork wizard.
/// Shows a summary of all selections and the create button.
class WizardReviewSection extends StatelessWidget {
  final String templateId;
  final VoidCallback onCreateTrip;

  const WizardReviewSection({
    super.key,
    required this.templateId,
    required this.onCreateTrip,
  });

  @override
  Widget build(BuildContext context) {
    final ew = context.ew;

    return Consumer<ForkWizardProvider>(
      builder: (context, provider, _) {
        final guide = provider.forkGuide;
        if (guide == null) {
          return const Center(child: Text('Complete the steps above first.'));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Outbound flight
            _buildSummaryRow(
              context,
              icon: Icons.flight_takeoff,
              iconColor: AppColors.brandPrimary,
              label: 'Outbound Flight',
              value: provider.outboundFlight != null
                  ? '${provider.outboundFlight!.airline} · €${provider.outboundFlight!.price.toStringAsFixed(0)}'
                  : 'Not selected',
              isSet: provider.outboundFlight != null,
            ),
            const SizedBox(height: 8),

            // Per-city summary
            ...guide.legs.map((leg) {
              final hotel = provider.selectedHotels[leg.order];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  children: [
                    _buildSummaryRow(
                      context,
                      icon: Icons.hotel,
                      iconColor: const Color(0xFFFF9800),
                      label: '🏨 ${leg.city} (${leg.days} nights)',
                      value: hotel != null
                          ? '${hotel.name} · €${hotel.priceTotal.toStringAsFixed(0)}'
                          : 'No hotel selected',
                      isSet: hotel != null,
                    ),
                    // Bus to next city
                    if (leg.order < guide.legs.length) ...[
                      const SizedBox(height: 8),
                      Builder(builder: (context) {
                        final busIndex = leg.order - guide.legs.first.order;
                        final bus = provider.selectedBuses[busIndex];
                        final nextLegIndex = guide.legs.indexWhere((l) => l.order == leg.order) + 1;
                        if (nextLegIndex >= guide.legs.length) return const SizedBox.shrink();
                        final nextLeg = guide.legs[nextLegIndex];
                        return _buildSummaryRow(
                          context,
                          icon: Icons.directions_bus,
                          iconColor: const Color(0xFF4CAF50),
                          label: '🚌 ${leg.city} → ${nextLeg.city}',
                          value: bus != null
                              ? '€${(bus.totalPrice ?? bus.price).toStringAsFixed(0)} · ${bus.duration}'
                              : 'Not selected',
                          isSet: bus != null,
                        );
                      }),
                    ],
                  ],
                ),
              );
            }),

            // Return flight
            _buildSummaryRow(
              context,
              icon: Icons.flight_land,
              iconColor: AppColors.brandSecondary,
              label: 'Return Flight',
              value: provider.returnFlight != null
                  ? '${provider.returnFlight!.airline} · €${provider.returnFlight!.price.toStringAsFixed(0)}'
                  : 'Not selected',
              isSet: provider.returnFlight != null,
            ),

            const SizedBox(height: 20),

            // Cost breakdown
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ew.cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.brandPrimary.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  _buildCostRow('Flights', '€${provider.flightsTotal.toStringAsFixed(0)}'),
                  const SizedBox(height: 6),
                  _buildCostRow('Hotels', '€${provider.hotelsTotal.toStringAsFixed(0)}'),
                  const SizedBox(height: 6),
                  _buildCostRow('Transport', '€${provider.busesTotal.toStringAsFixed(0)}'),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      Text(
                        '€${provider.grandTotal.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.brandPrimary),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Create button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: onCreateTrip,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text(
                  '🚀  CREATE MY TRIP',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryRow(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required bool isSet,
  }) {
    final ew = context.ew;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ew.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSet ? ew.textPrimary : ew.textSecondary,
                    fontStyle: isSet ? FontStyle.normal : FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          if (isSet)
            const Icon(Icons.check_circle, size: 18, color: Color(0xFF4CAF50))
          else
            Icon(Icons.radio_button_unchecked, size: 18, color: ew.textSecondary),
        ],
      ),
    );
  }

  Widget _buildCostRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: AppColors.lightTextSecondary)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
