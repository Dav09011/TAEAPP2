import 'package:flutter/material.dart';
import 'package:tae_app/features/admin/domain/entities/branch.dart';
import 'package:tae_app/features/admin/presentation/controllers/branches_controller.dart';
import 'package:tae_app/modules/admin/pages/branch_calendar_screen.dart';

class AdminBranchCalendarSelectorScreen extends StatefulWidget {
  const AdminBranchCalendarSelectorScreen({
    super.key,
    this.includeScaffold = true,
  });

  final bool includeScaffold;

  @override
  State<AdminBranchCalendarSelectorScreen> createState() =>
      _AdminBranchCalendarSelectorScreenState();
}

class _AdminBranchCalendarSelectorScreenState
    extends State<AdminBranchCalendarSelectorScreen> {
  final BranchesController _controller = BranchesController();

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
    final content = _buildContent(context);
    if (!widget.includeScaffold) {
      return content;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: content,
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_controller.isBootstrapping) {
      return const Center(child: CircularProgressIndicator());
    }

    final branchesStream = _controller.branchesStream;
    if (branchesStream == null) {
      return const Center(
        child: Text('No pudimos identificar al administrador.'),
      );
    }

    return SafeArea(
      top: !widget.includeScaffold,
      child: StreamBuilder<List<Branch>>(
        stream: branchesStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Error al cargar sucursales.'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final branches = snapshot.data ?? const <Branch>[];
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              if (!widget.includeScaffold && Navigator.of(context).canPop()) ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: BackButton(),
                ),
                const SizedBox(height: 4),
              ],
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.grey.withValues(alpha: 0.20),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Calendario',
                      style: TextStyle(
                        fontSize: 35,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Elige la sucursal que quieres administrar.',
                      style: TextStyle(
                        color: Color(0xFF6D645B),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              if (branches.isEmpty)
                const _EmptyCalendarBranches()
              else
                ...branches.map(
                  (branch) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _AdminCalendarBranchCard(branch: branch),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _AdminCalendarBranchCard extends StatelessWidget {
  const _AdminCalendarBranchCard({required this.branch});

  final Branch branch;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder:
                  (context) => BranchCalendarScreen(
                    branchId: branch.id,
                    branchName: branch.name,
                  ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.18)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 41, 53, 119)
                      .withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: Color.fromARGB(255, 41, 53, 119),
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      branch.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${branch.classesCount} clases - ${branch.participantsCount} participantes',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF6D645B),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCalendarBranches extends StatelessWidget {
  const _EmptyCalendarBranches();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.18)),
      ),
      child: const Text(
        'Aun no hay sucursales registradas para mostrar calendarios.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Color(0xFF6D645B),
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
