import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;
import 'package:tae_app/core/services/auth_service.dart';
import 'package:tae_app/core/services/firestore_service.dart';
import 'package:tae_app/features/payments/domain/entities/create_payment_charge_request.dart';
import 'package:tae_app/features/payments/domain/entities/create_payment_discount_code_request.dart';
import 'package:tae_app/features/payments/domain/entities/create_payment_tariff_request.dart';
import 'package:tae_app/features/payments/domain/entities/payment_charge.dart';
import 'package:tae_app/features/payments/domain/entities/payment_discount_code.dart';
import 'package:tae_app/features/payments/domain/entities/payment_tariff.dart';
import 'package:tae_app/features/payments/domain/repositories/payments_repository.dart';

class FirebasePaymentsRepository implements PaymentsRepository {
  FirebasePaymentsRepository({
    AuthService? authService,
    FirestoreService? firestoreService,
  }) : _authService = authService ?? AuthService(),
       _firestoreService = firestoreService ?? FirestoreService();

  final AuthService _authService;
  final FirestoreService _firestoreService;

  @override
  String? get currentUserId => _authService.currentUser?.uid;

  @override
  Stream<List<PaymentTariff>> watchTariffsByAdmin(String adminId) {
    return _firestoreService
        .adminPaymentTariffs(adminId)
        .orderBy('updated_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PaymentTariff.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  @override
  Future<String> createTariff(CreatePaymentTariffRequest request) async {
    final now = DateTime.now();
    final doc = _firestoreService.adminPaymentTariffs(request.adminId).doc();

    await doc.set({
      'admin_id': request.adminId,
      'branch_id': request.branchId,
      'name': request.name,
      'amount_cents': request.amountCents,
      'currency': request.currency,
      'period_type': request.periodType,
      'period_count': request.periodCount,
      'group_id': request.groupId,
      'description': request.description,
      'is_active': request.isActive,
      'stripe_product_id': null,
      'stripe_price_id': null,
      'created_at': Timestamp.fromDate(now),
      'updated_at': Timestamp.fromDate(now),
    });

    return doc.id;
  }

  @override
  Future<void> updateTariff(PaymentTariff tariff) async {
    await _firestoreService
        .adminPaymentTariffs(tariff.adminId)
        .doc(tariff.id)
        .update(tariff.copyWith(updatedAt: DateTime.now()).toMap());
  }

  @override
  Future<void> deleteTariff(String adminId, String tariffId) async {
    await _firestoreService.adminPaymentTariffs(adminId).doc(tariffId).delete();
  }

  @override
  Stream<List<PaymentDiscountCode>> watchDiscountCodesByAdmin(String adminId) {
    return _firestoreService
        .adminPaymentDiscountCodes(adminId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PaymentDiscountCode.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  @override
  Future<String> createDiscountCode(
    CreatePaymentDiscountCodeRequest request,
  ) async {
    final now = DateTime.now();
    final expiresAt = request.expiresAtIso == null
        ? null
        : DateTime.tryParse(request.expiresAtIso!);
    final doc = _firestoreService.adminPaymentDiscountCodes(request.adminId).doc();

    await doc.set({
      'admin_id': request.adminId,
      'code': request.code.trim().toUpperCase(),
      'kind': request.kind,
      'value': request.value,
      'branch_id': request.branchId,
      'group_id': request.groupId,
      'tariff_id': request.tariffId,
      'max_uses': request.maxUses,
      'uses_count': 0,
      'is_active': request.isActive,
      'expires_at': expiresAt == null ? null : Timestamp.fromDate(expiresAt),
      'used_by_student_id': null,
      'used_by_charge_id': null,
      'used_at': null,
      'created_at': Timestamp.fromDate(now),
      'updated_at': Timestamp.fromDate(now),
    });

    return doc.id;
  }

  @override
  Future<PaymentDiscountCode?> findDiscountCodeByValue(
    String adminId,
    String code,
  ) async {
    final query = await _firestoreService
        .adminPaymentDiscountCodes(adminId)
        .where('code', isEqualTo: code.trim().toUpperCase())
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      return null;
    }

    final doc = query.docs.first;
    return PaymentDiscountCode.fromMap(doc.id, doc.data());
  }

  @override
  Future<void> markDiscountCodeAsUsed({
    required String adminId,
    required String discountCodeId,
    required String studentId,
    required String chargeId,
  }) async {
    await _firestoreService.adminPaymentDiscountCodes(adminId).doc(discountCodeId).update({
      'uses_count': FieldValue.increment(1),
      'used_by_student_id': studentId,
      'used_by_charge_id': chargeId,
      'used_at': Timestamp.fromDate(DateTime.now()),
      'updated_at': Timestamp.fromDate(DateTime.now()),
    });
  }

  @override
  Stream<List<PaymentCharge>> watchChargesByAdmin(String adminId) {
    return _firestoreService
        .adminPaymentCharges(adminId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PaymentCharge.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  @override
  Future<String> createCharge(CreatePaymentChargeRequest request) async {
    final now = DateTime.now();
    final periodStart = DateTime.tryParse(request.periodStartIso) ?? now;
    final periodEnd = DateTime.tryParse(request.periodEndIso) ?? now;
    final total = math.max(0, request.amountCents - request.discountAmountCents);
    final doc = _firestoreService.adminPaymentCharges(request.adminId).doc();

    await doc.set({
      'admin_id': request.adminId,
      'student_id': request.studentId,
      'student_name': request.studentName,
      'tariff_id': request.tariffId,
      'tariff_name': request.tariffName,
      'branch_id': request.branchId,
      'branch_name': request.branchName,
      'group_id': request.groupId,
      'group_name': request.groupName,
      'amount_cents': request.amountCents,
      'currency': request.currency,
      'discount_amount_cents': request.discountAmountCents,
      'total_amount_cents': total,
      'provider': request.provider,
      'status': 'pending',
      'period_start': Timestamp.fromDate(periodStart),
      'period_end': Timestamp.fromDate(periodEnd),
      'created_at': Timestamp.fromDate(now),
      'updated_at': Timestamp.fromDate(now),
      'discount_code_id': request.discountCodeId,
      'discount_code': request.discountCode,
      'checkout_url': request.checkoutUrl,
      'checkout_session_id': null,
      'payment_intent_id': null,
      'invoice_id': null,
      'paid_at': null,
    });

    return doc.id;
  }

  @override
  Future<void> updateCharge(PaymentCharge charge) async {
    await _firestoreService
        .adminPaymentCharges(charge.adminId)
        .doc(charge.id)
        .update(charge.copyWith(updatedAt: DateTime.now()).toMap());
  }

  @override
  Future<void> markChargeAsPaid({
    required String adminId,
    required String chargeId,
    required String paymentIntentId,
    String? checkoutSessionId,
    DateTime? paidAt,
  }) async {
    final now = paidAt ?? DateTime.now();
    await _firestoreService.adminPaymentCharges(adminId).doc(chargeId).update({
      'status': 'paid',
      'payment_intent_id': paymentIntentId,
      'checkout_session_id': checkoutSessionId,
      'paid_at': Timestamp.fromDate(now),
      'updated_at': Timestamp.fromDate(now),
    });
  }
}
