class AttractionDestination {
  final int geoId;
  final String name;
  final String secondaryText;
  final String imageUrl;

  AttractionDestination({
    required this.geoId,
    required this.name,
    required this.secondaryText,
    required this.imageUrl,
  });

  factory AttractionDestination.fromJson(Map<String, dynamic> json) {
    return AttractionDestination(
      geoId: json['geo_id'] ?? 0,
      name: json['name'] ?? '',
      secondaryText: json['secondary_text'] ?? '',
      imageUrl: json['image_url'] ?? '',
    );
  }
}

class AttractionResponse {
  final String locationId;
  final String name;
  final String category;
  final String neighborhood;
  final double rating;
  final int numReviews;
  final String photoUrl;
  final double latitude;
  final double longitude;
  final String badge;
  final String ticketPrice;
  final bool isOpenNow;

  AttractionResponse({
    required this.locationId,
    required this.name,
    required this.category,
    required this.neighborhood,
    required this.rating,
    required this.numReviews,
    required this.photoUrl,
    required this.latitude,
    required this.longitude,
    required this.badge,
    required this.ticketPrice,
    required this.isOpenNow,
  });

  factory AttractionResponse.fromJson(Map<String, dynamic> json) {
    return AttractionResponse(
      locationId: json['location_id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      neighborhood: json['neighborhood'] ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      numReviews: json['num_reviews'] ?? 0,
      photoUrl: json['photo_url'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      badge: json['badge'] ?? '',
      ticketPrice: json['ticket_price'] ?? '',
      isOpenNow: json['is_open_now'] ?? false,
    );
  }
}

class PaginatedAttractions {
  final List<AttractionResponse> data;
  final int currentPage;
  final int totalPages;
  final int totalResults;
  final int pageSize;

  PaginatedAttractions({
    required this.data,
    required this.currentPage,
    required this.totalPages,
    required this.totalResults,
    required this.pageSize,
  });

  factory PaginatedAttractions.fromJson(Map<String, dynamic> json) {
    final pagination = json['pagination'] as Map<String, dynamic>? ?? {};
    return PaginatedAttractions(
      data: (json['data'] as List<dynamic>?)
              ?.map((e) => AttractionResponse.fromJson(e))
              .toList() ??
          [],
      currentPage: pagination['current_page'] ?? 1,
      totalPages: pagination['total_pages'] ?? 1,
      totalResults: pagination['total_results'] ?? 0,
      pageSize: pagination['page_size'] ?? 30,
    );
  }
}

class AttractionPhoto {
  final String url;
  final String caption;
  final int width;
  final int height;

  AttractionPhoto({
    required this.url,
    required this.caption,
    required this.width,
    required this.height,
  });

  factory AttractionPhoto.fromJson(Map<String, dynamic> json) {
    return AttractionPhoto(
      url: json['url'] ?? '',
      caption: json['caption'] ?? '',
      width: json['width'] ?? 0,
      height: json['height'] ?? 0,
    );
  }
}

class AttractionReview {
  final double rating;
  final String title;
  final String text;
  final String author;
  final String publishedDate;
  final String tripType;

  AttractionReview({
    required this.rating,
    required this.title,
    required this.text,
    required this.author,
    required this.publishedDate,
    required this.tripType,
  });

  factory AttractionReview.fromJson(Map<String, dynamic> json) {
    return AttractionReview(
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      title: json['title'] ?? '',
      text: json['text'] ?? '',
      author: json['author'] ?? '',
      publishedDate: json['published_date'] ?? '',
      tripType: json['trip_type'] ?? '',
    );
  }
}

class NearbyAttractionCard {
  final String contentId;
  final String name;
  final double rating;
  final int numReviews;
  final String distance;
  final String category;
  final String photoUrl;

  NearbyAttractionCard({
    required this.contentId,
    required this.name,
    required this.rating,
    required this.numReviews,
    required this.distance,
    required this.category,
    required this.photoUrl,
  });

  factory NearbyAttractionCard.fromJson(Map<String, dynamic> json) {
    return NearbyAttractionCard(
      contentId: json['content_id'] ?? '',
      name: json['name'] ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      numReviews: json['num_reviews'] ?? 0,
      distance: json['distance'] ?? '',
      category: json['category'] ?? '',
      photoUrl: json['photo_url'] ?? '',
    );
  }
}

class NearbyRestaurantCard {
  final String contentId;
  final String name;
  final double rating;
  final int numReviews;
  final String distance;
  final String cuisine;
  final String photoUrl;

  NearbyRestaurantCard({
    required this.contentId,
    required this.name,
    required this.rating,
    required this.numReviews,
    required this.distance,
    required this.cuisine,
    required this.photoUrl,
  });

  factory NearbyRestaurantCard.fromJson(Map<String, dynamic> json) {
    return NearbyRestaurantCard(
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

class AttractionDetail {
  final String contentId;
  final String name;
  final double rating;
  final int numReviews;
  final String ranking;
  final String category;
  final String description;
  final String address;
  final double latitude;
  final double longitude;
  final String phone;
  final String website;
  final String hoursStatus;
  final List<String> todaySchedule;
  final List<String> aboutItems;
  final List<AttractionPhoto> photos;
  final List<AttractionReview> reviews;
  final List<NearbyAttractionCard> nearbyAttractions;
  final List<NearbyRestaurantCard> nearbyRestaurants;

  AttractionDetail({
    required this.contentId,
    required this.name,
    required this.rating,
    required this.numReviews,
    required this.ranking,
    required this.category,
    required this.description,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.phone,
    required this.website,
    required this.hoursStatus,
    required this.todaySchedule,
    required this.aboutItems,
    required this.photos,
    required this.reviews,
    required this.nearbyAttractions,
    required this.nearbyRestaurants,
  });

  factory AttractionDetail.fromJson(Map<String, dynamic> json) {
    return AttractionDetail(
      contentId: json['content_id'] ?? '',
      name: json['name'] ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      numReviews: json['num_reviews'] ?? 0,
      ranking: json['ranking'] ?? '',
      category: json['category'] ?? '',
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
      aboutItems: (json['about_items'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      photos: (json['photos'] as List<dynamic>?)
              ?.map((e) => AttractionPhoto.fromJson(e))
              .toList() ??
          [],
      reviews: (json['reviews'] as List<dynamic>?)
              ?.map((e) => AttractionReview.fromJson(e))
              .toList() ??
          [],
      nearbyAttractions: (json['nearby_attractions'] as List<dynamic>?)
              ?.map((e) => NearbyAttractionCard.fromJson(e))
              .toList() ??
          [],
      nearbyRestaurants: (json['nearby_restaurants'] as List<dynamic>?)
              ?.map((e) => NearbyRestaurantCard.fromJson(e))
              .toList() ??
          [],
    );
  }
}
