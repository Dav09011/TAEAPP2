import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:tae_app/features/admin/data/repositories/firebase_admin_wallet_repository.dart';
import 'package:tae_app/features/admin/domain/entities/admin_cash_payment_request.dart';
import 'package:tae_app/features/admin/domain/entities/admin_wallet_student_status.dart';
import 'package:tae_app/features/admin/domain/repositories/admin_wallet_repository.dart';

class CashPaymentRequestsController extends ChangeNotifier {
  CashPaymentRequestsController({AdminWalletRepository? repository})
    : _repository = repository ?? FirebaseAdminWalletRepository();

  final AdminWalletRepository _repository;
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  List<AdminCashPaymentRequest> _requests = const [];
  List<AdminWalletStudentStatus> _students = const [];
  final Set<String> _selectedRequestIds = <String>{};
  String _searchQuery = '';
  bool _isLoading = true;

  List<AdminCashPaymentRequest> get requests =>
      List.unmodifiable(_filteredRequests);
  List<AdminWalletStudentStatus> get students => List.unmodifiable(_students);
  bool get isLoading => _isLoading;
  bool get isSelectionMode => _selectedRequestIds.isNotEmpty;
  int get selectedRequestsCount => _selectedRequestIds.length;
  Set<String> get selectedRequestIds => Set.unmodifiable(_selectedRequestIds);

  List<AdminCashPaymentRequest> get _filteredRequests {
    if (_searchQuery.trim().isEmpty) {
      return _requests;
    }

    final normalized = _searchQuery.toLowerCase();
    return _requests.where((request) {
      return request.studentName.toLowerCase().contains(normalized) ||
          request.branchName.toLowerCase().contains(normalized) ||
          request.groupName.toLowerCase().contains(normalized);
    }).toList();
  }

  Future<void> initialize() async {
    final uid = _repository.currentUserId;
    if (uid == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();

    _subscriptions.add(
      _repository.watchCashRequests().listen((items) {
        _requests = items.where((item) => item.status == 'pending').toList();
        _selectedRequestIds.removeWhere(
          (selectedId) => !_requests.any((request) => request.id == selectedId),
        );
        _isLoading = false;
        notifyListeners();
      }),
    );

    _students = await _repository.loadCashPaymentCandidates();
    _isLoading = false;
    notifyListeners();
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void toggleRequestSelection(String requestId) {
    if (_selectedRequestIds.contains(requestId)) {
      _selectedRequestIds.remove(requestId);
    } else {
      _selectedRequestIds.add(requestId);
    }
    notifyListeners();
  }

  void clearSelection() {
    if (_selectedRequestIds.isEmpty) return;
    _selectedRequestIds.clear();
    notifyListeners();
  }

  void selectAllVisibleRequests() {
    for (final request in _filteredRequests) {
      _selectedRequestIds.add(request.id);
    }
    notifyListeners();
  }

  bool isRequestSelected(String requestId) {
    return _selectedRequestIds.contains(requestId);
  }

  Future<void> approveRequest(String requestId) async {
    await _repository.approveCashPaymentRequest(requestId);
    _removeRequest(requestId);
  }

  Future<void> rejectRequest(String requestId) async {
    await _repository.rejectCashPaymentRequest(requestId);
    _removeRequest(requestId);
  }

  Future<void> approveSelectedRequests() async {
    final ids = _selectedRequestIds.toList();
    for (final requestId in ids) {
      await approveRequest(requestId);
    }
    clearSelection();
  }

  Future<void> rejectSelectedRequests() async {
    final ids = _selectedRequestIds.toList();
    for (final requestId in ids) {
      await rejectRequest(requestId);
    }
    clearSelection();
  }

  Future<void> createRequest({
    required String studentId,
    required String studentName,
    required String branchId,
    required String branchName,
    required String groupId,
    required String groupName,
    required int amountCents,
    String? note,
  }) {
    return _repository.createCashPaymentRequest(
      studentId: studentId,
      studentName: studentName,
      branchId: branchId,
      branchName: branchName,
      groupId: groupId,
      groupName: groupName,
      amountCents: amountCents,
      note: note,
    );
  }

  void _removeRequest(String requestId) {
    final nextRequests =
        _requests.where((request) => request.id != requestId).toList();
    if (nextRequests.length == _requests.length) return;
    _requests = nextRequests;
    _selectedRequestIds.remove(requestId);
    notifyListeners();
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    super.dispose();
  }
}
