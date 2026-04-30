import 'package:flutter/material.dart';
import 'package:tae_app/features/admin/domain/entities/student_billing_status.dart';
import 'package:tae_app/features/admin/presentation/controllers/wallet_student_status_controller.dart';

class WalletStudentStatusPage extends StatefulWidget {
  const WalletStudentStatusPage({super.key});

  @override
  State<WalletStudentStatusPage> createState() => _WalletStudentStatusPageState();
}

class _WalletStudentStatusPageState extends State<WalletStudentStatusPage> {
  final WalletStudentStatusController _controller =
      WalletStudentStatusController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleControllerChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleControllerChanged)
      ..dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Estado de Alumnos',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            onChanged: _controller.updateQuery,
            decoration: InputDecoration(
              hintText: 'Buscar por alumno, grupo o cinta',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: const Color.fromARGB(255, 247, 248, 252),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 247, 248, 252),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Text(
              'Este tablero ya vive sobre un controlador propio. Hoy usa datos '
              'semilla para modelar los estados de pago y dejar lista la '
              'separacion de logica antes de conectar reglas reales de cartera.',
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
          const SizedBox(height: 18),
          if (_controller.visibleStudents.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'No hay coincidencias para la busqueda actual.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ..._controller.visibleStudents.map(_buildStudentCard),
        ],
      ),
    );
  }

  Widget _buildStudentCard(StudentBillingStatus student) {
    final statusStyle = _statusStyle(student.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  student.studentName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                student.amountLabel,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${student.groupName} - ${student.beltName}',
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
          const SizedBox(height: 6),
          Text(
            student.lastPaymentLabel,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusStyle.$1,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              statusStyle.$2,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: statusStyle.$3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  (Color, String, Color) _statusStyle(StudentBillingState status) {
    switch (status) {
      case StudentBillingState.upToDate:
        return (
          Colors.green.withOpacity(0.10),
          'Pago al corriente',
          Colors.green.shade800,
        );
      case StudentBillingState.pending:
        return (
          Colors.orange.withOpacity(0.10),
          'Pago pendiente',
          Colors.orange.shade800,
        );
      case StudentBillingState.scholarship:
        return (
          const Color.fromARGB(255, 41, 53, 119).withOpacity(0.10),
          'Alumno con beca',
          const Color.fromARGB(255, 41, 53, 119),
        );
    }
  }
}
