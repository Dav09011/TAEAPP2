class StudentBillingStatus {
  const StudentBillingStatus({
    required this.id,
    required this.studentName,
    required this.groupName,
    required this.beltName,
    required this.amountLabel,
    required this.status,
    required this.lastPaymentLabel,
  });

  final String id;
  final String studentName;
  final String groupName;
  final String beltName;
  final String amountLabel;
  final StudentBillingState status;
  final String lastPaymentLabel;
}

enum StudentBillingState {
  upToDate,
  pending,
  scholarship,
}
