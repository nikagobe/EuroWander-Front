class ScheduleItem {
  final String id;
  final String dayDate;
  final String timeSlot;
  final String itemType;
  final String title;
  final String subtitle;
  final String referenceId;
  final bool isAuto;
  final int order;

  ScheduleItem({
    required this.id,
    required this.dayDate,
    required this.timeSlot,
    required this.itemType,
    required this.title,
    required this.subtitle,
    required this.referenceId,
    required this.isAuto,
    required this.order,
  });

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    return ScheduleItem(
      id: json['id'] ?? '',
      dayDate: json['day_date'] ?? '',
      timeSlot: json['time_slot'] ?? '',
      itemType: json['item_type'] ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      referenceId: json['reference_id'] ?? '',
      isAuto: json['is_auto'] == true,
      order: json['order'] ?? 0,
    );
  }
}

class ScheduleDay {
  final String date;
  final List<ScheduleItem> items;

  ScheduleDay({
    required this.date,
    required this.items,
  });

  factory ScheduleDay.fromJson(Map<String, dynamic> json) {
    return ScheduleDay(
      date: json['date'] ?? '',
      items: (json['items'] as List?)
              ?.map((item) => ScheduleItem.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class FullSchedule {
  final String tripId;
  final List<ScheduleDay> days;

  FullSchedule({
    required this.tripId,
    required this.days,
  });

  factory FullSchedule.fromJson(Map<String, dynamic> json) {
    return FullSchedule(
      tripId: json['trip_id'] ?? '',
      days: (json['days'] as List?)
              ?.map((day) => ScheduleDay.fromJson(day))
              .toList() ??
          [],
    );
  }
}
