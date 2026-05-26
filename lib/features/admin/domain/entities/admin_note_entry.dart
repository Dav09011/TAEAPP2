class AdminNoteEntry {
  const AdminNoteEntry({
    required this.id,
    required this.studentId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    required this.isPinned,
    required this.isActive,
    this.contextGroupId,
    this.contextGroupName,
    this.contextBranchId,
    this.contextBranchName,
  });

  final String id;
  final String studentId;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPinned;
  final bool isActive;
  final String? contextGroupId;
  final String? contextGroupName;
  final String? contextBranchId;
  final String? contextBranchName;

  AdminNoteEntry copyWith({
    String? id,
    String? studentId,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPinned,
    bool? isActive,
    String? contextGroupId,
    String? contextGroupName,
    String? contextBranchId,
    String? contextBranchName,
  }) {
    return AdminNoteEntry(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
      isActive: isActive ?? this.isActive,
      contextGroupId: contextGroupId ?? this.contextGroupId,
      contextGroupName: contextGroupName ?? this.contextGroupName,
      contextBranchId: contextBranchId ?? this.contextBranchId,
      contextBranchName: contextBranchName ?? this.contextBranchName,
    );
  }
}
