import 'package:flutter/material.dart';
import 'package:tae_app/core/errors/app_exception.dart';
import 'package:tae_app/features/admin/domain/entities/activity_item.dart';
import 'package:tae_app/features/admin/domain/entities/belt_section.dart';
import 'package:tae_app/features/admin/domain/entities/create_activity_request.dart';
import 'package:tae_app/features/admin/presentation/controllers/activities_controller.dart';
import 'package:tae_app/modules/admin/pages/admin_branch_calendar_selector.dart';
import 'package:tae_app/modules/admin/pages/profile_screen.dart';
import 'package:tae_app/modules/admin/pages/students_section.dart';
import 'package:tae_app/modules/admin/pages/wallet_screen.dart';
import 'package:tae_app/modules/admin/widgets/activities_card.dart';
import 'package:tae_app/modules/admin/widgets/custom_navigation_bar_admin.dart';
import 'package:tae_app/modules/admin/widgets/notes_button.dart';
import 'package:tae_app/modules/admin/widgets/search_bar.dart';

class ActivitiesSection extends StatefulWidget {
  const ActivitiesSection({
    super.key,
    this.groupName,
    this.groupDocId,
    this.branchName,
    this.branchDocId,
    this.isReadOnly = false,
  });

  final String? groupName;
  final String? groupDocId;
  final String? branchName;
  final String? branchDocId;
  final bool isReadOnly;

  @override
  State<ActivitiesSection> createState() => _ActivitiesSectionState();
}

class _ActivitiesSectionState extends State<ActivitiesSection> {
  int _selectedIndex = 0;

  List<Widget> get _screens => [
    ActivitiesSectionScreen(
      groupName: widget.groupName,
      groupDocId: widget.groupDocId,
      branchName: widget.branchName,
      branchDocId: widget.branchDocId,
      isReadOnly: widget.isReadOnly,
    ),
    const AdminBranchCalendarSelectorScreen(includeScaffold: false),
    const WalletScreen(),
    const ProfileScreen(
      fullName: 'Josepe',
      email: 'Josepe13186',
      phone: '34234234',
      role: 'Administrador',
      imageUrl: '',
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isReadOnly) {
      return Scaffold(
        body: ActivitiesSectionScreen(
          groupName: widget.groupName,
          groupDocId: widget.groupDocId,
          branchName: widget.branchName,
          branchDocId: widget.branchDocId,
          isReadOnly: true,
        ),
      );
    }

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: CustomNavigationBarAdmin(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
      floatingActionButton: _selectedIndex == 0 ? const NotesButton() : null,
    );
  }
}

/// Transitional activities screen.
///
/// This screen still owns modal composition and navigation, but all activity
/// and belt-section persistence now goes through `ActivitiesController`.
class ActivitiesSectionScreen extends StatefulWidget {
  const ActivitiesSectionScreen({
    super.key,
    this.groupName,
    this.groupDocId,
    this.branchName,
    this.branchDocId,
    this.isReadOnly = false,
  });

  final String? groupName;
  final String? groupDocId;
  final String? branchName;
  final String? branchDocId;
  final bool isReadOnly;

  @override
  State<ActivitiesSectionScreen> createState() => _ActivitiesSectionScreenState();
}

class _ActivitiesSectionScreenState extends State<ActivitiesSectionScreen> {
  final ActivitiesController _controller = ActivitiesController();

  String? get _groupId => widget.groupDocId ?? widget.groupName;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleControllerChanged);
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
      ),
    );
  }

  Future<void> _showAddActivityDialog(String beltName) async {
    final activityNameController = TextEditingController();
    final exercises = <String>[];

    await showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setLocalState) => AlertDialog(
                  backgroundColor: Colors.grey[50],
                  title: Text('Agregar actividad a $beltName'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: activityNameController,
                          decoration: InputDecoration(
                            labelText: 'Nombre de la actividad',
                            labelStyle: const TextStyle(color: Colors.blueGrey),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.blue.shade400),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.blue,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...exercises.map(
                          (exercise) => ListTile(
                            title: Text(exercise),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setLocalState(() {
                                  exercises.remove(exercise);
                                });
                              },
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(
                              160,
                              76,
                              175,
                              79,
                            ),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () async {
                            final exerciseController = TextEditingController();
                            final result = await showDialog<String>(
                              context: ctx,
                              builder:
                                  (innerCtx) => AlertDialog(
                                    backgroundColor: Colors.grey[50],
                                    title: const Text('Nuevo ejercicio'),
                                    content: TextField(
                                      controller: exerciseController,
                                      minLines: 3,
                                      maxLines: 6,
                                      decoration: const InputDecoration(
                                        hintText:
                                            'Ej: Describe la tecnica, postura o repeticiones del ejercicio.',
                                        labelText: 'Descripcion del ejercicio',
                                        labelStyle: TextStyle(
                                          color: Colors.blueGrey,
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Colors.blue,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () => Navigator.pop(innerCtx),
                                        style: TextButton.styleFrom(
                                          foregroundColor: const Color.fromARGB(
                                            255,
                                            58,
                                            57,
                                            57,
                                          ),
                                        ),
                                        child: const Text('Cancelar'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.pop(
                                            innerCtx,
                                            exerciseController.text.trim(),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: const Text('Agregar'),
                                      ),
                                    ],
                                  ),
                            );

                            if (result != null && result.isNotEmpty) {
                              setLocalState(() {
                                exercises.add(result);
                              });
                            }
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Agregar ejercicio'),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                      ),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final groupId = _groupId;
                        if (groupId == null || groupId.isEmpty) {
                          Navigator.pop(ctx);
                          return;
                        }

                        try {
                          await _controller.createActivity(
                            CreateActivityRequest(
                              groupId: groupId,
                              beltName: beltName,
                              activityName: activityNameController.text.trim(),
                              exercises: exercises,
                            ),
                          );
                          if (mounted) {
                            _showSnackBar(
                              'Actividad "${activityNameController.text.trim()}" guardada con exito.',
                            );
                          }
                        } on AppException catch (error) {
                          if (mounted) {
                            _showSnackBar(
                              error.message,
                              backgroundColor: Colors.orange,
                            );
                          }
                        } catch (_) {
                          if (mounted) {
                            _showSnackBar(
                              'Error al guardar actividad. Revisa permisos.',
                              backgroundColor: Colors.red,
                            );
                          }
                        }
                        if (mounted) {
                          Navigator.pop(ctx);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Guardar'),
                    ),
                  ],
                ),
          ),
    );
  }

  Future<void> _showAddBeltSectionDialog() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            title: const Text('Nueva seccion de cinta'),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Ej: Cintas Moradas',
                labelStyle: const TextStyle(color: Colors.blueGrey),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue.shade400),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 2),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  foregroundColor: const Color.fromARGB(179, 41, 40, 40),
                ),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () async {
                  final groupId = _groupId;
                  if (groupId == null || groupId.isEmpty) {
                    Navigator.pop(ctx);
                    return;
                  }

                  try {
                    await _controller.createBeltSection(
                      groupId: groupId,
                      beltName: controller.text.trim(),
                    );
                    if (mounted) {
                      _showSnackBar(
                        'Seccion "${controller.text.trim()}" creada.',
                      );
                    }
                  } on AppException catch (error) {
                    if (mounted) {
                      _showSnackBar(
                        error.message,
                        backgroundColor: Colors.orange,
                      );
                    }
                  } catch (_) {
                    if (mounted) {
                      _showSnackBar(
                        'Error al crear seccion en Firebase.',
                        backgroundColor: Colors.red,
                      );
                    }
                  }
                  if (mounted) {
                    Navigator.pop(ctx);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Crear'),
              ),
            ],
          ),
    );
  }

  Future<void> _renameBeltSection(String oldName, String newName) async {
    final groupId = _groupId;
    if (groupId == null || groupId.isEmpty) return;

    try {
      await _controller.renameBeltSection(
        groupId: groupId,
        oldName: oldName,
        newName: newName,
      );
      _showSnackBar(
        'Seccion renombrada de "$oldName" a "$newName".',
        backgroundColor: Colors.green,
      );
    } catch (error) {
      _showSnackBar(
        'Error al renombrar la seccion: $error',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _renameActivity({
    required String activityId,
    required String newName,
  }) async {
    final groupId = _groupId;
    if (groupId == null || groupId.isEmpty) return;

    try {
      await _controller.renameActivity(
        groupId: groupId,
        activityId: activityId,
        newName: newName,
      );
      _showSnackBar(
        'Nombre de actividad actualizado.',
        backgroundColor: Colors.green,
      );
    } catch (_) {
      _showSnackBar(
        'Error al actualizar nombre.',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _deleteActivity(String activityId) async {
    final groupId = _groupId;
    if (groupId == null || groupId.isEmpty) return;

    try {
      await _controller.deleteActivity(groupId: groupId, activityId: activityId);
      _showSnackBar(
        'Actividad eliminada con exito.',
        backgroundColor: Colors.green,
      );
    } catch (_) {
      _showSnackBar(
        'Error al eliminar la actividad.',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _confirmDeleteBeltSection(String beltName) async {
    final groupId = _groupId;
    if (groupId == null || groupId.isEmpty) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Eliminar seccion'),
            content: Text(
              'Se eliminara la seccion "$beltName" y tambien todas sus actividades. Esta accion no se puede deshacer.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );

    if (shouldDelete != true) return;

    try {
      await _controller.deleteBeltSection(
        groupId: groupId,
        beltName: beltName,
      );
      _showSnackBar(
        'Seccion "$beltName" eliminada.',
        backgroundColor: Colors.green,
      );
    } catch (_) {
      _showSnackBar(
        'Error al eliminar la seccion.',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _updateBeltSectionColor({
    required String beltName,
    required int colorValue,
  }) async {
    final groupId = _groupId;
    if (groupId == null || groupId.isEmpty) return;

    try {
      await _controller.updateBeltSectionColor(
        groupId: groupId,
        beltName: beltName,
        colorValue: colorValue,
      );
      _showSnackBar(
        'Color de la seccion actualizado.',
        backgroundColor: Colors.green,
      );
    } catch (_) {
      _showSnackBar(
        'Error al actualizar el color de la seccion.',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _updateActivityColor({
    required String activityId,
    required int colorValue,
  }) async {
    final groupId = _groupId;
    if (groupId == null || groupId.isEmpty) return;

    try {
      await _controller.updateActivityColor(
        groupId: groupId,
        activityId: activityId,
        colorValue: colorValue,
      );
      _showSnackBar(
        'Color de la actividad actualizado.',
        backgroundColor: Colors.green,
      );
    } catch (_) {
      _showSnackBar(
        'Error al actualizar el color de la actividad.',
        backgroundColor: Colors.red,
      );
    }
  }

  List<Map<String, dynamic>> _mapActivities(List<ActivityItem> activities) {
    return activities
        .map(
          (activity) => {
            'id': activity.id,
            'name': activity.name,
            'exercises': activity.exercises,
            'colorValue': activity.colorValue,
          },
        )
        .toList();
  }

  Widget _buildActivitiesHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.20),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.branchName ?? 'Actividades',
            style: const TextStyle(
              color: Color(0xFF6D645B),
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.groupName ?? 'Grupo',
            style: const TextStyle(
              fontSize: 31,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          BarSearch(
            hintText: 'Buscar actividad o cinta',
            onSearch: _controller.updateSearchQuery,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityActionsRow() {
    if (widget.isReadOnly) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => StudentsSectionScreen(
                      groupName: widget.groupName ?? 'Alumnos',
                      groupDocId: widget.groupDocId,
                    ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFB0B4B8)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ver alumnos',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(width: 6),
                Icon(Icons.remove_red_eye, size: 18),
              ],
            ),
          ),
        ),
        InkWell(
          onTap: _controller.isMutating ? null : _showAddBeltSectionDialog,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Agregar Seccion',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
                SizedBox(width: 6),
                Icon(
                  Icons.add_circle_outline,
                  color: Colors.black,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBeltSectionContent(String groupId, BeltSection beltSection) {
    return StreamBuilder<List<ActivityItem>>(
      stream: _controller.watchActivitiesBySection(
        groupId: groupId,
        beltName: beltSection.name,
      ),
      builder: (context, activitySnapshot) {
        if (activitySnapshot.connectionState == ConnectionState.waiting) {
          return const LinearProgressIndicator();
        }

        final activities = activitySnapshot.data ?? const <ActivityItem>[];
        final filteredActivities = _controller.filterActivities(activities);

        if (_controller.searchQuery.isNotEmpty && filteredActivities.isEmpty) {
          return const SizedBox.shrink();
        }

        return ActivitiesCard(
          group: _mapActivities(
            _controller.searchQuery.isEmpty ? activities : filteredActivities,
          ),
          groupTitle: beltSection.name,
          groupId: groupId,
          beltColorValue: beltSection.colorValue,
          isReadOnly: widget.isReadOnly,
          onAddActivity:
              widget.isReadOnly
                  ? null
                  : () => _showAddActivityDialog(beltSection.name),
          onNameChanged: (activityId, newName) {
            _renameActivity(activityId: activityId, newName: newName);
          },
          onDelete: _deleteActivity,
          onBeltNameChanged: (newName) {
            _renameBeltSection(beltSection.name, newName);
          },
          onBeltColorChanged:
              widget.isReadOnly
                  ? null
                  : (colorValue) => _updateBeltSectionColor(
                    beltName: beltSection.name,
                    colorValue: colorValue,
                  ),
          onDeleteBeltSection:
              widget.isReadOnly
                  ? null
                  : () => _confirmDeleteBeltSection(beltSection.name),
          onActivityColorChanged:
              widget.isReadOnly
                  ? null
                  : (activityId, colorValue) => _updateActivityColor(
                    activityId: activityId,
                    colorValue: colorValue,
                  ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupId = _groupId;
    if (groupId == null || groupId.isEmpty) {
      return const Center(
        child: Text('Error: El grupo no fue seleccionado correctamente.'),
      );
    }

    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BackButton(),
              _buildActivitiesHeaderCard(),
              if (!widget.isReadOnly) ...[
                const SizedBox(height: 14),
                _buildActivityActionsRow(),
              ],
              const SizedBox(height: 18),
              Expanded(
                child: StreamBuilder<List<BeltSection>>(
                  stream: _controller.watchBeltSections(groupId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final beltNames = snapshot.data ?? const <BeltSection>[];
                    if (beltNames.isEmpty) {
                      return const Center(
                        child: Text(
                          'Empieza agregando la primera seccion de cinta.',
                        ),
                      );
                    }

                    return ListView(
                      padding: EdgeInsets.zero,
                      children:
                          beltNames
                              .map(
                                (beltSection) => _buildBeltSectionContent(
                                  groupId,
                                  beltSection,
                                ),
                              )
                              .toList(),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
