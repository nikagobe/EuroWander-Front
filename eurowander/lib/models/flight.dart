class FlightOffer {
  final List<FlightLeg> legs;
  final int totalDuration;
  final double price;
  final String currency;
  final String airlineLogo;
  final String bookingToken;
  final int stops;
  final String source;
  final String? flightId;
  final bool isPaid;
  final double? actualPaidAmount;
  final String? paidCurrency;
  final String? paidBy;
  final List<String> eligibleMemberIds;
  final String departureAirport;
  final String departureAirportName;
  final String departureCityName;
  final String arrivalAirport;
  final String arrivalAirportName;
  final String arrivalCityName;
  final String topDepartureTime;
  final String topArrivalTime;

  FlightOffer({
    required this.legs,
    required this.totalDuration,
    required this.price,
    required this.currency,
    required this.airlineLogo,
    required this.bookingToken,
    required this.stops,
    required this.source,
    this.flightId,
    this.isPaid = false,
    this.actualPaidAmount,
    this.paidCurrency,
    this.paidBy,
    this.eligibleMemberIds = const [],
    this.departureAirport = '',
    this.departureAirportName = '',
    this.departureCityName = '',
    this.arrivalAirport = '',
    this.arrivalAirportName = '',
    this.arrivalCityName = '',
    this.topDepartureTime = '',
    this.topArrivalTime = '',
  });

  String get airline => legs.isNotEmpty ? legs.first.airline : '';
  String get departureTime => topDepartureTime.isNotEmpty ? topDepartureTime : (legs.isNotEmpty ? legs.first.departureTime : '');
  String get arrivalTime => topArrivalTime.isNotEmpty ? topArrivalTime : (legs.isNotEmpty ? legs.last.arrivalTime : '');
  String get departureAirportId => departureAirport.isNotEmpty ? departureAirport : (legs.isNotEmpty ? legs.first.departureAirport : '');
  String get arrivalAirportId => arrivalAirport.isNotEmpty ? arrivalAirport : (legs.isNotEmpty ? legs.last.arrivalAirport : '');

  factory FlightOffer.fromJson(Map<String, dynamic> json) {
    // Handle swagger FlightOfferResponse format (flat legs)
    final legsData = json['legs'] as List<dynamic>? ?? [];
    // Also handle raw SerpApi format (nested "flights")
    final flightsData = json['flights'] as List<dynamic>?;

    List<FlightLeg> parsedLegs;
    if (legsData.isNotEmpty) {
      parsedLegs = legsData.map((f) => FlightLeg.fromJson(f)).toList();
    } else if (flightsData != null) {
      parsedLegs = flightsData.map((f) => FlightLeg.fromJson(f)).toList();
    } else {
      parsedLegs = [];
    }

    return FlightOffer(
      legs: parsedLegs,
      totalDuration: (json['total_duration_minutes'] ?? json['total_duration'] ?? 0) as int,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'EUR',
      airlineLogo: json['airline_logo'] as String? ?? '',
      bookingToken: json['booking_token'] as String? ?? '',
      stops: (json['stops'] as int?) ?? (parsedLegs.length - 1).clamp(0, 99),
      source: json['source'] as String? ?? '',
      flightId: json['flight_id'] as String?,
      isPaid: json['is_paid'] as bool? ?? false,
      actualPaidAmount: (json['actual_paid_amount'] as num?)?.toDouble(),
      paidCurrency: json['paid_currency'] as String?,
      paidBy: json['paid_by'] as String?,
      eligibleMemberIds: (json['eligible_member_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      departureAirport: json['departure_airport'] as String? ?? '',
      departureAirportName: json['departure_airport_name'] as String? ?? '',
      departureCityName: json['departure_city_name'] as String? ?? '',
      arrivalAirport: json['arrival_airport'] as String? ?? '',
      arrivalAirportName: json['arrival_airport_name'] as String? ?? '',
      arrivalCityName: json['arrival_city_name'] as String? ?? '',
      topDepartureTime: json['departure_time'] as String? ?? '',
      topArrivalTime: json['arrival_time'] as String? ?? '',
    );
  }
}

class FlightLeg {
  final String departureAirportName;
  final String departureAirport;
  final String departureTime;
  final double? departureLat;
  final double? departureLng;
  final String departureCityName;
  final String departureCityFreebaseId;
  final String arrivalAirportName;
  final String arrivalAirport;
  final String arrivalTime;
  final double? arrivalLat;
  final double? arrivalLng;
  final String arrivalCityName;
  final String arrivalCityFreebaseId;
  final int duration;
  final String airplane;
  final String airline;
  final String airlineLogo;
  final String travelClass;
  final String flightNumber;
  final String legroom;

  FlightLeg({
    required this.departureAirportName,
    required this.departureAirport,
    required this.departureTime,
    this.departureLat,
    this.departureLng,
    this.departureCityName = '',
    this.departureCityFreebaseId = '',
    required this.arrivalAirportName,
    required this.arrivalAirport,
    required this.arrivalTime,
    this.arrivalLat,
    this.arrivalLng,
    this.arrivalCityName = '',
    this.arrivalCityFreebaseId = '',
    required this.duration,
    required this.airplane,
    required this.airline,
    required this.airlineLogo,
    required this.travelClass,
    required this.flightNumber,
    required this.legroom,
  });

  factory FlightLeg.fromJson(Map<String, dynamic> json) {
    // Handle both flat format (swagger) and nested format (SerpApi raw)
    final dep = json['departure_airport'];
    final arr = json['arrival_airport'];

    String depName, depId, depTime;
    String arrName, arrId, arrTime;

    if (dep is Map) {
      depName = dep['name'] as String? ?? '';
      depId = dep['id'] as String? ?? '';
      depTime = dep['time'] as String? ?? '';
    } else {
      depId = dep as String? ?? '';
      depName = json['departure_airport_name'] as String? ?? '';
      depTime = json['departure_time'] as String? ?? '';
    }

    if (arr is Map) {
      arrName = arr['name'] as String? ?? '';
      arrId = arr['id'] as String? ?? '';
      arrTime = arr['time'] as String? ?? '';
    } else {
      arrId = arr as String? ?? '';
      arrName = json['arrival_airport_name'] as String? ?? '';
      arrTime = json['arrival_time'] as String? ?? '';
    }

    return FlightLeg(
      departureAirportName: depName,
      departureAirport: depId,
      departureTime: depTime,
      departureLat: (json['departure_lat'] as num?)?.toDouble(),
      departureLng: (json['departure_lng'] as num?)?.toDouble(),
      departureCityName: json['departure_city_name'] as String? ?? '',
      departureCityFreebaseId: json['departure_city_freebase_id'] as String? ?? '',
      arrivalAirportName: arrName,
      arrivalAirport: arrId,
      arrivalTime: arrTime,
      arrivalLat: (json['arrival_lat'] as num?)?.toDouble(),
      arrivalLng: (json['arrival_lng'] as num?)?.toDouble(),
      arrivalCityName: json['arrival_city_name'] as String? ?? '',
      arrivalCityFreebaseId: json['arrival_city_freebase_id'] as String? ?? '',
      duration: (json['duration'] ?? json['duration_minutes'] ?? 0) as int,
      airplane: json['airplane'] as String? ?? '',
      airline: json['airline'] as String? ?? '',
      airlineLogo: json['airline_logo'] as String? ?? '',
      travelClass: json['travel_class'] as String? ?? 'Economy',
      flightNumber: json['flight_number'] as String? ?? '',
      legroom: json['legroom'] as String? ?? '',
    );
  }
}
