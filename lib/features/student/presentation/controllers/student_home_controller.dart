import 'package:tae_app/core/errors/app_exception.dart';
import 'package:tae_app/features/student/data/repositories/firebase_student_home_repository.dart';
import 'package:tae_app/features/student/domain/entities/student_group_data.dart';
import 'package:tae_app/features/student/domain/repositories/student_home_repository.dart';

class StudentHomeController {
  StudentHomeController({StudentHomeRepository? repository})
    : _repository = repository ?? FirebaseStudentHomeRepository();

  final StudentHomeRepository _repository;

  Stream<List<StudentGroupData>> watchCurrentStudentGroups() {
    return _repository.watchCurrentStudentGroups();
  }

  Stream<StudentGroupDetails> watchGroupDetails(StudentGroupData group) {
    return _repository.watchGroupDetails(group);
  }

  Future<void> removeMissingGroup(String groupId) {
    return _repository.removeGroupFromCurrentStudentProfile(groupId);
  }

  Future<bool> leaveGroup(String groupId) {
    return _repository.leaveGroup(groupId);
  }

  String errorMessage(Object? error) {
    if (error is AppException) {
      return error.message;
    }
    return 'No se pudo cargar tu grupo. Si ya escaneaste tu QR, intenta entrar de nuevo.';
  }

  String leaveGroupMessage(bool removedEnrollment) {
    return removedEnrollment
        ? 'Tu grupo ya no aparece en tu pantalla.'
        : 'Se quito el grupo de tu pantalla.';
  }
}
