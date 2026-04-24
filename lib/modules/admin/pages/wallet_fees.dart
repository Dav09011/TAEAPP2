import 'package:flutter/material.dart';

class WalletFeesPage extends StatelessWidget {
  const WalletFeesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Configurar Tarifas',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: const Center(
        child: Text('Aquí podrás gestionar mensualidades e inscripciones'),
      ),
    );
  }
}
