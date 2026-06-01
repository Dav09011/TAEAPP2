import 'package:tae_app/features/student/domain/entities/student_group_join_result.dart';

abstract class StudentGroupJoinRepository {
  Future<StudentGroupJoinResult> joinByAccessCode(String accessCode);

  Future<StudentGroupJoinResult> joinByGroupId({
    required String groupId,
    required String assignedRole,
    String? fallbackGroupName,
  });
}
