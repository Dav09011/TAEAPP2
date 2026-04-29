import 'package:flutter/material.dart';

class AddDialog extends StatefulWidget {
  const AddDialog({super.key});

  @override
  State<AddDialog> createState() => _AddDialogState();
}

class _AddDialogState extends State<AddDialog> {
  final TextEditingController nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
      return  AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Agregar Sucursal',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Nombre de la sucursal
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la Sucursal',
                  labelStyle: TextStyle(color: Colors.blueGrey),
                  border: OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)), // Color del borde normal
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blue,width: 2)),// Color cuando está enfocado
                                    
                ),
              ),
              const SizedBox(height: 12),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F7FB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD7E1EE)),
                ),
                child: const Text(
                  'Las clases y participantes se detectan automaticamente segun los grupos y alumnos registrados en la sucursal.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4B5B70),
                  ),
                ),
              ),
              const SizedBox(height: 12),

            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Cerrar sin hacer nada
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              )
              

            ),
            onPressed: () {
              String name = nameController.text.trim();

              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Por favor llena el nombre'),
                  ),
                );
                return;
              }

              Navigator.of(context).pop({
                "name": name,
              });
            },
            child: const Text('Guardar'),
          ),
        ],
      );
    }
}
