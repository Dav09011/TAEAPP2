import 'package:flutter/material.dart';
import 'package:tae_app/app/router/app_routes.dart';
import 'package:tae_app/features/admin/domain/entities/wallet_branch_option.dart';
import 'package:tae_app/features/admin/presentation/controllers/wallet_controller.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

/// Transitional wallet dashboard.
///
/// This cut migrates the admin greeting and branch selector away from direct
/// Firebase usage. Financial summary cards remain static placeholders for now.
class _WalletScreenState extends State<WalletScreen> {
  final WalletController _controller = WalletController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleControllerChanged);
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleControllerChanged)
      ..dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color.fromARGB(255, 255, 255, 255);

    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => _showBranchSelector(context),
              onHighlightChanged: _controller.setPressed,
              borderRadius: BorderRadius.circular(15),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 25,
                  horizontal: 25,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color:
                        _controller.isPressed
                            ? const Color.fromARGB(
                              255,
                              41,
                              53,
                              119,
                            ).withOpacity(0.5)
                            : Colors.grey.withOpacity(0.2),
                    width: 2.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(
                        _controller.isPressed ? 0.12 : 0.05,
                      ),
                      blurRadius: _controller.isPressed ? 25 : 15,
                      offset:
                          _controller.isPressed
                              ? const Offset(0, 8)
                              : const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CARTERA',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Icon(
                                Icons.person_outline,
                                size: 20,
                                color: Colors.blueAccent,
                              ),
                              const SizedBox(width: 8),
                              _controller.isLoadingHeader
                                  ? const Text(
                                    'Cargando...',
                                    style: TextStyle(fontSize: 14),
                                  )
                                  : Text(
                                    'Hola, ${_controller.adminName}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.storefront_rounded,
                          size: 32,
                          color: Color.fromARGB(255, 41, 53, 119),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Sucursales',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    _controller.selectedBranchName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 41, 53, 119),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryItem('Pagados', '18', Colors.green),
                      _buildSummaryItem('Pendientes', '7', Colors.orange),
                      _buildSummaryItem(
                        'Por Validar',
                        '\$1,200',
                        const Color.fromARGB(255, 41, 53, 119),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            _buildWalletActionCard(
              context,
              title: 'Pagos en Efectivo',
              subtitle: '3 solicitudes pendientes por revisar',
              icon: Icons.account_balance_wallet_outlined,
              color: Colors.green,
              onTap: () => Navigator.pushNamed(context, AppRoutes.walletFees),
            ),
            const SizedBox(height: 15),
            _buildWalletActionCard(
              context,
              title: 'Estado de Alumnos',
              subtitle: 'Control de mensualidades y becas',
              icon: Icons.people_alt_outlined,
              color: Colors.blue,
              onTap:
                  () => Navigator.pushNamed(
                    context,
                    AppRoutes.walletStudentStatus,
                  ),
            ),
            const SizedBox(height: 15),
            _buildWalletActionCard(
              context,
              title: 'Configurar Tarifas',
              subtitle: 'Gestionar montos y dias de clase',
              icon: Icons.settings_outlined,
              color: Colors.purple,
              onTap: () => Navigator.pushNamed(context, AppRoutes.walletFees),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  void _showBranchSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.only(top: 15),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: Text(
                  'Seleccionar Sucursal',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Flexible(
                child: StreamBuilder<List<WalletBranchOption>>(
                  stream: _controller.watchBranches(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('Error al cargar datos'),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      );
                    }

                    final branches = snapshot.data ?? const <WalletBranchOption>[];

                    if (branches.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('No hay sucursales registradas'),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: branches.length,
                      itemBuilder: (context, index) {
                        final branch = branches[index];
                        return ListTile(
                          leading: const Icon(
                            Icons.location_on_outlined,
                            color: Color.fromARGB(255, 41, 53, 119),
                          ),
                          title: Text(
                            branch.name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          trailing: const Icon(Icons.chevron_right, size: 20),
                          onTap: () {
                            _controller.selectBranch(branch.name);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Viendo finanzas de: ${branch.name}'),
                                duration: const Duration(seconds: 1),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}
