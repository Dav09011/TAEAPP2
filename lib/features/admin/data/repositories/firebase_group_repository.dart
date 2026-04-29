import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tae_app/core/errors/app_exception.dart';
import 'package:tae_app/core/services/firestore_service.dart';
import 'package:tae_app/features/admin/domain/entities/branch_group.dart';
import 'package:tae_app/features/admin/domain/entities/create_group_request.dart';
import 'package:tae_app/features/admin/domain/repositories/group_repository.dart';

class FirebaseGroupRepository implements GroupRepository {
  FirebaseGroupRepository({FirestoreService? firestoreService})
    : _firestoreService = firestoreService ?? FirestoreService();

  final FirestoreService _firestoreService;

  FirebaseFirestore get _db => _firestoreService.instance;

  @override
  Stream<List<BranchGroup>> watchGroupsByBranch(String branchId) {
    return _db
        .collection('grupos')
        .where('id_sucursal', isEqualTo: branchId)
        .orderBy('nombre_grupo')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => BranchGroup(
                      id: doc.id,
                      branchId: doc.data()['id_sucursal'] as String? ?? '',
                      name: doc.data()['nombre_grupo'] as String? ?? 'Sin Nombre',
                      beltType: doc.data()['tipo_cinta'] as String? ?? 'N/A',
                      schedule: doc.data()['horario'] as String? ?? 'Sin horario',
                      totalStudents:
                          (doc.data()['total_alumnos'] as num?)?.toInt() ?? 0,
                    ),
                  )
                  .toList(),
        );
  }

  @override
  Future<void> createGroup(CreateGroupRequest request) async {
    await _ensureGroupNameAvailable(
      branchId: request.branchId,
      groupName: request.name,
    );

    await _db.collection('grupos').add({
      'nombre_grupo': request.name,
      'tipo_cinta': request.beltType,
      'horario': request.schedule,
      'id_sucursal': request.branchId,
      'total_alumnos': 0,
      'fecha_creacion': FieldValue.serverTimestamp(),
    });

    await _db.collection('sucursales').doc(request.branchId).update({
      'classes': FieldValue.increment(1),
    });
  }

  @override
  Future<void> renameGroup({
    required String branchId,
    required String groupId,
    required String oldName,
    required String newName,
  }) async {
    await _ensureGroupNameAvailable(
      branchId: branchId,
      groupName: newName,
      exceptGroupId: groupId,
    );

    await _db.collection('grupos').doc(groupId).update({
      'nombre_grupo': newName,
    });

    await _syncUsersAfterGroupRename(groupId: groupId, newName: newName);
  }

  @override
  Future<void> deleteGroup({
    required String branchId,
    required String groupId,
  }) async {
    final groupRef = _db.collection('grupos').doc(groupId);
    final groupSnapshot = await groupRef.get();
    final totalStudents =
        (groupSnapshot.data()?['total_alumnos'] as num?)?.toInt() ?? 0;

    await _deleteCollection(groupRef.collection('alumnos'));
    await _deleteCollection(groupRef.collection('actividades'));
    await _deleteCollection(groupRef.collection('secciones_cinta'));
    await groupRef.delete();

    await _syncUsersAfterGroupDelete(groupId: groupId);

    await _db.collection('sucursales').doc(branchId).update({
      'classes': FieldValue.increment(-1),
      'participants': FieldValue.increment(-totalStudents),
    });
  }

  Future<void> _ensureGroupNameAvailable({
    required String branchId,
    required String groupName,
    String? exceptGroupId,
  }) async {
    final existingGroups =
        await _db
            .collection('grupos')
            .where('id_sucursal', isEqualTo: branchId)
            .get();

    final normalizedName = groupName.trim().toLowerCase();
    final duplicateExists = existingGroups.docs.any((doc) {
      if (exceptGroupId != null && doc.id == exceptGroupId) {
        return false;
      }
      final savedName =
          (doc.data()['nombre_grupo'] as String?)?.trim().toLowerCase() ?? '';
      return savedName == normalizedName;
    });

    if (duplicateExists) {
      throw const AppException(
        'Ya existe un grupo con ese nombre en esta sucursal.',
      );
    }
  }

  Future<void> _syncUsersAfterGroupRename({
    required String groupId,
    required String newName,
  }) async {
    final usersSnapshot = await _db.collection('usuarios').get();
    final batch = _db.batch();
    var hasWrites = false;

    for (final userDoc in usersSnapshot.docs) {
      final data = userDoc.data();
      final updates = <String, dynamic>{};

      final savedGroups = data['grupos'];
      if (savedGroups is List) {
        var groupsChanged = false;
        final updatedGroups =
            savedGroups.map((group) {
              if (group is! Map) return group;
              final updatedGroup = Map<String, dynamic>.from(group);
              if (updatedGroup['groupId'] == groupId) {
                updatedGroup['groupName'] = newName;
                groupsChanged = true;
              }
              return updatedGroup;
            }).toList();

        if (groupsChanged) {
          updates['grupos'] = updatedGroups;
        }
      }

      if (data['grupo_id'] == groupId) {
        updates['grupo_nombre'] = newName;
      }

      if (updates.isNotEmpty) {
        hasWrites = true;
        batch.update(userDoc.reference, updates);
      }
    }

    if (hasWrites) {
      await batch.commit();
    }
  }

  Future<void> _syncUsersAfterGroupDelete({required String groupId}) async {
    final usersSnapshot = await _db.collection('usuarios').get();
    final batch = _db.batch();
    var hasWrites = false;

    for (final userDoc in usersSnapshot.docs) {
      final data = userDoc.data();
      final updates = <String, dynamic>{};

      final savedGroups = data['grupos'];
      List<Map<String, dynamic>>? remainingGroups;
      if (savedGroups is List) {
        remainingGroups =
            savedGroups
                .whereType<Map>()
                .map((group) => Map<String, dynamic>.from(group))
                .where((group) => group['groupId']?.toString() != groupId)
                .toList();

        if (remainingGroups.length != savedGroups.length) {
          updates['grupos'] =
              remainingGroups.isEmpty ? FieldValue.delete() : remainingGroups;
        }
      }

      if (data['grupo_id'] == groupId) {
        if (remainingGroups != null && remainingGroups.isNotEmpty) {
          final firstGroup = remainingGroups.first;
          updates['grupo_id'] = firstGroup['groupId'] ?? '';
          updates['grupo_nombre'] = firstGroup['groupName'] ?? '';
          updates['grupo_sucursal'] = firstGroup['branchName'] ?? '';
          updates['grupo_cinta'] = firstGroup['beltType'] ?? '';
          updates['grupo_horario'] = firstGroup['schedule'] ?? '';
        } else {
          updates['grupo_id'] = FieldValue.delete();
          updates['grupo_nombre'] = FieldValue.delete();
          updates['grupo_sucursal'] = FieldValue.delete();
          updates['grupo_cinta'] = FieldValue.delete();
          updates['grupo_horario'] = FieldValue.delete();
        }
      }

      if (updates.isNotEmpty) {
        hasWrites = true;
        batch.update(userDoc.reference, updates);
      }
    }

    if (hasWrites) {
      await batch.commit();
    }
  }

  Future<void> _deleteCollection(
    CollectionReference<Map<String, dynamic>> collection,
  ) async {
    while (true) {
      final snapshot = await collection.limit(100).get();
      if (snapshot.docs.isEmpty) break;

      final batch = _db.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (snapshot.docs.length < 100) {
        break;
      }
    }
  }
}
