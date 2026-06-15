class TripPhoto {
  final String id;
  final String tripId;
  final String uploadedBy;
  final String fileName;
  final String contentType;
  final int sizeBytes;
  final String? caption;
  final DateTime createdAt;

  TripPhoto({
    required this.id,
    required this.tripId,
    required this.uploadedBy,
    required this.fileName,
    required this.contentType,
    required this.sizeBytes,
    this.caption,
    required this.createdAt,
  });

  factory TripPhoto.fromJson(Map<String, dynamic> json) {
    return TripPhoto(
      id: json['id'] ?? '',
      tripId: json['trip_id'] ?? '',
      uploadedBy: json['uploaded_by'] ?? '',
      fileName: json['file_name'] ?? '',
      contentType: json['content_type'] ?? '',
      sizeBytes: json['size_bytes'] ?? 0,
      caption: json['caption'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class PaginatedPhotos {
  final List<TripPhoto> items;
  final int total;
  final int skip;
  final int limit;
  final bool hasMore;

  PaginatedPhotos({
    required this.items,
    required this.total,
    required this.skip,
    required this.limit,
    required this.hasMore,
  });

  factory PaginatedPhotos.fromJson(Map<String, dynamic> json) {
    return PaginatedPhotos(
      items: (json['items'] as List).map((e) => TripPhoto.fromJson(e)).toList(),
      total: json['total'] ?? 0,
      skip: json['skip'] ?? 0,
      limit: json['limit'] ?? 20,
      hasMore: json['has_more'] ?? false,
    );
  }
}
