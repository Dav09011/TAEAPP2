import 'package:flutter/foundation.dart';
import 'package:tae_app/features/admin/domain/entities/student_billing_status.dart';

/// Prepares the student billing page for future persistence.
///
/// For now the controller exposes seeded records plus search/filter behavior.
/// That lets us keep business state out of the widget tree and preserves the
/// same migration pattern used in auth, branches, groups and activities.
class WalletStudentStatusController extends ChangeNotifier {
  final List<StudentBillingStatus> _students = const [
    StudentBillingStatus(
      id: '1',
      studentName: 'Israel Perez',
      groupName: 'Grupo Infantil',
      beltName: 'Cinta Blanca',
      amountLabel: r'$850 MXN',
      status: StudentBillingState.upToDate,
      lastPaymentLabel: 'Pagado el 05/04/2026',
    ),
    StudentBillingStatus(
      id: '2',
      studentName: 'Maribel Sanchez',
      groupName: 'Grupo Juvenil',
      beltName: 'Cinta Naranja',
      amountLabel: r'$1,150 MXN',
      status: StudentBillingState.pending,
      lastPaymentLabel: 'Vence el 30/04/2026',
    ),
    StudentBillingStatus(
      id: '3',
      studentName: 'Karen Diaz',
      groupName: 'Grupo Competencia',
      beltName: 'Cinta Verde',
      amountLabel: r'$0 MXN',
      status: StudentBillingState.scholarship,
      lastPaymentLabel: 'Beca activa hasta nuevo aviso',
    ),
    StudentBillingStatus(
      id: '4',
      studentName: 'Luis Gomez',
      groupName: 'Grupo Adultos',
      beltName: 'Cinta Amarilla',
      amountLabel: r'$850 MXN',
      status: StudentBillingState.pending,
      lastPaymentLabel: 'Pendiente desde el 18/04/2026',
    ),
  ];

  String _query = '';

  String get query => _query;

  List<StudentBillingStatus> get visibleStudents {
    final normalizedQuery = _query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return List<StudentBillingStatus>.unmodifiable(_students);
    }

    return _students.where((student) {
      return student.studentName.toLowerCase().contains(normalizedQuery) ||
          student.groupName.toLowerCase().contains(normalizedQuery) ||
          student.beltName.toLowerCase().contains(normalizedQuery);
    }).toList(growable: false);
  }

  void updateQuery(String value) {
    if (_query == value) return;
    _query = value;
    notifyListeners();
  }
}
