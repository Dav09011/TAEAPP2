import 'package:tae_app/features/admin/domain/entities/branch_group.dart';
import 'package:tae_app/features/admin/domain/entities/create_group_request.dart';

abstract class GroupRepository {
  Stream<List<BranchGroup>> watchGroupsByBranch(String branchId);

  Future<void> createGroup(CreateGroupRequest request);

  Future<void> renameGroup({
    required String branchId,
    required String groupId,
    required String oldName,
    required String newName,
  });

  Future<void> deleteGroup({
    required String branchId,
    required String groupId,
  });
}
