import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tae_app/core/errors/app_exception.dart';
import 'package:tae_app/core/services/auth_service.dart';
import 'package:tae_app/core/services/firestore_service.dart';
import 'package:tae_app/features/admin/domain/entities/branch_category_option.dart';
import 'package:tae_app/features/admin/domain/entities/branch_group.dart';
import 'package:tae_app/features/admin/domain/entities/create_group_request.dart';
import 'package:tae_app/features/admin/domain/repositories/group_repository.dart';

class FirebaseGroupRepository implements GroupRepository {
  FirebaseGroupRepository({
    AuthService? authService,
    FirestoreService? firestoreService,
  }) : _authService = authService ?? AuthService(),
       _firestoreService = firestoreService ?? FirestoreService();

  static final Random _random = Random.secure();
  final AuthService _authService;
  final FirestoreService _firestoreService;

  FirebaseFirestore get _db => _firestoreService.instance;

  @override
  Future<String?> getCurrentUserRole() async {
    final user = _authService.currentUser;
    if (user == null) {
      return null;
    }

    final userSnapshot = await _firestoreService.users().doc(user.uid).get();
    final data = userSnapshot.data() ?? const <String, dynamic>{};
    return data['role']?.toString() ?? data['tipo']?.toString();
  }

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
                      name:
                          doc.data()['nombre_grupo'] as String? ?? 'Sin Nombre',
                      beltType: doc.data()['tipo_cinta'] as String? ?? 'N/A',
                      schedule:
                          doc.data()['horario'] as String? ?? 'Sin horario',
                      totalStudents:
                          (doc.data()['total_alumnos'] as num?)?.toInt() ?? 0,
                      cardColorValue:
                          (doc.data()['group_card_color'] as num?)?.toInt(),
                    ),
                  )
                  .toList(),
        );
  }

  @override
  Stream<List<BranchCategoryOption>> watchBranchCategories(String branchId) {
    return _firestoreService.branches().doc(branchId).snapshots().map((
      snapshot,
    ) {
      return _parseBranchCategories(snapshot.data()?['available_belts']);
    });
  }

  @override
  Future<void> createGroup(CreateGroupRequest request) async {
    await _ensureGroupNameAvailable(
      branchId: request.branchId,
      groupName: request.name,
    );

    final groupId = _buildGroupDocumentId(
      branchName: request.branchName,
      groupName: request.name,
    );
    final branchColorValue = await _resolveBranchColorValue(request.branchId);
    final studentCode = await _generateUniqueAccessCode('codigo_alumno');
    final privilegedCode = await _generateUniqueAccessCode(
      'codigo_privilegiado',
    );

    await _db.collection('grupos').doc(groupId).set({
      'nombre_grupo': request.name.trim(),
      'tipo_cinta': request.beltType.trim(),
      'horario': request.schedule.trim(),
      'id_sucursal': request.branchId,
      'nombre_sucursal': request.branchName.trim(),
      'color_sucursal': branchColorValue,
      'group_card_color': null,
      'codigo_alumno': studentCode,
      'codigo_privilegiado': privilegedCode,
      'total_alumnos': 0,
      'fecha_creacion': FieldValue.serverTimestamp(),
    });

    await _db.collection('sucursales').doc(request.branchId).update({
      'classes': FieldValue.increment(1),
    });
  }

  @override
  Future<void> saveBranchCategories({
    required String branchId,
    required List<BranchCategoryOption> categories,
  }) {
    return _firestoreService.branches().doc(branchId).set({
      'available_belts':
          categories
              .map(
                (category) => {
                  'label': category.label,
                  'color_value': category.colorValue,
                },
              )
              .toList(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> updateGroupColor({
    required String groupId,
    required int colorValue,
  }) async {
    await _db.collection('grupos').doc(groupId).update({
      'group_card_color': colorValue,
    });

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
              if (updatedGroup['groupId']?.toString() == groupId) {
                updatedGroup['groupColorValue'] = colorValue;
                groupsChanged = true;
              }
              return updatedGroup;
            }).toList();

        if (groupsChanged) {
          updates['grupos'] = updatedGroups;
        }
      }

      if (data['grupo_id']?.toString() == groupId) {
        updates['grupo_color'] = colorValue;
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

  @override
  Future<String> generateGroupAccessCode({
    required String groupId,
    required bool privileged,
  }) async {
    final fieldName = privileged ? 'codigo_privilegiado' : 'codigo_alumno';
    final code = await _generateUniqueAccessCode(fieldName);

    await _db.collection('grupos').doc(groupId).set({
      fieldName: code,
    }, SetOptions(merge: true));

    return code;
  }

  Future<int?> _resolveBranchColorValue(String branchId) async {
    final branchSnapshot =
        await _db.collection('sucursales').doc(branchId).get();
    return (branchSnapshot.data()?['card_color'] as num?)?.toInt();
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

    final currentGroupRef = _db.collection('grupos').doc(groupId);
    final currentGroupSnapshot = await currentGroupRef.get();
    final currentGroupData = currentGroupSnapshot.data();

    if (!currentGroupSnapshot.exists || currentGroupData == null) {
      throw const AppException('El grupo ya no existe.');
    }

    final branchName = await _resolveBranchName(
      branchId: branchId,
      groupData: currentGroupData,
    );
    final newGroupId = _buildGroupDocumentId(
      branchName: branchName,
      groupName: newName,
    );

    if (newGroupId == groupId) {
      await currentGroupRef.update({'nombre_grupo': newName.trim()});
    } else {
      final newGroupRef = _db.collection('grupos').doc(newGroupId);
      await newGroupRef.set({
        ...currentGroupData,
        'nombre_grupo': newName.trim(),
      });

      await _copyCollection(
        from: currentGroupRef.collection('alumnos'),
        to: newGroupRef.collection('alumnos'),
      );
      await _copyCollection(
        from: currentGroupRef.collection('actividades'),
        to: newGroupRef.collection('actividades'),
      );
      await _copyCollection(
        from: currentGroupRef.collection('secciones_cinta'),
        to: newGroupRef.collection('secciones_cinta'),
      );

      await _deleteCollection(currentGroupRef.collection('alumnos'));
      await _deleteCollection(currentGroupRef.collection('actividades'));
      await _deleteCollection(currentGroupRef.collection('secciones_cinta'));
      await currentGroupRef.delete();
    }

    await _syncUsersAfterGroupRename(
      oldGroupId: groupId,
      newGroupId: newGroupId,
      newName: newName.trim(),
    );
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
    required String oldGroupId,
    required String newGroupId,
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
              if (updatedGroup['groupId'] == oldGroupId) {
                updatedGroup['groupId'] = newGroupId;
                updatedGroup['groupName'] = newName;
                groupsChanged = true;
              }
              return updatedGroup;
            }).toList();

        if (groupsChanged) {
          updates['grupos'] = updatedGroups;
        }
      }

      if (data['grupo_id'] == oldGroupId) {
        updates['grupo_id'] = newGroupId;
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

  Future<void> _copyCollection({
    required CollectionReference<Map<String, dynamic>> from,
    required CollectionReference<Map<String, dynamic>> to,
  }) async {
    final snapshot = await from.get();
    if (snapshot.docs.isEmpty) {
      return;
    }

    for (var i = 0; i < snapshot.docs.length; i += 400) {
      final batch = _db.batch();
      final chunk = snapshot.docs.skip(i).take(400);
      for (final doc in chunk) {
        batch.set(to.doc(doc.id), doc.data());
      }
      await batch.commit();
    }
  }

  Future<String> _generateUniqueAccessCode(String fieldName) async {
    while (true) {
      final code = (100000 + _random.nextInt(900000)).toString();
      final existing =
          await _db
              .collection('grupos')
              .where(fieldName, isEqualTo: code)
              .limit(1)
              .get();

      if (existing.docs.isEmpty) {
        return code;
      }
    }
  }

  List<BranchCategoryOption> _parseBranchCategories(Object? saved) {
    if (saved is! List || saved.isEmpty) {
      return const <BranchCategoryOption>[];
    }

    final categories = <BranchCategoryOption>[];
    for (final item in saved) {
      if (item is Map) {
        final label = item['label']?.toString().trim() ?? '';
        if (label.isEmpty) continue;
        categories.add(
          BranchCategoryOption(
            label: label,
            colorValue: (item['color_value'] as num?)?.toInt() ?? 0xFFD9D0C3,
          ),
        );
        continue;
      }

      final label = item.toString().trim();
      if (label.isEmpty) continue;
      categories.add(
        BranchCategoryOption(label: label, colorValue: 0xFFD9D0C3),
      );
    }

    return categories;
  }

  Future<String> _resolveBranchName({
    required String branchId,
    required Map<String, dynamic> groupData,
  }) async {
    final savedBranchName = groupData['nombre_sucursal']?.toString().trim();
    if (savedBranchName != null && savedBranchName.isNotEmpty) {
      return savedBranchName;
    }

    final branchSnapshot =
        await _db.collection('sucursales').doc(branchId).get();
    final branchName = branchSnapshot.data()?['name']?.toString().trim();
    if (branchName != null && branchName.isNotEmpty) {
      return branchName;
    }

    return branchId;
  }

  String _buildGroupDocumentId({
    required String branchName,
    required String groupName,
  }) {
    final normalizedBranchName = _slugify(branchName);
    final normalizedGroupName = _slugify(groupName);
    return '${normalizedBranchName}__$normalizedGroupName';
  }

  String _slugify(String value) {
    final cleaned = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');

    return cleaned.isEmpty ? 'grupo' : cleaned;
  }
}
