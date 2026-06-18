import 'package:tae_app/features/payments/domain/entities/payment_tariff.dart';
import 'package:tae_app/features/student/domain/entities/student_wallet_group_membership.dart';

class StudentWalletBranchSummary {
  const StudentWalletBranchSummary({
    required this.branchId,
    required this.branchName,
    required this.adminId,
    required this.groups,
    required this.availableTariffs,
    required this.hasPendingCashRequest,
    this.branchColorValue,
    this.currentTariffId,
    this.currentTariffName,
    this.currentTariffAmountCents,
    this.currentTariffPeriodType,
    this.currentTariffPeriodCount,
    this.pendingTariffId,
    this.pendingTariffName,
    this.pendingTariffAmountCents,
    this.pendingTariffPeriodType,
    this.pendingTariffPeriodCount,
    this.pendingCashRequestId,
  });

  final String branchId;
  final String branchName;
  final String adminId;
  final List<StudentWalletGroupMembership> groups;
  final List<PaymentTariff> availableTariffs;
  final bool hasPendingCashRequest;
  final int? branchColorValue;
  final String? currentTariffId;
  final String? currentTariffName;
  final int? currentTariffAmountCents;
  final String? currentTariffPeriodType;
  final int? currentTariffPeriodCount;
  final String? pendingTariffId;
  final String? pendingTariffName;
  final int? pendingTariffAmountCents;
  final String? pendingTariffPeriodType;
  final int? pendingTariffPeriodCount;
  final String? pendingCashRequestId;

  StudentWalletGroupMembership get primaryGroup => groups.first;

  String get currentTariffLabel =>
      currentTariffName ?? 'Mensualidad no definida';

  String get pendingTariffLabel => pendingTariffName ?? 'Sin cambio programado';

  String? get effectiveTariffId => pendingTariffId ?? currentTariffId;

  String? get effectiveTariffName => pendingTariffName ?? currentTariffName;

  int? get effectiveTariffAmountCents =>
      pendingTariffAmountCents ?? currentTariffAmountCents;

  String? get effectiveTariffPeriodType =>
      pendingTariffPeriodType ?? currentTariffPeriodType;

  int? get effectiveTariffPeriodCount =>
      pendingTariffPeriodCount ?? currentTariffPeriodCount;

  String get effectiveTariffLabel =>
      effectiveTariffName ?? 'Mensualidad no definida';

  String get currentAmountLabel =>
      currentTariffAmountCents == null
          ? '---'
          : '\$${(currentTariffAmountCents! / 100).toStringAsFixed(2)}';

  String get pendingAmountLabel =>
      pendingTariffAmountCents == null
          ? '---'
          : '\$${(pendingTariffAmountCents! / 100).toStringAsFixed(2)}';

  String get effectiveAmountLabel =>
      effectiveTariffAmountCents == null
          ? '---'
          : '\$${(effectiveTariffAmountCents! / 100).toStringAsFixed(2)}';
}
