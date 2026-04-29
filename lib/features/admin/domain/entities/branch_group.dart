class BranchGroup {
  const BranchGroup({
    required this.id,
    required this.branchId,
    required this.name,
    required this.beltType,
    required this.schedule,
    required this.totalStudents,
  });

  final String id;
  final String branchId;
  final String name;
  final String beltType;
  final String schedule;
  final int totalStudents;
}
