import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tae_app/core/errors/app_exception.dart';
import 'package:tae_app/core/services/auth_service.dart';
import 'package:tae_app/core/services/firestore_service.dart';
import 'package:tae_app/features/student/domain/entities/create_cash_payment_request.dart';
import 'package:tae_app/features/student/domain/repositories/student_cash_payment_repository.dart';

class FirebaseStudentCashPaymentRepository
    implements StudentCashPaymentRepository {
  FirebaseStudentCashPaymentRepository({
    AuthService? authService,
    FirestoreService? firestoreService,
  }) : _authService = authService ?? AuthService(),
       _firestoreService = firestoreService ?? FirestoreService();

  final AuthService _authService;
  final FirestoreService _firestoreService;

  @override
  Stream<bool> watchHasPendingRequestForCurrentStudent() {
    final user = _authService.currentUser;
    if (user == null) {
      return const Stream<bool>.empty();
    }

    return _cashPaymentRequests()
        .where('uid', isEqualTo: user.uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty);
  }

  @override
  Future<void> createRequest(CreateCashPaymentRequest request) {
    final user = _authService.currentUser;
    if (user == null) {
      throw const AppException('No hay sesion activa.');
    }

    return _cashPaymentRequests().add({
      'uid': user.uid,
      'classes': request.classes,
      'total': request.total,
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  CollectionReference<Map<String, dynamic>> _cashPaymentRequests() {
    return _firestoreService.instance.collection('cash_payment_requests');
  }
}
