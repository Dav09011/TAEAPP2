import 'package:flutter/material.dart';
import 'revenuecat_sandbox_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: RevenueCatPaywallScreen(),  // ← Cambiar aquí
  ));
}
