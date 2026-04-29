import 'package:tae_app/core/errors/app_exception.dart';
import 'package:tae_app/core/services/auth_service.dart';
import 'package:tae_app/core/services/firestore_service.dart';
import 'package:tae_app/features/admin/domain/entities/wallet_branch_option.dart';
import 'package:tae_app/features/admin/domain/repositories/wallet_repository.dart';

class FirebaseWalletRepository implements WalletRepository {
  FirebaseWalletRepository({
    AuthService? authService,
    FirestoreService? firestoreService,
  }) : _authService = authService ?? AuthService(),
       _firestoreService = firestoreService ?? FirestoreService();

  final AuthService _authService;
  final FirestoreService _firestoreService;

  @override
  String? get currentUserId => _authService.currentUser?.uid;

  @override
  Future<String> getCurrentAdminFirstName() async {
    final uid = currentUserId;
    if (uid == null) {
      throw const AppException('No hay sesion activa.');
    }

    final snapshot = await _firestoreService.users().doc(uid).get();
    final data = snapshot.data();
    if (data == null) {
      throw const AppException('No se encontro el perfil del administrador.');
    }

    return data['nombre'] as String? ?? 'Usuario';
  }

  @override
  Stream<List<WalletBranchOption>> watchBranchesByCurrentAdmin() {
    final uid = currentUserId;
    if (uid == null) {
      throw const AppException('No hay sesion activa.');
    }

    return _firestoreService
        .branches()
        .where('id_usuario', isEqualTo: uid)
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => WalletBranchOption(
                      id: doc.id,
                      name: doc.data()['name'] as String? ?? 'Sin nombre',
                    ),
                  )
                  .toList(),
        );
  }
}
