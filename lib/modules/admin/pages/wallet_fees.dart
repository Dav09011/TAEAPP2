import 'package:flutter/material.dart';
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
        onPressed: () => _openTariffSheet(context),
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
            padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Colors.grey.withValues(alpha: 0.2),
                  width: 2,
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
                    'Gestiona precios por sucursal. La activacion se controla desde cada tarjeta.',
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
                      child: Text('Todavia no hay tarifas creadas.'),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 92),
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
    final branchName = _controller.branchNameFor(tariff.branchId);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.payments_outlined, color: primaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tariff.name.isEmpty ? 'Tarifa sin nombre' : tariff.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      branchName,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _openTariffSheet(context, existing: tariff);
                  } else if (value == 'delete') {
                    _confirmDelete(tariff);
                  }
                },
                itemBuilder:
                    (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Editar')),
                      PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                    ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _TariffInfoPill(
                  label: 'Monto',
                  value: _formatMoney(tariff.amountCents),
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TariffInfoPill(
                  label: 'Periodo',
                  value:
                      '${tariff.periodCount} ${_periodLabel(tariff.periodType)}',
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          if ((tariff.description ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              tariff.description!.trim(),
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
          const SizedBox(height: 16),
          Divider(color: Colors.grey.withValues(alpha: 0.18), height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatusChip(isActive: isActive),
              const Spacer(),
              const Text(
                'Activa',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              Switch(
                value: isActive,
                activeThumbColor: Colors.green,
                onChanged:
                    (value) =>
                        value
                            ? _setTariffActive(tariff, true)
                            : _confirmDisableTariff(tariff),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _setTariffActive(PaymentTariff tariff, bool isActive) {
    return _controller.saveTariff(
      tariffId: tariff.id,
      branchId: tariff.branchId,
      name: tariff.name,
      amountCents: tariff.amountCents,
      currency: tariff.currency,
      periodType: tariff.periodType,
      periodCount: tariff.periodCount,
      groupId: tariff.groupId,
      description: tariff.description,
      isActive: isActive,
    );
  }

  Future<void> _confirmDisableTariff(PaymentTariff tariff) async {
    final shouldDisable = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Apagar tarifa'),
          content: Text(
            'Esta tarifa esta conectada a la cartera del alumno. Si la apagas, dejara de aparecer como opcion activa para nuevos pagos.\n\nDeseas apagar "${tariff.name}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Apagar'),
            ),
          ],
        );
      },
    );

    if (shouldDisable == true) {
      await _setTariffActive(tariff, false);
    }
  }

  void _confirmDelete(PaymentTariff tariff) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar tarifa'),
          content: Text('Seguro que deseas eliminar "${tariff.name}"?'),
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

  void _openTariffSheet(BuildContext context, {PaymentTariff? existing}) {
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
    String periodType = existing?.periodType ?? 'month';
    final selectedBranchIds = <String>{if (existing != null) existing.branchId};
    bool isSaving = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            final branches = _controller.branches;
            final hasPriceChange = _hasPriceChange(
              existing,
              amountController.text,
            );
            final allBranchesSelected =
                branches.isNotEmpty &&
                selectedBranchIds.length == branches.length;

            return Container(
              padding: EdgeInsets.fromLTRB(
                20,
                18,
                20,
                20 + MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.sell_outlined,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            existing == null ? 'Nueva tarifa' : 'Editar tarifa',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: nameController,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration(
                        label: 'Nombre',
                        icon: Icons.badge_outlined,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) => setStateSheet(() {}),
                      decoration: _inputDecoration(
                        label: 'Monto en pesos',
                        hint: 'Ej. 500.00',
                        icon: Icons.attach_money,
                      ),
                    ),
                    if (hasPriceChange) ...[
                      const SizedBox(height: 10),
                      const _NextMonthNotice(),
                    ],
                    const SizedBox(height: 12),
                    if (branches.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F6FA),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text(
                          'No hay sucursales disponibles.',
                          style: TextStyle(color: Colors.black54),
                        ),
                      )
                    else if (existing != null)
                      DropdownButtonFormField<String>(
                        initialValue: selectedBranchIds.first,
                        isExpanded: true,
                        decoration: _inputDecoration(
                          label: 'Sucursal',
                          icon: Icons.storefront_outlined,
                        ),
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
                          if (value == null) return;
                          setStateSheet(() {
                            selectedBranchIds
                              ..clear()
                              ..add(value);
                          });
                        },
                      )
                    else
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F8FB),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(14, 10, 8, 6),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.storefront_outlined,
                                    color: Colors.black54,
                                  ),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Text(
                                      'Sucursales',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      setStateSheet(() {
                                        if (allBranchesSelected) {
                                          selectedBranchIds.clear();
                                        } else {
                                          selectedBranchIds
                                            ..clear()
                                            ..addAll(
                                              branches.map(
                                                (branch) => branch.branchId,
                                              ),
                                            );
                                        }
                                      });
                                    },
                                    child: Text(
                                      allBranchesSelected
                                          ? 'Limpiar'
                                          : 'Seleccionar todas',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            ...branches.map(
                              (branch) => CheckboxListTile(
                                value: selectedBranchIds.contains(
                                  branch.branchId,
                                ),
                                dense: true,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                title: Text(branch.branchName),
                                onChanged: (selected) {
                                  setStateSheet(() {
                                    if (selected == true) {
                                      selectedBranchIds.add(branch.branchId);
                                    } else {
                                      selectedBranchIds.remove(branch.branchId);
                                    }
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: periodCountController,
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration(
                              label: 'Cantidad',
                              icon: Icons.repeat,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: periodType,
                            decoration: _inputDecoration(
                              label: 'Periodo',
                              icon: Icons.calendar_month_outlined,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'month',
                                child: Text('Mes'),
                              ),
                              DropdownMenuItem(
                                value: 'week',
                                child: Text('Semana'),
                              ),
                              DropdownMenuItem(
                                value: 'day',
                                child: Text('Dia'),
                              ),
                              DropdownMenuItem(
                                value: 'year',
                                child: Text('Año'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setStateSheet(() => periodType = value);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      maxLines: 2,
                      decoration: _inputDecoration(
                        label: 'Descripcion',
                        icon: Icons.notes_outlined,
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed:
                            isSaving
                                ? null
                                : () async {
                                  final amount =
                                      double.tryParse(
                                        amountController.text.trim().replaceAll(
                                          ',',
                                          '.',
                                        ),
                                      ) ??
                                      0;
                                  final periodCount =
                                      int.tryParse(
                                        periodCountController.text.trim(),
                                      ) ??
                                      1;
                                  final branchIds = selectedBranchIds.toList();
                                  final name = nameController.text.trim();
                                  final priceChanged = _hasPriceChange(
                                    existing,
                                    amountController.text,
                                  );

                                  if (name.isEmpty ||
                                      amount <= 0 ||
                                      branchIds.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Completa nombre, monto y selecciona al menos una sucursal.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  setStateSheet(() => isSaving = true);
                                  final description =
                                      descriptionController.text.trim().isEmpty
                                          ? null
                                          : descriptionController.text.trim();
                                  try {
                                    if (existing == null) {
                                      await _controller.saveTariffForBranches(
                                        branchIds: branchIds,
                                        name: name,
                                        amountCents: (amount * 100).round(),
                                        currency: 'mxn',
                                        periodType: periodType,
                                        periodCount:
                                            periodCount <= 0 ? 1 : periodCount,
                                        groupId: null,
                                        description: description,
                                      );
                                    } else {
                                      await _controller.saveTariff(
                                        tariffId: existing.id,
                                        branchId: branchIds.first,
                                        name: name,
                                        amountCents: (amount * 100).round(),
                                        currency: 'mxn',
                                        periodType: periodType,
                                        periodCount:
                                            periodCount <= 0 ? 1 : periodCount,
                                        groupId: null,
                                        description: description,
                                        isActive: existing.isActive,
                                      );
                                    }
                                    if (sheetContext.mounted) {
                                      Navigator.pop(sheetContext);
                                    }
                                    if (!context.mounted) return;
                                    if (priceChanged) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'El nuevo precio se va a aplicar al siguiente mes.',
                                          ),
                                        ),
                                      );
                                    } else if (existing == null &&
                                        branchIds.length > 1) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Tarifa creada en ${branchIds.length} sucursales.',
                                          ),
                                        ),
                                      );
                                    }
                                  } catch (_) {
                                    if (sheetContext.mounted) {
                                      setStateSheet(() => isSaving = false);
                                    }
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'No se pudo guardar la tarifa. Intenta de nuevo.',
                                        ),
                                      ),
                                    );
                                  }
                                },
                        icon:
                            isSaving
                                ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Icon(Icons.save_outlined),
                        label: Text(
                          isSaving
                              ? 'Guardando...'
                              : existing == null && selectedBranchIds.length > 1
                              ? 'Crear ${selectedBranchIds.length} tarifas'
                              : 'Guardar tarifa',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      nameController.dispose();
      amountController.dispose();
      periodCountController.dispose();
      descriptionController.dispose();
    });
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: const Color(0xFFF7F8FB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.16)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primaryColor, width: 1.4),
      ),
    );
  }

  bool _hasPriceChange(PaymentTariff? existing, String rawAmount) {
    if (existing == null) return false;
    final amount = double.tryParse(rawAmount.trim().replaceAll(',', '.'));
    if (amount == null) return false;
    return (amount * 100).round() != existing.amountCents;
  }

  String _formatMoney(int cents) {
    return '\$${(cents / 100).toStringAsFixed(2)}';
  }

  String _periodLabel(String periodType) {
    switch (periodType) {
      case 'year':
        return 'año';
      case 'week':
        return 'semana';
      case 'day':
        return 'dia';
      case 'month':
      default:
        return 'mes';
    }
  }
}

class _NextMonthNotice extends StatelessWidget {
  const _NextMonthNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.18)),
      ),
      child: const Row(
        children: [
          Icon(Icons.event_repeat_outlined, color: Colors.blue),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'El nuevo precio se va a aplicar al siguiente mes.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TariffInfoPill extends StatelessWidget {
  const _TariffInfoPill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color.withValues(alpha: 0.78),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isActive ? 'Visible para alumnos' : 'Apagada',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color.shade800,
        ),
      ),
    );
  }
}
