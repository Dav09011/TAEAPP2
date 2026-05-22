import 'package:flutter/foundation.dart';
import 'package:tae_app/features/admin/data/repositories/firebase_activity_repository.dart';
import 'package:tae_app/features/admin/domain/entities/activity_item.dart';
import 'package:tae_app/features/admin/domain/entities/belt_section.dart';
import 'package:tae_app/features/admin/domain/entities/create_activity_request.dart';
import 'package:tae_app/features/admin/domain/repositories/activity_repository.dart';

class ActivitiesController extends ChangeNotifier {
  ActivitiesController({ActivityRepository? activityRepository})
    : _activityRepository = activityRepository ?? FirebaseActivityRepository();

  final ActivityRepository _activityRepository;

  String _searchQuery = '';
  bool _isMutating = false;

  String get searchQuery => _searchQuery;
  bool get isMutating => _isMutating;

  Stream<List<BeltSection>> watchBeltSections(String groupId) {
    return _activityRepository.watchBeltSections(groupId);
  }

  Stream<List<ActivityItem>> watchActivitiesBySection({
    required String groupId,
    required String beltName,
  }) {
    return _activityRepository.watchActivitiesBySection(
      groupId: groupId,
      beltName: beltName,
    );
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  List<ActivityItem> filterActivities(List<ActivityItem> activities) {
    if (_searchQuery.isEmpty) return activities;
    final normalized = _searchQuery.toLowerCase();
    return activities.where((activity) {
      final nameMatch = activity.name.toLowerCase().contains(normalized);
      final exerciseMatch = activity.exercises.any(
        (exercise) => exercise.toLowerCase().contains(normalized),
      );
      return nameMatch || exerciseMatch;
    }).toList();
  }

  Future<void> createActivity(CreateActivityRequest request) {
    return _runMutation(() => _activityRepository.createActivity(request));
  }

  Future<void> createBeltSection({
    required String groupId,
    required String beltName,
  }) {
    return _runMutation(
      () => _activityRepository.createBeltSection(
        groupId: groupId,
        beltName: beltName,
      ),
    );
  }

  Future<void> renameActivity({
    required String groupId,
    required String activityId,
    required String newName,
  }) {
    return _runMutation(
      () => _activityRepository.renameActivity(
        groupId: groupId,
        activityId: activityId,
        newName: newName,
      ),
    );
  }

  Future<void> deleteActivity({
    required String groupId,
    required String activityId,
  }) {
    return _runMutation(
      () => _activityRepository.deleteActivity(
        groupId: groupId,
        activityId: activityId,
      ),
    );
  }

  Future<void> renameBeltSection({
    required String groupId,
    required String oldName,
    required String newName,
  }) {
    return _runMutation(
      () => _activityRepository.renameBeltSection(
        groupId: groupId,
        oldName: oldName,
        newName: newName,
      ),
    );
  }

  Future<void> deleteBeltSection({
    required String groupId,
    required String beltName,
  }) {
    return _runMutation(
      () => _activityRepository.deleteBeltSection(
        groupId: groupId,
        beltName: beltName,
      ),
    );
  }

  Future<void> updateBeltSectionColor({
    required String groupId,
    required String beltName,
    required int colorValue,
  }) {
    return _runMutation(
      () => _activityRepository.updateBeltSectionColor(
        groupId: groupId,
        beltName: beltName,
        colorValue: colorValue,
      ),
    );
  }

  Future<void> updateActivityColor({
    required String groupId,
    required String activityId,
    required int colorValue,
  }) {
    return _runMutation(
      () => _activityRepository.updateActivityColor(
        groupId: groupId,
        activityId: activityId,
        colorValue: colorValue,
      ),
    );
  }

  Future<void> _runMutation(Future<void> Function() action) async {
    _isMutating = true;
    notifyListeners();
    try {
      await action();
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }
}
