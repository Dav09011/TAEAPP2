import 'package:flutter_test/flutter_test.dart';
import 'package:tae_app/core/errors/app_exception.dart';
import 'package:tae_app/features/student/domain/entities/student_belt_option.dart';
import 'package:tae_app/features/student/domain/entities/student_profile.dart';
import 'package:tae_app/features/student/domain/entities/update_student_profile_request.dart';
import 'package:tae_app/features/student/domain/repositories/student_profile_repository.dart';
import 'package:tae_app/features/student/presentation/controllers/student_profile_controller.dart';

void main() {
  test(
    'delegates profile operations and preserves editable fallbacks',
    () async {
      final profile = StudentProfile(
        userId: 'student-1',
        authEmail: 'auth@example.com',
        data: const {
          'nombre': 'Ana',
          'ap': 'Lopez',
          'am': '',
          'telefono': '',
          'correo': '',
          'tipo': 'alumno',
        },
      );
      final repository = _FakeStudentProfileRepository(profile: profile);
      final controller = StudentProfileController(repository: repository);

      final streamedProfile = await controller.watchCurrentProfile().first;
      final belts = await controller.loadAvailableBelts(profile);
      final result = await controller.updateProfile(
        const UpdateStudentProfileRequest(
          firstName: 'Ana',
          lastName: 'Lopez',
          middleName: '',
          phone: '555',
          personalBelt: 'Verde',
          personalBeltColorValue: 0xFF2E8B57,
          email: 'ana@example.com',
        ),
      );
      await controller.signOut();

      expect(controller.currentUserId, 'student-1');
      expect(streamedProfile.fullName, 'Ana Lopez');
      expect(streamedProfile.email, 'auth@example.com');
      expect(streamedProfile.editableEmail, 'auth@example.com');
      expect(streamedProfile.editablePhone, '');
      expect(belts.single.label, 'Verde');
      expect(repository.updatedRequest?.email, 'ana@example.com');
      expect(result.emailVerificationSent, isTrue);
      expect(repository.signedOut, isTrue);
      expect(
        controller.errorMessage(const AppException('Perfil roto')),
        'Perfil roto',
      );
    },
  );
}

class _FakeStudentProfileRepository implements StudentProfileRepository {
  _FakeStudentProfileRepository({required this.profile});

  final StudentProfile profile;
  UpdateStudentProfileRequest? updatedRequest;
  bool signedOut = false;

  @override
  String? get currentUserId => profile.userId;

  @override
  Stream<StudentProfile> watchCurrentProfile() {
    return Stream.value(profile);
  }

  @override
  Future<List<StudentBeltOption>> loadAvailableBelts(
    StudentProfile profile,
  ) async {
    return const [StudentBeltOption(label: 'Verde', colorValue: 0xFF2E8B57)];
  }

  @override
  Future<StudentProfileUpdateResult> updateProfile(
    UpdateStudentProfileRequest request,
  ) async {
    updatedRequest = request;
    return const StudentProfileUpdateResult(emailVerificationSent: true);
  }

  @override
  Future<void> signOut() async {
    signedOut = true;
  }
}
