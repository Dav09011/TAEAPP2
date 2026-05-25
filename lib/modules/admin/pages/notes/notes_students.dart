import 'package:flutter/material.dart';

class NotasAlumnoScreen extends StatefulWidget {
  const NotasAlumnoScreen({super.key});

  @override
  State<NotasAlumnoScreen> createState() => _NotasAlumnoScreenState();
}

class _NotasAlumnoScreenState extends State<NotasAlumnoScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  late final List<_StudentNotes> _students = [
    _StudentNotes(
      id: 'stu_1',
      name: 'Samuel de Luque',
      branchName: 'Sucursal Centro',
      groupName: 'Cintas Blancas',
      accentColor: const Color(0xFF5B7CFA),
      entries: [
        _NoteEntry(
          id: 'n_1',
          createdAt: DateTime(2025, 3, 9),
          content: 'Es de los principales alumnos que muestra interes.',
        ),
        _NoteEntry(
          id: 'n_2',
          createdAt: DateTime(2025, 3, 14),
          content: 'Responde muy bien al trabajo tecnico en pareja.',
        ),
      ],
    ),
    _StudentNotes(
      id: 'stu_2',
      name: 'Alex Tovar',
      branchName: 'Sucursal Norte',
      groupName: 'Cintas Amarillas',
      accentColor: const Color(0xFFEF8C4A),
      entries: [
        _NoteEntry(
          id: 'n_3',
          createdAt: DateTime(2025, 3, 1),
          content: 'Conviene reforzar equilibrio en desplazamientos.',
        ),
      ],
    ),
    _StudentNotes(
      id: 'stu_3',
      name: 'Julio Cortes',
      branchName: 'Sucursal Centro',
      groupName: 'Cintas Verdes',
      accentColor: const Color(0xFF62B36F),
      isExpanded: true,
      entries: [
        _NoteEntry(
          id: 'n_4',
          createdAt: DateTime(2025, 3, 9),
          content: 'Es de los principales alumnos que muestra interes.',
        ),
        _NoteEntry(
          id: 'n_5',
          createdAt: DateTime(2025, 3, 1),
          content: 'Poner mas atencion en las tecnicas que usa.',
        ),
      ],
    ),
    _StudentNotes(
      id: 'stu_4',
      name: 'Camila Cabello',
      branchName: 'Sucursal Sur',
      groupName: 'Cintas Avanzadas',
      accentColor: const Color(0xFFE47DA4),
      entries: [
        _NoteEntry(
          id: 'n_6',
          createdAt: DateTime(2025, 2, 26),
          content: 'Puede apoyar en demostraciones por su buena memoria.',
        ),
        _NoteEntry(
          id: 'n_7',
          createdAt: DateTime(2025, 3, 12),
          content: 'Buena energia en clase, cuidar ritmo al corregir postura.',
        ),
        _NoteEntry(
          id: 'n_8',
          createdAt: DateTime(2025, 3, 18),
          content: 'Le beneficia recibir objetivos puntuales por semana.',
        ),
      ],
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_StudentNotes> get _filteredStudents {
    if (_searchQuery.isEmpty) {
      return _students;
    }

    return _students.where((student) {
      final query = _searchQuery.toLowerCase();
      return student.name.toLowerCase().contains(query) ||
          student.branchName.toLowerCase().contains(query) ||
          student.groupName.toLowerCase().contains(query);
    }).toList();
  }

  int get _totalEntries {
    return _students.fold<int>(
      0,
      (sum, student) => sum + student.entries.length,
    );
  }

  int get _activeBranches {
    return _students.map((student) => student.branchName).toSet().length;
  }

  @override
  Widget build(BuildContext context) {
    final filteredStudents = _filteredStudents;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF7F8FC),
        foregroundColor: Colors.black,
        title: const Text(
          'Notas',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Text(
                    'Alumnos inscritos',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF20222A),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${filteredStudents.length} alumnos',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6D7385),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (filteredStudents.isEmpty)
                _buildEmptyState()
              else
                ...filteredStudents.map(_buildStudentCard),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4E7F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  'NOTAS',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                    color: Color(0xFF20222A),
                  ),
                ),
              ),
              Icon(
                Icons.edit_note_rounded,
                color: Color(0xFF2E3F8F),
                size: 30,
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Consulta, edita y crea entradas para alumnos de todas tus sucursales.',
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Color(0xFF6D7385),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4FA),
              borderRadius: BorderRadius.circular(18),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim();
                });
              },
              decoration: const InputDecoration(
                hintText: 'Buscar alumno, grupo o sucursal',
                prefixIcon: Icon(Icons.search_rounded),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 18),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeaderMetric(
                  label: 'Entradas',
                  value: '$_totalEntries',
                  icon: Icons.sticky_note_2_outlined,
                  color: const Color(0xFF2E3F8F),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeaderMetric(
                  label: 'Sucursales',
                  value: '$_activeBranches',
                  icon: Icons.storefront_outlined,
                  color: const Color(0xFF1B8A5A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(_StudentNotes student) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFBFE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDADFF0)),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              setState(() {
                student.isExpanded = !student.isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: student.accentColor.withOpacity(0.18),
                    child: Text(
                      _initialsFrom(student.name),
                      style: TextStyle(
                        color: student.accentColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF20222A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${student.entries.length} notas  .  ${student.groupName}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6D7385),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          student.branchName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: student.accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: student.isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 28,
                      color: Color(0xFF20222A),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildExpandedContent(student),
            crossFadeState:
                student.isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent(_StudentNotes student) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          const Divider(height: 1, color: Color(0xFFDADFF0)),
          const SizedBox(height: 14),
          Row(
            children: [
              const Text(
                'Entradas recientes',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF20222A),
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _openEntryDialog(student: student),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2E3F8F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nueva entrada'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...student.entries.map(
            (entry) => _buildEntryCard(
              student: student,
              entry: entry,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryCard({
    required _StudentNotes student,
    required _NoteEntry entry,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 14, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E8F2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fecha: ${_formatDate(entry.createdAt)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF20222A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  entry.content,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: Color(0xFF343846),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            children: [
              IconButton(
                tooltip: 'Editar entrada',
                onPressed: () => _openEntryDialog(student: student, entry: entry),
                icon: const Icon(
                  Icons.edit_outlined,
                  color: Color(0xFF2E3F8F),
                ),
              ),
              IconButton(
                tooltip: 'Eliminar entrada',
                onPressed: () => _confirmDeleteEntry(student: student, entry: entry),
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFB63B3B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4E7F0)),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 38,
            color: Color(0xFF6D7385),
          ),
          SizedBox(height: 12),
          Text(
            'No encontramos alumnos con ese criterio.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF20222A),
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Prueba con otro nombre, grupo o sucursal.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF6D7385),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openEntryDialog({
    required _StudentNotes student,
    _NoteEntry? entry,
  }) async {
    final noteController = TextEditingController(text: entry?.content ?? '');

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            entry == null ? 'Nueva entrada' : 'Editar entrada',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                student.name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                '${student.branchName}  .  ${student.groupName}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6D7385),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                minLines: 4,
                maxLines: 7,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Contenido de la nota',
                  hintText: 'Escribe observaciones, avances o pendientes',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final content = noteController.text.trim();
                if (content.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Escribe el contenido de la nota.'),
                    ),
                  );
                  return;
                }

                setState(() {
                  if (entry == null) {
                    student.entries.insert(
                      0,
                      _NoteEntry(
                        id: 'n_${DateTime.now().millisecondsSinceEpoch}',
                        createdAt: DateTime.now(),
                        content: content,
                      ),
                    );
                    student.isExpanded = true;
                  } else {
                    entry.content = content;
                  }
                });

                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      entry == null
                          ? 'Entrada creada para ${student.name}.'
                          : 'Entrada actualizada.',
                    ),
                  ),
                );
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    noteController.dispose();
  }

  Future<void> _confirmDeleteEntry({
    required _StudentNotes student,
    required _NoteEntry entry,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar entrada'),
          content: Text(
            'Se eliminara esta nota de ${student.name}. Esta accion no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB63B3B),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      student.entries.removeWhere((item) => item.id == entry.id);
    });

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Entrada eliminada.')),
    );
  }

  String _initialsFrom(String name) {
    final parts = name.split(' ').where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) {
      return 'A';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }
}

class _HeaderMetric extends StatelessWidget {
  const _HeaderMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF20222A),
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6D7385),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StudentNotes {
  _StudentNotes({
    required this.id,
    required this.name,
    required this.branchName,
    required this.groupName,
    required this.accentColor,
    required this.entries,
    this.isExpanded = false,
  });

  final String id;
  final String name;
  final String branchName;
  final String groupName;
  final Color accentColor;
  final List<_NoteEntry> entries;
  bool isExpanded;
}

class _NoteEntry {
  _NoteEntry({
    required this.id,
    required this.createdAt,
    required this.content,
  });

  final String id;
  final DateTime createdAt;
  String content;
}
