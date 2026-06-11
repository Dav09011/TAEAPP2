import 'package:flutter/material.dart';
import 'package:tae_app/features/payments/domain/entities/payment_tariff.dart';
import 'package:tae_app/features/student/domain/entities/student_wallet_branch_summary.dart';
import 'package:tae_app/features/student/domain/entities/student_wallet_group_membership.dart';
import 'package:tae_app/features/student/presentation/controllers/student_wallet_controller.dart';
import 'package:tae_app/shared/presentation/color_customization.dart';

const _blue = Color(0xFF4A73B8);
const _blueDark = Color(0xFF3A5A94);
const _blueLight = Color(0xFFEBF0FA);

class WalletScreenStudent extends StatefulWidget {
  const WalletScreenStudent({super.key});

  @override
  State<WalletScreenStudent> createState() => _WalletScreenStudentState();
}

class _WalletScreenStudentState extends State<WalletScreenStudent> {
  final StudentWalletController _controller = StudentWalletController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F3),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: _buildHeader(),
            ),
            Expanded(
              child: StreamBuilder<bool>(
                stream: _controller.watchHasPendingCashRequest(),
                builder: (context, pendingSnapshot) {
                  final hasGlobalPending = pendingSnapshot.data ?? false;
                  return StreamBuilder<List<StudentWalletBranchSummary>>(
                    stream: _controller.watchWalletBranches(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return _EmptyState(
                          title: 'No pudimos cargar tu cartera',
                          message:
                              'Revisa tu conexion o vuelve a intentarlo mas tarde.',
                        );
                      }

                      final branches = snapshot.data ?? const <StudentWalletBranchSummary>[];
                      if (branches.isEmpty) {
                        return const _EmptyState();
                      }

                      return ListView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        children: [
                          if (hasGlobalPending) ...[
                            _PendingBanner(
                              text:
                                  'Tienes una solicitud en efectivo pendiente. Cuando se apruebe, tu cartera se actualizará automáticamente.',
                            ),
                            const SizedBox(height: 14),
                          ],
                          ...branches.map(
                            (branch) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _BranchWalletCard(
                                controller: _controller,
                                branch: branch,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _blue,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mi Wallet',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Administra tu mensualidad por sucursal.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BranchWalletCard extends StatelessWidget {
  const _BranchWalletCard({
    required this.controller,
    required this.branch,
  });

  final StudentWalletController controller;
  final StudentWalletBranchSummary branch;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = resolveCardColor(
      branch.branchColorValue,
      fallback: Colors.white,
    );
    final foregroundColor = resolveOnColor(backgroundColor);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        iconColor: foregroundColor,
        collapsedIconColor: foregroundColor,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              branch.branchName,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: foregroundColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${branch.groups.length} grupo${branch.groups.length == 1 ? '' : 's'} inscrito${branch.groups.length == 1 ? '' : 's'}',
              style: TextStyle(fontSize: 13, color: foregroundColor.withValues(alpha: 0.75)),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniInfoChip(
                label: 'Actual',
                value: branch.currentTariffLabel,
                backgroundColor: foregroundColor.withValues(alpha: 0.08),
                textColor: foregroundColor,
              ),
              _MiniInfoChip(
                label: 'Siguiente',
                value: branch.pendingTariffLabel,
                backgroundColor: Colors.white.withValues(alpha: 0.55),
                textColor: foregroundColor,
              ),
              if (branch.hasPendingCashRequest)
                _MiniInfoChip(
                  label: 'En revisión',
                  value: 'Efectivo',
                  backgroundColor: Colors.orange.withValues(alpha: 0.16),
                  textColor: Colors.orange.shade900,
                ),
            ],
          ),
        ),
        children: [
          const SizedBox(height: 10),
          _DetailRow(
            label: 'Mensualidad actual',
            value: '${branch.currentTariffLabel} · ${branch.currentAmountLabel}',
          ),
          const SizedBox(height: 8),
          _DetailRow(
            label: 'Cambio programado',
            value: '${branch.pendingTariffLabel} · ${branch.pendingAmountLabel}',
          ),
          const SizedBox(height: 14),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Tus grupos',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                branch.groups
                    .map(
                      (group) => Chip(
                        label: Text('${group.groupName} · ${group.schedule}'),
                        backgroundColor: Colors.white.withValues(alpha: 0.7),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openTariffSelector(context),
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Cambiar mensualidad'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed:
                      branch.hasPendingCashRequest
                          ? null
                          : () => _openPaymentSheet(context),
                  icon: const Icon(Icons.payments_outlined),
                  label: const Text('Pagar'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed:
                      branch.pendingTariffId == null
                          ? null
                          : () async {
                            await controller.clearPendingTariff(branch.branchId);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Cambio programado cancelado.'),
                                ),
                              );
                            }
                          },
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancelar cambio'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Pago con tarjeta se conecta en el siguiente corte.'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.credit_card),
                  label: const Text('Tarjeta'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openTariffSelector(BuildContext context) async {
    final tariffs = await controller.loadAvailableTariffs(branch.branchId);
    if (!context.mounted) return;

    if (tariffs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aun no hay tarifas definidas para esta sucursal.')),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        PaymentTariff? selectedTariff = tariffs.first;
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                20 + MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Cambiar mensualidad',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'El cambio se guarda como pendiente para el siguiente periodo.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: tariffs.length,
                      separatorBuilder: (context, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final tariff = tariffs[index];
                        return RadioListTile<PaymentTariff>(
                          value: tariff,
                          groupValue: selectedTariff,
                          onChanged: (value) {
                            if (value == null) return;
                            setStateSheet(() => selectedTariff = value);
                          },
                          title: Text(tariff.name),
                          subtitle: Text(
                            '${_money(tariff.amountCents)} · ${tariff.periodCount} ${tariff.periodType}',
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        await controller.setPendingTariff(
                          branchId: branch.branchId,
                          tariffId: selectedTariff!.id,
                        );
                        if (context.mounted) {
                          Navigator.pop(sheetContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Cambio guardado para el siguiente periodo.'),
                            ),
                          );
                        }
                      },
                      child: const Text('Guardar cambio'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openPaymentSheet(
    BuildContext context,
  ) async {
    final tariffs = branch.availableTariffs.isNotEmpty
        ? branch.availableTariffs
        : await controller.loadAvailableTariffs(branch.branchId);

    if (!context.mounted) return;

    if (tariffs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay tarifas disponibles para pagar.')),
      );
      return;
    }

    final groupOptions = branch.groups;
    StudentWalletBranchSummary localBranch = branch;
    PaymentTariff selectedTariff = tariffs.firstWhere(
      (item) => item.id == branch.currentTariffId,
      orElse: () => branch.pendingTariffId != null
          ? tariffs.firstWhere((item) => item.id == branch.pendingTariffId, orElse: () => tariffs.first)
          : tariffs.first,
    );
    StudentWalletGroupMembership selectedGroup = groupOptions.first;
    final noteController = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                20 + MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Pagar mensualidad',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    branch.hasPendingCashRequest
                        ? 'Esta sucursal ya tiene una solicitud en proceso. Podras generar otra cuando se resuelva.'
                        : 'Elige el grupo y la mensualidad que quieres solicitar.',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<StudentWalletGroupMembership>(
                    initialValue: selectedGroup,
                    items:
                        groupOptions
                            .map(
                              (group) => DropdownMenuItem(
                                value: group,
                                child: Text(group.groupName),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setStateSheet(() => selectedGroup = value);
                    },
                    decoration: const InputDecoration(
                      labelText: 'Grupo a cobrar',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<PaymentTariff>(
                    initialValue: selectedTariff,
                    items:
                        tariffs
                            .map(
                              (tariff) => DropdownMenuItem(
                                value: tariff,
                                child: Text(
                                  '${tariff.name} · ${_money(tariff.amountCents)}',
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setStateSheet(() => selectedTariff = value);
                    },
                    decoration: const InputDecoration(
                      labelText: 'Mensualidad a pagar',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Nota opcional',
                      hintText: 'Si quieres agregar un comentario para el admin',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _blueLight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedTariff.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: _blueDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _money(selectedTariff.amountCents),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: _blueDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Se cobrara a ${selectedGroup.groupName} en ${localBranch.branchName}',
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: branch.hasPendingCashRequest
                          ? null
                          : () async {
                              await controller.createCashPaymentRequest(
                                branchId: branch.branchId,
                                groupId: selectedGroup.groupId,
                                tariffId: selectedTariff.id,
                                tariffName: selectedTariff.name,
                                amountCents: selectedTariff.amountCents,
                                note:
                                    noteController.text.trim().isEmpty
                                        ? null
                                        : noteController.text.trim(),
                              );
                              if (context.mounted) {
                                Navigator.pop(sheetContext);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Solicitud enviada al administrador.'),
                                  ),
                                );
                              }
                            },
                      icon: const Icon(Icons.payments_outlined),
                      label: const Text('Solicitar pago en efectivo'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Pago con tarjeta se conectara en el siguiente corte.'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.credit_card),
                      label: const Text('Pagar con tarjeta'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _money(int cents) => '\$${(cents / 100).toStringAsFixed(2)}';
}

class _MiniInfoChip extends StatelessWidget {
  const _MiniInfoChip({
    required this.label,
    required this.value,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final String value;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _PendingBanner extends StatelessWidget {
  const _PendingBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time, color: Colors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    this.title = 'Aun no tienes sucursales activas',
    this.message =
        'Cuando estés inscrito en una sucursal, aquí aparecerán tus tarjetas de mensualidad.',
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.storefront_outlined, size: 78, color: Colors.black54),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
