import 'package:tae_app/core/errors/app_exception.dart';
import 'package:tae_app/features/student/data/repositories/firebase_student_profile_repository.dart';
import 'package:tae_app/features/student/domain/entities/student_belt_option.dart';
import 'package:tae_app/features/student/domain/entities/student_profile.dart';
import 'package:tae_app/features/student/domain/entities/update_student_profile_request.dart';
import 'package:tae_app/features/student/domain/repositories/student_profile_repository.dart';

class StudentProfileController {
  StudentProfileController({StudentProfileRepository? repository})
    : _repository = repository ?? FirebaseStudentProfileRepository();

  final StudentProfileRepository _repository;

  String? get currentUserId => _repository.currentUserId;

  Stream<StudentProfile> watchCurrentProfile() {
    return _repository.watchCurrentProfile();
  }

  Future<List<StudentBeltOption>> loadAvailableBelts(StudentProfile profile) {
    return _repository.loadAvailableBelts(profile);
  }

  Future<StudentProfileUpdateResult> updateProfile(
    UpdateStudentProfileRequest request,
  ) {
    return _repository.updateProfile(request);
  }

  Future<void> signOut() {
    return _repository.signOut();
  }

  String errorMessage(Object? error) {
    if (error is AppException) {
      return error.message;
    }
    return 'Ocurrio un error inesperado.';
  }
}
