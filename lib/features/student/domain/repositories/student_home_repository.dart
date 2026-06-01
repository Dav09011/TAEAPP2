import 'package:tae_app/features/student/domain/entities/student_group_data.dart';

abstract class StudentHomeRepository {
  Stream<List<StudentGroupData>> watchCurrentStudentGroups();

  Stream<StudentGroupDetails> watchGroupDetails(StudentGroupData group);

  Future<void> removeGroupFromCurrentStudentProfile(String groupId);

  Future<bool> leaveGroup(String groupId);
}
