class CreateGroupRequest {
  const CreateGroupRequest({
    required this.branchId,
    required this.name,
    required this.beltType,
    required this.schedule,
  });

  final String branchId;
  final String name;
  final String beltType;
  final String schedule;
}
