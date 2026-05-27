
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';


const String _testStoreApiKey = 'test_oIAehahYgamcmFPYMhhEpvoHJls';
const String _entitlementId   = 'TAEAPP Pro';

class RevenueCatPaywallScreen extends StatefulWidget {
  const RevenueCatPaywallScreen({super.key});

  static Future<void> show(BuildContext context) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RevenueCatPaywallScreen()),
    );
  }

  @override
  State<RevenueCatPaywallScreen> createState() => _RevenueCatPaywallScreenState();
}

class _RevenueCatPaywallScreenState extends State<RevenueCatPaywallScreen> {

  @override
  void initState() {
    super.initState();
    _initAndShowPaywall();
  }

  Future<void> _initAndShowPaywall() async {
    try {
      // Configura RevenueCat si aún no está inicializado
      if (!await Purchases.isConfigured) {
        await Purchases.setLogLevel(LogLevel.debug);
        await Purchases.configure(PurchasesConfiguration(_testStoreApiKey));
      }

      final offerings = await Purchases.getOfferings();
      final offering  = offerings.current;

      if (offering == null) {
        _snack('No hay planes disponibles por el momento.', isError: true);
        if (mounted) Navigator.pop(context);
        return;
      }

      // Abre el paywall nativo de RevenueCat
      HapticFeedback.mediumImpact();
      await RevenueCatUI.presentPaywall(offering: offering);

      // Al cerrarse el paywall, verifica el estado de la compra
      await Purchases.invalidateCustomerInfoCache();
      final info      = await Purchases.getCustomerInfo();
      final isPremium = info.entitlements.all[_entitlementId]?.isActive == true;

      if (!mounted) return;

      if (isPremium) {
        // Compra exitosa
        HapticFeedback.heavyImpact();
        _snack('¡Membresía activada con éxito!', isError: false);
      } else {
        // Cerró el paywall sin comprar
        _snack('No se completó ninguna compra.', isError: true);
      }

    } on PlatformException catch (e) {
      if (!mounted) return;

      final code = e.code;
      String mensaje;

      switch (code) {
        case '1':  mensaje = 'Compra cancelada.'; break;
        case '2':  mensaje = 'Error de red. Verifica tu conexión.'; break;
        case '3':  mensaje = 'Producto no disponible en la tienda.'; break;
        case '4':  mensaje = 'Compra no permitida en este dispositivo.'; break;
        case '5':  mensaje = 'Este producto ya fue comprado.'; break;
        case '6':  mensaje = 'Recibo inválido. Contacta a soporte.'; break;
        default:   mensaje = e.message ?? 'Error desconocido. Intenta de nuevo.';
      }

      _snack(mensaje, isError: true);

    } finally {
      if (mounted) Navigator.pop(context);
    }
  }

  void _snack(String msg, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,

      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(Color(0xFFD90429)),
        ),
      ),
    );
  }
}