import 'package:tae_app/features/payments/domain/entities/payment_tariff.dart';
import 'package:tae_app/features/student/domain/entities/student_wallet_branch_summary.dart';

abstract class StudentWalletRepository {
  String? get currentUserId;

  Stream<List<StudentWalletBranchSummary>> watchWalletBranches();

  Future<List<PaymentTariff>> loadAvailableTariffs(String branchId);

  Future<void> setPendingTariff({
    required String branchId,
    required String tariffId,
  });

  Future<void> clearPendingTariff(String branchId);

  Future<String> createCashPaymentRequest({
    required String branchId,
    required String groupId,
    required String tariffId,
    required String tariffName,
    required int amountCents,
    String? note,
  });

  Stream<bool> watchHasPendingCashRequest();
}
