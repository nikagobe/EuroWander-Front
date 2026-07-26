import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/bus.dart';
import '../../../models/city.dart';
import '../../../services/api_service.dart';
import '../../plan/bus_selection_screen.dart';

/// Transport section for the fork wizard.
/// Shows a compact summary and navigates to the classic BusSelectionScreen
/// in pick mode. The selected bus is returned to the wizard.
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

  City? _resolvedFrom;
  City? _resolvedTo;
  bool _isResolving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _resolveCities();
  }

  Future<void> _resolveCities() async {
    setState(() => _isResolving = true);
    try {
      final fromResults = await _apiService.searchCities(widget.fromCity);
      final toResults = await _apiService.searchCities(widget.toCity);

      if (mounted) {
        _resolvedFrom = fromResults.isNotEmpty
            ? fromResults.firstWhere(
                (c) => c.country.toLowerCase() == widget.fromCountry.toLowerCase(),
                orElse: () => fromResults.first,
              )
            : null;
        _resolvedTo = toResults.isNotEmpty
            ? toResults.firstWhere(
                (c) => c.country.toLowerCase() == widget.toCountry.toLowerCase(),
                orElse: () => toResults.first,
              )
            : null;
        setState(() => _isResolving = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to resolve cities: $e';
          _isResolving = false;
        });
      }
    }
  }

  Future<void> _openBusSearch() async {
    if (_resolvedFrom == null || _resolvedTo == null) return;

    final result = await Navigator.of(context).push<BusOffer>(
      MaterialPageRoute(
        builder: (_) => BusSelectionScreen(
          originCityFreebaseId: _resolvedFrom!.freebaseId,
          departureCityFreebaseId: _resolvedTo!.freebaseId,
          originCityName: widget.fromCity,
          departureCityName: widget.toCity,
          transitDate: widget.suggestedDate,
          pickMode: true,
        ),
      ),
    );

    if (result != null && mounted) {
      widget.onBusSelected(result);
    }
  }

  bool get _canSearch => !_isResolving && _resolvedFrom != null && _resolvedTo != null;

  @override
  Widget build(BuildContext context) {
    final ew = context.ew;
    final theme = Theme.of(context);

    // If a bus is already selected, show summary
    if (widget.selectedBus != null) {
      return _buildSelectedCard(widget.selectedBus!);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Route card
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
                    Text(
                      DateFormat('EEE, MMM d, yyyy').format(widget.suggestedDate),
                      style: theme.textTheme.bodySmall?.copyWith(color: ew.textSecondary),
                    ),
                  ],
                ),
              ),
              if (_isResolving)
                const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brandPrimary))
              else if (_resolvedFrom != null && _resolvedTo != null)
                const Icon(Icons.check_circle, size: 18, color: Color(0xFF4CAF50)),
            ],
          ),
        ),

        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
        ],

        const SizedBox(height: 16),

        // Search button - navigates to classic bus search page
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _canSearch ? _openBusSearch : null,
            icon: const Icon(Icons.search, size: 20),
            label: const Text('Search Transport', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
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

  Widget _buildSelectedCard(BusOffer bus) {
    final depTime = _formatTime(bus.depTime);
    final arrTime = _formatTime(bus.arrTime);

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
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.directions_bus_rounded, color: Color(0xFFFF9800), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.fromCity} → ${widget.toCity}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '$depTime → $arrTime · ${bus.duration}',
                      style: const TextStyle(fontSize: 12, color: AppColors.lightTextSecondary),
                    ),
                  ],
                ),
              ),
              Text(
                '€${(bus.totalPrice ?? bus.price).toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.brandPrimary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openBusSearch,
              icon: const Icon(Icons.swap_horiz, size: 18),
              label: const Text('Change Transport'),
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

  String _formatTime(String timeStr) {
    final parts = timeStr.split(' ');
    if (parts.length >= 2) return parts[1].length >= 5 ? parts[1].substring(0, 5) : parts[1];
    return timeStr.length >= 5 ? timeStr.substring(0, 5) : timeStr;
  }
}
