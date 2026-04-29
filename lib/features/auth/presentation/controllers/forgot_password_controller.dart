import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:tae_app/core/errors/app_exception.dart';
import 'package:tae_app/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:tae_app/features/auth/domain/repositories/auth_repository.dart';

/// Presentation controller for password reset.
class ForgotPasswordController extends ChangeNotifier {
  ForgotPasswordController({AuthRepository? authRepository})
    : _authRepository = authRepository ?? FirebaseAuthRepository();

  final AuthRepository _authRepository;

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Future<void> sendResetLink(String email) async {
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty) {
      throw const AppException(
        'Por favor, ingresa tu correo electronico.',
      );
    }

    _setLoading(true);
    try {
      await _authRepository.sendPasswordResetEmail(normalizedEmail);
    } on FirebaseAuthException catch (error) {
      throw AppException(_mapError(error));
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  String _mapError(FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found':
        return 'No encontramos ninguna cuenta con ese correo.';
      case 'invalid-email':
        return 'El formato del correo es incorrecto.';
      default:
        return 'Ocurrio un error inesperado.';
    }
  }
}
