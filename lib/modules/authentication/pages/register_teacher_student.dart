import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterTeacherStudent extends StatefulWidget {
  const RegisterTeacherStudent({super.key});
  @override
  State<RegisterTeacherStudent> createState() => _RegisterTeacherStudent();
}

class _RegisterTeacherStudent extends State<RegisterTeacherStudent> {
  final _formKey = GlobalKey<FormState>();
  bool _obscureText = true;

  // === 1. CONTROLADORES (igual que en RegisterAdmin) ===
  final _nombreController = TextEditingController();
  final _apController = TextEditingController();
  final _amController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nombreController.dispose();
    _apController.dispose();
    _amController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // === 2. LÓGICA DE REGISTRO EN FIREBASE ===
  Future<void> _registerStudent() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      // Crear cuenta en Firebase Auth
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final uid = userCredential.user!.uid;

      // Guardar datos en Firestore con tipo 'alumno'
      await FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
        'id_usuario': uid,
        'nombre': _nombreController.text.trim(),
        'ap': _apController.text.trim(),
        'am': _amController.text.trim(),
        'correo': _emailController.text.trim(),
        'telefono': _telefonoController.text.trim(),
        'tipo': 'alumno', // 👈 Diferencia clave vs admin
        'fecha_registro': Timestamp.now(),
        'perfil': {
          'categoria': 'alumno',
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Registro exitoso!'),
            backgroundColor: Colors.green,
          ),
        );
        // 👇 Aquí navegarás a HomePageAlumno cuando la crees
        // Por ahorita solo muestra el snackbar y regresa
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'email-already-in-use') {
        message = 'El correo ya está registrado.';
      } else if (e.code == 'weak-password') {
        message = 'La contraseña es demasiado débil.';
      } else {
        message = 'Error de registro: ${e.message}';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error en base de datos: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error inesperado: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Volver', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(color: Color(0xFFffffff)),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 50),
                  const Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Registro.',
                            style: TextStyle(
                              fontSize: 37,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Todos los campos son obligatorios \npara registrarte correctamente.',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 30),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xffd3d3d3), width: 1.5),
                      borderRadius: BorderRadius.circular(15),
                      color: Colors.white,
                    ),
                    // === 3. FORMULARIO CON CONTROLADORES ===
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          // --- Nombre ---
                          _buildLabel('Nombre'),
                          _buildTextField(
                            controller: _nombreController,
                            hint: 'Ingrese Nombre(s)',
                            formatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                            ],
                          ),
                          const SizedBox(height: 26),

                          // --- Apellido Paterno ---
                          _buildLabel('Apellido Paterno'),
                          _buildTextField(
                            controller: _apController,
                            hint: 'Ingrese su primer apellido',
                          ),
                          const SizedBox(height: 26),

                          // --- Apellido Materno ---
                          _buildLabel('Apellido Materno'),
                          _buildTextField(
                            controller: _amController,
                            hint: 'Ingrese su segundo apellido',
                          ),
                          const SizedBox(height: 26),

                          // --- Email ---
                          _buildLabel('Email'),
                          _buildTextField(
                            controller: _emailController,
                            hint: 'example@gmail.com',
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 26),

                          // --- Teléfono ---
                          _buildLabel('Número de teléfono'),
                          _buildTextField(
                            controller: _telefonoController,
                            hint: '+52',
                            keyboardType: TextInputType.phone,
                            formatters: [LengthLimitingTextInputFormatter(10)],
                          ),
                          const SizedBox(height: 26),

                          // --- Contraseña ---
                          _buildLabel('Contraseña'),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 30),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: const Color.fromARGB(98, 52, 78, 65),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TextFormField(
                                controller: _passwordController,
                                obscureText: _obscureText,
                                decoration: InputDecoration(
                                  hintText: 'mínimo 8 caracteres',
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 18,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureText
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () {
                                      setState(() => _obscureText = !_obscureText);
                                    },
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Campo requerido';
                                  }
                                  final regex = RegExp(
                                    r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[\W_]).{8,}$',
                                  );
                                  if (!regex.hasMatch(value)) {
                                    return 'Debe tener al menos 8 caracteres,\nuna mayúscula, una minúscula,\nun número y un símbolo';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),

                          // --- Botón Confirmar ---
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 30),
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: _registerStudent, // 👈 Llama a Firebase
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'Confirmar',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // === HELPERS para no repetir código ===
  Widget _buildLabel(String text) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 30),
      child: Text(
        text,
        style: GoogleFonts.bebasNeue(fontSize: 20, color: const Color(0xFF344e41)),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color.fromARGB(98, 52, 78, 65)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: formatters,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hint,
            ),
          ),
        ),
      ),
    );
  }
}