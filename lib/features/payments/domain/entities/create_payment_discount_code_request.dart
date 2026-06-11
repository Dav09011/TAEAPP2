class CreatePaymentDiscountCodeRequest {
  const CreatePaymentDiscountCodeRequest({
    required this.adminId,
    required this.code,
    required this.kind,
    required this.value,
    this.branchId,
    this.groupId,
    this.tariffId,
    this.maxUses = 1,
    this.isActive = true,
    this.expiresAtIso,
  });

  final String adminId;
  final String code;
  final String kind;
  final int value;
  final String? branchId;
  final String? groupId;
  final String? tariffId;
  final int maxUses;
  final bool isActive;
  final String? expiresAtIso;
}
