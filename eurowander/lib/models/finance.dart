class FinanceSummary {
  final String tripId;
  final List<Expense> expenses;
  final List<Balance> balances;
  final List<Debt> debts;

  FinanceSummary({
    required this.tripId,
    required this.expenses,
    required this.balances,
    required this.debts,
  });

  factory FinanceSummary.fromJson(Map<String, dynamic> json) {
    return FinanceSummary(
      tripId: json['trip_id'] ?? '',
      expenses: (json['expenses'] as List<dynamic>?)
              ?.map((e) => Expense.fromJson(e))
              .toList() ??
          [],
      balances: (json['balances'] as List<dynamic>?)
              ?.map((e) => Balance.fromJson(e))
              .toList() ??
          [],
      debts: (json['debts'] as List<dynamic>?)
              ?.map((e) => Debt.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class Expense {
  final String id;
  final String tripId;
  final String name;
  final double amount;
  final String currency;
  final String paidBy;
  final List<String> eligibleMemberIds;
  final double sharePerMember;
  final String source; // 'manual' or 'ticket'
  final String sourceRef;
  final DateTime createdAt;

  Expense({
    required this.id,
    required this.tripId,
    required this.name,
    required this.amount,
    required this.currency,
    required this.paidBy,
    required this.eligibleMemberIds,
    required this.sharePerMember,
    required this.source,
    required this.sourceRef,
    required this.createdAt,
  });

  bool get isManual => source == 'manual';
  bool get isTicket => source == 'ticket';

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] ?? '',
      tripId: json['trip_id'] ?? '',
      name: json['name'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] ?? 'EUR',
      paidBy: json['paid_by'] ?? '',
      eligibleMemberIds: (json['eligible_member_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      sharePerMember: (json['share_per_member'] as num?)?.toDouble() ?? 0,
      source: json['source'] ?? 'manual',
      sourceRef: json['source_ref'] ?? '',
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class CurrencyAmount {
  final String currency;
  final double netAmount;

  CurrencyAmount({required this.currency, required this.netAmount});

  factory CurrencyAmount.fromJson(Map<String, dynamic> json) {
    return CurrencyAmount(
      currency: json['currency'] ?? 'EUR',
      netAmount: (json['net_amount'] as num?)?.toDouble() ?? 0,
    );
  }
}

class Balance {
  final String userId;
  final String firstName;
  final String lastName;
  final List<CurrencyAmount> netByCurrency;

  Balance({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.netByCurrency,
  });

  String get displayName => '$firstName $lastName'.trim();

  factory Balance.fromJson(Map<String, dynamic> json) {
    return Balance(
      userId: json['user_id'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      netByCurrency: (json['net_by_currency'] as List<dynamic>?)
              ?.map((e) => CurrencyAmount.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class Debt {
  final String fromUserId;
  final String fromFirstName;
  final String fromLastName;
  final String toUserId;
  final String toFirstName;
  final String toLastName;
  final double amount;
  final String currency;

  Debt({
    required this.fromUserId,
    required this.fromFirstName,
    required this.fromLastName,
    required this.toUserId,
    required this.toFirstName,
    required this.toLastName,
    required this.amount,
    required this.currency,
  });

  String get fromDisplayName => '$fromFirstName $fromLastName'.trim();
  String get toDisplayName => '$toFirstName $toLastName'.trim();

  factory Debt.fromJson(Map<String, dynamic> json) {
    return Debt(
      fromUserId: json['from_user_id'] ?? '',
      fromFirstName: json['from_first_name'] ?? '',
      fromLastName: json['from_last_name'] ?? '',
      toUserId: json['to_user_id'] ?? '',
      toFirstName: json['to_first_name'] ?? '',
      toLastName: json['to_last_name'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] ?? 'EUR',
    );
  }
}
