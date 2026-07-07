import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/saved_trip.dart';
import '../../models/schedule.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import 'attraction_detail_screen.dart';
import 'restaurant_detail_screen.dart';
import 'schedule_planner_screen.dart';
import 'trip_hotels_screen.dart';
import 'trip_tickets_screen.dart';

class TripScheduleScreen extends StatefulWidget {
  final SavedTrip trip;

  const TripScheduleScreen({super.key, required this.trip});

  @override
  State<TripScheduleScreen> createState() => _TripScheduleScreenState();
}

class _TripScheduleScreenState extends State<TripScheduleScreen> {
  final ApiService _apiService = ApiService();
  FullSchedule? _schedule;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final schedule = await _apiService.getTripSchedule(
        token: token,
        tripId: widget.trip.id,
      );
      if (mounted) {
        setState(() {
          _schedule = schedule;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteItem(ScheduleItem item) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    try {
      await _apiService.deleteScheduleItem(
        token: token,
        tripId: widget.trip.id,
        itemId: item.id,
      );
      _loadSchedule();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove item: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  _buildAppBar(context),
                  Expanded(child: _buildBody()),
                ],
              ),
            ),
          ),
        ),
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
          Expanded(
            child: Text(
              'Schedule',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          GestureDetector(
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => SchedulePlannerScreen(trip: widget.trip)),
              );
              _loadSchedule();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppTheme.primaryColor, const Color(0xFF8B5CF6)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.edit_calendar_rounded, size: 16, color: Colors.white),
                  const SizedBox(width: 4),
                  Text('Plan', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                'Failed to load schedule',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _loadSchedule,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_schedule == null || _schedule!.days.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_today_rounded, size: 48, color: AppTheme.primaryColor.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text(
                'No schedule yet',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add attractions and restaurants to your trip to see them here.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSchedule,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: _schedule!.days.length,
        itemBuilder: (context, index) => _buildDayCard(_schedule!.days[index], index),
      ),
    );
  }

  Widget _buildDayCard(ScheduleDay day, int dayIndex) {
    final date = DateTime.tryParse(day.date);
    final dayLabel = date != null ? DateFormat('EEEE, MMM d').format(date) : day.date;
    final dayNumber = 'Day ${dayIndex + 1}';

    // Group items by time slot
    final slotOrder = ['morning', 'midday', 'evening', 'night'];
    final groupedItems = <String, List<ScheduleItem>>{};
    for (final slot in slotOrder) {
      final items = day.items.where((i) => i.timeSlot == slot).toList();
      if (items.isNotEmpty) {
        groupedItems[slot] = items;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryColor, const Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    dayNumber,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  dayLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Time slots
          if (groupedItems.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  'No activities planned',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            )
          else
            ...groupedItems.entries.map((entry) => _buildTimeSlotSection(entry.key, entry.value)),
        ],
      ),
    );
  }

  Widget _buildTimeSlotSection(String slot, List<ScheduleItem> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Slot header
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 6),
            child: Row(
              children: [
                Icon(
                  _getSlotIcon(slot),
                  size: 16,
                  color: _getSlotColor(slot),
                ),
                const SizedBox(width: 6),
                Text(
                  _getSlotLabel(slot),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _getSlotColor(slot),
                  ),
                ),
              ],
            ),
          ),
          // Items
          ...items.map((item) => _buildScheduleItemCard(item)),
        ],
      ),
    );
  }

  Widget _buildScheduleItemCard(ScheduleItem item) {
    final hasTime = _itemHasTime(item);

    return Dismissible(
      key: Key(item.id.isNotEmpty ? item.id : '${item.dayDate}_${item.timeSlot}_${item.title}'),
      direction: item.isAuto ? DismissDirection.none : DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Remove item'),
            content: Text('Remove "${item.title}" from the schedule?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove')),
            ],
          ),
        );
      },
      onDismissed: (_) => _deleteItem(item),
      child: GestureDetector(
        onTap: () => _onScheduleItemTap(item),
        onLongPress: () => _onScheduleItemLongPress(item),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: item.isAuto
                ? Border.all(color: _getItemTypeColor(item.itemType).withOpacity(0.3))
                : null,
            boxShadow: [
              BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Type icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getItemTypeColor(item.itemType).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getItemTypeIcon(item.itemType),
                size: 20,
                color: _getItemTypeColor(item.itemType),
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // Time indicator (only for items with a specific time)
            if (hasTime) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getItemTypeColor(item.itemType).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _extractTime(item),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: _getItemTypeColor(item.itemType),
                  ),
                ),
              ),
            ],
            // Auto badge
            if (item.isAuto) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.lock_outline_rounded,
                size: 14,
                color: AppTheme.textSecondary.withOpacity(0.5),
              ),
            ],
          ],
        ),
      ),
      ),
    );
  }

  void _onScheduleItemTap(ScheduleItem item) {
    final type = item.itemType.toLowerCase();

    // Attractions & restaurants → detail page
    if ((type == 'attraction' || type == 'restaurant') && item.referenceId.isNotEmpty) {
      if (type == 'attraction') {
        String startDate = '';
        String endDate = '';
        if (widget.trip.outboundFlight != null) {
          try {
            final dt = DateTime.parse(widget.trip.outboundFlight!.arrivalTime.replaceAll(' ', 'T'));
            startDate = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
          } catch (_) {}
        }
        if (widget.trip.returnFlight != null) {
          try {
            final dt = DateTime.parse(widget.trip.returnFlight!.departureTime.replaceAll(' ', 'T'));
            endDate = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
          } catch (_) {}
        }
        if (startDate.isEmpty) startDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
        if (endDate.isEmpty) endDate = DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 7)));

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AttractionDetailScreen(
              contentId: item.referenceId,
              startDate: startDate,
              endDate: endDate,
              trip: widget.trip,
            ),
          ),
        );
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RestaurantDetailScreen(
              contentId: item.referenceId,
              trip: widget.trip,
            ),
          ),
        );
      }
      return;
    }

    // Flights & buses → tickets screen
    if (type == 'flight' || type == 'bus' || type == 'transit') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TripTicketsScreen(trip: widget.trip),
        ),
      );
      return;
    }

    // Hotels → hotels screen
    if (type == 'hotel_checkin' || type == 'hotel_checkout') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TripHotelsScreen(trip: widget.trip),
        ),
      );
      return;
    }
  }

  void _onScheduleItemLongPress(ScheduleItem item) {
    final type = item.itemType.toLowerCase();
    if (type != 'attraction' && type != 'restaurant') return;
    if (item.referenceId.isEmpty) return;

    _showRescheduleSheet(item);
  }

  void _showRescheduleSheet(ScheduleItem item) {
    final days = _schedule?.days ?? [];
    if (days.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _RescheduleSheet(
        item: item,
        days: days,
        onConfirm: (dayDate, timeSlot) async {
          Navigator.pop(ctx);
          final token = context.read<AuthProvider>().token;
          if (token == null) return;
          try {
            final type = item.itemType.toLowerCase();
            if (type == 'attraction') {
              await _apiService.rescheduleAttraction(
                token: token, tripId: widget.trip.id, locationId: item.referenceId,
                dayDate: dayDate, timeSlot: timeSlot,
              );
            } else {
              await _apiService.rescheduleRestaurant(
                token: token, tripId: widget.trip.id, locationId: item.referenceId,
                dayDate: dayDate, timeSlot: timeSlot,
              );
            }
            _loadSchedule();
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to move: $e'), backgroundColor: Colors.red.shade600),
              );
            }
          }
        },
      ),
    );
  }

  bool _itemHasTime(ScheduleItem item) {
    // Flights, buses, and hotel check-in/check-out have specific times
    // Attractions and restaurants don't have a specific hour
    final type = item.itemType.toLowerCase();
    return type == 'flight' || type == 'bus' || type == 'hotel_checkin' || type == 'hotel_checkout' || type == 'transit';
  }

  String _extractTime(ScheduleItem item) {
    // Try to extract time from subtitle (e.g., "10:45 → 14:30 (4h 45m)")
    final subtitle = item.subtitle;
    final timeRegex = RegExp(r'(\d{1,2}:\d{2})');
    final match = timeRegex.firstMatch(subtitle);
    if (match != null) {
      return match.group(1)!;
    }
    return '';
  }

  String _getSlotLabel(String slot) {
    switch (slot) {
      case 'morning':
        return 'Morning';
      case 'midday':
        return 'Midday';
      case 'evening':
        return 'Evening';
      case 'night':
        return 'Night';
      default:
        return slot;
    }
  }

  IconData _getSlotIcon(String slot) {
    switch (slot) {
      case 'morning':
        return Icons.wb_sunny_rounded;
      case 'midday':
        return Icons.light_mode_rounded;
      case 'evening':
        return Icons.wb_twilight_rounded;
      case 'night':
        return Icons.nightlight_round;
      default:
        return Icons.schedule_rounded;
    }
  }

  Color _getSlotColor(String slot) {
    switch (slot) {
      case 'morning':
        return const Color(0xFFF59E0B);
      case 'midday':
        return const Color(0xFFEF6C00);
      case 'evening':
        return const Color(0xFF7C3AED);
      case 'night':
        return const Color(0xFF1E3A5F);
      default:
        return AppTheme.textSecondary;
    }
  }

  IconData _getItemTypeIcon(String itemType) {
    switch (itemType.toLowerCase()) {
      case 'flight':
        return Icons.flight_rounded;
      case 'bus':
      case 'transit':
        return Icons.directions_bus_rounded;
      case 'hotel_checkin':
        return Icons.login_rounded;
      case 'hotel_checkout':
        return Icons.logout_rounded;
      case 'attraction':
        return Icons.attractions_rounded;
      case 'restaurant':
        return Icons.restaurant_rounded;
      default:
        return Icons.event_rounded;
    }
  }

  Color _getItemTypeColor(String itemType) {
    switch (itemType.toLowerCase()) {
      case 'flight':
        return const Color(0xFF2196F3);
      case 'bus':
      case 'transit':
        return const Color(0xFF4CAF50);
      case 'hotel_checkin':
      case 'hotel_checkout':
        return const Color(0xFFFF9800);
      case 'attraction':
        return const Color(0xFFFF5722);
      case 'restaurant':
        return const Color(0xFF795548);
      default:
        return AppTheme.primaryColor;
    }
  }
}

// ─── Reschedule Bottom Sheet ─────────────────────────────────────────────

class _RescheduleSheet extends StatefulWidget {
  final ScheduleItem item;
  final List<ScheduleDay> days;
  final Future<void> Function(String dayDate, String timeSlot) onConfirm;

  const _RescheduleSheet({
    required this.item,
    required this.days,
    required this.onConfirm,
  });

  @override
  State<_RescheduleSheet> createState() => _RescheduleSheetState();
}

class _RescheduleSheetState extends State<_RescheduleSheet> {
  late String _selectedDate;
  late String _selectedSlot;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.item.dayDate;
    _selectedSlot = widget.item.timeSlot;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24, right: 24, top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 20),
          Text('Move "${widget.item.title}"', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 16),
          Text('Day', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.days.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final day = widget.days[index];
                final isSelected = day.date == _selectedDate;
                DateTime? dt;
                try { dt = DateTime.parse(day.date); } catch (_) {}
                return GestureDetector(
                  onTap: () => setState(() => _selectedDate = day.date),
                  child: Container(
                    width: 52,
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryColor : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(dt != null ? DateFormat('EEE').format(dt) : '', style: GoogleFonts.poppins(fontSize: 10, color: isSelected ? Colors.white70 : AppTheme.textSecondary)),
                        Text(dt != null ? DateFormat('d').format(dt) : day.date, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : AppTheme.textPrimary)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Text('Time slot', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['morning', 'midday', 'evening', 'night'].map((slot) {
              final isSelected = _selectedSlot == slot;
              return ChoiceChip(
                label: Text(slot[0].toUpperCase() + slot.substring(1)),
                selected: isSelected,
                onSelected: (_) => setState(() => _selectedSlot = slot),
                selectedColor: AppTheme.primaryColor,
                labelStyle: GoogleFonts.poppins(fontSize: 13, color: isSelected ? Colors.white : AppTheme.textPrimary),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : () async {
                setState(() => _saving = true);
                await widget.onConfirm(_selectedDate, _selectedSlot);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Move', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
