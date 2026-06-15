import 'bus.dart';
import 'flight.dart';

class SavedHotel {
  final int hotelId;
  final String name;
  final String city;
  final String address;
  final double latitude;
  final double longitude;
  final String photoUrl;
  final int stars;
  final double reviewScore;
  final String reviewScoreWord;
  final String checkinDate;
  final String checkoutDate;
  final double pricePerNight;
  final double priceTotal;
  final String currency;
  final String bookingUrl;
  final bool isPaid;
  final double? actualPaidAmount;
  final String? paidCurrency;
  final String? paidBy;
  final List<String>? eligibleMemberIds;

  SavedHotel({
    required this.hotelId,
    required this.name,
    required this.city,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.photoUrl,
    required this.stars,
    required this.reviewScore,
    required this.reviewScoreWord,
    required this.checkinDate,
    required this.checkoutDate,
    required this.pricePerNight,
    required this.priceTotal,
    required this.currency,
    required this.bookingUrl,
    this.isPaid = false,
    this.actualPaidAmount,
    this.paidCurrency,
    this.paidBy,
    this.eligibleMemberIds,
  });

  factory SavedHotel.fromJson(Map<String, dynamic> json) {
    return SavedHotel(
      hotelId: json['hotel_id'] ?? 0,
      name: json['name'] ?? '',
      city: json['city'] ?? '',
      address: json['address'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      photoUrl: json['photo_url'] ?? '',
      stars: json['stars'] ?? 0,
      reviewScore: (json['review_score'] ?? 0).toDouble(),
      reviewScoreWord: json['review_score_word'] ?? '',
      checkinDate: json['checkin_date'] ?? '',
      checkoutDate: json['checkout_date'] ?? '',
      pricePerNight: (json['price_per_night'] ?? 0).toDouble(),
      priceTotal: (json['price_total'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'EUR',
      bookingUrl: json['booking_url'] ?? '',
      isPaid: json['is_paid'] == true,
      actualPaidAmount: json['actual_paid_amount'] != null ? (json['actual_paid_amount']).toDouble() : null,
      paidCurrency: json['paid_currency'],
      paidBy: json['paid_by'],
      eligibleMemberIds: json['eligible_member_ids'] != null
          ? List<String>.from(json['eligible_member_ids'])
          : null,
    );
  }
}

class SavedTrip {
  final String id;
  final String userId;
  final String name;
  final String status;
  final FlightOffer? outboundFlight;
  final FlightOffer? returnFlight;
  final BusOffer? busJourney;
  final List<SavedHotel> hotels;
  final DateTime createdAt;
  final DateTime updatedAt;

  SavedTrip({
    required this.id,
    required this.userId,
    required this.name,
    required this.status,
    this.outboundFlight,
    this.returnFlight,
    this.busJourney,
    this.hotels = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory SavedTrip.fromJson(Map<String, dynamic> json) {
    return SavedTrip(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      name: json['name'] ?? '',
      status: json['status'] ?? 'planning',
      outboundFlight: json['outbound_flight'] != null
          ? FlightOffer.fromJson(json['outbound_flight'])
          : null,
      returnFlight: json['return_flight'] != null
          ? FlightOffer.fromJson(json['return_flight'])
          : null,
      busJourney: json['bus_journey'] != null
          ? BusOffer.fromJson(json['bus_journey'])
          : null,
      hotels: json['hotels'] != null
          ? (json['hotels'] as List).map((h) => SavedHotel.fromJson(h)).toList()
          : [],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class TripMember {
  final String userId;
  final String role;
  final DateTime joinedAt;
  final String firstName;
  final String lastName;
  final String email;

  TripMember({
    required this.userId,
    required this.role,
    required this.joinedAt,
    this.firstName = '',
    this.lastName = '',
    this.email = '',
  });

  bool get isMaster => role == 'master';

  String get displayName {
    if (firstName.isNotEmpty || lastName.isNotEmpty) {
      return '$firstName $lastName'.trim();
    }
    if (email.isNotEmpty) return email;
    return userId;
  }

  factory TripMember.fromJson(Map<String, dynamic> json) {
    return TripMember(
      userId: json['user_id'] ?? '',
      role: json['role'] ?? 'member',
      joinedAt: DateTime.parse(json['joined_at']),
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
    );
  }
}
