import 'package:flutter_test/flutter_test.dart';
import 'package:tae_app/features/student/domain/entities/student_wallet_branch_summary.dart';

void main() {
  group('StudentWalletBranchSummary', () {
    test('uses pending tariff as effective tariff when present', () {
      const summary = StudentWalletBranchSummary(
        branchId: 'branch-1',
        branchName: 'Sucursal Villas',
        adminId: 'admin-1',
        groups: [],
        availableTariffs: [],
        hasPendingCashRequest: false,
        currentTariffId: 'basic',
        currentTariffName: 'Basica',
        currentTariffAmountCents: 9000,
        pendingTariffId: 'premium',
        pendingTariffName: 'Premium',
        pendingTariffAmountCents: 12000,
      );

      expect(summary.effectiveTariffId, 'premium');
      expect(summary.effectiveTariffLabel, 'Premium');
      expect(summary.effectiveAmountLabel, r'$120.00');
    });

    test(
      'uses current tariff as effective tariff when no pending change exists',
      () {
        const summary = StudentWalletBranchSummary(
          branchId: 'branch-1',
          branchName: 'Sucursal Villas',
          adminId: 'admin-1',
          groups: [],
          availableTariffs: [],
          hasPendingCashRequest: false,
          currentTariffId: 'basic',
          currentTariffName: 'Basica',
          currentTariffAmountCents: 9000,
        );

        expect(summary.effectiveTariffId, 'basic');
        expect(summary.effectiveTariffLabel, 'Basica');
        expect(summary.effectiveAmountLabel, r'$90.00');
      },
    );
  });
}
