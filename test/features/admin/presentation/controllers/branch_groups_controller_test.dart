import 'package:flutter_test/flutter_test.dart';
import 'package:tae_app/features/admin/domain/entities/branch_category_option.dart';
import 'package:tae_app/features/admin/domain/entities/branch_group.dart';
import 'package:tae_app/features/admin/domain/entities/create_group_request.dart';
import 'package:tae_app/features/admin/domain/repositories/group_repository.dart';
import 'package:tae_app/features/admin/presentation/controllers/branch_groups_controller.dart';

void main() {
  test('initializes groups stream and filters by search query', () async {
    final repository = _FakeGroupRepository(
      groups: const [
        BranchGroup(
          id: 'g1',
          branchId: 'branch-1',
          name: 'Infantil',
          beltType: 'Verde',
          schedule: 'Lunes',
          totalStudents: 8,
        ),
        BranchGroup(
          id: 'g2',
          branchId: 'branch-1',
          name: 'Adultos',
          beltType: 'Azul',
          schedule: 'Martes',
          totalStudents: 5,
        ),
      ],
    );
    final controller = BranchGroupsController(groupRepository: repository);

    controller.initialize('branch-1');
    final groups = await controller.groupsStream!.first;

    expect(repository.watchedBranchId, 'branch-1');
    expect(groups, hasLength(2));

    controller.updateSearchQuery('verde');
    expect(controller.filterGroups(groups).single.id, 'g1');

    controller.dispose();
  });

  test('delegates branch categories and access codes to repository', () async {
    final repository = _FakeGroupRepository(role: 'admin', code: '123456');
    final controller = BranchGroupsController(groupRepository: repository);

    final role = await controller.loadCurrentUserRole();
    await controller.saveBranchCategories(
      branchId: 'branch-1',
      categories: const [
        BranchCategoryOption(label: 'Blanca', colorValue: 0xFFFFFFFF),
      ],
    );
    final code = await controller.generateAccessCode(
      groupId: 'g1',
      privileged: true,
    );

    expect(role, 'admin');
    expect(repository.savedCategoriesBranchId, 'branch-1');
    expect(repository.savedCategories.single.label, 'Blanca');
    expect(repository.generatedGroupId, 'g1');
    expect(repository.generatedPrivileged, isTrue);
    expect(code, '123456');

    controller.dispose();
  });
}

class _FakeGroupRepository implements GroupRepository {
  _FakeGroupRepository({
    this.groups = const [],
    this.role,
    this.code = '000000',
  });

  final List<BranchGroup> groups;
  final String? role;
  final String code;

  String? watchedBranchId;
  String? savedCategoriesBranchId;
  List<BranchCategoryOption> savedCategories = const [];
  String? generatedGroupId;
  bool? generatedPrivileged;

  @override
  Future<String?> getCurrentUserRole() async => role;

  @override
  Stream<List<BranchGroup>> watchGroupsByBranch(String branchId) {
    watchedBranchId = branchId;
    return Stream.value(groups);
  }

  @override
  Stream<List<BranchCategoryOption>> watchBranchCategories(String branchId) {
    return Stream.value(savedCategories);
  }

  @override
  Future<void> saveBranchCategories({
    required String branchId,
    required List<BranchCategoryOption> categories,
  }) async {
    savedCategoriesBranchId = branchId;
    savedCategories = categories;
  }

  @override
  Future<String> generateGroupAccessCode({
    required String groupId,
    required bool privileged,
  }) async {
    generatedGroupId = groupId;
    generatedPrivileged = privileged;
    return code;
  }

  @override
  Future<void> createGroup(CreateGroupRequest request) async {}

  @override
  Future<void> renameGroup({
    required String branchId,
    required String groupId,
    required String oldName,
    required String newName,
  }) async {}

  @override
  Future<void> updateGroupColor({
    required String groupId,
    required int colorValue,
  }) async {}

  @override
  Future<void> deleteGroup({
    required String branchId,
    required String groupId,
  }) async {}
}
