import 'package:flutter/material.dart';
import 'package:tae_app/features/student/domain/entities/student_group_data.dart';
import 'package:tae_app/features/student/presentation/controllers/student_home_controller.dart';
import 'package:tae_app/modules/admin/pages/activities_section.dart';
import 'package:tae_app/modules/student/branch_calendar_student_screen.dart';
import 'package:tae_app/modules/student/profile_screen_student.dart';
import 'package:tae_app/modules/student/qr_scanner_page.dart';
import 'package:tae_app/modules/student/wallet_screen_student.dart';
import 'package:tae_app/modules/student/widgets/custom_navigation_bar_student.dart';
import 'package:tae_app/shared/presentation/color_customization.dart';

class HomePageStudent extends StatefulWidget {
  const HomePageStudent({super.key});

  @override
  State<HomePageStudent> createState() => _HomePageStudentState();
}

class _HomePageStudentState extends State<HomePageStudent> {
  int _selectedIndex = 0;

  late final List<Widget> _screens = const [
    _StudentHomeScreen(),
    BranchCalendarStudentScreen(),
    WalletScreenStudent(),
    ProfileScreenStudent(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _screens[_selectedIndex],
      bottomNavigationBar: CustomNavigationBarStudent(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
      ),
    );
  }
}

class _StudentHomeScreen extends StatelessWidget {
  const _StudentHomeScreen();

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
            MaterialPageRoute(builder: (context) => const QRScannerPage()),
          );
        },
        tooltip: 'Escanear QR',
        child: const Icon(Icons.qr_code_scanner, color: Colors.white),
      ),
      body: const _StudentGroupView(),
    );
  }
}

class _StudentGroupView extends StatefulWidget {
  const _StudentGroupView({StudentHomeController? controller})
    : _controller = controller;

  final StudentHomeController? _controller;

  @override
  State<_StudentGroupView> createState() => _StudentGroupViewState();
}

class _StudentGroupViewState extends State<_StudentGroupView> {
  late final StudentHomeController _controller;
  late final Stream<List<StudentGroupData>> _groupsStream;

  @override
  void initState() {
    super.initState();
    _controller = widget._controller ?? StudentHomeController();
    _groupsStream = _controller.watchCurrentStudentGroups();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<StudentGroupData>>(
      stream: _groupsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _NoGroupAssignedState(
            message: _controller.errorMessage(snapshot.error),
          );
        }

        final resolvedGroups = snapshot.data ?? const <StudentGroupData>[];
        if (resolvedGroups.isEmpty) {
          return const _NoGroupAssignedState();
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                resolvedGroups.length == 1 ? 'Tu grupo' : 'Tus grupos',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...resolvedGroups.map(
                (resolvedGroup) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _StudentGroupCard(
                    controller: _controller,
                    group: resolvedGroup,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StudentGroupCard extends StatefulWidget {
  const _StudentGroupCard({required this.controller, required this.group});

  final StudentHomeController controller;
  final StudentGroupData group;

  @override
  State<_StudentGroupCard> createState() => _StudentGroupCardState();
}

class _StudentGroupCardState extends State<_StudentGroupCard> {
  bool _missingRemovalRequested = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<StudentGroupDetails>(
      stream: widget.controller.watchGroupDetails(widget.group),
      builder: (context, liveGroupSnapshot) {
        if (liveGroupSnapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (liveGroupSnapshot.hasError) {
          return const _InlineGroupMessage(
            message: 'No pudimos cargar uno de tus grupos.',
          );
        }

        final groupDetails = liveGroupSnapshot.data;
        if (groupDetails == null) {
          return const _InlineGroupMessage(
            message: 'No pudimos cargar uno de tus grupos.',
          );
        }

        if (!groupDetails.exists) {
          _requestMissingGroupRemoval();
          return const _InlineGroupMessage(
            message: 'Un grupo fue eliminado y ya no aparece en tu lista.',
          );
        }

        final backgroundColor = resolveCardColor(
          groupDetails.groupColorValue,
          fallback: resolveCardColor(groupDetails.branchColorValue),
        );
        final foregroundColor = resolveOnColor(backgroundColor);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 18,
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
                    child: Text(
                      groupDetails.groupName,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: foregroundColor,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: foregroundColor),
                    onSelected: (value) async {
                      if (value != 'leave_group') return;

                      final shouldLeave = await _showLeaveGroupDialog(context);
                      if (!context.mounted || shouldLeave != true) return;

                      try {
                        final removedEnrollment = await widget.controller
                            .leaveGroup(widget.group.groupId);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              widget.controller.leaveGroupMessage(
                                removedEnrollment,
                              ),
                            ),
                          ),
                        );
                      } catch (error) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              widget.controller.errorMessage(error),
                            ),
                          ),
                        );
                      }
                    },
                    itemBuilder:
                        (context) => const [
                          PopupMenuItem<String>(
                            value: 'leave_group',
                            child: Text('Quitar de mi pantalla'),
                          ),
                        ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _InfoRow(
                label: 'Sucursal',
                value: groupDetails.branchName,
                textColor: foregroundColor,
              ),
              _InfoRow(
                label: 'Cinta',
                value: groupDetails.beltType,
                textColor: foregroundColor,
              ),
              _InfoRow(
                label: 'Horario',
                value: groupDetails.schedule,
                textColor: foregroundColor,
              ),
              _InfoRow(
                label: 'Integrantes',
                value: '${groupDetails.totalStudents}',
                textColor: foregroundColor,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: foregroundColor,
                    foregroundColor: backgroundColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => ActivitiesSection(
                              groupName: groupDetails.groupName,
                              groupDocId: groupDetails.groupId,
                              isReadOnly: groupDetails.role != 'moderador',
                            ),
                      ),
                    );
                  },
                  child: const Text('Ver ejercicios'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _requestMissingGroupRemoval() {
    if (_missingRemovalRequested) return;

    _missingRemovalRequested = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.removeMissingGroup(widget.group.groupId);
    });
  }
}

Future<bool?> _showLeaveGroupDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder:
        (context) => AlertDialog(
          title: const Text('Quitar grupo'),
          content: const Text(
            'Este grupo dejara de aparecer en tu pantalla. Podras volver a entrar escaneando el QR o escribiendo el codigo otra vez.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              child: const Text('Quitar'),
            ),
          ],
        ),
  );
}

class _InlineGroupMessage extends StatelessWidget {
  const _InlineGroupMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(message, style: const TextStyle(color: Colors.black54)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.textColor});

  final String label;
  final String value;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final resolvedTextColor =
        textColor ?? DefaultTextStyle.of(context).style.color ?? Colors.black87;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: TextStyle(color: resolvedTextColor, fontSize: 16),
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: resolvedTextColor,
              ),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class _NoGroupAssignedState extends StatelessWidget {
  const _NoGroupAssignedState({
    this.message =
        'Aun no estas inscrito en un grupo. Escanea el QR o escribe el codigo que te comparta tu administrador.',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school_outlined, size: 80, color: Colors.black),
            const SizedBox(height: 20),
            const Text(
              'Sin grupo asignado',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
