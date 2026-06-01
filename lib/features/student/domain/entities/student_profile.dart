class StudentProfile {
  const StudentProfile({
    required this.userId,
    required this.authEmail,
    required this.data,
  });

  final String userId;
  final String? authEmail;
  final Map<String, dynamic> data;

  String get firstName => _stringValue(data['nombre']);
  String get lastName => _stringValue(data['ap']);
  String get middleName => _stringValue(data['am']);

  String get fullName => '$firstName $lastName $middleName'.trim();

  String get email => _stringValue(
    data['correo'],
    fallback:
        authEmail == null || authEmail!.trim().isEmpty
            ? 'Sin correo'
            : authEmail!.trim(),
  );

  String get editableEmail =>
      _stringValue(data['correo'], fallback: authEmail ?? '');
  String get editablePhone => _stringValue(data['telefono']);

  String get phone => _stringValue(data['telefono'], fallback: 'Sin telefono');
  String get role => _stringValue(data['tipo'], fallback: 'alumno');
  String get imageUrl => _stringValue(data['imagen']);
  String get personalBelt => _stringValue(data['cinta_personal']);

  int? get personalBeltColorValue =>
      (data['cinta_personal_color'] as num?)?.toInt();
}

String _stringValue(Object? value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isNotEmpty ? text : fallback;
}
