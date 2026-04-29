/// Business entity for the future admin licensing flow.
///
/// For now the plans are static, but keeping them out of the widget makes it
/// easier to later load them from Firestore, a backend, or remote config.
class LicensePlan {
  const LicensePlan({
    required this.id,
    required this.title,
    required this.price,
    required this.durationLabel,
    required this.features,
  });

  final String id;
  final String title;
  final int price;
  final String durationLabel;
  final List<String> features;
}
