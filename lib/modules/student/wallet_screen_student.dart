import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:tae_app/modules/revenuecat/revenuecat_sandbox_screen.dart';

const String _entitlementId = 'TAEAPP Pro';

const _blue      = Color(0xFF4A73B8);
const _blueDark  = Color(0xFF3A5A94);
const _blueLight = Color(0xFFEBF0FA);

// ─────────────────────────────────────────────
// PLANES DE CLASES
// ─────────────────────────────────────────────

class _Plan {
  final int    clases;
  final int    precio;
  final String nombre;
  final String descripcion;
  final IconData icono;

  const _Plan({
    required this.clases,
    required this.precio,
    required this.nombre,
    required this.descripcion,
    required this.icono,
  });
}

const _planes = [
  _Plan(clases: 1, precio: 500,  nombre: '1 clase semanal',     descripcion: 'Ideal para empezar a tu ritmo',            icono: Icons.looks_one_outlined),
  _Plan(clases: 2, precio: 650,  nombre: '2 clases semanales',  descripcion: 'Progreso constante dos veces por semana',   icono: Icons.looks_two_outlined),
  _Plan(clases: 3, precio: 850,  nombre: '3 clases semanales',  descripcion: 'El favorito de nuestros alumnos',           icono: Icons.looks_3_outlined),
  _Plan(clases: 4, precio: 900,  nombre: '4 clases semanales',  descripcion: 'Alta frecuencia para mejores resultados',   icono: Icons.looks_4_outlined),
  _Plan(clases: 5, precio: 1050, nombre: '5+ clases semanales', descripcion: 'Acceso ilimitado a todas las clases',       icono: Icons.all_inclusive),
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

              // HEADER
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
              const SizedBox(height: 20),
              const CashPaymentCard(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// CARD SUSCRIPCIÓN
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

  // Carga inicial sin invalidar caché — más rápido y estable
  // El botón de refresh sí invalida para forzar actualización
  Future<void> _loadSubscription({bool forceRefresh = false}) async {
    setState(() { _loading = true; _error = null; });
    try {
      if (forceRefresh) {
        await Purchases.invalidateCustomerInfoCache();
      }
      final info = await Purchases.getCustomerInfo();
      if (!mounted) return;
      setState(() { _customerInfo = info; _loading = false; });
    } catch (e) {
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
    if (id.contains('annual') || id.contains('year')) return 'Plan anual';
    if (id.contains('month')) return 'Plan mensual';
    if (id.contains('week'))  return 'Plan semanal';
    if (id.contains('life'))  return 'Plan de por vida';
    return productId;
  }

  void _showPaymentHistory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final purchases   = _customerInfo?.nonSubscriptionTransactions ?? [];
        final entitlement = _customerInfo?.entitlements.all[_entitlementId];

        return SafeArea(
          child: Padding(
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
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                if (entitlement != null)
                  _HistoryTile(
                    productId: _planType(entitlement.productIdentifier),
                    date:      _formatDate(entitlement.latestPurchaseDate),
                    isActive:  _isPremium,
                  ),
                ...purchases.map((t) => _HistoryTile(
                  productId: _planType(t.productIdentifier),
                  date:      _formatDate(t.purchaseDate),
                  isActive:  false,
                )),
                if (purchases.isEmpty && entitlement == null)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text('No hay pagos registrados.'),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Banner superior ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: (_isPremium && !_loading) ? _blue : Colors.black,
            borderRadius: const BorderRadius.only(
              topLeft:  Radius.circular(18),
              topRight: Radius.circular(18),
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
                  _isPremium
                      ? Icons.workspace_premium_outlined
                      : Icons.lock_outline,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isPremium ? 'Suscripción activa' : 'Sin suscripción',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      _isPremium ? 'TAEAPP Pro' : 'Obtén acceso premium',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              // Refresh fuerza invalidación
              IconButton(
                onPressed: () => _loadSubscription(forceRefresh: true),
                icon: const Icon(Icons.refresh, color: Colors.white),
              ),
            ],
          ),
        ),

        // ── Cuerpo ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              bottomLeft:  Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
          ),
          child: _loading
              ? const SizedBox.shrink()
              : _error != null
              ? Column(
            children: [
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => _loadSubscription(forceRefresh: true),
                child: const Text('Reintentar'),
              ),
            ],
          )
              : _isPremium
              ? _ActiveBody(
            customerInfo:  _customerInfo!,
            formatDate:    _formatDate,
            planType:      _planType,
            onShowHistory: _showPaymentHistory,
          )
              : _NoSubscriptionBody(
            onShowHistory: _showPaymentHistory,
          ),
        ),
      ],
    );
  }
}

// ── Tiene suscripción ──
class _ActiveBody extends StatelessWidget {
  final CustomerInfo             customerInfo;
  final String Function(String?) formatDate;
  final String Function(String)  planType;
  final VoidCallback             onShowHistory;

  const _ActiveBody({
    required this.customerInfo,
    required this.formatDate,
    required this.planType,
    required this.onShowHistory,
  });

  @override
  Widget build(BuildContext context) {
    final ent = customerInfo.entitlements.all[_entitlementId]!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoRow(icon: Icons.star_outline,             label: 'Plan',   value: planType(ent.productIdentifier)),
        const SizedBox(height: 12),
        _InfoRow(icon: Icons.calendar_today_outlined,  label: 'Expira', value: formatDate(ent.expirationDate)),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onShowHistory,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Colors.black12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon:  const Icon(Icons.history, color: Colors.black54),
            label: const Text('Ver historial de pagos', style: TextStyle(color: Colors.black54)),
          ),
        ),
      ],
    );
  }
}

// ── Sin suscripción ──
class _NoSubscriptionBody extends StatelessWidget {
  final VoidCallback onShowHistory;

  const _NoSubscriptionBody({required this.onShowHistory});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3A5A94), Color(0xFF4A73B8)],
              begin: Alignment.topLeft,
              end:   Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'TAEAPP PRO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Desbloquea tu\npotencial completo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              _BenefitRow(icon: Icons.check_circle_outline, text: 'Acceso a todo el contenido digital'),
              const SizedBox(height: 8),
              _BenefitRow(icon: Icons.check_circle_outline, text: 'Clases presenciales en academia'),
              const SizedBox(height: 8),
              _BenefitRow(icon: Icons.check_circle_outline, text: 'Seguimiento personalizado'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => RevenueCatPaywallScreen.show(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _blueDark,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Suscribirme ahora',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: onShowHistory,
            icon:  const Icon(Icons.history, size: 18, color: Colors.black38),
            label: const Text('Ver historial de pagos', style: TextStyle(color: Colors.black38, fontSize: 13)),
          ),
        ),
      ],
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String   text;
  const _BenefitRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13)),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// CARD PAGO EN EFECTIVO
// ─────────────────────────────────────────────

class CashPaymentCard extends StatelessWidget {
  const CashPaymentCard({super.key});

  void _openPlanSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _PlanSelectorSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.payments_outlined, color: Colors.green.shade700),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pago en efectivo',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Paga directamente en administración.',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Info rápida
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3F3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              children: [
                _CashInfoRow(icon: Icons.storefront_outlined,    title: 'Sucursal',     value: 'Paga directamente con administración'),
                SizedBox(height: 10),
                _CashInfoRow(icon: Icons.receipt_long_outlined,  title: 'Comprobante',  value: 'Tu pago será validado manualmente'),
                SizedBox(height: 10),
                _CashInfoRow(icon: Icons.access_time_outlined,   title: 'Activación',   value: 'La membresía se refleja después de validarse'),
              ],
            ),
          ),

          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openPlanSheet(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              icon:  const Icon(Icons.attach_money),
              label: const Text('Pago en efectivo', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// BOTTOM SHEET — SELECTOR DE PLAN
// ─────────────────────────────────────────────

class _PlanSelectorSheet extends StatefulWidget {
  const _PlanSelectorSheet();

  @override
  State<_PlanSelectorSheet> createState() => _PlanSelectorSheetState();
}

class _PlanSelectorSheetState extends State<_PlanSelectorSheet> {
  int _index = 0;

  _Plan get _plan => _planes[_index];

  void _prev() { if (_index > 0)                  setState(() => _index--); }
  void _next() { if (_index < _planes.length - 1) setState(() => _index++); }

  void _confirm() {
    final planName = _plan.nombre;
    final precio   = _plan.precio;

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Solicitud enviada: $planName — \$$precio MXN'),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          const SizedBox(height: 20),

          // Título
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Selecciona tu plan',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Elige cuántas clases quieres por semana',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),

          const SizedBox(height: 24),

          // Carrusel
          Row(
            children: [
              _ArrowButton(icon: Icons.chevron_left,  onTap: _index > 0 ? _prev : null),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: ScaleTransition(scale: anim, child: child),
                  ),
                  child: _PlanCard(key: ValueKey(_index), plan: _plan),
                ),
              ),
              _ArrowButton(icon: Icons.chevron_right, onTap: _index < _planes.length - 1 ? _next : null),
            ],
          ),

          // Puntos
          const SizedBox(height: 16),
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

          // Resumen plan seleccionado
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _SelectedPlanSummary(key: ValueKey(_index), plan: _plan),
          ),

          const SizedBox(height: 24),

          // Botón confirmar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _confirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text(
                'Confirmar solicitud',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tarjeta del plan ──
class _PlanCard extends StatelessWidget {
  final _Plan plan;
  const _PlanCard({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      decoration: BoxDecoration(
        color: _blueLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(plan.icono, size: 32, color: _blue),
          const SizedBox(height: 10),
          Text(
            plan.nombre.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: _blueDark,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            plan.descripcion,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.black45),
          ),
        ],
      ),
    );
  }
}

// ── Resumen plan seleccionado ──
class _SelectedPlanSummary extends StatelessWidget {
  final _Plan plan;
  const _SelectedPlanSummary({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3F3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _blue.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _blueLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(plan.icono, color: _blue, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Plan seleccionado', style: TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(
                  plan.nombre,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Total', style: TextStyle(fontSize: 11, color: Colors.grey)),
              Text(
                '\$${plan.precio} MXN',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: _blueDark),
              ),
            ],
          ),
        ],
      ),
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
          color: onTap != null ? _blueLight : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: onTap != null ? _blue : Colors.black12),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: _blueLight, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: _blue),
        ),
        const SizedBox(width: 12),
        Text('$label: ', style: const TextStyle(fontSize: 13, color: Colors.grey)),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

class _CashInfoRow extends StatelessWidget {
  final IconData icon;
  final String   title;
  final String   value;
  const _CashInfoRow({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.black54),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final String productId;
  final String date;
  final bool   isActive;
  const _HistoryTile({required this.productId, required this.date, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isActive ? _blueLight : const Color(0xFFF5F3F3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isActive ? _blue : Colors.black12),
      ),
      child: Row(
        children: [
          Icon(
            isActive ? Icons.check_circle_outline : Icons.history,
            color: isActive ? _blue : Colors.grey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              productId,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isActive ? _blueDark : Colors.black87,
              ),
            ),
          ),
          Text(date, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}