class Trip {
  final String? id;
  final String title;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final String? description;
  final String? imageUrl;

  Trip({
    this.id,
    required this.title,
    required this.destination,
    required this.startDate,
    required this.endDate,
    this.description,
    this.imageUrl,
  });

  int get durationInDays => endDate.difference(startDate).inDays + 1;

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] as String?,
      title: json['title'] as String,
      destination: json['destination'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'destination': destination,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      if (description != null) 'description': description,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }
}
