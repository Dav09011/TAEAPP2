class Branch {
  const Branch({
    required this.id,
    required this.name,
    required this.ownerUserId,
    required this.classesCount,
    required this.participantsCount,
  });

  final String id;
  final String name;
  final String ownerUserId;
  final int classesCount;
  final int participantsCount;
}
