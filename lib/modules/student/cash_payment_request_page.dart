import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:tae_app/modules/revenuecat/revenuecat_sandbox_screen.dart';

const String _entitlementId = 'TAEAPP Pro';

const _blue      = Color(0xFF4A73B8);
const _blueDark  = Color(0xFF3A5A94);
const _blueLight = Color(0xFFEBF0FA);

// ─────────────────────────────────────────────
// PLANES
// ─────────────────────────────────────────────

class _Plan {
  final int    clases;
  final int    precio;
  final String nombre;
  final String descripcion;

  const _Plan({
    required this.clases,
    required this.precio,
    required this.nombre,
    required this.descripcion,
  });
}

const _planes = [
  _Plan(clases: 1, precio: 500,  nombre: '1 CLASE SEMANAL',     descripcion: 'Acceso al contenido y a 1 clase en la academia'),
  _Plan(clases: 2, precio: 650,  nombre: '2 CLASES SEMANALES',  descripcion: 'Acceso al contenido y a 2 clases en la academia'),
  _Plan(clases: 3, precio: 850,  nombre: '3 CLASES SEMANALES',  descripcion: 'Acceso al contenido y a 3 clases en la academia'),
  _Plan(clases: 4, precio: 900,  nombre: '4 CLASES SEMANALES',  descripcion: 'Acceso al contenido y a 4 clases en la academia'),
  _Plan(clases: 5, precio: 1050, nombre: '5+ CLASES SEMANALES', descripcion: 'Acceso al contenido y clases ilimitadas en la academia'),
];

// ─────────────────────────────────────────────
// PANTALLA PRINCIPAL
// ─────────────────────────────────────────────

class WalletScreenStudent extends StatelessWidget {
  const WalletScreenStudent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F3),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mi Wallet',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        'Gestiona tu suscripción',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const SubscriptionCard(),
              const SizedBox(height: 24),
              const CashPaymentSection(),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// TARJETA SUSCRIPCIÓN
// ─────────────────────────────────────────────

class SubscriptionCard extends StatefulWidget {
  const SubscriptionCard({super.key});

  @override
  State<SubscriptionCard> createState() => _SubscriptionCardState();
}

class _SubscriptionCardState extends State<SubscriptionCard> {
  bool          _loading = true;
  String?       _error;
  CustomerInfo? _customerInfo;

  @override
  void initState() {
    super.initState();
    _loadSubscription();
  }

  Future<void> _loadSubscription() async {
    setState(() { _loading = true; _error = null; });
    try {
      await Purchases.invalidateCustomerInfoCache();
      final info = await Purchases.getCustomerInfo();
      if (!mounted) return;
      setState(() { _customerInfo = info; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _error = 'No se pudo cargar la suscripción.'; _loading = false; });
    }
  }

  bool get _isPremium =>
      _customerInfo?.entitlements.all[_entitlementId]?.isActive == true;

  String _formatDate(String? rawDate) {
    if (rawDate == null) return 'Sin fecha';
    try {
      final dt = DateTime.parse(rawDate).toLocal();
      const m = ['','ene','feb','mar','abr','may','jun','jul','ago','sep','oct','nov','dic'];
      return '${dt.day} ${m[dt.month]} ${dt.year}';
    } catch (_) { return rawDate; }
  }

  String _planType(String productId) {
    final id = productId.toLowerCase();
    if (id.contains('annual') || id.contains('year')) return 'Anual';
    if (id.contains('month')) return 'Mensual';
    if (id.contains('week'))  return 'Semanal';
    return productId;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Banner superior
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: _isPremium && !_loading ? _blue : Colors.black,
            borderRadius: const BorderRadius.only(
              topLeft:  Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: _loading
              ? const SizedBox(
            height: 36,
            child: Center(child: CircularProgressIndicator(color: Colors.white)),
          )
              : Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _isPremium ? Icons.verified_outlined : Icons.lock_outline,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isPremium ? 'Membresía activa' : 'Sin membresía',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _isPremium ? 'TAEAPP Pro' : 'Sin plan activo',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                onPressed: _loadSubscription,
                icon: const Icon(Icons.refresh, color: Colors.white),
              ),
            ],
          ),
        ),

        // Cuerpo
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              bottomLeft:  Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _loading
                ? const SizedBox.shrink()
                : _error != null
                ? Text(_error!, style: const TextStyle(color: Colors.red))
                : Column(
              children: [
                if (_isPremium) ...[
                  _InfoRow(
                    icon:  Icons.star_outline,
                    label: 'Plan',
                    value: _planType(
                      _customerInfo!.entitlements.all[_entitlementId]!.productIdentifier,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon:  Icons.calendar_today_outlined,
                    label: 'Expira',
                    value: _formatDate(
                      _customerInfo!.entitlements.all[_entitlementId]?.expirationDate,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        builder: (_) => _PaymentHistorySheet(
                          customerInfo: _customerInfo!,
                          planType:     _planType,
                          formatDate:   _formatDate,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Ver historial'),
                    ),
                  ),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: _blueLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.star_border_rounded, color: _blue, size: 40),
                        SizedBox(height: 10),
                        Text(
                          'No tienes ninguna suscripción activa.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.w600, color: _blueDark),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => RevenueCatPaywallScreen.show(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon:  const Icon(Icons.workspace_premium_outlined),
                      label: const Text('Ver planes premium'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// SECCIÓN PAGO EN EFECTIVO
// ─────────────────────────────────────────────

class CashPaymentSection extends StatefulWidget {
  const CashPaymentSection({super.key});

  @override
  State<CashPaymentSection> createState() => _CashPaymentSectionState();
}

class _CashPaymentSectionState extends State<CashPaymentSection> {
  int  _index   = 0;
  bool _loading = false;

  _Plan get _plan => _planes[_index];

  void _prev() { if (_index > 0)                    setState(() => _index--); }
  void _next() { if (_index < _planes.length - 1)   setState(() => _index++); }

  Future<void> _sendCashRequest() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _loading = true);
    try {
      await FirebaseFirestore.instance.collection('cash_payment_requests').add({
        'uid':        user.uid,
        'classes':    _plan.clases,
        'total':      _plan.precio,
        'status':     'pending',
        'created_at': DateTime.now().toIso8601String(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitud enviada correctamente')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo enviar la solicitud')),
      );
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('cash_payment_requests')
          .where('uid',    isEqualTo: user?.uid)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        final hasPending =
            snapshot.hasData && snapshot.data!.docs.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selecciona tu plan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),

            // Alerta pendiente
            if (hasPending) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.orange.shade800),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Tu solicitud está pendiente de aprobación.',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Tarjeta principal
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  // ── Carrusel ──
                  Row(
                    children: [
                      _ArrowButton(
                        icon:  Icons.chevron_left,
                        onTap: _index > 0 ? _prev : null,
                      ),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          transitionBuilder: (child, anim) => FadeTransition(
                            opacity: anim,
                            child: ScaleTransition(scale: anim, child: child),
                          ),
                          child: Container(
                            key: ValueKey(_index),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 20),
                            decoration: BoxDecoration(
                              color: _blueLight,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  _plan.nombre,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: _blueDark,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _plan.descripcion,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      _ArrowButton(
                        icon:  Icons.chevron_right,
                        onTap: _index < _planes.length - 1 ? _next : null,
                      ),
                    ],
                  ),

                  // Indicadores
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _planes.length,
                          (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width:  i == _index ? 18 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: i == _index ? _blue : Colors.black12,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Total
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F3F3),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Total a pagar',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            '\$${_plan.precio} MXN',
                            key: ValueKey(_plan.precio),
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: _blueDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Botón tarjeta
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => RevenueCatPaywallScreen.show(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon:  const Icon(Icons.credit_card),
                      label: const Text('Pago con tarjeta'),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Botón efectivo
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: hasPending || _loading ? null : _sendCashRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: _loading
                          ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                          : const Icon(Icons.payments_outlined),
                      label: Text(hasPending ? 'Solicitud pendiente' : 'Pago en efectivo'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// AUXILIARES
// ─────────────────────────────────────────────

class _ArrowButton extends StatelessWidget {
  final IconData      icon;
  final VoidCallback? onTap;

  const _ArrowButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: onTap != null ? _blueLight : Colors.black12,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: onTap != null ? _blue : Colors.black26,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _blueLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: _blue),
        ),
        const SizedBox(width: 12),
        Text('$label: ', style: const TextStyle(fontSize: 13, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _PaymentHistorySheet extends StatelessWidget {
  final CustomerInfo              customerInfo;
  final String Function(String)   planType;
  final String Function(String?)  formatDate;

  const _PaymentHistorySheet({
    required this.customerInfo,
    required this.planType,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 45, height: 5,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Historial de pagos',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ...customerInfo.nonSubscriptionTransactions.map(
                (t) => _HistoryTile(
              productId: planType(t.productIdentifier),
              date:      formatDate(t.purchaseDate),
              isActive:  false,
            ),
          ),
          if (customerInfo.entitlements.all[_entitlementId] != null)
            _HistoryTile(
              productId: planType(
                customerInfo.entitlements.all[_entitlementId]!.productIdentifier,
              ),
              date:     formatDate(
                customerInfo.entitlements.all[_entitlementId]!.latestPurchaseDate,
              ),
              isActive: true,
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final String productId;
  final String date;
  final bool   isActive;

  const _HistoryTile({
    required this.productId,
    required this.date,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isActive ? _blueLight : const Color(0xFFF5F3F3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            isActive ? Icons.check_circle_outline : Icons.history,
            color: isActive ? _blue : Colors.grey,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(productId)),
          Text(date, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}