import 'package:flutter_test/flutter_test.dart';
import 'package:tae_app/core/errors/app_exception.dart';
import 'package:tae_app/features/student/domain/entities/student_group_data.dart';
import 'package:tae_app/features/student/domain/repositories/student_home_repository.dart';
import 'package:tae_app/features/student/presentation/controllers/student_home_controller.dart';

void main() {
  test('watches groups, details, and delegates leave/remove actions', () async {
    const group = StudentGroupData(
      groupId: 'group-1',
      groupName: 'Infantil',
      cachedData: {'rol_en_grupo': 'moderador', 'nombre_sucursal': 'Centro'},
    );
    final details = StudentGroupDetails.fromData(
      fallback: group,
      data: const {
        'nombre_grupo': 'Infantil Avanzado',
        'nombre_sucursal': 'Centro',
        'tipo_cinta': 'Verde',
        'horario': 'Lunes 18:00',
        'total_alumnos': 12,
      },
    );
    final repository = _FakeStudentHomeRepository(
      groups: const [group],
      details: details,
      leaveResult: true,
    );
    final controller = StudentHomeController(repository: repository);

    final groups = await controller.watchCurrentStudentGroups().first;
    final streamedDetails = await controller.watchGroupDetails(group).first;
    await controller.removeMissingGroup('group-1');
    final leaveResult = await controller.leaveGroup('group-1');

    expect(groups.single.groupName, 'Infantil');
    expect(repository.detailGroupId, 'group-1');
    expect(streamedDetails.groupName, 'Infantil Avanzado');
    expect(streamedDetails.role, 'moderador');
    expect(repository.removedGroupId, 'group-1');
    expect(repository.leftGroupId, 'group-1');
    expect(leaveResult, isTrue);
  });

  test('maps error and leave messages for UI', () {
    final controller = StudentHomeController(
      repository: _FakeStudentHomeRepository(),
    );

    expect(
      controller.errorMessage(const AppException('No hay sesion activa.')),
      'No hay sesion activa.',
    );
    expect(
      controller.errorMessage(Exception('boom')),
      'No se pudo cargar tu grupo. Si ya escaneaste tu QR, intenta entrar de nuevo.',
    );
    expect(
      controller.leaveGroupMessage(true),
      'Tu grupo ya no aparece en tu pantalla.',
    );
    expect(
      controller.leaveGroupMessage(false),
      'Se quito el grupo de tu pantalla.',
    );
  });
}

class _FakeStudentHomeRepository implements StudentHomeRepository {
  _FakeStudentHomeRepository({
    this.groups = const [],
    StudentGroupDetails? details,
    this.leaveResult = false,
  }) : details =
           details ??
           StudentGroupDetails.missing(
             const StudentGroupData(
               groupId: 'missing',
               groupName: 'Sin grupo',
               cachedData: {},
             ),
           );

  final List<StudentGroupData> groups;
  final StudentGroupDetails details;
  final bool leaveResult;

  String? detailGroupId;
  String? removedGroupId;
  String? leftGroupId;

  @override
  Stream<List<StudentGroupData>> watchCurrentStudentGroups() {
    return Stream.value(groups);
  }

  @override
  Stream<StudentGroupDetails> watchGroupDetails(StudentGroupData group) {
    detailGroupId = group.groupId;
    return Stream.value(details);
  }

  @override
  Future<void> removeGroupFromCurrentStudentProfile(String groupId) async {
    removedGroupId = groupId;
  }

  @override
  Future<bool> leaveGroup(String groupId) async {
    leftGroupId = groupId;
    return leaveResult;
  }
}
