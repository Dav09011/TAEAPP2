class AdminWalletFilterOption {
  const AdminWalletFilterOption({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;

  @override
  bool operator ==(Object other) {
    return other is AdminWalletFilterOption &&
        other.id == id &&
        other.label == label;
  }

  @override
  int get hashCode => Object.hash(id, label);
}
