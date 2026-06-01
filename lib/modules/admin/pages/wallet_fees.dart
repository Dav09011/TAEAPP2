import 'package:flutter/material.dart';
import 'package:tae_app/features/admin/domain/entities/wallet_fee_configuration.dart';
import 'package:tae_app/features/admin/presentation/controllers/wallet_fees_controller.dart';

class WalletFeesPage extends StatefulWidget {
  const WalletFeesPage({super.key});

  @override
  State<WalletFeesPage> createState() => _WalletFeesPageState();
}

class _WalletFeesPageState extends State<WalletFeesPage> {
  final WalletFeesController _controller = WalletFeesController();

  // ✅ SOLUCIÓN: Definimos el color a nivel de clase para usarlo en cualquier parte del archivo
  static const Color primaryColor = Color.fromARGB(255, 41, 53, 119);

  @override
  Widget build(BuildContext context) {
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
          // --- TARJETA DE CABECERA ESTILO WALLET ---
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 22.0,
              vertical: 10.0,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 65.0,
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
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CONFIGURAR TARIFAS',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              children: _controller.configurations.map(_buildFeeCard).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeCard(WalletFeeConfiguration configuration) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  configuration.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                configuration.amountLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color:
                      primaryColor, // ✅ Aquí ya usamos la variable sin errores
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            configuration.scheduleLabel,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(
            configuration.notes,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color:
                  configuration.supportsScholarships
                      ? Colors.green.withValues(alpha: 0.10)
                      : Colors.orange.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              configuration.supportsScholarships
                  ? 'Admite becas o ajustes'
                  : 'Cobro fijo recomendado',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color:
                    configuration.supportsScholarships
                        ? Colors.green[800]
                        : Colors.orange[800],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
