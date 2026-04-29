import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tae_app/core/errors/app_exception.dart';
import 'package:tae_app/core/models/app_user_role.dart';
import 'package:tae_app/core/services/auth_service.dart';
import 'package:tae_app/core/services/firestore_service.dart';
import 'package:tae_app/features/auth/domain/entities/app_user.dart';
import 'package:tae_app/features/auth/domain/entities/registration_request.dart';
import 'package:tae_app/features/auth/domain/repositories/auth_repository.dart';

/// Firebase implementation for the auth boundary.
///
/// The goal of this repository is to keep widgets unaware of:
/// - FirebaseAuth APIs
/// - Firestore collection names
/// - profile document lookup details
///
/// As we migrate more auth screens, all reads and writes should flow through
/// this repository instead of talking directly to Firebase from the UI.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    AuthService? authService,
    FirestoreService? firestoreService,
  }) : _authService = authService ?? AuthService(),
       _firestoreService = firestoreService ?? FirestoreService();

  final AuthService _authService;
  final FirestoreService _firestoreService;

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _authService.signIn(
      email: email,
      password: password,
    );

    final profile =
        await _firestoreService.users().doc(credential.user!.uid).get();
    final data = profile.data();

    if (!profile.exists || data == null) {
      await _authService.signOut();
      throw const AppException('Error: usuario sin perfil asignado.');
    }

    return AppUser(
      id: credential.user!.uid,
      email: credential.user?.email ?? email,
      name: data['nombre'] as String? ?? '',
      role: AppUserRole.fromValue(data['tipo'] as String?),
    );
  }

  @override
  Future<AppUser> register(RegistrationRequest request) async {
    final credential = await _authService.register(
      email: request.email,
      password: request.password,
    );

    final user = AppUser(
      id: credential.user!.uid,
      email: credential.user?.email ?? request.email,
      name: request.firstName,
      role: AppUserRole.fromValue(request.role),
    );

    await _firestoreService.users().doc(user.id).set({
      'id_usuario': user.id,
      'nombre': request.firstName,
      'ap': request.lastName,
      'am': request.middleName,
      'correo': user.email,
      'telefono': request.phone,
      'tipo': request.role,
      'fecha_registro': Timestamp.now(),
      'perfil': {
        'categoria': request.profileCategory,
      },
    });

    return user;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) {
    return _authService.sendPasswordResetEmail(email);
  }

  @override
  Future<void> signOut() {
    return _authService.signOut();
  }
}
