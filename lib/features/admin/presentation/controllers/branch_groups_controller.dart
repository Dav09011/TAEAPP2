import 'package:flutter/foundation.dart';
import 'package:tae_app/features/admin/data/repositories/firebase_group_repository.dart';
import 'package:tae_app/features/admin/domain/entities/branch_group.dart';
import 'package:tae_app/features/admin/domain/entities/create_group_request.dart';
import 'package:tae_app/features/admin/domain/repositories/group_repository.dart';

class BranchGroupsController extends ChangeNotifier {
  BranchGroupsController({GroupRepository? groupRepository})
    : _groupRepository = groupRepository ?? FirebaseGroupRepository();

  final GroupRepository _groupRepository;

  Stream<List<BranchGroup>>? _groupsStream;
  String _searchQuery = '';
  bool _isMutating = false;

  Stream<List<BranchGroup>>? get groupsStream => _groupsStream;
  bool get isMutating => _isMutating;

  void initialize(String branchId) {
    _groupsStream = _groupRepository.watchGroupsByBranch(branchId);
    notifyListeners();
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  List<BranchGroup> filterGroups(List<BranchGroup> groups) {
    if (_searchQuery.isEmpty) return groups;
    final normalized = _searchQuery.toLowerCase();
    return groups.where((group) {
      return group.name.toLowerCase().contains(normalized) ||
          group.beltType.toLowerCase().contains(normalized) ||
          group.schedule.toLowerCase().contains(normalized);
    }).toList();
  }

  Future<void> createGroup(CreateGroupRequest request) {
    return _runMutation(() => _groupRepository.createGroup(request));
  }

  Future<void> renameGroup(BranchGroup group, String newName) {
    return _runMutation(
      () => _groupRepository.renameGroup(
        branchId: group.branchId,
        groupId: group.id,
        oldName: group.name,
        newName: newName.trim(),
      ),
    );
  }

  Future<void> updateGroupColor(BranchGroup group, int colorValue) {
    return _runMutation(
      () => _groupRepository.updateGroupColor(
        groupId: group.id,
        colorValue: colorValue,
      ),
    );
  }

  Future<void> deleteGroup(BranchGroup group) {
    return _runMutation(
      () => _groupRepository.deleteGroup(
        branchId: group.branchId,
        groupId: group.id,
      ),
    );
  }

  Future<void> _runMutation(Future<void> Function() action) async {
    _isMutating = true;
    notifyListeners();
    try {
      await action();
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }
}
