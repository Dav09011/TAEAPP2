import 'package:tae_app/core/errors/app_exception.dart';
import 'package:tae_app/features/student/data/repositories/firebase_student_calendar_repository.dart';
import 'package:tae_app/features/student/domain/entities/student_branch_context.dart';
import 'package:tae_app/features/student/domain/repositories/student_calendar_repository.dart';

class StudentCalendarController {
  StudentCalendarController({StudentCalendarRepository? repository})
    : _repository = repository ?? FirebaseStudentCalendarRepository();

  final StudentCalendarRepository _repository;

  Stream<List<StudentBranchContext>> watchBranchesForCurrentStudent() {
    return _repository.watchBranchesForCurrentStudent();
  }

  String errorMessage(Object? error) {
    if (error is AppException) {
      return error.message;
    }
    return 'No pudimos cargar tus sucursales.';
  }
}
