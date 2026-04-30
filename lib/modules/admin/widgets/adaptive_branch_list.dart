import 'package:flutter/material.dart';
import 'package:tae_app/features/admin/domain/entities/branch.dart';
import 'package:tae_app/modules/admin/widgets/branch_list_view.dart';

class AdaptiveBranchList extends StatelessWidget {
  const AdaptiveBranchList({
    super.key,
    required this.branches,
    required this.icon,
    this.onTap,
    this.onRename,
    this.onDelete,
  });

  final List<Branch> branches;
  final IconData icon;
  final void Function(Branch branch)? onTap;
  final void Function(Branch branch)? onRename;
  final void Function(Branch branch)? onDelete;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxCardWidth =
              constraints.maxWidth > 800 ? 600.0 : constraints.maxWidth * 0.95;

          return BranchListView(
            branches: branches,
            maxCardWidth: maxCardWidth,
            icon: icon,
            onTap: onTap,
            onRename: onRename,
            onDelete: onDelete,
          );
        },
      ),
    );
  }
}
