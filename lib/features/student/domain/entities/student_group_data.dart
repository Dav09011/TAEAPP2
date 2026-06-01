class StudentGroupData {
  const StudentGroupData({
    required this.groupId,
    required this.groupName,
    required this.cachedData,
  });

  final String groupId;
  final String groupName;
  final Map<String, dynamic> cachedData;
}

class StudentGroupDetails {
  const StudentGroupDetails({
    required this.groupId,
    required this.exists,
    required this.groupName,
    required this.branchName,
    required this.beltType,
    required this.schedule,
    required this.totalStudents,
    required this.role,
    this.branchColorValue,
    this.groupColorValue,
  });

  final String groupId;
  final bool exists;
  final String groupName;
  final String branchName;
  final String beltType;
  final String schedule;
  final int totalStudents;
  final String role;
  final int? branchColorValue;
  final int? groupColorValue;

  factory StudentGroupDetails.missing(StudentGroupData group) {
    return StudentGroupDetails(
      groupId: group.groupId,
      exists: false,
      groupName: group.groupName,
      branchName: 'Sucursal no disponible',
      beltType: 'Sin cinta asignada',
      schedule: 'Horario pendiente',
      totalStudents: 0,
      role: _stringValue(group.cachedData['rol_en_grupo'], fallback: 'alumno'),
      branchColorValue: (group.cachedData['color_sucursal'] as num?)?.toInt(),
      groupColorValue: (group.cachedData['group_card_color'] as num?)?.toInt(),
    );
  }

  factory StudentGroupDetails.fromData({
    required StudentGroupData fallback,
    required Map<String, dynamic> data,
  }) {
    return StudentGroupDetails(
      groupId: fallback.groupId,
      exists: true,
      groupName: _stringValue(
        data['nombre_grupo'],
        fallback: fallback.groupName,
      ),
      branchName: _stringValue(
        data['nombre_sucursal'],
        fallback: _stringValue(
          fallback.cachedData['nombre_sucursal'],
          fallback: _stringValue(
            data['id_sucursal'],
            fallback: 'Sucursal no disponible',
          ),
        ),
      ),
      beltType: _stringValue(
        data['tipo_cinta'],
        fallback: 'Sin cinta asignada',
      ),
      schedule: _stringValue(data['horario'], fallback: 'Horario pendiente'),
      totalStudents: (data['total_alumnos'] as num?)?.toInt() ?? 0,
      role: _stringValue(
        fallback.cachedData['rol_en_grupo'],
        fallback: 'alumno',
      ),
      branchColorValue:
          (data['color_sucursal'] as num?)?.toInt() ??
          (fallback.cachedData['color_sucursal'] as num?)?.toInt(),
      groupColorValue:
          (data['group_card_color'] as num?)?.toInt() ??
          (fallback.cachedData['group_card_color'] as num?)?.toInt(),
    );
  }
}

String _stringValue(Object? value, {required String fallback}) {
  final text = value?.toString().trim() ?? '';
  return text.isNotEmpty ? text : fallback;
}
