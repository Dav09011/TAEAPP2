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

    await _runMutation(
      () => _profileRepository.requestEmailChange(
        userId: userId,
        newEmail: normalized,
      ),
    );
  }

  Future<void> changePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    final trimmedEmail = email.trim();
    final trimmedNewPassword = newPassword.trim();
    if (trimmedEmail.isEmpty) {
      throw const AppException('No encontramos el correo actual.');
    }
    if (currentPassword.isEmpty || trimmedNewPassword.isEmpty) {
      throw const AppException('Ingresa tu contrasena actual y la nueva.');
    }
    if (trimmedNewPassword.length < 6) {
      throw const AppException(
        'La nueva contrasena debe tener al menos 6 caracteres.',
      );
    }

    await _runMutation(
      () => _profileRepository.changePassword(
        email: trimmedEmail,
        currentPassword: currentPassword,
        newPassword: trimmedNewPassword,
      ),
    );
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
}
