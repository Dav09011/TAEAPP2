import 'package:tae_app/features/admin/domain/entities/admin_note_entry.dart';

class AdminNotesStudent {
  const AdminNotesStudent({
    required this.id,
    required this.name,
    required this.fullName,
    required this.branchIds,
    required this.branchNames,
    required this.groupIds,
    required this.groupNames,
    required this.entries,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String fullName;
  final List<String> branchIds;
  final List<String> branchNames;
  final List<String> groupIds;
  final List<String> groupNames;
  final List<AdminNoteEntry> entries;
  final bool isActive;

  String get primaryBranchName => branchNames.isEmpty ? 'Sin sucursal' : branchNames.first;

  String get primaryGroupName => groupNames.isEmpty ? 'Sin grupo' : groupNames.first;

  AdminNotesStudent copyWith({
    String? id,
    String? name,
    String? fullName,
    List<String>? branchIds,
    List<String>? branchNames,
    List<String>? groupIds,
    List<String>? groupNames,
    List<AdminNoteEntry>? entries,
    bool? isActive,
  }) {
    return AdminNotesStudent(
      id: id ?? this.id,
      name: name ?? this.name,
      fullName: fullName ?? this.fullName,
      branchIds: branchIds ?? this.branchIds,
      branchNames: branchNames ?? this.branchNames,
      groupIds: groupIds ?? this.groupIds,
      groupNames: groupNames ?? this.groupNames,
      entries: entries ?? this.entries,
      isActive: isActive ?? this.isActive,
    );
  }
}
