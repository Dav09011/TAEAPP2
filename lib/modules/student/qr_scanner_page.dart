import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final MobileScannerController _cameraController = MobileScannerController();
  final TextEditingController _manualCodeController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _manualCodeController.dispose();
    _cameraController.dispose();
    super.dispose();
  }

  Future<void> _processQR(String rawValue) async {
    final payload = _parseQrPayload(rawValue);
    if (payload == null) {
      _showError('QR invalido. Escanea el codigo correcto.');
      return;
    }

    if (payload.type != 'ALUMNO') {
      _showError('Este QR no es para alumnos.');
      return;
    }

    await _joinGroupById(
      payload.groupId,
      fallbackGroupName: payload.groupName,
    );
  }

  _ParsedQrPayload? _parseQrPayload(String rawValue) {
    final parts = rawValue.split('|');
    if (parts.length < 2) {
      return null;
    }

    final type = parts.first.trim();
    final groupIdEntry = parts.where((part) => part.startsWith('GrupoId:'));
    final groupNameEntry = parts.where((part) => part.startsWith('Grupo:'));
    if (groupIdEntry.isEmpty) {
      return null;
    }

    final groupId = groupIdEntry.first.replaceFirst('GrupoId:', '').trim();
    if (groupId.isEmpty) {
      return null;
    }

    final groupName =
        groupNameEntry.isNotEmpty
            ? groupNameEntry.first.replaceFirst('Grupo:', '').trim()
            : '';

    return _ParsedQrPayload(
      type: type,
      groupId: groupId,
      groupName: groupName,
    );
  }

  Future<void> _openManualCodeDialog() async {
    _manualCodeController.clear();
    final manualCode = await showDialog<String>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Ingresar codigo'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Si no puedes escanear el QR, escribe el codigo que te comparta tu administrador.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _manualCodeController,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'Codigo de acceso',
                    hintText: 'Ej. 123456',
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                onPressed:
                    () => Navigator.of(
                      dialogContext,
                    ).pop(_manualCodeController.text),
                child: const Text('Unirme'),
              ),
            ],
          ),
    );

    if (manualCode == null) {
      return;
    }

    await _joinGroupByCode(manualCode);
  }

  Future<void> _joinGroupByCode(String rawCode) async {
    final accessCode = _normalizeAccessCode(rawCode);
    if (accessCode.isEmpty) {
      _showError('Ingresa un codigo de 6 digitos.');
      return;
    }

    if (!await _startProcessing()) {
      return;
    }

    try {
      final groupQuery =
          await FirebaseFirestore.instance
              .collection('grupos')
              .where('codigo_alumno', isEqualTo: accessCode)
              .limit(1)
              .get();

      if (groupQuery.docs.isEmpty) {
        _showError('No encontramos un grupo con ese codigo.');
        return;
      }

      await _joinGroupFromSnapshot(groupQuery.docs.first);
    } catch (error) {
      _showError('Error inesperado: $error');
    }
  }

  Future<void> _joinGroupById(
    String groupId, {
    String? fallbackGroupName,
  }) async {
    if (!await _startProcessing()) {
      return;
    }

    try {
      final groupSnapshot =
          await FirebaseFirestore.instance.collection('grupos').doc(groupId).get();

      if (!groupSnapshot.exists) {
        _showError('El grupo ya no esta disponible. Pide un QR actualizado.');
        return;
      }

      await _joinGroupFromSnapshot(
        groupSnapshot,
        fallbackGroupName: fallbackGroupName,
      );
    } catch (error) {
      _showError('Error inesperado: $error');
    }
  }

  Future<void> _joinGroupFromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> groupSnapshot, {
    String? fallbackGroupName,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showError('No hay sesion activa.');
      return;
    }

    final db = FirebaseFirestore.instance;
    final groupId = groupSnapshot.id;
    final groupData = groupSnapshot.data() ?? const <String, dynamic>{};
    final groupName =
        (groupData['nombre_grupo'] as String?)?.trim().isNotEmpty == true
            ? (groupData['nombre_grupo'] as String).trim()
            : (fallbackGroupName?.trim().isNotEmpty == true
                ? fallbackGroupName!.trim()
                : groupId);

    final enrolledStudent =
        await db
            .collection('grupos')
            .doc(groupId)
            .collection('alumnos')
            .where('uid', isEqualTo: user.uid)
            .limit(1)
            .get();

    if (enrolledStudent.docs.isNotEmpty) {
      _showError('Ya estas inscrito en el grupo "$groupName".');
      return;
    }

    final userSnapshot = await db.collection('usuarios').doc(user.uid).get();
    final userData = userSnapshot.data() ?? const <String, dynamic>{};
    final studentName =
        '${userData['nombre'] ?? ''} ${userData['ap'] ?? ''}'.trim();
    final beltType = groupData['tipo_cinta']?.toString() ?? '';
    final branchId = groupData['id_sucursal']?.toString() ?? '';
    final schedule = groupData['horario']?.toString() ?? '';
    final branchName = await _resolveBranchName(
      db: db,
      groupId: groupId,
      groupData: groupData,
    );

    await db.collection('grupos').doc(groupId).collection('alumnos').add({
      'uid': user.uid,
      'nombre': studentName,
      'cinta': beltType,
      'imagen': userData['imagen'] ?? '',
      'fecha_ingreso': FieldValue.serverTimestamp(),
    });

    await db.collection('grupos').doc(groupId).update({
      'total_alumnos': FieldValue.increment(1),
    });

    if (branchId.isNotEmpty) {
      await db.collection('sucursales').doc(branchId).update({
        'participants': FieldValue.increment(1),
      });
    }

    await db.collection('usuarios').doc(user.uid).set({
      'grupos': FieldValue.arrayUnion([
        {
          'groupId': groupId,
          'groupName': groupName,
          'branchName': branchName,
          'beltType': beltType,
          'schedule': schedule,
        },
      ]),
      'grupo_id': groupId,
      'grupo_nombre': groupName,
      'grupo_sucursal': branchName,
      'grupo_cinta': beltType,
      'grupo_horario': schedule,
    }, SetOptions(merge: true));

    if (mounted) {
      _showSuccess(groupName);
    }
  }

  Future<String> _resolveBranchName({
    required FirebaseFirestore db,
    required String groupId,
    required Map<String, dynamic> groupData,
  }) async {
    final savedBranchName = groupData['nombre_sucursal']?.toString().trim();
    if (savedBranchName != null && savedBranchName.isNotEmpty) {
      return savedBranchName;
    }

    final branchId = groupData['id_sucursal']?.toString().trim() ?? '';
    if (branchId.isEmpty) {
      return 'Sucursal no disponible';
    }

    final branchSnapshot = await db.collection('sucursales').doc(branchId).get();
    final branchName = branchSnapshot.data()?['name']?.toString().trim() ?? '';

    if (branchName.isNotEmpty) {
      await db.collection('grupos').doc(groupId).set({
        'nombre_sucursal': branchName,
      }, SetOptions(merge: true));
      return branchName;
    }

    return branchId;
  }

  String _normalizeAccessCode(String rawCode) {
    return rawCode.replaceAll(RegExp(r'[^0-9]'), '').trim();
  }

  Future<bool> _startProcessing() async {
    if (_isProcessing) {
      return false;
    }

    setState(() => _isProcessing = true);
    await _cameraController.stop();
    return true;
  }

  void _restartScanner() {
    _cameraController.start();
    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red),
                SizedBox(width: 8),
                Text('Error'),
              ],
            ),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _restartScanner();
                },
                child: const Text(
                  'Intentar de nuevo',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ],
          ),
    );
  }

  void _showSuccess(String groupName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.green),
                SizedBox(width: 8),
                Text('Listo'),
              ],
            ),
            content: Text('Te has unido al grupo "$groupName" exitosamente.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text(
                  'Aceptar',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Escanear QR', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton.icon(
            onPressed: _openManualCodeDialog,
            icon: const Icon(Icons.pin_outlined, color: Colors.white),
            label: const Text(
              'Codigo',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _cameraController,
            onDetect: (capture) {
              final barcode = capture.barcodes.firstOrNull;
              if (barcode?.rawValue != null) {
                _processQR(barcode!.rawValue!);
              }
            },
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 48,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Apunta al codigo QR del grupo',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _openManualCodeDialog,
                    icon: const Icon(Icons.keyboard_alt_outlined),
                    label: const Text('No puedo escanear, ingresar codigo'),
                  ),
                ),
              ],
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

class _ParsedQrPayload {
  const _ParsedQrPayload({
    required this.type,
    required this.groupId,
    required this.groupName,
  });

  final String type;
  final String groupId;
  final String groupName;
}
