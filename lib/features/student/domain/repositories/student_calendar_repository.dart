import 'package:tae_app/features/student/domain/entities/student_branch_context.dart';

abstract class StudentCalendarRepository {
  Stream<List<StudentBranchContext>> watchBranchesForCurrentStudent();
}
