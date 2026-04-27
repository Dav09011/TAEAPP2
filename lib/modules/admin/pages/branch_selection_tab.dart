import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Widgets personalizados
import 'package:tae_app/modules/admin/widgets/adaptive_branch_list.dart';
import 'package:tae_app/modules/admin/widgets/add_dialog.dart';
import 'package:tae_app/modules/admin/widgets/custom_navigation_bar_admin.dart';
import 'package:tae_app/modules/admin/widgets/notes_button.dart';
import 'package:tae_app/modules/admin/widgets/search_bar.dart';

// Pantallas
import 'group_selection.dart';
import 'wallet_screen.dart';
import 'profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const TaeApp());
}

class TaeApp extends StatelessWidget {
  const TaeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainBranches(),
    );
  }
}

class MainBranches extends StatefulWidget {
  const MainBranches({super.key});

  @override
  State<MainBranches> createState() => _MainBranchesState();
}

class _MainBranchesState extends State<MainBranches> {
  int _selectedIndex = 0;

  // Lista de pantallas para la navegación inferior
  final List<Widget> _screens = [
    BranchesScreen(),
    WalletScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: CustomNavigationBarAdmin(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

class BranchesScreen extends StatefulWidget {
  const BranchesScreen({super.key});

  @override
  State<BranchesScreen> createState() => _BranchesScreenState();
}

class _BranchesScreenState extends State<BranchesScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance; // ✅ Instancia de Auth añadida

  late final Stream<QuerySnapshot> _branchesStream;
  String _searchQuery = '';

  // ✅ Nuevas variables para controlar el acceso
  List<String> _sucursalesPermitidas = [];
  bool _cargandoPermisos = true;

  @override
  void initState() {
    super.initState();
    _branchesStream = _db.collection('sucursales').orderBy('name').snapshots();
    _cargarPermisosAdmin(); // ✅ Cargar permisos antes de mostrar los datos
  }

  // ✅ Función para leer las sucursales asignadas al admin actual
  Future<void> _cargarPermisosAdmin() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        final userDoc = await _db.collection('usuarios').doc(uid).get();
        if (userDoc.exists && userDoc.data()!.containsKey('sucursales')) {
          final List<dynamic> sucursales = userDoc['sucursales'];
          setState(() {
            _sucursalesPermitidas = sucursales.map((e) => e.toString()).toList();
            _cargandoPermisos = false;
          });
          return;
        }
      }
    } catch (e) {
      print("Error obteniendo permisos de sucursales: $e");
    }
    
    // Si falla o no tiene sucursales, quitamos el loading de todos modos
    setState(() => _cargandoPermisos = false);
  }

  void _showSnackBar(String message, {Color? backgroundColor}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: backgroundColor,
      ),
    );
  }

  Future<void> _showRenameBranchDialog(Map<String, dynamic> branch) async {
    final String currentName = (branch['name'] as String?)?.trim() ?? '';
    if (currentName.isEmpty) return;

    final controller = TextEditingController(text: currentName);
    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cambiar nombre de sucursal'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nuevo nombre',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (newName == null || newName.isEmpty || newName == currentName) {
      return;
    }

    await _renameBranch(branch, newName);
  }

  Future<void> _renameBranch(
    Map<String, dynamic> branch,
    String newName,
  ) async {
    final String oldName = (branch['name'] as String?)?.trim() ?? '';
    final String docId = (branch['docId'] as String?)?.trim() ?? '';
    if (oldName.isEmpty || docId.isEmpty) return;

    try {
      final duplicateBranchDocs = await _db.collection('sucursales').get();
      final normalizedNewName = newName.toLowerCase();
      final nameTaken = duplicateBranchDocs.docs.any((doc) {
        if (doc.id == docId) return false;
        final savedName = (doc.data()['name'] as String?)?.trim().toLowerCase() ?? '';
        return savedName == normalizedNewName;
      });
      if (nameTaken) {
        _showSnackBar(
          'Ya existe una sucursal con ese nombre.',
          backgroundColor: Colors.orange,
        );
        return;
      }

      await _db.collection('sucursales').doc(docId).update({'name': newName});

      final groupsSnapshot = await _db
          .collection('grupos')
          .where('id_sucursal', isEqualTo: oldName)
          .get();

      if (groupsSnapshot.docs.isNotEmpty) {
        final batch = _db.batch();
        for (final groupDoc in groupsSnapshot.docs) {
          batch.update(groupDoc.reference, {'id_sucursal': newName});
        }
        await batch.commit();
      }

      await _syncUsersAfterBranchRename(oldName: oldName, newName: newName);

      if (!mounted) return;
      setState(() {
        final index = _sucursalesPermitidas.indexOf(oldName);
        if (index != -1) {
          _sucursalesPermitidas[index] = newName;
        }
      });

      _showSnackBar(
        'Sucursal renombrada a "$newName".',
        backgroundColor: Colors.green,
      );
    } catch (e) {
      _showSnackBar(
        'No pudimos cambiar el nombre de la sucursal: $e',
        backgroundColor: Colors.red,
      );
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
        final updatedPermissions = branchPermissions
            .map((value) => value.toString() == oldName ? newName : value.toString())
            .toList();

        if (!_listsAreEqual(branchPermissions, updatedPermissions)) {
          updates['sucursales'] = updatedPermissions;
        }
      }

      final savedGroups = data['grupos'];
      if (savedGroups is List) {
        var groupsChanged = false;
        final updatedGroups = savedGroups.map((group) {
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

  Future<void> _confirmDeleteBranch(Map<String, dynamic> branch) async {
    final String branchName = (branch['name'] as String?)?.trim() ?? '';
    if (branchName.isEmpty) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Borrar sucursal'),
        content: Text(
          'Se borrara "$branchName" y tambien todos sus grupos y registros ligados. Esta accion no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await _deleteBranch(branch);
    }
  }

  Future<void> _deleteBranch(Map<String, dynamic> branch) async {
    final String branchName = (branch['name'] as String?)?.trim() ?? '';
    final String docId = (branch['docId'] as String?)?.trim() ?? '';
    if (branchName.isEmpty || docId.isEmpty) return;

    try {
      final groupsSnapshot = await _db
          .collection('grupos')
          .where('id_sucursal', isEqualTo: branchName)
          .get();

      final deletedGroupIds = <String>{};
      for (final groupDoc in groupsSnapshot.docs) {
        deletedGroupIds.add(groupDoc.id);
        await _deleteGroupDocument(groupDoc);
      }

      await _db.collection('sucursales').doc(docId).delete();
      await _syncUsersAfterBranchDelete(
        branchName: branchName,
        deletedGroupIds: deletedGroupIds,
      );

      if (!mounted) return;
      setState(() {
        _sucursalesPermitidas.remove(branchName);
      });

      _showSnackBar(
        'Sucursal "$branchName" eliminada correctamente.',
        backgroundColor: Colors.green,
      );
    } catch (e) {
      _showSnackBar(
        'No pudimos borrar la sucursal: $e',
        backgroundColor: Colors.red,
      );
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
        final updatedPermissions = branchPermissions
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
        remainingGroups = savedGroups
            .whereType<Map>()
            .map((group) => Map<String, dynamic>.from(group))
            .where((group) {
              final groupId = group['groupId']?.toString() ?? '';
              final groupBranch = group['branchName']?.toString() ?? '';
              return !deletedGroupIds.contains(groupId) && groupBranch != branchName;
            })
            .toList();

        if (remainingGroups.length != savedGroups.length) {
          updates['grupos'] =
              remainingGroups.isEmpty ? FieldValue.delete() : remainingGroups;
        }
      }

      final currentGroupId = data['grupo_id']?.toString() ?? '';
      final currentBranchName = data['grupo_sucursal']?.toString() ?? '';
      final shouldClearCurrentGroup = deletedGroupIds.contains(currentGroupId) ||
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

  Future<void> _openAddBranchDialog() async {
    final newBranchData = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => const AddDialog(),
    );

    if (newBranchData == null) return;

    final String branchName = (newBranchData['name'] as String?)?.trim() ?? '';
    if (branchName.isEmpty) return;

    try {
      final existingBranches = await _db.collection('sucursales').get();
      final normalizedBranchName = branchName.toLowerCase();
      final duplicateExists = existingBranches.docs.any((doc) {
        final savedName = (doc.data()['name'] as String?)?.trim().toLowerCase() ?? '';
        return savedName == normalizedBranchName;
      });

      if (duplicateExists) {
        _showSnackBar(
          'Ya existe una sucursal con ese nombre.',
          backgroundColor: Colors.orange,
        );
        return;
      }

      await _db.collection('sucursales').add({
        'name': branchName,
        'fecha_creacion': FieldValue.serverTimestamp(),
      });

      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        await _db.collection('usuarios').doc(uid).update({
          'sucursales': FieldValue.arrayUnion([branchName])
        });
        setState(() {
          if (!_sucursalesPermitidas.contains(branchName)) {
            _sucursalesPermitidas.add(branchName);
          }
        });
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => BranchGroupsScreen(
            branchName: branchName,
            successMessage: 'Sucursal "$branchName" creada exitosamente',
          ),
        ),
      );
    } catch (e) {
      _showSnackBar(
        'Error al crear la sucursal: ${e.toString()}',
        backgroundColor: Colors.red,
      );
    }
  }

  // ✅ Modificamos el filtro para bloquear las sucursales no permitidas
  List<Map<String, dynamic>> _filtrarSucursales(
    List<Map<String, dynamic>> sucursales,
    String query,
  ) {
    // 1. Filtrar SOLO las que están en el arreglo del administrador
    var sucursalesDelAdmin = sucursales.where((s) {
      return _sucursalesPermitidas.contains(s['name']);
    }).toList();

    // 2. Aplicar el filtro de la barra de búsqueda
    if (query.isEmpty) return sucursalesDelAdmin;
    
    return sucursalesDelAdmin.where((sucursal) {
      final nombre = (sucursal['name'] as String?)?.toLowerCase() ?? '';
      return nombre.contains(query.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Mostrar un indicador mientras consultamos el documento de "usuarios"
    if (_cargandoPermisos) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BarSearch(
                hintText: 'Buscar sucursal',
                onSearch: (query) {
                  setState(() {
                    _searchQuery = query;
                  });
                },
              ),
              const SizedBox(height: 10),

              Align(
                alignment: Alignment.centerRight,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _openAddBranchDialog,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            'Agregar Sucursal  ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(width: 5),
                          Icon(Icons.add_circle_outline),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _branchesStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                          child: Text('Error al cargar las sucursales.'));
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                          child: Text('No hay sucursales registradas.'));
                    }

                    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _db.collection('grupos').snapshots(),
                      builder: (context, groupsSnapshot) {
                        if (groupsSnapshot.hasError) {
                          return const Center(
                            child: Text('Error al cargar el resumen de sucursales.'),
                          );
                        }

                        if (groupsSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final branchStats = <String, Map<String, int>>{};
                        for (final groupDoc in groupsSnapshot.data?.docs ?? const []) {
                          final groupData = groupDoc.data();
                          final branchName =
                              (groupData['id_sucursal'] as String?)?.trim() ?? '';
                          if (branchName.isEmpty) continue;

                          final currentStats = branchStats.putIfAbsent(
                            branchName,
                            () => {'classes': 0, 'participants': 0},
                          );
                          currentStats['classes'] = (currentStats['classes'] ?? 0) + 1;
                          currentStats['participants'] =
                              (currentStats['participants'] ?? 0) +
                                  ((groupData['total_alumnos'] as num?)?.toInt() ?? 0);
                        }

                        final branchesFromFirebase =
                            snapshot.data!.docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final branchName = (data['name'] as String?)?.trim() ?? 'Sin nombre';
                          final stats = branchStats[branchName];

                          return {
                            'docId': doc.id,
                            'name': branchName,
                            'classes': stats?['classes'] ?? 0,
                            'participants': stats?['participants'] ?? 0,
                          };
                        }).toList();

                        final branchesFiltradas = _filtrarSucursales(
                          branchesFromFirebase,
                          _searchQuery,
                        );

                        if (branchesFiltradas.isEmpty) {
                          if (_sucursalesPermitidas.isEmpty && _searchQuery.isEmpty) {
                            return const Center(child: Text('No tienes sucursales asignadas.'));
                          }
                          return const Center(child: Text('No hay resultados.'));
                        }

                        return AdaptiveBranchList(
                          branches: branchesFiltradas,
                          icon: Icons.location_on_outlined,
                          onTap: (branchName) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BranchGroupsScreen(
                                  branchName: branchName.toString(),
                                ),
                              ),
                            );
                          },
                          onRename: _showRenameBranchDialog,
                          onDelete: _confirmDeleteBranch,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: NotesButton(),
    );
  }
}
