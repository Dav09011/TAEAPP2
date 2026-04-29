import 'package:flutter/foundation.dart';
import 'package:tae_app/features/admin/data/repositories/firebase_wallet_repository.dart';
import 'package:tae_app/features/admin/domain/entities/wallet_branch_option.dart';
import 'package:tae_app/features/admin/domain/repositories/wallet_repository.dart';

class WalletController extends ChangeNotifier {
  WalletController({WalletRepository? walletRepository})
    : _walletRepository = walletRepository ?? FirebaseWalletRepository();

  final WalletRepository _walletRepository;

  bool _isPressed = false;
  bool _isLoadingHeader = true;
  String _adminName = 'Usuario';
  String _selectedBranchName = 'General';

  bool get isPressed => _isPressed;
  bool get isLoadingHeader => _isLoadingHeader;
  String get adminName => _adminName;
  String get selectedBranchName => _selectedBranchName;

  Stream<List<WalletBranchOption>> watchBranches() {
    return _walletRepository.watchBranchesByCurrentAdmin();
  }

  Future<void> initialize() async {
    try {
      _adminName = await _walletRepository.getCurrentAdminFirstName();
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

  void selectBranch(String branchName) {
    _selectedBranchName = branchName;
    notifyListeners();
  }
}
