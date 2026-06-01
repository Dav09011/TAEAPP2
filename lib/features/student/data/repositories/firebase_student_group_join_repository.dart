import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tae_app/core/errors/app_exception.dart';
import 'package:tae_app/core/services/auth_service.dart';
import 'package:tae_app/core/services/firestore_service.dart';
import 'package:tae_app/features/student/domain/entities/student_group_join_result.dart';
import 'package:tae_app/features/student/domain/repositories/student_group_join_repository.dart';

class FirebaseStudentGroupJoinRepository implements StudentGroupJoinRepository {
  FirebaseStudentGroupJoinRepository({
    AuthService? authService,
    FirestoreService? firestoreService,
  }) : _authService = authService ?? AuthService(),
       _firestoreService = firestoreService ?? FirestoreService();

  final AuthService _authService;
  final FirestoreService _firestoreService;

  @override
  Future<StudentGroupJoinResult> joinByAccessCode(String accessCode) async {
    final studentQuery =
        await _groups()
            .where('codigo_alumno', isEqualTo: accessCode)
            .limit(1)
            .get();

    if (studentQuery.docs.isNotEmpty) {
      return _joinGroupFromSnapshot(
        studentQuery.docs.first,
        assignedRole: 'alumno',
      );
    }

    final privilegedQuery =
        await _groups()
            .where('codigo_privilegiado', isEqualTo: accessCode)
            .limit(1)
            .get();

    if (privilegedQuery.docs.isNotEmpty) {
      return _joinGroupFromSnapshot(
        privilegedQuery.docs.first,
        assignedRole: 'moderador',
      );
    }

    throw const AppException(
      'No encontramos un grupo con ese codigo o ya expiro.',
    );
  }

  @override
  Future<StudentGroupJoinResult> joinByGroupId({
    required String groupId,
    required String assignedRole,
    String? fallbackGroupName,
  }) async {
    final groupSnapshot = await _groups().doc(groupId).get();

    if (!groupSnapshot.exists) {
      throw const AppException(
        'El grupo ya no esta disponible. Pide un QR actualizado.',
      );
    }

    return _joinGroupFromSnapshot(
      groupSnapshot,
      fallbackGroupName: fallbackGroupName,
      assignedRole: assignedRole,
    );
  }

  Future<StudentGroupJoinResult> _joinGroupFromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> groupSnapshot, {
    String? fallbackGroupName,
    required String assignedRole,
  }) async {
    final user = _authService.currentUser;
    if (user == null) {
      throw const AppException('No hay sesion activa.');
    }

    final groupId = groupSnapshot.id;
    final groupData = groupSnapshot.data() ?? const <String, dynamic>{};
    final groupName = _resolveGroupName(
      groupId: groupId,
      groupData: groupData,
      fallbackGroupName: fallbackGroupName,
    );

    final enrolledStudent =
        await _groups()
            .doc(groupId)
            .collection('alumnos')
            .where('uid', isEqualTo: user.uid)
            .limit(1)
            .get();

    if (enrolledStudent.docs.isNotEmpty) {
      throw AppException('Ya estas inscrito en el grupo "$groupName".');
    }

    final userSnapshot = await _firestoreService.users().doc(user.uid).get();
    final userData = userSnapshot.data() ?? const <String, dynamic>{};
    final studentName =
        '${userData['nombre'] ?? ''} ${userData['ap'] ?? ''}'.trim();
    final beltType = groupData['tipo_cinta']?.toString() ?? '';
    final branchId = groupData['id_sucursal']?.toString() ?? '';
    final schedule = groupData['horario']?.toString() ?? '';
    final branchColorValue = (groupData['color_sucursal'] as num?)?.toInt();
    final groupColorValue = (groupData['group_card_color'] as num?)?.toInt();
    final branchName = await _resolveBranchName(
      groupId: groupId,
      groupData: groupData,
    );

    await _groups().doc(groupId).collection('alumnos').add({
      'uid': user.uid,
      'nombre': studentName,
      'cinta': beltType,
      'imagen': userData['imagen'] ?? '',
      'fecha_ingreso': FieldValue.serverTimestamp(),
    });

    await _groups().doc(groupId).update({
      'total_alumnos': FieldValue.increment(1),
    });

    if (branchId.isNotEmpty) {
      await _firestoreService.branches().doc(branchId).update({
        'participants': FieldValue.increment(1),
      });
    }

    await _firestoreService.users().doc(user.uid).set({
      'grupos': FieldValue.arrayUnion([
        {
          'groupId': groupId,
          'groupName': groupName,
          'branchName': branchName,
          'branchId': branchId,
          'beltType': beltType,
          'schedule': schedule,
          'branchColorValue': branchColorValue,
          'groupColorValue': groupColorValue,
          'rol_en_grupo': assignedRole,
        },
      ]),
      'grupo_id': groupId,
      'grupo_nombre': groupName,
      'grupo_sucursal': branchName,
      'grupo_cinta': beltType,
      'grupo_horario': schedule,
      'grupo_color_sucursal': branchColorValue,
      'grupo_color': groupColorValue,
    }, SetOptions(merge: true));

    return StudentGroupJoinResult(groupName: groupName);
  }

  String _resolveGroupName({
    required String groupId,
    required Map<String, dynamic> groupData,
    String? fallbackGroupName,
  }) {
    final savedGroupName = groupData['nombre_grupo']?.toString().trim() ?? '';
    if (savedGroupName.isNotEmpty) {
      return savedGroupName;
    }

    final fallback = fallbackGroupName?.trim() ?? '';
    return fallback.isNotEmpty ? fallback : groupId;
  }

  Future<String> _resolveBranchName({
    required String groupId,
    required Map<String, dynamic> groupData,
  }) async {
    final savedBranchName = groupData['nombre_sucursal']?.toString().trim();
    if (savedBranchName != null && savedBranchName.isNotEmpty) {
      return savedBranchName;
    }

    final branchId = groupData['id_sucursal']?.toString().trim() ?? '';
    if (branchId.isEmpty) {
      return 'Sucursal no disponible';
    }

    final branchSnapshot =
        await _firestoreService.branches().doc(branchId).get();
    final branchName = branchSnapshot.data()?['name']?.toString().trim() ?? '';

    if (branchName.isNotEmpty) {
      await _groups().doc(groupId).set({
        'nombre_sucursal': branchName,
      }, SetOptions(merge: true));
      return branchName;
    }

    return branchId;
  }

  CollectionReference<Map<String, dynamic>> _groups() {
    return _firestoreService.instance.collection('grupos');
  }
}
