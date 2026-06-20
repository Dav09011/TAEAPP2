import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:tae_app/features/admin/data/repositories/firebase_admin_wallet_repository.dart';
import 'package:tae_app/features/admin/domain/entities/admin_wallet_branch_summary.dart';
import 'package:tae_app/features/admin/domain/repositories/admin_wallet_repository.dart';
import 'package:tae_app/features/payments/domain/entities/payment_tariff.dart';

class WalletFeesController extends ChangeNotifier {
  WalletFeesController({AdminWalletRepository? repository})
    : _repository = repository ?? FirebaseAdminWalletRepository();

  final AdminWalletRepository _repository;
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  List<PaymentTariff> _tariffs = const [];
  List<AdminWalletBranchSummary> _branches = const [];
  bool _isLoading = true;

  List<PaymentTariff> get tariffs => List.unmodifiable(_tariffs);
  List<AdminWalletBranchSummary> get branches => List.unmodifiable(_branches);
  bool get isLoading => _isLoading;

  String branchNameFor(String branchId) {
    for (final branch in _branches) {
      if (branch.branchId == branchId) {
        return branch.branchName;
      }
    }
    return branchId.isEmpty ? 'Sin sucursal' : branchId;
  }

  Stream<List<AdminWalletBranchSummary>> watchBranches() {
    return _repository.watchBranchSummaries();
  }

  void bind() {
    final adminId = _repository.currentUserId;
    if (adminId == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();

    _subscriptions.add(
      _repository.watchTariffs().listen((items) {
        _tariffs = items;
        _isLoading = false;
        notifyListeners();
      }),
    );
    _subscriptions.add(
      _repository.watchBranchSummaries().listen((items) {
        _branches = items;
        notifyListeners();
      }),
    );
  }

  Future<void> saveTariff({
    String? tariffId,
    required String branchId,
    required String name,
    required int amountCents,
    required String currency,
    required String periodType,
    required int periodCount,
    String? groupId,
    String? description,
    bool isActive = true,
  }) {
    return _repository.createOrUpdateTariff(
      tariffId: tariffId,
      branchId: branchId,
      name: name,
      amountCents: amountCents,
      currency: currency,
      periodType: periodType,
      periodCount: periodCount,
      groupId: groupId,
      description: description,
      isActive: isActive,
    );
  }

  Future<void> saveTariffForBranches({
    required List<String> branchIds,
    required String name,
    required int amountCents,
    required String currency,
    required String periodType,
    required int periodCount,
    String? groupId,
    String? description,
    bool isActive = true,
  }) {
    return _repository.createTariffsForBranches(
      branchIds: branchIds,
      name: name,
      amountCents: amountCents,
      currency: currency,
      periodType: periodType,
      periodCount: periodCount,
      groupId: groupId,
      description: description,
      isActive: isActive,
    );
  }

  Future<void> deleteTariff(String tariffId) {
    return _repository.deleteTariff(tariffId);
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
