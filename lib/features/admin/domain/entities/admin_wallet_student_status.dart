class AdminWalletStudentStatus {
  const AdminWalletStudentStatus({
    required this.studentId,
    required this.studentName,
    required this.branchId,
    required this.branchName,
    required this.groupId,
    required this.groupName,
    required this.status,
    required this.billingLabel,
    required this.lastPaymentLabel,
    required this.lastPaymentCents,
    required this.pendingCents,
    required this.isScholarship,
  });

  final String studentId;
  final String studentName;
  final String branchId;
  final String branchName;
  final String groupId;
  final String groupName;
  final String status;
  final String billingLabel;
  final String lastPaymentLabel;
  final int lastPaymentCents;
  final int pendingCents;
  final bool isScholarship;

  bool get isPending => status == 'pending';
  bool get isPaid => status == 'paid';
}
