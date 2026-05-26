import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tae_app/core/services/auth_service.dart';
import 'package:tae_app/core/services/firestore_service.dart';
import 'package:tae_app/features/admin/domain/entities/admin_note_entry.dart';
import 'package:tae_app/features/admin/domain/entities/admin_notes_student.dart';
import 'package:tae_app/features/admin/domain/repositories/notes_repository.dart';

class FirebaseNotesRepository implements NotesRepository {
  FirebaseNotesRepository({
    FirestoreService? firestoreService,
    AuthService? authService,
  }) : _firestoreService = firestoreService ?? FirestoreService(),
       _authService = authService ?? AuthService();

  final FirestoreService _firestoreService;
  final AuthService _authService;

  FirebaseFirestore get _db => _firestoreService.instance;

  @override
  Future<List<AdminNotesStudent>> loadStudentsWithNotes() async {
    final adminId = _requireAdminId();
    final adminSnapshot = await _db.collection('usuarios').doc(adminId).get();
    final adminData = adminSnapshot.data() ?? const <String, dynamic>{};

    final ownedBranches = await _loadOwnedBranches(adminId);

    final allowedBranchNames =
        (adminData['sucursales'] as List<dynamic>? ?? const [])
            .map((value) => value.toString().trim())
            .where((value) => value.isNotEmpty)
            .toSet();

    final allowedBranchNamesEffective = <String>{
      ...allowedBranchNames,
      ...ownedBranches.names,
    };

    final allowedGroupIds =
        (adminData['grupos'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map((group) => group['groupId']?.toString().trim() ?? '')
            .where((value) => value.isNotEmpty)
            .toSet();

    bool isGroupAllowed(Map<String, dynamic> group) {
      final groupId = group['groupId']?.toString().trim() ?? '';
      if (groupId.isNotEmpty && allowedGroupIds.contains(groupId)) {
        return true;
      }

      final branchId = group['branchId']?.toString().trim() ?? '';
      if (branchId.isNotEmpty && ownedBranches.ids.contains(branchId)) {
        return true;
      }

      final branchName = group['branchName']?.toString().trim() ?? '';
      if (branchName.isNotEmpty && allowedBranchNamesEffective.contains(branchName)) {
        return true;
      }

      return false;
    }

    final notesRoot = _db
        .collection('usuarios')
        .doc(adminId)
        .collection('notas_alumnos');

    // Notes can exist even if group membership data is incomplete. We always
    // include students already present in `notas_alumnos` as a fallback source.
    final notesSummarySnapshot = await notesRoot.get();
    final fallbackStudentIds = notesSummarySnapshot.docs.map((doc) => doc.id).toSet();

    final groupsSnapshot = await _db.collection('grupos').get();
    final accessibleGroups =
        groupsSnapshot.docs.where((doc) {
          final data = doc.data();
          final branchName = data['nombre_sucursal']?.toString().trim() ?? '';
          final branchId = data['id_sucursal']?.toString().trim() ?? '';
          return allowedBranchNamesEffective.contains(branchName) ||
              allowedGroupIds.contains(doc.id) ||
              (branchId.isNotEmpty && ownedBranches.ids.contains(branchId));
        }).toList();

    final aggregatedStudents = <String, _StudentAccumulator>{};
    final studentSubcollections = await Future.wait(
      accessibleGroups.map((groupDoc) => groupDoc.reference.collection('alumnos').get()),
    );

    for (var index = 0; index < accessibleGroups.length; index++) {
      final groupDoc = accessibleGroups[index];
      final groupData = groupDoc.data();
      final groupId = groupDoc.id;
      final groupName = groupData['nombre_grupo']?.toString().trim() ?? groupId;
      final branchId = groupData['id_sucursal']?.toString().trim() ?? '';
      final branchName =
          groupData['nombre_sucursal']?.toString().trim() ?? 'Sin sucursal';

      for (final studentDoc in studentSubcollections[index].docs) {
        final studentData = studentDoc.data();
        final studentId = studentData['uid']?.toString().trim() ?? '';
        if (studentId.isEmpty) {
          continue;
        }

        final accumulator = aggregatedStudents.putIfAbsent(
          studentId,
          () => _StudentAccumulator(studentId: studentId),
        );

        accumulator.nameHint = studentData['nombre']?.toString().trim() ?? accumulator.nameHint;
        accumulator.branchIds.add(branchId);
        accumulator.branchNames.add(branchName);
        accumulator.groupIds.add(groupId);
        accumulator.groupNames.add(groupName);
      }
    }

    if (aggregatedStudents.isEmpty) {
      if (fallbackStudentIds.isEmpty) {
        return const [];
      }
    }

    final studentIds = <String>{
      ...aggregatedStudents.keys,
      ...fallbackStudentIds,
    }.toList();

    final userSnapshots = await Future.wait(
      studentIds.map((studentId) => _db.collection('usuarios').doc(studentId).get()),
    );

    final summaryByStudentId = {
      for (final doc in notesSummarySnapshot.docs) doc.id: doc.data(),
    };

    final entriesSnapshots = await Future.wait(
      studentIds.map(
        (studentId) => notesRoot.doc(studentId).collection('entradas').get(),
      ),
    );

    final result = <AdminNotesStudent>[];

    for (var index = 0; index < userSnapshots.length; index++) {
      final userSnapshot = userSnapshots[index];
      final studentId = userSnapshot.id;
      final accumulator = aggregatedStudents[studentId] ?? _StudentAccumulator(studentId: studentId);

      final userData = userSnapshot.data() ?? const <String, dynamic>{};
      final firstName = userData['nombre']?.toString().trim();
      final lastName = userData['ap']?.toString().trim() ?? '';
      final middleName = userData['am']?.toString().trim() ?? '';
      final fullName = [
        firstName ?? accumulator.nameHint,
        lastName,
        middleName,
      ].where((part) => part.trim().isNotEmpty).join(' ');

      final summaryData = summaryByStudentId[studentId];
      final sortedEntries =
          entriesSnapshots[index].docs
              .map((doc) => _mapEntry(doc))
              .where((entry) => entry.isActive)
              .toList()
            ..sort((a, b) {
              if (a.isPinned != b.isPinned) {
                return a.isPinned ? -1 : 1;
              }
              return b.updatedAt.compareTo(a.updatedAt);
            });

      final groupsFromUserDoc =
          (userData['grupos'] as List<dynamic>? ?? const [])
              .whereType<Map>()
              .map((group) => Map<String, dynamic>.from(group))
              .where(isGroupAllowed)
              .toList();

      final branchNamesFromUser =
          groupsFromUserDoc
              .map((group) => group['branchName']?.toString().trim() ?? '')
              .where((value) => value.isNotEmpty)
              .toSet()
              .toList()
            ..sort();
      final groupNamesFromUser =
          groupsFromUserDoc
              .map((group) => group['groupName']?.toString().trim() ?? '')
              .where((value) => value.isNotEmpty)
              .toSet()
              .toList()
            ..sort();
      final branchIdsFromUser =
          groupsFromUserDoc
              .map((group) => group['branchId']?.toString().trim() ?? '')
              .where((value) => value.isNotEmpty)
              .toSet()
              .toList()
            ..sort();
      final groupIdsFromUser =
          groupsFromUserDoc
              .map((group) => group['groupId']?.toString().trim() ?? '')
              .where((value) => value.isNotEmpty)
              .toSet()
              .toList()
            ..sort();

      final summaryBranchNamesRaw =
          (summaryData?['sucursales_nombres'] as List<dynamic>? ?? const [])
              .map((value) => value.toString().trim())
              .where((value) => value.isNotEmpty)
              .toList();
      final summaryGroupNamesRaw =
          (summaryData?['grupos_nombres'] as List<dynamic>? ?? const [])
              .map((value) => value.toString().trim())
              .where((value) => value.isNotEmpty)
              .toList();

      final allowedGroupNamesEffective = <String>{
        ...accumulator.groupNames,
        ...groupNamesFromUser,
      };

      final resolvedBranchNames =
          (summaryBranchNamesRaw.isNotEmpty
                  ? summaryBranchNamesRaw
                  : accumulator.branchNames.toList())
              .map((value) => value.toString().trim())
              .where((value) => value.isNotEmpty && allowedBranchNamesEffective.contains(value))
              .toSet()
              .toList()
            ..sort();
      final resolvedGroupNames =
          (summaryGroupNamesRaw.isNotEmpty
                  ? summaryGroupNamesRaw
                  : accumulator.groupNames.toList())
              .map((value) => value.toString().trim())
              .where((value) => value.isNotEmpty && allowedGroupNamesEffective.contains(value))
              .toSet()
              .toList()
            ..sort();

      result.add(
        AdminNotesStudent(
          id: studentId,
          name:
              firstName?.isNotEmpty == true
                  ? firstName!
                  : accumulator.nameHint.isNotEmpty
                  ? accumulator.nameHint
                  : 'Sin nombre',
          fullName: fullName.isNotEmpty ? fullName : 'Sin nombre',
          branchIds:
              (accumulator.branchIds.isEmpty ? branchIdsFromUser : accumulator.branchIds.toList())
                ..sort(),
          branchNames: resolvedBranchNames.isNotEmpty ? resolvedBranchNames : branchNamesFromUser,
          groupIds:
              (accumulator.groupIds.isEmpty ? groupIdsFromUser : accumulator.groupIds.toList())
                ..sort(),
          groupNames: resolvedGroupNames.isNotEmpty ? resolvedGroupNames : groupNamesFromUser,
          entries: sortedEntries,
          isActive: (summaryData?['alumno_activo'] as bool?) ?? true,
        ),
      );
    }

    result.sort((a, b) {
      final aDate = a.entries.isEmpty ? DateTime.fromMillisecondsSinceEpoch(0) : a.entries.first.updatedAt;
      final bDate = b.entries.isEmpty ? DateTime.fromMillisecondsSinceEpoch(0) : b.entries.first.updatedAt;
      return bDate.compareTo(aDate);
    });

    return result;
  }

  @override
  Future<AdminNoteEntry> createEntry({
    required AdminNotesStudent student,
    required String content,
    required bool isPinned,
  }) async {
    final adminId = _requireAdminId();
    final notesRoot = _notesRoot(adminId).doc(student.id);
    final entryRef = notesRoot.collection('entradas').doc();
    final now = DateTime.now();

    await _ensureStudentSummary(adminId: adminId, student: student);

    await entryRef.set({
      'nota_id': entryRef.id,
      'admin_id': adminId,
      'alumno_id': student.id,
      'contenido': content,
      'importante': isPinned,
      'activa': true,
      'contexto_grupo_id': student.groupIds.isEmpty ? null : student.groupIds.first,
      'contexto_grupo_nombre': student.groupNames.isEmpty ? null : student.groupNames.first,
      'contexto_sucursal_id': student.branchIds.isEmpty ? null : student.branchIds.first,
      'contexto_sucursal_nombre': student.branchNames.isEmpty ? null : student.branchNames.first,
      'created_at': Timestamp.fromDate(now),
      'updated_at': Timestamp.fromDate(now),
      'deleted_at': null,
    });

    await _refreshStudentSummary(adminId: adminId, student: student);

    return AdminNoteEntry(
      id: entryRef.id,
      studentId: student.id,
      content: content,
      createdAt: now,
      updatedAt: now,
      isPinned: isPinned,
      isActive: true,
      contextGroupId: student.groupIds.isEmpty ? null : student.groupIds.first,
      contextGroupName: student.groupNames.isEmpty ? null : student.groupNames.first,
      contextBranchId: student.branchIds.isEmpty ? null : student.branchIds.first,
      contextBranchName: student.branchNames.isEmpty ? null : student.branchNames.first,
    );
  }

  @override
  Future<AdminNoteEntry> updateEntry({
    required AdminNotesStudent student,
    required AdminNoteEntry entry,
    required String content,
    required bool isPinned,
  }) async {
    final adminId = _requireAdminId();
    final now = DateTime.now();

    await _notesRoot(adminId)
        .doc(student.id)
        .collection('entradas')
        .doc(entry.id)
        .update({
          'contenido': content,
          'importante': isPinned,
          'updated_at': Timestamp.fromDate(now),
        });

    await _refreshStudentSummary(adminId: adminId, student: student);

    return entry.copyWith(
      content: content,
      isPinned: isPinned,
      updatedAt: now,
    );
  }

  @override
  Future<void> setEntryPinned({
    required AdminNotesStudent student,
    required AdminNoteEntry entry,
    required bool isPinned,
  }) async {
    final adminId = _requireAdminId();
    await _notesRoot(adminId)
        .doc(student.id)
        .collection('entradas')
        .doc(entry.id)
        .update({
          'importante': isPinned,
          'updated_at': FieldValue.serverTimestamp(),
        });

    await _refreshStudentSummary(adminId: adminId, student: student);
  }

  @override
  Future<void> deleteEntry({
    required AdminNotesStudent student,
    required AdminNoteEntry entry,
  }) async {
    final adminId = _requireAdminId();
    await _notesRoot(adminId)
        .doc(student.id)
        .collection('entradas')
        .doc(entry.id)
        .update({
          'activa': false,
          'deleted_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });

    await _refreshStudentSummary(adminId: adminId, student: student);
  }

  @override
  Future<void> restoreEntry({
    required AdminNotesStudent student,
    required AdminNoteEntry entry,
  }) async {
    final adminId = _requireAdminId();
    await _notesRoot(adminId)
        .doc(student.id)
        .collection('entradas')
        .doc(entry.id)
        .update({
          'activa': true,
          'deleted_at': null,
          'updated_at': FieldValue.serverTimestamp(),
        });

    await _refreshStudentSummary(adminId: adminId, student: student);
  }

  CollectionReference<Map<String, dynamic>> _notesRoot(String adminId) {
    return _db.collection('usuarios').doc(adminId).collection('notas_alumnos');
  }

  Future<_OwnedBranches> _loadOwnedBranches(String adminId) async {
    final snapshot =
        await _db.collection('sucursales').where('id_usuario', isEqualTo: adminId).get();
    final ids = <String>{};
    final names = <String>{};
    for (final doc in snapshot.docs) {
      ids.add(doc.id);
      final name = doc.data()['name']?.toString().trim() ?? '';
      if (name.isNotEmpty) {
        names.add(name);
      }
    }
    return _OwnedBranches(ids: ids, names: names);
  }

  String _requireAdminId() {
    final adminId = _authService.currentUser?.uid;
    if (adminId == null || adminId.isEmpty) {
      throw StateError('No encontramos una sesion activa.');
    }
    return adminId;
  }

  AdminNoteEntry _mapEntry(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return AdminNoteEntry(
      id: doc.id,
      studentId: data['alumno_id']?.toString() ?? '',
      content: data['contenido']?.toString() ?? '',
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ??
          (data['created_at'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      isPinned: data['importante'] as bool? ?? false,
      isActive: data['activa'] as bool? ?? true,
      contextGroupId: data['contexto_grupo_id']?.toString(),
      contextGroupName: data['contexto_grupo_nombre']?.toString(),
      contextBranchId: data['contexto_sucursal_id']?.toString(),
      contextBranchName: data['contexto_sucursal_nombre']?.toString(),
    );
  }

  Future<void> _ensureStudentSummary({
    required String adminId,
    required AdminNotesStudent student,
  }) async {
    final summaryRef = _notesRoot(adminId).doc(student.id);
    final summarySnapshot = await summaryRef.get();
    if (summarySnapshot.exists) {
      return;
    }

    await summaryRef.set({
      'admin_id': adminId,
      'alumno_activo': student.isActive,
      'alumno_id': student.id,
      'alumno_nombre': student.name,
      'alumno_nombre_completo': student.fullName,
      'alumno_ref_path': 'usuarios/${student.id}',
      'created_at': FieldValue.serverTimestamp(),
      'grupos_ids': student.groupIds,
      'grupos_nombres': student.groupNames,
      'notas_count': 0,
      'notas_importantes_count': 0,
      'sucursales_ids': student.branchIds,
      'sucursales_nombres': student.branchNames,
      'ultima_nota_fecha': null,
      'ultima_nota_preview': '',
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _refreshStudentSummary({
    required String adminId,
    required AdminNotesStudent student,
  }) async {
    final summaryRef = _notesRoot(adminId).doc(student.id);
    final entriesSnapshot = await summaryRef.collection('entradas').get();
    final activeEntries =
        entriesSnapshot.docs
            .map(_mapEntry)
            .where((entry) => entry.isActive)
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    final latestEntry = activeEntries.isEmpty ? null : activeEntries.first;

    await summaryRef.set({
      'admin_id': adminId,
      'alumno_activo': student.isActive,
      'alumno_id': student.id,
      'alumno_nombre': student.name,
      'alumno_nombre_completo': student.fullName,
      'alumno_ref_path': 'usuarios/${student.id}',
      'grupos_ids': student.groupIds,
      'grupos_nombres': student.groupNames,
      'notas_count': activeEntries.length,
      'notas_importantes_count':
          activeEntries.where((entry) => entry.isPinned).length,
      'sucursales_ids': student.branchIds,
      'sucursales_nombres': student.branchNames,
      'ultima_nota_fecha':
          latestEntry == null ? null : Timestamp.fromDate(latestEntry.updatedAt),
      'ultima_nota_preview': latestEntry?.content ?? '',
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

class _StudentAccumulator {
  _StudentAccumulator({required this.studentId});

  final String studentId;
  String nameHint = '';
  final Set<String> branchIds = <String>{};
  final Set<String> branchNames = <String>{};
  final Set<String> groupIds = <String>{};
  final Set<String> groupNames = <String>{};
}

class _OwnedBranches {
  const _OwnedBranches({required this.ids, required this.names});

  final Set<String> ids;
  final Set<String> names;
}
