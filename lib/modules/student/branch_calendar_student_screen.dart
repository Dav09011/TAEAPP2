import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tae_app/modules/admin/pages/branch_calendar_screen.dart';

class BranchCalendarStudentScreen extends StatelessWidget {
  const BranchCalendarStudentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('No hay sesion activa.')),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream:
          FirebaseFirestore.instance
              .collection('usuarios')
              .doc(user.uid)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(
              child: Text('No pudimos cargar tus calendarios por ahora.'),
            ),
          );
        }

        final userData = snapshot.data?.data() ?? const <String, dynamic>{};

        return FutureBuilder<List<_StudentBranchContext>>(
          future: _loadStudentBranchContexts(
            uid: user.uid,
            userData: userData,
          ),
          builder: (context, branchSnapshot) {
            if (branchSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (branchSnapshot.hasError) {
              return const Scaffold(
                body: Center(
                  child: Text('No pudimos cargar tus sucursales.'),
                ),
              );
            }

            final branches =
                branchSnapshot.data ?? const <_StudentBranchContext>[];
            return _StudentCalendarBranchSelector(branches: branches);
          },
        );
      },
    );
  }
}

class _StudentCalendarBranchSelector extends StatelessWidget {
  const _StudentCalendarBranchSelector({required this.branches});

  final List<_StudentBranchContext> branches;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF7F4EF),
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Calendarios',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body:
          branches.isEmpty
              ? const _NoBranchCalendarsState()
              : ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  const Text(
                    'Elige una sucursal',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Selecciona el calendario que quieres consultar.',
                    style: TextStyle(
                      color: Color(0xFF6D645B),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ...branches.map(
                    (branch) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _BranchCalendarOptionCard(branch: branch),
                    ),
                  ),
                ],
              ),
    );
  }
}

class _BranchCalendarOptionCard extends StatelessWidget {
  const _BranchCalendarOptionCard({required this.branch});

  final _StudentBranchContext branch;

  @override
  Widget build(BuildContext context) {
    final groupCount = branch.groupNames.length;
    final groupSummary =
        groupCount == 1
            ? branch.groupNames.first
            : '$groupCount grupos inscritos';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder:
                  (context) => BranchCalendarScreen(
                    branchId: branch.branchId,
                    branchName: branch.branchName,
                    isReadOnly: true,
                  ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE8DDD2)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      branch.branchName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      groupSummary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF6D645B),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.chevron_right_rounded, size: 34),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoBranchCalendarsState extends StatelessWidget {
  const _NoBranchCalendarsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.event_busy_rounded, size: 76, color: Colors.black38),
            SizedBox(height: 18),
            Text(
              'Sin calendarios disponibles',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Cuando estes inscrito en una sucursal, podras consultar aqui sus eventos.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF6D645B),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentBranchContext {
  const _StudentBranchContext({
    required this.branchId,
    required this.branchName,
    required this.groupNames,
  });

  final String branchId;
  final String branchName;
  final List<String> groupNames;
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
  _MutableBranchContext({
    required this.branchId,
    required this.branchName,
  });

  String branchId;
  String branchName;
  final Set<String> groupNames = <String>{};

  void absorb(_StudentBranchContext resolved) {
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

  _StudentBranchContext freeze() {
    final groups = groupNames.toList()..sort();
    return _StudentBranchContext(
      branchId: branchId,
      branchName: branchName,
      groupNames: groups.isEmpty ? const ['Grupo inscrito'] : groups,
    );
  }
}

Future<List<_StudentBranchContext>> _loadStudentBranchContexts({
  required String uid,
  required Map<String, dynamic> userData,
}) async {
  final db = FirebaseFirestore.instance;
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
        await db.collectionGroup('alumnos').where('uid', isEqualTo: uid).get();
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

  final branches = branchesByKey.values.map((branch) => branch.freeze()).toList()
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

Future<_StudentBranchContext?> _resolveBranchCandidate(
  _StudentBranchCandidate candidate,
) async {
  final db = FirebaseFirestore.instance;
  var branchId = candidate.branchId.trim();
  var branchName = candidate.branchName.trim();
  var groupName = candidate.groupName.trim();

  if (candidate.groupId.isNotEmpty) {
    final groupDoc =
        await db.collection('grupos').doc(candidate.groupId).get();
    final groupData = groupDoc.data();
    if (groupData != null) {
      final liveBranchId = groupData['id_sucursal']?.toString().trim() ?? '';
      final liveBranchName =
          groupData['nombre_sucursal']?.toString().trim() ?? '';
      final liveGroupName = groupData['nombre_grupo']?.toString().trim() ?? '';

      branchId =
          liveBranchId.isNotEmpty
              ? liveBranchId
              : branchId;
      branchName =
          liveBranchName.isNotEmpty
              ? liveBranchName
              : branchName;
      groupName =
          liveGroupName.isNotEmpty
              ? liveGroupName
              : groupName;
    }
  }

  if (branchId.isNotEmpty && branchName.isEmpty) {
    final branchDoc = await db.collection('sucursales').doc(branchId).get();
    branchName = branchDoc.data()?['name']?.toString().trim() ?? branchId;
  }

  if (branchId.isEmpty && branchName.isNotEmpty) {
    final query =
        await db
            .collection('sucursales')
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

  return _StudentBranchContext(
    branchId: branchId,
    branchName: branchName.isNotEmpty ? branchName : branchId,
    groupNames: groupName.isEmpty ? const [] : [groupName],
  );
}

String _branchDedupKey(_StudentBranchContext branch) {
  final normalizedName = branch.branchName.trim().toLowerCase();
  if (normalizedName.isNotEmpty) {
    return 'name:$normalizedName';
  }
  return 'id:${branch.branchId.trim().toLowerCase()}';
}
