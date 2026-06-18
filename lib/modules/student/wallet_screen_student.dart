import 'dart:async';

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
  final Map<String, PaymentTariff> _tariffPreviews = {};

  late final Stream<bool> _hasPendingCashRequestStream;
  late final Stream<List<StudentWalletBranchSummary>> _walletBranchesStream;

  @override
  void initState() {
    super.initState();
    _hasPendingCashRequestStream = _controller.watchHasPendingCashRequest();
    _walletBranchesStream = _controller.watchWalletBranches();
  }

  void _setTariffPreview(String branchId, PaymentTariff? tariff) {
    if (!mounted) return;
    setState(() {
      if (tariff == null) {
        _tariffPreviews.remove(branchId);
      } else {
        _tariffPreviews[branchId] = tariff;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F3),
      body: SafeArea(
        child: Column(
          children: [
            Padding(padding: const EdgeInsets.all(20), child: _buildHeader()),
            Expanded(
              child: StreamBuilder<bool>(
                stream: _hasPendingCashRequestStream,
                builder: (context, pendingSnapshot) {
                  final hasGlobalPending = pendingSnapshot.data ?? false;
                  return StreamBuilder<List<StudentWalletBranchSummary>>(
                    stream: _walletBranchesStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return const _EmptyState(
                          title: 'No pudimos cargar tu cartera',
                          message:
                              'Revisa tu conexion o vuelve a intentarlo mas tarde.',
                        );
                      }

                      final branches =
                          snapshot.data ?? const <StudentWalletBranchSummary>[];
                      if (branches.isEmpty) {
                        return const _EmptyState();
                      }

                      return ListView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        children: [
                          if (hasGlobalPending) ...[
                            const _PendingBanner(
                              text:
                                  'Tienes una solicitud en efectivo pendiente. Cuando se apruebe, tu cartera se actualizara automaticamente.',
                            ),
                            const SizedBox(height: 14),
                          ],
                          ...branches.map(
                            (branch) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _BranchWalletCard(
                                controller: _controller,
                                branch: branch,
                                previewTariff: _tariffPreviews[branch.branchId],
                                onTariffPreviewChanged:
                                    (tariff) => _setTariffPreview(
                                      branch.branchId,
                                      tariff,
                                    ),
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
    required this.previewTariff,
    required this.onTariffPreviewChanged,
  });

  final StudentWalletController controller;
  final StudentWalletBranchSummary branch;
  final PaymentTariff? previewTariff;
  final ValueChanged<PaymentTariff?> onTariffPreviewChanged;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = resolveCardColor(
      branch.branchColorValue,
      fallback: Colors.white,
    );
    final foregroundColor = resolveOnColor(backgroundColor);
    final membershipLabel = previewTariff?.name ?? branch.effectiveTariffLabel;
    final priceLabel =
        previewTariff == null
            ? branch.effectiveAmountLabel
            : _money(previewTariff!.amountCents);
    final hasPendingChange =
        previewTariff != null || branch.pendingTariffId != null;

    return Container(
      padding: const EdgeInsets.all(18),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      branch.branchName,
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: foregroundColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      membershipLabel,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: foregroundColor.withValues(alpha: 0.78),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _groupSummary,
                      style: TextStyle(
                        fontSize: 12,
                        color: foregroundColor.withValues(alpha: 0.68),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    priceLabel,
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: foregroundColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (branch.hasPendingCashRequest)
                    const _SmallStateChip(
                      label: 'En revision',
                      color: Colors.orange,
                    )
                  else if (hasPendingChange)
                    const _SmallStateChip(
                      label: 'Cambio pendiente',
                      color: Colors.blue,
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () => _openManageSheet(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: foregroundColor,
                      side: BorderSide(
                        color: foregroundColor.withValues(alpha: 0.35),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      backgroundColor: Colors.white.withValues(alpha: 0.16),
                    ),
                    icon: const Icon(Icons.tune),
                    label: const Text('Administrar'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: FilledButton.icon(
                    onPressed:
                        branch.hasPendingCashRequest
                            ? null
                            : () => _openPaymentOptionsSheet(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: foregroundColor,
                      foregroundColor: backgroundColor,
                      disabledBackgroundColor: Colors.black12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    icon: const Icon(Icons.payments_outlined),
                    label: const Text('Pagar'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String get _groupSummary {
    if (branch.groups.isEmpty) {
      return 'Sin grupos activos';
    }
    if (branch.groups.length == 1) {
      return branch.groups.first.groupName;
    }
    return '${branch.groups.length} grupos activos';
  }

  Future<void> _openPaymentOptionsSheet(BuildContext context) async {
    final paymentData = await _resolvePaymentData(context);
    if (paymentData == null || !context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _BottomActionShell(
          title: 'Pagar mensualidad',
          subtitle:
              '${branch.branchName} / ${_money(paymentData.tariff.amountCents)}',
          child: Column(
            children: [
              _LargeSheetButton(
                icon: Icons.payments_outlined,
                title: 'Pagar con efectivo',
                subtitle: 'Enviar solicitud al administrador',
                onTap: () async {
                  final confirmed = await _confirmCashPayment(context);
                  if (confirmed != true) return;
                  if (!sheetContext.mounted) return;
                  Navigator.pop(sheetContext);
                  await _sendCashPaymentRequest(context, paymentData);
                },
              ),
              const SizedBox(height: 12),
              _LargeSheetButton(
                icon: Icons.credit_card,
                title: 'Pagar con tarjeta',
                subtitle: 'Disponible en el siguiente corte',
                onTap: () {
                  Navigator.pop(sheetContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Pago con tarjeta se conectara en el siguiente corte.',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openManageSheet(BuildContext context) async {
    _ManageAction selectedAction = _ManageAction.pay;

    final action = await showModalBottomSheet<_ManageAction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return _BottomActionShell(
              title: 'Administrar',
              subtitle:
                  '${branch.branchName} / ${previewTariff?.name ?? branch.effectiveTariffLabel}',
              child: Column(
                children: [
                  _ManageActionButton(
                    selected: selectedAction == _ManageAction.pay,
                    icon: Icons.payments_outlined,
                    title: 'Pagar',
                    subtitle: 'Abrir opciones de pago',
                    onTap: () {
                      setStateSheet(() => selectedAction = _ManageAction.pay);
                    },
                  ),
                  const SizedBox(height: 10),
                  _ManageActionButton(
                    selected: selectedAction == _ManageAction.change,
                    icon: Icons.swap_horiz,
                    title: 'Cambiar Mensualidad',
                    subtitle: 'Programar otra tarifa',
                    onTap: () {
                      setStateSheet(
                        () => selectedAction = _ManageAction.change,
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _ManageActionButton(
                    selected: selectedAction == _ManageAction.cancel,
                    icon: Icons.cancel_outlined,
                    title: 'Cancelarla',
                    subtitle: 'Cancelar el cambio programado o dejar pendiente',
                    onTap: () {
                      setStateSheet(
                        () => selectedAction = _ManageAction.cancel,
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pop(sheetContext),
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Cancelar'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: FilledButton.icon(
                            onPressed:
                                () =>
                                    Navigator.pop(sheetContext, selectedAction),
                            icon: const Icon(Icons.save_outlined),
                            label: const Text('Guardar'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (action == null || !context.mounted) return;
    await _handleManageAction(context, action);
  }

  Future<void> _handleManageAction(
    BuildContext context,
    _ManageAction action,
  ) async {
    switch (action) {
      case _ManageAction.pay:
        await _openPaymentOptionsSheet(context);
      case _ManageAction.change:
        await _openTariffSelector(context);
      case _ManageAction.cancel:
        if (branch.pendingTariffId == null && previewTariff == null) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No hay cambios programados para cancelar.'),
            ),
          );
          return;
        }
        await controller.clearPendingTariff(branch.branchId);
        onTariffPreviewChanged(null);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cambio programado cancelado.')),
        );
    }
  }

  Future<void> _openTariffSelector(BuildContext context) async {
    final tariffsFuture = controller.loadAvailableTariffs(branch.branchId);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return FutureBuilder<List<PaymentTariff>>(
          future: tariffsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _BottomActionShell(
                title: 'Cambiar mensualidad',
                subtitle: 'Cargando tarifas disponibles.',
                child: SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            if (snapshot.hasError) {
              return _BottomActionShell(
                title: 'Cambiar mensualidad',
                subtitle: 'No pudimos cargar las tarifas.',
                child: _SheetMessage(
                  icon: Icons.error_outline,
                  title: controller.errorMessage(snapshot.error!),
                  actionLabel: 'Cerrar',
                  onAction: () => Navigator.pop(sheetContext),
                ),
              );
            }

            final tariffs = snapshot.data ?? const <PaymentTariff>[];
            if (tariffs.isEmpty) {
              return _BottomActionShell(
                title: 'Cambiar mensualidad',
                subtitle: 'No hay tarifas para esta sucursal.',
                child: _SheetMessage(
                  icon: Icons.price_change_outlined,
                  title: 'Aun no hay tarifas definidas para esta sucursal.',
                  actionLabel: 'Cerrar',
                  onAction: () => Navigator.pop(sheetContext),
                ),
              );
            }

            return _BottomActionShell(
              title: 'Cambiar mensualidad',
              subtitle: 'El precio se actualiza en tu cartera al guardar.',
              child: _TariffSelectorBody(
                branch: branch,
                controller: controller,
                tariffs: tariffs,
                selectedTariffId: previewTariff?.id ?? branch.effectiveTariffId,
                onSaved: onTariffPreviewChanged,
                money: _money,
              ),
            );
          },
        );
      },
    );
  }

  String? get _effectiveTariffId =>
      previewTariff?.id ?? branch.effectiveTariffId;

  Future<_ResolvedPaymentData?> _resolvePaymentData(
    BuildContext context,
  ) async {
    final tariffs =
        branch.availableTariffs.isNotEmpty
            ? branch.availableTariffs
            : await controller.loadAvailableTariffs(branch.branchId);

    if (!context.mounted) return null;

    if (tariffs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay tarifas disponibles para pagar.')),
      );
      return null;
    }

    if (branch.groups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay grupos disponibles para cobrar.')),
      );
      return null;
    }

    final selectedTariff = tariffs.firstWhere(
      (item) => item.id == _effectiveTariffId,
      orElse: () => tariffs.first,
    );

    return _ResolvedPaymentData(
      tariff: selectedTariff,
      group: branch.groups.first,
    );
  }

  Future<bool?> _confirmCashPayment(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Pagar con efectivo'),
            content: const Text(
              'Estas seguro de pagar con efectivo? Se enviara una solicitud al administrador para revision.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Confirmar'),
              ),
            ],
          ),
    );
  }

  Future<void> _sendCashPaymentRequest(
    BuildContext context,
    _ResolvedPaymentData paymentData,
  ) async {
    try {
      await controller.createCashPaymentRequest(
        branchId: branch.branchId,
        groupId: paymentData.group.groupId,
        tariffId: paymentData.tariff.id,
        tariffName: paymentData.tariff.name,
        amountCents: paymentData.tariff.amountCents,
      );
      onTariffPreviewChanged(paymentData.tariff);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitud enviada al administrador.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(controller.errorMessage(error))));
    }
  }

  String _money(int cents) => '\$${(cents / 100).toStringAsFixed(2)}';
}

enum _ManageAction { pay, change, cancel }

class _ResolvedPaymentData {
  const _ResolvedPaymentData({required this.tariff, required this.group});

  final PaymentTariff tariff;
  final StudentWalletGroupMembership group;
}

class _TariffSelectorBody extends StatefulWidget {
  const _TariffSelectorBody({
    required this.branch,
    required this.controller,
    required this.tariffs,
    required this.selectedTariffId,
    required this.onSaved,
    required this.money,
  });

  final StudentWalletBranchSummary branch;
  final StudentWalletController controller;
  final List<PaymentTariff> tariffs;
  final String? selectedTariffId;
  final ValueChanged<PaymentTariff?> onSaved;
  final String Function(int cents) money;

  @override
  State<_TariffSelectorBody> createState() => _TariffSelectorBodyState();
}

class _TariffSelectorBodyState extends State<_TariffSelectorBody> {
  late PaymentTariff _selectedTariff;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedTariff = widget.tariffs.firstWhere(
      (item) => item.id == widget.selectedTariffId,
      orElse: () => widget.tariffs.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...widget.tariffs.map(
          (tariff) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _TariffOptionTile(
              selected: _selectedTariff.id == tariff.id,
              title: tariff.name,
              subtitle:
                  '${widget.money(tariff.amountCents)} / ${tariff.periodCount} ${tariff.periodType}',
              onTap:
                  _isSaving
                      ? () {}
                      : () {
                        setState(() => _selectedTariff = tariff);
                      },
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton.icon(
            onPressed: _isSaving ? null : _save,
            icon:
                _isSaving
                    ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.save_outlined),
            label: Text(_isSaving ? 'Guardando...' : 'Guardar cambio'),
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      await widget.controller.setPendingTariff(
        branchId: widget.branch.branchId,
        tariffId: _selectedTariff.id,
      );
      widget.onSaved(_selectedTariff);
      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Mensualidad actualizada en tu cartera.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      messenger.showSnackBar(
        SnackBar(content: Text(widget.controller.errorMessage(error))),
      );
    }
  }
}

class _SheetMessage extends StatelessWidget {
  const _SheetMessage({
    required this.icon,
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 42, color: Colors.grey),
        const SizedBox(height: 10),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(onPressed: onAction, child: Text(actionLabel)),
        ),
      ],
    );
  }
}

class _BottomActionShell extends StatelessWidget {
  const _BottomActionShell({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
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
      child: SafeArea(
        top: false,
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
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 18),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _LargeSheetButton extends StatelessWidget {
  const _LargeSheetButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F8FC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.16)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _blue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: _blue),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
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
}

class _ManageActionButton extends StatelessWidget {
  const _ManageActionButton({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: selected ? _blueLight : const Color(0xFFF7F8FB),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color:
                selected
                    ? _blue.withValues(alpha: 0.55)
                    : Colors.grey.withValues(alpha: 0.14),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? _blue : Colors.grey,
            ),
            const SizedBox(width: 12),
            Icon(icon, color: selected ? _blueDark : Colors.black54),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: selected ? _blueDark : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TariffOptionTile extends StatelessWidget {
  const _TariffOptionTile({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? _blueLight : const Color(0xFFF7F8FB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                selected
                    ? _blue.withValues(alpha: 0.55)
                    : Colors.grey.withValues(alpha: 0.14),
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              color: selected ? _blue : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallStateChip extends StatelessWidget {
  const _SmallStateChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
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
        'Cuando estes inscrito en una sucursal, aqui apareceran tus tarjetas de mensualidad.',
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
            const Icon(
              Icons.storefront_outlined,
              size: 78,
              color: Colors.black54,
            ),
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
