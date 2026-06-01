import 'package:flutter/material.dart';
import 'package:tae_app/features/admin/domain/entities/student_billing_status.dart';
import 'package:tae_app/features/admin/presentation/controllers/wallet_student_status_controller.dart';

class WalletStudentStatusPage extends StatefulWidget {
  const WalletStudentStatusPage({super.key});

  @override
  State<WalletStudentStatusPage> createState() =>
      _WalletStudentStatusPageState();
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
    _controller.removeListener(_handleControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color.fromARGB(255, 41, 53, 119);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- TARJETA DE CABECERA COMPACTA Y ALARGADA ---
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14.0,
              vertical: 8.0,
            ), // Margen exterior reducido para mayor longitud
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 18.0,
                vertical: 14.0,
              ), // Relleno interno optimizado
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Colors.grey.withValues(alpha: 0.2),
                  width: 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ESTADO DE ALUMNOS',
                    style: TextStyle(
                      fontSize: 30, // Tamaño balanceado
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Buscador integrado en la tarjeta
                  Container(
                    height: 40, // Altura fina y elegante
                    decoration: BoxDecoration(
                      color: const Color(0xfff1f3f6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.grey, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            onChanged: (value) {
                              _controller.filterStudents(value);
                            },
                            style: const TextStyle(fontSize: 14),
                            decoration: const InputDecoration(
                              hintText: 'Buscar por nombre o grupo...',
                              border: InputBorder.none,
                              hintStyle: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                              contentPadding: EdgeInsets.only(bottom: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Text(
              'Listado de mensualidades',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),

          // Lista de alumnos con scroll
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _controller.students.length,
              itemBuilder: (context, index) {
                return _buildStudentStatusCard(
                  _controller.students[index],
                  primaryColor,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentStatusCard(dynamic student, Color primaryColor) {
    final statusStyle = _statusStyle(student.state);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  student.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                student.groupName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            student.billingLabel,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
          const SizedBox(height: 6),
          Text(
            student.lastPaymentLabel,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
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
          Colors.green.withValues(alpha: 0.1),
          'Pago al corriente',
          Colors.green.shade800,
        );
      case StudentBillingState.pending:
        return (
          Colors.orange.withValues(alpha: 0.1),
          'Pago pendiente',
          Colors.orange.shade800,
        );
      case StudentBillingState.scholarship:
        return (
          const Color.fromARGB(255, 41, 53, 119).withValues(alpha: 0.1),
          'Beca aplicada',
          const Color.fromARGB(255, 41, 53, 119),
        );
      default:
        return (
          Colors.grey.withValues(alpha: 0.1),
          'Sin registro',
          Colors.grey.shade800,
        );
    }
  }
}
