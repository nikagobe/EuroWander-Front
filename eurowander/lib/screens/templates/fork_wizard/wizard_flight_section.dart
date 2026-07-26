import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/city.dart';
import '../../../models/flight.dart';
import '../../../services/api_service.dart';
import '../../plan/city_selection_screen.dart';

/// Flight search section for the fork wizard.
/// Shows a compact summary and navigates to the classic CitySelectionScreen
/// in pick mode. The selected flight is returned to the wizard.
class WizardFlightSection extends StatefulWidget {
  final String title;
  final String destinationCityName;
  final String destinationCountry;
  final DateTime date;
  final bool isReturn;
  final City? prefillOrigin;
  final FlightOffer? selectedFlight;
  final ValueChanged<FlightOffer?> onFlightSelected;
  final ValueChanged<City>? onOriginResolved;

  const WizardFlightSection({
    super.key,
    required this.title,
    required this.destinationCityName,
    required this.destinationCountry,
    required this.date,
    this.isReturn = false,
    this.prefillOrigin,
    this.selectedFlight,
    required this.onFlightSelected,
    this.onOriginResolved,
  });

  @override
  State<WizardFlightSection> createState() => _WizardFlightSectionState();
}

class _WizardFlightSectionState extends State<WizardFlightSection> {
  final ApiService _apiService = ApiService();
  final TextEditingController _originController = TextEditingController();
  final FocusNode _originFocus = FocusNode();

  List<City> _originSuggestions = [];
  City? _selectedOrigin;
  City? _resolvedDestination;
  bool _isLoadingOrigin = false;
  bool _isResolvingDest = false;

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    if (widget.prefillOrigin != null) {
      _selectedOrigin = widget.prefillOrigin;
      _originController.text = '${widget.prefillOrigin!.name}, ${widget.prefillOrigin!.country}';
    }
    _resolveDestinationCity();
  }

  @override
  void didUpdateWidget(WizardFlightSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.prefillOrigin != widget.prefillOrigin && widget.prefillOrigin != null) {
      _selectedOrigin = widget.prefillOrigin;
      _originController.text = '${widget.prefillOrigin!.name}, ${widget.prefillOrigin!.country}';
    }
  }

  @override
  void dispose() {
    _originController.dispose();
    _originFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _resolveDestinationCity() async {
    setState(() => _isResolvingDest = true);
    try {
      final results = await _apiService.searchCities(widget.destinationCityName);
      if (results.isNotEmpty && mounted) {
        final match = results.firstWhere(
          (c) => c.country.toLowerCase() == widget.destinationCountry.toLowerCase(),
          orElse: () => results.first,
        );
        setState(() {
          _resolvedDestination = match;
          _isResolvingDest = false;
        });
      } else {
        setState(() => _isResolvingDest = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isResolvingDest = false);
    }
  }

  void _onOriginChanged(String query) {
    _selectedOrigin = null;
    _debounce?.cancel();
    if (query.isEmpty) {
      setState(() => _originSuggestions = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      setState(() => _isLoadingOrigin = true);
      final results = await _apiService.searchCities(query);
      if (mounted) {
        setState(() {
          _originSuggestions = results;
          _isLoadingOrigin = false;
        });
      }
    });
  }

  void _selectOrigin(City city) {
    setState(() {
      _selectedOrigin = city;
      _originController.text = '${city.name}, ${city.country}';
      _originSuggestions = [];
    });
    _originFocus.unfocus();
    widget.onOriginResolved?.call(city);
  }

  Future<void> _openFlightSearch() async {
    final origin = widget.isReturn ? _resolvedDestination : _selectedOrigin;
    final destination = widget.isReturn ? _selectedOrigin : _resolvedDestination;

    if (origin == null || destination == null) return;

    final result = await Navigator.of(context).push<FlightOffer>(
      MaterialPageRoute(
        builder: (_) => CitySelectionScreen(
          prefillFrom: origin,
          prefillTo: destination,
          prefillDate: widget.date,
          pickMode: true,
        ),
      ),
    );

    if (result != null && mounted) {
      widget.onFlightSelected(result);
    }
  }

  bool get _canSearch {
    if (_isResolvingDest || _resolvedDestination == null) return false;
    return _selectedOrigin != null;
  }

  @override
  Widget build(BuildContext context) {
    final ew = context.ew;
    final theme = Theme.of(context);

    // If a flight is already selected, show compact summary
    if (widget.selectedFlight != null) {
      return _buildSelectedCard(widget.selectedFlight!);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Origin city input
        Text(
          widget.isReturn ? 'Flying back to:' : 'Flying from:',
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _originController,
          focusNode: _originFocus,
          onChanged: _onOriginChanged,
          decoration: InputDecoration(
            hintText: 'Search your city...',
            prefixIcon: const Icon(Icons.flight_takeoff, size: 20),
            suffixIcon: _isLoadingOrigin
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brandPrimary)),
                  )
                : null,
            filled: true,
            fillColor: ew.cardColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.withOpacity(0.2))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.withOpacity(0.2))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.brandPrimary, width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),

        // Suggestions dropdown
        if (_originSuggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: ew.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(
              children: _originSuggestions.map((city) {
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.location_city, size: 18, color: AppColors.brandPrimary),
                  title: Text('${city.name}, ${city.country}', style: const TextStyle(fontSize: 14)),
                  subtitle: city.description.isNotEmpty ? Text(city.description, style: const TextStyle(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis) : null,
                  onTap: () => _selectOrigin(city),
                );
              }).toList(),
            ),
          ),

        const SizedBox(height: 12),

        // Route preview
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.brandPrimary.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.brandPrimary.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              Icon(widget.isReturn ? Icons.flight_land : Icons.flight_takeoff, size: 20, color: AppColors.brandPrimary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isReturn
                          ? '${widget.destinationCityName} → ${_selectedOrigin?.name ?? '...'}'
                          : '${_selectedOrigin?.name ?? '...'} → ${widget.destinationCityName}',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ew.textPrimary),
                    ),
                    Text(
                      '${widget.date.day}/${widget.date.month}/${widget.date.year}',
                      style: TextStyle(fontSize: 12, color: ew.textSecondary),
                    ),
                  ],
                ),
              ),
              if (_isResolvingDest)
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brandPrimary))
              else if (_resolvedDestination != null)
                const Icon(Icons.check_circle, size: 18, color: Color(0xFF4CAF50)),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Search button - navigates to classic flight search page
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _canSearch ? _openFlightSearch : null,
            icon: const Icon(Icons.search, size: 20),
            label: const Text('Search Flights', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandPrimary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.withOpacity(0.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedCard(FlightOffer flight) {
    final depTime = _formatTime(flight.departureTime);
    final arrTime = _formatTime(flight.arrivalTime);
    final durationHrs = flight.totalDuration ~/ 60;
    final durationMins = flight.totalDuration % 60;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  flight.airlineLogo, width: 32, height: 32, fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Container(width: 32, height: 32, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.flight, size: 16)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(flight.airline, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                    Text('$depTime → $arrTime · ${durationHrs}h ${durationMins}m', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.lightTextSecondary)),
                  ],
                ),
              ),
              Text('€${flight.price.toStringAsFixed(0)}', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.brandPrimary)),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openFlightSearch,
              icon: const Icon(Icons.swap_horiz, size: 18),
              label: const Text('Change Flight'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.brandPrimary,
                side: const BorderSide(color: AppColors.brandPrimary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String dateTimeStr) {
    final parts = dateTimeStr.split(' ');
    if (parts.length >= 2) return parts[1].substring(0, 5);
    return dateTimeStr;
  }
}
