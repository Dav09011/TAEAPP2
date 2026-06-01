import 'package:flutter/material.dart';
import 'package:tae_app/modules/admin/pages/activity_detail_screen.dart';
import 'package:tae_app/shared/presentation/color_customization.dart';

class ActivitiesCard extends StatelessWidget {
  const ActivitiesCard({
    super.key,
    required this.group,
    required this.groupTitle,
    required this.groupId,
    this.beltColorValue,
    this.isReadOnly = false,
    this.onAddActivity,
    this.onNameChanged,
    this.onDelete,
    this.onActivityColorChanged,
    this.onBeltNameChanged,
    this.onBeltColorChanged,
    this.onDeleteBeltSection,
  });

  final List<Map<String, dynamic>> group;
  final String groupTitle;
  final String groupId;
  final int? beltColorValue;
  final bool isReadOnly;
  final VoidCallback? onAddActivity;
  final void Function(String activityId, String newName)? onNameChanged;
  final void Function(String activityId)? onDelete;
  final void Function(String activityId, int colorValue)?
  onActivityColorChanged;
  final ValueChanged<String>? onBeltNameChanged;
  final ValueChanged<int>? onBeltColorChanged;
  final VoidCallback? onDeleteBeltSection;

  void _showEditBeltNameDialog(
    BuildContext context,
    String currentName,
    ValueChanged<String>? onConfirm,
  ) {
    final nameController = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Editar nombre de la cinta'),
            content: TextField(
              controller: nameController,
              decoration: const InputDecoration(
                hintText: 'Nuevo nombre',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  final newName = nameController.text.trim();
                  if (newName.isNotEmpty && newName != currentName) {
                    onConfirm?.call(newName);
                  } else if (newName == currentName) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('El nombre ya esta actualizado.'),
                      ),
                    );
                  }
                  Navigator.of(dialogContext).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0EA2DD),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Guardar'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final beltBackgroundColor = resolveCardColor(beltColorValue);
    final beltForegroundColor = resolveOnColor(beltBackgroundColor);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (isReadOnly)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: beltBackgroundColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  groupTitle,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: beltForegroundColor,
                  ),
                ),
              )
            else ...[
              GroupHeaderWithMenu(
                title: groupTitle,
                backgroundColor: beltBackgroundColor,
                foregroundColor: beltForegroundColor,
                onEdit: () {
                  _showEditBeltNameDialog(
                    context,
                    groupTitle,
                    onBeltNameChanged,
                  );
                },
                onChangeColor:
                    onBeltColorChanged == null
                        ? null
                        : () async {
                          final selectedColor =
                              await showPresetColorPickerDialog(
                                context: context,
                                title: 'Cinta para $groupTitle',
                                selectedColorValue: beltColorValue,
                                options: kTaeKwonDoBeltColorOptions,
                              );
                          if (selectedColor != null) {
                            onBeltColorChanged?.call(selectedColor);
                          }
                        },
                onDelete: onDeleteBeltSection,
              ),
              const SizedBox(width: 25),
              InkWell(
                onTap: onAddActivity,
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(Icons.add_circle_outline, size: 30),
                ),
              ),
            ],
          ],
        ),
        if (group.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              isReadOnly
                  ? 'Aun no hay ejercicios asignados en esta seccion.'
                  : 'Aun no hay actividades en esta seccion.',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: group.length,
            itemBuilder: (context, index) {
              final activity = group[index];
              final activityId = activity['id'] as String;
              return ActivityCard(
                group: activity,
                activityId: activityId,
                groupId: groupId,
                fallbackColorValue: beltColorValue,
                isReadOnly: isReadOnly,
                onNameChanged: (newName) {
                  onNameChanged?.call(activityId, newName);
                },
                onDelete: () {
                  onDelete?.call(activityId);
                },
                onColorChanged:
                    onActivityColorChanged == null
                        ? null
                        : (colorValue) =>
                            onActivityColorChanged!(activityId, colorValue),
              );
            },
          ),
        ),
      ],
    );
  }
}

class GroupHeaderWithMenu extends StatelessWidget {
  const GroupHeaderWithMenu({
    super.key,
    required this.title,
    required this.backgroundColor,
    required this.foregroundColor,
    this.onEdit,
    this.onChangeColor,
    this.onDelete,
  });

  final String title;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback? onEdit;
  final VoidCallback? onChangeColor;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'editar') {
          onEdit?.call();
        } else if (value == 'color') {
          onChangeColor?.call();
        } else if (value == 'delete') {
          onDelete?.call();
        }
      },
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.more_vert, size: 20, color: foregroundColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: foregroundColor,
              ),
            ),
          ],
        ),
      ),
      itemBuilder:
          (context) => const [
            PopupMenuItem<String>(
              value: 'editar',
              child: Row(
                children: [
                  Icon(Icons.edit, color: Colors.blue, size: 18),
                  SizedBox(width: 12),
                  Text(
                    'Editar nombre',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'color',
              child: Row(
                children: [
                  Icon(
                    Icons.palette_outlined,
                    color: Colors.deepPurple,
                    size: 18,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Cambiar color',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: Colors.red, size: 18),
                  SizedBox(width: 12),
                  Text(
                    'Eliminar seccion',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
    );
  }
}

class ActivityCard extends StatelessWidget {
  const ActivityCard({
    super.key,
    required this.group,
    required this.activityId,
    required this.groupId,
    this.fallbackColorValue,
    this.isReadOnly = false,
    this.onNameChanged,
    this.onDelete,
    this.onColorChanged,
  });

  final Map<String, dynamic> group;
  final String activityId;
  final String groupId;
  final int? fallbackColorValue;
  final bool isReadOnly;
  final ValueChanged<String>? onNameChanged;
  final VoidCallback? onDelete;
  final ValueChanged<int>? onColorChanged;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = resolveCardColor(
      group['colorValue'] as int?,
      fallback: resolveCardColor(fallbackColorValue),
    );
    final foregroundColor = resolveOnColor(backgroundColor);

    return Container(
      width: 220,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              group['name']?.toString() ?? 'Actividad',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: foregroundColor,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: (group['exercises'] as List?)?.length ?? 0,
                itemBuilder: (context, index) {
                  final exercises = (group['exercises'] as List?) ?? const [];
                  return Text(
                    '${exercises[index]}',
                    style: TextStyle(
                      fontSize: 14,
                      color: foregroundColor.withValues(alpha: 0.82),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (isReadOnly)
                  const SizedBox.shrink()
                else
                  IconButton(
                    icon: Icon(
                      Icons.edit_note_sharp,
                      size: 20,
                      color: foregroundColor,
                    ),
                    onPressed: () => _showEditDialog(context),
                  ),
                if (isReadOnly)
                  const SizedBox(width: 24)
                else
                  IconButton(
                    icon: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: foregroundColor,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ActivityDetailScreen(
                                activityId: activityId,
                                groupId: groupId,
                                activityName: group['name'],
                                exercises: List<String>.from(
                                  group['exercises'] as List? ?? const [],
                                ),
                              ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditNameDialog(BuildContext context) {
    final nameController = TextEditingController(
      text: group['name']?.toString() ?? '',
    );
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Editar nombre'),
            content: TextField(
              controller: nameController,
              decoration: const InputDecoration(
                hintText: 'Nuevo nombre',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  final newName = nameController.text.trim();
                  if (newName.isNotEmpty) {
                    onNameChanged?.call(newName);
                  }
                  Navigator.of(dialogContext).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0EA2DD),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Guardar'),
              ),
            ],
          ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Eliminar actividad'),
            content: Text(
              'Se eliminara la actividad "${group['name']}". Esta accion no se puede deshacer.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  onDelete?.call();
                  Navigator.of(dialogContext).pop();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  'Eliminar',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Opciones de actividad',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Cerrar',
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Que deseas hacer con esta actividad?',
                    style: TextStyle(fontSize: 18, color: Colors.black87),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: [
                      _buildActionButton(
                        label: 'Editar nombre',
                        backgroundColor: const Color(0xFF0B8EE6),
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          _showEditNameDialog(context);
                        },
                      ),
                      _buildActionButton(
                        label: 'Cambiar color',
                        backgroundColor: const Color(0xFF7E57C2),
                        onPressed: () async {
                          Navigator.of(dialogContext).pop();
                          final selectedColor =
                              await showPresetColorPickerDialog(
                                context: context,
                                title: 'Color para ${group['name']}',
                                selectedColorValue: group['colorValue'] as int?,
                              );
                          if (selectedColor != null) {
                            onColorChanged?.call(selectedColor);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: _buildActionButton(
                      label: 'Eliminar',
                      backgroundColor: const Color(0xFFB10202),
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        _showDeleteConfirmation(context);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color backgroundColor,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 170,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        onPressed: onPressed,
        child: Text(label, textAlign: TextAlign.center),
      ),
    );
  }
}
