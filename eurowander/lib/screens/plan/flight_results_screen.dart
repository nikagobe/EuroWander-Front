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
import 'bus_selection_screen.dart';
import 'trip_confirmation_screen.dart';
import 'return_flight_options_screen.dart';

class FlightResultsScreen extends StatefulWidget {
  final City origin;
  final City destination;
  final DateTime departureDate;
  final int adults;
  final bool isReturn;
  final FlightOffer? firstFlight;
  final City? outboundDestinationCity;

  const FlightResultsScreen({
    super.key,
    required this.origin,
    required this.destination,
    required this.departureDate,
    this.adults = 1,
    this.isReturn = false,
    this.firstFlight,
    this.outboundDestinationCity,
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
        adults: widget.adults,
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
    if (_selectedFlight != null && _selectedFlight!.legs.isNotEmpty) {
      final firstLeg = _selectedFlight!.legs.first;
      final lastLeg = _selectedFlight!.legs.last;
      return firstLeg.departureLat != null && lastLeg.arrivalLat != null;
    }
    return widget.origin.coordinates != null && widget.destination.coordinates != null;
  }

  (LatLng origin, LatLng dest) get _mapPoints {
    if (_selectedFlight != null && _selectedFlight!.legs.isNotEmpty) {
      final firstLeg = _selectedFlight!.legs.first;
      final lastLeg = _selectedFlight!.legs.last;
      if (firstLeg.departureLat != null && lastLeg.arrivalLat != null) {
        return (
          LatLng(firstLeg.departureLat!, firstLeg.departureLng!),
          LatLng(lastLeg.arrivalLat!, lastLeg.arrivalLng!),
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
    if (_hasMapCoordinates && flight.legs.isNotEmpty) {
      // Calculate bounds that include all leg waypoints
      double minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;
      for (final leg in flight.legs) {
        if (leg.departureLat != null) {
          minLat = min(minLat, leg.departureLat!);
          maxLat = max(maxLat, leg.departureLat!);
          minLng = min(minLng, leg.departureLng!);
          maxLng = max(maxLng, leg.departureLng!);
        }
        if (leg.arrivalLat != null) {
          minLat = min(minLat, leg.arrivalLat!);
          maxLat = max(maxLat, leg.arrivalLat!);
          minLng = min(minLng, leg.arrivalLng!);
          maxLng = max(maxLng, leg.arrivalLng!);
        }
      }
      final centerLat = (minLat + maxLat) / 2;
      final centerLng = (minLng + maxLng) / 2;
      final zoom = _calculateZoom(LatLng(minLat, minLng), LatLng(maxLat, maxLng));
      _mapController.move(LatLng(centerLat, centerLng), zoom);
    }
  }

  Widget _buildRouteMap() {
    final (originLatLng, destLatLng) = _mapPoints;
    final centerLat = (originLatLng.latitude + destLatLng.latitude) / 2;
    final centerLng = (originLatLng.longitude + destLatLng.longitude) / 2;

    // Build polylines and markers for all legs
    final polylines = <Polyline<Object>>[];
    final markers = <Marker>[];
    final legColors = [AppTheme.primaryColor, const Color(0xFFE91E63), const Color(0xFF00BCD4), const Color(0xFFFF9800)];

    if (_selectedFlight != null && _selectedFlight!.legs.isNotEmpty) {
      final legs = _selectedFlight!.legs;
      for (int i = 0; i < legs.length; i++) {
        final leg = legs[i];
        if (leg.departureLat == null || leg.arrivalLat == null) continue;
        final start = LatLng(leg.departureLat!, leg.departureLng!);
        final end = LatLng(leg.arrivalLat!, leg.arrivalLng!);
        final color = legColors[i % legColors.length];
        polylines.add(
          Polyline(
            points: _generateArc(start, end),
            strokeWidth: 3,
            color: color,
            pattern: const StrokePattern.dotted(),
          ),
        );

        // Add departure marker for first leg
        if (i == 0) {
          markers.add(Marker(
            point: start,
            width: 24,
            height: 24,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 6)],
              ),
            ),
          ));
        }

        // Add stopover markers (intermediate airports)
        if (i < legs.length - 1) {
          markers.add(Marker(
            point: end,
            width: 20,
            height: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.orange.shade600,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 4)],
              ),
              child: const Icon(Icons.circle, size: 6, color: Colors.white),
            ),
          ));
        }

        // Add final arrival marker
        if (i == legs.length - 1) {
          markers.add(Marker(
            point: end,
            width: 24,
            height: 24,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [BoxShadow(color: AppTheme.secondaryColor.withOpacity(0.3), blurRadius: 6)],
              ),
            ),
          ));
        }
      }
    } else {
      // Fallback: single arc from origin to destination
      polylines.add(
        Polyline(
          points: _generateArc(originLatLng, destLatLng),
          strokeWidth: 3,
          color: AppTheme.primaryColor,
          pattern: const StrokePattern.dotted(),
        ),
      );
      markers.addAll([
        Marker(
          point: originLatLng,
          width: 24,
          height: 24,
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 6)],
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
              boxShadow: [BoxShadow(color: AppTheme.secondaryColor.withOpacity(0.3), blurRadius: 6)],
            ),
          ),
        ),
      ]);
    }

    // Calculate zoom to fit all points
    LatLng zoomOrigin = originLatLng;
    LatLng zoomDest = destLatLng;
    if (_selectedFlight != null && _selectedFlight!.legs.length > 1) {
      double minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;
      for (final leg in _selectedFlight!.legs) {
        if (leg.departureLat != null) {
          minLat = min(minLat, leg.departureLat!);
          maxLat = max(maxLat, leg.departureLat!);
          minLng = min(minLng, leg.departureLng!);
          maxLng = max(maxLng, leg.departureLng!);
        }
        if (leg.arrivalLat != null) {
          minLat = min(minLat, leg.arrivalLat!);
          maxLat = max(maxLat, leg.arrivalLat!);
          minLng = min(minLng, leg.arrivalLng!);
          maxLng = max(maxLng, leg.arrivalLng!);
        }
      }
      zoomOrigin = LatLng(minLat, minLng);
      zoomDest = LatLng(maxLat, maxLng);
    }

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
            initialCenter: LatLng(
              (zoomOrigin.latitude + zoomDest.latitude) / 2,
              (zoomOrigin.longitude + zoomDest.longitude) / 2,
            ),
            initialZoom: _calculateZoom(zoomOrigin, zoomDest),
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.eurowander.app',
            ),
            PolylineLayer(polylines: polylines),
            MarkerLayer(markers: markers),
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

    // Build polylines and markers for all legs (multi-leg support)
    final polylines = <Polyline<Object>>[];
    final markers = <Marker>[];
    final legColors = [AppTheme.primaryColor, const Color(0xFFE91E63), const Color(0xFF00BCD4), const Color(0xFFFF9800)];

    LatLng zoomOrigin = originLatLng;
    LatLng zoomDest = destLatLng;

    if (_selectedFlight != null && _selectedFlight!.legs.isNotEmpty) {
      final legs = _selectedFlight!.legs;
      bool hasCoords = false;
      for (int i = 0; i < legs.length; i++) {
        final leg = legs[i];
        if (leg.departureLat == null || leg.arrivalLat == null) continue;
        hasCoords = true;
        final start = LatLng(leg.departureLat!, leg.departureLng!);
        final end = LatLng(leg.arrivalLat!, leg.arrivalLng!);
        final color = legColors[i % legColors.length];
        polylines.add(
          Polyline(
            points: _generateArc(start, end),
            strokeWidth: 3,
            color: color,
            pattern: const StrokePattern.dotted(),
          ),
        );

        if (i == 0) {
          markers.add(Marker(
            point: start,
            width: 28,
            height: 28,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 6)],
              ),
            ),
          ));
        }

        if (i < legs.length - 1) {
          markers.add(Marker(
            point: end,
            width: 22,
            height: 22,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.orange.shade600,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 4)],
              ),
              child: const Icon(Icons.circle, size: 6, color: Colors.white),
            ),
          ));
        }

        if (i == legs.length - 1) {
          markers.add(Marker(
            point: end,
            width: 28,
            height: 28,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [BoxShadow(color: AppTheme.secondaryColor.withOpacity(0.3), blurRadius: 6)],
              ),
            ),
          ));
        }
      }

      if (!hasCoords) {
        // Fallback if legs have no coordinates
        polylines.add(Polyline(points: _generateArc(originLatLng, destLatLng), strokeWidth: 3, color: AppTheme.primaryColor, pattern: const StrokePattern.dotted()));
        markers.addAll([
          Marker(point: originLatLng, width: 28, height: 28, child: Container(decoration: BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3), boxShadow: [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 6)]))),
          Marker(point: destLatLng, width: 28, height: 28, child: Container(decoration: BoxDecoration(color: AppTheme.secondaryColor, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3), boxShadow: [BoxShadow(color: AppTheme.secondaryColor.withOpacity(0.3), blurRadius: 6)]))),
        ]);
      }

      // Calculate zoom to fit all waypoints
      if (legs.length > 1 && hasCoords) {
        double minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;
        for (final leg in legs) {
          if (leg.departureLat != null) {
            minLat = min(minLat, leg.departureLat!);
            maxLat = max(maxLat, leg.departureLat!);
            minLng = min(minLng, leg.departureLng!);
            maxLng = max(maxLng, leg.departureLng!);
          }
          if (leg.arrivalLat != null) {
            minLat = min(minLat, leg.arrivalLat!);
            maxLat = max(maxLat, leg.arrivalLat!);
            minLng = min(minLng, leg.arrivalLng!);
            maxLng = max(maxLng, leg.arrivalLng!);
          }
        }
        zoomOrigin = LatLng(minLat, minLng);
        zoomDest = LatLng(maxLat, maxLng);
      }
    } else {
      // No flight selected - single arc
      polylines.add(Polyline(points: _generateArc(originLatLng, destLatLng), strokeWidth: 3, color: AppTheme.primaryColor, pattern: const StrokePattern.dotted()));
      markers.addAll([
        Marker(point: originLatLng, width: 28, height: 28, child: Container(decoration: BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3), boxShadow: [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 6)]))),
        Marker(point: destLatLng, width: 28, height: 28, child: Container(decoration: BoxDecoration(color: AppTheme.secondaryColor, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3), boxShadow: [BoxShadow(color: AppTheme.secondaryColor.withOpacity(0.3), blurRadius: 6)]))),
      ]);
    }

    final centerLat = (zoomOrigin.latitude + zoomDest.latitude) / 2;
    final centerLng = (zoomOrigin.longitude + zoomDest.longitude) / 2;

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
          initialZoom: _calculateZoom(zoomOrigin, zoomDest),
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.eurowander.app',
          ),
          PolylineLayer(polylines: polylines),
          MarkerLayer(markers: markers),
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
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildFlightCard(_flights[index]),
    );
  }

  Widget _buildContinueButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: GestureDetector(
        onTap: () {
          if (widget.isReturn) {
            // Use top-level city info to check if bus transit is needed
            final outboundArrivalId = widget.firstFlight!.arrivalAirportId.isNotEmpty
                ? widget.firstFlight!.legs.last.arrivalCityFreebaseId
                : '';
            final returnDepartureId = _selectedFlight!.legs.isNotEmpty
                ? _selectedFlight!.legs.first.departureCityFreebaseId
                : '';
            final needsBus = outboundArrivalId.isNotEmpty &&
                returnDepartureId.isNotEmpty &&
                outboundArrivalId != returnDepartureId;

            if (needsBus) {
              // Need bus transit between outbound arrival and return departure
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BusSelectionScreen(
                    originCityFreebaseId: outboundArrivalId,
                    departureCityFreebaseId: returnDepartureId,
                    originCityName: widget.firstFlight!.arrivalCityName.isNotEmpty
                        ? widget.firstFlight!.arrivalCityName
                        : widget.firstFlight!.legs.last.arrivalCityName,
                    departureCityName: _selectedFlight!.departureCityName.isNotEmpty
                        ? _selectedFlight!.departureCityName
                        : _selectedFlight!.legs.first.departureCityName,
                    transitDate: widget.departureDate,
                    outboundFlight: widget.firstFlight!,
                    returnFlight: _selectedFlight!,
                    adults: widget.adults,
                  ),
                ),
              );
            } else {
              // Same city - go directly to confirmation
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TripConfirmationScreen(
                    selectedFlight: widget.firstFlight!,
                    returnFlight: _selectedFlight!,
                  ),
                ),
              );
            }
          } else {
            // Outbound flight selected - choose return
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ReturnFlightOptionsScreen(
                  origin: widget.origin,
                  destination: widget.destination,
                  departureDate: widget.departureDate,
                  firstFlight: _selectedFlight!,
                  adults: widget.adults,
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
    final depTime = _formatTime(flight.departureTime);
    final arrTime = _formatTime(flight.arrivalTime);
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
                  flight.airlineLogo,
                  width: 36,
                  height: 36,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Container(
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
                    flight.airline,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (flight.legs.isNotEmpty)
                    Text(
                      flight.legs.first.flightNumber,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
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
                  if (flight.adults > 1 && flight.pricePerPerson != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '€${flight.pricePerPerson!.toStringAsFixed(0)}/person',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                ],
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
                    flight.departureAirportId,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  if (flight.departureCityName.isNotEmpty)
                    Text(
                      flight.departureCityName,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppTheme.textSecondary.withOpacity(0.7),
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
                      if (flight.stops == 0)
                        Text(
                          'Direct',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.green.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      else
                        Tooltip(
                          message: _buildStopsTooltip(flight),
                          preferBelow: true,
                          textStyle: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade800,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${flight.stops} stop(s)',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
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
                    flight.arrivalAirportId,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  if (flight.arrivalCityName.isNotEmpty)
                    Text(
                      flight.arrivalCityName,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppTheme.textSecondary.withOpacity(0.7),
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
              if (flight.legs.isNotEmpty && flight.legs.first.airplane.isNotEmpty) _buildChip(flight.legs.first.airplane),
              if (flight.legs.isNotEmpty && flight.legs.first.travelClass.isNotEmpty) _buildChip(flight.legs.first.travelClass),
              if (flight.legs.isNotEmpty && flight.legs.first.legroom.isNotEmpty) _buildChip(flight.legs.first.legroom),
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

  String _buildStopsTooltip(FlightOffer flight) {
    if (flight.legs.length <= 1) return '${flight.stops} stop(s)';
    // Intermediate stops are the arrival airports of all legs except the last
    final stops = <String>[];
    for (int i = 0; i < flight.legs.length - 1; i++) {
      final leg = flight.legs[i];
      final city = leg.arrivalCityName.isNotEmpty ? leg.arrivalCityName : leg.arrivalAirport;
      stops.add('$city (${leg.arrivalAirport})');
    }
    return 'Via ${stops.join(', ')}';
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
