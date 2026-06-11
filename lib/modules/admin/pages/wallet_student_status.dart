import 'package:flutter/material.dart';
import 'package:tae_app/features/admin/domain/entities/admin_wallet_student_status.dart';
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
    _controller.load();
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
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
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 40,
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
                            onChanged: _controller.filterStudents,
                            style: const TextStyle(fontSize: 14),
                            decoration: const InputDecoration(
                              hintText: 'Buscar por nombre, grupo o estado...',
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: const Text('Todas las sucursales'),
                  selected: _controller.selectedBranchId == null,
                  onSelected: (_) => _controller.clearFilters(),
                ),
                ..._controller.branchOptions.map(
                  (branch) => FilterChip(
                    label: Text(branch.label),
                    selected: _controller.selectedBranchId == branch.id,
                    onSelected: (_) => _controller.setBranchFilter(branch.id),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: const Text('Todos los grupos'),
                  selected: _controller.selectedGroupId == null,
                  onSelected: (_) => _controller.setGroupFilter(null),
                ),
                ..._controller.groupOptions.map(
                  (group) => FilterChip(
                    label: Text(group.label),
                    selected: _controller.selectedGroupId == group.id,
                    onSelected: (_) => _controller.setGroupFilter(group.id),
                  ),
                ),
              ],
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
          Expanded(
            child:
                _controller.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _controller.students.isEmpty
                    ? const Center(child: Text('No hay alumnos con ese criterio.'))
                    : ListView.builder(
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

  Widget _buildStudentStatusCard(
    AdminWalletStudentStatus student,
    Color primaryColor,
  ) {
    final statusStyle = _statusStyle(student.status);

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
                  student.studentName,
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
          const SizedBox(height: 8),
          Text(
            '${student.branchName} · ${student.groupName}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
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

  (Color, String, Color) _statusStyle(String status) {
    switch (status) {
      case 'paid':
        return (
          Colors.green.withValues(alpha: 0.1),
          'Pago al corriente',
          Colors.green.shade800,
        );
      case 'pending':
        return (
          Colors.orange.withValues(alpha: 0.1),
          'Pago pendiente',
          Colors.orange.shade800,
        );
      case 'scholarship':
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
