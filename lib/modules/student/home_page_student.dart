import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tae_app/modules/admin/pages/activities_section.dart';
import 'package:tae_app/modules/student/profile_screen_student.dart';
import 'package:tae_app/modules/student/qr_scanner_page.dart';
import 'package:tae_app/modules/student/wallet_screen_student.dart';
import 'package:tae_app/modules/student/widgets/custom_navigation_bar_student.dart';

class HomePageStudent extends StatefulWidget {
  const HomePageStudent({super.key});

  @override
  State<HomePageStudent> createState() => _HomePageStudentState();
}

class _HomePageStudentState extends State<HomePageStudent> {
  int _selectedIndex = 0;

  late final List<Widget> _screens = const [
    _StudentHomeScreen(),
    WalletScreenStudent(),
    ProfileScreenStudent(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _screens[_selectedIndex],
      bottomNavigationBar: CustomNavigationBarStudent(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
      ),
    );
  }
}

class _StudentHomeScreen extends StatelessWidget {
  const _StudentHomeScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Inicio Alumno',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const QRScannerPage()),
          );
        },
        tooltip: 'Escanear QR',
        child: const Icon(Icons.qr_code_scanner, color: Colors.white),
      ),
      body: const _StudentGroupView(),
    );
  }
}

class _StudentGroupView extends StatelessWidget {
  const _StudentGroupView();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('No hay una sesion activa.'));
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream:
          FirebaseFirestore.instance
              .collection('usuarios')
              .doc(user.uid)
              .snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (userSnapshot.hasError) {
          return const _NoGroupAssignedState(
            message:
                'No se pudo cargar tu grupo. Si ya escaneaste tu QR, intenta entrar de nuevo.',
          );
        }

        return FutureBuilder<List<_StudentGroupData>>(
          future: _loadStudentGroups(user.uid, userSnapshot.data?.data()),
          builder: (context, groupSnapshot) {
            if (groupSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (groupSnapshot.hasError) {
              return const _NoGroupAssignedState(
                message:
                    'No se pudo cargar tu grupo. Si ya escaneaste tu QR, intenta entrar de nuevo.',
              );
            }

            final resolvedGroups =
                groupSnapshot.data ?? const <_StudentGroupData>[];
            if (resolvedGroups.isEmpty) {
              return const _NoGroupAssignedState();
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resolvedGroups.length == 1 ? 'Tu grupo' : 'Tus grupos',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...resolvedGroups.map(
                    (resolvedGroup) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _StudentGroupCard(
                        uid: user.uid,
                        group: resolvedGroup,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _StudentGroupCard extends StatelessWidget {
  final String uid;
  final _StudentGroupData group;

  const _StudentGroupCard({required this.uid, required this.group});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream:
          FirebaseFirestore.instance
              .collection('grupos')
              .doc(group.groupId)
              .snapshots(),
      builder: (context, liveGroupSnapshot) {
        if (liveGroupSnapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (liveGroupSnapshot.hasError) {
          return const _InlineGroupMessage(
            message: 'No pudimos cargar uno de tus grupos.',
          );
        }

        final groupExists = liveGroupSnapshot.data?.exists ?? false;
        if (!groupExists) {
          _removeGroupFromProfile(uid, group.groupId);
          return const _InlineGroupMessage(
            message: 'Un grupo fue eliminado y ya no aparece en tu lista.',
          );
        }

        final groupData = liveGroupSnapshot.data?.data() ?? group.cachedData;
        final groupName =
            (groupData['nombre_grupo'] as String?)?.trim().isNotEmpty == true
                ? groupData['nombre_grupo'] as String
                : group.groupName;
        final branchName =
            (groupData['id_sucursal'] as String?) ?? 'Sucursal no disponible';
        final beltType =
            (groupData['tipo_cinta'] as String?) ?? 'Sin cinta asignada';
        final schedule =
            (groupData['horario'] as String?) ?? 'Horario pendiente';
        final totalStudents = groupData['total_alumnos'] ?? 0;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      groupName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.black87),
                    onSelected: (value) async {
                      if (value == 'leave_group') {
                        final shouldLeave = await _showLeaveGroupDialog(
                          context,
                        );
                        if (!context.mounted) return;
                        if (shouldLeave == true) {
                          await _leaveGroup(
                            context: context,
                            uid: uid,
                            groupId: group.groupId,
                          );
                        }
                      }
                    },
                    itemBuilder:
                        (context) => const [
                          PopupMenuItem<String>(
                            value: 'leave_group',
                            child: Text('Quitar de mi pantalla'),
                          ),
                        ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _InfoRow(label: 'Sucursal', value: branchName),
              _InfoRow(label: 'Cinta', value: beltType),
              _InfoRow(label: 'Horario', value: schedule),
              _InfoRow(label: 'Integrantes', value: '$totalStudents'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => ActivitiesSection(
                              groupName: groupName,
                              groupDocId: group.groupId,
                              isReadOnly: true,
                            ),
                      ),
                    );
                  },
                  child: const Text('Ver ejercicios'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

Future<List<_StudentGroupData>> _loadStudentGroups(
  String uid,
  Map<String, dynamic>? userData,
) async {
  final db = FirebaseFirestore.instance;
  final safeUserData = userData ?? {};
  final savedGroups = _parseGroupsFromUserData(safeUserData);

  if (savedGroups.isNotEmpty) {
    return savedGroups;
  }

  final savedGroupId = (safeUserData['grupo_id'] as String?)?.trim();
  if (savedGroupId != null && savedGroupId.isNotEmpty) {
    return [
      _StudentGroupData(
        groupId: savedGroupId,
        groupName:
            (safeUserData['grupo_nombre'] as String?)?.trim().isNotEmpty == true
                ? safeUserData['grupo_nombre'] as String
                : savedGroupId,
        cachedData: {
          'nombre_grupo': safeUserData['grupo_nombre'],
          'id_sucursal': safeUserData['grupo_sucursal'],
          'tipo_cinta': safeUserData['grupo_cinta'],
          'horario': safeUserData['grupo_horario'],
        },
      ),
    ];
  }

  try {
    final studentQuery =
        await db.collectionGroup('alumnos').where('uid', isEqualTo: uid).get();

    if (studentQuery.docs.isEmpty) {
      return const [];
    }

    final resolvedGroups = <_StudentGroupData>[];
    for (final studentDoc in studentQuery.docs) {
      final groupRef = studentDoc.reference.parent.parent;
      if (groupRef == null) {
        continue;
      }

      final groupDoc = await groupRef.get();
      final groupData = groupDoc.data() ?? {};
      final groupName =
          (groupData['nombre_grupo'] as String?)?.trim().isNotEmpty == true
              ? groupData['nombre_grupo'] as String
              : groupRef.id;

      resolvedGroups.add(
        _StudentGroupData(
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

List<_StudentGroupData> _parseGroupsFromUserData(
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
        final groupId = (groupMap['groupId'] as String?)?.trim();
        if (groupId == null || groupId.isEmpty) {
          return null;
        }

        final groupName =
            (groupMap['groupName'] as String?)?.trim().isNotEmpty == true
                ? groupMap['groupName'] as String
                : groupId;

        return _StudentGroupData(
          groupId: groupId,
          groupName: groupName,
          cachedData: {
            'nombre_grupo': groupMap['groupName'],
            'id_sucursal': groupMap['branchName'],
            'tipo_cinta': groupMap['beltType'],
            'horario': groupMap['schedule'],
          },
        );
      })
      .whereType<_StudentGroupData>()
      .toList();
}

Future<void> _saveGroupsToProfile(String uid, List<_StudentGroupData> groups) {
  final payload =
      groups
          .map(
            (group) => {
              'groupId': group.groupId,
              'groupName': group.groupName,
              'branchName': group.cachedData['id_sucursal'] ?? '',
              'beltType': group.cachedData['tipo_cinta'] ?? '',
              'schedule': group.cachedData['horario'] ?? '',
            },
          )
          .toList();

  return FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
    'grupos': payload,
    if (groups.isNotEmpty) ...{
      'grupo_id': groups.first.groupId,
      'grupo_nombre': groups.first.groupName,
      'grupo_sucursal': groups.first.cachedData['id_sucursal'] ?? '',
      'grupo_cinta': groups.first.cachedData['tipo_cinta'] ?? '',
      'grupo_horario': groups.first.cachedData['horario'] ?? '',
    },
  }, SetOptions(merge: true));
}

Future<void> _removeGroupFromProfile(String uid, String groupId) async {
  final db = FirebaseFirestore.instance;
  final userDoc = await db.collection('usuarios').doc(uid).get();
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
  return FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
    'grupos': FieldValue.delete(),
    'grupo_id': FieldValue.delete(),
    'grupo_nombre': FieldValue.delete(),
    'grupo_sucursal': FieldValue.delete(),
    'grupo_cinta': FieldValue.delete(),
    'grupo_horario': FieldValue.delete(),
  }, SetOptions(merge: true));
}

Future<bool?> _showLeaveGroupDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder:
        (context) => AlertDialog(
          title: const Text('Quitar grupo'),
          content: const Text(
            'Este grupo dejara de aparecer en tu pantalla. Podras volver a entrar escaneando el QR otra vez.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              child: const Text('Quitar'),
            ),
          ],
        ),
  );
}

Future<void> _leaveGroup({
  required BuildContext context,
  required String uid,
  required String groupId,
}) async {
  final db = FirebaseFirestore.instance;

  try {
    final studentDocs =
        await db
            .collection('grupos')
            .doc(groupId)
            .collection('alumnos')
            .where('uid', isEqualTo: uid)
            .get();

    for (final doc in studentDocs.docs) {
      await doc.reference.delete();
    }

    if (studentDocs.docs.isNotEmpty) {
      // ✅ 1. Consultar a qué sucursal pertenece este grupo
      final grupoSnap = await db.collection('grupos').doc(groupId).get();
      final idSucursal = grupoSnap.data()?['id_sucursal'] as String?;
      final alumnosBorrados = studentDocs.docs.length;

      // ✅ 2. Restar alumnos del GRUPO
      await db.collection('grupos').doc(groupId).update({
        'total_alumnos': FieldValue.increment(-alumnosBorrados),
      });

      // ✅ 3. Restar participantes de la SUCURSAL
      if (idSucursal != null && idSucursal.isNotEmpty) {
        await db.collection('sucursales').doc(idSucursal).update({
          'participants': FieldValue.increment(-alumnosBorrados),
        });
      }
    }

    await _removeGroupFromProfile(uid, groupId);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tu grupo ya no aparece en tu pantalla.')),
      );
    }
  } catch (_) {
    await _removeGroupFromProfile(uid, groupId);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Se quito el grupo de tu pantalla.')),
      );
    }
  }
}

class _StudentGroupData {
  final String groupId;
  final String groupName;
  final Map<String, dynamic> cachedData;

  const _StudentGroupData({
    required this.groupId,
    required this.groupName,
    required this.cachedData,
  });
}

class _InlineGroupMessage extends StatelessWidget {
  final String message;

  const _InlineGroupMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(message, style: const TextStyle(color: Colors.black54)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87, fontSize: 16),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class _NoGroupAssignedState extends StatelessWidget {
  final String message;

  const _NoGroupAssignedState({
    this.message =
        'Aun no estas inscrito en un grupo. Escanea el QR que te comparta tu administrador.',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school_outlined, size: 80, color: Colors.black),
            const SizedBox(height: 20),
            const Text(
              'Sin grupo asignado',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
