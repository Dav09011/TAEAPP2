import 'package:tae_app/features/admin/domain/entities/admin_student.dart';

abstract class StudentRepository {
  Stream<List<AdminStudent>> watchStudentsByGroup(String groupId);

  Future<AdminStudent> getStudentDetails(String userId);

  Future<void> deleteStudents({
    required String groupId,
    required List<String> studentIds,
  });
}
