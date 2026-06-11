import 'package:flutter/foundation.dart';
import 'dart:async';

import 'package:tae_app/features/admin/data/repositories/firebase_admin_wallet_repository.dart';
import 'package:tae_app/features/admin/domain/entities/admin_cash_payment_request.dart';
import 'package:tae_app/features/admin/domain/entities/admin_wallet_branch_summary.dart';
import 'package:tae_app/features/admin/domain/repositories/admin_wallet_repository.dart';

class WalletController extends ChangeNotifier {
  WalletController({AdminWalletRepository? walletRepository})
    : _walletRepository = walletRepository ?? FirebaseAdminWalletRepository();

  final AdminWalletRepository _walletRepository;
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  bool _isPressed = false;
  bool _isLoadingHeader = true;
  bool _isLoadingSummary = true;
  String _adminName = 'Usuario';
  String _selectedBranchId = '';
  String _selectedBranchName = 'General';
  List<AdminWalletBranchSummary> _branchSummaries = const [];
  List<AdminCashPaymentRequest> _cashRequests = const [];

  bool get isPressed => _isPressed;
  bool get isLoadingHeader => _isLoadingHeader;
  bool get isLoadingSummary => _isLoadingSummary;
  String get adminName => _adminName;
  String get selectedBranchId => _selectedBranchId;
  String get selectedBranchName => _selectedBranchName;
  int get selectedBranchCashRequestsCount {
    final selected = selectedBranchSummary;
    if (selected == null) return 0;
    return _cashRequests
        .where(
          (request) =>
              request.branchId == selected.branchId &&
              request.status == 'pending',
        )
        .length;
  }
  List<AdminWalletBranchSummary> get branchSummaries =>
      List.unmodifiable(_branchSummaries);

  AdminWalletBranchSummary? get selectedBranchSummary {
    for (final summary in _branchSummaries) {
      if (summary.branchId == _selectedBranchId) {
        return summary;
      }
    }
    return _branchSummaries.isEmpty ? null : _branchSummaries.first;
  }

  Stream<List<AdminWalletBranchSummary>> watchBranchSummaries() {
    return _walletRepository.watchBranchSummaries();
  }

  Future<void> initialize() async {
    try {
      _adminName = await _walletRepository.getCurrentAdminFirstName();
      _subscriptions.add(
        _walletRepository.watchBranchSummaries().listen((summaries) {
          _branchSummaries = summaries;
          if (_selectedBranchId.isEmpty && summaries.isNotEmpty) {
            _selectedBranchId = summaries.first.branchId;
            _selectedBranchName = summaries.first.branchName;
          } else if (_selectedBranchId.isNotEmpty) {
            for (final item in summaries) {
              if (item.branchId == _selectedBranchId) {
                _selectedBranchName = item.branchName;
                break;
              }
            }
          }
          _isLoadingSummary = false;
          notifyListeners();
        }),
      );
      _subscriptions.add(
        _walletRepository.watchCashRequests().listen((requests) {
          _cashRequests = requests;
          notifyListeners();
        }),
      );
    } finally {
      _isLoadingHeader = false;
      notifyListeners();
    }
  }

  void setPressed(bool value) {
    if (_isPressed == value) return;
    _isPressed = value;
    notifyListeners();
  }

  void selectBranch(String branchId, String branchName) {
    _selectedBranchId = branchId;
    _selectedBranchName = branchName;
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
