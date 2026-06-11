import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentCharge {
  const PaymentCharge({
    required this.id,
    required this.adminId,
    required this.studentId,
    required this.studentName,
    required this.tariffId,
    required this.tariffName,
    required this.branchId,
    required this.branchName,
    required this.groupId,
    required this.groupName,
    required this.amountCents,
    required this.currency,
    required this.discountAmountCents,
    required this.totalAmountCents,
    required this.provider,
    required this.status,
    required this.periodStart,
    required this.periodEnd,
    required this.createdAt,
    required this.updatedAt,
    this.discountCodeId,
    this.discountCode,
    this.checkoutSessionId,
    this.checkoutUrl,
    this.paymentIntentId,
    this.invoiceId,
    this.paidAt,
  });

  final String id;
  final String adminId;
  final String studentId;
  final String studentName;
  final String tariffId;
  final String tariffName;
  final String branchId;
  final String branchName;
  final String groupId;
  final String groupName;
  final int amountCents;
  final String currency;
  final int discountAmountCents;
  final int totalAmountCents;
  final String provider;
  final String status;
  final DateTime periodStart;
  final DateTime periodEnd;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? discountCodeId;
  final String? discountCode;
  final String? checkoutSessionId;
  final String? checkoutUrl;
  final String? paymentIntentId;
  final String? invoiceId;
  final DateTime? paidAt;

  factory PaymentCharge.fromMap(String id, Map<String, dynamic> map) {
    return PaymentCharge(
      id: id,
      adminId: map['admin_id'] as String? ?? '',
      studentId: map['student_id'] as String? ?? '',
      studentName: map['student_name'] as String? ?? '',
      tariffId: map['tariff_id'] as String? ?? '',
      tariffName: map['tariff_name'] as String? ?? '',
      branchId: map['branch_id'] as String? ?? '',
      branchName: map['branch_name'] as String? ?? '',
      groupId: map['group_id'] as String? ?? '',
      groupName: map['group_name'] as String? ?? '',
      amountCents: (map['amount_cents'] as num?)?.toInt() ?? 0,
      currency: map['currency'] as String? ?? 'mxn',
      discountAmountCents: (map['discount_amount_cents'] as num?)?.toInt() ?? 0,
      totalAmountCents: (map['total_amount_cents'] as num?)?.toInt() ?? 0,
      provider: map['provider'] as String? ?? 'stripe',
      status: map['status'] as String? ?? 'pending',
      periodStart: _readDate(map['period_start']) ?? DateTime.now(),
      periodEnd: _readDate(map['period_end']) ?? DateTime.now(),
      createdAt: _readDate(map['created_at']) ?? DateTime.now(),
      updatedAt: _readDate(map['updated_at']) ?? DateTime.now(),
      discountCodeId: map['discount_code_id'] as String?,
      discountCode: map['discount_code'] as String?,
      checkoutSessionId: map['checkout_session_id'] as String?,
      checkoutUrl: map['checkout_url'] as String?,
      paymentIntentId: map['payment_intent_id'] as String?,
      invoiceId: map['invoice_id'] as String?,
      paidAt: _readDate(map['paid_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'admin_id': adminId,
      'student_id': studentId,
      'student_name': studentName,
      'tariff_id': tariffId,
      'tariff_name': tariffName,
      'branch_id': branchId,
      'branch_name': branchName,
      'group_id': groupId,
      'group_name': groupName,
      'amount_cents': amountCents,
      'currency': currency,
      'discount_amount_cents': discountAmountCents,
      'total_amount_cents': totalAmountCents,
      'provider': provider,
      'status': status,
      'period_start': Timestamp.fromDate(periodStart),
      'period_end': Timestamp.fromDate(periodEnd),
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
      'discount_code_id': discountCodeId,
      'discount_code': discountCode,
      'checkout_session_id': checkoutSessionId,
      'checkout_url': checkoutUrl,
      'payment_intent_id': paymentIntentId,
      'invoice_id': invoiceId,
      'paid_at': paidAt == null ? null : Timestamp.fromDate(paidAt!),
    };
  }

  PaymentCharge copyWith({
    String? id,
    String? adminId,
    String? studentId,
    String? studentName,
    String? tariffId,
    String? tariffName,
    String? branchId,
    String? branchName,
    String? groupId,
    String? groupName,
    int? amountCents,
    String? currency,
    int? discountAmountCents,
    int? totalAmountCents,
    String? provider,
    String? status,
    DateTime? periodStart,
    DateTime? periodEnd,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? discountCodeId,
    String? discountCode,
    String? checkoutSessionId,
    String? checkoutUrl,
    String? paymentIntentId,
    String? invoiceId,
    DateTime? paidAt,
  }) {
    return PaymentCharge(
      id: id ?? this.id,
      adminId: adminId ?? this.adminId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      tariffId: tariffId ?? this.tariffId,
      tariffName: tariffName ?? this.tariffName,
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      amountCents: amountCents ?? this.amountCents,
      currency: currency ?? this.currency,
      discountAmountCents: discountAmountCents ?? this.discountAmountCents,
      totalAmountCents: totalAmountCents ?? this.totalAmountCents,
      provider: provider ?? this.provider,
      status: status ?? this.status,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      discountCodeId: discountCodeId ?? this.discountCodeId,
      discountCode: discountCode ?? this.discountCode,
      checkoutSessionId: checkoutSessionId ?? this.checkoutSessionId,
      checkoutUrl: checkoutUrl ?? this.checkoutUrl,
      paymentIntentId: paymentIntentId ?? this.paymentIntentId,
      invoiceId: invoiceId ?? this.invoiceId,
      paidAt: paidAt ?? this.paidAt,
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
