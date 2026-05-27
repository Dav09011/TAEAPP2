import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:tae_app/modules/admin/domains/entities/student_billing_status.dart';

class WalletStudentStatusController extends ChangeNotifier {
  final List<StudentBillingStatus> _students = [];

  List<StudentBillingStatus> get students => _students;

  // ESTE MÉTODO ES EL QUE TE FALTA
  Future<void> loadStudents() async {
    _students.clear();

    try {
      final customerInfo = await Purchases.getCustomerInfo();

      final entitlement =
      customerInfo.entitlements.all['TAEAPP Pro'];

      final bool isPremium =
          entitlement?.isActive == true;

      _students.add(
        StudentBillingStatus(
          name: 'Alumno Demo',
          groupName: 'Grupo A',
          billingLabel: isPremium
              ? 'Membresía activa'
              : 'Sin membresía',
          lastPaymentLabel:
          entitlement?.latestPurchaseDate != null
              ? 'Último pago: ${entitlement!.latestPurchaseDate}'
              : 'Sin pagos',
          state: isPremium
              ? StudentBillingState.upToDate
              : StudentBillingState.pending,
        ),
      );
    } catch (e) {
      debugPrint(e.toString());
    }

    notifyListeners();
  }

  void filterStudents(String query) {
    notifyListeners();
  }
}