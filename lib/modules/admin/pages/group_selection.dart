import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tae_app/core/errors/app_exception.dart';
import 'package:tae_app/features/admin/domain/entities/branch_group.dart';
import 'package:tae_app/features/admin/domain/entities/create_group_request.dart';
import 'package:tae_app/features/admin/presentation/controllers/branch_groups_controller.dart';
import 'package:tae_app/modules/admin/pages/activities_section.dart';
import 'package:tae_app/modules/admin/pages/branch_calendar_screen.dart';
import 'package:tae_app/modules/admin/widgets/add_group_dialog.dart';
import 'package:tae_app/modules/admin/widgets/custom_navigation_bar_admin.dart';
import 'package:tae_app/modules/admin/widgets/notes_button.dart';
import 'package:tae_app/modules/admin/widgets/search_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tae_app/shared/presentation/color_customization.dart';
import 'dart:async';
import 'profile_screen.dart';
import 'wallet_screen.dart';

class BranchGroupsScreen extends StatefulWidget {
  const BranchGroupsScreen({
    super.key,
    required this.branchName,
    required this.branchDocId,
    this.successMessage,
  });

  final String branchDocId;
  final String branchName;
  final String? successMessage;

  @override
  State<BranchGroupsScreen> createState() => _BranchGroupsScreenState();
}

class _BranchGroupsScreenState extends State<BranchGroupsScreen> {
  final BranchGroupsController _controller = BranchGroupsController();
  int _selectedIndex = 0;
  String? _visibleSuccessMessage;
  bool _isSavingCategories = false;

  String? _miRolGlobal;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleControllerChanged);
    _controller.initialize(widget.branchDocId);
    _visibleSuccessMessage = widget.successMessage;
    _buscarMiRolEnFirebase();
  }

  Future<void> _buscarMiRolEnFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();

      if (mounted) {
        setState(() {
          _miRolGlobal = userDoc.data()?['role'] as String?;
        });
      }
    } catch (e) {
      print('Error al buscar rol: $e');
    }
  }
  @override
  void dispose() {
    _controller
      ..removeListener(_handleControllerChanged)
      ..dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    if (mounted) {
      setState(() {});
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

  Future<void> _openAddGroupDialog(BuildContext context) async {
    final newGroupData = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AddGroupDialog(onSave: (_) {}),
    );

    if (newGroupData == null) return;

    final groupName = (newGroupData['name'] as String?)?.trim() ?? '';
    final beltType = (newGroupData['beltType'] as String?)?.trim() ?? '';
    final schedule = (newGroupData['schedule'] as String?)?.trim() ?? '';

    if (groupName.isEmpty || beltType.isEmpty || schedule.isEmpty) {
      _showSnackBar(
        'El grupo necesita nombre, cintas y horario.',
        backgroundColor: Colors.orange,
      );
      return;
    }

    try {
      await _controller.createGroup(
        CreateGroupRequest(
          branchId: widget.branchDocId,
          branchName: widget.branchName,
          name: groupName,
          beltType: beltType,
          schedule: schedule,
        ),
      );
      _showSnackBar(
        'Grupo $groupName creado con exito.',
        backgroundColor: Colors.green,
      );
    } on AppException catch (error) {
      _showSnackBar(error.message, backgroundColor: Colors.orange);
    } catch (_) {
      _showSnackBar(
        'Error al crear grupo. Revisa conexion y permisos.',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _showRenameGroupDialog(BranchGroup group) async {
    final controller = TextEditingController(text: group.name);
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
                    () => Navigator.of(dialogContext).pop(controller.text.trim()),
                child: const Text('Guardar'),
              ),
            ],
          ),
    );

    if (newName == null || newName.isEmpty || newName == group.name) return;

    try {
      await _controller.renameGroup(group, newName);
      _showSnackBar(
        'Grupo renombrado a "$newName".',
        backgroundColor: Colors.green,
      );
    } on AppException catch (error) {
      _showSnackBar(error.message, backgroundColor: Colors.orange);
    } catch (error) {
      _showSnackBar(
        'No pudimos cambiar el nombre del grupo: $error',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _confirmDeleteGroup(BranchGroup group) async {
    // --- EL CANDADO LÓGICO ---
    if (_miRolGlobal != 'admin') {
      _showSnackBar(
        'No tienes permisos para borrar grupos enteros.',
        backgroundColor: Colors.orange,
      );
      return;
    }
    // -------------------------
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Borrar grupo'),
            content: Text(
              'Se borrara "${group.name}" y tambien sus alumnos, actividades y secciones. Esta accion no se puede deshacer.',
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

    if (shouldDelete != true) return;

    try {
      await _controller.deleteGroup(group);
      _showSnackBar(
        'Grupo "${group.name}" eliminado correctamente.',
        backgroundColor: Colors.green,
      );
    } catch (error) {
      _showSnackBar(
        'No pudimos borrar el grupo: $error',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _showGroupColorDialog(BranchGroup group) async {
    final selectedColor = await showPresetColorPickerDialog(
      context: context,
      title: 'Cinta para ${group.name}',
      selectedColorValue: group.cardColorValue,
      options: kTaeKwonDoBeltColorOptions,
    );

    if (selectedColor == null || selectedColor == group.cardColorValue) {
      return;
    }

    try {
      await _controller.updateGroupColor(group, selectedColor);
      _showSnackBar(
        'Color actualizado para "${group.name}".',
        backgroundColor: Colors.green,
      );
    } catch (error) {
      _showSnackBar(
        'No pudimos actualizar el color del grupo: $error',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _pickCategoryColor({
    int? selectedColorValue,
    required ValueChanged<int> onSelected,
  }) async {
    final colorValue = await showPresetColorPickerDialog(
      context: context,
      title: 'Color para la cinta',
      selectedColorValue: selectedColorValue,
      options: _categoryPaletteOptions,
    );

    if (colorValue != null) {
      onSelected(colorValue);
    }
  }

  Future<void> _saveBranchCategories(List<_BranchCategory> categories) async {
    try {
      setState(() {
        _isSavingCategories = true;
      });
      await FirebaseFirestore.instance
          .collection('sucursales')
          .doc(widget.branchDocId)
          .set({
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
      _showSnackBar(
        'Categorias actualizadas para ${widget.branchName}.',
        backgroundColor: Colors.green,
      );
    } catch (error) {
      _showSnackBar(
        'No pudimos guardar las categorias: $error',
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingCategories = false;
        });
      }
    }
  }

  Future<void> _showCategoriesPopup(List<_BranchCategory> initialCategories) async {
    final nameController = TextEditingController();
    var draftCategories = initialCategories
        .map((category) => category.copyWith())
        .toList();
    var draftColorValue = 0xFFF4D03F;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> saveDraft(List<_BranchCategory> categories) async {
              await _saveBranchCategories(categories);
              if (mounted && dialogContext.mounted) {
                setDialogState(() {
                  draftCategories =
                      categories.map((category) => category.copyWith()).toList();
                });
              }
            }

            return AlertDialog(
              title: const Text('Categorias de la sucursal'),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (draftCategories.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE5D7C7)),
                          ),
                          child: const Text(
                            'Aun no hay categorias. Agrega la primera cinta disponible para esta sucursal.',
                            style: TextStyle(
                              color: Color(0xFF6E6154),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ...draftCategories.map((category) {
                        final optionColor = Color(category.colorValue);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: optionColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: optionColor.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 14,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: optionColor,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  category.label,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2E2722),
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed:
                                    _isSavingCategories
                                        ? null
                                        : () => _pickCategoryColor(
                                          selectedColorValue: category.colorValue,
                                          onSelected: (colorValue) async {
                                            final updated =
                                                draftCategories
                                                    .map(
                                                      (item) =>
                                                          item.label ==
                                                                  category.label
                                                              ? item.copyWith(
                                                                colorValue:
                                                                    colorValue,
                                                              )
                                                              : item,
                                                    )
                                                    .toList();
                                            await saveDraft(updated);
                                          },
                                        ),
                                tooltip: 'Cambiar color',
                                icon: const Icon(Icons.palette_outlined),
                              ),
                              IconButton(
                                onPressed:
                                    _isSavingCategories
                                        ? null
                                        : () async {
                                          final updated =
                                              draftCategories
                                                  .where(
                                                    (item) =>
                                                        item.label.toLowerCase() !=
                                                        category.label
                                                            .toLowerCase(),
                                                  )
                                                  .toList();
                                          await saveDraft(updated);
                                        },
                                tooltip: 'Eliminar categoria',
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.62),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE5D7C7)),
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: nameController,
                              decoration: const InputDecoration(
                                labelText: 'Nombre de la cinta',
                                hintText: 'Ej. Roja Avanzada',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed:
                                        _isSavingCategories
                                            ? null
                                            : () => _pickCategoryColor(
                                              selectedColorValue:
                                                  draftColorValue,
                                              onSelected: (colorValue) {
                                                setDialogState(() {
                                                  draftColorValue = colorValue;
                                                });
                                              },
                                            ),
                                    icon: Icon(
                                      Icons.palette_outlined,
                                      color: Color(draftColorValue),
                                    ),
                                    label: const Text('Elegir color'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: Color(draftColorValue),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.black.withValues(
                                        alpha: 0.10,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed:
                                    _isSavingCategories
                                        ? null
                                        : () async {
                                          final label = nameController.text.trim();
                                          if (label.isEmpty) {
                                            _showSnackBar(
                                              'Escribe el nombre de la cinta.',
                                              backgroundColor: Colors.orange,
                                            );
                                            return;
                                          }

                                          final alreadyExists =
                                              draftCategories.any(
                                                (item) =>
                                                    item.label.toLowerCase() ==
                                                    label.toLowerCase(),
                                              );
                                          if (alreadyExists) {
                                            _showSnackBar(
                                              'Esa categoria ya existe en esta sucursal.',
                                              backgroundColor: Colors.orange,
                                            );
                                            return;
                                          }

                                          final updated = [
                                            ...draftCategories,
                                            _BranchCategory(
                                              label: label,
                                              colorValue: draftColorValue,
                                            ),
                                          ];
                                          await saveDraft(updated);
                                          if (dialogContext.mounted) {
                                            setDialogState(() {
                                              nameController.clear();
                                              draftColorValue = 0xFFF4D03F;
                                            });
                                          }
                                        },
                                icon:
                                    _isSavingCategories
                                        ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                        : const Icon(Icons.add),
                                label: Text(
                                  _isSavingCategories
                                      ? 'Guardando...'
                                      : 'Agregar categoria',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2B221C),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cerrar'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
  }

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
                onSearch: _controller.updateSearchQuery,
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
                      const Icon(Icons.check_circle_outline, color: Colors.white),
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
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream:
                    FirebaseFirestore.instance
                        .collection('sucursales')
                        .doc(widget.branchDocId)
                        .snapshots(),
                builder: (context, snapshot) {
                  final categories = _parseBranchCategories(snapshot.data?.data());
                  return Row(
                    children: [
                      _buildCategoriesCard(categories),
                      const Spacer(),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap:
                              _controller.isMutating
                                  ? null
                                  : () => _openAddGroupDialog(context),
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F0E8),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xFFE2D2BF),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Agregar Grupo',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.add_circle_outline),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              StreamBuilder<List<BranchGroup>>(
                stream: _controller.groupsStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('Tuvimos un error al cargar los grupos.'),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final groups = snapshot.data ?? const <BranchGroup>[];
                  final filteredGroups = _controller.filterGroups(groups);

                  if (groups.isEmpty) {
                    return Center(
                      child: Text(
                        'Aun no hay grupos para ${widget.branchName}. Agrega uno.',
                      ),
                    );
                  }

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
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesCard(List<_BranchCategory> categories) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showCategoriesPopup(categories),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F0E8),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2D2BF)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Categorias',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.open_in_new_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupCard(BranchGroup group) {
    final backgroundColor = resolveCardColor(group.cardColorValue);
    final foregroundColor = resolveOnColor(backgroundColor);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxCardWidth =
            constraints.maxWidth > 800 ? 600.0 : constraints.maxWidth * 0.95;

        return Center(
          child: Container(
            width: maxCardWidth,
            margin: const EdgeInsets.only(bottom: 26),
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: backgroundColor,
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
                              groupName: group.name,
                              groupDocId: group.id,
                              branchName: widget.branchName,
                              branchDocId: widget.branchDocId,
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
                          group.name,
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                            color: foregroundColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tipo de cinta(s): ${group.beltType}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: foregroundColor.withOpacity(0.82),
                          ),
                        ),
                        Text(
                          'Horario: ${group.schedule}',
                          style: TextStyle(
                            fontSize: 18,
                            color: foregroundColor.withOpacity(0.68),
                          ),
                        ),
                        Text(
                          'Alumnos: ${group.totalStudents} participantes',
                          style: TextStyle(
                            fontSize: 18,
                            color: foregroundColor.withOpacity(0.68),
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
                      } else if (value == 'color') {
                        _showGroupColorDialog(group);
                      } else if (value == 'delete') {
                        _confirmDeleteGroup(group);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem<String>(
                        value: 'rename',
                        child: Text('Cambiar nombre'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'color',
                        child: Text('Cambiar color'),
                      ),
                      if (_miRolGlobal == 'admin')
                        const PopupMenuItem<String>(
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

  Widget _getCurrentScreen() {
    switch (_selectedIndex) {
      case 0:
        return _buildGroupsContent();
      case 1:
        return BranchCalendarScreen(
          branchId: widget.branchDocId,
          branchName: widget.branchName,
        );
      case 2:
        return const WalletScreen();
      case 3:
        return const ProfileScreen(
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

  void _showQRDialog(BuildContext context, BranchGroup group) {
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
                    group.name,
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
                    'Para quien es el QR?',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 20),
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
    BranchGroup group, {
    required String tipo,
  }) {
    final esPrivilegiado = tipo == 'privilegiado';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DynamicQRDialog(
        group: group,
        branchName: widget.branchName,
        esPrivilegiado: esPrivilegiado,
      ),
    );
  }

  Future<_GroupAccessCodes> _ensureGroupAccessCodes(BranchGroup group) async {
    final groupRef = FirebaseFirestore.instance.collection('grupos').doc(
      group.id,
    );
    final snapshot = await groupRef.get();
    final data = snapshot.data() ?? const <String, dynamic>{};

    final studentCode = _normalizeAccessCode(data['codigo_alumno']);
    final privilegedCode = _normalizeAccessCode(data['codigo_privilegiado']);
    final resolvedStudentCode =
        studentCode.isNotEmpty ? studentCode : _generateFallbackAccessCode();
    final resolvedPrivilegedCode =
        privilegedCode.isNotEmpty
            ? privilegedCode
            : _generateFallbackAccessCode(seed: group.id.length);

    if (studentCode != resolvedStudentCode ||
        privilegedCode != resolvedPrivilegedCode) {
      await groupRef.set({
        'codigo_alumno': resolvedStudentCode,
        'codigo_privilegiado': resolvedPrivilegedCode,
      }, SetOptions(merge: true));
    }

    return _GroupAccessCodes(
      studentCode: resolvedStudentCode,
      privilegedCode: resolvedPrivilegedCode,
    );
  }

  String _normalizeAccessCode(Object? rawCode) {
    final normalized = rawCode?.toString().replaceAll(RegExp(r'[^0-9]'), '');
    return normalized ?? '';
  }

  String _generateFallbackAccessCode({int seed = 0}) {
    final millis = DateTime.now().millisecondsSinceEpoch + seed;
    return (100000 + (millis % 900000)).toString();
  }

  String _formatAccessCode(String code) {
    if (code.length != 6) {
      return code;
    }
    return '${code.substring(0, 3)} ${code.substring(3, 6)}';
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

List<_BranchCategory> _parseBranchCategories(Map<String, dynamic>? data) {
  final saved = data?['available_belts'];
  if (saved is! List || saved.isEmpty) {
    return const <_BranchCategory>[];
  }

  final parsed = <_BranchCategory>[];
  for (final item in saved) {
    if (item is Map) {
      final label = item['label']?.toString().trim() ?? '';
      if (label.isEmpty) continue;
      parsed.add(
        _BranchCategory(
          label: label,
          colorValue:
              (item['color_value'] as num?)?.toInt() ??
              _defaultColorValueForLabel(label),
        ),
      );
      continue;
    }

    final label = item.toString().trim();
    if (label.isEmpty) continue;
    parsed.add(
      _BranchCategory(
        label: label,
        colorValue: _defaultColorValueForLabel(label),
      ),
    );
  }
  return _sortBranchCategories(parsed);
}

List<_BranchCategory> _sortBranchCategories(List<_BranchCategory> categories) {
  final ordered = <_BranchCategory>[];
  for (final option in kTaeKwonDoBeltColorOptions) {
    for (final category in categories) {
      if (category.label.toLowerCase() == option.label.toLowerCase()) {
        ordered.add(category);
      }
    }
  }
  for (final category in categories) {
    if (!ordered.any(
      (value) => value.label.toLowerCase() == category.label.toLowerCase(),
    )) {
      ordered.add(category);
    }
  }
  return ordered;
}

int _defaultColorValueForLabel(String label) {
  for (final option in kTaeKwonDoBeltColorOptions) {
    if (option.label.toLowerCase() == label.toLowerCase()) {
      return option.colorValue;
    }
  }
  for (final option in kPresetColorOptions) {
    if (option.label.toLowerCase() == label.toLowerCase()) {
      return option.colorValue;
    }
  }
  return 0xFFD9D0C3;
}

final List<PresetColorOption> _categoryPaletteOptions = [
  ...kTaeKwonDoBeltColorOptions,
  ...kPresetColorOptions,
];

class _BranchCategory {
  const _BranchCategory({
    required this.label,
    required this.colorValue,
  });

  final String label;
  final int colorValue;

  _BranchCategory copyWith({
    String? label,
    int? colorValue,
  }) {
    return _BranchCategory(
      label: label ?? this.label,
      colorValue: colorValue ?? this.colorValue,
    );
  }
}

class _GroupAccessCodes {
  const _GroupAccessCodes({
    required this.studentCode,
    required this.privilegedCode,
  });

  final String studentCode;
  final String privilegedCode;
}

// ============================================================
// WIDGET DEL CÓDIGO QR DINÁMICO (Con Temporizador)
// ============================================================
class _DynamicQRDialog extends StatefulWidget {
  final BranchGroup group;
  final String branchName;
  final bool esPrivilegiado;

  const _DynamicQRDialog({
    required this.group,
    required this.branchName,
    required this.esPrivilegiado,
  });

  @override
  State<_DynamicQRDialog> createState() => _DynamicQRDialogState();
}

class _DynamicQRDialogState extends State<_DynamicQRDialog> {
  late Timer _timer;
  int _timeLeft = 120; // 2 minutos exactos en segundos
  String _currentCode = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _generarNuevoCodigo(); // Generamos uno nuevo en cuanto se abre la pantalla
    _iniciarTemporizador();
  }

  @override
  void dispose() {
    _timer.cancel(); // ¡Muy importante! Apaga el reloj al cerrar la ventana
    super.dispose();
  }

  void _iniciarTemporizador() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        if (mounted) setState(() => _timeLeft--);
      } else {
        // Se acabó el tiempo: Reiniciamos a 120 y forzamos código nuevo
        _timeLeft = 120;
        _generarNuevoCodigo();
      }
    });
  }

  Future<void> _generarNuevoCodigo() async {
    if (mounted) setState(() => _isLoading = true);

    // 1. Fabricamos un código de 6 dígitos aleatorio basado en el tiempo
    final millis = DateTime.now().millisecondsSinceEpoch;
    final int seed = widget.esPrivilegiado ? 1 : 0;
    final nuevoCodigo = (100000 + ((millis + seed) % 900000)).toString();

    // 2. Lo guardamos inmediatamente en Firebase
    final groupRef = FirebaseFirestore.instance.collection('grupos').doc(widget.group.id);
    final campoActualizar = widget.esPrivilegiado ? 'codigo_privilegiado' : 'codigo_alumno';

    await groupRef.set({
      campoActualizar: nuevoCodigo,
      // Opcional: Podrías guardar la fecha de expiración si el scanner lo necesita
      // 'expiracion_$campoActualizar': DateTime.now().add(const Duration(minutes: 2)).toIso8601String(),
    }, SetOptions(merge: true));

    // 3. Actualizamos la pantalla con el nuevo código
    if (mounted) {
      setState(() {
        _currentCode = nuevoCodigo;
        _isLoading = false;
      });
    }
  }

  String _formatAccessCode(String code) {
    if (code.length != 6) return code;
    return '${code.substring(0, 3)} ${code.substring(3, 6)}';
  }

  String _formatTime(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    // Generamos la cadena exacta que leerá tu escáner
    final qrData = widget.esPrivilegiado
        ? 'PRIVILEGIADO|GrupoId:${widget.group.id}|Grupo:${widget.group.name}|Sucursal:${widget.branchName}|Codigo:$_currentCode'
        : 'ALUMNO|GrupoId:${widget.group.id}|Grupo:${widget.group.name}|Sucursal:${widget.branchName}|Codigo:$_currentCode';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: widget.esPrivilegiado ? Colors.amber[700] : Colors.black,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.esPrivilegiado ? Icons.admin_panel_settings_outlined : Icons.school_outlined,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.esPrivilegiado ? 'Usuario Privilegiado' : 'Alumno',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(widget.group.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(widget.branchName, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            const SizedBox(height: 15),

            // === EL RELOJ TEMPORIZADOR ===
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _timeLeft <= 10 ? Colors.red[50] : Colors.grey[100], // Se pone rojo en los últimos 10 seg
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer_outlined, size: 18, color: _timeLeft <= 10 ? Colors.red : Colors.grey[700]),
                  const SizedBox(width: 5),
                  Text(
                    'Expira en: ${_formatTime(_timeLeft)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _timeLeft <= 10 ? Colors.red : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),

            // === EL QR Y EL CÓDIGO ===
            if (_isLoading)
              const SizedBox(height: 220, child: Center(child: CircularProgressIndicator(color: Colors.black)))
            else ...[
              QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 220,
                backgroundColor: Colors.white,
              ),
              const SizedBox(height: 12),
              Text('O ingresa el codigo:', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
              const SizedBox(height: 4),
              Text(
                _formatAccessCode(_currentCode),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2.0, color: Colors.black87),
              ),
            ],

            const SizedBox(height: 12),
            Text(
              widget.esPrivilegiado
                  ? 'Escanea para registrar acceso privilegiado'
                  : 'Si el alumno no puede escanear, puede escribir este codigo',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar', style: TextStyle(color: Colors.black, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
