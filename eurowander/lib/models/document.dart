class TripDocument {
  final String id;
  final String tripId;
  final String uploadedBy;
  final String fileName;
  final String contentType;
  final int sizeBytes;
  final String category;
  final String visibility;
  final String? name;
  final DateTime createdAt;

  TripDocument({
    required this.id,
    required this.tripId,
    required this.uploadedBy,
    required this.fileName,
    required this.contentType,
    required this.sizeBytes,
    required this.category,
    required this.visibility,
    this.name,
    required this.createdAt,
  });

  factory TripDocument.fromJson(Map<String, dynamic> json) {
    return TripDocument(
      id: json['id'] ?? '',
      tripId: json['trip_id'] ?? '',
      uploadedBy: json['uploaded_by'] ?? '',
      fileName: json['file_name'] ?? '',
      contentType: json['content_type'] ?? '',
      sizeBytes: json['size_bytes'] ?? 0,
      category: json['category'] ?? 'other',
      visibility: json['visibility'] ?? 'group',
      name: json['name'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  String get displayName => name ?? fileName;

  String get categoryLabel {
    switch (category) {
      case 'boarding_pass':
        return 'Boarding Pass';
      case 'hotel_confirmation':
        return 'Hotel Confirmation';
      case 'passport':
        return 'Passport';
      case 'visa':
        return 'Visa';
      case 'insurance':
        return 'Insurance';
      case 'ticket':
        return 'Ticket';
      default:
        return 'Other';
    }
  }

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
