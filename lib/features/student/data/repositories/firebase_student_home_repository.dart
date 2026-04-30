import 'package:tae_app/core/services/firestore_service.dart';
import 'package:tae_app/features/student/domain/repositories/student_home_repository.dart';

class FirebaseStudentHomeRepository implements StudentHomeRepository {
  FirebaseStudentHomeRepository({FirestoreService? firestoreService})
    : _firestoreService = firestoreService ?? FirestoreService();

  final FirestoreService _firestoreService;

  @override
  Future<Map<String, dynamic>?> loadHomeData(String userId) async {
    final snapshot = await _firestoreService.users().doc(userId).get();
    return snapshot.data();
  }
}
