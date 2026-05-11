import 'package:flutter/material.dart';
import 'package:tae_app/core/errors/app_exception.dart';
import 'package:tae_app/features/admin/domain/entities/branch.dart';
import 'package:tae_app/features/admin/presentation/controllers/branches_controller.dart';
import 'package:tae_app/modules/admin/widgets/adaptive_branch_list.dart';
import 'package:tae_app/modules/admin/widgets/add_dialog.dart';
import 'package:tae_app/modules/admin/widgets/custom_navigation_bar_admin.dart';
import 'package:tae_app/modules/admin/widgets/notes_button.dart';
import 'package:tae_app/modules/admin/widgets/search_bar.dart';
import 'package:tae_app/shared/presentation/color_customization.dart';

import 'group_selection.dart';
import 'profile_screen.dart';
import 'wallet_screen.dart';

class MainBranches extends StatefulWidget {
  const MainBranches({super.key});

  @override
  State<MainBranches> createState() => _MainBranchesState();
}

class _MainBranchesState extends State<MainBranches> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    BranchesScreen(),
    WalletScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: CustomNavigationBarAdmin(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

/// Transitional branch dashboard.
///
/// The screen still owns dialogs, snackbars and route transitions, but all
/// branch business operations now go through `BranchesController`.
class BranchesScreen extends StatefulWidget {
  const BranchesScreen({super.key});

  @override
  State<BranchesScreen> createState() => _BranchesScreenState();
}

class _BranchesScreenState extends State<BranchesScreen> {
  final BranchesController _controller = BranchesController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleControllerChanged);
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleControllerChanged)
      ..dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _showSnackBar(String message, {Color? backgroundColor}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: backgroundColor,
      ),
    );
  }

  Future<void> _showRenameBranchDialog(Branch branch) async {
    final controller = TextEditingController(text: branch.name);
    final newName = await showDialog<String>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Cambiar nombre de sucursal'),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Nuevo nombre',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed:
                    () => Navigator.of(dialogContext).pop(controller.text.trim()),
                child: const Text('Guardar'),
              ),
            ],
          ),
    );

    if (newName == null || newName.isEmpty || newName == branch.name) return;

    try {
      await _controller.renameBranch(branch, newName);
      _showSnackBar(
        'Sucursal renombrada a "$newName".',
        backgroundColor: Colors.green,
      );
    } on AppException catch (error) {
      _showSnackBar(error.message, backgroundColor: Colors.orange);
    } catch (error) {
      _showSnackBar(
        'No pudimos cambiar el nombre de la sucursal: $error',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _confirmDeleteBranch(Branch branch) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Borrar sucursal'),
            content: Text(
              'Se borrara "${branch.name}" y tambien todos sus grupos y registros ligados. Esta accion no se puede deshacer.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Borrar'),
              ),
            ],
          ),
    );

    if (shouldDelete != true) return;

    try {
      await _controller.deleteBranch(branch);
      _showSnackBar(
        'Sucursal "${branch.name}" eliminada correctamente.',
        backgroundColor: Colors.green,
      );
    } catch (error) {
      _showSnackBar(
        'No pudimos borrar la sucursal: $error',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _showBranchColorDialog(Branch branch) async {
    final selectedColor = await showPresetColorPickerDialog(
      context: context,
      title: 'Color para ${branch.name}',
      selectedColorValue: branch.cardColorValue,
    );

    if (selectedColor == null || selectedColor == branch.cardColorValue) {
      return;
    }

    try {
      await _controller.updateBranchColor(branch, selectedColor);
      _showSnackBar(
        'Color actualizado para "${branch.name}".',
        backgroundColor: Colors.green,
      );
    } catch (error) {
      _showSnackBar(
        'No pudimos actualizar el color: $error',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _openAddBranchDialog() async {
    final newBranchData = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => const AddDialog(),
    );

    if (newBranchData == null) return;

    final branchName = (newBranchData['name'] as String?)?.trim() ?? '';
    if (branchName.isEmpty) return;

    try {
      final branchDocId = await _controller.createBranch(branchName);
      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (context) => BranchGroupsScreen(
                branchName: branchName,
                branchDocId: branchDocId,
                successMessage: 'Sucursal "$branchName" creada exitosamente',
              ),
        ),
      );
    } on AppException catch (error) {
      _showSnackBar(error.message, backgroundColor: Colors.orange);
    } catch (error) {
      _showSnackBar(
        'Error al crear la sucursal: $error',
        backgroundColor: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.isBootstrapping) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BarSearch(
                hintText: 'Buscar sucursal',
                onSearch: _controller.updateSearchQuery,
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _controller.isMutating ? null : _openAddBranchDialog,
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Agregar Sucursal  ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(width: 5),
                          Icon(Icons.add_circle_outline),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child:
                    _controller.branchesStream == null
                        ? const Center(
                          child: Text('No pudimos identificar al administrador.'),
                        )
                        : StreamBuilder<List<Branch>>(
                          stream: _controller.branchesStream,
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return const Center(
                                child: Text('Error al cargar sucursales.'),
                              );
                            }
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            final branches = snapshot.data ?? const <Branch>[];
                            final filteredBranches =
                                _controller.filterBranches(branches);

                            if (filteredBranches.isEmpty) {
                              return Center(
                                child: Text(
                                  branches.isEmpty
                                      ? 'No hay sucursales registradas.'
                                      : 'No encontramos sucursales con esa busqueda.',
                                ),
                              );
                            }

                            return AdaptiveBranchList(
                              branches: filteredBranches,
                              icon: Icons.location_on_outlined,
                              onTap: (branch) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => BranchGroupsScreen(
                                          branchName: branch.name,
                                          branchDocId: branch.id,
                                        ),
                                  ),
                                );
                              },
                              onRename: _showRenameBranchDialog,
                              onChangeColor: _showBranchColorDialog,
                              onDelete: _confirmDeleteBranch,
                            );
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: NotesButton(),
    );
  }
}
