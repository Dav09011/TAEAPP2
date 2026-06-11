class CreatePaymentTariffRequest {
  const CreatePaymentTariffRequest({
    required this.adminId,
    required this.branchId,
    required this.name,
    required this.amountCents,
    required this.currency,
    required this.periodType,
    required this.periodCount,
    this.groupId,
    this.description,
    this.isActive = true,
  });

  final String adminId;
  final String branchId;
  final String name;
  final int amountCents;
  final String currency;
  final String periodType;
  final int periodCount;
  final String? groupId;
  final String? description;
  final bool isActive;
}
