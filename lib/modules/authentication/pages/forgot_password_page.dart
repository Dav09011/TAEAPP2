import 'package:flutter/material.dart';
import 'package:tae_app/core/errors/app_exception.dart';
import 'package:tae_app/features/auth/presentation/controllers/forgot_password_controller.dart';

/// Legacy screen wired to the new auth controller.
///
/// The UI still lives in `modules/`, but the reset-password logic now flows
/// through `features/auth`, which is the target architecture.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final ForgotPasswordController _controller = ForgotPasswordController();

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
    _emailController.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _resetPassword() async {
    try {
      await _controller.sendResetLink(_emailController.text);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enlace enviado. Revisa tu bandeja de entrada o spam.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } on AppException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Recuperar Contrasena',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
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
                'Ingresa el correo electronico asociado a tu cuenta y te enviaremos un enlace para restablecer tu contrasena.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 30),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: const Color.fromARGB(98, 52, 78, 65),
                  ),
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
              SizedBox(
                width: double.infinity,
                child: Material(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: _controller.isLoading ? null : _resetPassword,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child:
                            _controller.isLoading
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
