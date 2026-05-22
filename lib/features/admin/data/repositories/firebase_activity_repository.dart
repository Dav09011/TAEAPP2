import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tae_app/core/errors/app_exception.dart';
import 'package:tae_app/core/services/firestore_service.dart';
import 'package:tae_app/features/admin/domain/entities/activity_item.dart';
import 'package:tae_app/features/admin/domain/entities/belt_section.dart';
import 'package:tae_app/features/admin/domain/entities/create_activity_request.dart';
import 'package:tae_app/features/admin/domain/repositories/activity_repository.dart';

class FirebaseActivityRepository implements ActivityRepository {
  FirebaseActivityRepository({FirestoreService? firestoreService})
    : _firestoreService = firestoreService ?? FirestoreService();

  final FirestoreService _firestoreService;

  FirebaseFirestore get _db => _firestoreService.instance;

  @override
  Stream<List<BeltSection>> watchBeltSections(String groupId) {
    return _db
        .collection('grupos')
        .doc(groupId)
        .collection('secciones_cinta')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => BeltSection(
                      id: doc.id,
                      name: doc.id,
                      colorValue: (doc.data()['color_value'] as num?)?.toInt(),
                    ),
                  )
                  .toList(),
        );
  }

  @override
  Stream<List<ActivityItem>> watchActivitiesBySection({
    required String groupId,
    required String beltName,
  }) {
    return _db
        .collection('grupos')
        .doc(groupId)
        .collection('actividades')
        .where('cinta_seccion', isEqualTo: beltName)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => ActivityItem(
                      id: doc.id,
                      name:
                          doc.data()['nombre_actividad'] as String? ??
                          'Actividad sin nombre',
                      exercises:
                          (doc.data()['ejercicios'] as List<dynamic>? ?? const [])
                              .map((item) => item.toString())
                              .toList(),
                      beltSection:
                          doc.data()['cinta_seccion'] as String? ?? beltName,
                      colorValue: (doc.data()['color_value'] as num?)?.toInt(),
                    ),
                  )
                  .toList(),
        );
  }

  @override
  Future<void> createActivity(CreateActivityRequest request) async {
    if (request.activityName.trim().isEmpty || request.exercises.isEmpty) {
      throw const AppException(
        'La actividad necesita nombre y al menos un ejercicio.',
      );
    }

    await _db
        .collection('grupos')
        .doc(request.groupId)
        .collection('actividades')
        .add({
          'nombre_actividad': request.activityName,
          'ejercicios': request.exercises,
          'cinta_seccion': request.beltName,
          'color_value': null,
          'fecha_creacion': FieldValue.serverTimestamp(),
        });
  }

  @override
  Future<void> createBeltSection({
    required String groupId,
    required String beltName,
  }) async {
    if (beltName.trim().isEmpty) {
      throw const AppException('La seccion necesita un nombre.');
    }

    await _db
        .collection('grupos')
        .doc(groupId)
        .collection('secciones_cinta')
        .doc(beltName)
        .set({
          'nombre_cinta': beltName,
          'color_value': null,
          'fecha_creacion': FieldValue.serverTimestamp(),
        });
  }

  @override
  Future<void> renameActivity({
    required String groupId,
    required String activityId,
    required String newName,
  }) {
    return _db
        .collection('grupos')
        .doc(groupId)
        .collection('actividades')
        .doc(activityId)
        .update({'nombre_actividad': newName});
  }

  @override
  Future<void> deleteActivity({
    required String groupId,
    required String activityId,
  }) {
    return _db
        .collection('grupos')
        .doc(groupId)
        .collection('actividades')
        .doc(activityId)
        .delete();
  }

  @override
  Future<void> renameBeltSection({
    required String groupId,
    required String oldName,
    required String newName,
  }) async {
    final oldDoc =
        await _db
            .collection('grupos')
            .doc(groupId)
            .collection('secciones_cinta')
            .doc(oldName)
            .get();

    if (!oldDoc.exists) {
      throw const AppException('La seccion no existe.');
    }

    final data = oldDoc.data() ?? {};

    await _db
        .collection('grupos')
        .doc(groupId)
        .collection('secciones_cinta')
        .doc(newName)
        .set({
          ...data,
          'nombre_cinta': newName,
        });

    final activitiesSnapshot =
        await _db
            .collection('grupos')
            .doc(groupId)
            .collection('actividades')
            .where('cinta_seccion', isEqualTo: oldName)
            .get();

    final batch = _db.batch();
    for (final doc in activitiesSnapshot.docs) {
      batch.update(doc.reference, {'cinta_seccion': newName});
    }
    await batch.commit();

    await _db
        .collection('grupos')
        .doc(groupId)
        .collection('secciones_cinta')
        .doc(oldName)
        .delete();
  }

  @override
  Future<void> deleteBeltSection({
    required String groupId,
    required String beltName,
  }) async {
    final activitiesSnapshot =
        await _db
            .collection('grupos')
            .doc(groupId)
            .collection('actividades')
            .where('cinta_seccion', isEqualTo: beltName)
            .get();

    if (activitiesSnapshot.docs.isNotEmpty) {
      final batch = _db.batch();
      for (final doc in activitiesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }

    await _db
        .collection('grupos')
        .doc(groupId)
        .collection('secciones_cinta')
        .doc(beltName)
        .delete();
  }

  @override
  Future<void> updateBeltSectionColor({
    required String groupId,
    required String beltName,
    required int colorValue,
  }) {
    return _db
        .collection('grupos')
        .doc(groupId)
        .collection('secciones_cinta')
        .doc(beltName)
        .set({'color_value': colorValue}, SetOptions(merge: true));
  }

  @override
  Future<void> updateActivityColor({
    required String groupId,
    required String activityId,
    required int colorValue,
  }) {
    return _db
        .collection('grupos')
        .doc(groupId)
        .collection('actividades')
        .doc(activityId)
        .update({'color_value': colorValue});
  }

  @override
  Future<void> addExercise({
    required String groupId,
    required String activityId,
    required String exerciseName,
  }) {
    return _db
        .collection('grupos')
        .doc(groupId)
        .collection('actividades')
        .doc(activityId)
        .update({
          'ejercicios': FieldValue.arrayUnion([exerciseName]),
        });
  }

  @override
  Future<void> removeExercise({
    required String groupId,
    required String activityId,
    required String exerciseName,
  }) {
    return _db
        .collection('grupos')
        .doc(groupId)
        .collection('actividades')
        .doc(activityId)
        .update({
          'ejercicios': FieldValue.arrayRemove([exerciseName]),
        });
  }

  @override
  Future<void> renameExercise({
    required String groupId,
    required String activityId,
    required String oldName,
    required String newName,
  }) async {
    await removeExercise(
      groupId: groupId,
      activityId: activityId,
      exerciseName: oldName,
    );

    await addExercise(
      groupId: groupId,
      activityId: activityId,
      exerciseName: newName,
    );
  }
}
