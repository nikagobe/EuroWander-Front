import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/template.dart';

class StepDefineRoute extends StatefulWidget {
  final List<CreateTemplateLeg> legs;
  final ValueChanged<List<CreateTemplateLeg>> onLegsChanged;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const StepDefineRoute({
    super.key,
    required this.legs,
    required this.onLegsChanged,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<StepDefineRoute> createState() => _StepDefineRouteState();
}

class _StepDefineRouteState extends State<StepDefineRoute> {
  void _addLeg() {
    final newLeg = CreateTemplateLeg(
      order: widget.legs.length + 1,
      city: '',
      country: '',
      days: 1,
      restaurantIds: [],
      authorNotes: '',
    );
    widget.onLegsChanged([...widget.legs, newLeg]);
  }

  void _removeLeg(int index) {
    final updated = List<CreateTemplateLeg>.from(widget.legs);
    updated.removeAt(index);
    // Re-order
    for (int i = 0; i < updated.length; i++) {
      updated[i] = CreateTemplateLeg(
        order: i + 1,
        city: updated[i].city,
        country: updated[i].country,
        days: updated[i].days,
        flightRecommendation: updated[i].flightRecommendation,
        transportRecommendation: updated[i].transportRecommendation,
        hotelRecommendations: updated[i].hotelRecommendations,
        playlistId: updated[i].playlistId,
        restaurantIds: updated[i].restaurantIds,
        authorNotes: updated[i].authorNotes,
      );
    }
    widget.onLegsChanged(updated);
  }

  void _updateLeg(int index, {String? city, String? country, int? days}) {
    final updated = List<CreateTemplateLeg>.from(widget.legs);
    final old = updated[index];
    updated[index] = CreateTemplateLeg(
      order: old.order,
      city: city ?? old.city,
      country: country ?? old.country,
      days: days ?? old.days,
      flightRecommendation: old.flightRecommendation,
      transportRecommendation: old.transportRecommendation,
      hotelRecommendations: old.hotelRecommendations,
      playlistId: old.playlistId,
      restaurantIds: old.restaurantIds,
      authorNotes: old.authorNotes,
    );
    widget.onLegsChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Define your route',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'Add the cities you\'ll visit in order',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),

          // Leg cards
          ...widget.legs.asMap().entries.map((entry) {
            final index = entry.key;
            final leg = entry.value;
            return _buildLegCard(index, leg);
          }),

          // Add leg button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _addLeg,
              icon: const Icon(Icons.add),
              label: const Text('Add another leg'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                side: BorderSide(
                  color: AppTheme.primaryColor.withOpacity(0.5),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Navigation buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onBack,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                    side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('← Back'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed:
                      widget.legs.isNotEmpty && widget.legs.first.city.isNotEmpty
                          ? widget.onNext
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                  ),
                  child: const Text('Next →'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegCard(int index, CreateTemplateLeg leg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Leg ${index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              if (widget.legs.length > 1)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => _removeLeg(index),
                  color: Colors.red.withOpacity(0.7),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: _inputDecoration('City'),
            controller: TextEditingController(text: leg.city)
              ..selection = TextSelection.collapsed(offset: leg.city.length),
            onChanged: (v) => _updateLeg(index, city: v),
          ),
          const SizedBox(height: 10),
          TextField(
            decoration: _inputDecoration('Country'),
            controller: TextEditingController(text: leg.country)
              ..selection = TextSelection.collapsed(offset: leg.country.length),
            onChanged: (v) => _updateLeg(index, country: v),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text('Days: ', style: TextStyle(fontSize: 14)),
              SizedBox(
                width: 60,
                child: TextField(
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: _inputDecoration(''),
                  controller: TextEditingController(text: leg.days.toString()),
                  onChanged: (v) {
                    final days = int.tryParse(v);
                    if (days != null && days > 0) {
                      _updateLeg(index, days: days);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppTheme.backgroundColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }
}
