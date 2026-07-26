import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/widgets.dart';
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

  Future<void> _openDayOnMap(String dayDate) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    try {
      final result = await _apiService.getDayMapUrl(
        token: token,
        tripId: widget.trip.id,
        dayDate: dayDate,
      );
      final uri = Uri.parse(result.mapUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: Column(
        children: [
          EWAppBar(
            title: 'Schedule',
            trailing: [
              GestureDetector(
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => SchedulePlannerScreen(trip: widget.trip)),
                  );
                  _loadSchedule();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [AppColors.brandPrimary, const Color(0xFF8B5CF6)]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.edit_calendar_rounded, size: 16, color: Colors.white),
                      const SizedBox(width: AppSpacing.xxs),
                      Text('Plan', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Expanded(child: _buildBody()),
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
              const SizedBox(height: AppSpacing.md),
              Text(
                'Failed to load schedule',
                style: Theme.of(context).textTheme.titleMedium!,
              ),
              const SizedBox(height: AppSpacing.xs),
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
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.calendar_today_rounded, size: 32, color: AppColors.brandPrimary.withOpacity(0.6)),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'No schedule yet',
                style: Theme.of(context).textTheme.titleMedium!.copyWith(color: context.ew.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Add attractions and restaurants to your trip to see them here.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(color: context.ew.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSchedule,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        itemCount: _schedule!.days.length,
        itemBuilder: (context, index) => _buildDayCard(_schedule!.days[index], index),
      ),
    );
  }

  Widget _buildDayCard(ScheduleDay day, int dayIndex) {
    final ew = context.ew;
    final date = DateTime.tryParse(day.date);
    final dayLabel = date != null ? DateFormat('EEEE, MMM d').format(date) : day.date;
    final dayNumber = 'Day ${dayIndex + 1}';
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final isToday = day.date == today;
    final isPast = day.date.compareTo(today) < 0;
    final hasPlaces = day.items.any((i) => i.itemType == 'attraction' || i.itemType == 'restaurant');

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
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: isToday
                  ? const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)])
                  : isPast
                      ? LinearGradient(colors: [Colors.grey.shade400, Colors.grey.shade500])
                      : LinearGradient(colors: [AppColors.brandPrimary, const Color(0xFF8B5CF6)]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: (isToday ? AppColors.success : AppColors.brandPrimary).withOpacity(0.25),
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
                    isToday ? 'Today' : dayNumber,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    dayLabel,
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(color: Colors.white),
                  ),
                ),
                if (hasPlaces)
                  GestureDetector(
                    onTap: () => _openDayOnMap(day.date),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.map_rounded, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text('Map', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Timeline content
          if (groupedItems.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ew.cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.withOpacity(0.08)),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.event_available_rounded, size: 28, color: ew.textTertiary),
                    const SizedBox(height: 8),
                    Text(
                      'No activities planned',
                      style: TextStyle(fontSize: 13, color: ew.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Long-press items to reschedule',
                      style: TextStyle(fontSize: 11, color: ew.textTertiary),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: ew.cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.withOpacity(0.06)),
              ),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: groupedItems.entries.map((entry) => _buildTimeSlotSection(entry.key, entry.value)).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeSlotSection(String slot, List<ScheduleItem> items) {
    final ew = context.ew;
    final slotColor = _getSlotColor(slot);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Slot header
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
            child: Row(
              children: [
                Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    color: slotColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_getSlotIcon(slot), size: 13, color: slotColor),
                ),
                const SizedBox(width: 8),
                Text(
                  _getSlotLabel(slot),
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w700, color: slotColor),
                ),
                const SizedBox(width: 8),
                Expanded(child: Container(height: 1, color: slotColor.withOpacity(0.15))),
              ],
            ),
          ),
          // Items with timeline
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isLast = index == items.length - 1;
            return _buildTimelineItem(item, slotColor, isLast);
          }),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(ScheduleItem item, Color slotColor, bool isLast) {
    final ew = context.ew;
    final itemColor = _getItemTypeColor(item.itemType);
    final hasTime = _itemHasTime(item);

    return Dismissible(
      key: Key(item.id.isNotEmpty ? item.id : '${item.dayDate}_${item.timeSlot}_${item.title}'),
      direction: item.isAuto ? DismissDirection.none : DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8, left: 32),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(12),
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
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline connector
              SizedBox(
                width: 28,
                child: Column(
                  children: [
                    Container(
                      width: 10, height: 10,
                      decoration: BoxDecoration(
                        color: itemColor,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: itemColor.withOpacity(0.3), blurRadius: 4)],
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          decoration: BoxDecoration(
                            color: slotColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Card content
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ew.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: item.isAuto ? itemColor.withOpacity(0.2) : Colors.grey.withOpacity(0.08),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Type icon
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: itemColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(_getItemTypeIcon(item.itemType), size: 18, color: itemColor),
                      ),
                      const SizedBox(width: 10),
                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: Theme.of(context).textTheme.labelLarge!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (item.subtitle.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                item.subtitle,
                                style: TextStyle(fontSize: 11, color: ew.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Time chip
                      if (hasTime) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: itemColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _extractTime(item),
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: itemColor),
                          ),
                        ),
                      ],
                      // Auto indicator
                      if (item.isAuto) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.auto_awesome_rounded, size: 13, color: ew.textTertiary),
                      ],
                    ],
                  ),
                ),
              ),
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
        return context.ew.textSecondary;
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
        return AppColors.info;
      case 'bus':
      case 'transit':
        return AppColors.success;
      case 'hotel_checkin':
      case 'hotel_checkout':
        return AppColors.brandAmber;
      case 'attraction':
        return AppColors.restaurant;
      case 'restaurant':
        return const Color(0xFF795548);
      default:
        return AppColors.brandPrimary;
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
          const SizedBox(height: AppSpacing.lg),
          Text('Move "${widget.item.title}"', style: Theme.of(context).textTheme.titleMedium!, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: AppSpacing.md),
          Text('Day', style: Theme.of(context).textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.days.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
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
                      color: isSelected ? AppColors.brandPrimary : Colors.grey.shade100,
                      borderRadius: AppRadius.borderMd,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(dt != null ? DateFormat('EEE').format(dt) : '', style: Theme.of(context).textTheme.labelSmall!.copyWith(color: isSelected ? Colors.white70 : context.ew.textSecondary)),
                        Text(dt != null ? DateFormat('d').format(dt) : day.date, style: Theme.of(context).textTheme.titleMedium!.copyWith(color: isSelected ? Colors.white : context.ew.textPrimary)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Time slot', style: Theme.of(context).textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['morning', 'midday', 'evening', 'night'].map((slot) {
              final isSelected = _selectedSlot == slot;
              return ChoiceChip(
                label: Text(slot[0].toUpperCase() + slot.substring(1)),
                selected: isSelected,
                onSelected: (_) => setState(() => _selectedSlot = slot),
                selectedColor: AppColors.brandPrimary,
                labelStyle: Theme.of(context).textTheme.bodySmall!.copyWith(color: isSelected ? Colors.white : context.ew.textPrimary),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : () async {
                setState(() => _saving = true);
                await widget.onConfirm(_selectedDate, _selectedSlot);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.borderLg),
              ),
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Move', style: Theme.of(context).textTheme.titleMedium!),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
