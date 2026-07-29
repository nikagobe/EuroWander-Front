class UserProfile {
  final String userId;
  final String bio;
  final String homeCity;
  final String baseAirport;
  final String profilePhotoUrl;
  final String coverPhotoUrl;
  final List<String> preferredLanguages;
  final List<String> travelStyleTags;
  final DateTime updatedAt;
  final String firstName;
  final String lastName;

  UserProfile({
    required this.userId,
    this.bio = '',
    this.homeCity = '',
    this.baseAirport = '',
    this.profilePhotoUrl = '',
    this.coverPhotoUrl = '',
    this.preferredLanguages = const [],
    this.travelStyleTags = const [],
    required this.updatedAt,
    this.firstName = '',
    this.lastName = '',
  });

  String get fullName => '$firstName $lastName'.trim();

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['user_id'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      homeCity: json['home_city'] as String? ?? '',
      baseAirport: json['base_airport'] as String? ?? '',
      profilePhotoUrl: json['profile_photo_url'] as String? ?? '',
      coverPhotoUrl: json['cover_photo_url'] as String? ?? '',
      preferredLanguages: (json['preferred_languages'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      travelStyleTags: (json['travel_style_tags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'bio': bio,
        'home_city': homeCity,
        'base_airport': baseAirport,
        'profile_photo_url': profilePhotoUrl,
        'cover_photo_url': coverPhotoUrl,
        'preferred_languages': preferredLanguages,
        'travel_style_tags': travelStyleTags,
        'first_name': firstName,
        'last_name': lastName,
      };
}

class TravelStats {
  final int tripsCompleted;
  final List<String> citiesVisited;
  final double totalDistanceKm;
  final String favoriteDestination;

  TravelStats({
    this.tripsCompleted = 0,
    this.citiesVisited = const [],
    this.totalDistanceKm = 0,
    this.favoriteDestination = '',
  });

  int get citiesCount => citiesVisited.length;

  factory TravelStats.fromJson(Map<String, dynamic> json) {
    return TravelStats(
      tripsCompleted: json['trips_completed'] as int? ?? 0,
      citiesVisited: (json['cities_visited'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      totalDistanceKm:
          (json['total_distance_km'] as num?)?.toDouble() ?? 0,
      favoriteDestination: json['favorite_destination'] as String? ?? '',
    );
  }
}

class TravelBadge {
  final String badge;
  final String label;

  TravelBadge({required this.badge, required this.label});

  factory TravelBadge.fromJson(Map<String, dynamic> json) {
    return TravelBadge(
      badge: json['badge'] as String? ?? '',
      label: json['label'] as String? ?? '',
    );
  }
}

class FrequentCollaborator {
  final String userId;
  final String firstName;
  final String lastName;
  final String profilePhotoUrl;
  final int sharedTripCount;

  FrequentCollaborator({
    required this.userId,
    required this.firstName,
    required this.lastName,
    this.profilePhotoUrl = '',
    this.sharedTripCount = 0,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory FrequentCollaborator.fromJson(Map<String, dynamic> json) {
    return FrequentCollaborator(
      userId: json['user_id'] as String,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      profilePhotoUrl: json['profile_photo_url'] as String? ?? '',
      sharedTripCount: json['shared_trip_count'] as int? ?? 0,
    );
  }
}

class ActivityTripSummary {
  final String tripId;
  final String name;
  final String destination;
  final DateTime createdAt;
  final DateTime? startDate;
  final DateTime? endDate;

  ActivityTripSummary({
    required this.tripId,
    required this.name,
    required this.destination,
    required this.createdAt,
    this.startDate,
    this.endDate,
  });

  factory ActivityTripSummary.fromJson(Map<String, dynamic> json) {
    return ActivityTripSummary(
      tripId: json['trip_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      destination: json['destination'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['end_date'] as String)
          : null,
    );
  }
}

class FullProfile {
  final UserProfile profile;
  final TravelStats stats;
  final List<TravelBadge> badges;
  final List<FrequentCollaborator> collaborators;

  FullProfile({
    required this.profile,
    required this.stats,
    this.badges = const [],
    this.collaborators = const [],
  });

  factory FullProfile.fromJson(Map<String, dynamic> json) {
    return FullProfile(
      profile: UserProfile.fromJson(json['profile'] as Map<String, dynamic>),
      stats: TravelStats.fromJson(
          json['stats'] as Map<String, dynamic>? ?? {}),
      badges: (json['badges'] as List<dynamic>?)
              ?.map((e) => TravelBadge.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      collaborators: (json['collaborators'] as List<dynamic>?)
              ?.map((e) =>
                  FrequentCollaborator.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class ActivityFeed {
  final List<ActivityTripSummary> recentCompleted;
  final List<ActivityTripSummary> upcoming;

  ActivityFeed({
    this.recentCompleted = const [],
    this.upcoming = const [],
  });

  factory ActivityFeed.fromJson(Map<String, dynamic> json) {
    return ActivityFeed(
      recentCompleted: (json['recent_completed'] as List<dynamic>?)
              ?.map((e) =>
                  ActivityTripSummary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      upcoming: (json['upcoming'] as List<dynamic>?)
              ?.map((e) =>
                  ActivityTripSummary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
