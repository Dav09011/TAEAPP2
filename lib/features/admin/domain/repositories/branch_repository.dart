import 'package:tae_app/features/admin/domain/entities/branch.dart';

abstract class BranchRepository {
  Stream<List<Branch>> watchBranchesByOwner(String ownerUserId);

  Future<String> createBranch({
    required String ownerUserId,
    required String branchName,
  });

  Future<void> renameBranch({
    required String branchId,
    required String oldName,
    required String newName,
  });

  Future<void> updateBranchColor({
    required String branchId,
    required int colorValue,
  });

  Future<void> deleteBranch({
    required String branchId,
    required String branchName,
  });
}
