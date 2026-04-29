import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:tae_app/core/errors/app_exception.dart';
import 'package:tae_app/features/admin/data/repositories/firebase_profile_repository.dart';
import 'package:tae_app/features/admin/domain/entities/admin_profile.dart';
import 'package:tae_app/features/admin/domain/entities/update_admin_profile_request.dart';
import 'package:tae_app/features/admin/domain/repositories/profile_repository.dart';

class ProfileController extends ChangeNotifier {
  ProfileController({ProfileRepository? profileRepository})
    : _profileRepository = profileRepository ?? FirebaseProfileRepository();

  final ProfileRepository _profileRepository;

  bool _isMutating = false;

  bool get isMutating => _isMutating;
  String? get currentUserId => _profileRepository.currentUserId;

  Stream<AdminProfile> watchCurrentProfile() {
    return _profileRepository.watchCurrentProfile();
  }

  Future<AdminProfile> getCurrentProfile() {
    return _profileRepository.getCurrentProfile();
  }

  Future<void> updateProfile(UpdateAdminProfileRequest request) {
    return _runMutation(() => _profileRepository.updateProfile(request));
  }

  Future<void> requestEmailChange({
    required String userId,
    required String currentEmail,
    required String newEmail,
  }) async {
    final normalized = newEmail.trim();
    if (normalized.isEmpty || normalized == currentEmail) {
      throw const AppException('Necesitas ingresar un correo diferente.');
    }

    try {
      await _runMutation(
        () => _profileRepository.requestEmailChange(
          userId: userId,
          newEmail: normalized,
        ),
      );
    } on FirebaseAuthException catch (error) {
      throw AppException(_mapEmailChangeError(error));
    }
  }

  Future<void> signOut() {
    return _runMutation(_profileRepository.signOut);
  }

  Future<void> _runMutation(Future<void> Function() action) async {
    _isMutating = true;
    notifyListeners();
    try {
      await action();
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  String _mapEmailChangeError(FirebaseAuthException error) {
    switch (error.code) {
      case 'requires-recent-login':
        return 'Por seguridad, debes cerrar sesion y volver a entrar para hacer este cambio.';
      case 'email-already-in-use':
        return 'Este correo ya esta registrado en otra cuenta.';
      case 'invalid-email':
        return 'El formato del correo es invalido.';
      default:
        return 'Error al actualizar el correo.';
    }
  }
}
