import 'package:tae_app/features/admin/domain/entities/activity_item.dart';
import 'package:tae_app/features/admin/domain/entities/belt_section.dart';
import 'package:tae_app/features/admin/domain/entities/create_activity_request.dart';

abstract class ActivityRepository {
  Stream<List<BeltSection>> watchBeltSections(String groupId);

  Stream<List<ActivityItem>> watchActivitiesBySection({
    required String groupId,
    required String beltName,
  });

  Future<void> createActivity(CreateActivityRequest request);

  Future<void> createBeltSection({
    required String groupId,
    required String beltName,
  });

  Future<void> renameActivity({
    required String groupId,
    required String activityId,
    required String newName,
  });

  Future<void> deleteActivity({
    required String groupId,
    required String activityId,
  });

  Future<void> renameBeltSection({
    required String groupId,
    required String oldName,
    required String newName,
  });

  Future<void> addExercise({
    required String groupId,
    required String activityId,
    required String exerciseName,
  });

  Future<void> removeExercise({
    required String groupId,
    required String activityId,
    required String exerciseName,
  });

  Future<void> renameExercise({
    required String groupId,
    required String activityId,
    required String oldName,
    required String newName,
  });
}
