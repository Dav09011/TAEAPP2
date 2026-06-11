class AdminWalletBranchSummary {
  const AdminWalletBranchSummary({
    required this.branchId,
    required this.branchName,
    required this.groupsCount,
    required this.studentsCount,
    required this.paidCount,
    required this.pendingCount,
    required this.totalPaidCents,
    required this.totalPendingCents,
    required this.cashRequestsCount,
  });

  final String branchId;
  final String branchName;
  final int groupsCount;
  final int studentsCount;
  final int paidCount;
  final int pendingCount;
  final int totalPaidCents;
  final int totalPendingCents;
  final int cashRequestsCount;

  String get paidLabel => _formatMoney(totalPaidCents);

  String get pendingLabel => _formatMoney(totalPendingCents);

  static String _formatMoney(int cents) {
    final value = cents / 100.0;
    return '\$${value.toStringAsFixed(2)}';
  }
}
