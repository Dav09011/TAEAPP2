import 'package:tae_app/core/errors/app_exception.dart';
import 'package:tae_app/core/services/auth_service.dart';
import 'package:tae_app/core/services/firestore_service.dart';
import 'package:tae_app/features/student/domain/entities/student_branch_context.dart';
import 'package:tae_app/features/student/domain/repositories/student_calendar_repository.dart';

class FirebaseStudentCalendarRepository implements StudentCalendarRepository {
  FirebaseStudentCalendarRepository({
    AuthService? authService,
    FirestoreService? firestoreService,
  }) : _authService = authService ?? AuthService(),
       _firestoreService = firestoreService ?? FirestoreService();

  final AuthService _authService;
  final FirestoreService _firestoreService;

  @override
  Stream<List<StudentBranchContext>> watchBranchesForCurrentStudent() {
    final user = _authService.currentUser;
    if (user == null) {
      return Stream<List<StudentBranchContext>>.error(
        const AppException('No hay sesion activa.'),
      );
    }

    return _firestoreService.users().doc(user.uid).snapshots().asyncMap((
      snapshot,
    ) {
      return _loadStudentBranchContexts(
        uid: user.uid,
        userData: snapshot.data() ?? const <String, dynamic>{},
      );
    });
  }

  Future<List<StudentBranchContext>> _loadStudentBranchContexts({
    required String uid,
    required Map<String, dynamic> userData,
  }) async {
    final candidates = <_StudentBranchCandidate>[
      ..._parseSavedBranchCandidates(userData),
    ];

    final legacyGroupId = userData['grupo_id']?.toString().trim() ?? '';
    if (legacyGroupId.isNotEmpty &&
        candidates.every((candidate) => candidate.groupId != legacyGroupId)) {
      candidates.add(_StudentBranchCandidate(groupId: legacyGroupId));
    }

    if (candidates.isEmpty) {
      final studentGroups =
          await _firestoreService.instance
              .collectionGroup('alumnos')
              .where('uid', isEqualTo: uid)
              .get();
      for (final studentDoc in studentGroups.docs) {
        final groupRef = studentDoc.reference.parent.parent;
        if (groupRef != null) {
          candidates.add(_StudentBranchCandidate(groupId: groupRef.id));
        }
      }
    }

    final branchesByKey = <String, _MutableBranchContext>{};
    for (final candidate in candidates) {
      final resolved = await _resolveBranchCandidate(candidate);
      if (resolved == null || resolved.branchId.isEmpty) {
        continue;
      }

      final key = _branchDedupKey(resolved);
      final branch =
          branchesByKey[key] ??
          _MutableBranchContext(
            branchId: resolved.branchId,
            branchName: resolved.branchName,
          );
      branch.absorb(resolved);
      branchesByKey[key] = branch;
    }

    final branches =
        branchesByKey.values.map((branch) => branch.freeze()).toList()
          ..sort((a, b) => a.branchName.compareTo(b.branchName));
    return branches;
  }

  List<_StudentBranchCandidate> _parseSavedBranchCandidates(
    Map<String, dynamic> userData,
  ) {
    final rawGroups = userData['grupos'];
    if (rawGroups is! List) {
      return const [];
    }

    return rawGroups.whereType<Map>().map((rawGroup) {
      final group = Map<String, dynamic>.from(rawGroup);
      return _StudentBranchCandidate(
        groupId: group['groupId']?.toString().trim() ?? '',
        groupName: group['groupName']?.toString().trim() ?? '',
        branchId: group['branchId']?.toString().trim() ?? '',
        branchName: group['branchName']?.toString().trim() ?? '',
      );
    }).toList();
  }

  Future<StudentBranchContext?> _resolveBranchCandidate(
    _StudentBranchCandidate candidate,
  ) async {
    var branchId = candidate.branchId.trim();
    var branchName = candidate.branchName.trim();
    var groupName = candidate.groupName.trim();

    if (candidate.groupId.isNotEmpty) {
      final groupDoc =
          await _firestoreService.instance
              .collection('grupos')
              .doc(candidate.groupId)
              .get();
      final groupData = groupDoc.data();
      if (groupData != null) {
        final liveBranchId = groupData['id_sucursal']?.toString().trim() ?? '';
        final liveBranchName =
            groupData['nombre_sucursal']?.toString().trim() ?? '';
        final liveGroupName =
            groupData['nombre_grupo']?.toString().trim() ?? '';

        branchId = liveBranchId.isNotEmpty ? liveBranchId : branchId;
        branchName = liveBranchName.isNotEmpty ? liveBranchName : branchName;
        groupName = liveGroupName.isNotEmpty ? liveGroupName : groupName;
      }
    }

    if (branchId.isNotEmpty && branchName.isEmpty) {
      final branchDoc = await _firestoreService.branches().doc(branchId).get();
      branchName = branchDoc.data()?['name']?.toString().trim() ?? branchId;
    }

    if (branchId.isEmpty && branchName.isNotEmpty) {
      final query =
          await _firestoreService
              .branches()
              .where('name', isEqualTo: branchName)
              .limit(1)
              .get();
      if (query.docs.isNotEmpty) {
        branchId = query.docs.first.id;
        branchName =
            query.docs.first.data()['name']?.toString().trim() ?? branchName;
      }
    }

    if (branchId.isEmpty) {
      return null;
    }

    return StudentBranchContext(
      branchId: branchId,
      branchName: branchName.isNotEmpty ? branchName : branchId,
      groupNames: groupName.isEmpty ? const [] : [groupName],
    );
  }

  String _branchDedupKey(StudentBranchContext branch) {
    final normalizedName = branch.branchName.trim().toLowerCase();
    if (normalizedName.isNotEmpty) {
      return 'name:$normalizedName';
    }
    return 'id:${branch.branchId.trim().toLowerCase()}';
  }
}

class _StudentBranchCandidate {
  const _StudentBranchCandidate({
    this.groupId = '',
    this.groupName = '',
    this.branchId = '',
    this.branchName = '',
  });

  final String groupId;
  final String groupName;
  final String branchId;
  final String branchName;
}

class _MutableBranchContext {
  _MutableBranchContext({required this.branchId, required this.branchName});

  String branchId;
  String branchName;
  final Set<String> groupNames = <String>{};

  void absorb(StudentBranchContext resolved) {
    final currentIdLooksLikeName =
        branchId.trim().toLowerCase() == branchName.trim().toLowerCase();
    final resolvedIdLooksLikeName =
        resolved.branchId.trim().toLowerCase() ==
        resolved.branchName.trim().toLowerCase();

    if (currentIdLooksLikeName && !resolvedIdLooksLikeName) {
      branchId = resolved.branchId;
    }
    if (branchName.trim().isEmpty ||
        branchName.trim().toLowerCase() == branchId.trim().toLowerCase()) {
      branchName = resolved.branchName;
    }
    groupNames.addAll(resolved.groupNames);
  }

  StudentBranchContext freeze() {
    final groups = groupNames.toList()..sort();
    return StudentBranchContext(
      branchId: branchId,
      branchName: branchName,
      groupNames: groups.isEmpty ? const ['Grupo inscrito'] : groups,
    );
  }
}
