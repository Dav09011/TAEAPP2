import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tae_app/core/errors/app_exception.dart';
import 'package:tae_app/core/services/auth_service.dart';
import 'package:tae_app/core/services/firestore_service.dart';
import 'package:tae_app/features/student/domain/entities/student_belt_option.dart';
import 'package:tae_app/features/student/domain/entities/student_profile.dart';
import 'package:tae_app/features/student/domain/entities/update_student_profile_request.dart';
import 'package:tae_app/features/student/domain/repositories/student_profile_repository.dart';

class FirebaseStudentProfileRepository implements StudentProfileRepository {
  FirebaseStudentProfileRepository({
    AuthService? authService,
    FirestoreService? firestoreService,
  }) : _authService = authService ?? AuthService(),
       _firestoreService = firestoreService ?? FirestoreService();

  final AuthService _authService;
  final FirestoreService _firestoreService;

  @override
  String? get currentUserId => _authService.currentUser?.uid;

  @override
  Stream<StudentProfile> watchCurrentProfile() {
    final user = _authService.currentUser;
    if (user == null) {
      return Stream<StudentProfile>.error(
        const AppException('No hay sesion activa.'),
      );
    }

    return _firestoreService.users().doc(user.uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) {
        throw const AppException('No se encontro el perfil.');
      }

      return StudentProfile(
        userId: user.uid,
        authEmail: user.email,
        data: data,
      );
    });
  }

  @override
  Future<List<StudentBeltOption>> loadAvailableBelts(
    StudentProfile profile,
  ) async {
    final branchIds = await _resolveStudentBranchIds(profile.data);
    if (branchIds.isEmpty) {
      return const <StudentBeltOption>[];
    }

    final beltsByName = <String, StudentBeltOption>{};
    for (final branchId in branchIds) {
      final branchSnapshot =
          await _firestoreService.branches().doc(branchId).get();
      final savedBelts = branchSnapshot.data()?['available_belts'];

      for (final belt in _parseStudentBeltOptions(savedBelts)) {
        final key = belt.label.trim().toLowerCase();
        final existing = beltsByName[key];
        if (existing == null ||
            (existing.colorValue == null && belt.colorValue != null)) {
          beltsByName[key] = belt;
        }
      }
    }

    return beltsByName.values.toList();
  }

  @override
  Future<StudentProfileUpdateResult> updateProfile(
    UpdateStudentProfileRequest request,
  ) async {
    final user = _authService.currentUser;
    if (user == null) {
      throw const AppException('No hay sesion activa.');
    }

    final trimmedEmail = request.email.trim();
    await _firestoreService.users().doc(user.uid).set({
      'nombre': request.firstName.trim(),
      'ap': request.lastName.trim(),
      'am': request.middleName.trim(),
      'telefono': request.phone.trim(),
      'cinta_personal': request.personalBelt,
      'cinta_personal_color': request.personalBeltColorValue,
      'correo': trimmedEmail,
    }, SetOptions(merge: true));

    final shouldRequestEmailChange =
        trimmedEmail.isNotEmpty && trimmedEmail != user.email;
    if (!shouldRequestEmailChange) {
      return const StudentProfileUpdateResult(emailVerificationSent: false);
    }

    try {
      await user.verifyBeforeUpdateEmail(trimmedEmail);
    } on FirebaseAuthException catch (error) {
      throw AppException(
        'Se guardaron tus datos, pero no se pudo actualizar el correo: '
        '${error.message ?? _mapEmailChangeError(error)}',
      );
    }

    return const StudentProfileUpdateResult(emailVerificationSent: true);
  }

  @override
  Future<void> signOut() {
    return _authService.signOut();
  }

  List<StudentBeltOption> _parseStudentBeltOptions(Object? savedBelts) {
    if (savedBelts is! List) {
      return const <StudentBeltOption>[];
    }

    final belts = <StudentBeltOption>[];
    for (final value in savedBelts) {
      if (value is Map) {
        final label = _normalizeBeltName(value['label']);
        if (label.isEmpty) continue;
        belts.add(
          StudentBeltOption(
            label: label,
            colorValue: (value['color_value'] as num?)?.toInt(),
          ),
        );
      } else {
        final label = _normalizeBeltName(value);
        if (label.isEmpty) continue;
        belts.add(StudentBeltOption(label: label));
      }
    }
    return belts;
  }

  Future<List<String>> _resolveStudentBranchIds(
    Map<String, dynamic> userData,
  ) async {
    final branchIds = <String>[];
    final seenBranchIds = <String>{};

    Future<void> addBranchId(String branchId) async {
      final resolvedBranchId = await _resolveBranchIdFromPossibleIdOrName(
        branchId,
      );
      if (resolvedBranchId.isEmpty) return;
      final key = resolvedBranchId.toLowerCase();
      if (seenBranchIds.add(key)) {
        branchIds.add(resolvedBranchId);
      }
    }

    Future<bool> addBranchFromGroupId(String groupId) async {
      if (groupId.isEmpty) return false;
      final groupSnapshot = await _groups().doc(groupId).get();
      final branchId =
          groupSnapshot.data()?['id_sucursal']?.toString().trim() ?? '';
      if (branchId.isNotEmpty) {
        await addBranchId(branchId);
        return true;
      }
      return false;
    }

    final currentGroupId = userData['grupo_id']?.toString().trim() ?? '';
    if (currentGroupId.isNotEmpty) {
      await addBranchFromGroupId(currentGroupId);
    }

    final savedGroups = userData['grupos'];
    if (savedGroups is List) {
      for (final group in savedGroups) {
        if (group is! Map) continue;
        final groupMap = Map<String, dynamic>.from(group);
        final groupId = groupMap['groupId']?.toString().trim() ?? '';
        if (groupId.isNotEmpty) {
          final resolvedFromGroup = await addBranchFromGroupId(groupId);
          if (resolvedFromGroup) {
            continue;
          }
        }

        final branchId = groupMap['branchId']?.toString().trim() ?? '';
        if (branchId.isNotEmpty) {
          await addBranchId(branchId);
          continue;
        }

        final branchName = groupMap['branchName']?.toString().trim() ?? '';
        if (branchName.isNotEmpty) {
          await addBranchId(branchName);
        }
      }
    }

    final branchName = userData['grupo_sucursal']?.toString().trim() ?? '';
    if (branchName.isNotEmpty) {
      final branchQuery =
          await _firestoreService
              .branches()
              .where('name', isEqualTo: branchName)
              .limit(1)
              .get();
      if (branchQuery.docs.isNotEmpty) {
        await addBranchId(branchQuery.docs.first.id);
      }
    }

    return branchIds;
  }

  Future<String> _resolveBranchIdFromPossibleIdOrName(String value) async {
    final trimmedValue = value.trim();
    if (trimmedValue.isEmpty) {
      return '';
    }

    final branchSnapshot =
        await _firestoreService.branches().doc(trimmedValue).get();
    if (branchSnapshot.exists) {
      return trimmedValue;
    }

    final branchQuery =
        await _firestoreService
            .branches()
            .where('name', isEqualTo: trimmedValue)
            .limit(1)
            .get();
    if (branchQuery.docs.isNotEmpty) {
      return branchQuery.docs.first.id;
    }

    return '';
  }

  CollectionReference<Map<String, dynamic>> _groups() {
    return _firestoreService.instance.collection('grupos');
  }

  String _normalizeBeltName(Object? beltValue) {
    final belt = beltValue?.toString().trim() ?? '';
    if (belt.isEmpty) {
      return '';
    }

    final lower = belt.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    switch (lower) {
      case 'blanca':
      case 'white':
        return 'Blanca';
      case 'amarilla':
      case 'yellow':
        return 'Amarilla';
      case 'naranja':
      case 'orange':
        return 'Naranja';
      case 'verde':
      case 'green':
        return 'Verde';
      case 'azul':
      case 'blue':
        return 'Azul';
      case 'morada':
      case 'purple':
        return 'Morada';
      case 'roja':
      case 'red':
        return 'Roja';
      case 'roja/negra':
      case 'roja negra':
      case 'red/black':
      case 'red black':
        return 'Roja/Negra';
      case 'negra':
      case 'black':
        return 'Negra';
    }
    return belt;
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
