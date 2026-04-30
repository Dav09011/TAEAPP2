import 'package:flutter/foundation.dart';
import 'package:tae_app/core/errors/app_exception.dart';
import 'package:tae_app/features/admin/data/repositories/firebase_activity_repository.dart';
import 'package:tae_app/features/admin/domain/repositories/activity_repository.dart';

/// Handles exercise-level mutations for a single activity.
///
/// Multimedia remains local to the screen for now. This controller only covers
/// the Firebase-backed exercise array so the detail page stops talking to
/// Firestore directly.
class ActivityDetailController extends ChangeNotifier {
  ActivityDetailController({
    required this.groupId,
    required this.activityId,
    required List<String> initialExercises,
    ActivityRepository? activityRepository,
  }) : _activityRepository = activityRepository ?? FirebaseActivityRepository(),
       _exercises = List<String>.from(initialExercises);

  final String groupId;
  final String activityId;
  final ActivityRepository _activityRepository;

  final List<String> _exercises;
  bool _isMutating = false;

  List<String> get exercises => List.unmodifiable(_exercises);
  bool get isMutating => _isMutating;

  Future<void> addExercise(String exerciseName) async {
    final normalized = exerciseName.trim();
    if (normalized.isEmpty) {
      throw const AppException('El ejercicio necesita un nombre.');
    }

    await _runMutation(() async {
      await _activityRepository.addExercise(
        groupId: groupId,
        activityId: activityId,
        exerciseName: normalized,
      );
      _exercises.add(normalized);
    });
  }

  Future<void> deleteExerciseAt(int index) async {
    if (index < 0 || index >= _exercises.length) return;
    final exerciseName = _exercises[index];

    await _runMutation(() async {
      await _activityRepository.removeExercise(
        groupId: groupId,
        activityId: activityId,
        exerciseName: exerciseName,
      );
      _exercises.removeAt(index);
    });
  }

  Future<void> renameExerciseAt(int index, String newName) async {
    if (index < 0 || index >= _exercises.length) return;

    final oldName = _exercises[index];
    final normalized = newName.trim();
    if (normalized.isEmpty) {
      throw const AppException('El ejercicio necesita un nombre.');
    }
    if (oldName == normalized) return;

    await _runMutation(() async {
      await _activityRepository.renameExercise(
        groupId: groupId,
        activityId: activityId,
        oldName: oldName,
        newName: normalized,
      );
      _exercises[index] = normalized;
    });
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
