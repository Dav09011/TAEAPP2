import 'package:flutter/material.dart';
import 'package:tae_app/features/admin/domain/entities/branch.dart';
import 'package:tae_app/modules/admin/pages/group_selection.dart';

class BranchCard extends StatelessWidget {
  const BranchCard({
    super.key,
    required this.branch,
    required this.maxCardWidth,
    required this.icon,
    this.onTap,
    this.onRename,
    this.onDelete,
  });

  final Branch branch;
  final double maxCardWidth;
  final IconData icon;
  final VoidCallback? onTap;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InkWell(
        onTap:
            onTap ??
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => BranchGroupsScreen(
                        branchName: branch.name,
                        branchDocId: branch.id,
                      ),
                ),
              );
            },
        child: Container(
          width: maxCardWidth,
          height: 170,
          margin: const EdgeInsets.only(bottom: 26),
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
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
                            branch.name,
                            style: const TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${branch.classesCount} clases',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          '${branch.participantsCount} participantes',
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
