import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tae_app/features/admin/domain/entities/admin_wallet_branch_summary.dart';
import 'package:tae_app/features/admin/presentation/controllers/wallet_controller.dart';

class WalletPerformanceDetailPage extends StatefulWidget {
  const WalletPerformanceDetailPage({super.key});

  @override
  State<WalletPerformanceDetailPage> createState() =>
      _WalletPerformanceDetailPageState();
}

class _WalletPerformanceDetailPageState
    extends State<WalletPerformanceDetailPage> {
  final WalletController _controller = WalletController();
  String? _selectedBranchId;

  static const Color _primaryColor = Color.fromARGB(255, 41, 53, 119);

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleControllerChanged);
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleControllerChanged)
      ..dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    final branches = _controller.branchSummaries;
    if (branches.isNotEmpty &&
        (_selectedBranchId == null ||
            !branches.any((branch) => branch.branchId == _selectedBranchId))) {
      _selectedBranchId = branches.first.branchId;
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final branches = _controller.branchSummaries;
    final selected = _selectedBranch(branches);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Detalle financiero',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body:
          _controller.isLoadingSummary
              ? const Center(child: CircularProgressIndicator())
              : branches.isEmpty
              ? const _EmptyBranchesState()
              : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBranchSelector(branches),
                    const SizedBox(height: 16),
                    if (selected != null) ...[
                      _buildSummaryCard(selected),
                      const SizedBox(height: 16),
                      _buildDateRangeCard(),
                      const SizedBox(height: 16),
                      _buildReportRows(selected),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Reporte preparado en UI. La descarga se conectara despues.',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.description_outlined),
                          label: const Text('Generar reporte'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
    );
  }

  AdminWalletBranchSummary? _selectedBranch(
    List<AdminWalletBranchSummary> branches,
  ) {
    if (branches.isEmpty) return null;
    for (final branch in branches) {
      if (branch.branchId == _selectedBranchId) {
        return branch;
      }
    }
    return branches.first;
  }

  Widget _buildBranchSelector(List<AdminWalletBranchSummary> branches) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _primaryColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.storefront_outlined, color: _primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: _selectedBranchId ?? branches.first.branchId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Sucursal',
                border: InputBorder.none,
              ),
              items:
                  branches
                      .map(
                        (branch) => DropdownMenuItem(
                          value: branch.branchId,
                          child: Text(branch.branchName),
                        ),
                      )
                      .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selectedBranchId = value);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(AdminWalletBranchSummary branch) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Historial ${branch.branchName}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${branch.studentsCount} alumnos / ${branch.groupsCount} grupos',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.account_balance_outlined, color: _primaryColor),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _BranchPieChart(
                paidCount: branch.paidCount,
                pendingCount: branch.pendingCount,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  children: [
                    _DetailMetricRow(
                      label: 'Pagados',
                      value: branch.paidCount.toString(),
                      color: Colors.green,
                    ),
                    const SizedBox(height: 10),
                    _DetailMetricRow(
                      label: 'Pendientes',
                      value: branch.pendingCount.toString(),
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 10),
                    _DetailMetricRow(
                      label: 'Ingresos',
                      value: _formatMoney(branch.totalPaidCents),
                      color: _primaryColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(Icons.calendar_today_outlined, size: 18, color: _primaryColor),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              '01/06/2026',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text('-', style: TextStyle(color: Colors.black45)),
          Expanded(
            child: Text(
              '30/06/2026',
              textAlign: TextAlign.right,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportRows(AdminWalletBranchSummary branch) {
    return Column(
      children: [
        _ReportMetricCard(
          icon: Icons.trending_up,
          title: 'Ingresos confirmados',
          value: _formatMoney(branch.totalPaidCents),
          color: Colors.green,
        ),
        const SizedBox(height: 12),
        _ReportMetricCard(
          icon: Icons.pending_actions_outlined,
          title: 'Monto pendiente',
          value: _formatMoney(branch.totalPendingCents),
          color: Colors.orange,
        ),
        const SizedBox(height: 12),
        _ReportMetricCard(
          icon: Icons.payments_outlined,
          title: 'Solicitudes en efectivo',
          value: branch.cashRequestsCount.toString(),
          color: _primaryColor,
        ),
      ],
    );
  }

  String _formatMoney(int cents) {
    return '\$${(cents / 100).toStringAsFixed(2)}';
  }
}

class _BranchPieChart extends StatelessWidget {
  const _BranchPieChart({required this.paidCount, required this.pendingCount});

  final int paidCount;
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 98,
      height: 98,
      child: CustomPaint(
        painter: _BranchPiePainter(
          paidCount: paidCount,
          pendingCount: pendingCount,
        ),
      ),
    );
  }
}

class _BranchPiePainter extends CustomPainter {
  const _BranchPiePainter({
    required this.paidCount,
    required this.pendingCount,
  });

  final int paidCount;
  final int pendingCount;

  @override
  void paint(Canvas canvas, Size size) {
    final total = paidCount + pendingCount;
    final rect = Offset.zero & size;
    final paint = Paint()..style = PaintingStyle.fill;

    if (total == 0) {
      paint.color = const Color(0xFFE9EAF0);
      canvas.drawOval(rect, paint);
      return;
    }

    final paidSweep = (paidCount / total) * math.pi * 2;
    paint.color = Colors.green;
    canvas.drawArc(rect, -math.pi / 2, paidSweep, true, paint);
    paint.color = Colors.orange;
    canvas.drawArc(
      rect,
      -math.pi / 2 + paidSweep,
      math.pi * 2 - paidSweep,
      true,
      paint,
    );
    paint.color = Colors.white;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width * 0.28,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _BranchPiePainter oldDelegate) {
    return oldDelegate.paidCount != paidCount ||
        oldDelegate.pendingCount != pendingCount;
  }
}

class _DetailMetricRow extends StatelessWidget {
  const _DetailMetricRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _ReportMetricCard extends StatelessWidget {
  const _ReportMetricCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyBranchesState extends StatelessWidget {
  const _EmptyBranchesState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Text(
          'Todavia no hay sucursales para mostrar rendimiento.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
      ),
    );
  }
}
