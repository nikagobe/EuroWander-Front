import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/city.dart';
import '../../../models/flight.dart';
import '../../../services/api_service.dart';

/// Embedded flight search section for the fork wizard.
/// Pre-fills destination/date from the template and lets the user search.
class WizardFlightSection extends StatefulWidget {
  final String title;
  final String destinationCityName;
  final String destinationCountry;
  final DateTime date;
  final bool isReturn;
  final City? prefillOrigin;
  final FlightOffer? selectedFlight;
  final ValueChanged<FlightOffer?> onFlightSelected;

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

  List<FlightOffer> _flights = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  String? _error;
  FlightOffer? _localSelected;

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _localSelected = widget.selectedFlight;
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
        // Try to find an exact match by country
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
  }

  Future<void> _searchFlights() async {
    final origin = widget.isReturn ? _resolvedDestination : _selectedOrigin;
    final destination = widget.isReturn ? _selectedOrigin : _resolvedDestination;

    if (origin == null || destination == null) return;

    setState(() {
      _isSearching = true;
      _hasSearched = true;
      _error = null;
    });

    try {
      final dateStr =
          '${widget.date.year}-${widget.date.month.toString().padLeft(2, '0')}-${widget.date.day.toString().padLeft(2, '0')}';
      final results = await _apiService.searchFlights(
        originId: origin.freebaseId,
        destinationId: destination.freebaseId,
        outboundDate: dateStr,
      );
      if (mounted) {
        setState(() {
          _flights = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to search flights: $e';
          _isSearching = false;
        });
      }
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
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.brandPrimary, width: 2),
            ),
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

        // Destination (pre-filled, non-editable)
        Text(
          widget.isReturn ? 'From:' : 'To:',
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.brandPrimary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.brandPrimary.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.flight_land, size: 20, color: AppColors.brandPrimary),
              const SizedBox(width: 12),
              Text(
                '${widget.destinationCityName}, ${widget.destinationCountry}',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: ew.textPrimary),
              ),
              if (_isResolvingDest) ...[
                const Spacer(),
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brandPrimary)),
              ] else if (_resolvedDestination != null) ...[
                const Spacer(),
                const Icon(Icons.check_circle, size: 18, color: Color(0xFF4CAF50)),
              ],
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Date (pre-filled)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: ew.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, size: 18, color: AppColors.brandPrimary),
              const SizedBox(width: 12),
              Text(
                '${widget.date.day}/${widget.date.month}/${widget.date.year}',
                style: TextStyle(fontSize: 14, color: ew.textPrimary),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Search button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _canSearch ? _searchFlights : null,
            icon: const Icon(Icons.search, size: 20),
            label: Text(_isSearching ? 'Searching...' : 'Search Flights'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandPrimary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.withOpacity(0.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),

        // Error
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
        ],

        // Results
        if (_isSearching)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator(color: AppColors.brandPrimary)),
          )
        else if (_hasSearched && _flights.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text('No flights found for this route.', style: TextStyle(color: ew.textSecondary)),
            ),
          )
        else if (_flights.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            '${_flights.length} flights found',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ew.textSecondary),
          ),
          const SizedBox(height: 8),
          ..._flights.map((flight) => _buildFlightCard(flight)),
        ],

        // Selected flight summary
        if (_localSelected != null && !_flights.contains(_localSelected)) ...[
          const SizedBox(height: 12),
          _buildSelectedSummary(),
        ],
      ],
    );
  }

  Widget _buildSelectedSummary() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${_localSelected!.airline} · €${_localSelected!.price.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlightCard(FlightOffer flight) {
    final depTime = _formatTime(flight.departureTime);
    final arrTime = _formatTime(flight.arrivalTime);
    final durationHrs = flight.totalDuration ~/ 60;
    final durationMins = flight.totalDuration % 60;
    final durationStr = '${durationHrs}h ${durationMins}m';
    final isSelected = _localSelected == flight;

    return GestureDetector(
      onTap: () {
        setState(() => _localSelected = flight);
        widget.onFlightSelected(flight);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.brandPrimary : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.brandPrimary.withOpacity(0.12)
                  : Colors.black.withOpacity(0.04),
              blurRadius: isSelected ? 16 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            // Airline + price
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    flight.airlineLogo,
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.flight, size: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(flight.airline, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                      if (flight.legs.isNotEmpty)
                        Text(flight.legs.first.flightNumber, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.lightTextSecondary)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.brandPrimary, AppColors.brandSecondary]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '€${flight.price.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Time row
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(depTime, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(flight.departureAirportId, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.lightTextSecondary)),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      children: [
                        Text(durationStr, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.lightTextSecondary)),
                        const SizedBox(height: 4),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(height: 2, decoration: BoxDecoration(color: AppColors.brandPrimary.withOpacity(0.2), borderRadius: BorderRadius.circular(1))),
                            Icon(Icons.flight_rounded, size: 14, color: AppColors.brandPrimary.withOpacity(0.6)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        flight.stops == 0
                            ? Text('Direct', style: GoogleFonts.poppins(fontSize: 11, color: Colors.green.shade600, fontWeight: FontWeight.w500))
                            : Text('${flight.stops} stop(s)', style: GoogleFonts.poppins(fontSize: 11, color: Colors.orange.shade700)),
                      ],
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(arrTime, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(flight.arrivalAirportId, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.lightTextSecondary)),
                  ],
                ),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: AppColors.brandPrimary, shape: BoxShape.circle),
                    child: const Icon(Icons.check, size: 14, color: Colors.white),
                  ),
                  const SizedBox(width: 6),
                  const Text('Selected', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.brandPrimary)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(String dateTimeStr) {
    final parts = dateTimeStr.split(' ');
    if (parts.length >= 2) return parts[1].substring(0, 5);
    return dateTimeStr;
  }
}
