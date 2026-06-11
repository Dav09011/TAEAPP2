import 'package:flutter/foundation.dart';
import 'package:tae_app/features/payments/data/repositories/firebase_payments_repository.dart';
import 'package:tae_app/features/payments/data/services/url_launcher_checkout_launcher.dart';
import 'package:tae_app/features/payments/domain/entities/create_payment_charge_request.dart';
import 'package:tae_app/features/payments/domain/entities/create_payment_discount_code_request.dart';
import 'package:tae_app/features/payments/domain/entities/create_payment_tariff_request.dart';
import 'package:tae_app/features/payments/domain/entities/payment_charge.dart';
import 'package:tae_app/features/payments/domain/entities/payment_discount_code.dart';
import 'package:tae_app/features/payments/domain/entities/payment_tariff.dart';
import 'package:tae_app/features/payments/domain/repositories/payments_repository.dart';
import 'package:tae_app/features/payments/domain/services/checkout_launcher.dart';
import 'dart:async';

class PaymentsController extends ChangeNotifier {
  PaymentsController({PaymentsRepository? repository})
      : _repository = repository ?? FirebasePaymentsRepository();

  final PaymentsRepository _repository;
  final CheckoutLauncher _checkoutLauncher = UrlLauncherCheckoutLauncher();
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  List<PaymentTariff> _tariffs = const [];
  List<PaymentDiscountCode> _discountCodes = const [];
  List<PaymentCharge> _charges = const [];

  List<PaymentTariff> get tariffs => List.unmodifiable(_tariffs);
  List<PaymentDiscountCode> get discountCodes => List.unmodifiable(_discountCodes);
  List<PaymentCharge> get charges => List.unmodifiable(_charges);

  void bindAdmin(String adminId) {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();

    _subscriptions.add(
      _repository.watchTariffsByAdmin(adminId).listen((items) {
        _tariffs = items;
        notifyListeners();
      }),
    );
    _subscriptions.add(
      _repository.watchDiscountCodesByAdmin(adminId).listen((items) {
        _discountCodes = items;
        notifyListeners();
      }),
    );
    _subscriptions.add(
      _repository.watchChargesByAdmin(adminId).listen((items) {
        _charges = items;
        notifyListeners();
      }),
    );
  }

  Future<String> createTariff(CreatePaymentTariffRequest request) {
    return _repository.createTariff(request);
  }

  Future<String> createDiscountCode(CreatePaymentDiscountCodeRequest request) {
    return _repository.createDiscountCode(request);
  }

  Future<String> createCharge(CreatePaymentChargeRequest request) {
    return _repository.createCharge(request);
  }

  Future<bool> openCheckoutUrl(String url) {
    return _checkoutLauncher.openUrl(url);
  }

  Future<PaymentDiscountCode?> findDiscountCode(String adminId, String code) {
    return _repository.findDiscountCodeByValue(adminId, code);
  }

  Future<void> markChargeAsPaid({
    required String adminId,
    required String chargeId,
    required String paymentIntentId,
    String? checkoutSessionId,
  }) {
    return _repository.markChargeAsPaid(
      adminId: adminId,
      chargeId: chargeId,
      paymentIntentId: paymentIntentId,
      checkoutSessionId: checkoutSessionId,
    );
  }

  Future<void> markDiscountCodeAsUsed({
    required String adminId,
    required String discountCodeId,
    required String studentId,
    required String chargeId,
  }) {
    return _repository.markDiscountCodeAsUsed(
      adminId: adminId,
      discountCodeId: discountCodeId,
      studentId: studentId,
      chargeId: chargeId,
    );
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    super.dispose();
  }
}
