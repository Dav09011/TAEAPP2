import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tae_app/core/errors/app_exception.dart';
import 'package:tae_app/core/services/auth_service.dart';
import 'package:tae_app/core/services/firestore_service.dart';
import 'package:tae_app/features/student/domain/entities/student_group_data.dart';
import 'package:tae_app/features/student/domain/repositories/student_home_repository.dart';

class FirebaseStudentHomeRepository implements StudentHomeRepository {
  FirebaseStudentHomeRepository({
    AuthService? authService,
    FirestoreService? firestoreService,
  }) : _authService = authService ?? AuthService(),
       _firestoreService = firestoreService ?? FirestoreService();

  final AuthService _authService;
  final FirestoreService _firestoreService;

  @override
  Stream<List<StudentGroupData>> watchCurrentStudentGroups() {
    final user = _authService.currentUser;
    if (user == null) {
      return Stream<List<StudentGroupData>>.error(
        const AppException('No hay una sesion activa.'),
      );
    }

    return _firestoreService.users().doc(user.uid).snapshots().asyncMap((
      snapshot,
    ) {
      return _loadStudentGroups(user.uid, snapshot.data());
    });
  }

  @override
  Stream<StudentGroupDetails> watchGroupDetails(StudentGroupData group) {
    return _groups().doc(group.groupId).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return StudentGroupDetails.missing(group);
      }

      return StudentGroupDetails.fromData(
        fallback: group,
        data: snapshot.data() ?? group.cachedData,
      );
    });
  }

  @override
  Future<void> removeGroupFromCurrentStudentProfile(String groupId) {
    final user = _requireCurrentUser();
    return _removeGroupFromProfile(user.uid, groupId);
  }

  @override
  Future<bool> leaveGroup(String groupId) async {
    final user = _requireCurrentUser();

    try {
      final studentDocs =
          await _groups()
              .doc(groupId)
              .collection('alumnos')
              .where('uid', isEqualTo: user.uid)
              .get();

      for (final doc in studentDocs.docs) {
        await doc.reference.delete();
      }

      if (studentDocs.docs.isNotEmpty) {
        final groupSnapshot = await _groups().doc(groupId).get();
        final branchId = groupSnapshot.data()?['id_sucursal'] as String?;
        final deletedStudents = studentDocs.docs.length;

        await _groups().doc(groupId).update({
          'total_alumnos': FieldValue.increment(-deletedStudents),
        });

        if (branchId != null && branchId.isNotEmpty) {
          await _firestoreService.branches().doc(branchId).update({
            'participants': FieldValue.increment(-deletedStudents),
          });
        }
      }

      await _removeGroupFromProfile(user.uid, groupId);
      return studentDocs.docs.isNotEmpty;
    } catch (_) {
      await _removeGroupFromProfile(user.uid, groupId);
      return false;
    }
  }

  Future<List<StudentGroupData>> _loadStudentGroups(
    String uid,
    Map<String, dynamic>? userData,
  ) async {
    final safeUserData = userData ?? {};
    final savedGroups = _parseGroupsFromUserData(safeUserData);

    if (savedGroups.isNotEmpty) {
      return savedGroups;
    }

    final savedGroupId = safeUserData['grupo_id']?.toString().trim() ?? '';
    if (savedGroupId.isNotEmpty) {
      return [
        StudentGroupData(
          groupId: savedGroupId,
          groupName: _stringValue(
            safeUserData['grupo_nombre'],
            fallback: savedGroupId,
          ),
          cachedData: {
            'nombre_grupo': safeUserData['grupo_nombre'],
            'nombre_sucursal': safeUserData['grupo_sucursal'],
            'id_sucursal': safeUserData['grupo_sucursal'],
            'tipo_cinta': safeUserData['grupo_cinta'],
            'horario': safeUserData['grupo_horario'],
            'color_sucursal': safeUserData['grupo_color_sucursal'],
            'group_card_color': safeUserData['grupo_color'],
          },
        ),
      ];
    }

    try {
      final studentQuery =
          await _firestoreService.instance
              .collectionGroup('alumnos')
              .where('uid', isEqualTo: uid)
              .get();

      if (studentQuery.docs.isEmpty) {
        return const [];
      }

      final resolvedGroups = <StudentGroupData>[];
      for (final studentDoc in studentQuery.docs) {
        final groupRef = studentDoc.reference.parent.parent;
        if (groupRef == null) {
          continue;
        }

        final groupDoc = await groupRef.get();
        final groupData = groupDoc.data() ?? {};
        final groupName = _stringValue(
          groupData['nombre_grupo'],
          fallback: groupRef.id,
        );

        resolvedGroups.add(
          StudentGroupData(
            groupId: groupRef.id,
            groupName: groupName,
            cachedData: groupData,
          ),
        );
      }

      if (resolvedGroups.isEmpty) {
        return const [];
      }

      await _saveGroupsToProfile(uid, resolvedGroups);
      return resolvedGroups;
    } catch (_) {
      return const [];
    }
  }

  List<StudentGroupData> _parseGroupsFromUserData(
    Map<String, dynamic> userData,
  ) {
    final rawGroups = userData['grupos'];
    if (rawGroups is! List) {
      return const [];
    }

    return rawGroups
        .whereType<Map>()
        .map((rawGroup) {
          final groupMap = Map<String, dynamic>.from(rawGroup);
          final groupId = groupMap['groupId']?.toString().trim() ?? '';
          if (groupId.isEmpty) {
            return null;
          }

          return StudentGroupData(
            groupId: groupId,
            groupName: _stringValue(groupMap['groupName'], fallback: groupId),
            cachedData: {
              'nombre_grupo': groupMap['groupName'],
              'nombre_sucursal': groupMap['branchName'],
              'id_sucursal': groupMap['branchId'] ?? groupMap['branchName'],
              'tipo_cinta': groupMap['beltType'],
              'horario': groupMap['schedule'],
              'color_sucursal': groupMap['branchColorValue'],
              'group_card_color': groupMap['groupColorValue'],
              'rol_en_grupo': groupMap['rol_en_grupo'],
            },
          );
        })
        .whereType<StudentGroupData>()
        .toList();
  }

  Future<void> _saveGroupsToProfile(String uid, List<StudentGroupData> groups) {
    final payload =
        groups
            .map(
              (group) => {
                'groupId': group.groupId,
                'groupName': group.groupName,
                'branchName':
                    group.cachedData['nombre_sucursal'] ??
                    group.cachedData['id_sucursal'] ??
                    '',
                'branchId': group.cachedData['id_sucursal'] ?? '',
                'beltType': group.cachedData['tipo_cinta'] ?? '',
                'schedule': group.cachedData['horario'] ?? '',
                'branchColorValue': group.cachedData['color_sucursal'],
                'groupColorValue': group.cachedData['group_card_color'],
                'rol_en_grupo': group.cachedData['rol_en_grupo'] ?? 'alumno',
              },
            )
            .toList();

    return _firestoreService.users().doc(uid).set({
      'grupos': payload,
      if (groups.isNotEmpty) ...{
        'grupo_id': groups.first.groupId,
        'grupo_nombre': groups.first.groupName,
        'grupo_sucursal':
            groups.first.cachedData['nombre_sucursal'] ??
            groups.first.cachedData['id_sucursal'] ??
            '',
        'grupo_cinta': groups.first.cachedData['tipo_cinta'] ?? '',
        'grupo_horario': groups.first.cachedData['horario'] ?? '',
        'grupo_color_sucursal': groups.first.cachedData['color_sucursal'],
        'grupo_color': groups.first.cachedData['group_card_color'],
      },
    }, SetOptions(merge: true));
  }

  Future<void> _removeGroupFromProfile(String uid, String groupId) async {
    final userDoc = await _firestoreService.users().doc(uid).get();
    final currentGroups = _parseGroupsFromUserData(userDoc.data() ?? {});
    final remainingGroups =
        currentGroups.where((group) => group.groupId != groupId).toList();

    if (remainingGroups.isEmpty) {
      await _clearSavedGroups(uid);
      return;
    }

    await _saveGroupsToProfile(uid, remainingGroups);
  }

  Future<void> _clearSavedGroups(String uid) {
    return _firestoreService.users().doc(uid).set({
      'grupos': FieldValue.delete(),
      'grupo_id': FieldValue.delete(),
      'grupo_nombre': FieldValue.delete(),
      'grupo_sucursal': FieldValue.delete(),
      'grupo_cinta': FieldValue.delete(),
      'grupo_horario': FieldValue.delete(),
      'grupo_color_sucursal': FieldValue.delete(),
      'grupo_color': FieldValue.delete(),
    }, SetOptions(merge: true));
  }

  User _requireCurrentUser() {
    final user = _authService.currentUser;
    if (user == null) {
      throw const AppException('No hay una sesion activa.');
    }
    return user;
  }

  CollectionReference<Map<String, dynamic>> _groups() {
    return _firestoreService.instance.collection('grupos');
  }

  String _stringValue(Object? value, {required String fallback}) {
    final text = value?.toString().trim() ?? '';
    return text.isNotEmpty ? text : fallback;
  }
}
