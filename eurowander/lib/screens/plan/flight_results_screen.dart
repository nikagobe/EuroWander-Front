import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_theme.dart';
import '../../models/city.dart';
import '../../models/flight.dart';
import '../../services/api_service.dart';
import 'trip_confirmation_screen.dart';
import 'return_flight_options_screen.dart';

class FlightResultsScreen extends StatefulWidget {
  final City origin;
  final City destination;
  final DateTime departureDate;
  final bool isReturn;
  final FlightOffer? firstFlight;

  const FlightResultsScreen({
    super.key,
    required this.origin,
    required this.destination,
    required this.departureDate,
    this.isReturn = false,
    this.firstFlight,
  });

  @override
  State<FlightResultsScreen> createState() => _FlightResultsScreenState();
}

class _FlightResultsScreenState extends State<FlightResultsScreen> {
  final ApiService _apiService = ApiService();
  final MapController _mapController = MapController();
  List<FlightOffer> _flights = [];
  bool _isLoading = true;
  String? _error;
  FlightOffer? _selectedFlight;

  @override
  void initState() {
    super.initState();
    _searchFlights();
  }

  Future<void> _searchFlights() async {
    try {
      final dateStr =
          '${widget.departureDate.year}-${widget.departureDate.month.toString().padLeft(2, '0')}-${widget.departureDate.day.toString().padLeft(2, '0')}';
      final results = await _apiService.searchFlights(
        originId: widget.origin.freebaseId,
        destinationId: widget.destination.freebaseId,
        outboundDate: dateStr,
      );
      if (mounted) {
        setState(() {
          _flights = results;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('[FlightResults] Error: $e');
      debugPrint('[FlightResults] StackTrace: $stackTrace');
      if (mounted) {
        setState(() {
          _error = 'Failed to load flights: $e';
          _isLoading = false;
        });
      }
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildBackButton(context),
                    const SizedBox(width: 16),
                    Text(
                      'Available Flights',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: isWide
                    ? _buildWideLayout()
                    : _buildNarrowLayout(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _hasMapCoordinates {
    if (_selectedFlight != null) {
      final leg = _selectedFlight!.legs.first;
      return leg.departureLat != null && leg.arrivalLat != null;
    }
    return widget.origin.coordinates != null && widget.destination.coordinates != null;
  }

  (LatLng origin, LatLng dest) get _mapPoints {
    if (_selectedFlight != null) {
      final leg = _selectedFlight!.legs.first;
      if (leg.departureLat != null && leg.arrivalLat != null) {
        return (
          LatLng(leg.departureLat!, leg.departureLng!),
          LatLng(leg.arrivalLat!, leg.arrivalLng!),
        );
      }
    }
    final o = widget.origin.coordinates!;
    final d = widget.destination.coordinates!;
    return (LatLng(o.$1, o.$2), LatLng(d.$1, d.$2));
  }

  void _onFlightSelected(FlightOffer flight) {
    setState(() {
      _selectedFlight = flight;
    });
    if (_hasMapCoordinates) {
      final (origin, dest) = _mapPoints;
      final centerLat = (origin.latitude + dest.latitude) / 2;
      final centerLng = (origin.longitude + dest.longitude) / 2;
      _mapController.move(
        LatLng(centerLat, centerLng),
        _calculateZoom(origin, dest),
      );
    }
  }

  Widget _buildRouteMap() {
    final (originLatLng, destLatLng) = _mapPoints;
    final centerLat = (originLatLng.latitude + destLatLng.latitude) / 2;
    final centerLng = (originLatLng.longitude + destLatLng.longitude) / 2;
    final arcPoints = _generateArc(originLatLng, destLatLng);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
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
            initialCenter: LatLng(centerLat, centerLng),
            initialZoom: _calculateZoom(originLatLng, destLatLng),
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
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
                  point: originLatLng,
                  width: 24,
                  height: 24,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
                Marker(
                  point: destLatLng,
                  width: 24,
                  height: 24,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.secondaryColor.withOpacity(0.3),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
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
      // Add a curve offset perpendicular to the line
      final offset = sin(t * pi) * 2.0; // arc height in degrees
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
    if (maxDiff > 5) return 6;
    return 7;
  }

  Widget _buildBackButton(BuildContext context) {
    return GestureDetector(
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
    );
  }

  Widget _buildWideLayout() {
    return Row(
      children: [
        // Left side: route header + flight list
        Expanded(
          flex: 5,
          child: Column(
            children: [
              _buildRouteHeader(),
              const SizedBox(height: 16),
              Expanded(child: _buildBody()),
              if (_selectedFlight != null) _buildContinueButton(),
            ],
          ),
        ),
        // Right side: map
        if (_hasMapCoordinates)
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.only(right: 24, top: 8, bottom: 24),
              child: _buildFullMap(),
            ),
          ),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          children: [
            _buildRouteHeader(),
            if (_hasMapCoordinates) ...[              const SizedBox(height: 16),
              _buildRouteMap(),
            ],
            const SizedBox(height: 16),
            Expanded(child: _buildBody()),
            if (_selectedFlight != null) _buildContinueButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildFullMap() {
    final (originLatLng, destLatLng) = _mapPoints;
    final centerLat = (originLatLng.latitude + destLatLng.latitude) / 2;
    final centerLng = (originLatLng.longitude + destLatLng.longitude) / 2;
    final arcPoints = _generateArc(originLatLng, destLatLng);

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
          initialCenter: LatLng(centerLat, centerLng),
          initialZoom: _calculateZoom(originLatLng, destLatLng),
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all,
          ),
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
                point: originLatLng,
                width: 28,
                height: 28,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
              Marker(
                point: destLatLng,
                width: 28,
                height: 28,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.secondaryColor.withOpacity(0.3),
                        blurRadius: 6,
                      ),
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

  Widget _buildRouteHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.origin.name,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    widget.origin.country,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: AppTheme.primaryColor,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    widget.destination.name,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    widget.destination.country,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (_flights.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flight_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No flights found for this route',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
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

  Widget _buildContinueButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: GestureDetector(
        onTap: () {
          if (widget.isReturn) {
            // Return flight selected - go to confirmation
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TripConfirmationScreen(
                  origin: widget.origin,
                  destination: widget.destination,
                  departureDate: widget.departureDate,
                  selectedFlight: _selectedFlight!,
                ),
              ),
            );
          } else {
            // Outbound flight selected - choose return
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ReturnFlightOptionsScreen(
                  origin: widget.origin,
                  destination: widget.destination,
                  departureDate: widget.departureDate,
                  firstFlight: _selectedFlight!,
                ),
              ),
            );
          }
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
              const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
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
          // Airline row
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
                    leg.flightNumber,
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
          const SizedBox(height: 16),
          // Time & route row
          Row(
            children: [
              // Departure
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    depTime,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    leg.departureAirport,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              // Flight line
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      Text(
                        durationStr,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            height: 2,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                          Icon(
                            Icons.flight_rounded,
                            size: 16,
                            color: AppTheme.primaryColor.withOpacity(0.6),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        flight.stops == 0 ? 'Direct' : '${flight.stops} stop(s)',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: flight.stops == 0
                              ? Colors.green.shade600
                              : Colors.orange.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Arrival
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    arrTime,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    leg.arrivalAirport,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Info chips
          Row(
            children: [
              if (leg.airplane.isNotEmpty) _buildChip(leg.airplane),
              if (leg.travelClass.isNotEmpty) _buildChip(leg.travelClass),
              if (leg.legroom.isNotEmpty) _buildChip(leg.legroom),
              const Spacer(),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildChip(String text) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 11,
          color: AppTheme.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatTime(String dateTimeStr) {
    // Format: "2026-06-15 10:45"
    final parts = dateTimeStr.split(' ');
    if (parts.length >= 2) {
      return parts[1].substring(0, 5);
    }
    return dateTimeStr;
  }
}
