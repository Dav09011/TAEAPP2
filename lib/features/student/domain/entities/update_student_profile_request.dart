class UpdateStudentProfileRequest {
  const UpdateStudentProfileRequest({
    required this.firstName,
    required this.lastName,
    required this.middleName,
    required this.phone,
    required this.personalBelt,
    required this.personalBeltColorValue,
    required this.email,
  });

  final String firstName;
  final String lastName;
  final String middleName;
  final String phone;
  final String personalBelt;
  final int? personalBeltColorValue;
  final String email;
}

class StudentProfileUpdateResult {
  const StudentProfileUpdateResult({required this.emailVerificationSent});

  final bool emailVerificationSent;
}
