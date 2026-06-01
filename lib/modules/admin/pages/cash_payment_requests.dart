import 'package:flutter/material.dart';

class CashPaymentRequestsScreen extends StatefulWidget {
  const CashPaymentRequestsScreen({super.key});

  @override
  State<CashPaymentRequestsScreen> createState() =>
      _CashPaymentRequestsScreenState();
}

class _CashPaymentRequestsScreenState extends State<CashPaymentRequestsScreen> {
  // Datos de prueba (manteniendo tu lógica actual)
  final List<Map<String, String>> _todosLosAlumnos = [
    {
      'nombre': 'Maribel Castillo',
      'inscripcion': '1,500',
      'grupo': 'Cinta Blanca',
    },
    {'nombre': 'Jose Jose', 'inscripcion': '1,500', 'grupo': 'Cinta Blanca'},
    {
      'nombre': 'Nancy Herrera',
      'inscripcion': '1,500',
      'grupo': 'Cinta Blanca',
    },
    {
      'nombre': 'Josue De Vicente',
      'inscripcion': '1,500',
      'grupo': 'Cinta Blanca',
    },
    {
      'nombre': 'Israel García',
      'inscripcion': '1,500',
      'grupo': 'Cinta Amarilla',
    },
  ];

  late List<Map<String, String>> _alumnosMostrados;
  final Set<String> _alumnosSeleccionados = {};

  @override
  void initState() {
    super.initState();
    _alumnosMostrados = List.from(_todosLosAlumnos);
  }

  void _filtrarAlumnos(String query) {
    setState(() {
      _alumnosMostrados =
          query.isEmpty
              ? List.from(_todosLosAlumnos)
              : _todosLosAlumnos
                  .where(
                    (alumno) => alumno['nombre']!.toLowerCase().contains(
                      query.toLowerCase(),
                    ),
                  )
                  .toList();
    });
  }

  void _toggleSeleccion(String nombre) {
    setState(() {
      if (_alumnosSeleccionados.contains(nombre)) {
        _alumnosSeleccionados.remove(nombre);
      } else {
        _alumnosSeleccionados.add(nombre);
      }
    });
  }

  void _procesarPagoIndividual(String nombre, bool aprobado) {
    setState(() {
      _todosLosAlumnos.removeWhere((a) => a['nombre'] == nombre);
      _alumnosMostrados.removeWhere((a) => a['nombre'] == nombre);
      _alumnosSeleccionados.remove(nombre);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          aprobado ? 'Pago de $nombre aprobado.' : 'Solicitud rechazada.',
        ),
        backgroundColor: aprobado ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _confirmarSeleccionados() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Confirmar pagos'),
          content: Text(
            '¿Aprobar el pago de ${_alumnosSeleccionados.length} alumnos?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _todosLosAlumnos.removeWhere(
                    (a) => _alumnosSeleccionados.contains(a['nombre']),
                  );
                  _alumnosMostrados.removeWhere(
                    (a) => _alumnosSeleccionados.contains(a['nombre']),
                  );
                  _alumnosSeleccionados.clear();
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 41, 53, 119),
              ),
              child: const Text(
                'Aprobar todos',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color.fromARGB(255, 41, 53, 119);
    final bool modoMultiSeleccion = _alumnosSeleccionados.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      floatingActionButton:
          modoMultiSeleccion
              ? FloatingActionButton.extended(
                onPressed: _confirmarSeleccionados,
                backgroundColor: primaryColor,
                label: Text(
                  'Aprobar ${_alumnosSeleccionados.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                icon: const Icon(Icons.check, color: Colors.white),
              )
              : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- TARJETA DE CABECERA (ESTILO WALLET) ---
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 8.0,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SOLICITUDES EN EFECTIVO',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Buscador dentro de la tarjeta
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xfff1f3f6),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 2,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            onChanged: _filtrarAlumnos,
                            decoration: const InputDecoration(
                              hintText: 'Buscar alumno...',
                              border: InputBorder.none,
                              hintStyle: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bandeja de entrada',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(
                  height: 4,
                ), // Espacio pequeño entre el título y la instrucción
                Text(
                  'Desliza a la derecha para aprobar, a la izquierda para rechazar, o selecciona varios para procesar en bloque.',
                  style: TextStyle(
                    fontSize: 13, // Tamaño compacto para no saturar la vista
                    color: Colors.grey,
                    height: 1.2, // Ajusta el interlineado para que se lea mejor
                  ),
                ),
              ],
            ),
          ),

          // --- LISTA DE SOLICITUDES ---
          Expanded(
            child:
                _alumnosMostrados.isEmpty
                    ? const Center(
                      child: Text('No hay solicitudes pendientes.'),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.only(
                        left: 20,
                        right: 20,
                        bottom: 100,
                      ),
                      itemCount: _alumnosMostrados.length,
                      itemBuilder: (context, index) {
                        final alumno = _alumnosMostrados[index];
                        final nombre = alumno['nombre']!;
                        final seleccionado = _alumnosSeleccionados.contains(
                          nombre,
                        );

                        return Dismissible(
                          key: Key(nombre),
                          background: _buildSwipeBackground(
                            Colors.green,
                            Icons.check,
                            Alignment.centerLeft,
                          ),
                          secondaryBackground: _buildSwipeBackground(
                            Colors.red,
                            Icons.close,
                            Alignment.centerRight,
                          ),
                          onDismissed:
                              (dir) => _procesarPagoIndividual(
                                nombre,
                                dir == DismissDirection.startToEnd,
                              ),
                          child: _buildStudentCard(
                            alumno,
                            seleccionado,
                            primaryColor,
                            modoMultiSeleccion,
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(
    Map<String, String> alumno,
    bool seleccionado,
    Color primaryColor,
    bool modoMulti,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              seleccionado ? primaryColor : Colors.grey.withValues(alpha: 0.15),
          width: seleccionado ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _toggleSeleccion(alumno['nombre']!),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      seleccionado
                          ? primaryColor.withValues(alpha: 0.1)
                          : Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  seleccionado ? Icons.check : Icons.person_outline,
                  color: seleccionado ? primaryColor : Colors.green,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alumno['nombre']!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      alumno['grupo']!,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Text(
                '\$${alumno['inscripcion']}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeBackground(Color color, IconData icon, Alignment align) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      alignment: align,
      child: Icon(icon, color: Colors.white, size: 30),
    );
  }
}
