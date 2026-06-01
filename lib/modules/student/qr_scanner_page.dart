import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:tae_app/features/student/domain/entities/student_group_join_result.dart';
import 'package:tae_app/features/student/presentation/controllers/student_group_join_controller.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key, StudentGroupJoinController? controller})
    : _controller = controller;

  final StudentGroupJoinController? _controller;

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final MobileScannerController _cameraController = MobileScannerController();
  final TextEditingController _manualCodeController = TextEditingController();
  late final StudentGroupJoinController _joinController;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _joinController = widget._controller ?? StudentGroupJoinController();
  }

  @override
  void dispose() {
    _manualCodeController.dispose();
    _cameraController.dispose();
    super.dispose();
  }

  Future<void> _processQR(String rawValue) async {
    await _runJoin(() => _joinController.joinFromQr(rawValue));
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
    await _runJoin(() => _joinController.joinByManualCode(rawCode));
  }

  Future<void> _runJoin(
    Future<StudentGroupJoinResult> Function() joinAction,
  ) async {
    if (!await _startProcessing()) {
      return;
    }

    try {
      final result = await joinAction();
      if (!mounted) return;
      _showSuccess(result.groupName);
    } catch (error) {
      _showError(_joinController.errorMessage(error));
    }
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
            label: const Text('Codigo', style: TextStyle(color: Colors.white)),
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
