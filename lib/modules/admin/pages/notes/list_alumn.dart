// main_screen.dart
import 'package:flutter/material.dart';
import 'package:tae_app/features/admin/domain/entities/admin_grouped_student.dart';
import 'package:tae_app/features/admin/presentation/controllers/notes_controller.dart';

class AlumnosPorGrupoScreen extends StatefulWidget {
  const AlumnosPorGrupoScreen({super.key});

  @override
  State<AlumnosPorGrupoScreen> createState() => _AlumnosPorGrupoScreenState();
}

class _AlumnosPorGrupoScreenState extends State<AlumnosPorGrupoScreen> {
  final NotesController _controller = NotesController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alumnos por Grupo')),
      body: StreamBuilder<List<AdminGroupedStudent>>(
        stream: _controller.watchLegacyStudents(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final groups = <String, List<AdminGroupedStudent>>{};
          for (final student in snapshot.data!) {
            groups.putIfAbsent(student.group, () => []).add(student);
          }

          return ListView.builder(
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups.keys.elementAt(index);
              final students = groups[group]!;
              return ExpansionTile(
                title: Text(group.isEmpty ? 'Sin grupo' : group),
                children:
                    students.map((student) {
                      final avatarUrl = student.avatarUrl;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage:
                              avatarUrl != null && avatarUrl.isNotEmpty
                                  ? NetworkImage(avatarUrl)
                                  : null,
                          child:
                              avatarUrl == null || avatarUrl.isEmpty
                                  ? const Icon(Icons.person)
                                  : null,
                        ),
                        title: Text(student.name),
                        onTap: () {
                          /*
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => NotasAlumnoScreen(alumno: alumno),
                            ),
                          );
                          */
                        },
                      );
                    }).toList(),
              );
            },
          );
        },
      ),
    );
  }
}
