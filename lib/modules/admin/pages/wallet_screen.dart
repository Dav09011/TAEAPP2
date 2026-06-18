import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tae_app/app/router/app_routes.dart';
import 'package:tae_app/features/admin/presentation/controllers/wallet_controller.dart';
import 'package:tae_app/modules/admin/pages/wallet_performance_detail.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final WalletController _controller = WalletController();

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
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 22),
            _buildGeneralPerformanceCard(context),
            const SizedBox(height: 28),
            _buildWalletActionCard(
              context,
              title: 'Pagos en Efectivo',
              subtitle:
                  '${_controller.totalCashRequestsCount} solicitudes pendientes por revisar',
              icon: Icons.account_balance_wallet_outlined,
              color: Colors.green,
              onTap: () => Navigator.pushNamed(context, AppRoutes.cashPayments),
            ),
            const SizedBox(height: 15),
            _buildWalletActionCard(
              context,
              title: 'Estado de Alumnos',
              subtitle: 'Control de mensualidades y becas',
              icon: Icons.people_alt_outlined,
              color: Colors.blue,
              onTap:
                  () => Navigator.pushNamed(
                    context,
                    AppRoutes.walletStudentStatus,
                  ),
            ),
            const SizedBox(height: 15),
            _buildWalletActionCard(
              context,
              title: 'Configurar Tarifas',
              subtitle: 'Gestionar montos y dias de clase',
              icon: Icons.settings_outlined,
              color: Colors.purple,
              onTap: () => Navigator.pushNamed(context, AppRoutes.walletFees),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CARTERA',
            style: TextStyle(
              fontSize: 35,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(
                Icons.person_outline,
                size: 20,
                color: Colors.blueAccent,
              ),
              const SizedBox(width: 8),
              _controller.isLoadingHeader
                  ? const Text('Cargando...', style: TextStyle(fontSize: 14))
                  : Text(
                    'Hola, ${_controller.adminName}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralPerformanceCard(BuildContext context) {
    return InkWell(
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const WalletPerformanceDetailPage(),
            ),
          ),
      onHighlightChanged: _controller.setPressed,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color:
                _controller.isPressed
                    ? _primaryColor.withValues(alpha: 0.35)
                    : Colors.grey.withValues(alpha: 0.16),
            width: _controller.isPressed ? 1.8 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: _controller.isPressed ? 20 : 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child:
            _controller.isLoadingSummary
                ? const SizedBox(
                  height: 150,
                  child: Center(child: CircularProgressIndicator()),
                )
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Rendimiento General',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_controller.branchSummaries.length} sucursales conectadas',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        _WalletPieChart(
                          paidCount: _controller.totalPaidCount,
                          pendingCount: _controller.totalPendingCount,
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            children: [
                              _MetricRow(
                                label: 'Pagados',
                                value: _formatCount(_controller.totalPaidCount),
                                color: Colors.green,
                              ),
                              const SizedBox(height: 10),
                              _MetricRow(
                                label: 'Pendientes',
                                value: _formatCount(
                                  _controller.totalPendingCount,
                                ),
                                color: Colors.orange,
                              ),
                              const SizedBox(height: 10),
                              _MetricRow(
                                label: 'Ingresos',
                                value: _formatMoney(
                                  _controller.totalIncomeCents,
                                ),
                                color: _primaryColor,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _SmallSummaryPill(
                            label: 'Alumnos',
                            value: _formatCount(_controller.totalStudentsCount),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _SmallSummaryPill(
                            label: 'Grupos',
                            value: _formatCount(_controller.totalGroupsCount),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildWalletActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  String _formatMoney(int cents) {
    return '\$${(cents / 100).toStringAsFixed(2)}';
  }

  String _formatCount(int value) {
    return value.toString();
  }
}

class _WalletPieChart extends StatelessWidget {
  const _WalletPieChart({required this.paidCount, required this.pendingCount});

  final int paidCount;
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      height: 92,
      child: CustomPaint(
        painter: _WalletPiePainter(
          paidCount: paidCount,
          pendingCount: pendingCount,
        ),
      ),
    );
  }
}

class _WalletPiePainter extends CustomPainter {
  const _WalletPiePainter({
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
  bool shouldRepaint(covariant _WalletPiePainter oldDelegate) {
    return oldDelegate.paidCount != paidCount ||
        oldDelegate.pendingCount != pendingCount;
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
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

class _SmallSummaryPill extends StatelessWidget {
  const _SmallSummaryPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
