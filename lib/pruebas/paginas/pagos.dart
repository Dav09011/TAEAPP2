import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PagosScreen extends StatefulWidget {
  const PagosScreen({super.key});

  @override
  State<PagosScreen> createState() => _PagosScreenState();
}

class _PagosScreenState extends State<PagosScreen> {
  final List<Map<String, dynamic>> pagos = [
    {'monto': 500.0, 'fecha': DateTime.now(), 'estado': 'Pagado'},
    {
      'monto': 300.0,
      'fecha': DateTime.now().subtract(const Duration(days: 3)),
      'estado': 'Pendiente',
    },
    {
      'monto': 700.0,
      'fecha': DateTime.now().subtract(const Duration(days: 7)),
      'estado': 'Pagado',
    },
  ];

  String formatFecha(DateTime fecha) {
    return DateFormat('dd/MM/yyyy').format(fecha);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Historial de Pagos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: pagos.length,
          itemBuilder: (context, index) {
            final pago = pagos[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
                gradient: LinearGradient(
                  colors:
                      pago['estado'] == 'Pagado'
                          ? [Colors.greenAccent.shade100, Colors.green.shade400]
                          : [Colors.redAccent.shade100, Colors.red.shade400],
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                leading: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(
                    pago['estado'] == 'Pagado'
                        ? Icons.check_circle
                        : Icons.error,
                    color:
                        pago['estado'] == 'Pagado' ? Colors.green : Colors.red,
                    size: 28,
                  ),
                ),
                title: Text(
                  '\$${pago['monto']}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                subtitle: Text(
                  'Fecha: ${formatFecha(pago['fecha'])}',
                  style: const TextStyle(color: Colors.white70),
                ),
                trailing: Text(
                  pago['estado'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Acción futura: agregar un pago
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, size: 30),
      ),
    );
  }
}
