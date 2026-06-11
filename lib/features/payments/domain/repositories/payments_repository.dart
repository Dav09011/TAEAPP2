import 'package:tae_app/features/payments/domain/entities/create_payment_charge_request.dart';
import 'package:tae_app/features/payments/domain/entities/create_payment_discount_code_request.dart';
import 'package:tae_app/features/payments/domain/entities/create_payment_tariff_request.dart';
import 'package:tae_app/features/payments/domain/entities/payment_charge.dart';
import 'package:tae_app/features/payments/domain/entities/payment_discount_code.dart';
import 'package:tae_app/features/payments/domain/entities/payment_tariff.dart';

abstract class PaymentsRepository {
  String? get currentUserId;

  Stream<List<PaymentTariff>> watchTariffsByAdmin(String adminId);

  Future<String> createTariff(CreatePaymentTariffRequest request);

  Future<void> updateTariff(PaymentTariff tariff);

  Future<void> deleteTariff(String adminId, String tariffId);

  Stream<List<PaymentDiscountCode>> watchDiscountCodesByAdmin(String adminId);

  Future<String> createDiscountCode(CreatePaymentDiscountCodeRequest request);

  Future<PaymentDiscountCode?> findDiscountCodeByValue(
    String adminId,
    String code,
  );

  Future<void> markDiscountCodeAsUsed({
    required String adminId,
    required String discountCodeId,
    required String studentId,
    required String chargeId,
  });

  Stream<List<PaymentCharge>> watchChargesByAdmin(String adminId);

  Future<String> createCharge(CreatePaymentChargeRequest request);

  Future<void> updateCharge(PaymentCharge charge);

  Future<void> markChargeAsPaid({
    required String adminId,
    required String chargeId,
    required String paymentIntentId,
    String? checkoutSessionId,
    DateTime? paidAt,
  });
}
