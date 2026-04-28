// branch_card.dart
import 'package:flutter/material.dart';
import 'package:tae_app/modules/admin/pages/group_selection.dart';
// (3) Aqui es donde se usa el icono realmente.

/*
  > Es el que se encarga de mostrar el diseño de cada tarjeta individual.
  > Recibe un branch (un mapa con datos: nombre, clases, participantes).
  > Dibuja la tarjeta con:
    Un Container con bordes redondeados y sombra.
    A la izquierda: una Column con el texto (nombre, clases, participantes).
    A la derecha: un Icon (personalizable gracias al parámetro icon).
    Está envuelto en un InkWell para que la tarjeta sea clickeable → abre BranchGroupsScreen al tocarla.

  📌 En resumen: “Pinta cómo se ve una sucursal y define qué pasa al tocarla”.
  Es el artista/diseñador de todo el flujo.
 */
class BranchCard extends StatelessWidget {
  final Map<String, dynamic> branch; // Info de la sucursal
  final double maxCardWidth; // Tamaño máximo de la tarjeta
  final IconData icon; // <--- Nuevo parámetro para el ícono
  final VoidCallback? onTap;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;

  const BranchCard({
    super.key,
    required this.branch,
    required this.maxCardWidth,
    required this.icon, // <--- Obligatorio al crear la tarjeta
    this.onTap,
    this.onRename,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      // InkWell le da un efecto visual al tocar (ripple effect) y ejecuta el onTap.
      child: InkWell(
        onTap:
            onTap ??
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => BranchGroupsScreen(
                        branchName: branch['name'],
                        branchDocId: branch['docId'].toString(),
                      ),
                ),
              );
            },

        // Aquí es donde se diseña visualmente cada tarjeta:
        child: Container(
          // width: maxCardWidth y height: 170
          // Tamaño de cada tarjeta.
          // El ancho lo ajusta el LayoutBuilder.
          width: maxCardWidth,
          height: 170, // Aquí se define el alto deseado de la tarjeta
          // Espacio entre cada tarjeta
          margin: const EdgeInsets.only(bottom: 26),

          // Espacio dentro de la tarjeta, para que el texto
          // y contenido no estén pegados a los bordes.
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),

          // Organiza horizontalmente a sus hijos.
          // En este caso tiene dos hijos:
          // Una Column (con los textos)
          // Un Icon
          child: Stack(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            branch['name'],
                            style: const TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${branch["classes"]} clases',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          '${branch["participants"]} participantes',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    icon,
                    size: 50,
                    color: const Color.fromARGB(255, 57, 56, 56),
                  ),
                ],
              ),
              Positioned(
                top: -10,
                right: -10,
                child: PopupMenuButton<String>(
                  tooltip: 'Opciones de sucursal',
                  onSelected: (value) {
                    if (value == 'rename') {
                      onRename?.call();
                    } else if (value == 'delete') {
                      onDelete?.call();
                    }
                  },
                  itemBuilder:
                      (context) => const [
                        PopupMenuItem<String>(
                          value: 'rename',
                          child: Text('Cambiar nombre'),
                        ),
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Text('Borrar sucursal'),
                        ),
                      ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
