class StudentBranchContext {
  const StudentBranchContext({
    required this.branchId,
    required this.branchName,
    required this.groupNames,
  });

  final String branchId;
  final String branchName;
  final List<String> groupNames;
}
