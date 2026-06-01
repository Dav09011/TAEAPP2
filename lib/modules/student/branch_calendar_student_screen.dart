import 'package:flutter/material.dart';
import 'package:tae_app/features/student/domain/entities/student_branch_context.dart';
import 'package:tae_app/features/student/presentation/controllers/student_calendar_controller.dart';
import 'package:tae_app/modules/admin/pages/branch_calendar_screen.dart';

class BranchCalendarStudentScreen extends StatefulWidget {
  const BranchCalendarStudentScreen({
    super.key,
    StudentCalendarController? controller,
  }) : _controller = controller;

  final StudentCalendarController? _controller;

  @override
  State<BranchCalendarStudentScreen> createState() =>
      _BranchCalendarStudentScreenState();
}

class _BranchCalendarStudentScreenState
    extends State<BranchCalendarStudentScreen> {
  late final StudentCalendarController _controller;
  late final Stream<List<StudentBranchContext>> _branchesStream;

  @override
  void initState() {
    super.initState();
    _controller = widget._controller ?? StudentCalendarController();
    _branchesStream = _controller.watchBranchesForCurrentStudent();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<StudentBranchContext>>(
      stream: _branchesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text(_controller.errorMessage(snapshot.error))),
          );
        }

        final branches = snapshot.data ?? const <StudentBranchContext>[];
        return _StudentCalendarBranchSelector(branches: branches);
      },
    );
  }
}

class _StudentCalendarBranchSelector extends StatelessWidget {
  const _StudentCalendarBranchSelector({required this.branches});

  final List<StudentBranchContext> branches;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF7F4EF),
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Calendarios',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800),
        ),
      ),
      body:
          branches.isEmpty
              ? const _NoBranchCalendarsState()
              : ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  const Text(
                    'Elige una sucursal',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Selecciona el calendario que quieres consultar.',
                    style: TextStyle(
                      color: Color(0xFF6D645B),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ...branches.map(
                    (branch) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _BranchCalendarOptionCard(branch: branch),
                    ),
                  ),
                ],
              ),
    );
  }
}

class _BranchCalendarOptionCard extends StatelessWidget {
  const _BranchCalendarOptionCard({required this.branch});

  final StudentBranchContext branch;

  @override
  Widget build(BuildContext context) {
    final groupCount = branch.groupNames.length;
    final groupSummary =
        groupCount == 1
            ? branch.groupNames.first
            : '$groupCount grupos inscritos';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder:
                  (context) => BranchCalendarScreen(
                    branchId: branch.branchId,
                    branchName: branch.branchName,
                    isReadOnly: true,
                  ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE8DDD2)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      branch.branchName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      groupSummary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF6D645B),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.chevron_right_rounded, size: 34),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoBranchCalendarsState extends StatelessWidget {
  const _NoBranchCalendarsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.event_busy_rounded, size: 76, color: Colors.black38),
            SizedBox(height: 18),
            Text(
              'Sin calendarios disponibles',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 10),
            Text(
              'Cuando estes inscrito en una sucursal, podras consultar aqui sus eventos.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF6D645B),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
