import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:tae_app/core/errors/app_exception.dart';
import 'package:tae_app/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:tae_app/features/auth/domain/entities/app_user.dart';
import 'package:tae_app/features/auth/domain/entities/registration_request.dart';
import 'package:tae_app/features/auth/domain/repositories/auth_repository.dart';

/// Shared controller for registration screens.
///
/// Different UI flows can reuse the same registration boundary while still
/// deciding their own navigation after a successful response.
class RegisterAccountController extends ChangeNotifier {
  RegisterAccountController({AuthRepository? authRepository})
    : _authRepository = authRepository ?? FirebaseAuthRepository();

  final AuthRepository _authRepository;

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Future<AppUser> register(RegistrationRequest request) async {
    _setLoading(true);
    try {
      return await _authRepository.register(request);
    } on FirebaseAuthException catch (error) {
      throw AppException(_mapFirebaseAuthError(error));
    } catch (error) {
      if (error is AppException) rethrow;
      throw const AppException('Ocurrio un error inesperado.');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  String _mapFirebaseAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'El correo ya esta registrado.';
      case 'weak-password':
        return 'La contrasena es demasiado debil.';
      case 'invalid-email':
        return 'El formato del correo es incorrecto.';
      default:
        return 'Error de registro.';
    }
  }
}
