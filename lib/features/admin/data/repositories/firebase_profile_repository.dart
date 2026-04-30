import 'package:tae_app/core/errors/app_exception.dart';
import 'package:tae_app/core/services/auth_service.dart';
import 'package:tae_app/core/services/firestore_service.dart';
import 'package:tae_app/features/admin/domain/entities/admin_profile.dart';
import 'package:tae_app/features/admin/domain/entities/update_admin_profile_request.dart';
import 'package:tae_app/features/admin/domain/repositories/profile_repository.dart';

class FirebaseProfileRepository implements ProfileRepository {
  FirebaseProfileRepository({
    AuthService? authService,
    FirestoreService? firestoreService,
  }) : _authService = authService ?? AuthService(),
       _firestoreService = firestoreService ?? FirestoreService();

  final AuthService _authService;
  final FirestoreService _firestoreService;

  @override
  String? get currentUserId => _authService.currentUser?.uid;

  @override
  Stream<AdminProfile> watchCurrentProfile() {
    final uid = currentUserId;
    if (uid == null) {
      throw const AppException('No hay sesion activa.');
    }

    return _firestoreService
        .users()
        .doc(uid)
        .snapshots()
        .map((snapshot) {
          final data = snapshot.data();
          if (data == null) {
            throw const AppException('No se encontro el perfil.');
          }
          return _mapProfile(uid, data);
        });
  }

  @override
  Future<AdminProfile> getCurrentProfile() async {
    final uid = currentUserId;
    if (uid == null) {
      throw const AppException('No hay sesion activa.');
    }

    final snapshot = await _firestoreService.users().doc(uid).get();
    final data = snapshot.data();
    if (data == null) {
      throw const AppException('No se encontro el perfil.');
    }

    return _mapProfile(uid, data);
  }

  @override
  Future<void> updateProfile(UpdateAdminProfileRequest request) {
    return _firestoreService.users().doc(request.userId).update({
      'nombre': request.firstName.trim(),
      'ap': request.lastName.trim(),
      'am': request.middleName.trim(),
      'telefono': request.phone.trim(),
    });
  }

  @override
  Future<void> requestEmailChange({
    required String userId,
    required String newEmail,
  }) async {
    final user = _authService.currentUser;
    if (user == null) {
      throw const AppException('No hay sesion activa.');
    }

    await user.verifyBeforeUpdateEmail(newEmail);
    await _firestoreService.users().doc(userId).update({
      'correo': newEmail,
    });
  }

  @override
  Future<void> signOut() {
    return _authService.signOut();
  }

  AdminProfile _mapProfile(String uid, Map<String, dynamic> data) {
    return AdminProfile(
      userId: uid,
      firstName: data['nombre'] as String? ?? '',
      lastName: data['ap'] as String? ?? '',
      middleName: data['am'] as String? ?? '',
      email: data['correo'] as String? ?? 'Sin correo',
      phone: data['telefono'] as String? ?? 'Sin telefono',
      role: data['tipo'] as String? ?? 'Sin rol',
      imageUrl: data['imagen'] as String? ?? '',
    );
  }
}
