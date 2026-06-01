import 'package:flutter/material.dart';
import 'package:tae_app/app/router/app_routes.dart';
import 'package:tae_app/core/errors/app_exception.dart';
import 'package:tae_app/features/admin/domain/entities/admin_profile.dart';
import 'package:tae_app/features/admin/domain/entities/update_admin_profile_request.dart';
import 'package:tae_app/features/admin/presentation/controllers/profile_controller.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    String? fullName,
    String? email,
    String? phone,
    String? role,
    String? imageUrl,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileController _controller = ProfileController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleControllerChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleControllerChanged)
      ..dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _showCombinedEditDialog(AdminProfile profile) async {
    final nombreCtrl = TextEditingController(text: profile.firstName);
    final apCtrl = TextEditingController(text: profile.lastName);
    final amCtrl = TextEditingController(text: profile.middleName);
    final telefonoCtrl = TextEditingController(text: profile.phone);
    final correoCtrl = TextEditingController(text: profile.email);
    final String correoOriginal = profile.email;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Editar Información',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nombreCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre(s)'),
                  ),
                  TextField(
                    controller: apCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Apellido Paterno',
                    ),
                  ),
                  TextField(
                    controller: amCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Apellido Materno',
                    ),
                  ),
                  TextField(
                    controller: telefonoCtrl,
                    decoration: const InputDecoration(labelText: 'Teléfono'),
                    keyboardType: TextInputType.phone,
                  ),
                  const Divider(height: 30),
                  TextField(
                    controller: correoCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo Electrónico',
                      helperText:
                          'Si lo cambias, deberás confirmarlo en tu nuevo email.',
                      helperMaxLines: 2,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () async {
                  try {
                    // 1. Actualizamos datos generales
                    await _controller.updateProfile(
                      UpdateAdminProfileRequest(
                        userId: profile.userId,
                        firstName: nombreCtrl.text.trim(),
                        lastName: apCtrl.text.trim(),
                        middleName: amCtrl.text.trim(),
                        phone: telefonoCtrl.text.trim(),
                      ),
                    );

                    // 2. Si el correo cambió, lanzamos la petición de cambio
                    final nuevoCorreo = correoCtrl.text.trim();
                    bool correoActualizado = false;

                    if (nuevoCorreo.isNotEmpty &&
                        nuevoCorreo != correoOriginal) {
                      await _controller.requestEmailChange(
                        userId: profile.userId,
                        currentEmail: correoOriginal,
                        newEmail: nuevoCorreo,
                      );
                      correoActualizado = true;
                    }

                    if (context.mounted) {
                      Navigator.pop(context);
                      if (correoActualizado) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Guardado. Revisa tu nuevo correo para confirmar.',
                            ),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 5),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Información actualizada'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  } on AppException catch (error) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(error.message),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  } catch (error) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: $error')));
                    }
                  }
                },
                child: const Text('Guardar Todo'),
              ),
            ],
          ),
    );
  }

  Future<void> _showChangePasswordDialog(String currentEmail) async {
    final passActualCtrl = TextEditingController();
    final passNuevaCtrl = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setStateDialog) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Text(
                  'Cambiar Contraseña',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Por seguridad, ingresa tu contraseña actual antes de crear una nueva.',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: passActualCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña Actual',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: passNuevaCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Nueva Contraseña',
                        prefixIcon: Icon(Icons.lock_reset),
                        helperText: 'Mínimo 6 caracteres',
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: isLoading ? null : () => Navigator.pop(context),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed:
                        isLoading
                            ? null
                            : () async {
                              final passActual = passActualCtrl.text;
                              final passNueva = passNuevaCtrl.text.trim();

                              if (passActual.isEmpty || passNueva.isEmpty) {
                                return;
                              }
                              if (passNueva.length < 6) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'La nueva contraseña debe tener al menos 6 caracteres',
                                    ),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                                return;
                              }

                              setStateDialog(() => isLoading = true);

                              try {
                                await _controller.changePassword(
                                  email: currentEmail,
                                  currentPassword: passActual,
                                  newPassword: passNueva,
                                );
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Contraseña actualizada con éxito. ¡Guárdala bien!',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } on AppException catch (error) {
                                if (context.mounted) {
                                  var message = error.message;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(message),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                }
                              } finally {
                                setStateDialog(() => isLoading = false);
                              }
                            },
                    child:
                        isLoading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : const Text('Actualizar'),
                  ),
                ],
              );
            },
          ),
    );
  }

  Future<void> _signOut() async {
    await _controller.signOut();
    if (mounted) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = _controller.currentUserId;

    if (userId == null) {
      return const Scaffold(body: Center(child: Text('No hay sesion activa.')));
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
              try {
                final profile = await _controller.getCurrentProfile();
                if (context.mounted) {
                  _showCombinedEditDialog(profile);
                }
              } catch (error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $error')));
                }
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<AdminProfile>(
        stream: _controller.watchCurrentProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('No se encontro el perfil.'));
          }

          final profile = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 40),
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[300],
                  backgroundImage:
                      profile.imageUrl.isNotEmpty
                          ? NetworkImage(profile.imageUrl)
                          : null,
                  child:
                      profile.imageUrl.isEmpty
                          ? const Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.grey,
                          )
                          : null,
                ),
                const SizedBox(height: 20),
                Text(
                  profile.fullName.isNotEmpty ? profile.fullName : 'Sin nombre',
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
                    profile.role.toUpperCase(),
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
                            profile.email,
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
                            'Telefono',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          subtitle: Text(
                            profile.phone,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.password_outlined),
                          title: const Text(
                            'Contraseña',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          subtitle: const Text(
                            '********',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.edit_outlined,
                              size: 20,
                              color: Colors.blueAccent,
                            ),
                            onPressed:
                                () => _showChangePasswordDialog(profile.email),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.logout),
                    label: const Text('Cerrar Sesion'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 199, 0, 0),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      textStyle: const TextStyle(fontSize: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _controller.isMutating ? null : _signOut,
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
