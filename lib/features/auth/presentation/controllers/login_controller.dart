import 'package:flutter/foundation.dart';
import 'package:tae_app/core/errors/app_exception.dart';
import 'package:tae_app/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:tae_app/features/auth/domain/entities/app_user.dart';
import 'package:tae_app/features/auth/domain/repositories/auth_repository.dart';

/// Coordinates the login flow for the presentation layer.
///
/// This controller is intentionally small:
/// - validates raw form values
/// - calls the auth repository
/// - translates low-level exceptions into UI-friendly messages
///
/// Widgets should depend on this controller instead of using Firebase APIs
/// directly. That makes the screen easier to test and keeps the future
/// migration path consistent with the rest of the module.
class LoginController extends ChangeNotifier {
  LoginController({AuthRepository? authRepository})
    : _authRepository = authRepository ?? FirebaseAuthRepository();

  final AuthRepository _authRepository;

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim();
    final normalizedPassword = password.trim();

    if (normalizedEmail.isEmpty || normalizedPassword.isEmpty) {
      throw const AppException('Por favor, ingresa tu email y contrasena.');
    }

    _setLoading(true);

    try {
      return await _authRepository.signIn(
        email: normalizedEmail,
        password: normalizedPassword,
      );
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }
}
