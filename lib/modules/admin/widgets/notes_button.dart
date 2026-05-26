import 'package:flutter/material.dart';
import 'package:tae_app/features/admin/data/repositories/firebase_notes_repository.dart';
import 'package:tae_app/features/admin/domain/entities/admin_notes_student.dart';
import 'package:tae_app/features/admin/presentation/controllers/notes_controller.dart';
import 'package:tae_app/modules/admin/pages/notes/notes_students.dart';

class NotesButton extends StatefulWidget {
  const NotesButton({super.key});

  @override
  State<NotesButton> createState() => _NotesButtonState();
}

class _NotesButtonState extends State<NotesButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  Future<void> _openCreateNoteDialog() async {
    _toggleMenu();

    final noteController = TextEditingController();
    final notesController = NotesController();
    final notesRepository = FirebaseNotesRepository();
    AdminNotesStudent? selectedStudent;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Nueva nota'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FutureBuilder<List<AdminNotesStudent>>(
                  future: notesRepository.loadStudentsWithNotes(),
                  builder: (context, snapshot) {
                    final students = snapshot.data ?? const <AdminNotesStudent>[];

                    return Autocomplete<AdminNotesStudent>(
                      displayStringForOption: (option) => option.fullName,
                      optionsBuilder: (TextEditingValue value) {
                        final query = value.text.trim().toLowerCase();
                        if (query.isEmpty) {
                          return const Iterable<AdminNotesStudent>.empty();
                        }
                        return students.where((student) {
                          return student.fullName.toLowerCase().contains(query);
                        });
                      },
                      onSelected: (student) {
                        selectedStudent = student;
                      },
                      fieldViewBuilder: (
                        context,
                        textEditingController,
                        focusNode,
                        onFieldSubmitted,
                      ) {
                        return TextField(
                          controller: textEditingController,
                          focusNode: focusNode,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: 'Nombre del alumno',
                            hintText: 'Ej. Julio Hernandez',
                            suffixIcon:
                                snapshot.connectionState == ConnectionState.waiting
                                    ? const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    )
                                    : null,
                          ),
                          onChanged: (_) {
                            selectedStudent = null;
                          },
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: noteController,
                  minLines: 4,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Contenido de la nota',
                    hintText: 'Escribe aqui el contenido de la nota',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                final noteContent = noteController.text.trim();

                if (selectedStudent == null || noteContent.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Selecciona un alumno y escribe la nota.'),
                    ),
                  );
                  return;
                }

                try {
                  await notesController.createEntry(
                    student: selectedStudent!,
                    content: noteContent,
                    isPinned: false,
                  );
                  if (context.mounted) {
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Nota creada para ${selectedStudent!.fullName}.'),
                      ),
                    );
                  }
                } catch (error) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$error')),
                    );
                  }
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    noteController.dispose();
    notesController.dispose();
  }

  void _openNotesHome() {
    _toggleMenu();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotasAlumnoScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.bottomRight,
        clipBehavior: Clip.none,
        children: [
          _buildSecondaryAction(
            icon: Icons.add,
            tooltip: 'Crear nota',
            offset: const Offset(78, 18),
            onPressed: _openCreateNoteDialog,
          ),
          _buildSecondaryAction(
            icon: Icons.remove_red_eye_outlined,
            tooltip: 'Ver notas',
            offset: const Offset(18, 78),
            onPressed: _openNotesHome,
          ),
          FloatingActionButton(
            heroTag: null,
            onPressed: _toggleMenu,
            child: AnimatedRotation(
              turns: _isExpanded ? 0.125 : 0,
              duration: const Duration(milliseconds: 220),
              child: const Icon(Icons.edit),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryAction({
    required IconData icon,
    required String tooltip,
    required Offset offset,
    required VoidCallback onPressed,
  }) {
    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        final progress = _expandAnimation.value;

        return Positioned(
          right: offset.dx * progress,
          bottom: offset.dy * progress,
          child: IgnorePointer(
            ignoring: !_isExpanded,
            child: Opacity(
              opacity: progress.clamp(0, 1),
              child: Transform.scale(
                scale: 0.75 + (0.25 * progress),
                child: child,
              ),
            ),
          ),
        );
      },
      child: FloatingActionButton.small(
        heroTag: null,
        tooltip: tooltip,
        onPressed: onPressed,
        child: Icon(icon),
      ),
    );
  }
}
