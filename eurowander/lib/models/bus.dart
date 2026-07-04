class BusSegment {
  final String depName;
  final String arrName;
  final String depTime;
  final String arrTime;
  final String productType;
  final String product;

  BusSegment({
    required this.depName,
    required this.arrName,
    required this.depTime,
    required this.arrTime,
    required this.productType,
    required this.product,
  });

  factory BusSegment.fromJson(Map<String, dynamic> json) {
    return BusSegment(
      depName: json['dep_name'] ?? '',
      arrName: json['arr_name'] ?? '',
      depTime: json['dep_time'] ?? '',
      arrTime: json['arr_time'] ?? '',
      productType: json['product_type'] ?? '',
      product: json['product'] ?? '',
    );
  }
}

class BusOffer {
  final String depName;
  final String arrName;
  final String depTime;
  final String arrTime;
  final String duration;
  final int durationMinutes;
  final int changeovers;
  final double price;
  final double? pricePerPerson;
  final double? totalPrice;
  final int adults;
  final String currency;
  final String deeplink;
  final String additionalInfo;
  final String source;
  final List<BusSegment> segments;
  final bool isPaid;
  final double? actualPaidAmount;
  final String? paidCurrency;
  final String? paidBy;
  final List<String> eligibleMemberIds;

  BusOffer({
    required this.depName,
    required this.arrName,
    required this.depTime,
    required this.arrTime,
    required this.duration,
    required this.durationMinutes,
    required this.changeovers,
    required this.price,
    this.pricePerPerson,
    this.totalPrice,
    this.adults = 1,
    required this.currency,
    required this.deeplink,
    required this.additionalInfo,
    required this.source,
    required this.segments,
    this.isPaid = false,
    this.actualPaidAmount,
    this.paidCurrency,
    this.paidBy,
    this.eligibleMemberIds = const [],
  });

  factory BusOffer.fromJson(Map<String, dynamic> json) {
    return BusOffer(
      depName: json['dep_name'] ?? '',
      arrName: json['arr_name'] ?? '',
      depTime: json['dep_time'] ?? '',
      arrTime: json['arr_time'] ?? '',
      duration: json['duration'] ?? '',
      durationMinutes: json['duration_minutes'] ?? 0,
      changeovers: json['changeovers'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
      pricePerPerson: (json['price_per_person'] as num?)?.toDouble(),
      totalPrice: (json['total_price'] as num?)?.toDouble(),
      adults: (json['adults'] as int?) ?? 1,
      currency: json['currency'] ?? 'EUR',
      deeplink: json['deeplink'] ?? '',
      additionalInfo: json['additional_info'] ?? '',
      source: json['source'] ?? '',
      segments: (json['segments'] as List<dynamic>?)
              ?.map((s) => BusSegment.fromJson(s))
              .toList() ??
          [],
      isPaid: json['is_paid'] as bool? ?? false,
      actualPaidAmount: (json['actual_paid_amount'] as num?)?.toDouble(),
      paidCurrency: json['paid_currency'] as String?,
      paidBy: json['paid_by'] as String?,
      eligibleMemberIds: (json['eligible_member_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}
