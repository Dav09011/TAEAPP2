class ActivityItem {
  const ActivityItem({
    required this.id,
    required this.name,
    required this.exercises,
    required this.beltSection,
    this.colorValue,
  });

  final String id;
  final String name;
  final List<String> exercises;
  final String beltSection;
  final int? colorValue;
}
