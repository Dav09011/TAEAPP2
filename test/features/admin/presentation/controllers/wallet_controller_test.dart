import 'package:flutter_test/flutter_test.dart';
import 'package:tae_app/features/admin/domain/entities/admin_cash_payment_request.dart';
import 'package:tae_app/features/admin/domain/entities/admin_wallet_branch_summary.dart';
import 'package:tae_app/features/admin/domain/entities/admin_wallet_student_status.dart';
import 'package:tae_app/features/admin/domain/repositories/admin_wallet_repository.dart';
import 'package:tae_app/features/admin/presentation/controllers/wallet_controller.dart';
import 'package:tae_app/features/admin/presentation/controllers/wallet_fees_controller.dart';
import 'package:tae_app/features/payments/domain/entities/payment_tariff.dart';

void main() {
  test('WalletController exposes aggregate performance totals', () async {
    final repository = _FakeAdminWalletRepository(
      branches: const [
        AdminWalletBranchSummary(
          branchId: 'b1',
          branchName: 'Centro',
          groupsCount: 2,
          studentsCount: 15,
          paidCount: 10,
          pendingCount: 3,
          totalPaidCents: 350000,
          totalPendingCents: 90000,
          cashRequestsCount: 2,
        ),
        AdminWalletBranchSummary(
          branchId: 'b2',
          branchName: 'Norte',
          groupsCount: 1,
          studentsCount: 8,
          paidCount: 4,
          pendingCount: 1,
          totalPaidCents: 140000,
          totalPendingCents: 30000,
          cashRequestsCount: 1,
        ),
      ],
    );
    final controller = WalletController(walletRepository: repository);

    await controller.initialize();
    await pumpEventQueue();

    expect(controller.adminName, 'Admin');
    expect(controller.totalPaidCount, 14);
    expect(controller.totalPendingCount, 4);
    expect(controller.totalIncomeCents, 490000);
    expect(controller.totalPendingCents, 120000);
    expect(controller.totalStudentsCount, 23);
    expect(controller.totalGroupsCount, 3);
    expect(controller.totalCashRequestsCount, 3);
    expect(controller.paidShare, closeTo(14 / 18, 0.001));

    controller.dispose();
  });

  test(
    'WalletFeesController maps branches and delegates active state',
    () async {
      final repository = _FakeAdminWalletRepository(
        branches: const [
          AdminWalletBranchSummary(
            branchId: 'b1',
            branchName: 'Centro',
            groupsCount: 1,
            studentsCount: 5,
            paidCount: 2,
            pendingCount: 1,
            totalPaidCents: 100000,
            totalPendingCents: 50000,
            cashRequestsCount: 0,
          ),
        ],
        tariffs: [
          PaymentTariff(
            id: 't1',
            adminId: 'admin-1',
            branchId: 'b1',
            name: 'Mensualidad',
            amountCents: 50000,
            currency: 'mxn',
            periodType: 'month',
            periodCount: 1,
            isActive: true,
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
          ),
        ],
      );
      final controller = WalletFeesController(repository: repository);

      controller.bind();
      await pumpEventQueue();

      expect(controller.branchNameFor('b1'), 'Centro');
      expect(controller.branchNameFor('missing'), 'missing');
      expect(controller.tariffs.single.id, 't1');

      await controller.saveTariff(
        tariffId: 't1',
        branchId: 'b1',
        name: 'Mensualidad',
        amountCents: 50000,
        currency: 'mxn',
        periodType: 'month',
        periodCount: 1,
        isActive: false,
      );

      expect(repository.savedTariffId, 't1');
      expect(repository.savedIsActive, isFalse);

      controller.dispose();
    },
  );
}

class _FakeAdminWalletRepository implements AdminWalletRepository {
  _FakeAdminWalletRepository({
    this.branches = const [],
    this.tariffs = const [],
  });

  final List<AdminWalletBranchSummary> branches;
  final List<PaymentTariff> tariffs;

  String? savedTariffId;
  bool? savedIsActive;

  @override
  String? get currentUserId => 'admin-1';

  @override
  Future<String> getCurrentAdminFirstName() async => 'Admin';

  @override
  Stream<List<AdminWalletBranchSummary>> watchBranchSummaries() {
    return Stream.value(branches);
  }

  @override
  Stream<List<PaymentTariff>> watchTariffs() {
    return Stream.value(tariffs);
  }

  @override
  Stream<List<AdminCashPaymentRequest>> watchCashRequests() {
    return const Stream.empty();
  }

  @override
  Future<List<AdminWalletStudentStatus>> loadStudentStatuses({
    String? branchId,
    String? groupId,
  }) async {
    return const [];
  }

  @override
  Future<List<AdminWalletStudentStatus>> loadCashPaymentCandidates({
    String? branchId,
    String? groupId,
  }) async {
    return const [];
  }

  @override
  Future<String> createCashPaymentRequest({
    required String studentId,
    required String studentName,
    required String branchId,
    required String branchName,
    required String groupId,
    required String groupName,
    required int amountCents,
    String? note,
  }) async {
    return 'request-1';
  }

  @override
  Future<void> approveCashPaymentRequest(String requestId) async {}

  @override
  Future<void> rejectCashPaymentRequest(String requestId) async {}

  @override
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
    bool isActive = true,
  }) async {
    savedTariffId = tariffId;
    savedIsActive = isActive;
  }

  @override
  Future<void> deleteTariff(String tariffId) async {}
}
