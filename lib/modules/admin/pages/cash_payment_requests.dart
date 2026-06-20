import 'package:flutter/material.dart';
import 'package:tae_app/features/admin/domain/entities/admin_cash_payment_request.dart';
import 'package:tae_app/features/admin/presentation/controllers/cash_payment_requests_controller.dart';

class CashPaymentRequestsScreen extends StatefulWidget {
  const CashPaymentRequestsScreen({super.key});

  @override
  State<CashPaymentRequestsScreen> createState() =>
      _CashPaymentRequestsScreenState();
}

class _CashPaymentRequestsScreenState extends State<CashPaymentRequestsScreen> {
  final CashPaymentRequestsController _controller =
      CashPaymentRequestsController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleControllerChanged);
    _controller.initialize();
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
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 8.0,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 16.0,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Colors.grey.withValues(alpha: 0.2),
                  width: 2.0,
                ),
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
                    'SOLICITUDES EN EFECTIVO',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xfff1f3f6),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 2,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            onChanged: _controller.updateSearchQuery,
                            decoration: const InputDecoration(
                              hintText: 'Buscar alumno, sucursal o grupo...',
                              border: InputBorder.none,
                              hintStyle: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bandeja de entrada',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Las solicitudes salen de Firestore y se aprueban o rechazan desde aqui.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child:
                _controller.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _controller.requests.isEmpty
                    ? const Center(
                      child: Text('No hay solicitudes pendientes.'),
                    )
                    : RefreshIndicator(
                      onRefresh: _controller.initialize,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(
                          left: 20,
                          right: 20,
                          bottom: 100,
                        ),
                        itemCount: _controller.requests.length,
                        itemBuilder: (context, index) {
                          final request = _controller.requests[index];
                          return _buildRequestItem(
                            context,
                            request,
                            primaryColor,
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Future<bool> _showPaymentDecisionDialog(
    BuildContext context, {
    required bool approve,
    required String studentName,
    required String amountLabel,
  }) async {
    final target = '$studentName por $amountLabel';
    final result = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            icon: Icon(
              approve ? Icons.payments_outlined : Icons.warning_amber_rounded,
              color: approve ? Colors.green : Colors.red,
              size: 34,
            ),
            title: Text(
              approve
                  ? 'Confirmar pago en efectivo'
                  : 'Denegar pago en efectivo',
            ),
            content: Text(
              approve
                  ? 'Confirmas el pago de $target? Se registrara como pagado.'
                  : 'Deseas denegar el pago de $target? La solicitud se retirara de la bandeja.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: approve ? Colors.green : Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(approve ? 'Confirmar pago' : 'Denegar pago'),
              ),
            ],
          ),
    );
    return result ?? false;
  }

  void _showProcessError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No se pudo procesar la solicitud.')),
    );
  }

  Widget _buildRequestItem(
    BuildContext context,
    AdminCashPaymentRequest request,
    Color primaryColor,
  ) {
    return Dismissible(
      key: ValueKey(request.id),
      direction: DismissDirection.horizontal,
      background: _SwipeActionBackground(
        color: Colors.green,
        icon: Icons.check_circle_outline,
        label: 'Aceptar',
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: _SwipeActionBackground(
        color: Colors.red,
        icon: Icons.cancel_outlined,
        label: 'Rechazar',
        alignment: Alignment.centerRight,
      ),
      confirmDismiss: (direction) async {
        final approve = direction == DismissDirection.startToEnd;
        final confirmed = await _showPaymentDecisionDialog(
          context,
          approve: approve,
          studentName: request.studentName,
          amountLabel: _formatMoney(request.amountCents),
        );
        if (!confirmed) return false;

        try {
          if (approve) {
            await _controller.approveRequest(request.id);
          } else {
            await _controller.rejectRequest(request.id);
          }
          return true;
        } catch (error) {
          if (!context.mounted) return false;
          _showProcessError(context);
          return false;
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_outline, color: Colors.green),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.studentName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${request.branchName} · ${request.groupName}',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatMoney(request.amountCents),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMoney(int cents) {
    return '\$${(cents / 100).toStringAsFixed(2)}';
  }
}

class _SwipeActionBackground extends StatelessWidget {
  const _SwipeActionBackground({
    required this.color,
    required this.icon,
    required this.label,
    required this.alignment,
  });

  final Color color;
  final IconData icon;
  final String label;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment:
            alignment == Alignment.centerLeft
                ? MainAxisAlignment.start
                : MainAxisAlignment.end,
        children: [
          if (alignment == Alignment.centerLeft) ...[
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ] else ...[
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Icon(icon, color: color),
          ],
        ],
      ),
    );
  }
}
