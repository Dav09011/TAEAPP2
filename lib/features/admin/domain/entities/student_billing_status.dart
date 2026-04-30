// student_billing_status.dart
enum StudentBillingState { upToDate, pending, scholarship, unregistered }

class StudentBillingStatus {
  final String id;
  final String name;
  final String groupName;
  final StudentBillingState state;
  final String billingLabel;
  final String lastPaymentLabel;

  StudentBillingStatus({
    required this.id,
    required this.name,
    required this.groupName,
    required this.state,
    required this.billingLabel,
    required this.lastPaymentLabel,
  });
}
