import 'package:flutter/material.dart';
import 'package:tae_app/features/admin/domain/entities/admin_note_entry.dart';
import 'package:tae_app/features/admin/domain/entities/admin_notes_student.dart';
import 'package:tae_app/features/admin/presentation/controllers/notes_controller.dart';

class NotasAlumnoScreen extends StatefulWidget {
  const NotasAlumnoScreen({super.key});

  @override
  State<NotasAlumnoScreen> createState() => _NotasAlumnoScreenState();
}

class _NotasAlumnoScreenState extends State<NotasAlumnoScreen> {
  final NotesController _controller = NotesController();
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _expandedStudentIds = <String>{};
  String _searchQuery = '';
  String _selectedBranch = 'Todas';
  String _selectedGroup = 'Todos';
  _DeletedEntrySnapshot? _pendingDeletion;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleControllerChanged);
    _controller.load();
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleControllerChanged)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  List<String> get _branchFilters {
    final values =
        _controller.students
            .expand((student) => student.branchNames)
            .where((value) => value.trim().isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return ['Todas', ...values];
  }

  List<String> get _groupFilters {
    final values =
        _controller.students
            .expand((student) => student.groupNames)
            .where((value) => value.trim().isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return ['Todos', ...values];
  }

  List<AdminNotesStudent> get _filteredStudents {
    return _controller.students.where((student) {
      final query = _searchQuery.toLowerCase();
      final matchesBranch =
          _selectedBranch == 'Todas' ||
          student.branchNames.contains(_selectedBranch);
      final matchesGroup =
          _selectedGroup == 'Todos' ||
          student.groupNames.contains(_selectedGroup);
      final matchesSearch =
          query.isEmpty ||
          student.fullName.toLowerCase().contains(query) ||
          student.branchNames.any(
            (name) => name.toLowerCase().contains(query),
          ) ||
          student.groupNames.any(
            (name) => name.toLowerCase().contains(query),
          ) ||
          student.entries.any(
            (entry) => entry.content.toLowerCase().contains(query),
          );

      return matchesBranch && matchesGroup && matchesSearch;
    }).toList();
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
      ),
      body: SafeArea(
        child:
            _controller.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _controller.errorMessage != null
                ? _buildErrorState()
                : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderCard(),
                      const SizedBox(height: 16),
                      _buildFilterSection(),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          const Text(
                            'ALUMNOS',
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
      padding: const EdgeInsets.only(left: 20, right: 20, top: 15, bottom: 5),
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
              Icon(Icons.edit_note_rounded, color: Color(0xFF2E3F8F), size: 30),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Consulta, organiza y da seguimiento de observaciones.',
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Color(0xFF6D7385),
            ),
          ),
          const SizedBox(height: 10),
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
                hintText: 'Buscar alumno, grupo, sucursal o texto de nota',
                prefixIcon: Icon(Icons.search_rounded),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 18),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilterRow(
          title: 'Sucursal',
          values: _branchFilters,
          selectedValue: _selectedBranch,
          onSelected: (value) {
            setState(() {
              _selectedBranch = value;
            });
          },
        ),
        const SizedBox(height: 12),
        _buildFilterRow(
          title: 'Grupo',
          values: _groupFilters,
          selectedValue: _selectedGroup,
          onSelected: (value) {
            setState(() {
              _selectedGroup = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildFilterRow({
    required String title,
    required List<String> values,
    required String selectedValue,
    required ValueChanged<String> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF6D7385),
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children:
                values.map((value) {
                  final isSelected = value == selectedValue;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(value),
                      selected: isSelected,
                      onSelected: (_) => onSelected(value),
                      selectedColor: const Color(0xFF2E3F8F),
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color:
                            isSelected ? Colors.white : const Color(0xFF343846),
                        fontWeight: FontWeight.w600,
                      ),
                      side: BorderSide(
                        color:
                            isSelected
                                ? const Color(0xFF2E3F8F)
                                : const Color(0xFFDADFF0),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentCard(AdminNotesStudent student) {
    final sortedEntries = [...student.entries]..sort(_sortEntries);
    final isExpanded = _expandedStudentIds.contains(student.id);
    final lastUpdated =
        sortedEntries.isEmpty ? null : sortedEntries.first.updatedAt;

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
                if (isExpanded) {
                  _expandedStudentIds.remove(student.id);
                } else {
                  _expandedStudentIds.add(student.id);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: _colorForStudent(
                      student.id,
                    ).withValues(alpha: 0.18),
                    child: Text(
                      _initialsFrom(student.fullName),
                      style: TextStyle(
                        color: _colorForStudent(student.id),
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
                          student.fullName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF20222A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${student.entries.length} notas  .  ${student.primaryGroupName}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6D7385),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _joinLabels(student.branchNames),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _colorForStudent(student.id),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        lastUpdated == null
                            ? 'Sin notas'
                            : 'Ultima: ${_formatDate(lastUpdated)}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6D7385),
                        ),
                      ),
                      const SizedBox(height: 6),
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 220),
                        child: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 28,
                          color: Color(0xFF20222A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildExpandedContent(student, sortedEntries),
            crossFadeState:
                isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent(
    AdminNotesStudent student,
    List<AdminNoteEntry> sortedEntries,
  ) {
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
                onPressed:
                    _controller.isSaving
                        ? null
                        : () => _openEntryEditor(student: student),
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
          if (sortedEntries.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E8F2)),
              ),
              child: const Text(
                'Todavia no hay entradas para este alumno.',
                style: TextStyle(fontSize: 13, color: Color(0xFF6D7385)),
              ),
            )
          else
            ...sortedEntries.map(
              (entry) => _buildEntryCard(student: student, entry: entry),
            ),
        ],
      ),
    );
  }

  Widget _buildEntryCard({
    required AdminNotesStudent student,
    required AdminNoteEntry entry,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _openEntryDetails(student: student, entry: entry),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
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
                  Row(
                    children: [
                      Text(
                        _formatDate(entry.createdAt),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF20222A),
                        ),
                      ),
                      if (entry.isPinned) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3DD),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Importante',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFB67824),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    entry.content,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: Color(0xFF343846),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Mas opciones',
              onPressed:
                  () => _openEntryDetails(student: student, entry: entry),
              icon: const Icon(
                Icons.more_horiz_rounded,
                color: Color(0xFF6D7385),
              ),
            ),
          ],
        ),
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
          Icon(Icons.search_off_rounded, size: 38, color: Color(0xFF6D7385)),
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
            'Prueba con otro nombre, grupo, sucursal o palabra de la nota.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF6D7385)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 40,
              color: Color(0xFFB63B3B),
            ),
            const SizedBox(height: 12),
            Text(
              _controller.errorMessage ?? 'No pudimos cargar las notas.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _controller.reload,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openEntryDetails({
    required AdminNotesStudent student,
    required AdminNoteEntry entry,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDADFF0),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.fullName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF20222A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${student.primaryBranchName}  .  ${student.primaryGroupName}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6D7385),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (entry.isPinned)
                      const Icon(
                        Icons.push_pin_rounded,
                        color: Color(0xFFB67824),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FC),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fecha: ${_formatDate(entry.createdAt)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF20222A),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        entry.content,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: Color(0xFF343846),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _SheetAction(
                  icon: Icons.edit_outlined,
                  title: 'Editar nota',
                  subtitle: 'Abre el editor con el contenido actual',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _openEntryEditor(student: student, entry: entry);
                  },
                ),
                _SheetAction(
                  icon:
                      entry.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  title:
                      entry.isPinned
                          ? 'Quitar importancia'
                          : 'Marcar importante',
                  subtitle: 'Fija esta nota al inicio del historial del alumno',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _togglePinned(student: student, entry: entry);
                  },
                ),
                _SheetAction(
                  icon: Icons.delete_outline_rounded,
                  title: 'Eliminar nota',
                  subtitle: 'Pasa por una confirmacion y permite deshacer',
                  titleColor: const Color(0xFFB63B3B),
                  iconColor: const Color(0xFFB63B3B),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _confirmDeleteEntry(student: student, entry: entry);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openEntryEditor({
    required AdminNotesStudent student,
    AdminNoteEntry? entry,
  }) async {
    final noteController = TextEditingController(text: entry?.content ?? '');
    var isPinned = entry?.isPinned ?? false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetBuilderContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetBuilderContext).viewInsets.bottom,
              ),
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDADFF0),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        entry == null ? 'Nueva entrada' : 'Editar entrada',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF20222A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${student.fullName}  .  ${student.primaryBranchName}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6D7385),
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: noteController,
                        minLines: 5,
                        maxLines: 8,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          labelText: 'Contenido de la nota',
                          hintText:
                              'Escribe observaciones, avances o pendientes',
                          filled: true,
                          fillColor: const Color(0xFFF7F8FC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SwitchListTile.adaptive(
                        value: isPinned,
                        onChanged: (value) {
                          setSheetState(() {
                            isPinned = value;
                          });
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        tileColor: const Color(0xFFF7F8FC),
                        activeThumbColor: const Color(0xFFB67824),
                        title: const Text(
                          'Marcar como importante',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: const Text(
                          'Aparecera al inicio del historial del alumno',
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF2E3F8F),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed:
                              _controller.isSaving
                                  ? null
                                  : () async {
                                    final content = noteController.text.trim();
                                    if (content.isEmpty) {
                                      ScaffoldMessenger.of(
                                        sheetBuilderContext,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Escribe el contenido de la nota.',
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    try {
                                      if (entry == null) {
                                        await _controller.createEntry(
                                          student: student,
                                          content: content,
                                          isPinned: isPinned,
                                        );
                                      } else {
                                        await _controller.updateEntry(
                                          student: student,
                                          entry: entry,
                                          content: content,
                                          isPinned: isPinned,
                                        );
                                      }

                                      if (!mounted || !sheetContext.mounted) {
                                        return;
                                      }

                                      _expandedStudentIds.add(student.id);
                                      Navigator.of(sheetContext).pop();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            entry == null
                                                ? 'Entrada creada para ${student.name}.'
                                                : 'Entrada actualizada.',
                                          ),
                                        ),
                                      );
                                    } catch (error) {
                                      if (!mounted || !sheetContext.mounted) {
                                        return;
                                      }

                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text('$error')),
                                      );
                                    }
                                  },
                          child: Text(
                            entry == null
                                ? 'Guardar entrada'
                                : 'Guardar cambios',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    noteController.dispose();
  }

  Future<void> _confirmDeleteEntry({
    required AdminNotesStudent student,
    required AdminNoteEntry entry,
  }) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDADFF0),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Eliminar nota',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF20222A),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Esta accion quitara la nota de ${student.name}. Si fue un error, podras deshacerla enseguida.',
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Color(0xFF6D7385),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFB63B3B),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => Navigator.of(sheetContext).pop(true),
                    child: const Text('Confirmar eliminacion'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(sheetContext).pop(false),
                    child: const Text('Cancelar'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    _pendingDeletion = _DeletedEntrySnapshot(student: student, entry: entry);

    try {
      await _controller.deleteEntry(student: student, entry: entry);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
      return;
    }

    if (!mounted) {
      return;
    }

    final deletedEntryId = entry.id;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    final snackBarController = messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        content: Text('Nota eliminada de ${student.name}.'),
        action: SnackBarAction(label: 'Deshacer', onPressed: _undoDeletion),
      ),
    );

    snackBarController.closed.then((_) {
      if (!mounted) {
        return;
      }

      if (_pendingDeletion?.entry.id != deletedEntryId) {
        return;
      }

      setState(() {
        _pendingDeletion = null;
      });
    });
  }

  Future<void> _undoDeletion() async {
    final snapshot = _pendingDeletion;
    if (snapshot == null) {
      return;
    }

    try {
      await _controller.restoreEntry(
        student: snapshot.student,
        entry: snapshot.entry,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _expandedStudentIds.add(snapshot.student.id);
        _pendingDeletion = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  Future<void> _togglePinned({
    required AdminNotesStudent student,
    required AdminNoteEntry entry,
  }) async {
    try {
      await _controller.togglePinned(student: student, entry: entry);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            entry.isPinned
                ? 'La nota ya no esta fijada.'
                : 'Nota marcada como importante.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  int _sortEntries(AdminNoteEntry a, AdminNoteEntry b) {
    if (a.isPinned != b.isPinned) {
      return a.isPinned ? -1 : 1;
    }
    return b.updatedAt.compareTo(a.updatedAt);
  }

  Color _colorForStudent(String seed) {
    const palette = <Color>[
      Color(0xFF5B7CFA),
      Color(0xFFEF8C4A),
      Color(0xFF62B36F),
      Color(0xFFE47DA4),
      Color(0xFF00A6A6),
      Color(0xFF7C5DFA),
    ];
    return palette[seed.hashCode.abs() % palette.length];
  }

  String _joinLabels(List<String> values) {
    if (values.isEmpty) {
      return 'Sin sucursal';
    }
    if (values.length == 1) {
      return values.first;
    }
    return '${values.first} +${values.length - 1}';
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

class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.titleColor = const Color(0xFF20222A),
    this.iconColor = const Color(0xFF2E3F8F),
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color titleColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6D7385),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF6D7385)),
          ],
        ),
      ),
    );
  }
}

class _DeletedEntrySnapshot {
  const _DeletedEntrySnapshot({required this.student, required this.entry});

  final AdminNotesStudent student;
  final AdminNoteEntry entry;
}
