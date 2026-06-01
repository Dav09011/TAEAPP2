import 'package:tae_app/features/student/domain/entities/student_belt_option.dart';
import 'package:tae_app/features/student/domain/entities/student_profile.dart';
import 'package:tae_app/features/student/domain/entities/update_student_profile_request.dart';

abstract class StudentProfileRepository {
  String? get currentUserId;

  Stream<StudentProfile> watchCurrentProfile();

  Future<List<StudentBeltOption>> loadAvailableBelts(StudentProfile profile);

  Future<StudentProfileUpdateResult> updateProfile(
    UpdateStudentProfileRequest request,
  );

  Future<void> signOut();
}
