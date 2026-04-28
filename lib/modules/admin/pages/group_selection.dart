import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tae_app/modules/admin/pages/activities_section.dart';
import 'package:tae_app/modules/admin/widgets/custom_navigation_bar_admin.dart';
import 'package:tae_app/modules/admin/widgets/notes_button.dart';
import 'package:tae_app/modules/admin/widgets/search_bar.dart';
import 'wallet_screen.dart';
import 'profile_screen.dart';
import 'package:tae_app/modules/admin/widgets/add_group_dialog.dart';
import 'package:qr_flutter/qr_flutter.dart';

class BranchGroupsScreen extends StatefulWidget {
  final String branchDocId; // ✅ NUEVO: El ID inmutable de la sucursal
  final String branchName;
  final String? successMessage;

  const BranchGroupsScreen({
    super.key,
    required this.branchName,
    required this.branchDocId, // ✅ NUEVO
    this.successMessage,
  });

  @override
  State<BranchGroupsScreen> createState() => _BranchGroupsScreenState();
}

class _BranchGroupsScreenState extends State<BranchGroupsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  int _selectedIndex = 0;
  late Stream<QuerySnapshot> _groupsStream;

  String _searchQuery = '';
  String? _visibleSuccessMessage;

  @override
  void initState() {
    super.initState();
    // Inicializamos el Stream para escuchar la colección 'grupos'
    _groupsStream =
        _db
            .collection('grupos')
            .where('id_sucursal', isEqualTo: widget.branchDocId)
            .orderBy('nombre_grupo')
            .snapshots();
    _visibleSuccessMessage = widget.successMessage;
  }

  // =================================================================
  // === AGREGAR GRUPO ===
  // =================================================================
  void _openAddGroupDialog(BuildContext context) async {
    final newGroupData = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AddGroupDialog(onSave: (_) {}),
    );

    if (newGroupData == null) return;

    try {
      final String groupName = (newGroupData['name'] as String?)?.trim() ?? '';
      if (groupName.isEmpty) {
        _showSnackBar(
          'El grupo necesita un nombre.',
          backgroundColor: Colors.orange,
        );
        return;
      }

      final existingGroups =
          await _db
              .collection('grupos')
              .where('id_sucursal', isEqualTo: widget.branchDocId)
              .get();

      final normalizedGroupName = groupName.toLowerCase();
      final duplicateExists = existingGroups.docs.any((doc) {
        final savedName =
            (doc.data()['nombre_grupo'] as String?)?.trim().toLowerCase() ?? '';
        return savedName == normalizedGroupName;
      });

      if (duplicateExists) {
        _showSnackBar(
          'Ya existe un grupo con ese nombre en esta sucursal.',
          backgroundColor: Colors.orange,
        );
        return;
      }

      final groupToSave = {
        'nombre_grupo': groupName,
        'tipo_cinta': newGroupData['beltType'],
        'horario': newGroupData['schedule'],
        'id_sucursal': widget.branchDocId,
        'total_alumnos': 0,
        'fecha_creacion': FieldValue.serverTimestamp(),
      };

      await _db.collection('grupos').add(groupToSave);
      await _db.collection('sucursales').doc(widget.branchDocId).update({
        'classes': FieldValue.increment(1),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Grupo $groupName creado con éxito.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print("Error al guardar grupo en Firebase: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al crear grupo. Revisa conexión y permisos.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showSnackBar(String message, {Color? backgroundColor}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showRenameGroupDialog(Map<String, dynamic> group) async {
    final String currentName = (group['name'] as String?)?.trim() ?? '';
    if (currentName.isEmpty) return;

    final controller = TextEditingController(text: currentName);
    final newName = await showDialog<String>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Cambiar nombre del grupo'),
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
                onPressed:
                    () =>
                        Navigator.of(dialogContext).pop(controller.text.trim()),
                child: const Text('Guardar'),
              ),
            ],
          ),
    );

    if (newName == null || newName.isEmpty || newName == currentName) {
      return;
    }

    await _renameGroup(group, newName);
  }

  Future<void> _renameGroup(Map<String, dynamic> group, String newName) async {
    final String docId = (group['docId'] as String?)?.trim() ?? '';
    final String oldName = (group['name'] as String?)?.trim() ?? '';
    if (docId.isEmpty || oldName.isEmpty) return;

    try {
      final duplicateGroupQuery =
          await _db
              .collection('grupos')
              .where('id_sucursal', isEqualTo: widget.branchDocId)
              .get();

      final normalizedNewName = newName.toLowerCase();
      final nameTaken = duplicateGroupQuery.docs.any((doc) {
        if (doc.id == docId) return false;
        final savedName =
            (doc.data()['nombre_grupo'] as String?)?.trim().toLowerCase() ?? '';
        return savedName == normalizedNewName;
      });
      if (nameTaken) {
        _showSnackBar(
          'Ya existe un grupo con ese nombre en esta sucursal.',
          backgroundColor: Colors.orange,
        );
        return;
      }

      await _db.collection('grupos').doc(docId).update({
        'nombre_grupo': newName,
      });

      await _syncUsersAfterGroupRename(groupId: docId, newName: newName);

      _showSnackBar(
        'Grupo renombrado a "$newName".',
        backgroundColor: Colors.green,
      );
    } catch (e) {
      _showSnackBar(
        'No pudimos cambiar el nombre del grupo: $e',
        backgroundColor: Colors.red,
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

  Future<void> _confirmDeleteGroup(Map<String, dynamic> group) async {
    final String groupName = (group['name'] as String?)?.trim() ?? '';
    if (groupName.isEmpty) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Borrar grupo'),
            content: Text(
              'Se borrara "$groupName" y tambien sus alumnos, actividades y secciones. Esta accion no se puede deshacer.',
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
      await _deleteGroup(group);
    }
  }

  Future<void> _deleteGroup(Map<String, dynamic> group) async {
    final String docId = (group['docId'] as String?)?.trim() ?? '';
    final String groupName = (group['name'] as String?)?.trim() ?? '';
    if (docId.isEmpty) return;

    try {
      final groupRef = _db.collection('grupos').doc(docId);
      final groupSnapshot = await groupRef.get();
      final totalAlumnos =
          (groupSnapshot.data()?['total_alumnos'] as num?)?.toInt() ?? 0;

      await _deleteCollection(groupRef.collection('alumnos'));
      await _deleteCollection(groupRef.collection('actividades'));
      await _deleteCollection(groupRef.collection('secciones_cinta'));
      await groupRef.delete();

      await _syncUsersAfterGroupDelete(groupId: docId);

      // ✅ UNA SOLA ACTUALIZACIÓN ATÓMICA
      await _db.collection('sucursales').doc(widget.branchDocId).update({
        'classes': FieldValue.increment(-1),
        'participants': FieldValue.increment(-totalAlumnos),
      });

      _showSnackBar(
        'Grupo "${groupName.isEmpty ? docId : groupName}" eliminado correctamente.',
        backgroundColor: Colors.green,
      );
    } catch (e) {
      _showSnackBar(
        'No pudimos borrar el grupo: $e',
        backgroundColor: Colors.red,
      );
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

  // =================================================================
  // === VISTA DE GRUPOS (DINÁMICA) ===
  // =================================================================
  Widget _buildGroupsContent() {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BarSearch(
                hintText: 'Buscar grupo, cinta o horario',
                onSearch: (query) {
                  setState(() {
                    _searchQuery = query;
                  });
                },
              ),
              if (_visibleSuccessMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _visibleSuccessMessage!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _visibleSuccessMessage = null;
                          });
                        },
                        icon: const Icon(Icons.close, color: Colors.white),
                        tooltip: 'Cerrar mensaje',
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 10),

              // Botón Agregar Grupo
              Align(
                alignment: Alignment.centerRight,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _openAddGroupDialog(context),
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Agregar Grupo  ',
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

              // === StreamBuilder: Escucha cambios en 'grupos' ===

              // === StreamBuilder mejorado con filtro local ===
              StreamBuilder<QuerySnapshot>(
                stream: _groupsStream,
                builder: (context, snapshot) {
                  try {
                    if (snapshot.hasError) {
                      return const Text(
                        '¡Oh no! Tuvimos un error al cargar los grupos.',
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                      // 1. Extraer todos los grupos desde Firebase
                      final allGroups =
                          snapshot.data!.docs.map((doc) {
                            final data =
                                doc.data() as Map<String, dynamic>? ?? {};
                            return {
                              'docId': doc.id,
                              'name': data['nombre_grupo'] ?? 'Sin Nombre',
                              'beltType': data['tipo_cinta'] ?? 'N/A',
                              'schedule': data['horario'] ?? 'Sin horario',
                              'alumns':
                                  '${data['total_alumnos'] ?? 0} participantes',
                            };
                          }).toList();

                      // 2. Filtrar localmente según _searchQuery
                      List<Map<String, dynamic>> filteredGroups = allGroups;
                      if (_searchQuery.isNotEmpty) {
                        final query = _searchQuery.toLowerCase();
                        filteredGroups =
                            allGroups.where((group) {
                              final name =
                                  (group['name'] as String).toLowerCase();
                              final belt =
                                  (group['beltType'] as String).toLowerCase();
                              final schedule =
                                  (group['schedule'] as String).toLowerCase();
                              return name.contains(query) ||
                                  belt.contains(query) ||
                                  schedule.contains(query);
                            }).toList();
                      }

                      // 3. Mostrar resultados
                      if (filteredGroups.isEmpty) {
                        return const Center(
                          child: Text('No se encontraron grupos.'),
                        );
                      }

                      return Column(
                        children:
                            filteredGroups
                                .map((group) => _buildGroupCard(group))
                                .toList(),
                      );
                    }

                    return Center(
                      child: Text(
                        'Aún no hay grupos para ${widget.branchName}. ¡Agrega uno!',
                      ),
                    );
                  } catch (e, stack) {
                    print("⚠️ Error en StreamBuilder: $e\n$stack");
                    return const Text('Error al renderizar grupos.');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =================================================================
  // === TARJETA DE GRUPO ===
  // =================================================================
  Widget _buildGroupCard(Map<String, dynamic> group) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxCardWidth =
            constraints.maxWidth > 800 ? 600 : constraints.maxWidth * 0.95;

        return Center(
          child: Container(
            width: maxCardWidth,
            margin: const EdgeInsets.only(bottom: 26),
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => ActivitiesSection(
                              groupName: group['name'],
                              groupDocId: group['docId'],
                            ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(right: 56),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          group['name'],
                          style: const TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tipo de cinta(s): ${group["beltType"]}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          'Horario: ${group["schedule"]}',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[500],
                          ),
                        ),
                        Text(
                          'Alumnos: ${group["alumns"]}',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: -10,
                  right: -10,
                  child: PopupMenuButton<String>(
                    tooltip: 'Opciones del grupo',
                    onSelected: (value) {
                      if (value == 'rename') {
                        _showRenameGroupDialog(group);
                      } else if (value == 'delete') {
                        _confirmDeleteGroup(group);
                      }
                    },
                    itemBuilder:
                        (context) => const [
                          PopupMenuItem<String>(
                            value: 'rename',
                            child: Text('Cambiar nombre'),
                          ),
                          PopupMenuItem<String>(
                            value: 'delete',
                            child: Text('Borrar grupo'),
                          ),
                        ],
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => _showQRDialog(context, group),
                    child: const Icon(
                      Icons.qr_code,
                      size: 36,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =================================================================
  // === OBTENER PANTALLA ACTUAL ===
  // =================================================================
  Widget _getCurrentScreen() {
    switch (_selectedIndex) {
      case 0:
        return _buildGroupsContent();
      case 1:
        return WalletScreen();
      case 2:
        return ProfileScreen(
          fullName: 'Josepe',
          email: 'Josepe13186',
          phone: '34234234',
          role: 'Administrador',
          imageUrl: '',
        );
      default:
        return _buildGroupsContent();
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showQRDialog(BuildContext context, Map<String, dynamic> group) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    group['name'],
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.branchName,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '¿Para quién es el QR?',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 20),
                  // === Opción: Alumno ===
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showQRCode(context, group, tipo: 'alumno');
                      },
                      icon: const Icon(Icons.school_outlined),
                      label: const Text('QR para Alumno'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // === Opción: Usuario Privilegiado ===
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showQRCode(context, group, tipo: 'privilegiado');
                      },
                      icon: const Icon(Icons.admin_panel_settings_outlined),
                      label: const Text('QR para Usuario Privilegiado'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _showQRCode(
    BuildContext context,
    Map<String, dynamic> group, {
    required String tipo,
  }) {
    final bool esPrivilegiado = tipo == 'privilegiado';

    final String qrData =
        esPrivilegiado
            ? 'PRIVILEGIADO|GrupoId:${group['docId']}|Grupo:${group['name']}|Sucursal:${widget.branchName}'
            : 'ALUMNO|GrupoId:${group['docId']}|Grupo:${group['name']}|Sucursal:${widget.branchName}';

    // === GENERACIÓN DEL CÓDIGO NUMÉRICO ===
    // Tomamos los datos del QR, los convertimos a un número único (hashCode),
    // aseguramos que sea positivo (abs) y tomamos los primeros 6 dígitos.
    final String codigoCorto = qrData.hashCode
        .abs()
        .toString()
        .padRight(6, '0')
        .substring(0, 6);

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // === Badge tipo ===
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: esPrivilegiado ? Colors.amber[700] : Colors.black,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          esPrivilegiado
                              ? Icons.admin_panel_settings_outlined
                              : Icons.school_outlined,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          esPrivilegiado ? 'Usuario Privilegiado' : 'Alumno',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    group['name'],
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.branchName,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 20),

                  // === QR ===
                  QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 220,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: 12),

                  // === CÓDIGO NUMÉRICO DE RESPALDO (NUEVO) ===
                  Text(
                    'O ingresa el código:',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    // Separamos el código visualmente (ej. "123 456") para que sea más fácil de leer
                    '${codigoCorto.substring(0, 3)} ${codigoCorto.substring(3, 6)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0, // Espacio entre los números
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ===========================================
                  Text(
                    'Escanea para registrar acceso',
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cerrar',
                      style: TextStyle(color: Colors.black, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Grupos en ${widget.branchName}',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _getCurrentScreen(),
      floatingActionButton: const NotesButton(),
      bottomNavigationBar: CustomNavigationBarAdmin(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
