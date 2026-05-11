class Branch {
  const Branch({
    required this.id,
    required this.name,
    required this.ownerUserId,
    required this.classesCount,
    required this.participantsCount,
    this.cardColorValue,
  });

  final String id;
  final String name;
  final String ownerUserId;
  final int classesCount;
  final int participantsCount;
  final int? cardColorValue;
}
