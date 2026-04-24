// archivo: forgot_password_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Importación necesaria para enviar el correo

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  // Controlador para atrapar el texto que escribe el usuario
  final _emailController = TextEditingController();
  bool _isLoading = false; // Para mostrar el circulito de carga

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // === LÓGICA PARA ENVIAR EL CORREO ===
  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();

    // 1. Validar que no esté vacío
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingresa tu correo electrónico.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 2. Pedirle a Firebase que envíe el correo de recuperación
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      
      if (mounted) {
        // 3. Mostrar mensaje de éxito y regresar a la pantalla de Login
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Enlace enviado! Revisa tu bandeja de entrada o spam.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); 
      }
    } on FirebaseAuthException catch (e) {
      // 4. Manejo de errores específicos
      String mensaje = 'Ocurrió un error inesperado.';
      if (e.code == 'user-not-found') {
        mensaje = 'No encontramos ninguna cuenta con ese correo.';
      } else if (e.code == 'invalid-email') {
        mensaje = 'El formato del correo es incorrecto.';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensaje), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Recuperar Contraseña', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black), // Flecha de retroceso negra
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const Icon(
                Icons.lock_reset_rounded,
                size: 80,
                color: Color(0xFF344e41),
              ),
              const SizedBox(height: 20),
              const Text(
                'Ingresa el correo electrónico asociado a tu cuenta y te enviaremos un enlace para restablecer tu contraseña.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 30),

              // === CAMPO DE TEXTO PARA EL CORREO ===
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color.fromARGB(98, 52, 78, 65)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 20.0),
                  child: TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'correo@ejemplo.com',
                      icon: Icon(Icons.email_outlined, color: Colors.grey),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // === BOTÓN DE ENVIAR ===
              SizedBox(
                width: double.infinity,
                child: Material(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: _isLoading ? null : _resetPassword,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Enviar enlace',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}