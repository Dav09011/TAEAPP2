import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

const String _androidApiKey = "goog_TU_CLAVE_AQUI";
const String _iosApiKey = "appl_TU_CLAVE_AQUI";

class RevenueCatTestScreen extends StatefulWidget {
  const RevenueCatTestScreen({super.key});

  @override
  State<RevenueCatTestScreen> createState() => _RevenueCatTestScreenState();
}

class _RevenueCatTestScreenState extends State<RevenueCatTestScreen> {
  bool _isConfigured = false;
  bool _isLoading = true;
  String _statusMessage = "Configurando SDK...";

  @override
  void initState() {
    super.initState();
    _configureSDK();
  }

  Future<void> _configureSDK() async {
    try {
      await Purchases.setLogLevel(LogLevel.debug);

      await Purchases.configure(PurchasesConfiguration(_androidApiKey));

      if (mounted) {
        setState(() {
          _isConfigured = true;
          _statusMessage = "SDK listo. Obteniendo ofertas...";
        });
        _fetchOfferings();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = "Error al configurar: $e";
        });
      }
    }
  }

  Future<void> _fetchOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (offerings.current != null) {
            _statusMessage = "Oferta '${offerings.current!.identifier}' lista para mostrar.";
          } else {
            _statusMessage = "No se encontraron ofertas. Revisa el dashboard de RevenueCat.";
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = "Error al obtener ofertas: $e";
        });
      }
    }
  }

  Future<void> _presentPaywall() async {
    try {
      await RevenueCatUI.presentPaywall();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error mostrando paywall: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Prueba RevenueCat")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading)
                const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 30),
              // Botón para probar el paywall
              ElevatedButton(
                onPressed: (_isConfigured && !_isLoading) ? _presentPaywall : null,
                child: const Text("Mostrar Paywall de Prueba"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    home: RevenueCatTestScreen(),
  ));
}