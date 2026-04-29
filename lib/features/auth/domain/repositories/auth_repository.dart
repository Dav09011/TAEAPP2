import 'package:tae_app/features/auth/domain/entities/app_user.dart';
import 'package:tae_app/features/auth/domain/entities/registration_request.dart';

abstract class AuthRepository {
  Future<AppUser> signIn({
    required String email,
    required String password,
  });

  Future<AppUser> register(RegistrationRequest request);

  Future<void> sendPasswordResetEmail(String email);

  Future<void> signOut();
}
