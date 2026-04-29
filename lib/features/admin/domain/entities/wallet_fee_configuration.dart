class WalletFeeConfiguration {
  const WalletFeeConfiguration({
    required this.id,
    required this.title,
    required this.amountLabel,
    required this.scheduleLabel,
    required this.notes,
    required this.supportsScholarships,
  });

  final String id;
  final String title;
  final String amountLabel;
  final String scheduleLabel;
  final String notes;
  final bool supportsScholarships;
}
