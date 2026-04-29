class AdminProfile {
  const AdminProfile({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.middleName,
    required this.email,
    required this.phone,
    required this.role,
    required this.imageUrl,
  });

  final String userId;
  final String firstName;
  final String lastName;
  final String middleName;
  final String email;
  final String phone;
  final String role;
  final String imageUrl;

  String get fullName => '$firstName $lastName $middleName'.trim();
}
