enum StudentBillingState {
  upToDate,
  pending,
  scholarship,
  none,
}

class StudentBillingStatus {
  final String name;
  final String groupName;
  final String billingLabel;
  final String lastPaymentLabel;
  final StudentBillingState state;

  StudentBillingStatus({
    required this.name,
    required this.groupName,
    required this.billingLabel,
    required this.lastPaymentLabel,
    required this.state,
  });
}