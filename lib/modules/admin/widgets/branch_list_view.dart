import 'package:flutter/material.dart';
import 'package:tae_app/modules/admin/widgets/branch_card.dart';
// (2) CLASE IMPORTANTE PARA LAS TARJETAS -- Recibe el icon de AdaptiveBranchList:
  /*
  > Es el encargado de armar la lista scrollable.
  > Usa ListView.builder para construir la lista de tarjetas dinámicamente.
  > Recorre todas las sucursales (branches) y por cada una crea un BranchCard.
  > No tiene lógica de diseño compleja, solo construye una lista de tarjetas.

  📌 En resumen: “Muestra la lista de sucursales en scroll, pero no decide cómo se ve cada tarjeta”.
  Es básicamente el conector entre los datos y las tarjetas.

  */

class BranchListView extends StatelessWidget {
  const BranchListView({
    super.key,
    required this.branches,
    required this.maxCardWidth,
    // Esto significa: "para construir este widget 
    // necesito que me pases un IconData, y lo voy a guardar automáticamente en una variable interna llamada icon."
    required this.icon, // <--- Nuevo parámetro para el ícono
    this.onTap,
    this.onRename,
    this.onDelete,

  });

  final List<Map<String, dynamic>> branches;
  final double maxCardWidth;
  // Aquí definimos la propiedad interna de la clase que guardará el valor pasado.
  // Como es final, no puede cambiar después de ser asignado (es inmutable).
  final IconData icon; // 👈 propiedad de la clase
  final void Function(String branchName)? onTap;
  final void Function(Map<String, dynamic> branch)? onRename;
  final void Function(Map<String, dynamic> branch)? onDelete;


  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 10),
      itemCount: branches.length,
      itemBuilder: (context, index) {
        final branch = branches[index];
        return BranchCard(
          branch: branch,
          maxCardWidth: maxCardWidth,
          icon: icon,
          onTap: onTap == null ? null : () => onTap!(branch['name'] as String),
          onRename: onRename == null ? null : () => onRename!(branch),
          onDelete: onDelete == null ? null : () => onDelete!(branch),
        );
      },
    );
  }
}
