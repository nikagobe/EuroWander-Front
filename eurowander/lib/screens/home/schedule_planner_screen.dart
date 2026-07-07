import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/saved_trip.dart';
import '../../models/schedule.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class SchedulePlannerScreen extends StatefulWidget {
  final SavedTrip trip;

  const SchedulePlannerScreen({super.key, required this.trip});

  @override
  State<SchedulePlannerScreen> createState() => _SchedulePlannerScreenState();
}

class _SchedulePlannerScreenState extends State<SchedulePlannerScreen> {
  final ApiService _apiService = ApiService();
  late SavedTrip _trip;
  FullSchedule? _schedule;
  bool _isLoading = true;
  int _selectedDayIndex = 0;

  @override
  void initState() {
    super.initState();
    _trip = widget.trip;
    _loadData();
  }

  Future<void> _loadData() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    setState(() => _isLoading = true);
    try {
      final trips = await _apiService.getTrips(token: token);
      final updated = trips.where((t) => t.id == _trip.id).firstOrNull;
      if (updated != null) _trip = updated;

      final schedule = await _apiService.getTripSchedule(token: token, tripId: _trip.id);
      if (mounted) {
        setState(() {
          _schedule = schedule;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _rescheduleAttraction(SavedAttraction attraction, String dayDate, String timeSlot) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    try {
      final updated = await _apiService.rescheduleAttraction(
        token: token,
        tripId: _trip.id,
        locationId: attraction.locationId,
        dayDate: dayDate,
        timeSlot: timeSlot,
      );
      setState(() => _trip = updated);
      _reloadSchedule();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to move: $e'), backgroundColor: Colors.red.shade600),
        );
      }
    }
  }

  Future<void> _rescheduleRestaurant(SavedRestaurant restaurant, String dayDate, String timeSlot) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    try {
      final updated = await _apiService.rescheduleRestaurant(
        token: token,
        tripId: _trip.id,
        locationId: restaurant.locationId,
        dayDate: dayDate,
        timeSlot: timeSlot,
      );
      setState(() => _trip = updated);
      _reloadSchedule();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to move: $e'), backgroundColor: Colors.red.shade600),
        );
      }
    }
  }

  Future<void> _reloadSchedule() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    try {
      final schedule = await _apiService.getTripSchedule(token: token, tripId: _trip.id);
      if (mounted) setState(() => _schedule = schedule);
    } catch (_) {}
  }

  List<DateTime> get _tripDays {
    if (_schedule == null || _schedule!.days.isEmpty) return [];
    return _schedule!.days.map((d) {
      try {
        return DateTime.parse(d.date);
      } catch (_) {
        return DateTime.now();
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF8F5FF), Color(0xFFEDE7F6), Color(0xFFF3E5F5)],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
              : Column(
                  children: [
                    _buildAppBar(),
                    _buildDaySelector(),
                    Expanded(child: _buildPlannerBody()),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
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
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppTheme.textPrimary),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Plan Schedule',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector() {
    final days = _tripDays;
    if (days.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected = index == _selectedDayIndex;
          return GestureDetector(
            onTap: () => setState(() => _selectedDayIndex = index),
            child: Container(
              width: 60,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: isSelected
                    ? [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE').format(day),
                    style: GoogleFonts.poppins(fontSize: 11, color: isSelected ? Colors.white70 : AppTheme.textSecondary),
                  ),
                  Text(
                    DateFormat('d').format(day),
                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : AppTheme.textPrimary),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlannerBody() {
    if (_schedule == null || _schedule!.days.isEmpty) {
      return Center(
        child: Text('No schedule data', style: GoogleFonts.poppins(color: AppTheme.textSecondary)),
      );
    }

    final currentDay = _schedule!.days[_selectedDayIndex];
    final dayDate = currentDay.date;
    final slots = ['morning', 'midday', 'evening', 'night'];

    return Column(
      children: [
        const SizedBox(height: 12),
        // Unscheduled items (draggable source)
        _buildUnscheduledPanel(dayDate),
        const SizedBox(height: 8),
        // Schedule slots (drop targets)
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: slots.map((slot) => _buildSlotDropZone(dayDate, slot, currentDay)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildUnscheduledPanel(String dayDate) {
    // Items that are on this day but could be moved, or items from other days user might want to move here
    final unscheduledAttractions = _trip.attractions.where((a) => a.dayDate == dayDate).toList();
    final unscheduledRestaurants = _trip.restaurants.where((r) => r.dayDate == dayDate).toList();
    final allOnDay = [...unscheduledAttractions.map((a) => _DragItem(type: 'attraction', id: a.locationId, name: a.name, icon: Icons.attractions_rounded, color: const Color(0xFFFF5722))),
                      ...unscheduledRestaurants.map((r) => _DragItem(type: 'restaurant', id: r.locationId, name: r.name, icon: Icons.restaurant_rounded, color: const Color(0xFF795548)))];

    // Also show items from other days that can be moved
    final otherAttractions = _trip.attractions.where((a) => a.dayDate != dayDate).toList();
    final otherRestaurants = _trip.restaurants.where((r) => r.dayDate != dayDate).toList();
    final otherItems = [...otherAttractions.map((a) => _DragItem(type: 'attraction', id: a.locationId, name: a.name, icon: Icons.attractions_rounded, color: const Color(0xFFFF5722), fromOtherDay: true)),
                        ...otherRestaurants.map((r) => _DragItem(type: 'restaurant', id: r.locationId, name: r.name, icon: Icons.restaurant_rounded, color: const Color(0xFF795548), fromOtherDay: true))];

    final allItems = [...allOnDay, ...otherItems];
    if (allItems.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.drag_indicator_rounded, size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 6),
              Text('Drag items to a time slot', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textSecondary)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: allItems.map((item) => _buildDraggableChip(item)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggableChip(_DragItem item) {
    return Draggable<_DragItem>(
      data: item,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: item.color,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, size: 14, color: Colors.white),
              const SizedBox(width: 6),
              Text(item.name, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.4,
        child: _buildChipContent(item),
      ),
      child: _buildChipContent(item),
    );
  }

  Widget _buildChipContent(_DragItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: item.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: item.color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(item.icon, size: 14, color: item.color),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: Text(
              item.name,
              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: item.color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (item.fromOtherDay) ...[
            const SizedBox(width: 4),
            Icon(Icons.open_in_new_rounded, size: 10, color: item.color),
          ],
        ],
      ),
    );
  }

  Widget _buildSlotDropZone(String dayDate, String slot, ScheduleDay currentDay) {
    final slotItems = currentDay.items.where((i) => i.timeSlot == slot).toList();

    return DragTarget<_DragItem>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) {
        final item = details.data;
        if (item.type == 'attraction') {
          final attraction = _trip.attractions.firstWhere((a) => a.locationId == item.id);
          _rescheduleAttraction(attraction, dayDate, slot);
        } else {
          final restaurant = _trip.restaurants.firstWhere((r) => r.locationId == item.id);
          _rescheduleRestaurant(restaurant, dayDate, slot);
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isHovering ? AppTheme.primaryColor.withOpacity(0.08) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isHovering ? AppTheme.primaryColor : Colors.grey.shade200,
              width: isHovering ? 2 : 1,
            ),
            boxShadow: [
              if (!isHovering) BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Slot header
              Row(
                children: [
                  Icon(_getSlotIcon(slot), size: 16, color: _getSlotColor(slot)),
                  const SizedBox(width: 6),
                  Text(
                    _getSlotLabel(slot),
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: _getSlotColor(slot)),
                  ),
                  if (isHovering) ...[
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('Drop here', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.primaryColor)),
                    ),
                  ],
                ],
              ),
              if (slotItems.isNotEmpty) ...[
                const SizedBox(height: 8),
                ...slotItems.map((item) => _buildScheduleItemTile(item)),
              ] else ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
                  ),
                  child: Center(
                    child: Text(
                      'Empty — drag items here',
                      style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade400),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildScheduleItemTile(ScheduleItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _getItemColor(item.itemType).withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(_getItemIcon(item.itemType), size: 16, color: _getItemColor(item.itemType)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.title,
              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (item.isAuto)
            Icon(Icons.lock_outline_rounded, size: 12, color: AppTheme.textSecondary.withOpacity(0.5)),
        ],
      ),
    );
  }

  String _getSlotLabel(String slot) {
    switch (slot) {
      case 'morning': return 'Morning';
      case 'midday': return 'Midday';
      case 'evening': return 'Evening';
      case 'night': return 'Night';
      default: return slot;
    }
  }

  IconData _getSlotIcon(String slot) {
    switch (slot) {
      case 'morning': return Icons.wb_sunny_rounded;
      case 'midday': return Icons.light_mode_rounded;
      case 'evening': return Icons.wb_twilight_rounded;
      case 'night': return Icons.nightlight_round;
      default: return Icons.schedule_rounded;
    }
  }

  Color _getSlotColor(String slot) {
    switch (slot) {
      case 'morning': return const Color(0xFFF59E0B);
      case 'midday': return const Color(0xFFEF6C00);
      case 'evening': return const Color(0xFF7C3AED);
      case 'night': return const Color(0xFF1E3A5F);
      default: return AppTheme.textSecondary;
    }
  }

  IconData _getItemIcon(String itemType) {
    switch (itemType.toLowerCase()) {
      case 'flight': return Icons.flight_rounded;
      case 'bus':
      case 'transit': return Icons.directions_bus_rounded;
      case 'hotel_checkin': return Icons.login_rounded;
      case 'hotel_checkout': return Icons.logout_rounded;
      case 'attraction': return Icons.attractions_rounded;
      case 'restaurant': return Icons.restaurant_rounded;
      default: return Icons.event_rounded;
    }
  }

  Color _getItemColor(String itemType) {
    switch (itemType.toLowerCase()) {
      case 'flight': return const Color(0xFF2196F3);
      case 'bus':
      case 'transit': return const Color(0xFF4CAF50);
      case 'hotel_checkin':
      case 'hotel_checkout': return const Color(0xFFFF9800);
      case 'attraction': return const Color(0xFFFF5722);
      case 'restaurant': return const Color(0xFF795548);
      default: return AppTheme.primaryColor;
    }
  }
}

class _DragItem {
  final String type;
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final bool fromOtherDay;

  _DragItem({
    required this.type,
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.fromOtherDay = false,
  });
}
