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

  Future<void> _reloadSchedule() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    try {
      final trips = await _apiService.getTrips(token: token);
      final updated = trips.where((t) => t.id == _trip.id).firstOrNull;
      if (updated != null) _trip = updated;

      final schedule = await _apiService.getTripSchedule(token: token, tripId: _trip.id);
      if (mounted) setState(() => _schedule = schedule);
    } catch (_) {}
  }

  Future<void> _rescheduleItem(ScheduleItem item, String dayDate, String timeSlot, {int? order}) async {
    // Optimistic UI: move item locally first
    _moveItemLocally(item, dayDate, timeSlot, order: order);

    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    final type = item.itemType.toLowerCase();
    try {
      if (type == 'attraction') {
        await _apiService.rescheduleAttraction(
          token: token, tripId: _trip.id, locationId: item.referenceId,
          dayDate: dayDate, timeSlot: timeSlot,
        );
      } else if (type == 'restaurant') {
        await _apiService.rescheduleRestaurant(
          token: token, tripId: _trip.id, locationId: item.referenceId,
          dayDate: dayDate, timeSlot: timeSlot,
        );
      } else if (!item.isAuto && item.id.isNotEmpty) {
        await _apiService.updateScheduleItem(
          token: token, tripId: _trip.id, itemId: item.id,
          dayDate: dayDate, timeSlot: timeSlot, order: order,
        );
      }
      // Background refresh to get server state
      _reloadSchedule();
    } catch (e) {
      // Revert on failure
      await _reloadSchedule();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to move: $e'), backgroundColor: Colors.red.shade600),
        );
      }
    }
  }

  void _moveItemLocally(ScheduleItem item, String newDayDate, String newTimeSlot, {int? order}) {
    if (_schedule == null) return;
    setState(() {
      // Remove from old location
      for (final day in _schedule!.days) {
        day.items.removeWhere((i) => i.id == item.id && i.title == item.title && i.referenceId == item.referenceId && i.timeSlot == item.timeSlot && i.dayDate == item.dayDate);
      }
      // Add to new location
      final movedItem = ScheduleItem(
        id: item.id, dayDate: newDayDate, timeSlot: newTimeSlot,
        itemType: item.itemType, title: item.title, subtitle: item.subtitle,
        referenceId: item.referenceId, isAuto: item.isAuto, order: order ?? 0,
      );
      for (final day in _schedule!.days) {
        if (day.date == newDayDate) {
          if (order != null) {
            final slotItems = day.items.where((i) => i.timeSlot == newTimeSlot).toList();
            final insertAt = order.clamp(0, slotItems.length);
            // Find actual index in the full items list
            int actualIndex = 0;
            int slotCount = 0;
            for (int i = 0; i < day.items.length; i++) {
              if (day.items[i].timeSlot == newTimeSlot) {
                if (slotCount == insertAt) { actualIndex = i; break; }
                slotCount++;
                actualIndex = i + 1;
              }
            }
            day.items.insert(actualIndex, movedItem);
          } else {
            day.items.add(movedItem);
          }
          break;
        }
      }
    });
  }

  Future<void> _reorderWithinSlot(String dayDate, String slot, int oldIndex, int newIndex) async {
    if (_schedule == null) return;
    if (newIndex > oldIndex) newIndex--;

    // Get items in this slot
    final day = _schedule!.days.firstWhere((d) => d.date == dayDate);
    final slotItems = day.items.where((i) => i.timeSlot == slot).toList();
    if (oldIndex >= slotItems.length || newIndex >= slotItems.length) return;

    final item = slotItems[oldIndex];

    // Optimistic reorder locally
    setState(() {
      final allSlotIndices = <int>[];
      for (int i = 0; i < day.items.length; i++) {
        if (day.items[i].timeSlot == slot) allSlotIndices.add(i);
      }
      if (oldIndex < allSlotIndices.length && newIndex < allSlotIndices.length) {
        final removed = day.items.removeAt(allSlotIndices[oldIndex]);
        final newActualIndex = newIndex <= oldIndex
            ? allSlotIndices[newIndex]
            : allSlotIndices[newIndex] - 1;
        day.items.insert(newActualIndex.clamp(0, day.items.length), removed);
      }
    });

    // Sync with backend
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    final type = item.itemType.toLowerCase();
    try {
      if (!item.isAuto && item.id.isNotEmpty && type != 'attraction' && type != 'restaurant') {
        await _apiService.updateScheduleItem(
          token: token, tripId: _trip.id, itemId: item.id,
          order: newIndex,
        );
      }
    } catch (_) {}
  }

  Future<void> _duplicateItem(ScheduleItem item, String dayDate, String timeSlot) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    try {
      await _apiService.addScheduleItem(
        token: token,
        tripId: _trip.id,
        dayDate: dayDate,
        timeSlot: timeSlot,
        itemType: item.itemType,
        title: item.title,
        subtitle: item.subtitle,
        referenceId: item.referenceId,
      );
      await _reloadSchedule();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Duplicated "${item.title}"'), backgroundColor: Colors.green.shade600),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to duplicate: $e'), backgroundColor: Colors.red.shade600),
        );
      }
    }
  }

  Future<void> _deleteItem(ScheduleItem item) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    try {
      await _apiService.deleteScheduleItem(token: token, tripId: _trip.id, itemId: item.id);
      await _reloadSchedule();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove: $e'), backgroundColor: Colors.red.shade600),
        );
      }
    }
  }

  List<_UnscheduledItem> _getAllActivities() {
    // Get all reference_ids already in the schedule
    final scheduledIds = <String>{};
    if (_schedule != null) {
      for (final day in _schedule!.days) {
        for (final item in day.items) {
          if (item.referenceId.isNotEmpty) {
            scheduledIds.add(item.referenceId);
          }
        }
      }
    }

    final items = <_UnscheduledItem>[];
    for (final a in _trip.attractions) {
      if (scheduledIds.contains(a.locationId)) continue;
      items.add(_UnscheduledItem(
        type: 'attraction', id: a.locationId, name: a.name,
        subtitle: a.category, icon: Icons.attractions_rounded,
        color: const Color(0xFFFF5722), currentDay: a.dayDate, currentSlot: a.timeSlot,
      ));
    }
    for (final r in _trip.restaurants) {
      if (scheduledIds.contains(r.locationId)) continue;
      items.add(_UnscheduledItem(
        type: 'restaurant', id: r.locationId, name: r.name,
        subtitle: r.cuisine, icon: Icons.restaurant_rounded,
        color: const Color(0xFF795548), currentDay: r.dayDate, currentSlot: r.timeSlot,
      ));
    }
    return items;
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
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      children: [
                        _buildAppBar(),
                        Expanded(child: _buildScheduleList()),
                      ],
                    ),
                  ),
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
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppTheme.textPrimary),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text('Edit Schedule', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleList() {
    if (_schedule == null || _schedule!.days.isEmpty) {
      return Center(child: Text('No schedule data', style: GoogleFonts.poppins(color: AppTheme.textSecondary)));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: _schedule!.days.length,
      itemBuilder: (context, dayIndex) => _buildDaySection(_schedule!.days[dayIndex], dayIndex),
    );
  }

  Widget _buildDaySection(ScheduleDay day, int dayIndex) {
    final date = DateTime.tryParse(day.date);
    final dayLabel = date != null ? DateFormat('EEEE, MMM d').format(date) : day.date;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppTheme.primaryColor, const Color(0xFF8B5CF6)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                  child: Text('Day ${dayIndex + 1}', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
                const SizedBox(width: 10),
                Text(dayLabel, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ..._buildTimeSlots(day),
        ],
      ),
    );
  }

  List<Widget> _buildTimeSlots(ScheduleDay day) {
    const slots = ['morning', 'midday', 'evening', 'night'];
    return slots.where((slot) {
      return day.items.any((i) => i.timeSlot == slot);
    }).map((slot) {
      final slotItems = day.items.where((i) => i.timeSlot == slot).toList();
      return _buildSlotSection(day.date, slot, slotItems);
    }).toList();
  }

  Widget _buildSlotSection(String dayDate, String slot, List<ScheduleItem> items) {
    return DragTarget<_DragData>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) {
        final data = details.data;
        _rescheduleItem(data.item, dayDate, slot);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            color: isHovering ? AppTheme.primaryColor.withOpacity(0.06) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isHovering ? Border.all(color: AppTheme.primaryColor, width: 1.5) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Slot header — tap to add
              GestureDetector(
                onTap: () => _showAddToSlotSheet(dayDate, slot),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)],
                  ),
                  child: Row(
                    children: [
                      Icon(_getSlotIcon(slot), size: 16, color: _getSlotColor(slot)),
                      const SizedBox(width: 6),
                      Text(_getSlotLabel(slot), style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: _getSlotColor(slot))),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_rounded, size: 14, color: AppTheme.primaryColor),
                            const SizedBox(width: 2),
                            Text('Add', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryColor)),
                          ],
                        ),
                      ),
                      if (isHovering) ...[
                        const SizedBox(width: 8),
                        Text('Drop here', style: GoogleFonts.poppins(fontSize: 10, color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
                      ],
                    ],
                  ),
                ),
              ),
              // Items — reorderable within slot
              if (items.isNotEmpty)
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  itemCount: items.length,
                  onReorder: (oldIndex, newIndex) => _reorderWithinSlot(dayDate, slot, oldIndex, newIndex),
                  proxyDecorator: (child, index, animation) {
                    return Material(
                      elevation: 6,
                      borderRadius: BorderRadius.circular(10),
                      child: child,
                    );
                  },
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _buildItemTile(item, index, dayDate, slot, key: ValueKey('${dayDate}_${slot}_${item.id}_${item.title}_$index'));
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildItemTile(ScheduleItem item, int index, String dayDate, String slot, {required Key key}) {
    final isMovable = item.itemType.toLowerCase() == 'attraction' ||
                      item.itemType.toLowerCase() == 'restaurant' ||
                      !item.isAuto;

    if (!isMovable) {
      return Container(key: key, child: _buildItemContent(item, false, index));
    }

    return Draggable<_DragData>(
      key: key,
      data: _DragData(item: item),
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 240,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _getItemColor(item.itemType).withOpacity(0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_getItemIcon(item.itemType), size: 18, color: _getItemColor(item.itemType)),
              const SizedBox(width: 8),
              Flexible(child: Text(item.title, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildItemContent(item, isMovable, index),
      ),
      child: _buildItemContent(item, isMovable, index),
    );
  }

  Widget _buildItemContent(ScheduleItem item, bool isMovable, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _getItemColor(item.itemType).withOpacity(0.12)),
      ),
      child: Row(
        children: [
          // Reorder drag handle
          if (isMovable)
            ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(Icons.drag_indicator_rounded, size: 18, color: Colors.grey.shade400),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(Icons.lock_outline_rounded, size: 14, color: Colors.grey.shade300),
            ),
          // Icon
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: _getItemColor(item.itemType).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_getItemIcon(item.itemType), size: 16, color: _getItemColor(item.itemType)),
          ),
          const SizedBox(width: 10),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                if (item.subtitle.isNotEmpty)
                  Text(item.subtitle, style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          // Options menu
          if (isMovable)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded, size: 18, color: AppTheme.textSecondary),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (value) {
                if (value == 'edit_time') _showEditTimeSheet(item);
                else if (value == 'duplicate') _showDuplicateSheet(item);
                else if (value == 'remove') _deleteItem(item);
              },
              itemBuilder: (context) => [
                PopupMenuItem(value: 'edit_time', child: Row(children: [
                  Icon(Icons.schedule_rounded, size: 18, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Text('Edit time', style: GoogleFonts.poppins(fontSize: 13)),
                ])),
                PopupMenuItem(value: 'duplicate', child: Row(children: [
                  Icon(Icons.copy_rounded, size: 18, color: Colors.blue.shade600),
                  const SizedBox(width: 8),
                  Text('Duplicate', style: GoogleFonts.poppins(fontSize: 13)),
                ])),
                PopupMenuItem(value: 'remove', child: Row(children: [
                  Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red.shade600),
                  const SizedBox(width: 8),
                  Text('Remove', style: GoogleFonts.poppins(fontSize: 13, color: Colors.red.shade600)),
                ])),
              ],
            ),
        ],
      ),
    );
  }

  void _showAddToSlotSheet(String dayDate, String slot) {
    final items = _getAllActivities();
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No saved activities. Save attractions or restaurants first.'), backgroundColor: Colors.orange),
      );
      return;
    }

    final date = DateTime.tryParse(dayDate);
    final dayLabel = date != null ? DateFormat('MMM d').format(date) : dayDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 16),
                  Text('Add to $dayLabel • ${_getSlotLabel(slot)}', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('Tap to schedule or duplicate an activity', style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final isHere = item.currentDay == dayDate && item.currentSlot == slot;
                        return GestureDetector(
                          onTap: () async {
                            Navigator.pop(ctx);
                            final token = context.read<AuthProvider>().token;
                            if (token == null) return;
                            try {
                              if (isHere) {
                                // Duplicate
                                await _apiService.addScheduleItem(
                                  token: token, tripId: _trip.id,
                                  dayDate: dayDate, timeSlot: slot,
                                  itemType: item.type, title: item.name,
                                  subtitle: item.subtitle, referenceId: item.id,
                                );
                              } else {
                                // Move
                                if (item.type == 'attraction') {
                                  await _apiService.rescheduleAttraction(token: token, tripId: _trip.id, locationId: item.id, dayDate: dayDate, timeSlot: slot);
                                } else {
                                  await _apiService.rescheduleRestaurant(token: token, tripId: _trip.id, locationId: item.id, dayDate: dayDate, timeSlot: slot);
                                }
                              }
                              await _reloadSchedule();
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red.shade600));
                              }
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isHere ? item.color.withOpacity(0.4) : Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36, height: 36,
                                  decoration: BoxDecoration(color: item.color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                  child: Icon(item.icon, size: 18, color: item.color),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.name, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      Text(
                                        isHere ? 'Tap to duplicate here' : 'Currently: ${_formatDaySlot(item.currentDay, item.currentSlot)}',
                                        style: GoogleFonts.poppins(fontSize: 11, color: isHere ? item.color : AppTheme.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(isHere ? Icons.copy_rounded : Icons.add_circle_outline_rounded, size: 20, color: isHere ? item.color : AppTheme.primaryColor),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatDaySlot(String dayDate, String slot) {
    final dt = DateTime.tryParse(dayDate);
    final dayStr = dt != null ? DateFormat('MMM d').format(dt) : dayDate;
    return '$dayStr • ${_getSlotLabel(slot)}';
  }

  void _showEditTimeSheet(ScheduleItem item) {
    final days = _schedule?.days ?? [];
    if (days.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _EditTimeSheet(
        item: item, days: days,
        onConfirm: (dayDate, timeSlot) async {
          Navigator.pop(ctx);
          await _rescheduleItem(item, dayDate, timeSlot);
        },
      ),
    );
  }

  void _showDuplicateSheet(ScheduleItem item) {
    final days = _schedule?.days ?? [];
    if (days.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _EditTimeSheet(
        item: item, days: days, title: 'Duplicate to...', confirmLabel: 'Duplicate',
        onConfirm: (dayDate, timeSlot) async {
          Navigator.pop(ctx);
          await _duplicateItem(item, dayDate, timeSlot);
        },
      ),
    );
  }

  String _getSlotLabel(String slot) {
    switch (slot) { case 'morning': return 'Morning'; case 'midday': return 'Midday'; case 'evening': return 'Evening'; case 'night': return 'Night'; default: return slot; }
  }

  IconData _getSlotIcon(String slot) {
    switch (slot) { case 'morning': return Icons.wb_sunny_rounded; case 'midday': return Icons.light_mode_rounded; case 'evening': return Icons.wb_twilight_rounded; case 'night': return Icons.nightlight_round; default: return Icons.schedule_rounded; }
  }

  Color _getSlotColor(String slot) {
    switch (slot) { case 'morning': return const Color(0xFFF59E0B); case 'midday': return const Color(0xFFEF6C00); case 'evening': return const Color(0xFF7C3AED); case 'night': return const Color(0xFF1E3A5F); default: return AppTheme.textSecondary; }
  }

  IconData _getItemIcon(String t) {
    switch (t.toLowerCase()) { case 'flight': return Icons.flight_rounded; case 'bus': case 'transit': return Icons.directions_bus_rounded; case 'hotel_checkin': return Icons.login_rounded; case 'hotel_checkout': return Icons.logout_rounded; case 'attraction': return Icons.attractions_rounded; case 'restaurant': return Icons.restaurant_rounded; default: return Icons.event_rounded; }
  }

  Color _getItemColor(String t) {
    switch (t.toLowerCase()) { case 'flight': return const Color(0xFF2196F3); case 'bus': case 'transit': return const Color(0xFF4CAF50); case 'hotel_checkin': case 'hotel_checkout': return const Color(0xFFFF9800); case 'attraction': return const Color(0xFFFF5722); case 'restaurant': return const Color(0xFF795548); default: return AppTheme.primaryColor; }
  }
}

class _DragData {
  final ScheduleItem item;
  _DragData({required this.item});
}

class _UnscheduledItem {
  final String type, id, name, subtitle, currentDay, currentSlot;
  final IconData icon;
  final Color color;
  _UnscheduledItem({required this.type, required this.id, required this.name, required this.subtitle, required this.icon, required this.color, required this.currentDay, required this.currentSlot});
}

class _EditTimeSheet extends StatefulWidget {
  final ScheduleItem item;
  final List<ScheduleDay> days;
  final String title;
  final String confirmLabel;
  final Future<void> Function(String dayDate, String timeSlot) onConfirm;

  const _EditTimeSheet({required this.item, required this.days, required this.onConfirm, this.title = 'Move to...', this.confirmLabel = 'Move'});

  @override
  State<_EditTimeSheet> createState() => _EditTimeSheetState();
}

class _EditTimeSheetState extends State<_EditTimeSheet> {
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
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Text(widget.title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(widget.item.title, style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
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
                    decoration: BoxDecoration(color: isSelected ? AppTheme.primaryColor : Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
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
            spacing: 8, runSpacing: 8,
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
          SafeArea(
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : () async {
                  setState(() => _saving = true);
                  await widget.onConfirm(_selectedDate, _selectedSlot);
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: _saving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(widget.confirmLabel, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
