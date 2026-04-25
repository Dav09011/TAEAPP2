import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final MobileScannerController _cameraController = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  // =================================================================
  // === PROCESAR QR ESCANEADO =======================================
  // =================================================================
  Future<void> _processQR(String rawValue) async {
  if (_isProcessing) return;
  setState(() => _isProcessing = true);
  await _cameraController.stop();

  try {
    // 1. Parsear QR
    final parts = rawValue.split('|');
    if (parts.length < 2) {
      _showError('QR inválido. Escanea el código correcto.');
      return;
    }

    final tipo = parts[0];
    if (tipo != 'ALUMNO') {
      _showError('Este QR no es para alumnos.');
      return;
    }

    // 2. Extraer GrupoId y nombre del grupo
    final grupoIdEntry = parts.firstWhere(
      (p) => p.startsWith('GrupoId:'),
      orElse: () => '',
    );
    final grupoNameEntry = parts.firstWhere(
      (p) => p.startsWith('Grupo:'),
      orElse: () => '',
    );

    if (grupoIdEntry.isEmpty) {
      _showError('QR sin ID de grupo. Regenera el QR.');
      return;
    }

    final grupoId = grupoIdEntry.replaceFirst('GrupoId:', '');
    final nombreGrupo = grupoNameEntry.replaceFirst('Grupo:', '');

    // 3. Obtener alumno logueado
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showError('No hay sesión activa.');
      return;
    }

    final db = FirebaseFirestore.instance;

    // 4. Verificar si el alumno ya está en el grupo (busca por campo, no por ID)
final alumnoQuery = await db
    .collection('grupos')
    .doc(grupoId)
    .collection('alumnos')
    .where('uid', isEqualTo: user.uid) // 👈 busca por campo
    .limit(1)
    .get();

if (alumnoQuery.docs.isNotEmpty) {
  _showError('Ya estás inscrito en el grupo "$nombreGrupo".');
  return;
}

// 5. Obtener datos del alumno desde 'usuarios'
final usuarioSnap = await db.collection('usuarios').doc(user.uid).get();
final usuarioData = usuarioSnap.data() ?? {};
final nombre =
    '${usuarioData['nombre'] ?? ''} ${usuarioData['ap'] ?? ''}'.trim();

    // 6. Obtener informacion del grupo para guardar la relacion en el perfil
final grupoSnap = await db.collection('grupos').doc(grupoId).get();
final grupoData = grupoSnap.data() ?? {};
final cinta = grupoData['tipo_cinta'] ?? '';
final sucursal = grupoData['id_sucursal'] ?? '';
final horario = grupoData['horario'] ?? '';

// 7. Agregar alumno con ID autogenerado (igual que los existentes)
await db
    .collection('grupos')
    .doc(grupoId)
    .collection('alumnos')
    .add({                                    // 👈 .add() en lugar de .doc().set()
      'uid': user.uid,                        // 👈 guarda el UID como campo
      'nombre': nombre,
      'cinta': cinta,
      'imagen': usuarioData['imagen'] ?? '',
      'fecha_ingreso': FieldValue.serverTimestamp(),
    });

// 8. Incrementar total_alumnos
await db.collection('grupos').doc(grupoId).update({
  'total_alumnos': FieldValue.increment(1),
});

// 8.1 Guardar acceso rapido al grupo en el documento del usuario
await db.collection('usuarios').doc(user.uid).set({
  'grupos': FieldValue.arrayUnion([
    {
      'groupId': grupoId,
      'groupName': nombreGrupo,
      'branchName': sucursal,
      'beltType': cinta,
      'schedule': horario,
    }
  ]),
  'grupo_id': grupoId,
  'grupo_nombre': nombreGrupo,
  'grupo_sucursal': sucursal,
  'grupo_cinta': cinta,
  'grupo_horario': horario,
}, SetOptions(merge: true));

// 9. Éxito
if (mounted) _showSuccess(nombreGrupo);

  } catch (e) {
    _showError('Error inesperado: $e');
  }
}

  void _showError(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              // Reactivar escáner para intentar de nuevo
              _cameraController.start();
              setState(() => _isProcessing = false);
            },
            child: const Text('Intentar de nuevo',
                style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _showSuccess(String nombreGrupo) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green),
            SizedBox(width: 8),
            Text('¡Listo!'),
          ],
        ),
        content: Text('Te has unido al grupo "$nombreGrupo" exitosamente.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Cierra dialog
              Navigator.pop(context); // Regresa a HomePageStudent
            },
            child: const Text('Aceptar',
                style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  // =================================================================
  // === UI ==========================================================
  // =================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Escanear QR',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Cámara
          MobileScanner(
            controller: _cameraController,
            onDetect: (capture) {
              final barcode = capture.barcodes.firstOrNull;
              if (barcode?.rawValue != null) {
                _processQR(barcode!.rawValue!);
              }
            },
          ),

          // Marco de escaneo
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

          // Texto guía
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Apunta al código QR del grupo',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),

          // Indicador de procesando
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
