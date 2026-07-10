enum PlaylistVibe {
  chill,
  adventure,
  cultural,
  foodie,
  nightlife,
  romantic,
  family,
  instagram,
  hiddenGems,
  luxury,
  backpacker,
  wellness;

  String get apiValue {
    switch (this) {
      case PlaylistVibe.hiddenGems:
        return 'hidden_gems';
      default:
        return name;
    }
  }

  static PlaylistVibe fromString(String value) {
    switch (value) {
      case 'hidden_gems':
        return PlaylistVibe.hiddenGems;
      default:
        return PlaylistVibe.values.firstWhere(
          (v) => v.name == value,
          orElse: () => PlaylistVibe.chill,
        );
    }
  }

  String get displayName {
    switch (this) {
      case PlaylistVibe.chill:
        return 'Chill';
      case PlaylistVibe.adventure:
        return 'Adventure';
      case PlaylistVibe.cultural:
        return 'Cultural';
      case PlaylistVibe.foodie:
        return 'Foodie';
      case PlaylistVibe.nightlife:
        return 'Nightlife';
      case PlaylistVibe.romantic:
        return 'Romantic';
      case PlaylistVibe.family:
        return 'Family';
      case PlaylistVibe.instagram:
        return 'Instagram';
      case PlaylistVibe.hiddenGems:
        return 'Hidden Gems';
      case PlaylistVibe.luxury:
        return 'Luxury';
      case PlaylistVibe.backpacker:
        return 'Backpacker';
      case PlaylistVibe.wellness:
        return 'Wellness';
    }
  }

  String get icon {
    switch (this) {
      case PlaylistVibe.chill:
        return '🧘';
      case PlaylistVibe.adventure:
        return '🏔️';
      case PlaylistVibe.cultural:
        return '🏛️';
      case PlaylistVibe.foodie:
        return '🍕';
      case PlaylistVibe.nightlife:
        return '🎶';
      case PlaylistVibe.romantic:
        return '💕';
      case PlaylistVibe.family:
        return '👨‍👩‍👧';
      case PlaylistVibe.instagram:
        return '📸';
      case PlaylistVibe.hiddenGems:
        return '💎';
      case PlaylistVibe.luxury:
        return '👑';
      case PlaylistVibe.backpacker:
        return '🎒';
      case PlaylistVibe.wellness:
        return '🧖';
    }
  }
}

enum BudgetTier {
  ultraBudget,
  budget,
  midRange,
  premium,
  luxury;

  String get apiValue {
    switch (this) {
      case BudgetTier.ultraBudget:
        return 'ultra_budget';
      case BudgetTier.midRange:
        return 'mid_range';
      default:
        return name;
    }
  }

  static BudgetTier fromString(String value) {
    switch (value) {
      case 'ultra_budget':
        return BudgetTier.ultraBudget;
      case 'mid_range':
        return BudgetTier.midRange;
      default:
        return BudgetTier.values.firstWhere(
          (v) => v.name == value,
          orElse: () => BudgetTier.budget,
        );
    }
  }

  String get displayName {
    switch (this) {
      case BudgetTier.ultraBudget:
        return 'Ultra Budget';
      case BudgetTier.budget:
        return 'Budget';
      case BudgetTier.midRange:
        return 'Mid-Range';
      case BudgetTier.premium:
        return 'Premium';
      case BudgetTier.luxury:
        return 'Luxury';
    }
  }

  String get icon {
    switch (this) {
      case BudgetTier.ultraBudget:
        return '🪙';
      case BudgetTier.budget:
        return '💰';
      case BudgetTier.midRange:
        return '💳';
      case BudgetTier.premium:
        return '💎';
      case BudgetTier.luxury:
        return '👑';
    }
  }
}

class PlaylistItem {
  final String itemType;
  final String name;
  final int dayNumber;
  final String timeSlot;
  final int order;
  final String locationId;
  final String category;
  final String photoUrl;
  final double latitude;
  final double longitude;
  final String address;
  final double rating;
  final int numReviews;
  final String priceIndicator;
  final String note;
  final int suggestedDurationMinutes;

  PlaylistItem({
    required this.itemType,
    required this.name,
    required this.dayNumber,
    required this.timeSlot,
    required this.order,
    this.locationId = '',
    this.category = '',
    this.photoUrl = '',
    this.latitude = 0,
    this.longitude = 0,
    this.address = '',
    this.rating = 0,
    this.numReviews = 0,
    this.priceIndicator = '',
    this.note = '',
    this.suggestedDurationMinutes = 60,
  });

  factory PlaylistItem.fromJson(Map<String, dynamic> json) {
    return PlaylistItem(
      itemType: json['item_type'] ?? '',
      name: json['name'] ?? '',
      dayNumber: json['day_number'] ?? 1,
      timeSlot: json['time_slot'] ?? 'morning',
      order: json['order'] ?? 0,
      locationId: json['location_id'] ?? '',
      category: json['category'] ?? '',
      photoUrl: json['photo_url'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      address: json['address'] ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      numReviews: json['num_reviews'] ?? 0,
      priceIndicator: json['price_indicator'] ?? '',
      note: json['note'] ?? '',
      suggestedDurationMinutes: json['suggested_duration_minutes'] ?? 60,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_type': itemType,
      'name': name,
      'day_number': dayNumber,
      'time_slot': timeSlot,
      'order': order,
      'location_id': locationId,
      'category': category,
      'photo_url': photoUrl,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'rating': rating,
      'num_reviews': numReviews,
      'price_indicator': priceIndicator,
      'note': note,
      'suggested_duration_minutes': suggestedDurationMinutes,
    };
  }

  PlaylistItem copyWith({
    String? itemType,
    String? name,
    int? dayNumber,
    String? timeSlot,
    int? order,
    String? locationId,
    String? category,
    String? photoUrl,
    double? latitude,
    double? longitude,
    String? address,
    double? rating,
    int? numReviews,
    String? priceIndicator,
    String? note,
    int? suggestedDurationMinutes,
  }) {
    return PlaylistItem(
      itemType: itemType ?? this.itemType,
      name: name ?? this.name,
      dayNumber: dayNumber ?? this.dayNumber,
      timeSlot: timeSlot ?? this.timeSlot,
      order: order ?? this.order,
      locationId: locationId ?? this.locationId,
      category: category ?? this.category,
      photoUrl: photoUrl ?? this.photoUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      rating: rating ?? this.rating,
      numReviews: numReviews ?? this.numReviews,
      priceIndicator: priceIndicator ?? this.priceIndicator,
      note: note ?? this.note,
      suggestedDurationMinutes: suggestedDurationMinutes ?? this.suggestedDurationMinutes,
    );
  }
}

class Playlist {
  final String id;
  final String creatorId;
  final String creatorFirstName;
  final String creatorLastName;
  final String city;
  final String country;
  final String title;
  final String description;
  final String coverPhotoUrl;
  final String vibe;
  final String budgetTier;
  final List<PlaylistItem> items;
  final List<String> tags;
  final int totalDays;
  final bool isPublic;
  final int likeCount;
  final int importCount;
  final int reviewCount;
  final double averageRating;
  final String createdAt;
  final String updatedAt;
  final bool isLikedByMe;

  Playlist({
    required this.id,
    required this.creatorId,
    this.creatorFirstName = '',
    this.creatorLastName = '',
    required this.city,
    required this.country,
    required this.title,
    this.description = '',
    this.coverPhotoUrl = '',
    required this.vibe,
    required this.budgetTier,
    this.items = const [],
    this.tags = const [],
    required this.totalDays,
    this.isPublic = true,
    this.likeCount = 0,
    this.importCount = 0,
    this.reviewCount = 0,
    this.averageRating = 0,
    this.createdAt = '',
    this.updatedAt = '',
    this.isLikedByMe = false,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] ?? '',
      creatorId: json['creator_id'] ?? '',
      creatorFirstName: json['creator_first_name'] ?? '',
      creatorLastName: json['creator_last_name'] ?? '',
      city: json['city'] ?? '',
      country: json['country'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      coverPhotoUrl: json['cover_photo_url'] ?? '',
      vibe: json['vibe'] ?? 'chill',
      budgetTier: json['budget_tier'] ?? 'budget',
      items: (json['items'] as List?)
              ?.map((item) => PlaylistItem.fromJson(item))
              .toList() ??
          [],
      tags: (json['tags'] as List?)?.map((t) => t.toString()).toList() ?? [],
      totalDays: json['total_days'] ?? 1,
      isPublic: json['is_public'] ?? true,
      likeCount: json['like_count'] ?? 0,
      importCount: json['import_count'] ?? 0,
      reviewCount: json['review_count'] ?? 0,
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      isLikedByMe: json['is_liked_by_me'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'city': city,
      'country': country,
      'title': title,
      'description': description,
      'cover_photo_url': coverPhotoUrl,
      'vibe': vibe,
      'budget_tier': budgetTier,
      'items': items.map((i) => i.toJson()).toList(),
      'tags': tags,
      'total_days': totalDays,
      'is_public': isPublic,
    };
  }
}

class PlaylistSummary {
  final String id;
  final String creatorId;
  final String creatorFirstName;
  final String creatorLastName;
  final String city;
  final String country;
  final String title;
  final String description;
  final String coverPhotoUrl;
  final String vibe;
  final String budgetTier;
  final int totalDays;
  final int itemCount;
  final int likeCount;
  final int importCount;
  final int reviewCount;
  final double averageRating;
  final List<String> tags;

  PlaylistSummary({
    required this.id,
    required this.creatorId,
    this.creatorFirstName = '',
    this.creatorLastName = '',
    required this.city,
    required this.country,
    required this.title,
    this.description = '',
    this.coverPhotoUrl = '',
    required this.vibe,
    required this.budgetTier,
    required this.totalDays,
    this.itemCount = 0,
    this.likeCount = 0,
    this.importCount = 0,
    this.reviewCount = 0,
    this.averageRating = 0,
    this.tags = const [],
  });

  factory PlaylistSummary.fromJson(Map<String, dynamic> json) {
    return PlaylistSummary(
      id: json['id'] ?? '',
      creatorId: json['creator_id'] ?? '',
      creatorFirstName: json['creator_first_name'] ?? '',
      creatorLastName: json['creator_last_name'] ?? '',
      city: json['city'] ?? '',
      country: json['country'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      coverPhotoUrl: json['cover_photo_url'] ?? '',
      vibe: json['vibe'] ?? 'chill',
      budgetTier: json['budget_tier'] ?? 'budget',
      totalDays: json['total_days'] ?? 1,
      itemCount: json['item_count'] ?? 0,
      likeCount: json['like_count'] ?? 0,
      importCount: json['import_count'] ?? 0,
      reviewCount: json['review_count'] ?? 0,
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0,
      tags: (json['tags'] as List?)?.map((t) => t.toString()).toList() ?? [],
    );
  }
}

class PlaylistReview {
  final String id;
  final String playlistId;
  final String userId;
  final String userFirstName;
  final String userLastName;
  final int rating;
  final String comment;
  final String createdAt;

  PlaylistReview({
    required this.id,
    required this.playlistId,
    required this.userId,
    required this.userFirstName,
    required this.userLastName,
    required this.rating,
    this.comment = '',
    required this.createdAt,
  });

  factory PlaylistReview.fromJson(Map<String, dynamic> json) {
    return PlaylistReview(
      id: json['id'] ?? '',
      playlistId: json['playlist_id'] ?? '',
      userId: json['user_id'] ?? '',
      userFirstName: json['user_first_name'] ?? '',
      userLastName: json['user_last_name'] ?? '',
      rating: json['rating'] ?? 0,
      comment: json['comment'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}
