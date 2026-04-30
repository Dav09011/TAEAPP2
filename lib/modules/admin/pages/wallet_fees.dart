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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Configurar Tarifas',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 247, 248, 252),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Base de tarifas preparada',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Este corte deja la pantalla lista para crecer sin meter '
                  'reglas de cobro directo en la UI. Por ahora el catalogo es '
                  'semilla y sirve como referencia funcional para la siguiente '
                  'fase del modulo financiero.',
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ..._controller.configurations.map(_buildFeeCard),
          const SizedBox(height: 12),
          const Text(
            'Siguiente paso recomendado: mover este catalogo a un repositorio y '
            'amarrarlo a la sucursal seleccionada cuando definamos el modelo '
            'real de cobros.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
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
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
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
                  color: Color.fromARGB(255, 41, 53, 119),
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
                      ? Colors.green.withOpacity(0.10)
                      : Colors.orange.withOpacity(0.10),
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
