import 'package:flutter/material.dart';
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

    final studentController = TextEditingController();
    final noteController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Nueva nota'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: studentController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del alumno',
                    hintText: 'Ej. Julio Hernandez',
                  ),
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
              onPressed: () {
                final studentName = studentController.text.trim();
                final noteContent = noteController.text.trim();

                if (studentName.isEmpty || noteContent.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Completa el nombre del alumno y la nota.'),
                    ),
                  );
                  return;
                }

                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Nota preparada para $studentName.'),
                  ),
                );
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    studentController.dispose();
    noteController.dispose();
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
