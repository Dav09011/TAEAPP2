import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:tae_app/core/errors/app_exception.dart';
import 'package:tae_app/features/student/domain/entities/student_belt_option.dart';
import 'package:tae_app/features/student/domain/entities/student_profile.dart';
import 'package:tae_app/features/student/domain/entities/update_student_profile_request.dart';
import 'package:tae_app/features/student/presentation/controllers/student_profile_controller.dart';

import '../../shared/presentation/color_customization.dart';

class ProfileScreenStudent extends StatefulWidget {
  const ProfileScreenStudent({super.key});

  @override
  State<ProfileScreenStudent> createState() => _ProfileScreenStudentState();
}

class _ProfileScreenStudentState extends State<ProfileScreenStudent> {
  late final StudentProfileController _controller;
  late final Stream<StudentProfile> _profileStream;

  @override
  void initState() {
    super.initState();
    _controller = StudentProfileController();
    _profileStream = _controller.watchCurrentProfile();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.currentUserId == null) {
      return const Scaffold(body: Center(child: Text('No hay sesion activa.')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EF),
      body: StreamBuilder<StudentProfile>(
        stream: _profileStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${_controller.errorMessage(snapshot.error)}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('No se encontro el perfil.'));
          }

          final profile = snapshot.data!;
          final belt = _normalizeBeltName(profile.personalBelt);
          final beltTheme = _beltThemeForSelection(
            beltLabel: belt,
            colorValue: profile.personalBeltColorValue,
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
                        fullName: profile.fullName,
                        role: profile.role,
                        imageUrl: profile.imageUrl,
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
                                  value: profile.email,
                                  tintColor: beltTheme.primary,
                                ),
                                const SizedBox(height: 12),
                                _InfoCard(
                                  icon: Icons.phone_outlined,
                                  title: 'Telefono',
                                  value: profile.phone,
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
                            final availableBelts = _normalizeAvailableBelts(
                              await _controller.loadAvailableBelts(profile),
                            );
                            if (!context.mounted) {
                              return;
                            }
                            await _showEditProfileDialog(
                              context: context,
                              controller: _controller,
                              profile: profile,
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
                              color: const Color(
                                0xFF8D1515,
                              ).withValues(alpha: 0.25),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.55,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          onPressed: () async {
                            await _controller.signOut();
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
    final heroShadowColor =
        beltTheme.primary.computeLuminance() > 0.88
            ? beltTheme.accent.withValues(alpha: 0.24)
            : beltTheme.primary.withValues(alpha: 0.28);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [beltTheme.primary, beltTheme.secondary],
        ),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(
          color: beltTheme.accent.withValues(alpha: 0.30),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: heroShadowColor,
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
  required StudentProfileController controller,
  required StudentProfile profile,
  required List<StudentBeltOption> availableBelts,
}) async {
  final formKey = GlobalKey<FormState>();
  final nombreController = TextEditingController(text: profile.firstName);
  final apController = TextEditingController(text: profile.lastName);
  final amController = TextEditingController(text: profile.middleName);
  final telefonoController = TextEditingController(text: profile.editablePhone);
  final correoController = TextEditingController(text: profile.editableEmail);
  final normalizedInitialBelt = _normalizeBeltName(profile.personalBelt);
  String selectedBelt = normalizedInitialBelt;
  int? selectedBeltColorValue = profile.personalBeltColorValue;
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
              final result = await controller.updateProfile(
                UpdateStudentProfileRequest(
                  firstName: nombreController.text.trim(),
                  lastName: apController.text.trim(),
                  middleName: amController.text.trim(),
                  phone: telefonoController.text.trim(),
                  personalBelt: selectedBelt,
                  personalBeltColorValue: selectedBeltColorValue,
                  email: trimmedEmail,
                ),
              );

              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }

              if (context.mounted) {
                final emailMessage =
                    result.emailVerificationSent
                        ? ' Revisa tu correo para confirmar el cambio de email.'
                        : '';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Perfil actualizado.$emailMessage')),
                );
              }
            } on AppException catch (error) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(error.message)));
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
                      initialValue: selectedBelt,
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
                                    border: Border.all(
                                      color:
                                          _isVeryLightColor(
                                                beltOption.colorValue,
                                              )
                                              ? const Color(0xFF8F877A)
                                              : Colors.transparent,
                                    ),
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
                        StudentBeltOption? matchedOption;
                        for (final option in _mergeSelectedBeltWithAvailable(
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
                    isSaving ? null : () => Navigator.of(dialogContext).pop(),
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
    final visualTint =
        tintColor.computeLuminance() > 0.88
            ? const Color(0xFF7B6448)
            : tintColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: visualTint.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: visualTint.withValues(alpha: 0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: visualTint.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: visualTint),
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

List<StudentBeltOption> _normalizeAvailableBelts(
  List<StudentBeltOption> belts,
) {
  final beltsByName = <String, StudentBeltOption>{};
  for (final belt in belts) {
    final label = _normalizeBeltName(belt.label);
    if (label.isEmpty) continue;

    final normalizedBelt = StudentBeltOption(
      label: label,
      colorValue: belt.colorValue ?? _defaultStudentBeltColorValue(label),
    );
    final key = label.toLowerCase();
    final existing = beltsByName[key];
    if (existing == null ||
        (existing.colorValue == null && normalizedBelt.colorValue != null)) {
      beltsByName[key] = normalizedBelt;
    }
  }

  return _sortStudentBelts(beltsByName.values.toList());
}

List<StudentBeltOption> _mergeSelectedBeltWithAvailable(
  List<StudentBeltOption> availableBelts,
  String selectedBelt,
) {
  final merged = <StudentBeltOption>[
    ...availableBelts,
    if (selectedBelt.isNotEmpty &&
        !availableBelts.any(
          (value) => value.label.toLowerCase() == selectedBelt.toLowerCase(),
        ))
      StudentBeltOption(
        label: selectedBelt,
        colorValue: _defaultStudentBeltColorValue(selectedBelt),
      ),
  ];
  return _sortStudentBelts(merged);
}

List<StudentBeltOption> _sortStudentBelts(List<StudentBeltOption> belts) {
  final ordered = <StudentBeltOption>[];
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
  if (beltLabel.toLowerCase() == 'blanca' || _isVeryLightColor(colorValue)) {
    return _beltThemeFromName('blanca');
  }

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

bool _isVeryLightColor(int? colorValue) {
  if (colorValue == null) {
    return false;
  }
  return Color(colorValue).computeLuminance() > 0.88;
}

_StudentBeltTheme _beltThemeFromName(String belt) {
  switch (belt.toLowerCase()) {
    case 'blanca':
      return const _StudentBeltTheme(
        primary: Color(0xFFFFFFFF),
        secondary: Color(0xFFD1C5B4),
        accent: Color(0xFF7B6448),
        onPrimary: Color(0xFF241F1A),
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
