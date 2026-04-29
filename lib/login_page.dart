import 'package:flutter/material.dart';
import 'package:tae_app/app/router/app_router.dart';
import 'package:tae_app/app/router/app_routes.dart';
import 'package:tae_app/core/errors/app_exception.dart';
import 'package:tae_app/core/models/app_user_role.dart';
import 'package:tae_app/features/auth/presentation/controllers/login_controller.dart';
import 'package:tae_app/modules/admin/pages/branch_selection_tab.dart';
import 'package:tae_app/modules/student/home_page_student.dart';

/// Legacy entrypoint kept temporarily for compatibility while the project
/// migrates to `lib/main.dart`.
///
/// New work should use the centralized bootstrap and router under `app/`.
void main() {
  runApp(const WelcomeTaeApp());
}

/// Transitional app shell.
///
/// This wrapper now delegates route creation to the new centralized router
/// so we do not maintain route definitions in two places.
class WelcomeTaeApp extends StatelessWidget {
  const WelcomeTaeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TAE App',
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.login,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final LoginController _loginController = LoginController();
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _loginController.addListener(_handleControllerChanged);
  }

  @override
  void dispose() {
    _loginController
      ..removeListener(_handleControllerChanged)
      ..dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _signIn() async {
    try {
      final user = await _loginController.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;

      final Widget nextPage =
          user.role == AppUserRole.admin
              ? const MainBranches()
              : const HomePageStudent();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => nextPage),
      );
    } on AppException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: Image.asset(
                      'assets/image/TAE - APP LOGIN.png',
                      width: 460,
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildLoginForm(),
                  const SizedBox(height: 20),
                  _buildRegisterSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 30),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xffd3d3d3), width: 1.5),
        borderRadius: BorderRadius.circular(15),
        color: Colors.white,
      ),
      child: Column(
        children: [
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'correo@gmail.com',
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _passwordController,
            obscureText: _obscureText,
            decoration: InputDecoration(
              labelText: 'Contrasena',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () => setState(() => _obscureText = !_obscureText),
              ),
            ),
          ),
          const SizedBox(height: 30),
          _loginController.isLoading
              ? const CircularProgressIndicator()
              : ElevatedButton(
                onPressed: _signIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Iniciar Sesion',
                  style: TextStyle(color: Colors.white),
                ),
              ),
          TextButton(
            onPressed:
                () => Navigator.pushNamed(context, AppRoutes.forgotPassword),
            child: const Text(
              'Olvidaste tu contrasena?',
              style: TextStyle(
                decoration: TextDecoration.underline,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterSection() {
    return Column(
      children: [
        const Text(
          'No tienes una cuenta?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.typeRegister),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
          child: const Text(
            'Registrate',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
