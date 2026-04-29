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

  Future<void> _showEditDialog(AdminProfile profile) async {
    final nombreCtrl = TextEditingController(text: profile.firstName);
    final apCtrl = TextEditingController(text: profile.lastName);
    final amCtrl = TextEditingController(text: profile.middleName);
    final telefonoCtrl = TextEditingController(text: profile.phone);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Editar Perfil',
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
                    decoration: const InputDecoration(labelText: 'Telefono'),
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await _controller.updateProfile(
                      UpdateAdminProfileRequest(
                        userId: profile.userId,
                        firstName: nombreCtrl.text,
                        lastName: apCtrl.text,
                        middleName: amCtrl.text,
                        phone: telefonoCtrl.text,
                      ),
                    );
                    if (context.mounted) Navigator.pop(context);
                  } catch (error) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error al guardar: $error')),
                      );
                    }
                  }
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
    );
  }

  Future<void> _showEmailDialog(AdminProfile profile) async {
    final correoCtrl = TextEditingController(text: profile.email);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Cambiar Correo',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Nota: Tu correo es tu credencial de acceso. Si el sistema detecta que iniciaste sesion hace mucho tiempo, te pedira que vuelvas a entrar por seguridad.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: correoCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Nuevo Correo Electronico',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
              ],
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
                    await _controller.requestEmailChange(
                      userId: profile.userId,
                      currentEmail: profile.email,
                      newEmail: correoCtrl.text,
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Revisa la bandeja de tu nuevo correo para confirmar el cambio.',
                          ),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 5),
                        ),
                      );
                    }
                  } on AppException catch (error) {
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(error.message),
                          backgroundColor: Colors.redAccent,
                        ),
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
      return const Scaffold(
        body: Center(child: Text('No hay sesion activa.')),
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
              try {
                final profile = await _controller.getCurrentProfile();
                if (context.mounted) {
                  _showEditDialog(profile);
                }
              } catch (error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $error')),
                  );
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
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.edit_outlined,
                              size: 20,
                              color: Colors.blueAccent,
                            ),
                            onPressed: () => _showEmailDialog(profile),
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
