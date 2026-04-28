import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tae_app/firebase_options.dart';

import 'package:tae_app/modules/admin/pages/branch_selection_tab.dart';
import 'package:tae_app/modules/authentication/pages/forgot_password_page.dart';
import 'package:tae_app/modules/authentication/pages/type_register.dart';
import 'package:tae_app/modules/authentication/pages/register_admin.dart';
import 'package:tae_app/modules/authentication/pages/register_teacher_student.dart';
import 'package:tae_app/modules/admin/pages/wallet_screen.dart';
import 'package:tae_app/modules/admin/pages/wallet_fees.dart';
import 'package:tae_app/modules/admin/pages/wallet_student_status.dart';
/*
Este importa el paquete material.dart, 
que es parte del framework de Flutter y 
te da acceso a componentes de diseño Material 
(como botones, cajas de texto, AppBar, etc.).
*/
import '../modules/admin/pages/branch_selection_tab.dart';
import '../modules/authentication/pages/forgot_password_page.dart';
import '../modules/authentication/pages/type_register.dart';
import 'package:tae_app/modules/student/home_page_student.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const WelcomeTaeApp());
}

class WelcomeTaeApp extends StatelessWidget {
  const WelcomeTaeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TAE App',
      debugShowCheckedModeBanner: false,

      // ✅ Definimos el punto de entrada mediante el nombre de la ruta
      initialRoute: '/',

      // ✅ Mapa Central de Navegación
      routes: {
        '/': (context) => const LoginPage(),
        '/main-admin': (context) => const MainBranches(),
        '/forgot-password': (context) => const ForgotPasswordPage(),
        '/type-register': (context) => const TypeRegister(),
        '/register-admin': (context) => const RegisterAdmin(),
        '/register-user': (context) => const RegisterTeacherStudent(),
        '/wallet': (context) => const WalletScreen(), // La principal
        '/wallet-fees':
            (context) => const WalletFeesPage(), // La de configuración
        '/wallet-student-status': (context) => const WalletStudentStatusPage(),
      },
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
  bool _isLoading = false;
  bool _obscureText = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, ingresa tu email y contraseña.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      final userDoc =
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(userCredential.user!.uid)
              .get();

      if (userDoc.exists) {
        final userType = userDoc.data()?['tipo'] ?? 'alumno';

        if (mounted) {
          // ✅ USANDO RUTAS NOMBRADAS
          String routeName =
              (userType == 'admin') ? '/main-admin' : '/main-admin';
          Navigator.pushReplacementNamed(context, routeName);
        }
  Widget nextPage;
  
  // 1. LÓGICA DE DECISIÓN: Asignar la página correcta
  if (userType == 'admin') {
    // Si es administrador, va a la pantalla principal de pestañas (MainBranches)
    nextPage = MainBranches(); 
  } else {
    // Si no es admin (es alumno u otro rol), va a la página del alumno
    // Asumiendo que esta clase existe:
    // next_page = const HomePageAlumno(); 

    // 🚨 Como no tenemos la página del alumno, usaremos MainBranches temporalmente
    // O si quieres que falle si no es admin, puedes lanzar un error o ir al login.
    nextPage = HomePageStudent(); // Reemplázalo con HomePageAlumno() cuando esté lista.
  }
  
  // 2. EJECUTAR NAVEGACIÓN REEMPLAZADA con la variable nextPage
  // Usamos pushReplacement para que el Login se elimine de la pila de navegación.
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => nextPage), // << ¡USAR nextPage AQUÍ!
  );
}
      } else {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: Usuario sin perfil asignado.'),
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Error de autenticación';
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        message = 'Email o contraseña incorrectos.';
      }
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
              labelText: 'Contraseña',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () => setState(() => _obscureText = !_obscureText),
              ),
            ),
          ),
          const SizedBox(height: 30),
          _isLoading
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
                  'Iniciar Sesión',
                  style: TextStyle(color: Colors.white),
                ),
              ),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
            child: const Text(
              "¿Olvidaste tu contraseña?",
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
          "¿No tienes una cuenta?",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, '/type-register'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
          child: const Text(
            'Regístrate',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
