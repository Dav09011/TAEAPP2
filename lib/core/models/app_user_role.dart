enum AppUserRole {
  admin,
  student,
  teacher,
  unknown;

  static AppUserRole fromValue(String? value) {
    switch (value) {
      case 'admin':
        return AppUserRole.admin;
      case 'alumno':
        return AppUserRole.student;
      case 'maestro':
        return AppUserRole.teacher;
      default:
        return AppUserRole.unknown;
    }
  }
}
