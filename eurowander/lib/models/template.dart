class TemplateListItem {
  final String id;
  final String authorId;
  final String title;
  final String description;
  final List<String> tags;
  final String coverPhotoUrl;
  final int totalDays;
  final double? estimatedBudgetMin;
  final double? estimatedBudgetMax;
  final String currency;
  final int forkCount;
  final int likeCount;
  final String status;
  final List<String> legCities;

  TemplateListItem({
    required this.id,
    required this.authorId,
    required this.title,
    required this.description,
    required this.tags,
    required this.coverPhotoUrl,
    required this.totalDays,
    this.estimatedBudgetMin,
    this.estimatedBudgetMax,
    required this.currency,
    required this.forkCount,
    required this.likeCount,
    required this.status,
    required this.legCities,
  });

  factory TemplateListItem.fromJson(Map<String, dynamic> json) {
    return TemplateListItem(
      id: json['id'] ?? '',
      authorId: json['author_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      coverPhotoUrl: json['cover_photo_url'] ?? '',
      totalDays: json['total_days'] ?? 0,
      estimatedBudgetMin: json['estimated_budget_min'] != null
          ? (json['estimated_budget_min'] as num).toDouble()
          : null,
      estimatedBudgetMax: json['estimated_budget_max'] != null
          ? (json['estimated_budget_max'] as num).toDouble()
          : null,
      currency: json['currency'] ?? 'EUR',
      forkCount: json['fork_count'] ?? 0,
      likeCount: json['like_count'] ?? 0,
      status: json['status'] ?? 'draft',
      legCities: List<String>.from(json['leg_cities'] ?? []),
    );
  }
}

class TemplateResponse {
  final String id;
  final String authorId;
  final String title;
  final String description;
  final List<TemplateLegResponse> legs;
  final List<String> tags;
  final String coverPhotoUrl;
  final double? estimatedBudgetMin;
  final double? estimatedBudgetMax;
  final String currency;
  final int totalDays;
  final String status;
  final int forkCount;
  final int likeCount;
  final String createdAt;
  final String updatedAt;

  TemplateResponse({
    required this.id,
    required this.authorId,
    required this.title,
    required this.description,
    required this.legs,
    required this.tags,
    required this.coverPhotoUrl,
    this.estimatedBudgetMin,
    this.estimatedBudgetMax,
    required this.currency,
    required this.totalDays,
    required this.status,
    required this.forkCount,
    required this.likeCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TemplateResponse.fromJson(Map<String, dynamic> json) {
    return TemplateResponse(
      id: json['id'] ?? '',
      authorId: json['author_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      legs: (json['legs'] as List<dynamic>?)
              ?.map((l) => TemplateLegResponse.fromJson(l))
              .toList() ??
          [],
      tags: List<String>.from(json['tags'] ?? []),
      coverPhotoUrl: json['cover_photo_url'] ?? '',
      estimatedBudgetMin: json['estimated_budget_min'] != null
          ? (json['estimated_budget_min'] as num).toDouble()
          : null,
      estimatedBudgetMax: json['estimated_budget_max'] != null
          ? (json['estimated_budget_max'] as num).toDouble()
          : null,
      currency: json['currency'] ?? 'EUR',
      totalDays: json['total_days'] ?? 0,
      status: json['status'] ?? 'draft',
      forkCount: json['fork_count'] ?? 0,
      likeCount: json['like_count'] ?? 0,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}

class TemplateLegResponse {
  final int order;
  final String city;
  final String country;
  final int days;
  final FlightRecommendation? flightRecommendation;
  final TransportRecommendation? transportRecommendation;
  final HotelRecommendations? hotelRecommendations;
  final String? playlistId;
  final List<String> restaurantIds;
  final String authorNotes;

  TemplateLegResponse({
    required this.order,
    required this.city,
    required this.country,
    required this.days,
    this.flightRecommendation,
    this.transportRecommendation,
    this.hotelRecommendations,
    this.playlistId,
    required this.restaurantIds,
    required this.authorNotes,
  });

  factory TemplateLegResponse.fromJson(Map<String, dynamic> json) {
    return TemplateLegResponse(
      order: json['order'] ?? 0,
      city: json['city'] ?? '',
      country: json['country'] ?? '',
      days: json['days'] ?? 0,
      flightRecommendation: json['flight_recommendation'] != null
          ? FlightRecommendation.fromJson(json['flight_recommendation'])
          : null,
      transportRecommendation: json['transport_recommendation'] != null
          ? TransportRecommendation.fromJson(json['transport_recommendation'])
          : null,
      hotelRecommendations: json['hotel_recommendations'] != null
          ? HotelRecommendations.fromJson(json['hotel_recommendations'])
          : null,
      playlistId: json['playlist_id'],
      restaurantIds: List<String>.from(json['restaurant_ids'] ?? []),
      authorNotes: json['author_notes'] ?? '',
    );
  }
}

class FlightRecommendation {
  final String originIata;
  final String destinationIata;
  final String originCity;
  final String destinationCity;
  final List<String> preferredAirlines;
  final List<String> preferredFlightNumbers;
  final String preferredDepartureWindow;
  final double? typicalPriceMin;
  final double? typicalPriceMax;
  final int? typicalDurationMinutes;
  final String tip;

  FlightRecommendation({
    required this.originIata,
    required this.destinationIata,
    required this.originCity,
    required this.destinationCity,
    required this.preferredAirlines,
    required this.preferredFlightNumbers,
    required this.preferredDepartureWindow,
    this.typicalPriceMin,
    this.typicalPriceMax,
    this.typicalDurationMinutes,
    required this.tip,
  });

  factory FlightRecommendation.fromJson(Map<String, dynamic> json) {
    return FlightRecommendation(
      originIata: json['origin_iata'] ?? '',
      destinationIata: json['destination_iata'] ?? '',
      originCity: json['origin_city'] ?? '',
      destinationCity: json['destination_city'] ?? '',
      preferredAirlines: List<String>.from(json['preferred_airlines'] ?? []),
      preferredFlightNumbers:
          List<String>.from(json['preferred_flight_numbers'] ?? []),
      preferredDepartureWindow: json['preferred_departure_window'] ?? '',
      typicalPriceMin: json['typical_price_min'] != null
          ? (json['typical_price_min'] as num).toDouble()
          : null,
      typicalPriceMax: json['typical_price_max'] != null
          ? (json['typical_price_max'] as num).toDouble()
          : null,
      typicalDurationMinutes: json['typical_duration_minutes'],
      tip: json['tip'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'origin_iata': originIata,
      'destination_iata': destinationIata,
      'origin_city': originCity,
      'destination_city': destinationCity,
      'preferred_airlines': preferredAirlines,
      'preferred_flight_numbers': preferredFlightNumbers,
      'preferred_departure_window': preferredDepartureWindow,
      if (typicalPriceMin != null) 'typical_price_min': typicalPriceMin,
      if (typicalPriceMax != null) 'typical_price_max': typicalPriceMax,
      if (typicalDurationMinutes != null)
        'typical_duration_minutes': typicalDurationMinutes,
      'tip': tip,
    };
  }
}

class HotelPick {
  final int bookingHotelId;
  final String name;
  final String city;
  final String neighborhood;
  final int stars;
  final String photoUrl;
  final String authorReview;
  final int priority;
  final double? pricePaid;
  final String currency;

  HotelPick({
    required this.bookingHotelId,
    required this.name,
    required this.city,
    required this.neighborhood,
    required this.stars,
    required this.photoUrl,
    required this.authorReview,
    required this.priority,
    this.pricePaid,
    required this.currency,
  });

  factory HotelPick.fromJson(Map<String, dynamic> json) {
    return HotelPick(
      bookingHotelId: json['booking_hotel_id'] ?? 0,
      name: json['name'] ?? '',
      city: json['city'] ?? '',
      neighborhood: json['neighborhood'] ?? '',
      stars: json['stars'] ?? 0,
      photoUrl: json['photo_url'] ?? '',
      authorReview: json['author_review'] ?? '',
      priority: json['priority'] ?? 0,
      pricePaid: json['price_paid'] != null
          ? (json['price_paid'] as num).toDouble()
          : null,
      currency: json['currency'] ?? 'EUR',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'booking_hotel_id': bookingHotelId,
      'name': name,
      'city': city,
      'neighborhood': neighborhood,
      'stars': stars,
      'photo_url': photoUrl,
      'author_review': authorReview,
      'priority': priority,
      if (pricePaid != null) 'price_paid': pricePaid,
      'currency': currency,
    };
  }
}

class HotelRecommendations {
  final String city;
  final String country;
  final List<HotelPick> primaryPicks;
  final String fallbackNeighborhood;
  final int fallbackStarMin;
  final int fallbackStarMax;
  final double? fallbackBudgetPerNightMin;
  final double? fallbackBudgetPerNightMax;

  HotelRecommendations({
    required this.city,
    required this.country,
    required this.primaryPicks,
    required this.fallbackNeighborhood,
    required this.fallbackStarMin,
    required this.fallbackStarMax,
    this.fallbackBudgetPerNightMin,
    this.fallbackBudgetPerNightMax,
  });

  factory HotelRecommendations.fromJson(Map<String, dynamic> json) {
    return HotelRecommendations(
      city: json['city'] ?? '',
      country: json['country'] ?? '',
      primaryPicks: (json['primary_picks'] as List<dynamic>?)
              ?.map((p) => HotelPick.fromJson(p))
              .toList() ??
          [],
      fallbackNeighborhood: json['fallback_neighborhood'] ?? '',
      fallbackStarMin: json['fallback_star_min'] ?? 1,
      fallbackStarMax: json['fallback_star_max'] ?? 5,
      fallbackBudgetPerNightMin: json['fallback_budget_per_night_min'] != null
          ? (json['fallback_budget_per_night_min'] as num).toDouble()
          : null,
      fallbackBudgetPerNightMax: json['fallback_budget_per_night_max'] != null
          ? (json['fallback_budget_per_night_max'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'city': city,
      'country': country,
      'primary_picks': primaryPicks.map((p) => p.toJson()).toList(),
      'fallback_neighborhood': fallbackNeighborhood,
      'fallback_star_min': fallbackStarMin,
      'fallback_star_max': fallbackStarMax,
      if (fallbackBudgetPerNightMin != null)
        'fallback_budget_per_night_min': fallbackBudgetPerNightMin,
      if (fallbackBudgetPerNightMax != null)
        'fallback_budget_per_night_max': fallbackBudgetPerNightMax,
    };
  }
}

class TransportRecommendation {
  final String fromCity;
  final String toCity;
  final String mode;
  final List<String> preferredProviders;
  final int? typicalDurationMinutes;
  final double? typicalPrice;
  final String currency;
  final String tip;

  TransportRecommendation({
    required this.fromCity,
    required this.toCity,
    required this.mode,
    required this.preferredProviders,
    this.typicalDurationMinutes,
    this.typicalPrice,
    required this.currency,
    required this.tip,
  });

  factory TransportRecommendation.fromJson(Map<String, dynamic> json) {
    return TransportRecommendation(
      fromCity: json['from_city'] ?? '',
      toCity: json['to_city'] ?? '',
      mode: json['mode'] ?? 'bus',
      preferredProviders:
          List<String>.from(json['preferred_providers'] ?? []),
      typicalDurationMinutes: json['typical_duration_minutes'],
      typicalPrice: json['typical_price'] != null
          ? (json['typical_price'] as num).toDouble()
          : null,
      currency: json['currency'] ?? 'EUR',
      tip: json['tip'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'from_city': fromCity,
      'to_city': toCity,
      'mode': mode,
      'preferred_providers': preferredProviders,
      if (typicalDurationMinutes != null)
        'typical_duration_minutes': typicalDurationMinutes,
      if (typicalPrice != null) 'typical_price': typicalPrice,
      'currency': currency,
      'tip': tip,
    };
  }
}

// --- Request Models ---

class CreateTemplateRequest {
  final String authorId;
  final String title;
  final String description;
  final List<CreateTemplateLeg> legs;
  final List<String> tags;
  final String coverPhotoUrl;
  final double? estimatedBudgetMin;
  final double? estimatedBudgetMax;
  final String currency;

  CreateTemplateRequest({
    required this.authorId,
    required this.title,
    required this.description,
    required this.legs,
    required this.tags,
    required this.coverPhotoUrl,
    this.estimatedBudgetMin,
    this.estimatedBudgetMax,
    required this.currency,
  });

  Map<String, dynamic> toJson() {
    return {
      'author_id': authorId,
      'title': title,
      'description': description,
      'legs': legs.map((l) => l.toJson()).toList(),
      'tags': tags,
      'cover_photo_url': coverPhotoUrl,
      if (estimatedBudgetMin != null)
        'estimated_budget_min': estimatedBudgetMin,
      if (estimatedBudgetMax != null)
        'estimated_budget_max': estimatedBudgetMax,
      'currency': currency,
    };
  }
}

class CreateTemplateLeg {
  final int order;
  final String city;
  final String country;
  final int days;
  final FlightRecommendation? flightRecommendation;
  final TransportRecommendation? transportRecommendation;
  final HotelRecommendations? hotelRecommendations;
  final String? playlistId;
  final List<String> restaurantIds;
  final String authorNotes;

  CreateTemplateLeg({
    required this.order,
    required this.city,
    required this.country,
    required this.days,
    this.flightRecommendation,
    this.transportRecommendation,
    this.hotelRecommendations,
    this.playlistId,
    required this.restaurantIds,
    required this.authorNotes,
  });

  Map<String, dynamic> toJson() {
    return {
      'order': order,
      'city': city,
      'country': country,
      'days': days,
      if (flightRecommendation != null)
        'flight_recommendation': flightRecommendation!.toJson(),
      if (transportRecommendation != null)
        'transport_recommendation': transportRecommendation!.toJson(),
      if (hotelRecommendations != null)
        'hotel_recommendations': hotelRecommendations!.toJson(),
      if (playlistId != null) 'playlist_id': playlistId,
      'restaurant_ids': restaurantIds,
      'author_notes': authorNotes,
    };
  }
}

class UpdateTemplateRequest {
  final String? title;
  final String? description;
  final List<CreateTemplateLeg>? legs;
  final List<String>? tags;
  final String? coverPhotoUrl;
  final double? estimatedBudgetMin;
  final double? estimatedBudgetMax;
  final String? currency;

  UpdateTemplateRequest({
    this.title,
    this.description,
    this.legs,
    this.tags,
    this.coverPhotoUrl,
    this.estimatedBudgetMin,
    this.estimatedBudgetMax,
    this.currency,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (title != null) map['title'] = title;
    if (description != null) map['description'] = description;
    if (legs != null) map['legs'] = legs!.map((l) => l.toJson()).toList();
    if (tags != null) map['tags'] = tags;
    if (coverPhotoUrl != null) map['cover_photo_url'] = coverPhotoUrl;
    if (estimatedBudgetMin != null)
      map['estimated_budget_min'] = estimatedBudgetMin;
    if (estimatedBudgetMax != null)
      map['estimated_budget_max'] = estimatedBudgetMax;
    if (currency != null) map['currency'] = currency;
    return map;
  }
}

// --- Fork Guide Models ---

class ForkGuide {
  final String templateId;
  final String title;
  final int totalDays;
  final double? estimatedBudgetMin;
  final double? estimatedBudgetMax;
  final String currency;
  final List<ForkGuideLeg> legs;

  ForkGuide({
    required this.templateId,
    required this.title,
    required this.totalDays,
    this.estimatedBudgetMin,
    this.estimatedBudgetMax,
    required this.currency,
    required this.legs,
  });

  factory ForkGuide.fromJson(Map<String, dynamic> json) {
    return ForkGuide(
      templateId: json['template_id'] ?? '',
      title: json['title'] ?? '',
      totalDays: json['total_days'] ?? 0,
      estimatedBudgetMin: json['estimated_budget_min'] != null
          ? (json['estimated_budget_min'] as num).toDouble()
          : null,
      estimatedBudgetMax: json['estimated_budget_max'] != null
          ? (json['estimated_budget_max'] as num).toDouble()
          : null,
      currency: json['currency'] ?? 'EUR',
      legs: (json['legs'] as List<dynamic>?)
              ?.map((l) => ForkGuideLeg.fromJson(l))
              .toList() ??
          [],
    );
  }
}

class ForkGuideLeg {
  final int order;
  final String city;
  final String country;
  final int days;
  final ForkDateRange dateRange;
  final ForkFlightSearch? flightSearch;
  final ForkTransportSearch? transportSearch;
  final ForkHotelSearch? hotelSearch;
  final String? playlistId;
  final List<String> restaurantIds;
  final String authorNotes;

  ForkGuideLeg({
    required this.order,
    required this.city,
    required this.country,
    required this.days,
    required this.dateRange,
    this.flightSearch,
    this.transportSearch,
    this.hotelSearch,
    this.playlistId,
    required this.restaurantIds,
    required this.authorNotes,
  });

  factory ForkGuideLeg.fromJson(Map<String, dynamic> json) {
    return ForkGuideLeg(
      order: json['order'] ?? 0,
      city: json['city'] ?? '',
      country: json['country'] ?? '',
      days: json['days'] ?? 0,
      dateRange: ForkDateRange.fromJson(json['date_range'] ?? {}),
      flightSearch: json['flight_search'] != null
          ? ForkFlightSearch.fromJson(json['flight_search'])
          : null,
      transportSearch: json['transport_search'] != null
          ? ForkTransportSearch.fromJson(json['transport_search'])
          : null,
      hotelSearch: json['hotel_search'] != null
          ? ForkHotelSearch.fromJson(json['hotel_search'])
          : null,
      playlistId: json['playlist_id'],
      restaurantIds: List<String>.from(json['restaurant_ids'] ?? []),
      authorNotes: json['author_notes'] ?? '',
    );
  }
}

class ForkDateRange {
  final String start;
  final String end;

  ForkDateRange({required this.start, required this.end});

  factory ForkDateRange.fromJson(Map<String, dynamic> json) {
    return ForkDateRange(
      start: json['start'] ?? '',
      end: json['end'] ?? '',
    );
  }
}

class ForkFlightSearch {
  final String originIata;
  final String destinationIata;
  final String originCity;
  final String destinationCity;
  final String date;
  final List<String> preferredAirlines;
  final List<String> preferredFlightNumbers;
  final String preferredDepartureWindow;
  final String authorTip;

  ForkFlightSearch({
    required this.originIata,
    required this.destinationIata,
    required this.originCity,
    required this.destinationCity,
    required this.date,
    required this.preferredAirlines,
    required this.preferredFlightNumbers,
    required this.preferredDepartureWindow,
    required this.authorTip,
  });

  factory ForkFlightSearch.fromJson(Map<String, dynamic> json) {
    return ForkFlightSearch(
      originIata: json['origin_iata'] ?? '',
      destinationIata: json['destination_iata'] ?? '',
      originCity: json['origin_city'] ?? '',
      destinationCity: json['destination_city'] ?? '',
      date: json['date'] ?? '',
      preferredAirlines:
          List<String>.from(json['preferred_airlines'] ?? []),
      preferredFlightNumbers:
          List<String>.from(json['preferred_flight_numbers'] ?? []),
      preferredDepartureWindow: json['preferred_departure_window'] ?? '',
      authorTip: json['author_tip'] ?? '',
    );
  }
}

class ForkTransportSearch {
  final String fromCity;
  final String toCity;
  final String date;
  final String mode;
  final List<String> preferredProviders;
  final String authorTip;

  ForkTransportSearch({
    required this.fromCity,
    required this.toCity,
    required this.date,
    required this.mode,
    required this.preferredProviders,
    required this.authorTip,
  });

  factory ForkTransportSearch.fromJson(Map<String, dynamic> json) {
    return ForkTransportSearch(
      fromCity: json['from_city'] ?? '',
      toCity: json['to_city'] ?? '',
      date: json['date'] ?? '',
      mode: json['mode'] ?? 'bus',
      preferredProviders:
          List<String>.from(json['preferred_providers'] ?? []),
      authorTip: json['author_tip'] ?? '',
    );
  }
}

class ForkHotelSearch {
  final String city;
  final String checkin;
  final String checkout;
  final List<ForkHotelPick> primaryPicks;
  final ForkFallbackParams? fallbackParams;

  ForkHotelSearch({
    required this.city,
    required this.checkin,
    required this.checkout,
    required this.primaryPicks,
    this.fallbackParams,
  });

  factory ForkHotelSearch.fromJson(Map<String, dynamic> json) {
    return ForkHotelSearch(
      city: json['city'] ?? '',
      checkin: json['checkin'] ?? '',
      checkout: json['checkout'] ?? '',
      primaryPicks: (json['primary_picks'] as List<dynamic>?)
              ?.map((p) => ForkHotelPick.fromJson(p))
              .toList() ??
          [],
      fallbackParams: json['fallback_params'] != null
          ? ForkFallbackParams.fromJson(json['fallback_params'])
          : null,
    );
  }
}

class ForkHotelPick {
  final int bookingHotelId;
  final String name;
  final String neighborhood;
  final int stars;
  final String photoUrl;
  final String authorReview;
  final int priority;
  final double? pricePaid;
  final String currency;

  ForkHotelPick({
    required this.bookingHotelId,
    required this.name,
    required this.neighborhood,
    required this.stars,
    required this.photoUrl,
    required this.authorReview,
    required this.priority,
    this.pricePaid,
    required this.currency,
  });

  factory ForkHotelPick.fromJson(Map<String, dynamic> json) {
    return ForkHotelPick(
      bookingHotelId: json['booking_hotel_id'] ?? 0,
      name: json['name'] ?? '',
      neighborhood: json['neighborhood'] ?? '',
      stars: json['stars'] ?? 0,
      photoUrl: json['photo_url'] ?? '',
      authorReview: json['author_review'] ?? '',
      priority: json['priority'] ?? 0,
      pricePaid: json['price_paid'] != null
          ? (json['price_paid'] as num).toDouble()
          : null,
      currency: json['currency'] ?? 'EUR',
    );
  }
}

class ForkFallbackParams {
  final String neighborhood;
  final int starMin;
  final int starMax;
  final double? budgetMinPerNight;
  final double? budgetMaxPerNight;

  ForkFallbackParams({
    required this.neighborhood,
    required this.starMin,
    required this.starMax,
    this.budgetMinPerNight,
    this.budgetMaxPerNight,
  });

  factory ForkFallbackParams.fromJson(Map<String, dynamic> json) {
    return ForkFallbackParams(
      neighborhood: json['neighborhood'] ?? '',
      starMin: json['star_min'] ?? 1,
      starMax: json['star_max'] ?? 5,
      budgetMinPerNight: json['budget_min_per_night'] != null
          ? (json['budget_min_per_night'] as num).toDouble()
          : null,
      budgetMaxPerNight: json['budget_max_per_night'] != null
          ? (json['budget_max_per_night'] as num).toDouble()
          : null,
    );
  }
}
