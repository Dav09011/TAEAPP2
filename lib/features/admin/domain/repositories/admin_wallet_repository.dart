import 'package:tae_app/features/admin/domain/entities/admin_cash_payment_request.dart';
import 'package:tae_app/features/admin/domain/entities/admin_wallet_branch_summary.dart';
import 'package:tae_app/features/admin/domain/entities/admin_wallet_student_status.dart';
import 'package:tae_app/features/payments/domain/entities/payment_tariff.dart';

abstract class AdminWalletRepository {
  String? get currentUserId;

  Future<String> getCurrentAdminFirstName();

  Stream<List<AdminWalletBranchSummary>> watchBranchSummaries();

  Stream<List<PaymentTariff>> watchTariffs();

  Stream<List<AdminCashPaymentRequest>> watchCashRequests();

  Future<List<AdminWalletStudentStatus>> loadStudentStatuses({
    String? branchId,
    String? groupId,
  });

  Future<List<AdminWalletStudentStatus>> loadCashPaymentCandidates({
    String? branchId,
    String? groupId,
  });

  Future<String> createCashPaymentRequest({
    required String studentId,
    required String studentName,
    required String branchId,
    required String branchName,
    required String groupId,
    required String groupName,
    required int amountCents,
    String? note,
  });

  Future<void> approveCashPaymentRequest(String requestId);

  Future<void> rejectCashPaymentRequest(String requestId);

  Future<void> createOrUpdateTariff({
    String? tariffId,
    required String branchId,
    required String name,
    required int amountCents,
    required String currency,
    required String periodType,
    required int periodCount,
    String? groupId,
    String? description,
    bool isActive,
  });

  Future<void> deleteTariff(String tariffId);
}
