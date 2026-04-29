class UpdateAdminProfileRequest {
  const UpdateAdminProfileRequest({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.middleName,
    required this.phone,
  });

  final String userId;
  final String firstName;
  final String lastName;
  final String middleName;
  final String phone;
}
