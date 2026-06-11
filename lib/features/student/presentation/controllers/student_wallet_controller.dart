import 'package:tae_app/core/errors/app_exception.dart';
import 'package:tae_app/features/payments/domain/entities/payment_tariff.dart';
import 'package:tae_app/features/student/data/repositories/firebase_student_wallet_repository.dart';
import 'package:tae_app/features/student/domain/entities/student_wallet_branch_summary.dart';
import 'package:tae_app/features/student/domain/repositories/student_wallet_repository.dart';

class StudentWalletController {
  StudentWalletController({StudentWalletRepository? repository})
      : _repository = repository ?? FirebaseStudentWalletRepository();

  final StudentWalletRepository _repository;

  Stream<List<StudentWalletBranchSummary>> watchWalletBranches() {
    return _repository.watchWalletBranches();
  }

  Stream<bool> watchHasPendingCashRequest() {
    return _repository.watchHasPendingCashRequest();
  }

  Future<List<PaymentTariff>> loadAvailableTariffs(String branchId) {
    return _repository.loadAvailableTariffs(branchId);
  }

  Future<void> setPendingTariff({
    required String branchId,
    required String tariffId,
  }) {
    return _repository.setPendingTariff(
      branchId: branchId,
      tariffId: tariffId,
    );
  }

  Future<void> clearPendingTariff(String branchId) {
    return _repository.clearPendingTariff(branchId);
  }

  Future<String> createCashPaymentRequest({
    required String branchId,
    required String groupId,
    required String tariffId,
    required String tariffName,
    required int amountCents,
    String? note,
  }) {
    return _repository.createCashPaymentRequest(
      branchId: branchId,
      groupId: groupId,
      tariffId: tariffId,
      tariffName: tariffName,
      amountCents: amountCents,
      note: note,
    );
  }

  String errorMessage(Object error) {
    if (error is AppException) {
      return error.message;
    }
    return 'No se pudo completar la acción.';
  }
}
