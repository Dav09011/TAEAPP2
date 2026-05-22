class AdminStudent {
  const AdminStudent({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.belt,
    this.userId = '',
    this.lastName = '',
    this.middleName = '',
    this.email = '',
    this.phone = '',
    this.role = '',
  });

  final String id;
  final String name;
  final String imageUrl;
  final String belt;
  final String userId;
  final String lastName;
  final String middleName;
  final String email;
  final String phone;
  final String role;

  String get fullName => '$name $lastName $middleName'.trim();
}
