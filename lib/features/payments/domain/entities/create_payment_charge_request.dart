class CreatePaymentChargeRequest {
  const CreatePaymentChargeRequest({
    required this.adminId,
    required this.studentId,
    required this.studentName,
    required this.tariffId,
    required this.tariffName,
    required this.branchId,
    required this.branchName,
    required this.groupId,
    required this.groupName,
    required this.amountCents,
    required this.currency,
    required this.periodStartIso,
    required this.periodEndIso,
    this.discountCodeId,
    this.discountCode,
    this.discountAmountCents = 0,
    this.provider = 'stripe',
    this.checkoutUrl,
  });

  final String adminId;
  final String studentId;
  final String studentName;
  final String tariffId;
  final String tariffName;
  final String branchId;
  final String branchName;
  final String groupId;
  final String groupName;
  final int amountCents;
  final String currency;
  final String periodStartIso;
  final String periodEndIso;
  final String? discountCodeId;
  final String? discountCode;
  final int discountAmountCents;
  final String provider;
  final String? checkoutUrl;
}
