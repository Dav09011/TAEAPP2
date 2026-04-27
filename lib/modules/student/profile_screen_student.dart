import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileScreenStudent extends StatelessWidget {
  const ProfileScreenStudent({super.key});

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
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('No se encontró el perfil.'));
          }

          final data = snapshot.data!.data() ?? {};
          final fullName =
              '${data['nombre'] ?? ''} ${data['ap'] ?? ''} ${data['am'] ?? ''}'
                  .trim();
          final email = data['correo'] ?? user.email ?? 'Sin correo';
          final phone = data['telefono'] ?? 'Sin teléfono';
          final role = data['tipo'] ?? 'alumno';
          final imageUrl = data['imagen'] ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 40),
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: imageUrl.toString().isNotEmpty
                      ? NetworkImage(imageUrl)
                      : null,
                  child: imageUrl.toString().isEmpty
                      ? const Icon(Icons.person, size: 60, color: Colors.grey)
                      : null,
                ),
                const SizedBox(height: 20),
                Text(
                  fullName.isNotEmpty ? fullName : 'Sin nombre',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
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
                    role.toString().toUpperCase(),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
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
                          title: const Text(
                            'Correo',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          subtitle: Text(
                            email,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.phone_outlined),
                          title: const Text(
                            'Teléfono',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
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
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Editar datos personales'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Colors.black12),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => _showEditProfileDialog(
                      context: context,
                      user: user,
                      data: data,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
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

Future<void> _showEditProfileDialog({
  required BuildContext context,
  required User user,
  required Map<String, dynamic> data,
}) async {
  final formKey = GlobalKey<FormState>();
  final nombreController =
      TextEditingController(text: (data['nombre'] ?? '').toString());
  final apController =
      TextEditingController(text: (data['ap'] ?? '').toString());
  final amController =
      TextEditingController(text: (data['am'] ?? '').toString());
  final telefonoController =
      TextEditingController(text: (data['telefono'] ?? '').toString());
  final correoController = TextEditingController(
    text: (data['correo'] ?? user.email ?? '').toString(),
  );
  var isSaving = false;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          Future<void> saveProfile() async {
            if (!(formKey.currentState?.validate() ?? false) || isSaving) {
              return;
            }

            setState(() => isSaving = true);
            final trimmedEmail = correoController.text.trim();

            try {
              await FirebaseFirestore.instance
                  .collection('usuarios')
                  .doc(user.uid)
                  .set({
                'nombre': nombreController.text.trim(),
                'ap': apController.text.trim(),
                'am': amController.text.trim(),
                'telefono': telefonoController.text.trim(),
                'correo': trimmedEmail,
              }, SetOptions(merge: true));

              if (trimmedEmail.isNotEmpty && trimmedEmail != user.email) {
                await user.verifyBeforeUpdateEmail(trimmedEmail);
              }

              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }

              if (context.mounted) {
                final emailMessage = trimmedEmail != user.email
                    ? ' Revisa tu correo para confirmar el cambio de email.'
                    : '';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Perfil actualizado.$emailMessage'),
                  ),
                );
              }
            } on FirebaseAuthException catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Se guardaron tus datos, pero no se pudo actualizar el correo: ${e.message}',
                    ),
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('No se pudo actualizar tu perfil: $e'),
                  ),
                );
              }
            } finally {
              if (dialogContext.mounted) {
                setState(() => isSaving = false);
              }
            }
          }

          return AlertDialog(
            title: const Text('Editar datos personales'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nombreController,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Ingresa tu nombre'
                              : null,
                    ),
                    TextFormField(
                      controller: apController,
                      decoration:
                          const InputDecoration(labelText: 'Apellido paterno'),
                    ),
                    TextFormField(
                      controller: amController,
                      decoration:
                          const InputDecoration(labelText: 'Apellido materno'),
                    ),
                    TextFormField(
                      controller: telefonoController,
                      decoration: const InputDecoration(labelText: 'Teléfono'),
                      keyboardType: TextInputType.phone,
                    ),
                    TextFormField(
                      controller: correoController,
                      decoration: const InputDecoration(labelText: 'Correo'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (email.isEmpty) return 'Ingresa tu correo';
                        if (!email.contains('@')) return 'Correo inválido';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving
                    ? null
                    : () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: isSaving ? null : saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                child: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Guardar'),
              ),
            ],
          );
        },
      );
    },
  );
}
