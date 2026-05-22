import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../shared/presentation/color_customization.dart';

class ProfileScreenStudent extends StatelessWidget {
  const ProfileScreenStudent({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('No hay sesion activa.')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EF),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream:
            FirebaseFirestore.instance
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
            return const Center(child: Text('No se encontro el perfil.'));
          }

          final data = snapshot.data!.data() ?? {};
          final fullName =
              '${data['nombre'] ?? ''} ${data['ap'] ?? ''} ${data['am'] ?? ''}'
                  .trim();
          final email = data['correo'] ?? user.email ?? 'Sin correo';
          final phone = data['telefono'] ?? 'Sin telefono';
          final belt = _normalizeBeltName(data['cinta_personal']);
          final beltColorValue =
              (data['cinta_personal_color'] as num?)?.toInt();
          final role = data['tipo'] ?? 'alumno';
          final imageUrl = data['imagen'] ?? '';
          final beltTheme = _beltThemeForSelection(
            beltLabel: belt,
            colorValue: beltColorValue,
          );
          final beltLabel = belt.isEmpty ? 'Sin cinta' : belt;

          return Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        beltTheme.primary.withValues(alpha: 0.20),
                        const Color(0xFFF7F4EF),
                        beltTheme.secondary.withValues(alpha: 0.12),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -60,
                left: -40,
                child: _GlowOrb(
                  color: beltTheme.primary,
                  size: 190,
                  blurSigma: 36,
                ),
              ),
              Positioned(
                top: 220,
                right: -50,
                child: _GlowOrb(
                  color: beltTheme.secondary,
                  size: 220,
                  blurSigma: 42,
                ),
              ),
              Positioned(
                bottom: 60,
                left: 20,
                child: _GlowOrb(
                  color: beltTheme.accent,
                  size: 150,
                  blurSigma: 34,
                ),
              ),
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                  child: Column(
                    children: [
                      _buildHeroCard(
                        context: context,
                        fullName: fullName,
                        role: role.toString(),
                        imageUrl: imageUrl.toString(),
                        beltLabel: beltLabel,
                        beltTheme: beltTheme,
                      ),
                      const SizedBox(height: 18),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.72),
                              borderRadius: BorderRadius.circular(32),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.78),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: beltTheme.primary.withValues(
                                    alpha: 0.12,
                                  ),
                                  blurRadius: 26,
                                  offset: const Offset(0, 14),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                _InfoCard(
                                  icon: Icons.email_outlined,
                                  title: 'Correo',
                                  value: email,
                                  tintColor: beltTheme.primary,
                                ),
                                const SizedBox(height: 12),
                                _InfoCard(
                                  icon: Icons.phone_outlined,
                                  title: 'Telefono',
                                  value: phone,
                                  tintColor: beltTheme.secondary,
                                ),
                                const SizedBox(height: 12),
                                _InfoCard(
                                  icon: Icons.sports_martial_arts,
                                  title: 'Cinta',
                                  value: beltLabel,
                                  tintColor: beltTheme.primary,
                                  valueWidget: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            beltTheme.primary,
                                            beltTheme.secondary,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: beltTheme.primary.withValues(
                                              alpha: 0.24,
                                            ),
                                            blurRadius: 18,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        beltLabel,
                                        style: TextStyle(
                                          color: beltTheme.onPrimary,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          icon: const Icon(Icons.auto_awesome_outlined),
                          label: const Text('Editar datos personales'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          onPressed: () async {
                            final availableBelts =
                                await _loadAvailableBeltsForStudent(data);
                            if (!context.mounted) {
                              return;
                            }
                            await _showEditProfileDialog(
                              context: context,
                              user: user,
                              data: data,
                              availableBelts: availableBelts,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.logout),
                          label: const Text('Cerrar sesion'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF8D1515),
                            side: BorderSide(
                              color: const Color(0xFF8D1515).withValues(
                                alpha: 0.25,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.white.withValues(alpha: 0.55),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          onPressed: () async {
                            await FirebaseAuth.instance.signOut();
                            if (context.mounted) {
                              Navigator.of(
                                context,
                              ).pushNamedAndRemoveUntil('/', (route) => false);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeroCard({
    required BuildContext context,
    required String fullName,
    required String role,
    required String imageUrl,
    required String beltLabel,
    required _StudentBeltTheme beltTheme,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            beltTheme.primary,
            beltTheme.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: beltTheme.primary.withValues(alpha: 0.28),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -6,
            right: -18,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left: 90,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.06),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white.withValues(alpha: 0.92),
                    backgroundImage:
                        imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                    child:
                        imageUrl.isEmpty
                            ? Icon(
                              Icons.person,
                              size: 42,
                              color: beltTheme.secondary,
                            )
                            : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.18),
                            ),
                          ),
                          child: Text(
                            role.toUpperCase(),
                            style: TextStyle(
                              color: beltTheme.onPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          fullName.isNotEmpty ? fullName : 'Sin nombre',
                          style: TextStyle(
                            fontSize: 27,
                            height: 1.05,
                            fontWeight: FontWeight.w800,
                            color: beltTheme.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 14,
                          height: 48,
                          decoration: BoxDecoration(
                            color: beltTheme.accent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tu energia actual',
                                style: TextStyle(
                                  color: beltTheme.onPrimary.withValues(
                                    alpha: 0.84,
                                  ),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                beltLabel,
                                style: TextStyle(
                                  color: beltTheme.onPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.auto_awesome,
                          color: beltTheme.onPrimary.withValues(alpha: 0.92),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> _showEditProfileDialog({
  required BuildContext context,
  required User user,
  required Map<String, dynamic> data,
  required List<_StudentBeltOption> availableBelts,
}) async {
  final formKey = GlobalKey<FormState>();
  final nombreController = TextEditingController(
    text: (data['nombre'] ?? '').toString(),
  );
  final apController = TextEditingController(
    text: (data['ap'] ?? '').toString(),
  );
  final amController = TextEditingController(
    text: (data['am'] ?? '').toString(),
  );
  final telefonoController = TextEditingController(
    text: (data['telefono'] ?? '').toString(),
  );
  final correoController = TextEditingController(
    text: (data['correo'] ?? user.email ?? '').toString(),
  );
  final normalizedInitialBelt = _normalizeBeltName(data['cinta_personal']);
  String selectedBelt = normalizedInitialBelt;
  int? selectedBeltColorValue = (data['cinta_personal_color'] as num?)?.toInt();
  for (final option in availableBelts) {
    if (option.label.toLowerCase() == normalizedInitialBelt.toLowerCase()) {
      selectedBeltColorValue ??= option.colorValue;
      break;
    }
  }
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
                    'cinta_personal': selectedBelt,
                    'cinta_personal_color': selectedBeltColorValue,
                    'correo': trimmedEmail,
                  }, SetOptions(merge: true));

              if (trimmedEmail.isNotEmpty && trimmedEmail != user.email) {
                await user.verifyBeforeUpdateEmail(trimmedEmail);
              }

              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }

              if (context.mounted) {
                final emailMessage =
                    trimmedEmail != user.email
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
                      validator:
                          (value) =>
                              value == null || value.trim().isEmpty
                                  ? 'Ingresa tu nombre'
                                  : null,
                    ),
                    TextFormField(
                      controller: apController,
                      decoration: const InputDecoration(
                        labelText: 'Apellido paterno',
                      ),
                    ),
                    TextFormField(
                      controller: amController,
                      decoration: const InputDecoration(
                        labelText: 'Apellido materno',
                      ),
                    ),
                    TextFormField(
                      controller: telefonoController,
                      decoration: const InputDecoration(labelText: 'Telefono'),
                      keyboardType: TextInputType.phone,
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedBelt,
                      decoration: const InputDecoration(labelText: 'Cinta'),
                      items: [
                        const DropdownMenuItem<String>(
                          value: '',
                          child: Text('Sin cinta'),
                        ),
                        ..._mergeSelectedBeltWithAvailable(
                          availableBelts,
                          selectedBelt,
                        ).map(
                          (beltOption) => DropdownMenuItem<String>(
                            value: beltOption.label,
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color:
                                        beltOption.colorValue != null
                                            ? Color(beltOption.colorValue!)
                                            : const Color(0xFFD9D0C3),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(beltOption.label),
                              ],
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        _StudentBeltOption? matchedOption;
                        for (final option
                            in _mergeSelectedBeltWithAvailable(
                              availableBelts,
                              selectedBelt,
                            )) {
                          if (option.label.toLowerCase() ==
                              (value ?? '').toLowerCase()) {
                            matchedOption = option;
                            break;
                          }
                        }
                        setState(() {
                          selectedBelt = value ?? '';
                          selectedBeltColorValue = matchedOption?.colorValue;
                        });
                      },
                    ),
                    TextFormField(
                      controller: correoController,
                      decoration: const InputDecoration(labelText: 'Correo'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (email.isEmpty) return 'Ingresa tu correo';
                        if (!email.contains('@')) return 'Correo invalido';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed:
                    isSaving
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
                child:
                    isSaving
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

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.tintColor,
    this.valueWidget,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color tintColor;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tintColor.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: tintColor.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: tintColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: tintColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6D6761),
                  ),
                ),
                const SizedBox(height: 6),
                valueWidget ??
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF231F1C),
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<List<_StudentBeltOption>> _loadAvailableBeltsForStudent(
  Map<String, dynamic> userData,
) async {
  final branchId = await _resolveStudentBranchId(userData);
  if (branchId.isEmpty) {
    return const <_StudentBeltOption>[];
  }

  final branchSnapshot =
      await FirebaseFirestore.instance.collection('sucursales').doc(branchId).get();
  final branchData = branchSnapshot.data();
  final savedBelts = branchData?['available_belts'];
  if (savedBelts is! List) {
    return const <_StudentBeltOption>[];
  }

  final belts = <_StudentBeltOption>[];
  for (final value in savedBelts) {
    if (value is Map) {
      final label = _normalizeBeltName(value['label']);
      if (label.isEmpty) continue;
      belts.add(
        _StudentBeltOption(
          label: label,
          colorValue: (value['color_value'] as num?)?.toInt(),
        ),
      );
      continue;
    }

    final label = _normalizeBeltName(value);
    if (label.isEmpty) continue;
    belts.add(
      _StudentBeltOption(
        label: label,
        colorValue: _defaultStudentBeltColorValue(label),
      ),
    );
  }
  return belts.isEmpty ? const <_StudentBeltOption>[] : _sortStudentBelts(belts);
}

Future<String> _resolveStudentBranchId(Map<String, dynamic> userData) async {
  final currentGroupId = userData['grupo_id']?.toString().trim() ?? '';
  if (currentGroupId.isNotEmpty) {
    final groupSnapshot =
        await FirebaseFirestore.instance.collection('grupos').doc(currentGroupId).get();
    final branchId = groupSnapshot.data()?['id_sucursal']?.toString().trim() ?? '';
    if (branchId.isNotEmpty) {
      return branchId;
    }
  }

  final savedGroups = userData['grupos'];
  if (savedGroups is List) {
    for (final group in savedGroups) {
      if (group is! Map) continue;
      final groupMap = Map<String, dynamic>.from(group);
      final branchId = groupMap['branchId']?.toString().trim() ?? '';
      if (branchId.isNotEmpty) {
        return branchId;
      }
    }
  }

  final branchName = userData['grupo_sucursal']?.toString().trim() ?? '';
  if (branchName.isNotEmpty) {
    final branchQuery =
        await FirebaseFirestore.instance
            .collection('sucursales')
            .where('name', isEqualTo: branchName)
            .limit(1)
            .get();
    if (branchQuery.docs.isNotEmpty) {
      return branchQuery.docs.first.id;
    }
  }

  return '';
}

List<_StudentBeltOption> _mergeSelectedBeltWithAvailable(
  List<_StudentBeltOption> availableBelts,
  String selectedBelt,
) {
  final merged = <_StudentBeltOption>[
    ...availableBelts,
    if (selectedBelt.isNotEmpty &&
        !availableBelts.any(
          (value) => value.label.toLowerCase() == selectedBelt.toLowerCase(),
        ))
      _StudentBeltOption(
        label: selectedBelt,
        colorValue: _defaultStudentBeltColorValue(selectedBelt),
      ),
  ];
  return _sortStudentBelts(merged);
}

List<_StudentBeltOption> _sortStudentBelts(List<_StudentBeltOption> belts) {
  final ordered = <_StudentBeltOption>[];
  for (final option in kTaeKwonDoBeltColorOptions) {
    for (final belt in belts) {
      if (belt.label.toLowerCase() == option.label.toLowerCase()) {
        ordered.add(belt);
      }
    }
  }
  for (final belt in belts) {
    if (!ordered.any(
      (value) => value.label.toLowerCase() == belt.label.toLowerCase(),
    )) {
      ordered.add(belt);
    }
  }
  return ordered;
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.color,
    required this.size,
    required this.blurSigma,
  });

  final Color color;
  final double size;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.28),
        ),
      ),
    );
  }
}

class _StudentBeltTheme {
  const _StudentBeltTheme({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.onPrimary,
  });

  final Color primary;
  final Color secondary;
  final Color accent;
  final Color onPrimary;
}

class _StudentBeltOption {
  const _StudentBeltOption({
    required this.label,
    this.colorValue,
  });

  final String label;
  final int? colorValue;
}

String _normalizeBeltName(Object? beltValue) {
  final belt = beltValue?.toString().trim() ?? '';
  if (belt.isEmpty) {
    return '';
  }

  final lower = belt.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  for (final option in kTaeKwonDoBeltColorOptions) {
    if (option.label.toLowerCase() == lower) {
      return option.label;
    }
  }

  switch (lower) {
    case 'blanca':
    case 'white':
      return 'Blanca';
    case 'amarilla':
    case 'yellow':
      return 'Amarilla';
    case 'naranja':
    case 'orange':
      return 'Naranja';
    case 'verde':
    case 'green':
      return 'Verde';
    case 'azul':
    case 'blue':
      return 'Azul';
    case 'morada':
    case 'purple':
      return 'Morada';
    case 'roja':
    case 'red':
      return 'Roja';
    case 'roja/negra':
    case 'roja negra':
    case 'red/black':
    case 'red black':
      return 'Roja/Negra';
    case 'negra':
    case 'black':
      return 'Negra';
  }
  return belt;
}

int? _defaultStudentBeltColorValue(String belt) {
  for (final option in kTaeKwonDoBeltColorOptions) {
    if (option.label.toLowerCase() == belt.toLowerCase()) {
      return option.colorValue;
    }
  }
  for (final option in kPresetColorOptions) {
    if (option.label.toLowerCase() == belt.toLowerCase()) {
      return option.colorValue;
    }
  }
  return null;
}

_StudentBeltTheme _beltThemeForSelection({
  required String beltLabel,
  required int? colorValue,
}) {
  if (colorValue == null) {
    return _beltThemeFromName(beltLabel);
  }

  final primary = Color(colorValue);
  final brightness = ThemeData.estimateBrightnessForColor(primary);
  final onPrimary =
      brightness == Brightness.dark ? Colors.white : const Color(0xFF231F1C);
  final secondary =
      brightness == Brightness.dark
          ? Color.alphaBlend(Colors.black.withValues(alpha: 0.28), primary)
          : Color.alphaBlend(Colors.white.withValues(alpha: 0.22), primary);
  final accent =
      brightness == Brightness.dark
          ? Color.alphaBlend(Colors.white.withValues(alpha: 0.34), primary)
          : Color.alphaBlend(Colors.black.withValues(alpha: 0.08), primary);

  return _StudentBeltTheme(
    primary: primary,
    secondary: secondary,
    accent: accent,
    onPrimary: onPrimary,
  );
}

_StudentBeltTheme _beltThemeFromName(String belt) {
  switch (belt.toLowerCase()) {
    case 'blanca':
      return const _StudentBeltTheme(
        primary: Color(0xFFF6F1E7),
        secondary: Color(0xFFE2D8C8),
        accent: Color(0xFFB9A88E),
        onPrimary: Color(0xFF2D261F),
      );
    case 'amarilla':
      return const _StudentBeltTheme(
        primary: Color(0xFFF7D64A),
        secondary: Color(0xFFF4B73F),
        accent: Color(0xFFFFF0AA),
        onPrimary: Color(0xFF3D2D00),
      );
    case 'naranja':
      return const _StudentBeltTheme(
        primary: Color(0xFFF39A2B),
        secondary: Color(0xFFE36B2C),
        accent: Color(0xFFFFD2A8),
        onPrimary: Colors.white,
      );
    case 'verde':
      return const _StudentBeltTheme(
        primary: Color(0xFF2E8B57),
        secondary: Color(0xFF185C3C),
        accent: Color(0xFFA8E4B6),
        onPrimary: Colors.white,
      );
    case 'azul':
      return const _StudentBeltTheme(
        primary: Color(0xFF2D7BD8),
        secondary: Color(0xFF184F9A),
        accent: Color(0xFFA7D0FF),
        onPrimary: Colors.white,
      );
    case 'morada':
      return const _StudentBeltTheme(
        primary: Color(0xFF7A4BC7),
        secondary: Color(0xFF4B247F),
        accent: Color(0xFFD6C0FF),
        onPrimary: Colors.white,
      );
    case 'roja':
      return const _StudentBeltTheme(
        primary: Color(0xFFD33A36),
        secondary: Color(0xFF7E1818),
        accent: Color(0xFFFFB2A8),
        onPrimary: Colors.white,
      );
    case 'roja/negra':
      return const _StudentBeltTheme(
        primary: Color(0xFF7B1E23),
        secondary: Color(0xFF171717),
        accent: Color(0xFFD89A9A),
        onPrimary: Colors.white,
      );
    case 'negra':
      return const _StudentBeltTheme(
        primary: Color(0xFF262626),
        secondary: Color(0xFF090909),
        accent: Color(0xFF6A6A6A),
        onPrimary: Colors.white,
      );
    default:
      return const _StudentBeltTheme(
        primary: Color(0xFF8F7AE5),
        secondary: Color(0xFF534392),
        accent: Color(0xFFD6CAFF),
        onPrimary: Colors.white,
      );
  }
}
