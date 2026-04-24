import 'package:flutter/material.dart';
import 'package:tae_app/modules/student/qr_scanner_page.dart';

class HomePageStudent extends StatelessWidget {
  const HomePageStudent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Inicio Alumno',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        onPressed: () {
        Navigator.push(
        context,
        MaterialPageRoute(
        builder: (context) => const QRScannerPage(),
      ),
    );
  },
    child: const Icon(Icons.qr_code_scanner, color: Colors.white),
    tooltip: 'Escanear QR',
    ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 80, color: Colors.black),
            SizedBox(height: 20),
            Text(
              '¡Bienvenido!',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Pantalla de alumno en construcción.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}