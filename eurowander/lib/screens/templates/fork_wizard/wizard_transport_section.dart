import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/bus.dart';
import '../../../services/api_service.dart';

/// Embedded bus/transport search section for the fork wizard.
/// Searches for buses between two template cities.
class WizardTransportSection extends StatefulWidget {
  final String fromCity;
  final String fromCountry;
  final String toCity;
  final String toCountry;
  final DateTime suggestedDate;
  final int segmentIndex;
  final BusOffer? selectedBus;
  final ValueChanged<BusOffer?> onBusSelected;

  const WizardTransportSection({
    super.key,
    required this.fromCity,
    required this.fromCountry,
    required this.toCity,
    required this.toCountry,
    required this.suggestedDate,
    required this.segmentIndex,
    this.selectedBus,
    required this.onBusSelected,
  });

  @override
  State<WizardTransportSection> createState() => _WizardTransportSectionState();
}

class _WizardTransportSectionState extends State<WizardTransportSection> {
  final ApiService _apiService = ApiService();

  List<BusOffer> _buses = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  String? _error;
  BusOffer? _localSelected;
  late DateTime _selectedDate;

  // Resolved freebase IDs
  String? _fromFreebaseId;
  String? _toFreebaseId;
  bool _isResolving = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.suggestedDate;
    _localSelected = widget.selectedBus;
  }

  Future<void> _resolveAndSearch() async {
    setState(() {
      _isResolving = true;
      _error = null;
    });

    try {
      // Resolve both cities
      final fromResults = await _apiService.searchCities(widget.fromCity);
      final toResults = await _apiService.searchCities(widget.toCity);

      if (fromResults.isEmpty || toResults.isEmpty) {
        setState(() {
          _error = 'Could not find one or both cities';
          _isResolving = false;
        });
        return;
      }

      final fromCity = fromResults.firstWhere(
        (c) => c.country.toLowerCase() == widget.fromCountry.toLowerCase(),
        orElse: () => fromResults.first,
      );
      final toCity = toResults.firstWhere(
        (c) => c.country.toLowerCase() == widget.toCountry.toLowerCase(),
        orElse: () => toResults.first,
      );

      _fromFreebaseId = fromCity.freebaseId;
      _toFreebaseId = toCity.freebaseId;
      setState(() => _isResolving = false);

      await _searchBuses();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to resolve cities: $e';
          _isResolving = false;
        });
      }
    }
  }

  Future<void> _searchBuses() async {
    if (_fromFreebaseId == null || _toFreebaseId == null) return;

    setState(() {
      _isSearching = true;
      _hasSearched = true;
      _error = null;
    });

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final results = await _apiService.searchBuses(
        originFreebaseId: _fromFreebaseId!,
        destinationFreebaseId: _toFreebaseId!,
        date: dateStr,
      );
      if (mounted) {
        setState(() {
          _buses = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to search buses: $e';
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.brandPrimary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.lightTextPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _localSelected = null;
      });
      if (_fromFreebaseId != null) {
        _searchBuses();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ew = context.ew;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Route header
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: ew.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.directions_bus_rounded, color: Color(0xFFFF9800), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.fromCity} → ${widget.toCity}',
                      style: theme.textTheme.labelLarge?.copyWith(color: ew.textPrimary),
                    ),
                    Text('Inter-city transit', style: theme.textTheme.bodySmall?.copyWith(color: ew.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Date picker
        GestureDetector(
          onTap: _pickDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.brandPrimary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.brandPrimary.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.brandPrimary),
                const SizedBox(width: 10),
                Text(
                  DateFormat('EEE, MMM d, yyyy').format(_selectedDate),
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.brandPrimary),
                ),
                const Spacer(),
                Text('Change', style: TextStyle(color: AppColors.brandPrimary.withOpacity(0.7), fontSize: 13)),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Search button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: (_isSearching || _isResolving) ? null : _resolveAndSearch,
            icon: const Icon(Icons.search, size: 20),
            label: Text(
              _isResolving
                  ? 'Resolving cities...'
                  : _isSearching
                      ? 'Searching...'
                      : 'Search Transport',
            ),
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
        if (_isSearching || _isResolving)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator(color: AppColors.brandPrimary)),
          )
        else if (_hasSearched && _buses.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(child: Text('No bus routes found for this date.', style: TextStyle(color: ew.textSecondary))),
          )
        else if (_buses.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            '${_buses.length} routes found',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ew.textSecondary),
          ),
          const SizedBox(height: 8),
          ..._buses.map((bus) => _buildBusCard(bus)),
        ],
      ],
    );
  }

  Widget _buildBusCard(BusOffer bus) {
    final isSelected = _localSelected == bus;
    final depTime = _formatTime(bus.depTime);
    final arrTime = _formatTime(bus.arrTime);
    final ew = context.ew;

    return GestureDetector(
      onTap: () {
        setState(() => _localSelected = bus);
        widget.onBusSelected(bus);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ew.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.brandPrimary : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.brandPrimary.withOpacity(0.1)
                  : Colors.black.withOpacity(0.04),
              blurRadius: isSelected ? 12 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product + price
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.directions_bus, size: 14, color: Color(0xFF4CAF50)),
                      const SizedBox(width: 4),
                      Text(
                        bus.segments.isNotEmpty ? bus.segments.first.product.toUpperCase() : 'BUS',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF4CAF50)),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  '€${(bus.totalPrice ?? bus.price).toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.brandPrimary),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Time row
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(depTime, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    Text(bus.depName, style: TextStyle(fontSize: 11, color: ew.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(bus.duration, style: TextStyle(fontSize: 11, color: ew.textSecondary)),
                      const SizedBox(height: 3),
                      Container(height: 2, margin: const EdgeInsets.symmetric(horizontal: 8), color: AppColors.brandPrimary.withOpacity(0.2)),
                      const SizedBox(height: 3),
                      if (bus.changeovers > 0)
                        Text('${bus.changeovers} change(s)', style: TextStyle(fontSize: 11, color: Colors.orange.shade700))
                      else
                        Text('Direct', style: TextStyle(fontSize: 11, color: Colors.green.shade600, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(arrTime, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    Text(bus.arrName, style: TextStyle(fontSize: 11, color: ew.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(height: 8),
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

  String _formatTime(String timeStr) {
    // Handle "2026-06-15 10:45" and "10:45" formats
    final parts = timeStr.split(' ');
    if (parts.length >= 2) return parts[1].length >= 5 ? parts[1].substring(0, 5) : parts[1];
    return timeStr.length >= 5 ? timeStr.substring(0, 5) : timeStr;
  }
}
