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
import 'flight_results_screen.dart';

class CitySelectionScreen extends StatefulWidget {
  final City? prefillFrom;
  final City? prefillTo;
  final bool isReturn;
  final FlightOffer? firstFlight;
  final City? outboundDestinationCity;

  const CitySelectionScreen({
    super.key,
    this.prefillFrom,
    this.prefillTo,
    this.isReturn = false,
    this.firstFlight,
    this.outboundDestinationCity,
  });

  @override
  State<CitySelectionScreen> createState() => _CitySelectionScreenState();
}

class _CitySelectionScreenState extends State<CitySelectionScreen> {
  final ApiService _apiService = ApiService();
  final MapController _mapController = MapController();

  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  final FocusNode _fromFocus = FocusNode();
  final FocusNode _toFocus = FocusNode();

  List<City> _fromSuggestions = [];
  List<City> _toSuggestions = [];
  City? _selectedFrom;
  City? _selectedTo;
  bool _isLoadingFrom = false;
  bool _isLoadingTo = false;
  DateTime? _departureDate;

  Timer? _debounceFrom;
  Timer? _debounceTo;

  @override
  void initState() {
    super.initState();
    if (widget.prefillFrom != null) {
      _selectedFrom = widget.prefillFrom;
      _fromController.text = '${widget.prefillFrom!.name}, ${widget.prefillFrom!.country}';
    }
    if (widget.prefillTo != null) {
      _selectedTo = widget.prefillTo;
      _toController.text = '${widget.prefillTo!.name}, ${widget.prefillTo!.country}';
    }
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _fromFocus.dispose();
    _toFocus.dispose();
    _debounceFrom?.cancel();
    _debounceTo?.cancel();
    super.dispose();
  }

  void _onFromChanged(String query) {
    _selectedFrom = null;
    _debounceFrom?.cancel();
    if (query.isEmpty) {
      setState(() => _fromSuggestions = []);
      return;
    }
    _debounceFrom = Timer(const Duration(milliseconds: 300), () async {
      setState(() => _isLoadingFrom = true);
      final results = await _apiService.searchCities(query);
      if (mounted) {
        setState(() {
          _fromSuggestions = results;
          _isLoadingFrom = false;
        });
      }
    });
  }

  void _onToChanged(String query) {
    _selectedTo = null;
    _debounceTo?.cancel();
    if (query.isEmpty) {
      setState(() => _toSuggestions = []);
      return;
    }
    _debounceTo = Timer(const Duration(milliseconds: 300), () async {
      setState(() => _isLoadingTo = true);
      final results = await _apiService.searchCities(query);
      if (mounted) {
        setState(() {
          _toSuggestions = results;
          _isLoadingTo = false;
        });
      }
    });
  }

  void _selectFromCity(City city) {
    setState(() {
      _selectedFrom = city;
      _fromController.text = '${city.name}, ${city.country}';
      _fromSuggestions = [];
    });
    _updateMapView();
    _toFocus.requestFocus();
  }

  void _selectToCity(City city) {
    setState(() {
      _selectedTo = city;
      _toController.text = '${city.name}, ${city.country}';
      _toSuggestions = [];
    });
    _updateMapView();
    _toFocus.unfocus();
  }

  void _updateMapView() {
    final from = _selectedFrom?.coordinates;
    final to = _selectedTo?.coordinates;

    if (from != null && to != null) {
      final centerLat = (from.$1 + to.$1) / 2;
      final centerLng = (from.$2 + to.$2) / 2;
      final zoom = _calculateZoom(
        LatLng(from.$1, from.$2),
        LatLng(to.$1, to.$2),
      );
      _mapController.move(LatLng(centerLat, centerLng), zoom);
    } else if (from != null) {
      _mapController.move(LatLng(from.$1, from.$2), 6);
    } else if (to != null) {
      _mapController.move(LatLng(to.$1, to.$2), 6);
    }
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
              _buildAppBar(context),
              Expanded(
                child: isWide ? _buildWideLayout() : _buildNarrowLayout(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      'Where are you\ntravelling?',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildSearchCard(),
                    const SizedBox(height: 20),
                    _buildDateCard(),
                    const SizedBox(height: 32),
                    _buildSearchButton(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                height: 180,
                child: _buildMap(),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      'Where are you\ntravelling?',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildSearchCard(),
                    const SizedBox(height: 20),
                    _buildDateCard(),
                    const SizedBox(height: 32),
                    _buildSearchButton(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    final from = _selectedFrom?.coordinates;
    final to = _selectedTo?.coordinates;

    final markers = <Marker>[];
    List<LatLng>? arcPoints;

    if (from != null) {
      markers.add(Marker(
        point: LatLng(from.$1, from.$2),
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
                blurRadius: 8,
              ),
            ],
          ),
        ),
      ));
    }
    if (to != null) {
      markers.add(Marker(
        point: LatLng(to.$1, to.$2),
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
                blurRadius: 8,
              ),
            ],
          ),
        ),
      ));
    }
    if (from != null && to != null) {
      arcPoints = _generateArc(
        LatLng(from.$1, from.$2),
        LatLng(to.$1, to.$2),
      );
    }

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
          interactionOptions: InteractionOptions(
            flags: InteractiveFlag.all,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.eurowander.app',
          ),
          if (arcPoints != null)
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
          if (markers.isNotEmpty)
            MarkerLayer(markers: markers),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
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
            'Plan Trip',
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

  Widget _buildSearchCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
          _buildCityField(
            controller: _fromController,
            focusNode: _fromFocus,
            label: 'From',
            hint: 'Departure city',
            icon: Icons.flight_takeoff_rounded,
            onChanged: _onFromChanged,
            suggestions: _fromSuggestions,
            isLoading: _isLoadingFrom,
            onSelect: _selectFromCity,
            selectedCity: _selectedFrom,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                const SizedBox(width: 18),
                Container(
                  width: 2,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            ),
          ),
          _buildCityField(
            controller: _toController,
            focusNode: _toFocus,
            label: 'To',
            hint: 'Destination city',
            icon: Icons.flight_land_rounded,
            onChanged: _onToChanged,
            suggestions: _toSuggestions,
            isLoading: _isLoadingTo,
            onSelect: _selectToCity,
            selectedCity: _selectedTo,
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate({required bool isDeparture}) async {
    final now = DateTime.now();
    final initial = _departureDate ?? now.add(const Duration(days: 1));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
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
      setState(() {
        _departureDate = picked;
      });
    }
  }

  Widget _buildDateCard() {
    final dateFormat = DateFormat('EEE, MMM d');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: _buildDateTile(
        label: 'Departure',
        value: _departureDate != null
            ? dateFormat.format(_departureDate!)
            : 'Select date',
        icon: Icons.calendar_today_rounded,
        isSelected: _departureDate != null,
        onTap: () => _pickDate(isDeparture: true),
      ),
    );
  }

  Widget _buildSearchButton() {
    final isReady =
        _selectedFrom != null && _selectedTo != null && _departureDate != null;
    return GestureDetector(
      onTap: isReady
          ? () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => FlightResultsScreen(
                    origin: _selectedFrom!,
                    destination: _selectedTo!,
                    departureDate: _departureDate!,
                    isReturn: widget.isReturn,
                    firstFlight: widget.firstFlight,
                    outboundDestinationCity: widget.outboundDestinationCity,
                  ),
                ),
              );
            }
          : null,
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
              'Search Flights',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isReady ? Colors.white : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTile({
    required String label,
    required String value,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryColor.withOpacity(0.1)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 18,
              color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? AppTheme.textPrimary
                        : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCityField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData icon,
    required ValueChanged<String> onChanged,
    required List<City> suggestions,
    required bool isLoading,
    required ValueChanged<City> onSelect,
    required City? selectedCity,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selectedCity != null
                    ? AppTheme.primaryColor.withOpacity(0.1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 20,
                color: selectedCity != null
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
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: controller,
                    focusNode: focusNode,
                    onChanged: onChanged,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: hint,
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
            if (isLoading)
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
        if (suggestions.isNotEmpty) _buildSuggestionsList(suggestions, onSelect),
      ],
    );
  }

  Widget _buildSuggestionsList(List<City> suggestions, ValueChanged<City> onSelect) {
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
        itemCount: suggestions.length,
        separatorBuilder: (_, _) => Divider(
          height: 1,
          indent: 12,
          endIndent: 12,
          color: Colors.grey.shade200,
        ),
        itemBuilder: (context, index) {
          final city = suggestions[index];
          return InkWell(
            onTap: () => onSelect(city),
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
}
