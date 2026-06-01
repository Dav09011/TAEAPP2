import 'package:tae_app/core/errors/app_exception.dart';
import 'package:tae_app/features/student/data/repositories/firebase_student_cash_payment_repository.dart';
import 'package:tae_app/features/student/domain/entities/create_cash_payment_request.dart';
import 'package:tae_app/features/student/domain/repositories/student_cash_payment_repository.dart';

class StudentCashPaymentController {
  StudentCashPaymentController({StudentCashPaymentRepository? repository})
    : _repository = repository ?? FirebaseStudentCashPaymentRepository();

  final StudentCashPaymentRepository _repository;

  Stream<bool> watchHasPendingRequest() {
    return _repository.watchHasPendingRequestForCurrentStudent();
  }

  Future<void> createRequest({required int classes, required int total}) {
    return _repository.createRequest(
      CreateCashPaymentRequest(classes: classes, total: total),
    );
  }

  String errorMessage(Object error) {
    if (error is AppException) {
      return error.message;
    }
    return 'No se pudo enviar la solicitud';
  }
}
