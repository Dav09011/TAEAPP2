import 'package:tae_app/features/admin/domain/entities/admin_profile.dart';
import 'package:tae_app/features/admin/domain/entities/update_admin_profile_request.dart';

abstract class ProfileRepository {
  String? get currentUserId;

  Stream<AdminProfile> watchCurrentProfile();

  Future<AdminProfile> getCurrentProfile();

  Future<void> updateProfile(UpdateAdminProfileRequest request);

  Future<void> requestEmailChange({
    required String userId,
    required String newEmail,
  });

  Future<void> signOut();
}
