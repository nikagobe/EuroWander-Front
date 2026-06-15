class HotelDestination {
  final String destId;
  final String cityName;
  final String label;

  HotelDestination({
    required this.destId,
    required this.cityName,
    required this.label,
  });

  factory HotelDestination.fromJson(Map<String, dynamic> json) {
    return HotelDestination(
      destId: json['dest_id'] ?? '',
      cityName: json['city_name'] ?? '',
      label: json['label'] ?? '',
    );
  }
}

class HotelOffer {
  final int hotelId;
  final String name;
  final double latitude;
  final double longitude;
  final String photoUrl;
  final int stars;
  final double reviewScore;
  final String reviewScoreWord;
  final int reviewCount;
  final double pricePerNight;
  final double priceTotal;
  final double priceExcluded;
  final String currency;
  final String checkinFrom;
  final String checkoutUntil;
  final String countryCode;

  HotelOffer({
    required this.hotelId,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.photoUrl,
    required this.stars,
    required this.reviewScore,
    required this.reviewScoreWord,
    required this.reviewCount,
    required this.pricePerNight,
    required this.priceTotal,
    required this.priceExcluded,
    required this.currency,
    required this.checkinFrom,
    required this.checkoutUntil,
    required this.countryCode,
  });

  factory HotelOffer.fromJson(Map<String, dynamic> json) {
    return HotelOffer(
      hotelId: json['hotel_id'] ?? 0,
      name: json['name'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      photoUrl: json['photo_url'] ?? '',
      stars: json['stars'] ?? 0,
      reviewScore: (json['review_score'] as num?)?.toDouble() ?? 0,
      reviewScoreWord: json['review_score_word'] ?? '',
      reviewCount: json['review_count'] ?? 0,
      pricePerNight: (json['price_per_night'] as num?)?.toDouble() ?? 0,
      priceTotal: (json['price_total'] as num?)?.toDouble() ?? 0,
      priceExcluded: (json['price_excluded'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] ?? 'EUR',
      checkinFrom: json['checkin_from'] ?? '',
      checkoutUntil: json['checkout_until'] ?? '',
      countryCode: json['country_code'] ?? '',
    );
  }
}

class RoomHighlight {
  final String name;
  final String icon;

  RoomHighlight({required this.name, required this.icon});

  factory RoomHighlight.fromJson(Map<String, dynamic> json) {
    return RoomHighlight(
      name: json['name'] ?? '',
      icon: json['icon'] ?? '',
    );
  }
}

class HotelRoom {
  final String roomId;
  final String description;
  final List<String> photos;
  final List<RoomHighlight> highlights;
  final List<String> bedConfigurations;
  final double roomSurfaceM2;

  HotelRoom({
    required this.roomId,
    required this.description,
    required this.photos,
    required this.highlights,
    required this.bedConfigurations,
    required this.roomSurfaceM2,
  });

  factory HotelRoom.fromJson(Map<String, dynamic> json) {
    return HotelRoom(
      roomId: json['room_id'] ?? '',
      description: json['description'] ?? '',
      photos: (json['photos'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      highlights: (json['highlights'] as List<dynamic>?)?.map((e) => RoomHighlight.fromJson(e)).toList() ?? [],
      bedConfigurations: (json['bed_configurations'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      roomSurfaceM2: (json['room_surface_m2'] as num?)?.toDouble() ?? 0,
    );
  }
}

class HotelDetails {
  final int hotelId;
  final String name;
  final String url;
  final String description;
  final double latitude;
  final double longitude;
  final String address;
  final String city;
  final String district;
  final String country;
  final String countryCode;
  final String zipCode;
  final String accommodationType;
  final int stars;
  final double reviewScore;
  final String reviewScoreWord;
  final int reviewCount;
  final String currency;
  final double pricePerNight;
  final double priceTotal;
  final double priceExcluded;
  final int availableRooms;
  final bool breakfastIncluded;
  final String checkinFrom;
  final String checkinUntil;
  final String checkoutFrom;
  final String checkoutUntil;
  final double distanceToCenterKm;
  final List<String> facilities;
  final List<String> photos;
  final List<HotelRoom> rooms;

  HotelDetails({
    required this.hotelId,
    required this.name,
    required this.url,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.city,
    required this.district,
    required this.country,
    required this.countryCode,
    required this.zipCode,
    required this.accommodationType,
    required this.stars,
    required this.reviewScore,
    required this.reviewScoreWord,
    required this.reviewCount,
    required this.currency,
    required this.pricePerNight,
    required this.priceTotal,
    required this.priceExcluded,
    required this.availableRooms,
    required this.breakfastIncluded,
    required this.checkinFrom,
    required this.checkinUntil,
    required this.checkoutFrom,
    required this.checkoutUntil,
    required this.distanceToCenterKm,
    required this.facilities,
    required this.photos,
    required this.rooms,
  });

  factory HotelDetails.fromJson(Map<String, dynamic> json) {
    return HotelDetails(
      hotelId: json['hotel_id'] ?? 0,
      name: json['name'] ?? '',
      url: json['url'] ?? '',
      description: json['description'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      district: json['district'] ?? '',
      country: json['country'] ?? '',
      countryCode: json['country_code'] ?? '',
      zipCode: json['zip_code'] ?? '',
      accommodationType: json['accommodation_type'] ?? '',
      stars: json['stars'] ?? 0,
      reviewScore: (json['review_score'] as num?)?.toDouble() ?? 0,
      reviewScoreWord: json['review_score_word'] ?? '',
      reviewCount: json['review_count'] ?? 0,
      currency: json['currency'] ?? 'EUR',
      pricePerNight: (json['price_per_night'] as num?)?.toDouble() ?? 0,
      priceTotal: (json['price_total'] as num?)?.toDouble() ?? 0,
      priceExcluded: (json['price_excluded'] as num?)?.toDouble() ?? 0,
      availableRooms: json['available_rooms'] ?? 0,
      breakfastIncluded: json['breakfast_included'] ?? false,
      checkinFrom: json['checkin_from'] ?? '',
      checkinUntil: json['checkin_until'] ?? '',
      checkoutFrom: json['checkout_from'] ?? '',
      checkoutUntil: json['checkout_until'] ?? '',
      distanceToCenterKm: (json['distance_to_center_km'] as num?)?.toDouble() ?? 0,
      facilities: (json['facilities'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      photos: (json['photos'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      rooms: (json['rooms'] as List<dynamic>?)?.map((e) => HotelRoom.fromJson(e)).toList() ?? [],
    );
  }
}
