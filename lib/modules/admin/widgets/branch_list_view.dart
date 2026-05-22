import 'package:flutter/material.dart';
import 'package:tae_app/features/admin/domain/entities/branch.dart';
import 'package:tae_app/modules/admin/widgets/branch_card.dart';

class BranchListView extends StatelessWidget {
  const BranchListView({
    super.key,
    required this.branches,
    required this.maxCardWidth,
    required this.icon,
    this.onTap,
    this.onRename,
    this.onChangeColor,
    this.onDelete,
  });

  final List<Branch> branches;
  final double maxCardWidth;
  final IconData icon;
  final void Function(Branch branch)? onTap;
  final void Function(Branch branch)? onRename;
  final void Function(Branch branch)? onChangeColor;
  final void Function(Branch branch)? onDelete;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 10),
      itemCount: branches.length,
      itemBuilder: (context, index) {
        final branch = branches[index];
        return BranchCard(
          branch: branch,
          maxCardWidth: maxCardWidth,
          icon: icon,
          onTap: onTap == null ? null : () => onTap!(branch),
          onRename: onRename == null ? null : () => onRename!(branch),
          onChangeColor:
              onChangeColor == null ? null : () => onChangeColor!(branch),
          onDelete: onDelete == null ? null : () => onDelete!(branch),
        );
      },
    );
  }
}
