class CreateActivityRequest {
  const CreateActivityRequest({
    required this.groupId,
    required this.beltName,
    required this.activityName,
    required this.exercises,
  });

  final String groupId;
  final String beltName;
  final String activityName;
  final List<String> exercises;
}
