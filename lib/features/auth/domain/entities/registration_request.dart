/// Immutable payload used by auth registration flows.
///
/// We keep it in `domain/` because both admin and student registration share
/// the same business data, even if their screens are still different today.
class RegistrationRequest {
  const RegistrationRequest({
    required this.firstName,
    required this.lastName,
    required this.middleName,
    required this.email,
    required this.phone,
    required this.password,
    required this.role,
    required this.profileCategory,
  });

  final String firstName;
  final String lastName;
  final String middleName;
  final String email;
  final String phone;
  final String password;
  final String role;
  final String profileCategory;
}
