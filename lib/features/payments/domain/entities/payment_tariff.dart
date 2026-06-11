import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentTariff {
  const PaymentTariff({
    required this.id,
    required this.adminId,
    required this.branchId,
    required this.name,
    required this.amountCents,
    required this.currency,
    required this.periodType,
    required this.periodCount,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.groupId,
    this.description,
    this.stripeProductId,
    this.stripePriceId,
  });

  final String id;
  final String adminId;
  final String branchId;
  final String name;
  final int amountCents;
  final String currency;
  final String periodType;
  final int periodCount;
  final String? groupId;
  final String? description;
  final bool isActive;
  final String? stripeProductId;
  final String? stripePriceId;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory PaymentTariff.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return PaymentTariff(
      id: id,
      adminId: map['admin_id'] as String? ?? '',
      branchId: map['branch_id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      amountCents: (map['amount_cents'] as num?)?.toInt() ?? 0,
      currency: map['currency'] as String? ?? 'mxn',
      periodType: map['period_type'] as String? ?? 'month',
      periodCount: (map['period_count'] as num?)?.toInt() ?? 1,
      groupId: map['group_id'] as String?,
      description: map['description'] as String?,
      isActive: _readBool(map, ['is_active', 'active', 'activa']),
      stripeProductId: map['stripe_product_id'] as String?,
      stripePriceId: map['stripe_price_id'] as String?,
      createdAt: _readDate(map['created_at']) ?? DateTime.now(),
      updatedAt: _readDate(map['updated_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'admin_id': adminId,
      'branch_id': branchId,
      'name': name,
      'amount_cents': amountCents,
      'currency': currency,
      'period_type': periodType,
      'period_count': periodCount,
      'group_id': groupId,
      'description': description,
      'is_active': isActive,
      'stripe_product_id': stripeProductId,
      'stripe_price_id': stripePriceId,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  PaymentTariff copyWith({
    String? id,
    String? adminId,
    String? branchId,
    String? name,
    int? amountCents,
    String? currency,
    String? periodType,
    int? periodCount,
    String? groupId,
    String? description,
    bool? isActive,
    String? stripeProductId,
    String? stripePriceId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentTariff(
      id: id ?? this.id,
      adminId: adminId ?? this.adminId,
      branchId: branchId ?? this.branchId,
      name: name ?? this.name,
      amountCents: amountCents ?? this.amountCents,
      currency: currency ?? this.currency,
      periodType: periodType ?? this.periodType,
      periodCount: periodCount ?? this.periodCount,
      groupId: groupId ?? this.groupId,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      stripeProductId: stripeProductId ?? this.stripeProductId,
      stripePriceId: stripePriceId ?? this.stripePriceId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

DateTime? _readDate(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  return null;
}

bool _readBool(Map<String, dynamic> map, List<String> keys, {bool fallback = true}) {
  for (final key in keys) {
    final value = map[key];
    if (value is bool) {
      return value;
    }
  }
  return fallback;
}
