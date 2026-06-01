class AdminGroupedStudent {
  const AdminGroupedStudent({
    required this.id,
    required this.name,
    required this.group,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String group;
  final String? avatarUrl;
}
