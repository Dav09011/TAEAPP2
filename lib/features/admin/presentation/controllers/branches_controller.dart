import 'package:flutter/foundation.dart';
import 'package:tae_app/core/errors/app_exception.dart';
import 'package:tae_app/core/services/auth_service.dart';
import 'package:tae_app/features/admin/data/repositories/firebase_branch_repository.dart';
import 'package:tae_app/features/admin/domain/entities/branch.dart';
import 'package:tae_app/features/admin/domain/repositories/branch_repository.dart';

class BranchesController extends ChangeNotifier {
  BranchesController({
    BranchRepository? branchRepository,
    AuthService? authService,
  }) : _branchRepository = branchRepository ?? FirebaseBranchRepository(),
       _authService = authService ?? AuthService();

  final BranchRepository _branchRepository;
  final AuthService _authService;

  Stream<List<Branch>>? _branchesStream;
  String _searchQuery = '';
  bool _isBootstrapping = true;
  bool _isMutating = false;
  String? _ownerUserId;

  Stream<List<Branch>>? get branchesStream => _branchesStream;
  String get searchQuery => _searchQuery;
  bool get isBootstrapping => _isBootstrapping;
  bool get isMutating => _isMutating;

  Future<void> initialize() async {
    try {
      _ownerUserId = _authService.currentUser?.uid;
      if (_ownerUserId != null) {
        _branchesStream = _branchRepository.watchBranchesByOwner(_ownerUserId!);
      }
    } finally {
      _isBootstrapping = false;
      notifyListeners();
    }
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  List<Branch> filterBranches(List<Branch> branches) {
    if (_searchQuery.isEmpty) return branches;
    final normalized = _searchQuery.toLowerCase();
    return branches
        .where((branch) => branch.name.toLowerCase().contains(normalized))
        .toList();
  }

  Future<String> createBranch(String branchName) async {
    final ownerUserId = _ownerUserId;
    if (ownerUserId == null) {
      throw const AppException('Error: no se pudo verificar la sesion.');
    }

    return _runMutation(
      () => _branchRepository.createBranch(
        ownerUserId: ownerUserId,
        branchName: branchName.trim(),
      ),
    );
  }

  Future<void> renameBranch(Branch branch, String newName) {
    return _runMutation(
      () => _branchRepository.renameBranch(
        branchId: branch.id,
        oldName: branch.name,
        newName: newName.trim(),
      ),
    );
  }

  Future<void> updateBranchColor(Branch branch, int colorValue) {
    return _runMutation(
      () => _branchRepository.updateBranchColor(
        branchId: branch.id,
        colorValue: colorValue,
      ),
    );
  }

  Future<void> deleteBranch(Branch branch) {
    return _runMutation(
      () => _branchRepository.deleteBranch(
        branchId: branch.id,
        branchName: branch.name,
      ),
    );
  }

  Future<T> _runMutation<T>(Future<T> Function() action) async {
    _isMutating = true;
    notifyListeners();
    try {
      return await action();
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }
}
