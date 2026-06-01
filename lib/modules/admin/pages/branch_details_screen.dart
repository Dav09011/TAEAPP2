import 'package:flutter/material.dart';

class BranchDetailsScreen extends StatelessWidget {
  final String branchName;

  const BranchDetailsScreen({super.key, required this.branchName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(branchName)),
      body: Center(
        child: Text(
          'Detalles de la sucursal $branchName',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
