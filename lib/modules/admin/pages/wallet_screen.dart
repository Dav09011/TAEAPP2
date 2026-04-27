import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  bool _isPressed = false;
  String _sucursalSeleccionada = "General";

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color.fromARGB(255, 255, 255, 255);

    return Scaffold(
      backgroundColor: primaryColor,
      // 1. Dejamos el AppBar solo para controles (como el botón de atrás si fuera necesario)
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => _mostrarSelectorSucursales(context),
              onHighlightChanged: (value) {
                // Esto detecta cuando el dedo entra o sale del área
                setState(() {
                  _isPressed = value;
                });
              },
              // 2. EL TÍTULO GIGANTE AQUÍ (Sin cortes y con espacio controlado)
              borderRadius: BorderRadius.circular(15),
              child: AnimatedContainer(
                // 4. AnimatedContainer hace que la sombra crezca suavemente
                duration: const Duration(milliseconds: 150),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 25,
                  horizontal: 25,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    // El borde se oscurece un poco al presionar
                    color:
                        _isPressed
                            ? const Color.fromARGB(
                              255,
                              41,
                              53,
                              119,
                            ).withOpacity(0.5)
                            : Colors.grey.withOpacity(0.2),
                    width: 2.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(_isPressed ? 0.12 : 0.05),
                      // Si está presionado, la sombra es más grande (efecto elevación)
                      blurRadius: _isPressed ? 25 : 15,
                      offset:
                          _isPressed ? const Offset(0, 8) : const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CARTERA',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Icon(
                                Icons.person_outline,
                                size: 20,
                                color: Colors.blueAccent,
                              ),
                              const SizedBox(width: 8),
                              FutureBuilder<DocumentSnapshot>(
                                // 1. Obtenemos el UID del usuario actual
                                future:
                                    FirebaseFirestore.instance
                                        .collection('usuarios')
                                        .doc(
                                          FirebaseAuth
                                              .instance
                                              .currentUser
                                              ?.uid,
                                        )
                                        .get(),
                                builder: (context, snapshot) {
                                  // 2. Mientras carga o si hay error, mostramos algo temporal
                                  if (snapshot.hasError)
                                    return const Text("Error al cargar");
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Text(
                                      "Cargando...",
                                      style: TextStyle(fontSize: 14),
                                    );
                                  }

                                  // 3. Extraemos el nombre del documento de Firestore
                                  // Asegúrate de que en tu base de datos el campo se llame 'nombre'
                                  Map<String, dynamic>? data =
                                      snapshot.data?.data()
                                          as Map<String, dynamic>?;
                                  String nombreUsuario =
                                      data?['nombre'] ?? 'Usuario';

                                  return Text(
                                    'Hola, $nombreUsuario',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[800],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.storefront_rounded,
                          size: 32,
                          color: Color.fromARGB(255, 41, 53, 119),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Sucursales',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            // Tu Dashboard (Este no cambia, se mantiene igual)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: Column(
                // ✅ Cambiamos a Column para poner el título arriba de la Row
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "$_sucursalSeleccionada", // ✅ Título dinámico
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 41, 53, 119),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Divider(), // Una línea sutil divisoria
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryItem("Pagados", "18", Colors.green),
                      _buildSummaryItem("Pendientes", "7", Colors.orange),
                      _buildSummaryItem(
                        "Por Validar",
                        "\$1,200",
                        const Color.fromARGB(255, 41, 53, 119),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Tus tarjetas de acción (Se mantienen igual)
            _buildWalletActionCard(
              context,
              title: 'Pagos en Efectivo',
              subtitle: '3 solicitudes pendientes por revisar',
              icon: Icons.account_balance_wallet_outlined,
              color: Colors.green,
              onTap: () => Navigator.pushNamed(context, '/wallet-fees'),
            ),
            const SizedBox(height: 15),

            _buildWalletActionCard(
              context,
              title: 'Estado de Alumnos',
              subtitle: 'Control de mensualidades y becas',
              icon: Icons.people_alt_outlined,
              color: Colors.blue,
              onTap:
                  () => Navigator.pushNamed(context, '/wallet-student-status'),
            ),
            const SizedBox(height: 15),

            _buildWalletActionCard(
              context,
              title: 'Configurar Tarifas',
              subtitle: 'Gestionar montos y días de clase',
              icon: Icons.settings_outlined,
              color: Colors.purple,
              onTap: () {
                Navigator.pushNamed(context, '/wallet-fees');
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- MÉTODOS AUXILIARES ---
  Widget _buildWalletActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  void _mostrarSelectorSucursales(BuildContext context) {
    final FirebaseFirestore db = FirebaseFirestore.instance;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled:
          true, // Permite que se ajuste si hay muchas sucursales
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.only(top: 15),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Línea de agarre estéticamente minimalista
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: Text(
                  'Seleccionar Sucursal',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              // --- CONEXIÓN DINÁMICA ---
              Flexible(
                child: StreamBuilder<QuerySnapshot>(
                  stream:
                      db.collection('sucursales').orderBy('name').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('Error al cargar datos'),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      );
                    }

                    final docs = snapshot.data!.docs;

                    if (docs.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('No hay sucursales registradas'),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true, // Importante para BottomSheet
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        final String nombre = data['name'] ?? 'Sin nombre';

                        return ListTile(
                          leading: const Icon(
                            Icons.location_on_outlined,
                            color: Color.fromARGB(255, 41, 53, 119),
                          ),
                          title: Text(
                            nombre,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          trailing: const Icon(Icons.chevron_right, size: 20),
                          onTap: () {
                            setState(() {
                              _sucursalSeleccionada = nombre;
                            });
                            // TODO: Aquí guardarías la sucursal seleccionada en una variable global o Provider
                            print("Sucursal elegida: $nombre");

                            Navigator.pop(context); // Cierra el menú

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Viendo finanzas de: $nombre'),
                                duration: const Duration(seconds: 1),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}
