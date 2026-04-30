import 'package:flutter/material.dart';
import 'package:tae_app/features/admin/domain/entities/student_billing_status.dart';

class WalletStudentStatusController extends ChangeNotifier {
  // 1. La lista original (Intocable, funciona como nuestra base de datos local temporal)
  final List<StudentBillingStatus> _allStudents = [
    StudentBillingStatus(
      id: '1',
      name: 'Maribel Castillo',
      groupName: 'Cinta Blanca',
      state: StudentBillingState.upToDate,
      billingLabel: 'Mensualidad: Pagada',
      lastPaymentLabel: 'Último pago: hace 2 días',
    ),
    StudentBillingStatus(
      id: '2',
      name: 'Jose Jose',
      groupName: 'Cinta Blanca',
      state: StudentBillingState.pending,
      billingLabel: 'Mensualidad: Pendiente',
      lastPaymentLabel: 'Venció hace 5 días',
    ),
    StudentBillingStatus(
      id: '3',
      name: 'Nancy Herrera',
      groupName: 'Cinta Amarilla',
      state: StudentBillingState.scholarship,
      billingLabel: 'Beca Deportiva (100%)',
      lastPaymentLabel: 'Ajuste de sistema',
    ),
    StudentBillingStatus(
      id: '4',
      name: 'Israel García',
      groupName: 'Cinta Azul',
      state: StudentBillingState.upToDate,
      billingLabel: 'Mensualidad: Pagada',
      lastPaymentLabel: 'Último pago: hace 1 semana',
    ),
  ];

  // 2. La lista que realmente se muestra en la pantalla
  List<StudentBillingStatus> _filteredStudents = [];

  WalletStudentStatusController() {
    // Cuando el controlador nace, la lista filtrada es igual a la original
    _filteredStudents = List.from(_allStudents);
  }

  // El Getter ahora devuelve la lista filtrada
  List<StudentBillingStatus> get students => _filteredStudents;

  // 3. La función mágica de búsqueda
  void filterStudents(String query) {
    if (query.isEmpty) {
      // Si borran el texto, regresamos todos los alumnos
      _filteredStudents = List.from(_allStudents);
    } else {
      // Si hay texto, filtramos buscando coincidencias en el nombre ignorando mayúsculas
      _filteredStudents =
          _allStudents.where((student) {
            return student.name.toLowerCase().contains(query.toLowerCase());
          }).toList();
    }

    // Le gritamos a la UI: "¡Oye, la lista cambió, vuelve a dibujarte!"
    notifyListeners();
  }
}
