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
          FirebaseFirestore.instance.collection('usuarios').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(
              child: Text('No pudimos cargar tu calendario por ahora.'),
            ),
          );
        }

        final userData = snapshot.data?.data() ?? const <String, dynamic>{};
        final branchContext = _resolveStudentBranchContext(userData);

        return FutureBuilder<_StudentBranchContext>(
          future: _resolveBranchContextWithFallback(
            branchContext: branchContext,
            userData: userData,
          ),
          builder: (context, branchSnapshot) {
            if (branchSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final resolvedContext = branchSnapshot.data ?? branchContext;
            return BranchCalendarScreen(
              branchId: resolvedContext.branchId,
              branchName: resolvedContext.branchName,
              isReadOnly: true,
            );
          },
        );
      },
    );
  }
}

class _StudentBranchContext {
  const _StudentBranchContext({
    required this.branchId,
    required this.branchName,
  });

  final String branchId;
  final String branchName;
}

_StudentBranchContext _resolveStudentBranchContext(Map<String, dynamic> userData) {
  final savedGroups = userData['grupos'];
  if (savedGroups is List) {
    for (final rawGroup in savedGroups) {
      if (rawGroup is! Map) continue;
      final group = Map<String, dynamic>.from(rawGroup);
      final branchId = group['branchId']?.toString().trim() ?? '';
      final branchName = group['branchName']?.toString().trim() ?? '';
      if (branchId.isNotEmpty || branchName.isNotEmpty) {
        return _StudentBranchContext(
          branchId: branchId,
          branchName: branchName,
        );
      }
    }
  }

  final fallbackBranchId = userData['grupo_sucursal']?.toString().trim() ?? '';
  return _StudentBranchContext(
    branchId: '',
    branchName: fallbackBranchId,
  );
}

Future<_StudentBranchContext> _resolveBranchContextWithFallback(
  {
  required _StudentBranchContext branchContext,
  required Map<String, dynamic> userData,
}
) async {
  final currentGroupId = userData['grupo_id']?.toString().trim() ?? '';
  if (currentGroupId.isNotEmpty) {
    final groupDoc =
        await FirebaseFirestore.instance.collection('grupos').doc(currentGroupId).get();
    final groupData = groupDoc.data();
    final branchId = groupData?['id_sucursal']?.toString().trim() ?? '';
    final branchName =
        groupData?['nombre_sucursal']?.toString().trim() ??
        branchContext.branchName;
    if (branchId.isNotEmpty) {
      return _StudentBranchContext(
        branchId: branchId,
        branchName: branchName.isNotEmpty ? branchName : branchId,
      );
    }
  }

  if (branchContext.branchId.isNotEmpty && branchContext.branchName.isNotEmpty) {
    return branchContext;
  }

  if (branchContext.branchId.isNotEmpty && branchContext.branchName.isEmpty) {
    final doc =
        await FirebaseFirestore.instance
            .collection('sucursales')
            .doc(branchContext.branchId)
            .get();
    final branchName =
        doc.data()?['name']?.toString().trim() ?? branchContext.branchId;
    return _StudentBranchContext(
      branchId: branchContext.branchId,
      branchName: branchName,
    );
  }

  if (branchContext.branchName.isNotEmpty) {
    final query =
        await FirebaseFirestore.instance
            .collection('sucursales')
            .where('name', isEqualTo: branchContext.branchName)
            .limit(1)
            .get();
    if (query.docs.isNotEmpty) {
      return _StudentBranchContext(
        branchId: query.docs.first.id,
        branchName: branchContext.branchName,
      );
    }
  }

  return branchContext;
}
