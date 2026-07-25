import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/bus.dart';
import '../../models/flight.dart';
import '../../services/api_service.dart';
import '../../widgets/widgets.dart';
import 'trip_confirmation_screen.dart';

class BusSelectionScreen extends StatefulWidget {
  final String originCityFreebaseId;
  final String departureCityFreebaseId;
  final String originCityName;
  final String departureCityName;
  final DateTime transitDate;
  final FlightOffer outboundFlight;
  final FlightOffer returnFlight;
  final int adults;

  const BusSelectionScreen({
    super.key,
    required this.originCityFreebaseId,
    required this.departureCityFreebaseId,
    required this.originCityName,
    required this.departureCityName,
    required this.transitDate,
    required this.outboundFlight,
    required this.returnFlight,
    this.adults = 1,
  });

  @override
  State<BusSelectionScreen> createState() => _BusSelectionScreenState();
}

class _BusSelectionScreenState extends State<BusSelectionScreen> {
  final ApiService _apiService = ApiService();
  List<BusOffer> _buses = [];
  bool _isLoading = true;
  String? _error;
  BusOffer? _selectedBus;
  late DateTime _selectedDate;

  DateTime get _earliestDate {
    try {
      final arrTime = widget.outboundFlight.arrivalTime;
      if (arrTime.isNotEmpty) return DateTime.parse(arrTime);
    } catch (_) {}
    return widget.transitDate;
  }

  DateTime get _latestDate {
    try {
      final depTime = widget.returnFlight.departureTime;
      if (depTime.isNotEmpty) return DateTime.parse(depTime);
    } catch (_) {}
    return widget.transitDate.add(const Duration(days: 30));
  }

  @override
  void initState() {
    super.initState();
    // Default to middle date between outbound arrival and return departure
    final earliest = _earliestDate;
    final latest = _latestDate;
    final midMillis = (earliest.millisecondsSinceEpoch + latest.millisecondsSinceEpoch) ~/ 2;
    _selectedDate = DateTime.fromMillisecondsSinceEpoch(midMillis);
    // Ensure it's a clean date (no time component)
    _selectedDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    _searchBuses();
  }

  Future<void> _searchBuses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final results = await _apiService.searchBuses(
        originFreebaseId: widget.originCityFreebaseId,
        destinationFreebaseId: widget.departureCityFreebaseId,
        date: dateStr,
        adults: widget.adults,
      );
      setState(() {
        _buses = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: _earliestDate,
      lastDate: _latestDate,
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
        _selectedBus = null;
      });
      _searchBuses();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: Column(
        children: [
          EWAppBar(title: 'Bus Transit'),
          _buildRouteHeader(),
          Expanded(child: _buildBody()),
          _buildBottomButtons(),
        ],
      ),
    );
  }

  Widget _buildRouteHeader() {
    final ew = context.ew;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: ew.cardColor,
          borderRadius: AppRadius.borderLg,
          boxShadow: [
            BoxShadow(
              color: AppColors.brandPrimary.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.directions_bus_rounded, color: Color(0xFFFF9800), size: 22),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.originCityName} → ${widget.departureCityName}',
                        style: theme.textTheme.labelLarge?.copyWith(color: ew.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Inter-city transit',
                        style: theme.textTheme.bodySmall?.copyWith(color: ew.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary.withOpacity(0.06),
                  borderRadius: AppRadius.borderMd,
                  border: Border.all(color: AppColors.brandPrimary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.brandPrimary),
                    const SizedBox(width: 10),
                    Text(
                      DateFormat('EEE, MMM d, yyyy').format(_selectedDate),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.brandPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Change',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppColors.brandPrimary.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xxs),
                    Icon(Icons.arrow_drop_down_rounded, size: 20, color: AppColors.brandPrimary.withOpacity(0.7)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    final ew = context.ew;
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.brandPrimary),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Failed to search buses',
                style: theme.textTheme.titleMedium?.copyWith(color: ew.textPrimary),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _error!,
                style: theme.textTheme.bodySmall?.copyWith(color: ew.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    if (_buses.isEmpty) {
      return EmptyState(
        icon: Icons.directions_bus_outlined,
        title: 'No bus routes found',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
      itemCount: _buses.length,
      itemBuilder: (context, index) => _buildBusCard(_buses[index]),
    );
  }

  Widget _buildBusCard(BusOffer bus) {
    final isSelected = _selectedBus == bus;
    final depTime = _formatTime(bus.depTime);
    final arrTime = _formatTime(bus.arrTime);
    final ew = context.ew;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => setState(() => _selectedBus = bus),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: ew.cardColor,
          borderRadius: AppRadius.borderLg,
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
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: product + price
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.directions_bus, size: 14, color: Color(0xFF4CAF50)),
                      const SizedBox(width: AppSpacing.xxs),
                      Text(
                        bus.segments.isNotEmpty ? bus.segments.first.product.toUpperCase() : 'BUS',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF4CAF50),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '€${(bus.totalPrice ?? bus.price).toStringAsFixed(2)}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: AppColors.brandPrimary,
                      ),
                    ),
                    if (bus.adults > 1 && bus.pricePerPerson != null)
                      Text(
                        '€${bus.pricePerPerson!.toStringAsFixed(2)}/person',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: ew.textSecondary,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            // Route row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        depTime,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: ew.textPrimary,
                        ),
                      ),
                      Text(
                        bus.depName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: ew.textSecondary,
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
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: ew.textSecondary,
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
                        style: theme.textTheme.bodySmall?.copyWith(
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
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: ew.textPrimary,
                        ),
                      ),
                      Text(
                        bus.arrName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: ew.textSecondary,
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
            // Additional info
            if (bus.additionalInfo.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  bus.additionalInfo,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.red.shade700,
                  ),
                ),
              ),
            ],
            // Segments for multi-leg
            if (bus.changeovers > 0) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: bus.segments.map((seg) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
                    child: Row(
                      children: [
                        Icon(Icons.circle, size: 6, color: Colors.grey.shade400),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            '${_formatTime(seg.depTime)} ${seg.depName} → ${_formatTime(seg.arrTime)} ${seg.arrName}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                              color: ew.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButtons() {
    final ew = context.ew;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_selectedBus != null)
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TripConfirmationScreen(
                      selectedFlight: widget.outboundFlight,
                      returnFlight: widget.returnFlight,
                      busTransit: _selectedBus,
                    ),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.brandPrimary, Color(0xFF8B5CF6), AppColors.brandSecondary],
                  ),
                  borderRadius: AppRadius.borderXl,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brandPrimary.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'Continue',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TripConfirmationScreen(
                    selectedFlight: widget.outboundFlight,
                    returnFlight: widget.returnFlight,
                    busTransit: null,
                  ),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: ew.cardColor,
                borderRadius: AppRadius.borderXl,
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Center(
                child: Text(
                  'Skip Bus Transit',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: ew.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String dateTimeStr) {
    try {
      final dt = DateTime.parse(dateTimeStr);
      return DateFormat('HH:mm').format(dt);
    } catch (_) {
      return dateTimeStr;
    }
  }
}
