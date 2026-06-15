import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/bus.dart';
import '../../models/flight.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class TripConfirmationScreen extends StatefulWidget {
  final FlightOffer selectedFlight;
  final FlightOffer? returnFlight;
  final BusOffer? busTransit;

  const TripConfirmationScreen({
    super.key,
    required this.selectedFlight,
    this.returnFlight,
    this.busTransit,
  });

  @override
  State<TripConfirmationScreen> createState() => _TripConfirmationScreenState();
}

class _TripConfirmationScreenState extends State<TripConfirmationScreen> {
  final ApiService _apiService = ApiService();
  bool _isSaving = false;

  FlightOffer get selectedFlight => widget.selectedFlight;
  FlightOffer? get returnFlight => widget.returnFlight;
  BusOffer? get busTransit => widget.busTransit;

  List<LatLng> _getMapPoints() {
    final points = <LatLng>[];

    // Outbound: all legs
    for (final leg in selectedFlight.legs) {
      if (leg.departureLat != null && leg.departureLng != null) {
        points.add(LatLng(leg.departureLat!, leg.departureLng!));
      }
      if (leg.arrivalLat != null && leg.arrivalLng != null) {
        points.add(LatLng(leg.arrivalLat!, leg.arrivalLng!));
      }
    }

    // Return flight: all legs
    if (returnFlight != null) {
      for (final leg in returnFlight!.legs) {
        if (leg.departureLat != null && leg.departureLng != null) {
          points.add(LatLng(leg.departureLat!, leg.departureLng!));
        }
        if (leg.arrivalLat != null && leg.arrivalLng != null) {
          points.add(LatLng(leg.arrivalLat!, leg.arrivalLng!));
        }
      }
    }

    return points;
  }

  LatLngBounds? _getBounds(List<LatLng> points) {
    if (points.isEmpty) return null;
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    return LatLngBounds(
      LatLng(minLat - 0.5, minLng - 0.5),
      LatLng(maxLat + 0.5, maxLng + 0.5),
    );
  }

  List<LatLng> _buildArc(LatLng start, LatLng end) {
    final points = <LatLng>[];
    const steps = 30;
    final midLat = (start.latitude + end.latitude) / 2;
    final midLng = (start.longitude + end.longitude) / 2;
    final dist = sqrt(pow(end.latitude - start.latitude, 2) + pow(end.longitude - start.longitude, 2));
    final bulge = dist * 0.15;
    final angle = atan2(end.longitude - start.longitude, end.latitude - start.latitude) + pi / 2;
    final controlLat = midLat + bulge * cos(angle);
    final controlLng = midLng + bulge * sin(angle);

    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      final lat = (1 - t) * (1 - t) * start.latitude + 2 * (1 - t) * t * controlLat + t * t * end.latitude;
      final lng = (1 - t) * (1 - t) * start.longitude + 2 * (1 - t) * t * controlLng + t * t * end.longitude;
      points.add(LatLng(lat, lng));
    }
    return points;
  }

  String _getDefaultTripName() {
    String cityName = selectedFlight.arrivalCityName.isNotEmpty
        ? selectedFlight.arrivalCityName
        : (selectedFlight.legs.isNotEmpty
            ? selectedFlight.legs.last.arrivalCityName
            : '');
    if (cityName.isEmpty && selectedFlight.legs.isNotEmpty) {
      cityName = selectedFlight.legs.last.arrivalAirportName;
    }
    // Extract just the city part if it contains extra info
    if (cityName.contains(' ')) {
      // Keep first two words max for clean names like "El Prat" but trim "Barcelona El Prat Airport"
      final words = cityName.split(' ');
      if (words.length > 2) cityName = words.first;
    }
    try {
      final depTimeStr = selectedFlight.departureTime.isNotEmpty
          ? selectedFlight.departureTime
          : (selectedFlight.legs.isNotEmpty ? selectedFlight.legs.first.departureTime : '');
      final depTime = DateTime.parse(depTimeStr.replaceAll(' ', 'T'));
      final month = DateFormat('MMMM').format(depTime);
      return '$cityName Trip $month';
    } catch (_) {
      return '$cityName Trip';
    }
  }

  Future<void> _showNameDialog() async {
    final controller = TextEditingController(text: _getDefaultTripName());
    final name = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Name Your Trip',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: GoogleFonts.poppins(fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Enter trip name',
            hintStyle: GoogleFonts.poppins(color: AppTheme.textSecondary),
            filled: true,
            fillColor: const Color(0xFFF8F5FF),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              Navigator.of(ctx).pop(text.isEmpty ? _getDefaultTripName() : text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'Save',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || !mounted) return;
    _saveTrip(name);
  }

  Future<void> _saveTrip(String name) async {
    setState(() => _isSaving = true);
    try {
      final token = context.read<AuthProvider>().token;
      if (token == null) {
        throw Exception('Not authenticated');
      }
      await _apiService.saveTrip(
        token: token,
        name: name,
        outboundFlight: selectedFlight,
        returnFlight: returnFlight,
        busOffer: busTransit,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Trip saved successfully!',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
          backgroundColor: const Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to save trip: $e',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapPoints = _getMapPoints();
    final bounds = _getBounds(mapPoints);
    final totalPrice = selectedFlight.price + (returnFlight?.price ?? 0) + (busTransit?.price ?? 0);

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
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  // App bar
                  Padding(
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
                          'Trip Summary',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          // Map
                          if (mapPoints.length >= 2)
                            Container(
                              height: 200,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryColor.withOpacity(0.1),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: FlutterMap(
                                options: MapOptions(
                                  initialCameraFit: bounds != null
                                      ? CameraFit.bounds(
                                          bounds: bounds,
                                          padding: const EdgeInsets.all(40),
                                        )
                                      : null,
                                  interactionOptions: const InteractionOptions(
                                    flags: InteractiveFlag.none,
                                  ),
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate: 'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                                  ),
                                  PolylineLayer(
                                    polylines: _buildPolylines(mapPoints),
                                  ),
                                  MarkerLayer(
                                    markers: _buildMarkers(mapPoints),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 24),
                          // Outbound flight label
                          _buildSectionLabel('Outbound Flight', Icons.flight_takeoff_rounded),
                          const SizedBox(height: 12),
                          // Outbound flight card
                          _buildFlightCard(selectedFlight),
                          // Bus transit
                          if (busTransit != null) ...[
                            const SizedBox(height: 24),
                            _buildSectionLabel('Bus Transit', Icons.directions_bus_rounded),
                            const SizedBox(height: 12),
                            _buildBusCard(busTransit!),
                          ],
                          // Return flight
                          if (returnFlight != null) ...[
                            const SizedBox(height: 24),
                            _buildSectionLabel('Return Flight', Icons.flight_land_rounded),
                            const SizedBox(height: 12),
                            _buildFlightCard(returnFlight!),
                          ],
                          const SizedBox(height: 24),
                          // Price card
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withOpacity(0.3),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total Price',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                    if (returnFlight != null)
                                      Text(
                                        '${returnFlight != null ? "2" : "1"} flight${returnFlight != null ? "s" : ""}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.white.withOpacity(0.7),
                                        ),
                                      ),
                                  ],
                                ),
                                Text(
                                  '€${totalPrice.toStringAsFixed(0)}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Confirm button
                          GestureDetector(
                            onTap: _isSaving ? null : _showNameDialog,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              decoration: BoxDecoration(
                                color: AppTheme.textPrimary,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Center(
                                child: _isSaving
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        'Confirm Trip',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildFlightCard(FlightOffer flight) {
    final depTime = _formatTime(flight.departureTime);
    final arrTime = _formatTime(flight.arrivalTime);
    final depDate = _formatDate(flight.departureTime);
    final durationHrs = flight.totalDuration ~/ 60;
    final durationMins = flight.totalDuration % 60;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Date row
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 14, color: AppTheme.primaryColor.withOpacity(0.7)),
                const SizedBox(width: 8),
                Text(
                  depDate,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          // Airline row
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  flight.airlineLogo,
                  width: 36,
                  height: 36,
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
              Expanded(
                child: Column(
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
              ),
              Text(
                '€${flight.price.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Route
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
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
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    Text(
                      flight.departureAirportName.isNotEmpty
                          ? flight.departureAirportName
                          : (flight.legs.isNotEmpty ? flight.legs.first.departureAirportName : ''),
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Column(
                  children: [
                    Text(
                      '${durationHrs}h ${durationMins}m',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      width: 50,
                      height: 2,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      flight.stops == 0 ? 'Direct' : '${flight.stops} stop(s)',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.green.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
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
                        fontWeight: FontWeight.w600,
                        color: AppTheme.secondaryColor,
                      ),
                    ),
                    Text(
                      flight.arrivalAirportName.isNotEmpty
                          ? flight.arrivalAirportName
                          : (flight.legs.isNotEmpty ? flight.legs.last.arrivalAirportName : ''),
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBusCard(BusOffer bus) {
    final depTime = _formatBusTime(bus.depTime);
    final arrTime = _formatBusTime(bus.arrTime);
    final busDate = _formatDate(bus.depTime);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9800).withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Date row
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9800).withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 14, color: const Color(0xFFFF9800).withOpacity(0.7)),
                const SizedBox(width: 8),
                Text(
                  busDate,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFFF9800),
                  ),
                ),
              ],
            ),
          ),
          // Product row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.directions_bus, size: 16, color: Color(0xFFFF9800)),
                    const SizedBox(width: 4),
                    Text(
                      bus.segments.isNotEmpty ? bus.segments.first.product.toUpperCase() : 'BUS',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFFF9800),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                '€${bus.price.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFF9800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Route
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
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
                      bus.depName,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Column(
                  children: [
                    Text(
                      bus.duration,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      width: 50,
                      height: 2,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9800).withOpacity(0.4),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      bus.changeovers == 0 ? 'Direct' : '${bus.changeovers} change(s)',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: bus.changeovers == 0
                            ? Colors.green.shade600
                            : Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
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
                      bus.arrName,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.end,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatBusTime(String dateTimeStr) {
    try {
      final dt = DateTime.parse(dateTimeStr);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateTimeStr;
    }
  }

  List<Marker> _buildMarkers(List<LatLng> points) {
    final markers = <Marker>[];
    final addedPoints = <String>{};

    void addMarker(LatLng point, Color color, {double size = 28, IconData? icon}) {
      final key = '${point.latitude.toStringAsFixed(3)},${point.longitude.toStringAsFixed(3)}';
      if (addedPoints.contains(key)) return;
      addedPoints.add(key);
      markers.add(Marker(
        point: point,
        width: size,
        height: size,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.4), blurRadius: 6, offset: const Offset(0, 2)),
            ],
          ),
          child: icon != null ? Icon(icon, color: Colors.white, size: size * 0.5) : null,
        ),
      ));
    }

    // Outbound flight
    for (int i = 0; i < selectedFlight.legs.length; i++) {
      final leg = selectedFlight.legs[i];
      if (i == 0 && leg.departureLat != null) {
        addMarker(LatLng(leg.departureLat!, leg.departureLng!), AppTheme.primaryColor, icon: Icons.flight_takeoff);
      }
      if (leg.arrivalLat != null) {
        if (i < selectedFlight.legs.length - 1) {
          addMarker(LatLng(leg.arrivalLat!, leg.arrivalLng!), Colors.orange.shade600, size: 20, icon: Icons.circle);
        } else {
          addMarker(LatLng(leg.arrivalLat!, leg.arrivalLng!), AppTheme.secondaryColor, icon: Icons.flight_land);
        }
      }
    }

    // Return flight
    if (returnFlight != null) {
      for (int i = 0; i < returnFlight!.legs.length; i++) {
        final leg = returnFlight!.legs[i];
        if (i == 0 && leg.departureLat != null) {
          addMarker(LatLng(leg.departureLat!, leg.departureLng!), AppTheme.secondaryColor, icon: Icons.flight_takeoff);
        }
        if (leg.arrivalLat != null) {
          if (i < returnFlight!.legs.length - 1) {
            addMarker(LatLng(leg.arrivalLat!, leg.arrivalLng!), Colors.orange.shade600, size: 20, icon: Icons.circle);
          } else {
            addMarker(LatLng(leg.arrivalLat!, leg.arrivalLng!), AppTheme.primaryColor, icon: Icons.flight_land);
          }
        }
      }
    }

    return markers;
  }

  List<Polyline<Object>> _buildPolylines(List<LatLng> points) {
    final polylines = <Polyline<Object>>[];
    final outboundColors = [AppTheme.primaryColor, const Color(0xFFE91E63), const Color(0xFF00BCD4)];
    final returnColors = [AppTheme.secondaryColor, const Color(0xFFFF9800), const Color(0xFF4CAF50)];

    // Outbound legs
    for (int i = 0; i < selectedFlight.legs.length; i++) {
      final leg = selectedFlight.legs[i];
      if (leg.departureLat == null || leg.arrivalLat == null) continue;
      final start = LatLng(leg.departureLat!, leg.departureLng!);
      final end = LatLng(leg.arrivalLat!, leg.arrivalLng!);
      polylines.add(Polyline(
        points: _buildArc(start, end),
        color: outboundColors[i % outboundColors.length],
        strokeWidth: 2.5,
        pattern: const StrokePattern.dotted(),
      ));
    }

    // Return legs
    if (returnFlight != null) {
      for (int i = 0; i < returnFlight!.legs.length; i++) {
        final leg = returnFlight!.legs[i];
        if (leg.departureLat == null || leg.arrivalLat == null) continue;
        final start = LatLng(leg.departureLat!, leg.departureLng!);
        final end = LatLng(leg.arrivalLat!, leg.arrivalLng!);
        polylines.add(Polyline(
          points: _buildArc(start, end),
          color: returnColors[i % returnColors.length],
          strokeWidth: 2.5,
          pattern: const StrokePattern.dotted(),
        ));
      }
    }

    return polylines;
  }

  Widget _buildDetail(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  String _formatTime(String dateTimeStr) {
    final parts = dateTimeStr.split(' ');
    if (parts.length >= 2) {
      return parts[1].substring(0, 5);
    }
    return dateTimeStr;
  }

  String _formatDate(String dateTimeStr) {
    try {
      final dt = DateTime.parse(dateTimeStr);
      return DateFormat('EEE, MMM d, yyyy').format(dt);
    } catch (_) {
      final parts = dateTimeStr.split(' ');
      if (parts.isNotEmpty) return parts[0];
      return dateTimeStr;
    }
  }
}
