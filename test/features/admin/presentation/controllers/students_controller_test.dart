import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tae_app/features/admin/domain/entities/admin_student.dart';
import 'package:tae_app/features/admin/domain/repositories/student_repository.dart';
import 'package:tae_app/features/admin/presentation/controllers/students_controller.dart';

void main() {
  test('groups and filters students by belt and name', () async {
    final repository = _FakeStudentRepository(
      students: const [
        AdminStudent(id: 's1', name: 'Ana', imageUrl: '', belt: 'Verde'),
        AdminStudent(id: 's2', name: 'Luis', imageUrl: '', belt: 'Azul'),
        AdminStudent(id: 's3', name: 'Anahi', imageUrl: '', belt: 'Verde'),
      ],
    );
    final controller = StudentsController(studentRepository: repository);

    final students = await controller.watchStudentsByGroup('group-1').first;
    final grouped = controller.groupByBelt(students);

    expect(repository.watchedGroupId, 'group-1');
    expect(grouped['Verde'], hasLength(2));
    expect(grouped['Azul'], hasLength(1));

    controller.updateSearchQuery('ana');
    final filtered = controller.filterGroupedStudents(grouped);

    expect(filtered.keys, ['Verde']);
    expect(filtered['Verde']!.map((student) => student.id), ['s1', 's3']);

    controller.dispose();
  });

  test('deleteStudents toggles mutation state and delegates ids', () async {
    final deleteCompleter = Completer<void>();
    final repository = _FakeStudentRepository(
      deleteCallback: () => deleteCompleter.future,
    );
    final controller = StudentsController(studentRepository: repository);
    final mutationStates = <bool>[];
    controller.addListener(() => mutationStates.add(controller.isMutating));

    final deleteFuture = controller.deleteStudents(
      groupId: 'group-1',
      studentIds: const ['s1', 's2'],
    );

    expect(controller.isMutating, isTrue);
    expect(mutationStates, [true]);
    expect(repository.deletedGroupId, 'group-1');
    expect(repository.deletedStudentIds, ['s1', 's2']);

    deleteCompleter.complete();
    await deleteFuture;

    expect(controller.isMutating, isFalse);
    expect(mutationStates, [true, false]);

    controller.dispose();
  });
}

class _FakeStudentRepository implements StudentRepository {
  _FakeStudentRepository({this.students = const [], this.deleteCallback});

  final List<AdminStudent> students;
  final Future<void> Function()? deleteCallback;

  String? watchedGroupId;
  String? detailsUserId;
  String? deletedGroupId;
  List<String> deletedStudentIds = const [];

  @override
  Stream<List<AdminStudent>> watchStudentsByGroup(String groupId) {
    watchedGroupId = groupId;
    return Stream.value(students);
  }

  @override
  Future<AdminStudent> getStudentDetails(String userId) async {
    detailsUserId = userId;
    return AdminStudent(
      id: userId,
      name: 'Detalle',
      imageUrl: '',
      belt: 'Verde',
      userId: userId,
    );
  }

  @override
  Future<void> deleteStudents({
    required String groupId,
    required List<String> studentIds,
  }) async {
    deletedGroupId = groupId;
    deletedStudentIds = studentIds;
    await deleteCallback?.call();
  }
}
