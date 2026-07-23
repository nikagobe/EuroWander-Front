import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/template.dart';

class StepLegRecommendations extends StatefulWidget {
  final List<CreateTemplateLeg> legs;
  final ValueChanged<List<CreateTemplateLeg>> onLegsChanged;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const StepLegRecommendations({
    super.key,
    required this.legs,
    required this.onLegsChanged,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<StepLegRecommendations> createState() =>
      _StepLegRecommendationsState();
}

class _StepLegRecommendationsState extends State<StepLegRecommendations> {
  int _currentLegIndex = 0;
  final PageController _legPageController = PageController();

  // Per-leg controllers
  final Map<int, TextEditingController> _originIataControllers = {};
  final Map<int, TextEditingController> _destIataControllers = {};
  final Map<int, TextEditingController> _airlinesControllers = {};
  final Map<int, TextEditingController> _flightTipControllers = {};
  final Map<int, TextEditingController> _transportFromControllers = {};
  final Map<int, TextEditingController> _transportToControllers = {};
  final Map<int, TextEditingController> _transportProviderControllers = {};
  final Map<int, TextEditingController> _transportTipControllers = {};
  final Map<int, TextEditingController> _authorNotesControllers = {};
  final Map<int, String> _transportMode = {};
  final Map<int, String> _travelType = {};

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.legs.length; i++) {
      final leg = widget.legs[i];
      _authorNotesControllers[i] = TextEditingController(text: leg.authorNotes);

      if (leg.flightRecommendation != null) {
        _travelType[i] = 'flight';
        _originIataControllers[i] =
            TextEditingController(text: leg.flightRecommendation!.originIata);
        _destIataControllers[i] = TextEditingController(
            text: leg.flightRecommendation!.destinationIata);
        _airlinesControllers[i] = TextEditingController(
            text: leg.flightRecommendation!.preferredAirlines.join(', '));
        _flightTipControllers[i] =
            TextEditingController(text: leg.flightRecommendation!.tip);
      } else if (leg.transportRecommendation != null) {
        _travelType[i] = 'transport';
        _transportFromControllers[i] =
            TextEditingController(text: leg.transportRecommendation!.fromCity);
        _transportToControllers[i] =
            TextEditingController(text: leg.transportRecommendation!.toCity);
        _transportProviderControllers[i] = TextEditingController(
            text: leg.transportRecommendation!.preferredProviders.join(', '));
        _transportTipControllers[i] =
            TextEditingController(text: leg.transportRecommendation!.tip);
        _transportMode[i] = leg.transportRecommendation!.mode;
      } else {
        _travelType[i] = 'none';
      }

      // Initialize empty controllers for unused fields
      _originIataControllers[i] ??= TextEditingController();
      _destIataControllers[i] ??= TextEditingController();
      _airlinesControllers[i] ??= TextEditingController();
      _flightTipControllers[i] ??= TextEditingController();
      _transportFromControllers[i] ??= TextEditingController();
      _transportToControllers[i] ??= TextEditingController();
      _transportProviderControllers[i] ??= TextEditingController();
      _transportTipControllers[i] ??= TextEditingController();
    }
  }

  @override
  void dispose() {
    _legPageController.dispose();
    for (final c in _originIataControllers.values) {
      c.dispose();
    }
    for (final c in _destIataControllers.values) {
      c.dispose();
    }
    for (final c in _airlinesControllers.values) {
      c.dispose();
    }
    for (final c in _flightTipControllers.values) {
      c.dispose();
    }
    for (final c in _transportFromControllers.values) {
      c.dispose();
    }
    for (final c in _transportToControllers.values) {
      c.dispose();
    }
    for (final c in _transportProviderControllers.values) {
      c.dispose();
    }
    for (final c in _transportTipControllers.values) {
      c.dispose();
    }
    for (final c in _authorNotesControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _saveLegData(int index) {
    final type = _travelType[index] ?? 'none';
    final legs = List<CreateTemplateLeg>.from(widget.legs);
    final old = legs[index];

    FlightRecommendation? flightRec;
    TransportRecommendation? transportRec;

    if (type == 'flight') {
      final airlines = _airlinesControllers[index]!
          .text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      flightRec = FlightRecommendation(
        originIata: _originIataControllers[index]!.text.toUpperCase(),
        destinationIata: _destIataControllers[index]!.text.toUpperCase(),
        originCity: '',
        destinationCity: old.city,
        preferredAirlines: airlines,
        preferredFlightNumbers: [],
        preferredDepartureWindow: '',
        tip: _flightTipControllers[index]!.text,
      );
    } else if (type == 'transport') {
      final providers = _transportProviderControllers[index]!
          .text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      transportRec = TransportRecommendation(
        fromCity: _transportFromControllers[index]!.text,
        toCity: _transportToControllers[index]!.text,
        mode: _transportMode[index] ?? 'bus',
        preferredProviders: providers,
        currency: 'EUR',
        tip: _transportTipControllers[index]!.text,
      );
    }

    legs[index] = CreateTemplateLeg(
      order: old.order,
      city: old.city,
      country: old.country,
      days: old.days,
      flightRecommendation: flightRec,
      transportRecommendation: transportRec,
      hotelRecommendations: old.hotelRecommendations,
      playlistId: old.playlistId,
      restaurantIds: old.restaurantIds,
      authorNotes: _authorNotesControllers[index]!.text,
    );

    widget.onLegsChanged(legs);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.legs.isEmpty) {
      return Center(
        child: Text(
          'Add legs in the previous step first',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return Column(
      children: [
        // Leg tab bar
        Container(
          height: 44,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: widget.legs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final leg = widget.legs[index];
              final isActive = _currentLegIndex == index;
              return GestureDetector(
                onTap: () {
                  _saveLegData(_currentLegIndex);
                  setState(() => _currentLegIndex = index);
                  _legPageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isActive ? AppTheme.primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isActive
                          ? AppTheme.primaryColor
                          : Colors.grey.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    'Leg ${index + 1}: ${leg.city.isNotEmpty ? leg.city : "?"}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isActive ? Colors.white : AppTheme.textSecondary,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Leg content pages
        Expanded(
          child: PageView.builder(
            controller: _legPageController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.legs.length,
            itemBuilder: (context, index) => _buildLegContent(index),
          ),
        ),

        // Navigation
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
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
                  onPressed: () {
                    _saveLegData(_currentLegIndex);
                    widget.onNext();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Next →'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegContent(int index) {
    final leg = widget.legs[index];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Leg ${index + 1}: ${leg.city}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),

          // Getting there section
          _buildSectionTitle('GETTING THERE'),
          const SizedBox(height: 8),
          _buildTravelTypeSelector(index),
          const SizedBox(height: 12),

          if (_travelType[index] == 'flight') _buildFlightForm(index),
          if (_travelType[index] == 'transport') _buildTransportForm(index),

          const SizedBox(height: 24),

          // Author notes
          _buildSectionTitle('AUTHOR NOTES'),
          const SizedBox(height: 8),
          TextField(
            controller: _authorNotesControllers[index],
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Tips for travelers visiting ${leg.city}...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppTheme.primaryColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppTheme.textSecondary,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildTravelTypeSelector(int index) {
    final type = _travelType[index] ?? 'none';
    return Row(
      children: [
        _buildTypeChip('Flight', 'flight', type, index),
        const SizedBox(width: 8),
        _buildTypeChip('Bus/Train', 'transport', type, index),
        const SizedBox(width: 8),
        _buildTypeChip('None', 'none', type, index),
      ],
    );
  }

  Widget _buildTypeChip(
      String label, String value, String current, int index) {
    final isSelected = current == value;
    return GestureDetector(
      onTap: () {
        setState(() => _travelType[index] = value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildFlightForm(int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _originIataControllers[index],
                textCapitalization: TextCapitalization.characters,
                decoration: _inputDecoration('From (IATA)'),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('→'),
            ),
            Expanded(
              child: TextField(
                controller: _destIataControllers[index],
                textCapitalization: TextCapitalization.characters,
                decoration: _inputDecoration('To (IATA)'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _airlinesControllers[index],
          decoration: _inputDecoration('Preferred airlines (comma-separated)'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _flightTipControllers[index],
          decoration: _inputDecoration('💡 Tip for travelers'),
        ),
      ],
    );
  }

  Widget _buildTransportForm(int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mode selector
        Row(
          children: [
            _buildModeChip('Bus', 'bus', index),
            const SizedBox(width: 8),
            _buildModeChip('Train', 'train', index),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _transportFromControllers[index],
                decoration: _inputDecoration('From city'),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('→'),
            ),
            Expanded(
              child: TextField(
                controller: _transportToControllers[index],
                decoration: _inputDecoration('To city'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _transportProviderControllers[index],
          decoration: _inputDecoration('Preferred providers (comma-separated)'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _transportTipControllers[index],
          decoration: _inputDecoration('💡 Tip for travelers'),
        ),
      ],
    );
  }

  Widget _buildModeChip(String label, String value, int index) {
    final current = _transportMode[index] ?? 'bus';
    final isSelected = current == value;
    return GestureDetector(
      onTap: () => setState(() => _transportMode[index] = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.primaryColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}
