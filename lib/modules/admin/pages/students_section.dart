import 'package:flutter/material.dart';
import 'package:tae_app/features/admin/domain/entities/admin_student.dart';
import 'package:tae_app/features/admin/presentation/controllers/students_controller.dart';
import 'package:tae_app/modules/admin/widgets/notes_button.dart';
import 'package:tae_app/modules/admin/widgets/search_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  Future<void> _deleteSelectedStudents() async {
    final groupId = widget.groupDocId ?? widget.groupName;
    if (groupId == null || groupId.isEmpty || _selectedStudentIds.isEmpty) {
      return;
    }

    try {
      // --- LÓGICA DE LIMPIEZA PROFUNDA DIRECTO EN LA PANTALLA ---
      final db = FirebaseFirestore.instance;
      
      // 1. Obtenemos la sucursal para actualizar su contador
      final groupSnap = await db.collection('grupos').doc(groupId).get();
      final idSucursal = groupSnap.data()?['id_sucursal'] as String?;

      int alumnosBorradosReales = 0;

      // 2. Iteramos sobre los alumnos seleccionados
      for (final studentDocId in _selectedStudentIds) {
        final studentRef = db
            .collection('grupos')
            .doc(groupId)
            .collection('alumnos')
            .doc(studentDocId);

        final studentSnap = await studentRef.get();
        
        if (studentSnap.exists) {
          final uidDelAlumno = studentSnap.data()?['uid'] as String?;

          // A. Borramos al alumno de la clase
          await studentRef.delete();
          alumnosBorradosReales++;

          // B. Le quitamos el grupo (y el gafete VIP) de su perfil personal
          if (uidDelAlumno != null) {
            final userRef = db.collection('usuarios').doc(uidDelAlumno);
            final userSnap = await userRef.get();
            
            if (userSnap.exists && userSnap.data()?['grupos'] != null) {
              final List<dynamic> gruposActuales = userSnap.data()!['grupos'];
              final gruposLimpios = gruposActuales
                  .where((g) => g['groupId'] != groupId)
                  .toList();
              
              await userRef.update({'grupos': gruposLimpios});
            }
          }
        }
      }

      // 3. Actualizamos los contadores de Firebase
      if (alumnosBorradosReales > 0) {
        await db.collection('grupos').doc(groupId).update({
          'total_alumnos': FieldValue.increment(-alumnosBorradosReales),
        });

        if (idSucursal != null && idSucursal.isNotEmpty) {
          await db.collection('sucursales').doc(idSucursal).update({
            'participants': FieldValue.increment(-alumnosBorradosReales),
          });
        }
      }
      // ----------------------------------------------------------

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
                                      : const AssetImage('assets/image/Logo.png')
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
                              style: const TextStyle(fontWeight: FontWeight.bold),
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
        titleTextStyle: const TextStyle(
          fontSize: 25,
          color: Colors.white,
        ),
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
                              : () => _showDeleteConfirmationDialog(allStudents),
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
                        child: Text('No hay alumnos registrados en este grupo.'),
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
                                onSelectionChanged: (selectedIdsFromGroup) {
                                  setState(() {
                                    _selectedStudentIds
                                      ..removeWhere(
                                        (id) =>
                                            entry.value.any(
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
  });

  final String name;
  final String image;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70,
      height: 130,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
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
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
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
                side: BorderSide(
                  width: 2,
                  color: Colors.grey[400]!,
                ),
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
    required this.onSelectionChanged,
  });

  final String beltName;
  final List<AdminStudent> students;
  final Set<String> selectedStudentIds;
  final VoidCallback onSeeMore;
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
