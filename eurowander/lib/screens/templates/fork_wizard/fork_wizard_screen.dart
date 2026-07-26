import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/fork_wizard_provider.dart';
import '../../../widgets/widgets.dart';
import 'wizard_flight_section.dart';
import 'wizard_hotel_section.dart';
import 'wizard_transport_section.dart';
import 'wizard_review_section.dart';

class ForkWizardScreen extends StatefulWidget {
  final String templateId;
  const ForkWizardScreen({super.key, required this.templateId});

  @override
  State<ForkWizardScreen> createState() => _ForkWizardScreenState();
}

class _ForkWizardScreenState extends State<ForkWizardScreen> {
  final ScrollController _scrollController = ScrollController();

  // Section keys for scrolling
  final _dateKey = GlobalKey();
  final _reviewKey = GlobalKey();
  final Map<String, GlobalKey> _sectionKeys = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<ForkWizardProvider>().reset());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToKey(GlobalKey key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = key.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
      }
    });
  }

  GlobalKey _getKey(String id) {
    return _sectionKeys.putIfAbsent(id, () => GlobalKey());
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: Consumer<ForkWizardProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              EWAppBar(title: 'Trip Builder'),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _buildAllSections(provider),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildAllSections(ForkWizardProvider provider) {
    final sections = <Widget>[];

    // ── 1. DATE SECTION ─────────────────────────────────────────────
    sections.add(_buildSectionCard(
      key: _dateKey,
      stepNumber: 1,
      icon: Icons.calendar_today,
      title: 'Select Start Date',
      isCompleted: provider.startDate != null && provider.forkGuide != null,
      child: _buildDateSection(provider),
    ));

    // Everything below needs the fork guide loaded
    if (provider.forkGuide == null) {
      sections.add(const SizedBox(height: 16));
      sections.add(_buildLockedSection('Complete the date step to continue'));
      return sections;
    }

    final guide = provider.forkGuide!;
    final legs = guide.legs;
    int stepNum = 2;

    // ── 2. FLIGHT TO FIRST CITY ─────────────────────────────────────
    final firstLeg = legs.first;
    final outboundKey = _getKey('flight_outbound');
    sections.add(_buildSectionCard(
      key: outboundKey,
      stepNumber: stepNum++,
      icon: Icons.flight_takeoff,
      title: 'Flight to ${firstLeg.city}',
      isCompleted: provider.outboundFlight != null,
      child: WizardFlightSection(
        title: 'Flight to ${firstLeg.city}',
        destinationCityName: firstLeg.city,
        destinationCountry: firstLeg.country,
        date: provider.startDate!,
        prefillOrigin: provider.originCity,
        selectedFlight: provider.outboundFlight,
        onFlightSelected: (flight) {
          provider.setOutboundFlight(flight);
        },
        onOriginResolved: (city) {
          provider.setOriginCity(city);
        },
      ),
    ));

    // ── 3..N. FOR EACH LEG: HOTEL + TRANSPORT ───────────────────────
    for (int i = 0; i < legs.length; i++) {
      final leg = legs[i];

      // Hotel for this city
      final hotelKey = _getKey('hotel_${leg.order}');
      sections.add(_buildSectionCard(
        key: hotelKey,
        stepNumber: stepNum++,
        icon: Icons.hotel,
        title: 'Hotel in ${leg.city}',
        isCompleted: provider.selectedHotels[leg.order] != null,
        child: WizardHotelSection(leg: leg),
      ));

      // Transport to next city (if not last)
      if (i < legs.length - 1) {
        final nextLeg = legs[i + 1];
        final transportKey = _getKey('transport_$i');
        final transitDate = provider.legEndDate(leg.order) ?? provider.startDate!;

        sections.add(_buildSectionCard(
          key: transportKey,
          stepNumber: stepNum++,
          icon: Icons.directions_bus,
          title: '${leg.city} → ${nextLeg.city}',
          isCompleted: provider.selectedBuses[i] != null,
          child: WizardTransportSection(
            fromCity: leg.city,
            fromCountry: leg.country,
            toCity: nextLeg.city,
            toCountry: nextLeg.country,
            suggestedDate: transitDate,
            segmentIndex: i,
            selectedBus: provider.selectedBuses[i],
            onBusSelected: (bus) => provider.selectBus(i, bus),
          ),
        ));
      }
    }

    // ── RETURN FLIGHT ───────────────────────────────────────────────
    final lastLeg = legs.last;
    final returnDate = provider.legEndDate(lastLeg.order) ?? provider.startDate!;
    final returnKey = _getKey('flight_return');

    sections.add(_buildSectionCard(
      key: returnKey,
      stepNumber: stepNum++,
      icon: Icons.flight_land,
      title: 'Return from ${lastLeg.city}',
      isCompleted: provider.returnFlight != null,
      child: WizardFlightSection(
        title: 'Return from ${lastLeg.city}',
        destinationCityName: lastLeg.city,
        destinationCountry: lastLeg.country,
        date: returnDate,
        isReturn: true,
        prefillOrigin: provider.originCity,
        selectedFlight: provider.returnFlight,
        onFlightSelected: (flight) => provider.setReturnFlight(flight),
      ),
    ));

    // ── REVIEW ──────────────────────────────────────────────────────
    sections.add(_buildSectionCard(
      key: _reviewKey,
      stepNumber: stepNum,
      icon: Icons.check_circle_outline,
      title: 'Review & Create',
      isCompleted: false,
      child: WizardReviewSection(
        templateId: widget.templateId,
        onCreateTrip: () => _createTrip(context, provider),
      ),
    ));

    // Bottom padding
    sections.add(const SizedBox(height: 40));

    return sections;
  }

  // ─── Date section content ─────────────────────────────────────────

  Widget _buildDateSection(ForkWizardProvider provider) {
    if (provider.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(color: AppColors.brandPrimary),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'When do you want to start?',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),

        // Date picker button
        GestureDetector(
          onTap: () => _selectDate(context, provider),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: provider.startDate != null
                    ? AppColors.brandPrimary
                    : Colors.grey.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: provider.startDate != null ? AppColors.brandPrimary : context.ew.textSecondary,
                ),
                const SizedBox(width: 12),
                Text(
                  provider.startDate != null
                      ? DateFormat('MMMM d, yyyy').format(provider.startDate!)
                      : 'Select start date',
                  style: TextStyle(
                    fontSize: 16,
                    color: provider.startDate != null ? context.ew.textPrimary : context.ew.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Trip duration preview
        if (provider.startDate != null && provider.forkGuide != null) ...[
          const SizedBox(height: 16),
          _buildDatePreview(provider),
        ],

        if (provider.startDate != null && provider.forkGuide == null) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => _confirmDate(provider),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Confirm Date', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],

        if (provider.error != null) ...[
          const SizedBox(height: 12),
          Text(provider.error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
        ],
      ],
    );
  }

  Widget _buildDatePreview(ForkWizardProvider provider) {
    final start = provider.startDate!;
    final totalDays = provider.forkGuide!.totalDays;
    final end = start.add(Duration(days: totalDays));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.brandPrimary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your trip:', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            '${DateFormat('MMM d').format(start)} – ${DateFormat('MMM d, yyyy').format(end)} ($totalDays days)',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          ...provider.forkGuide!.legs.map((leg) {
            final legStart = provider.legStartDate(leg.order)!;
            final legEnd = provider.legEndDate(leg.order)!;
            return Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                '📍 ${leg.city} — ${DateFormat('MMM d').format(legStart)}–${DateFormat('MMM d').format(legEnd)} (${leg.days} days)',
                style: const TextStyle(fontSize: 12, color: AppColors.lightTextSecondary),
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, ForkWizardProvider provider) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: provider.startDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(primary: AppColors.brandPrimary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      provider.setStartDate(picked);
      if (provider.forkGuide == null) {
        await _confirmDate(provider);
      }
    }
  }

  Future<void> _confirmDate(ForkWizardProvider provider) async {
    if (provider.startDate == null) return;
    final userId = context.read<AuthProvider>().user?.id ?? '';
    final dateStr = DateFormat('yyyy-MM-dd').format(provider.startDate!);
    await provider.initializeFork(
      templateId: widget.templateId,
      userId: userId,
      startDate: dateStr,
    );
  }

  // ─── Section card wrapper ─────────────────────────────────────────

  Widget _buildSectionCard({
    required Key key,
    required int stepNumber,
    required IconData icon,
    required String title,
    required bool isCompleted,
    required Widget child,
  }) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.ew.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted ? const Color(0xFF4CAF50).withOpacity(0.4) : Colors.grey.withOpacity(0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isCompleted ? const Color(0xFF4CAF50).withOpacity(0.06) : AppColors.brandPrimary.withOpacity(0.04),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: isCompleted ? const Color(0xFF4CAF50) : AppColors.brandPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : Text(
                            '$stepNumber',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(icon, size: 20, color: isCompleted ? const Color(0xFF4CAF50) : AppColors.brandPrimary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isCompleted ? const Color(0xFF2E7D32) : context.ew.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Section content
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildLockedSection(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(color: context.ew.textSecondary, fontStyle: FontStyle.italic),
        ),
      ),
    );
  }

  // ─── Create trip ──────────────────────────────────────────────────

  Future<void> _createTrip(BuildContext context, ForkWizardProvider provider) async {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Trip created from template! You can view and edit it from your trips.'),
        duration: Duration(seconds: 4),
      ),
    );
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}


