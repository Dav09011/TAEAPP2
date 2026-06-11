import 'package:flutter/foundation.dart';
import 'package:tae_app/features/admin/data/repositories/firebase_admin_wallet_repository.dart';
import 'package:tae_app/features/admin/domain/entities/admin_wallet_filter_option.dart';
import 'package:tae_app/features/admin/domain/entities/admin_wallet_student_status.dart';
import 'package:tae_app/features/admin/domain/repositories/admin_wallet_repository.dart';

class WalletStudentStatusController extends ChangeNotifier {
  WalletStudentStatusController({AdminWalletRepository? repository})
      : _repository = repository ?? FirebaseAdminWalletRepository();

  final AdminWalletRepository _repository;

  List<AdminWalletStudentStatus> _allStudents = const [];
  List<AdminWalletStudentStatus> _filteredStudents = const [];
  String _searchQuery = '';
  String? _selectedBranchId;
  String? _selectedGroupId;
  bool _isLoading = true;

  List<AdminWalletStudentStatus> get students => List.unmodifiable(_filteredStudents);
  List<AdminWalletFilterOption> get branchOptions =>
      _allStudents
          .map(
            (student) => AdminWalletFilterOption(
              id: student.branchId,
              label: student.branchName,
            ),
          )
          .toSet()
          .toList();
  List<AdminWalletFilterOption> get groupOptions =>
      (_selectedBranchId == null
              ? _allStudents
              : _allStudents
                  .where((student) => student.branchId == _selectedBranchId))
          .map(
            (student) => AdminWalletFilterOption(
              id: student.groupId,
              label: student.groupName,
            ),
          )
          .toSet()
          .toList();
  bool get isLoading => _isLoading;
  String? get selectedBranchId => _selectedBranchId;
  String? get selectedGroupId => _selectedGroupId;
  String get searchQuery => _searchQuery;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      _allStudents = await _repository.loadStudentStatuses(
        branchId: _selectedBranchId,
        groupId: _selectedGroupId,
      );
      _applyFilters();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void filterStudents(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void setBranchFilter(String? branchId) {
    _selectedBranchId = branchId;
    _selectedGroupId = null;
    load();
  }

  void setGroupFilter(String? groupId) {
    _selectedGroupId = groupId;
    load();
  }

  void clearFilters() {
    _selectedBranchId = null;
    _selectedGroupId = null;
    load();
  }

  void _applyFilters() {
    if (_searchQuery.trim().isEmpty) {
      _filteredStudents = List.from(_allStudents);
      return;
    }

    final normalized = _searchQuery.toLowerCase();
    _filteredStudents =
        _allStudents.where((student) {
          return student.studentName.toLowerCase().contains(normalized) ||
              student.branchName.toLowerCase().contains(normalized) ||
              student.groupName.toLowerCase().contains(normalized) ||
              student.billingLabel.toLowerCase().contains(normalized);
        }).toList();
  }
}
