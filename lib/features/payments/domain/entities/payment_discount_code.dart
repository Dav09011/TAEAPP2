import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentDiscountCode {
  const PaymentDiscountCode({
    required this.id,
    required this.adminId,
    required this.code,
    required this.kind,
    required this.value,
    required this.maxUses,
    required this.usesCount,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.branchId,
    this.groupId,
    this.tariffId,
    this.expiresAt,
    this.usedByStudentId,
    this.usedByChargeId,
    this.usedAt,
  });

  final String id;
  final String adminId;
  final String code;
  final String kind;
  final int value;
  final String? branchId;
  final String? groupId;
  final String? tariffId;
  final int maxUses;
  final int usesCount;
  final bool isActive;
  final DateTime? expiresAt;
  final String? usedByStudentId;
  final String? usedByChargeId;
  final DateTime? usedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isExhausted => usesCount >= maxUses;

  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  factory PaymentDiscountCode.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return PaymentDiscountCode(
      id: id,
      adminId: map['admin_id'] as String? ?? '',
      code: map['code'] as String? ?? '',
      kind: map['kind'] as String? ?? 'fixed',
      value: (map['value'] as num?)?.toInt() ?? 0,
      branchId: map['branch_id'] as String?,
      groupId: map['group_id'] as String?,
      tariffId: map['tariff_id'] as String?,
      maxUses: (map['max_uses'] as num?)?.toInt() ??
          (map['max_users'] as num?)?.toInt() ??
          1,
      usesCount: (map['uses_count'] as num?)?.toInt() ?? 0,
      isActive: _readBool(map, ['is_active', 'active', 'activa']),
      expiresAt: _readDate(map['expires_at']),
      usedByStudentId: map['used_by_student_id'] as String?,
      usedByChargeId: map['used_by_charge_id'] as String?,
      usedAt: _readDate(map['used_at']),
      createdAt: _readDate(map['created_at']) ?? DateTime.now(),
      updatedAt: _readDate(map['updated_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'admin_id': adminId,
      'code': code,
      'kind': kind,
      'value': value,
      'branch_id': branchId,
      'group_id': groupId,
      'tariff_id': tariffId,
      'max_uses': maxUses,
      'uses_count': usesCount,
      'is_active': isActive,
      'expires_at': expiresAt == null ? null : Timestamp.fromDate(expiresAt!),
      'used_by_student_id': usedByStudentId,
      'used_by_charge_id': usedByChargeId,
      'used_at': usedAt == null ? null : Timestamp.fromDate(usedAt!),
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  PaymentDiscountCode copyWith({
    String? id,
    String? adminId,
    String? code,
    String? kind,
    int? value,
    String? branchId,
    String? groupId,
    String? tariffId,
    int? maxUses,
    int? usesCount,
    bool? isActive,
    DateTime? expiresAt,
    String? usedByStudentId,
    String? usedByChargeId,
    DateTime? usedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentDiscountCode(
      id: id ?? this.id,
      adminId: adminId ?? this.adminId,
      code: code ?? this.code,
      kind: kind ?? this.kind,
      value: value ?? this.value,
      branchId: branchId ?? this.branchId,
      groupId: groupId ?? this.groupId,
      tariffId: tariffId ?? this.tariffId,
      maxUses: maxUses ?? this.maxUses,
      usesCount: usesCount ?? this.usesCount,
      isActive: isActive ?? this.isActive,
      expiresAt: expiresAt ?? this.expiresAt,
      usedByStudentId: usedByStudentId ?? this.usedByStudentId,
      usedByChargeId: usedByChargeId ?? this.usedByChargeId,
      usedAt: usedAt ?? this.usedAt,
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
