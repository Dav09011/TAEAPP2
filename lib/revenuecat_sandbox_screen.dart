import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

const String _testStoreApiKey = 'test_oIAehahYgamcmFPYMhhEpvoHJls';
const String _entitlementId   = 'TAEAPP Pro';

class _P {
  static const bg          = Color(0xFFFFFFFF);
  static const bgOff       = Color(0xFFF5F5F7);
  static const ink         = Color(0xFF0D0D0D);
  static const inkMid      = Color(0xFF4A4A4A);
  static const inkLight    = Color(0xFF9A9A9A);
  static const red         = Color(0xFFD90429);
  static const redDark     = Color(0xFF9B0320);
  static const redLight    = Color(0xFFFF3352);
  static const redSurface  = Color(0xFFFFF0F2);
  static const success     = Color(0xFF00B371);
}

class RevenueCatPaywallScreen extends StatefulWidget {
  const RevenueCatPaywallScreen({super.key});

  @override
  State<RevenueCatPaywallScreen> createState() => _RevenueCatPaywallScreenState();
}

class _RevenueCatPaywallScreenState extends State<RevenueCatPaywallScreen>
    with TickerProviderStateMixin {

  bool _loading        = true;
  bool _loadingPaywall = false;
  bool _loadingRestore = false;
  String? _error;
  CustomerInfo? _customerInfo;
  bool _isPremium = false;

  late final AnimationController _diagonalAnim;
  late final AnimationController _revealCtrl;
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    _diagonalAnim = AnimationController(
      vsync: this, duration: const Duration(seconds: 8),
    )..repeat();

    _revealCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800),
    );

    _pulseCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _initAndLoad();
    Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdated);
  }

  @override
  void dispose() {
    _diagonalAnim.dispose();
    _revealCtrl.dispose();
    _pulseCtrl.dispose();
    Purchases.removeCustomerInfoUpdateListener(_onCustomerInfoUpdated);
    super.dispose();
  }

  Future<void> _initAndLoad() async {
    setState(() { _loading = true; _error = null; });
    _revealCtrl.reset();
    try {
      if (!await Purchases.isConfigured) {
        await Purchases.setLogLevel(LogLevel.debug);
        await Purchases.configure(PurchasesConfiguration(_testStoreApiKey));
      }
      final info = await Purchases.getCustomerInfo();
      if (!mounted) return;
      setState(() {
        _customerInfo = info;
        _isPremium    = _isActive(info);
        _loading      = false;
      });
      _revealCtrl.forward();
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() { _error = e.message ?? 'Error desconocido'; _loading = false; });
    }
  }

  void _onCustomerInfoUpdated(CustomerInfo info) {
    if (!mounted) return;
    setState(() { _customerInfo = info; _isPremium = _isActive(info); });
  }

  bool _isActive(CustomerInfo info) =>
      info.entitlements.all[_entitlementId]?.isActive == true;

  String _formatExpiry(String? rawDate) {
    if (rawDate == null) return 'Sin expiración';
    try {
      final dt = DateTime.parse(rawDate).toLocal();
      const m = ['','ene','feb','mar','abr','may','jun','jul','ago','sep','oct','nov','dic'];
      return '${dt.day} ${m[dt.month]} ${dt.year}';
    } catch (_) { return rawDate; }
  }

  String _subscriptionType(CustomerInfo info) {
    final id = info.entitlements.all[_entitlementId]?.productIdentifier ?? '';
    if (id.contains('annual') || id.contains('year'))   return 'Anual';
    if (id.contains('month'))                           return 'Mensual';
    if (id.contains('week'))                            return 'Semanal';
    if (id.contains('lifetime') || id.contains('life')) return 'De por vida';
    return id.isNotEmpty ? id : 'Pro';
  }

  Future<void> _showPaywall() async {
    HapticFeedback.mediumImpact();
    setState(() => _loadingPaywall = true);
    final bool wasActive = _isActive(_customerInfo!);
    try {
      final offerings = await Purchases.getOfferings();
      final offering  = offerings.current;
      if (offering == null) { _snack('Sin offering configurado'); return; }
      await RevenueCatUI.presentPaywall(offering: offering);
      await Purchases.invalidateCustomerInfoCache();
      final fresh = await Purchases.getCustomerInfo();
      if (!mounted) return;
      final bool isNowActive = _isActive(fresh);
      setState(() { _customerInfo = fresh; _isPremium = isNowActive; });
      if (!wasActive && isNowActive) {
        await _showSuccessDialog(fresh);
      } else if (wasActive && isNowActive) {
        _snack('Ya tienes el plan ${_subscriptionType(fresh)} activo');
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      _snack('Error: ${e.message}');
    } finally {
      if (mounted) setState(() => _loadingPaywall = false);
    }
  }

  Future<void> _restore() async {
    HapticFeedback.lightImpact();
    setState(() => _loadingRestore = true);
    final bool wasActive = _customerInfo != null ? _isActive(_customerInfo!) : false;
    try {
      await Purchases.invalidateCustomerInfoCache();
      final fresh = await Purchases.restorePurchases();
      if (!mounted) return;
      final bool isNowActive = _isActive(fresh);
      setState(() { _customerInfo = fresh; _isPremium = isNowActive; });
      if (!wasActive && isNowActive) {
        await _showSuccessDialog(fresh);
      } else if (isNowActive) {
        _snack('Plan ${_subscriptionType(fresh)} ya activo');
      } else {
        _snack('Sin compras activas para restaurar');
      }
    } on PlatformException catch (e) {
      _snack('${e.message}');
    } finally {
      if (mounted) setState(() => _loadingRestore = false);
    }
  }

  Future<void> _showSuccessDialog(CustomerInfo info) async {
    HapticFeedback.heavyImpact();
    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) => _SuccessDialog(
        tipo:   _subscriptionType(info),
        expiry: _formatExpiry(info.entitlements.all[_entitlementId]?.expirationDate),
      ),
    );
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: _P.bg, fontWeight: FontWeight.w600)),
      backgroundColor: _P.ink,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _P.bg,
      body: Stack(
        children: [
          _DiagonalPattern(ctrl: _diagonalAnim),
          SafeArea(
            child: Column(children: [
              _TopBar(
                loading: _loading,
                onRefresh: _initAndLoad,
                onDebug: () async {
                  final id = DateTime.now().millisecondsSinceEpoch.toString();
                  await Purchases.logIn(id);
                  await _initAndLoad();
                },
              ),
              Expanded(
                child: _loading
                    ? const _LoadingView()
                    : _error != null
                    ? _ErrorView(message: _error!, onRetry: _initAndLoad)
                    : _Body(
                  customerInfo:     _customerInfo,
                  isPremium:        _isPremium,
                  loadingPaywall:   _loadingPaywall,
                  loadingRestore:   _loadingRestore,
                  formatExpiry:     _formatExpiry,
                  subscriptionType: _subscriptionType,
                  onShowPaywall:    _showPaywall,
                  onRestore:        _restore,
                  revealCtrl:       _revealCtrl,
                  pulseCtrl:        _pulseCtrl,
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _DiagonalPattern extends StatelessWidget {
  final AnimationController ctrl;
  const _DiagonalPattern({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) => CustomPaint(
        size: MediaQuery.of(context).size,
        painter: _DiagPainter(ctrl.value),
      ),
    );
  }
}

class _DiagPainter extends CustomPainter {
  final double t;
  _DiagPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD90429).withOpacity(0.03)
      ..strokeWidth = 32
      ..style = PaintingStyle.stroke;

    final offset = t * 64;
    for (double x = -size.height + offset % 64; x < size.width + size.height; x += 64) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), paint);
    }

    // Triángulo acento superior derecho
    final triPaint = Paint()
      ..color = const Color(0xFFD90429).withOpacity(0.055)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width * 0.55, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.32)
      ..close();
    canvas.drawPath(path, triPaint);
  }

  @override
  bool shouldRepaint(_DiagPainter old) => old.t != t;
}

class _TopBar extends StatelessWidget {
  final bool loading;
  final VoidCallback onRefresh;
  final VoidCallback onDebug;
  const _TopBar({required this.loading, required this.onRefresh, required this.onDebug});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(children: [
        Row(children: [
          Container(width: 6, height: 26,
              decoration: BoxDecoration(color: _P.red, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          const Text('TAE',
              style: TextStyle(color: _P.ink, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const Text(' APP',
              style: TextStyle(color: _P.red, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 2)),
        ]),
        const Spacer(),
        _SmBtn(icon: Icons.refresh_rounded,    onTap: loading ? null : onRefresh),
        const SizedBox(width: 8),
        _SmBtn(icon: Icons.person_off_outlined, onTap: loading ? null : onDebug),
      ]),
    );
  }
}

class _SmBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _SmBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(width: 34, height: 34,
      decoration: BoxDecoration(color: _P.bgOff, borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE0E0E0))),
      child: Icon(icon, size: 16, color: onTap == null ? _P.inkLight : _P.inkMid),
    ),
  );
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) => const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    SizedBox(width: 28, height: 28,
        child: CircularProgressIndicator(strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation(_P.red))),
    SizedBox(height: 14),
    Text('Cargando…', style: TextStyle(color: _P.inkMid, fontSize: 13, letterSpacing: 0.5)),
  ]));
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(32),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 60, height: 60,
        decoration: BoxDecoration(color: _P.redSurface, shape: BoxShape.circle,
            border: Border.all(color: _P.red.withOpacity(0.3))),
        child: const Icon(Icons.error_outline_rounded, color: _P.red, size: 28),
      ),
      const SizedBox(height: 16),
      Text(message, textAlign: TextAlign.center,
          style: const TextStyle(color: _P.ink, fontSize: 14)),
      const SizedBox(height: 6),
      const Text('Verifica tu API key de RevenueCat.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: _P.inkLight)),
      const SizedBox(height: 24),
      _RedButton(label: 'Reintentar', onTap: onRetry),
    ]),
  ));
}

class _Body extends StatelessWidget {
  final CustomerInfo? customerInfo;
  final bool isPremium;
  final bool loadingPaywall;
  final bool loadingRestore;
  final String Function(String?) formatExpiry;
  final String Function(CustomerInfo) subscriptionType;
  final VoidCallback onShowPaywall;
  final VoidCallback onRestore;
  final AnimationController revealCtrl;
  final AnimationController pulseCtrl;

  const _Body({
    required this.customerInfo, required this.isPremium,
    required this.loadingPaywall, required this.loadingRestore,
    required this.formatExpiry, required this.subscriptionType,
    required this.onShowPaywall, required this.onRestore,
    required this.revealCtrl, required this.pulseCtrl,
  });

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _HeroHeader(isPremium: isPremium, revealCtrl: revealCtrl),
      const SizedBox(height: 28),
      _StatusCard(
        customerInfo: customerInfo, isPremium: isPremium,
        formatExpiry: formatExpiry, subscriptionType: subscriptionType,
        revealCtrl: revealCtrl,
      ),
      const SizedBox(height: 24),
      if (!isPremium) ...[
        _BenefitsSection(revealCtrl: revealCtrl),
        const SizedBox(height: 28),
      ],
      _CTAButton(
        loading: loadingPaywall, disabled: loadingRestore,
        isPremium: isPremium, pulseCtrl: pulseCtrl, onTap: onShowPaywall,
      ),
      const SizedBox(height: 12),
      _RestoreBtn(loading: loadingRestore, disabled: loadingPaywall, onTap: onRestore),
      const SizedBox(height: 10),
      const _LegalNote(),
    ]),
  );
}

class _HeroHeader extends StatelessWidget {
  final bool isPremium;
  final AnimationController revealCtrl;
  const _HeroHeader({required this.isPremium, required this.revealCtrl});

  @override
  Widget build(BuildContext context) {
    final slide = Tween<Offset>(begin: const Offset(-0.15, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: revealCtrl, curve: Curves.easeOutCubic));
    final fade  = CurvedAnimation(parent: revealCtrl, curve: const Interval(0, 0.7));

    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: slide,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: _P.red, borderRadius: BorderRadius.circular(4)),
            child: Text(
              isPremium ? 'CINTURÓN NEGRO' : 'MEMBRESÍA PRO',
              style: const TextStyle(color: Colors.white, fontSize: 10,
                  fontWeight: FontWeight.w800, letterSpacing: 2),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isPremium ? 'ACCESO\nCOMPLETO' : 'ENTRENA\nSIN LÍMITES',
            style: const TextStyle(
              color: _P.ink, fontSize: 42,
              fontWeight: FontWeight.w900, height: 1.0, letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isPremium
                ? 'Tu membresía Pro está activa. Sigue entrenando.'
                : 'Accede a todos los programas de la academia.',
            style: const TextStyle(color: _P.inkMid, fontSize: 14, height: 1.5),
          ),
        ]),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final CustomerInfo? customerInfo;
  final bool isPremium;
  final String Function(String?) formatExpiry;
  final String Function(CustomerInfo) subscriptionType;
  final AnimationController revealCtrl;

  const _StatusCard({
    required this.customerInfo, required this.isPremium,
    required this.formatExpiry, required this.subscriptionType,
    required this.revealCtrl,
  });

  String _planLabel(String type) {
    switch (type) {
      case 'Anual':       return 'PLAN ANUAL';
      case 'Mensual':     return 'PLAN MENSUAL';
      case 'Semanal':     return 'PLAN SEMANAL';
      case 'De por vida': return 'DE POR VIDA';
      default:            return type.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final slide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: revealCtrl,
        curve: const Interval(0.15, 1, curve: Curves.easeOutCubic)));
    final fade = CurvedAnimation(parent: revealCtrl, curve: const Interval(0.15, 0.85));

    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: slide,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isPremium ? _P.red : _P.bgOff,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isPremium
                ? [BoxShadow(color: _P.red.withOpacity(0.28), blurRadius: 22, offset: const Offset(0, 8))]
                : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
          ),
          child: Stack(children: [
            if (isPremium) Positioned.fill(child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CustomPaint(painter: _CardAccentPainter()),
            )),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(isPremium ? Icons.verified_rounded : Icons.lock_outline_rounded,
                      color: isPremium ? Colors.white : _P.inkLight, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    isPremium ? 'MEMBRESÍA ACTIVA' : 'SIN MEMBRESÍA',
                    style: TextStyle(
                      color: isPremium ? Colors.white : _P.inkMid,
                      fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2,
                    ),
                  ),
                  const Spacer(),
                  Container(width: 8, height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isPremium ? const Color(0xFF7FFFCA) : _P.inkLight.withOpacity(0.4),
                        boxShadow: isPremium
                            ? [const BoxShadow(color: Color(0x807FFFCA), blurRadius: 8)] : [],
                      )),
                ]),

                if (isPremium && customerInfo != null) ...[
                  const SizedBox(height: 16),
                  Text(_planLabel(subscriptionType(customerInfo!)),
                      style: const TextStyle(color: Colors.white,
                          fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: -0.5, height: 1)),
                  const SizedBox(height: 4),
                  Text(
                    'Expira ${formatExpiry(customerInfo!.entitlements.all[_entitlementId]?.expirationDate)}',
                    style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 12),
                  ),
                ],

                if (!isPremium) ...[
                  const SizedBox(height: 8),
                  const Text('Únete hoy y lleva tu entrenamiento al siguiente nivel.',
                      style: TextStyle(color: _P.inkMid, fontSize: 13, height: 1.4)),
                ],

                if (customerInfo != null) ...[
                  const SizedBox(height: 12),
                  Text('ID ${customerInfo!.originalAppUserId}',
                      style: TextStyle(fontSize: 10, letterSpacing: 0.3,
                          color: isPremium ? Colors.white.withOpacity(0.45) : _P.inkLight),
                      overflow: TextOverflow.ellipsis),
                ],
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _CardAccentPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.07)..style = PaintingStyle.fill;
    canvas.drawPath(Path()
      ..moveTo(size.width * 0.55, size.height)
      ..lineTo(size.width, size.height * 0.1)
      ..lineTo(size.width, size.height)
      ..close(), paint);
  }
  @override bool shouldRepaint(_) => false;
}

class _BenefitsSection extends StatelessWidget {
  final AnimationController revealCtrl;
  const _BenefitsSection({required this.revealCtrl});

  @override
  Widget build(BuildContext context) {
    const benefits = [
      (Icons.play_circle_fill_rounded, 'Clases en video ilimitadas',  'Todos los niveles, sin restricciones.'),
      (Icons.emoji_events_rounded,     'Seguimiento de progreso',     'Registra tus rangos y avances.'),
      (Icons.calendar_month_rounded,   'Agenda de entrenamientos',    'Planea tu semana dojo.'),
      (Icons.support_agent_rounded,    'Soporte prioritario',         'Respuesta directa del equipo.'),
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('QUÉ INCLUYE',
          style: TextStyle(color: _P.ink, fontSize: 11,
              fontWeight: FontWeight.w800, letterSpacing: 2)),
      const SizedBox(height: 14),
      ...benefits.asMap().entries.map((e) {
        final delay = e.key * 0.08;
        final slide = Tween<Offset>(begin: const Offset(0.1, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: revealCtrl,
            curve: Interval(0.3 + delay, 1, curve: Curves.easeOutCubic)));
        final fade = CurvedAnimation(parent: revealCtrl,
            curve: Interval(0.3 + delay, 0.9));
        return FadeTransition(
          opacity: fade,
          child: SlideTransition(
            position: slide,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _BenefitTile(icon: e.value.$1, title: e.value.$2, desc: e.value.$3),
            ),
          ),
        );
      }),
    ]);
  }
}

class _BenefitTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  const _BenefitTile({required this.icon, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: _P.bg,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFEAEAEA)),
    ),
    child: Row(children: [
      Container(width: 40, height: 40,
          decoration: BoxDecoration(color: _P.redSurface, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: _P.red, size: 20)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: _P.ink, fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(desc, style: const TextStyle(color: _P.inkLight, fontSize: 11)),
      ])),
      const Icon(Icons.check_rounded, color: _P.red, size: 18),
    ]),
  );
}

class _CTAButton extends StatelessWidget {
  final bool loading, disabled, isPremium;
  final AnimationController pulseCtrl;
  final VoidCallback onTap;
  const _CTAButton({
    required this.loading, required this.disabled,
    required this.isPremium, required this.pulseCtrl, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = loading || disabled;
    return AnimatedBuilder(
      animation: pulseCtrl,
      builder: (_, child) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: isDisabled ? [] : [
            BoxShadow(
              color: _P.red.withOpacity(0.22 + pulseCtrl.value * 0.18),
              blurRadius: 20, offset: const Offset(0, 6),
            ),
          ],
        ),
        child: child,
      ),
      child: _RedButton(
        label:    loading ? 'Cargando…' : (isPremium ? 'Gestionar mi plan' : 'UNIRME AHORA'),
        icon:     loading ? null : (isPremium ? Icons.manage_accounts_rounded : Icons.arrow_forward_rounded),
        loading:  loading,
        disabled: isDisabled,
        onTap:    onTap,
      ),
    );
  }
}

class _RedButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool loading, disabled;
  final VoidCallback onTap;
  const _RedButton({
    required this.label, this.icon, this.loading = false,
    this.disabled = false, required this.onTap,
  });

  @override
  State<_RedButton> createState() => _RedButtonState();
}

class _RedButtonState extends State<_RedButton> with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  @override
  void initState() {
    super.initState();
    _press = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 90), lowerBound: 0.96, upperBound: 1);
    _press.value = 1;
  }
  @override void dispose() { _press.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown:  widget.disabled ? null : (_) => _press.reverse(),
    onTapUp:    widget.disabled ? null : (_) { _press.forward(); widget.onTap(); },
    onTapCancel: () => _press.forward(),
    child: ScaleTransition(
      scale: _press,
      child: Container(
        width: double.infinity, height: 58,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: widget.disabled ? const Color(0xFFE0E0E0) : _P.red,
        ),
        child: Center(
          child: widget.loading
              ? const SizedBox(width: 22, height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(Colors.white70)))
              : Row(mainAxisSize: MainAxisSize.min, children: [
            Text(widget.label,
                style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.8,
                  color: widget.disabled ? _P.inkLight : Colors.white,
                )),
            if (widget.icon != null) ...[
              const SizedBox(width: 8),
              Icon(widget.icon, size: 18,
                  color: widget.disabled ? _P.inkLight : Colors.white),
            ],
          ]),
        ),
      ),
    ),
  );
}

class _RestoreBtn extends StatelessWidget {
  final bool loading, disabled;
  final VoidCallback onTap;
  const _RestoreBtn({required this.loading, required this.disabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDisabled = loading || disabled;
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: SizedBox(
        width: double.infinity, height: 50,
        child: Center(
          child: loading
              ? const SizedBox(width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(_P.inkLight)))
              : Text('Restaurar compras',
              style: TextStyle(
                fontSize: 14,
                color: isDisabled ? _P.inkLight.withOpacity(0.5) : _P.inkMid,
                decoration: TextDecoration.underline,
                decorationColor: _P.inkLight,
              )),
        ),
      ),
    );
  }
}

class _LegalNote extends StatelessWidget {
  const _LegalNote();
  @override
  Widget build(BuildContext context) => const Text(
    'Al suscribirte aceptas los Términos de Servicio y la Política de Privacidad. '
        'La suscripción se renueva automáticamente.',
    textAlign: TextAlign.center,
    style: TextStyle(fontSize: 10, color: _P.inkLight, height: 1.6),
  );
}

class _SuccessDialog extends StatefulWidget {
  final String tipo, expiry;
  const _SuccessDialog({required this.tipo, required this.expiry});

  @override
  State<_SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<_SuccessDialog> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 650))..forward();
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    final fade  = CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.45));

    return FadeTransition(
      opacity: fade,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.85, end: 1.0).animate(scale),
        child: Dialog(
          backgroundColor: _P.bg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Header rojo con acento diagonal
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: const BoxDecoration(
                color: _P.red,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Stack(alignment: Alignment.center, children: [
                Positioned.fill(child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: CustomPaint(painter: _CardAccentPainter()),
                )),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 48),
                  const SizedBox(height: 8),
                  const Text('¡BIENVENIDO AL DOJO!',
                      style: TextStyle(color: Colors.white, fontSize: 18,
                          fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('PLAN ${widget.tipo.toUpperCase()}',
                        style: const TextStyle(color: Colors.white, fontSize: 11,
                            fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                  ),
                ]),
              ]),
            ),

            // Body
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                Text('Expira: ${widget.expiry}',
                    style: const TextStyle(fontSize: 12, color: _P.inkLight)),
                const SizedBox(height: 20),
                const _BenefitTile(icon: Icons.play_circle_fill_rounded,
                    title: 'Clases ilimitadas', desc: 'Acceso completo a TAEAPP'),
                const SizedBox(height: 8),
                const _BenefitTile(icon: Icons.block_rounded,
                    title: 'Sin anuncios', desc: 'Entrena sin interrupciones'),
                const SizedBox(height: 8),
                const _BenefitTile(icon: Icons.support_agent_rounded,
                    title: 'Soporte prioritario', desc: 'Ayuda directa del equipo'),
                const SizedBox(height: 24),
                _RedButton(label: 'EMPEZAR A ENTRENAR',
                    icon: Icons.arrow_forward_rounded,
                    onTap: () => Navigator.of(context).pop()),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}