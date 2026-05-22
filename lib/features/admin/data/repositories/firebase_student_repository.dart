import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tae_app/core/services/firestore_service.dart';
import 'package:tae_app/features/admin/domain/entities/admin_student.dart';
import 'package:tae_app/features/admin/domain/repositories/student_repository.dart';

class FirebaseStudentRepository implements StudentRepository {
  FirebaseStudentRepository({FirestoreService? firestoreService})
    : _firestoreService = firestoreService ?? FirestoreService();

  final FirestoreService _firestoreService;

  FirebaseFirestore get _db => _firestoreService.instance;

  @override
  Stream<List<AdminStudent>> watchStudentsByGroup(String groupId) {
    return _db
        .collection('grupos')
        .doc(groupId)
        .collection('alumnos')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => AdminStudent(
                      id: doc.id,
                      name: doc.data()['nombre'] as String? ?? 'Sin nombre',
                      imageUrl: doc.data()['imagen'] as String? ?? '',
                      belt: doc.data()['cinta'] as String? ?? 'Sin cinta',
                      userId: doc.data()['uid'] as String? ?? '',
                    ),
                  )
                  .toList(),
        );
  }

  @override
  Future<AdminStudent> getStudentDetails(String userId) async {
    final userDoc = await _db.collection('usuarios').doc(userId).get();
    final data = userDoc.data() ?? const <String, dynamic>{};

    return AdminStudent(
      id: userId,
      userId: userId,
      name: data['nombre'] as String? ?? 'Sin nombre',
      lastName: data['ap'] as String? ?? '',
      middleName: data['am'] as String? ?? '',
      imageUrl: data['imagen'] as String? ?? '',
      belt: data['grupo_cinta'] as String? ?? 'Sin cinta',
      email: data['correo'] as String? ?? '',
      phone: data['telefono'] as String? ?? '',
      role: data['tipo'] as String? ?? '',
    );
  }

  @override
  Future<void> deleteStudents({
    required String groupId,
    required List<String> studentIds,
  }) async {
    final batch = _db.batch();
    for (final studentId in studentIds) {
      final docRef = _db
          .collection('grupos')
          .doc(groupId)
          .collection('alumnos')
          .doc(studentId);
      batch.delete(docRef);
    }
    await batch.commit();
  }
}
