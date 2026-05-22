import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tae_app/core/errors/app_exception.dart';
import 'package:tae_app/core/services/firestore_service.dart';
import 'package:tae_app/features/admin/domain/entities/branch.dart';
import 'package:tae_app/features/admin/domain/repositories/branch_repository.dart';

class FirebaseBranchRepository implements BranchRepository {
  FirebaseBranchRepository({FirestoreService? firestoreService})
    : _firestoreService = firestoreService ?? FirestoreService();

  final FirestoreService _firestoreService;

  FirebaseFirestore get _db => _firestoreService.instance;

  @override
  Stream<List<Branch>> watchBranchesByOwner(String ownerUserId) {
    return _firestoreService
        .branches()
        .where('id_usuario', isEqualTo: ownerUserId)
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => Branch(
                      id: doc.id,
                      name: doc.data()['name'] as String? ?? '',
                      ownerUserId: doc.data()['id_usuario'] as String? ?? '',
                      classesCount: (doc.data()['classes'] as num?)?.toInt() ?? 0,
                      participantsCount:
                          (doc.data()['participants'] as num?)?.toInt() ?? 0,
                      cardColorValue: (doc.data()['card_color'] as num?)?.toInt(),
                    ),
                  )
                  .toList(),
        );
  }

  @override
  Future<String> createBranch({
    required String ownerUserId,
    required String branchName,
  }) async {
    await _ensureBranchNameAvailable(branchName);

    final ref = await _db.collection('sucursales').add({
      'name': branchName,
      'fecha_creacion': FieldValue.serverTimestamp(),
      'id_usuario': ownerUserId,
      'classes': 0,
      'participants': 0,
    });

    return ref.id;
  }

  @override
  Future<void> renameBranch({
    required String branchId,
    required String oldName,
    required String newName,
  }) async {
    await _ensureBranchNameAvailable(newName, exceptBranchId: branchId);

    await _db.collection('sucursales').doc(branchId).update({'name': newName});

    final groupsSnapshot =
        await _db
            .collection('grupos')
            .where('id_sucursal', isEqualTo: branchId)
            .get();

    if (groupsSnapshot.docs.isNotEmpty) {
      final batch = _db.batch();
      for (final groupDoc in groupsSnapshot.docs) {
        batch.update(groupDoc.reference, {'nombre_sucursal': newName});
      }
      await batch.commit();
    }

    await _syncUsersAfterBranchRename(oldName: oldName, newName: newName);
  }

  @override
  Future<void> updateBranchColor({
    required String branchId,
    required int colorValue,
  }) async {
    await _db.collection('sucursales').doc(branchId).update({
      'card_color': colorValue,
    });

    final groupsSnapshot =
        await _db
            .collection('grupos')
            .where('id_sucursal', isEqualTo: branchId)
            .get();

    if (groupsSnapshot.docs.isNotEmpty) {
      final batch = _db.batch();
      for (final groupDoc in groupsSnapshot.docs) {
        batch.update(groupDoc.reference, {'color_sucursal': colorValue});
      }
      await batch.commit();
    }

    await _syncUsersAfterBranchColorUpdate(
      branchId: branchId,
      colorValue: colorValue,
    );
  }

  @override
  Future<void> deleteBranch({
    required String branchId,
    required String branchName,
  }) async {
    final groupsSnapshot =
        await _db
            .collection('grupos')
            .where('id_sucursal', isEqualTo: branchId)
            .get();

    final deletedGroupIds = <String>{};
    for (final groupDoc in groupsSnapshot.docs) {
      deletedGroupIds.add(groupDoc.id);
      await _deleteGroupDocument(groupDoc);
    }

    await _db.collection('sucursales').doc(branchId).delete();
    await _syncUsersAfterBranchDelete(
      branchName: branchName,
      deletedGroupIds: deletedGroupIds,
    );
  }

  Future<void> _ensureBranchNameAvailable(
    String branchName, {
    String? exceptBranchId,
  }) async {
    final existingBranches = await _db.collection('sucursales').get();
    final normalizedBranchName = branchName.trim().toLowerCase();
    final duplicateExists = existingBranches.docs.any((doc) {
      if (exceptBranchId != null && doc.id == exceptBranchId) {
        return false;
      }
      final savedName =
          (doc.data()['name'] as String?)?.trim().toLowerCase() ?? '';
      return savedName == normalizedBranchName;
    });

    if (duplicateExists) {
      throw const AppException('Ya existe una sucursal con ese nombre.');
    }
  }

  Future<void> _syncUsersAfterBranchRename({
    required String oldName,
    required String newName,
  }) async {
    final usersSnapshot = await _db.collection('usuarios').get();
    final batch = _db.batch();
    var hasWrites = false;

    for (final userDoc in usersSnapshot.docs) {
      final data = userDoc.data();
      final updates = <String, dynamic>{};

      final branchPermissions = data['sucursales'];
      if (branchPermissions is List) {
        final updatedPermissions =
            branchPermissions
                .map(
                  (value) =>
                      value.toString() == oldName ? newName : value.toString(),
                )
                .toList();

        if (!_listsAreEqual(branchPermissions, updatedPermissions)) {
          updates['sucursales'] = updatedPermissions;
        }
      }

      final savedGroups = data['grupos'];
      if (savedGroups is List) {
        var groupsChanged = false;
        final updatedGroups =
            savedGroups.map((group) {
              if (group is! Map) return group;
              final updatedGroup = Map<String, dynamic>.from(group);
              if (updatedGroup['branchName'] == oldName) {
                updatedGroup['branchName'] = newName;
                groupsChanged = true;
              }
              return updatedGroup;
            }).toList();

        if (groupsChanged) {
          updates['grupos'] = updatedGroups;
        }
      }

      if (data['grupo_sucursal'] == oldName) {
        updates['grupo_sucursal'] = newName;
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

  Future<void> _deleteGroupDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> groupDoc,
  ) async {
    await _deleteCollection(groupDoc.reference.collection('alumnos'));
    await _deleteCollection(groupDoc.reference.collection('actividades'));
    await _deleteCollection(groupDoc.reference.collection('secciones_cinta'));
    await groupDoc.reference.delete();
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

  Future<void> _syncUsersAfterBranchColorUpdate({
    required String branchId,
    required int colorValue,
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
              if (updatedGroup['branchId']?.toString() == branchId) {
                updatedGroup['branchColorValue'] = colorValue;
                groupsChanged = true;
              }
              return updatedGroup;
            }).toList();

        if (groupsChanged) {
          updates['grupos'] = updatedGroups;
        }

        final currentGroupId = data['grupo_id']?.toString();
        if (currentGroupId != null && currentGroupId.isNotEmpty) {
          Map<String, dynamic>? currentGroup;
          for (final group in updatedGroups) {
            if (group is! Map) continue;
            final groupMap = Map<String, dynamic>.from(group);
            if (groupMap['groupId']?.toString() == currentGroupId) {
              currentGroup = groupMap;
              break;
            }
          }
          if (currentGroup != null) {
            updates['grupo_color_sucursal'] =
                currentGroup['branchColorValue'] ?? colorValue;
          }
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

  Future<void> _syncUsersAfterBranchDelete({
    required String branchName,
    required Set<String> deletedGroupIds,
  }) async {
    final usersSnapshot = await _db.collection('usuarios').get();
    final batch = _db.batch();
    var hasWrites = false;

    for (final userDoc in usersSnapshot.docs) {
      final data = userDoc.data();
      final updates = <String, dynamic>{};

      final branchPermissions = data['sucursales'];
      if (branchPermissions is List) {
        final updatedPermissions =
            branchPermissions
                .where((value) => value.toString() != branchName)
                .map((value) => value.toString())
                .toList();

        if (!_listsAreEqual(branchPermissions, updatedPermissions)) {
          updates['sucursales'] = updatedPermissions;
        }
      }

      final savedGroups = data['grupos'];
      List<Map<String, dynamic>>? remainingGroups;
      if (savedGroups is List) {
        remainingGroups =
            savedGroups
                .whereType<Map>()
                .map((group) => Map<String, dynamic>.from(group))
                .where((group) {
                  final groupId = group['groupId']?.toString() ?? '';
                  final groupBranch = group['branchName']?.toString() ?? '';
                  return !deletedGroupIds.contains(groupId) &&
                      groupBranch != branchName;
                })
                .toList();

        if (remainingGroups.length != savedGroups.length) {
          updates['grupos'] =
              remainingGroups.isEmpty ? FieldValue.delete() : remainingGroups;
        }
      }

      final currentGroupId = data['grupo_id']?.toString() ?? '';
      final currentBranchName = data['grupo_sucursal']?.toString() ?? '';
      final shouldClearCurrentGroup =
          deletedGroupIds.contains(currentGroupId) ||
          currentBranchName == branchName;

      if (shouldClearCurrentGroup) {
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

  bool _listsAreEqual(List<dynamic> original, List<dynamic> updated) {
    if (original.length != updated.length) {
      return false;
    }

    for (var i = 0; i < original.length; i++) {
      if (original[i].toString() != updated[i].toString()) {
        return false;
      }
    }
    return true;
  }
}
