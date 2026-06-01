import 'package:flutter/material.dart';
import 'package:tae_app/features/admin/domain/entities/admin_student.dart';
import 'package:tae_app/features/admin/presentation/controllers/students_controller.dart';
import 'package:tae_app/modules/admin/widgets/notes_button.dart';
import 'package:tae_app/modules/admin/widgets/search_bar.dart';

class StudentsSectionScreen extends StatefulWidget {
  const StudentsSectionScreen({super.key, this.groupName, this.groupDocId});

  final String? groupName;
  final String? groupDocId;

  @override
  State<StudentsSectionScreen> createState() => _StudentsSectionScreenState();
}

class _StudentsSectionScreenState extends State<StudentsSectionScreen> {
  final StudentsController _controller = StudentsController();
  final Set<String> _selectedStudentIds = <String>{};

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

  Future<void> _showStudentDetails(AdminStudent student) async {
    if (student.userId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No encontramos informacion adicional del alumno.'),
        ),
      );
      return;
    }

    try {
      final details = await _controller.getStudentDetails(student.userId);
      if (!mounted) return;
      final currentGroupName = (widget.groupName ?? '').trim();
      final resolvedBelt =
          student.belt.trim().isNotEmpty ? student.belt.trim() : details.belt;
      final resolvedGroup =
          currentGroupName.isNotEmpty ? currentGroupName : resolvedBelt;

      showDialog(
        context: context,
        builder:
            (dialogContext) => AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 24,
              ),
              titlePadding: const EdgeInsets.fromLTRB(24, 20, 12, 0),
              title: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Informacion del alumno',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              content: SizedBox(
                width: 380,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 20,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F7FB),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 38,
                              backgroundImage:
                                  details.imageUrl.isNotEmpty
                                      ? NetworkImage(details.imageUrl)
                                      : const AssetImage(
                                            'assets/image/Logo.png',
                                          )
                                          as ImageProvider,
                              backgroundColor: Colors.white,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              details.fullName.isNotEmpty
                                  ? details.fullName
                                  : student.name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                _InfoChip(
                                  icon: Icons.sports_martial_arts,
                                  label: 'Cinta',
                                  value:
                                      resolvedBelt.isNotEmpty
                                          ? resolvedBelt
                                          : 'No registrada',
                                ),
                                _InfoChip(
                                  icon: Icons.groups_2_outlined,
                                  label: 'Grupo actual',
                                  value:
                                      resolvedGroup.isNotEmpty
                                          ? resolvedGroup
                                          : 'No registrado',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _DetailCard(
                        icon: Icons.mail_outline,
                        label: 'Correo',
                        value:
                            details.email.isNotEmpty
                                ? details.email
                                : 'No registrado',
                      ),
                      const SizedBox(height: 12),
                      _DetailCard(
                        icon: Icons.phone_outlined,
                        label: 'Telefono',
                        value:
                            details.phone.isNotEmpty
                                ? details.phone
                                : 'No registrado',
                      ),
                      const SizedBox(height: 12),
                      _DetailCard(
                        icon: Icons.badge_outlined,
                        label: 'Tipo',
                        value:
                            details.role.isNotEmpty
                                ? details.role
                                : 'No registrado',
                      ),
                    ],
                  ),
                ),
              ),
            ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No pudimos cargar la informacion: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteSelectedStudents() async {
    final groupId = widget.groupDocId ?? widget.groupName;
    if (groupId == null || groupId.isEmpty || _selectedStudentIds.isEmpty) {
      return;
    }

    try {
      await _controller.deleteStudents(
        groupId: groupId,
        studentIds: _selectedStudentIds.toList(),
      );

      if (mounted) {
        setState(() {
          _selectedStudentIds.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alumno(s) eliminado(s) correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmationDialog(List<AdminStudent> allStudents) {
    if (_selectedStudentIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay alumnos seleccionados')),
      );
      return;
    }

    final selectedStudents =
        allStudents
            .where((student) => _selectedStudentIds.contains(student.id))
            .toList();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color.fromARGB(255, 250, 250, 250),
            title: const Text('Confirmar eliminación'),
            titleTextStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 25,
              color: Colors.black,
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children:
                    selectedStudents
                        .map(
                          (student) => ListTile(
                            leading: CircleAvatar(
                              backgroundImage:
                                  student.imageUrl.isNotEmpty
                                      ? NetworkImage(student.imageUrl)
                                      : const AssetImage(
                                            'assets/image/Logo.png',
                                          )
                                          as ImageProvider,
                              backgroundColor: const Color.fromARGB(
                                255,
                                250,
                                250,
                                250,
                              ),
                            ),
                            title: Text(
                              student.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              student.belt,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                        .toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(213, 247, 222, 1),
                  foregroundColor: const Color.fromARGB(255, 66, 66, 66),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteSelectedStudents();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 214, 1, 1),
                  foregroundColor: const Color.fromARGB(255, 255, 255, 255),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupId = widget.groupDocId ?? widget.groupName;

    if (groupId == null || groupId.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text('Error: El grupo no fue seleccionado correctamente.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Atras'),
        titleTextStyle: const TextStyle(fontSize: 25, color: Colors.white),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BarSearch(
                hintText: 'Buscar alumno por nombre',
                onSearch: _controller.updateSearchQuery,
              ),
              const SizedBox(height: 20),
              StreamBuilder<List<AdminStudent>>(
                stream: _controller.watchStudentsByGroup(groupId),
                builder: (context, snapshot) {
                  final allStudents = snapshot.data ?? const <AdminStudent>[];

                  return Align(
                    alignment: Alignment.centerRight,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap:
                          _controller.isMutating
                              ? null
                              : () =>
                                  _showDeleteConfirmationDialog(allStudents),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.delete,
                              color: Color.fromARGB(255, 184, 10, 10),
                              size: 18,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'Borrar Alumnos Seleccionados',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color.fromARGB(255, 184, 10, 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              Expanded(
                child: StreamBuilder<List<AdminStudent>>(
                  stream: _controller.watchStudentsByGroup(groupId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final students = snapshot.data ?? const <AdminStudent>[];
                    if (students.isEmpty) {
                      return const Center(
                        child: Text(
                          'No hay alumnos registrados en este grupo.',
                        ),
                      );
                    }

                    final grouped = _controller.groupByBelt(students);
                    final filtered = _controller.filterGroupedStudents(grouped);

                    if (filtered.isEmpty) {
                      return const Center(
                        child: Text('No se encontraron alumnos.'),
                      );
                    }

                    return SingleChildScrollView(
                      child: Column(
                        children:
                            filtered.entries.map((entry) {
                              return BeltGroup(
                                beltName: entry.key,
                                students: entry.value,
                                selectedStudentIds: _selectedStudentIds,
                                onSeeMore: () {},
                                onViewStudentDetails: _showStudentDetails,
                                onSelectionChanged: (selectedIdsFromGroup) {
                                  setState(() {
                                    _selectedStudentIds
                                      ..removeWhere(
                                        (id) => entry.value.any(
                                          (student) => student.id == id,
                                        ),
                                      )
                                      ..addAll(selectedIdsFromGroup);
                                  });
                                },
                              );
                            }).toList(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: const NotesButton(),
    );
  }
}

class StudentCard extends StatelessWidget {
  const StudentCard({
    super.key,
    required this.name,
    required this.image,
    required this.isSelected,
    required this.onTap,
    required this.onViewDetails,
  });

  final String name;
  final String image;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70,
      height: 130,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(40),
            onTap: onViewDetails,
            child: Container(
              width: 70,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image:
                      image.isNotEmpty
                          ? NetworkImage(image)
                          : const AssetImage('assets/image/Logo.png')
                              as ImageProvider,
                  fit: BoxFit.cover,
                ),
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: onViewDetails,
            child: Text(
              name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2),
          Align(
            alignment: Alignment.center,
            child: SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: isSelected,
                onChanged: (value) => onTap(),
                activeColor: Colors.blue,
                side: BorderSide(width: 2, color: Colors.grey[400]!),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BeltGroup extends StatelessWidget {
  const BeltGroup({
    super.key,
    required this.beltName,
    required this.students,
    required this.selectedStudentIds,
    required this.onSeeMore,
    required this.onViewStudentDetails,
    required this.onSelectionChanged,
  });

  final String beltName;
  final List<AdminStudent> students;
  final Set<String> selectedStudentIds;
  final VoidCallback onSeeMore;
  final ValueChanged<AdminStudent> onViewStudentDetails;
  final ValueChanged<Set<String>> onSelectionChanged;

  void _toggleSelection(AdminStudent student) {
    final newSelection = Set<String>.from(
      selectedStudentIds.where(
        (id) => students.any((currentStudent) => currentStudent.id == id),
      ),
    );

    if (newSelection.contains(student.id)) {
      newSelection.remove(student.id);
    } else {
      newSelection.add(student.id);
    }

    onSelectionChanged(newSelection);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              beltName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward, size: 26),
              onPressed: onSeeMore,
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              final isSelected = selectedStudentIds.contains(student.id);

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: StudentCard(
                  name: student.name,
                  image: student.imageUrl,
                  isSelected: isSelected,
                  onTap: () => _toggleSelection(student),
                  onViewDetails: () => onViewStudentDetails(student),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.black87),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.black54,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9FB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8E8EE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: Colors.black87),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
