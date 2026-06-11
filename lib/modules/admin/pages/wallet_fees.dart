import 'package:flutter/material.dart';
import 'package:tae_app/features/admin/domain/entities/admin_wallet_branch_summary.dart';
import 'package:tae_app/features/admin/presentation/controllers/wallet_fees_controller.dart';
import 'package:tae_app/features/payments/domain/entities/payment_tariff.dart';

class WalletFeesPage extends StatefulWidget {
  const WalletFeesPage({super.key});

  @override
  State<WalletFeesPage> createState() => _WalletFeesPageState();
}

class _WalletFeesPageState extends State<WalletFeesPage> {
  final WalletFeesController _controller = WalletFeesController();

  static const Color primaryColor = Color.fromARGB(255, 41, 53, 119);

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
    _controller.bind();
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryColor,
        onPressed: () => _openTariffDialog(context),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nueva tarifa',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 22.0,
              vertical: 10.0,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 16.0,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Colors.grey.withValues(alpha: 0.2),
                  width: 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CONFIGURAR TARIFAS',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tarifas reales del admin, por sucursal y con control de activación.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child:
                _controller.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _controller.tariffs.isEmpty
                    ? const Center(
                      child: Text('Todavía no hay tarifas creadas.'),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      itemCount: _controller.tariffs.length,
                      itemBuilder: (context, index) {
                        return _buildTariffCard(_controller.tariffs[index]);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildTariffCard(PaymentTariff tariff) {
    final isActive = tariff.isActive;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  tariff.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _openTariffDialog(context, existing: tariff);
                  } else if (value == 'toggle') {
                    _controller.saveTariff(
                      tariffId: tariff.id,
                      branchId: tariff.branchId,
                      name: tariff.name,
                      amountCents: tariff.amountCents,
                      currency: tariff.currency,
                      periodType: tariff.periodType,
                      periodCount: tariff.periodCount,
                      groupId: tariff.groupId,
                      description: tariff.description,
                      isActive: !isActive,
                    );
                  } else if (value == 'delete') {
                    _confirmDelete(tariff);
                  }
                },
                itemBuilder:
                    (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Editar')),
                      PopupMenuItem(value: 'toggle', child: Text('Activar / desactivar')),
                      PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                    ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatMoney(tariff.amountCents),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Periodo: ${tariff.periodCount} ${tariff.periodType}',
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Text(
            'Sucursal: ${tariff.branchId}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          if ((tariff.groupId ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Grupo: ${tariff.groupId}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color:
                  isActive
                      ? Colors.green.withValues(alpha: 0.10)
                      : Colors.orange.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              isActive ? 'Activa' : 'Inactiva',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.green[800] : Colors.orange[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(PaymentTariff tariff) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar tarifa'),
          content: Text('¿Seguro que deseas eliminar "${tariff.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _controller.deleteTariff(tariff.id);
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  void _openTariffDialog(
    BuildContext context, {
    PaymentTariff? existing,
  }) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final amountController = TextEditingController(
      text:
          existing == null
              ? ''
              : (existing.amountCents / 100).toStringAsFixed(2),
    );
    final periodCountController = TextEditingController(
      text: existing?.periodCount.toString() ?? '1',
    );
    final descriptionController = TextEditingController(
      text: existing?.description ?? '',
    );
    final groupController = TextEditingController(text: existing?.groupId ?? '');
    String periodType = existing?.periodType ?? 'month';
    bool isActive = existing?.isActive ?? true;
    String? selectedBranchId = existing?.branchId;
    String? selectedGroupId = existing?.groupId;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(existing == null ? 'Nueva tarifa' : 'Editar tarifa'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Monto en pesos',
                          hintText: 'Ej. 500.00',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: periodCountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Cantidad del periodo',
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: periodType,
                        items: const [
                          DropdownMenuItem(value: 'month', child: Text('Mes')),
                          DropdownMenuItem(value: 'week', child: Text('Semana')),
                          DropdownMenuItem(value: 'day', child: Text('Día')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setStateDialog(() => periodType = value);
                          }
                        },
                        decoration: const InputDecoration(labelText: 'Periodo'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: descriptionController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Descripción',
                        ),
                      ),
                      const SizedBox(height: 10),
                      SwitchListTile(
                        value: isActive,
                        onChanged: (value) {
                          setStateDialog(() => isActive = value);
                        },
                        title: const Text('Tarifa activa'),
                      ),
                      const SizedBox(height: 10),
                      StreamBuilder<List<AdminWalletBranchSummary>>(
                        stream: _controller.watchBranches(),
                        builder: (context, snapshot) {
                          final branches =
                              snapshot.data ?? const <AdminWalletBranchSummary>[];
                          if (branches.isEmpty) {
                            return const Text('No hay sucursales disponibles.');
                          }

                          selectedBranchId ??= branches.first.branchId;

                          return DropdownButtonFormField<String>(
                            initialValue: selectedBranchId,
                            items:
                                branches
                                    .map(
                                      (branch) => DropdownMenuItem(
                                        value: branch.branchId,
                                        child: Text(branch.branchName),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (value) {
                              setStateDialog(() => selectedBranchId = value);
                            },
                            decoration: const InputDecoration(
                              labelText: 'Sucursal',
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: groupController,
                        decoration: const InputDecoration(
                          labelText: 'Grupo (opcional)',
                        ),
                        onChanged: (value) =>
                            selectedGroupId =
                                value.trim().isEmpty ? null : value.trim(),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () async {
                    final amount = double.tryParse(
                          amountController.text.trim().replaceAll(',', '.'),
                        ) ??
                        0;
                    await _controller.saveTariff(
                      tariffId: existing?.id,
                      branchId: selectedBranchId ?? '',
                      name: nameController.text.trim(),
                      amountCents: (amount * 100).round(),
                      currency: 'mxn',
                      periodType: periodType,
                      periodCount:
                          int.tryParse(periodCountController.text.trim()) ?? 1,
                      groupId: selectedGroupId,
                      description: descriptionController.text.trim(),
                      isActive: isActive,
                    );
                    if (context.mounted) {
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatMoney(int cents) {
    return '\$${(cents / 100).toStringAsFixed(2)}';
  }
}
