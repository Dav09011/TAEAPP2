import 'package:tae_app/features/student/domain/entities/create_cash_payment_request.dart';

abstract class StudentCashPaymentRepository {
  Stream<bool> watchHasPendingRequestForCurrentStudent();

  Future<void> createRequest(CreateCashPaymentRequest request);
}
