class RestaurantResponse {
  final String locationId;
  final String name;
  final String cuisine;
  final String neighborhood;
  final double rating;
  final int numReviews;
  final String photoUrl;
  final String badge;
  final String badgeYear;
  final String priceLevel;
  final bool isSponsored;

  RestaurantResponse({
    required this.locationId,
    required this.name,
    required this.cuisine,
    required this.neighborhood,
    required this.rating,
    required this.numReviews,
    required this.photoUrl,
    required this.badge,
    required this.badgeYear,
    required this.priceLevel,
    required this.isSponsored,
  });

  factory RestaurantResponse.fromJson(Map<String, dynamic> json) {
    return RestaurantResponse(
      locationId: json['location_id'] ?? '',
      name: json['name'] ?? '',
      cuisine: json['cuisine'] ?? '',
      neighborhood: json['neighborhood'] ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      numReviews: json['num_reviews'] ?? 0,
      photoUrl: json['photo_url'] ?? '',
      badge: json['badge'] ?? '',
      badgeYear: json['badge_year'] ?? '',
      priceLevel: json['price_level'] ?? '',
      isSponsored: json['is_sponsored'] ?? false,
    );
  }
}

class PaginatedRestaurants {
  final List<RestaurantResponse> data;
  final int currentPage;
  final int totalPages;
  final int totalResults;
  final int pageSize;
  final String updateToken;

  PaginatedRestaurants({
    required this.data,
    required this.currentPage,
    required this.totalPages,
    required this.totalResults,
    required this.pageSize,
    required this.updateToken,
  });

  factory PaginatedRestaurants.fromJson(Map<String, dynamic> json) {
    final pagination = json['pagination'] as Map<String, dynamic>? ?? {};
    return PaginatedRestaurants(
      data: (json['data'] as List<dynamic>?)
              ?.map((e) => RestaurantResponse.fromJson(e))
              .toList() ??
          [],
      currentPage: pagination['current_page'] ?? 1,
      totalPages: pagination['total_pages'] ?? 1,
      totalResults: pagination['total_results'] ?? 0,
      pageSize: pagination['page_size'] ?? 30,
      updateToken: pagination['update_token'] ?? '',
    );
  }
}

class RestaurantPhoto {
  final String url;
  final String caption;
  final int width;
  final int height;

  RestaurantPhoto({
    required this.url,
    required this.caption,
    required this.width,
    required this.height,
  });

  factory RestaurantPhoto.fromJson(Map<String, dynamic> json) {
    return RestaurantPhoto(
      url: json['url'] ?? '',
      caption: json['caption'] ?? '',
      width: json['width'] ?? 0,
      height: json['height'] ?? 0,
    );
  }
}

class RestaurantReview {
  final double rating;
  final String title;
  final String text;
  final String author;
  final String publishedDate;
  final String tripType;

  RestaurantReview({
    required this.rating,
    required this.title,
    required this.text,
    required this.author,
    required this.publishedDate,
    required this.tripType,
  });

  factory RestaurantReview.fromJson(Map<String, dynamic> json) {
    return RestaurantReview(
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      title: json['title'] ?? '',
      text: json['text'] ?? '',
      author: json['author'] ?? '',
      publishedDate: json['published_date'] ?? '',
      tripType: json['trip_type'] ?? '',
    );
  }
}

class NearbyRestaurant {
  final String contentId;
  final String name;
  final double rating;
  final int numReviews;
  final String distance;
  final String cuisine;
  final String photoUrl;

  NearbyRestaurant({
    required this.contentId,
    required this.name,
    required this.rating,
    required this.numReviews,
    required this.distance,
    required this.cuisine,
    required this.photoUrl,
  });

  factory NearbyRestaurant.fromJson(Map<String, dynamic> json) {
    return NearbyRestaurant(
      contentId: json['content_id'] ?? '',
      name: json['name'] ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      numReviews: json['num_reviews'] ?? 0,
      distance: json['distance'] ?? '',
      cuisine: json['cuisine'] ?? '',
      photoUrl: json['photo_url'] ?? '',
    );
  }
}

class RestaurantDetail {
  final String contentId;
  final String name;
  final double rating;
  final int numReviews;
  final String ranking;
  final String priceLevel;
  final String description;
  final String address;
  final double latitude;
  final double longitude;
  final String phone;
  final String website;
  final String hoursStatus;
  final List<String> todaySchedule;
  final List<String> serving;
  final List<String> features;
  final List<String> cuisines;
  final List<RestaurantPhoto> photos;
  final List<RestaurantReview> reviews;
  final List<NearbyRestaurant> nearbyRestaurants;

  RestaurantDetail({
    required this.contentId,
    required this.name,
    required this.rating,
    required this.numReviews,
    required this.ranking,
    required this.priceLevel,
    required this.description,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.phone,
    required this.website,
    required this.hoursStatus,
    required this.todaySchedule,
    required this.serving,
    required this.features,
    required this.cuisines,
    required this.photos,
    required this.reviews,
    required this.nearbyRestaurants,
  });

  factory RestaurantDetail.fromJson(Map<String, dynamic> json) {
    return RestaurantDetail(
      contentId: json['content_id'] ?? '',
      name: json['name'] ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      numReviews: json['num_reviews'] ?? 0,
      ranking: json['ranking'] ?? '',
      priceLevel: json['price_level'] ?? '',
      description: json['description'] ?? '',
      address: json['address'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      phone: json['phone'] ?? '',
      website: json['website'] ?? '',
      hoursStatus: json['hours_status'] ?? '',
      todaySchedule: (json['today_schedule'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      serving: (json['serving'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      features: (json['features'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      cuisines: (json['cuisines'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      photos: (json['photos'] as List<dynamic>?)
              ?.map((e) => RestaurantPhoto.fromJson(e))
              .toList() ??
          [],
      reviews: (json['reviews'] as List<dynamic>?)
              ?.map((e) => RestaurantReview.fromJson(e))
              .toList() ??
          [],
      nearbyRestaurants: (json['nearby_restaurants'] as List<dynamic>?)
              ?.map((e) => NearbyRestaurant.fromJson(e))
              .toList() ??
          [],
    );
  }
}
