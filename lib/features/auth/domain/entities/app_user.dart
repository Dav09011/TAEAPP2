import 'package:tae_app/core/models/app_user_role.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
  });

  final String id;
  final String email;
  final String name;
  final AppUserRole role;
}
