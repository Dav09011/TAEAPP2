import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatelessWidget {
  // Mantenemos los parámetros por compatibilidad con quien ya lo usa
  // pero ahora los datos reales vienen de Firebase
  const ProfileScreen({
    super.key,
    // Estos parámetros ya no se usan pero los dejamos para no romper
    // las pantallas que ya llaman a ProfileScreen con estos argumentos
    String? fullName,
    String? email,
    String? phone,
    String? role,
    String? imageUrl,
  });

// === FUNCIÓN PARA MOSTRAR EL DIÁLOGO DE EDICIÓN ===
  void _mostrarDialogoEdicion(BuildContext context, Map<String, dynamic> data, String uid) {
    final nombreCtrl = TextEditingController(text: data['nombre'] ?? '');
    final apCtrl = TextEditingController(text: data['ap'] ?? '');
    final amCtrl = TextEditingController(text: data['am'] ?? '');
    final telefonoCtrl = TextEditingController(text: data['telefono'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Editar Perfil', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre(s)')),
              TextField(controller: apCtrl, decoration: const InputDecoration(labelText: 'Apellido Paterno')),
              TextField(controller: amCtrl, decoration: const InputDecoration(labelText: 'Apellido Materno')),
              TextField(controller: telefonoCtrl, decoration: const InputDecoration(labelText: 'Teléfono'), keyboardType: TextInputType.phone),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('usuarios').doc(uid).update({
                'nombre': nombreCtrl.text.trim(),
                'ap': apCtrl.text.trim(),
                'am': amCtrl.text.trim(),
                'telefono': telefonoCtrl.text.trim(),
              });
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  // === FUNCIÓN EXCLUSIVA PARA CAMBIAR EL CORREO ===
  void _mostrarDialogoCorreo(BuildContext context, String correoActual, String uid) {
    final correoCtrl = TextEditingController(text: correoActual);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cambiar Correo', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Nota: Tu correo es tu credencial de acceso. Si el sistema detecta que iniciaste sesión hace mucho tiempo, te pedirá que vuelvas a entrar por seguridad.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: correoCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Nuevo Correo Electrónico',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final nuevoCorreo = correoCtrl.text.trim();
              
              // Evitamos procesar si está vacío o es el mismo correo
              if (nuevoCorreo.isEmpty || nuevoCorreo == correoActual) return;

              try {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  // 1. Usamos el NUEVO método de seguridad obligatorio de Firebase
                  await user.verifyBeforeUpdateEmail(nuevoCorreo);

                  // 2. Actualizamos el texto en la base de datos (Firestore)
                  await FirebaseFirestore.instance.collection('usuarios').doc(uid).update({
                    'correo': nuevoCorreo,
                  });

                  if (context.mounted) {
                    Navigator.pop(context); // Cerramos el cuadro
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Revisa la bandeja de tu NUEVO correo para confirmar el cambio.'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 5), // Le damos más tiempo para leerlo
                      ),
                    );
                  }
                }
              } on FirebaseAuthException catch (e) {
                if (context.mounted) {
                  Navigator.pop(context); // Cerramos el cuadro para mostrar el error
                  String mensaje = 'Error al actualizar el correo.';
                  
                  // Manejo de errores específicos de Firebase
                  if (e.code == 'requires-recent-login') {
                    mensaje = 'Por seguridad, debes cerrar sesión y volver a entrar para hacer este cambio.';
                  } else if (e.code == 'email-already-in-use') {
                    mensaje = 'Este correo ya está registrado en otra cuenta.';
                  } else if (e.code == 'invalid-email') {
                    mensaje = 'El formato del correo es inválido.';
                  }
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(mensaje), backgroundColor: Colors.redAccent),
                  );
                }
              }
            },
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('No hay sesión activa.')),
      );
    }

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 245, 243, 243),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.black),
            onPressed: () async {
              final doc = await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).get();
              if (doc.exists && context.mounted) {
                _mostrarDialogoEdicion(context, doc.data() as Map<String, dynamic>, user.uid);
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          // === Cargando ===
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // === Error ===
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // === Sin datos ===
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('No se encontró el perfil.'));
          }

          // === Datos reales de Firestore ===
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final fullName =
              '${data['nombre'] ?? ''} ${data['ap'] ?? ''} ${data['am'] ?? ''}'
                  .trim();
          final email = data['correo'] ?? 'Sin correo';
          final phone = data['telefono'] ?? 'Sin teléfono';
          final role = data['tipo'] ?? 'Sin rol';
          final imageUrl = data['imagen'] ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 40),

                // === Foto de perfil ===
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: imageUrl.isNotEmpty
                      ? NetworkImage(imageUrl)
                      : null,
                  child: imageUrl.isEmpty
                      ? const Icon(Icons.person, size: 60, color: Colors.grey)
                      : null,
                ),
                const SizedBox(height: 20),

                // === Nombre ===
                Text(
                  fullName.isNotEmpty ? fullName : 'Sin nombre',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),

                // === Rol ===
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    role.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // === Card con info ===
                Card(
                  color: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 15,
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.email_outlined),
                          title: const Text('Correo', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          subtitle: Text(
                            email,
                            style: const TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.w500),
                          ),
                          // === BOTÓN EXCLUSIVO PARA EDITAR CORREO ===
                          trailing: IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blueAccent),
                            onPressed: () => _mostrarDialogoCorreo(context, email, user.uid),
                          ),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.phone_outlined),
                          title: const Text(
                            'Teléfono',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          subtitle: Text(
                            phone,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // === Botón cerrar sesión ===
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.logout),
                    label: const Text('Cerrar Sesión'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 199, 0, 0),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      textStyle: const TextStyle(fontSize: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        // Regresa al login y limpia toda la pila
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/',
                          (route) => false,
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}