import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_theme.dart';
import '../../models/city.dart';
import '../../models/flight.dart';
import '../../services/api_service.dart';
import 'trip_confirmation_screen.dart';

class RegionalSearchScreen extends StatefulWidget {
  final String arrivalCountry;
  final City defaultDestination;
  final FlightOffer firstFlight;
  final City origin;
  final City destination;
  final DateTime outboundDate;

  const RegionalSearchScreen({
    super.key,
    required this.arrivalCountry,
    required this.defaultDestination,
    required this.firstFlight,
    required this.origin,
    required this.destination,
    required this.outboundDate,
  });

  @override
  State<RegionalSearchScreen> createState() => _RegionalSearchScreenState();
}

class _RegionalSearchScreenState extends State<RegionalSearchScreen> {
  final ApiService _apiService = ApiService();
  final MapController _mapController = MapController();
  final TextEditingController _destController = TextEditingController();
  final FocusNode _destFocus = FocusNode();

  List<City> _suggestions = [];
  City? _selectedDest;
  bool _isLoadingSuggestions = false;
  DateTime? _returnDate;
  Timer? _debounce;

  // Flight results
  List<FlightOffer> _flights = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  String? _error;
  FlightOffer? _selectedFlight;

  @override
  void initState() {
    super.initState();
    _selectedDest = widget.defaultDestination;
    _destController.text = '${widget.defaultDestination.name}, ${widget.defaultDestination.country}';
  }

  @override
  void dispose() {
    _destController.dispose();
    _destFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onDestChanged(String query) {
    _selectedDest = null;
    _debounce?.cancel();
    if (query.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      setState(() => _isLoadingSuggestions = true);
      final results = await _apiService.searchCities(query);
      if (mounted) {
        setState(() {
          _suggestions = results;
          _isLoadingSuggestions = false;
        });
      }
    });
  }

  void _selectDest(City city) {
    setState(() {
      _selectedDest = city;
      _destController.text = '${city.name}, ${city.country}';
      _suggestions = [];
    });
    _destFocus.unfocus();
  }

  Future<void> _pickReturnDate() async {
    final now = DateTime.now();
    final initial = _returnDate ?? widget.outboundDate.add(const Duration(days: 3));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: widget.outboundDate,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _returnDate = picked);
    }
  }

  Future<void> _searchFlights() async {
    if (_selectedDest == null || _returnDate == null) return;

    setState(() {
      _isSearching = true;
      _hasSearched = true;
      _error = null;
    });

    try {
      final dateStr =
          '${_returnDate!.year}-${_returnDate!.month.toString().padLeft(2, '0')}-${_returnDate!.day.toString().padLeft(2, '0')}';
      final results = await _apiService.searchRegionalFlights(
        originCountry: widget.arrivalCountry,
        destinationId: _selectedDest!.freebaseId,
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

  void _onFlightSelected(FlightOffer flight) {
    setState(() => _selectedFlight = flight);
    final leg = flight.legs.first;
    if (leg.departureLat != null && leg.arrivalLat != null) {
      final centerLat = (leg.departureLat! + leg.arrivalLat!) / 2;
      final centerLng = (leg.departureLng! + leg.arrivalLng!) / 2;
      final origin = LatLng(leg.departureLat!, leg.departureLng!);
      final dest = LatLng(leg.arrivalLat!, leg.arrivalLng!);
      _mapController.move(LatLng(centerLat, centerLng), _calculateZoom(origin, dest));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 800;

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
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: isWide ? _buildWideLayout() : _buildNarrowLayout(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
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
          Text(
            'Cheap Return Flights',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: _buildContent(),
        ),
        if (_hasSearched && _flights.isNotEmpty)
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.only(right: 24, top: 8, bottom: 24),
              child: _buildMap(),
            ),
          ),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        if (!_hasSearched) ...[
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildSearchForm(),
            ),
          ),
        ] else ...[
          Expanded(child: _buildResults()),
          if (_selectedFlight != null) _buildContinueButton(),
        ],
      ],
    );
  }

  Widget _buildSearchForm() {
    final dateFormat = DateFormat('EEE, MMM d');
    final isReady = _selectedDest != null && _returnDate != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          'Find cheap returns\nfrom ${widget.arrivalCountry}',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'We\'ll search all airports in ${widget.arrivalCountry} for the best prices',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 32),
        // Departure country (read-only)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.flight_takeoff_rounded,
                  size: 20,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'From (country)',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.arrivalCountry,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.lock_outline_rounded, size: 16, color: Colors.grey.shade400),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Destination city (editable)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _selectedDest != null
                          ? AppTheme.secondaryColor.withOpacity(0.1)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.flight_land_rounded,
                      size: 20,
                      color: _selectedDest != null
                          ? AppTheme.secondaryColor
                          : AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'To (city)',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _destController,
                          focusNode: _destFocus,
                          onChanged: _onDestChanged,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Arrival city',
                            hintStyle: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey.shade400,
                            ),
                            border: InputBorder.none,
                            isDense: false,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isLoadingSuggestions)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                ],
              ),
              if (_suggestions.isNotEmpty) _buildSuggestionsList(),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Date picker
        GestureDetector(
          onTap: _pickReturnDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _returnDate != null
                        ? AppTheme.primaryColor.withOpacity(0.1)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.calendar_today_rounded,
                    size: 20,
                    color: _returnDate != null
                        ? AppTheme.primaryColor
                        : AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Return date',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _returnDate != null
                            ? dateFormat.format(_returnDate!)
                            : 'Select date',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: _returnDate != null
                              ? AppTheme.textPrimary
                              : Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        // Search button
        GestureDetector(
          onTap: isReady ? _searchFlights : null,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              gradient: isReady
                  ? const LinearGradient(
                      colors: [AppTheme.primaryColor, Color(0xFF8B5CF6), AppTheme.secondaryColor],
                    )
                  : null,
              color: isReady ? null : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(18),
              boxShadow: isReady
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_rounded,
                  color: isReady ? Colors.white : Colors.grey.shade500,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  'Search Cheap Flights',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isReady ? Colors.white : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSuggestionsList() {
    return Container(
      margin: const EdgeInsets.only(top: 8, left: 50),
      constraints: const BoxConstraints(maxHeight: 180),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          indent: 12,
          endIndent: 12,
          color: Colors.grey.shade200,
        ),
        itemBuilder: (context, index) {
          final city = _suggestions[index];
          return InkWell(
            onTap: () => _selectDest(city),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: AppTheme.primaryColor.withOpacity(0.7),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          city.name,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          '${city.country} · ${city.description}',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResults() {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            style: GoogleFonts.poppins(color: Colors.red.shade600, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (_flights.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flight_rounded, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'No flights found',
              style: GoogleFonts.poppins(fontSize: 16, color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: _flights.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildFlightCard(_flights[index]),
    );
  }

  Widget _buildFlightCard(FlightOffer flight) {
    final leg = flight.legs.first;
    final depTime = _formatTime(leg.departureTime);
    final arrTime = _formatTime(leg.arrivalTime);
    final durationHrs = flight.totalDuration ~/ 60;
    final durationMins = flight.totalDuration % 60;
    final durationStr = '${durationHrs}h ${durationMins}m';
    final isSelected = _selectedFlight == flight;

    return GestureDetector(
      onTap: () => _onFlightSelected(flight),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppTheme.primaryColor.withOpacity(0.15)
                  : AppTheme.primaryColor.withOpacity(0.05),
              blurRadius: isSelected ? 20 : 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    leg.airlineLogo.isNotEmpty ? leg.airlineLogo : flight.airlineLogo,
                    width: 36,
                    height: 36,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.flight, size: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      leg.airline,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      '${leg.departureAirport} → ${leg.arrivalAirport}',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '€${flight.price.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  depTime,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      children: [
                        Text(
                          durationStr,
                          style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          height: 2,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          flight.stops == 0 ? 'Direct' : '${flight.stops} stop(s)',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: flight.stops == 0 ? Colors.green.shade600 : Colors.orange.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Text(
                  arrTime,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
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
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, size: 14, color: Colors.white),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    if (_selectedFlight == null) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: FlutterMap(
          mapController: _mapController,
          options: const MapOptions(
            initialCenter: LatLng(48.0, 14.0),
            initialZoom: 4,
            interactionOptions: InteractionOptions(flags: InteractiveFlag.all),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.eurowander.app',
            ),
          ],
        ),
      );
    }

    final leg = _selectedFlight!.legs.first;
    if (leg.departureLat == null || leg.arrivalLat == null) {
      return const SizedBox.shrink();
    }

    final origin = LatLng(leg.departureLat!, leg.departureLng!);
    final dest = LatLng(leg.arrivalLat!, leg.arrivalLng!);
    final arcPoints = _generateArc(origin, dest);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: LatLng(
            (origin.latitude + dest.latitude) / 2,
            (origin.longitude + dest.longitude) / 2,
          ),
          initialZoom: _calculateZoom(origin, dest),
          interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.eurowander.app',
          ),
          PolylineLayer(
            polylines: <Polyline<Object>>[
              Polyline(
                points: arcPoints,
                strokeWidth: 3,
                color: AppTheme.primaryColor,
                pattern: const StrokePattern.dotted(),
              ),
            ],
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: origin,
                width: 28,
                height: 28,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 6),
                    ],
                  ),
                ),
              ),
              Marker(
                point: dest,
                width: 28,
                height: 28,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(color: AppTheme.secondaryColor.withOpacity(0.3), blurRadius: 6),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TripConfirmationScreen(
                origin: widget.origin,
                destination: widget.destination,
                departureDate: widget.outboundDate,
                selectedFlight: widget.firstFlight,
              ),
            ),
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryColor, Color(0xFF8B5CF6), AppTheme.secondaryColor],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Continue',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  List<LatLng> _generateArc(LatLng start, LatLng end, {int segments = 30}) {
    final points = <LatLng>[];
    for (int i = 0; i <= segments; i++) {
      final t = i / segments;
      final lat = start.latitude + (end.latitude - start.latitude) * t;
      final lng = start.longitude + (end.longitude - start.longitude) * t;
      final offset = sin(t * pi) * 2.0;
      final dx = end.longitude - start.longitude;
      final dy = end.latitude - start.latitude;
      final len = sqrt(dx * dx + dy * dy);
      if (len == 0) continue;
      final nx = -dy / len;
      final ny = dx / len;
      points.add(LatLng(lat + nx * offset, lng + ny * offset));
    }
    return points;
  }

  double _calculateZoom(LatLng a, LatLng b) {
    final latDiff = (a.latitude - b.latitude).abs();
    final lngDiff = (a.longitude - b.longitude).abs();
    final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;
    if (maxDiff > 40) return 3;
    if (maxDiff > 20) return 4;
    if (maxDiff > 10) return 5;
    if (maxDiff > 5) return 5.5;
    return 6;
  }

  String _formatTime(String dateTimeStr) {
    final parts = dateTimeStr.split(' ');
    if (parts.length >= 2) {
      return parts[1].substring(0, 5);
    }
    return dateTimeStr;
  }
}
