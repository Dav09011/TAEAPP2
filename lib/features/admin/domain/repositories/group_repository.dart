import 'package:tae_app/features/admin/domain/entities/branch_category_option.dart';
import 'package:tae_app/features/admin/domain/entities/branch_group.dart';
import 'package:tae_app/features/admin/domain/entities/create_group_request.dart';

abstract class GroupRepository {
  Future<String?> getCurrentUserRole();

  Stream<List<BranchGroup>> watchGroupsByBranch(String branchId);

  Stream<List<BranchCategoryOption>> watchBranchCategories(String branchId);

  Future<void> createGroup(CreateGroupRequest request);

  Future<void> saveBranchCategories({
    required String branchId,
    required List<BranchCategoryOption> categories,
  });

  Future<void> renameGroup({
    required String branchId,
    required String groupId,
    required String oldName,
    required String newName,
  });

  Future<void> updateGroupColor({
    required String groupId,
    required int colorValue,
  });

  Future<void> deleteGroup({required String branchId, required String groupId});

  Future<String> generateGroupAccessCode({
    required String groupId,
    required bool privileged,
  });
}
