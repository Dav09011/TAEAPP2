class CreateGroupRequest {
  const CreateGroupRequest({
    required this.branchId,
    required this.branchName,
    required this.name,
    required this.beltType,
    required this.schedule,
  });

  final String branchId;
  final String branchName;
  final String name;
  final String beltType;
  final String schedule;
}
