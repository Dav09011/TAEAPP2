import 'package:tae_app/features/admin/domain/entities/wallet_branch_option.dart';

abstract class WalletRepository {
  String? get currentUserId;

  Future<String> getCurrentAdminFirstName();

  Stream<List<WalletBranchOption>> watchBranchesByCurrentAdmin();
}
