import 'package:tae_app/features/licensing/domain/entities/license_plan.dart';

/// Temporary in-memory catalog for admin license offers.
///
/// This is the first extraction step before we implement real purchasing
/// options. UI screens should read plans from here instead of hardcoding them.
abstract final class LicensePlanCatalog {
  static const plans = <LicensePlan>[
    LicensePlan(
      id: 'master',
      title: 'MASTER',
      price: 1799,
      durationLabel: '6ms',
      features: [
        '3 sucursales',
        'Crea grupos',
        'Asigna contenido',
        'Realiza notas',
        'Administra tus finanzas',
      ],
    ),
    LicensePlan(
      id: 'tilin',
      title: 'TILIN',
      price: 1200,
      durationLabel: '3ms',
      features: [
        '1 sucursal',
        'Sin grupos',
        'Contenido limitado',
        'Notas basicas',
        'Solo estadisticas basicas',
      ],
    ),
  ];
}
