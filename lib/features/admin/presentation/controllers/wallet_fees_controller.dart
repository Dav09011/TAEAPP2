import 'package:flutter/foundation.dart';
import 'package:tae_app/features/admin/domain/entities/wallet_fee_configuration.dart';

/// Holds the wallet fee catalog while the payment domain is still being
/// formalized.
///
/// This controller intentionally starts with seeded data so the UI can stop
/// being an empty placeholder without forcing us to invent persistence rules
/// too early. When real storage is defined, this controller should delegate to
/// a repository just like the rest of the admin feature.
class WalletFeesController extends ChangeNotifier {
  final List<WalletFeeConfiguration> _configurations = const [
    WalletFeeConfiguration(
      id: 'monthly-2-days',
      title: 'Mensualidad 2 dias',
      amountLabel: r'$850 MXN',
      scheduleLabel: '2 clases por semana',
      notes: 'Plan base para alumnos regulares con asistencia parcial.',
      supportsScholarships: true,
    ),
    WalletFeeConfiguration(
      id: 'monthly-unlimited',
      title: 'Mensualidad ilimitada',
      amountLabel: r'$1,150 MXN',
      scheduleLabel: 'Acceso libre a clases disponibles',
      notes: 'Usar para alumnos con frecuencia alta o grupos competitivos.',
      supportsScholarships: true,
    ),
    WalletFeeConfiguration(
      id: 'registration',
      title: 'Inscripcion',
      amountLabel: r'$500 MXN',
      scheduleLabel: 'Cobro unico',
      notes: 'Incluye alta administrativa y apertura del expediente.',
      supportsScholarships: false,
    ),
    WalletFeeConfiguration(
      id: 'exam',
      title: 'Examen de cinta',
      amountLabel: r'$650 MXN',
      scheduleLabel: 'Por evaluacion programada',
      notes: 'Se recomienda separar este cobro del pago mensual.',
      supportsScholarships: false,
    ),
  ];

  List<WalletFeeConfiguration> get configurations =>
      List<WalletFeeConfiguration>.unmodifiable(_configurations);
}
