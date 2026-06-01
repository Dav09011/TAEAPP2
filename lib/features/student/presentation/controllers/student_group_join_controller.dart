import 'package:tae_app/core/errors/app_exception.dart';
import 'package:tae_app/features/student/data/repositories/firebase_student_group_join_repository.dart';
import 'package:tae_app/features/student/domain/entities/student_group_join_result.dart';
import 'package:tae_app/features/student/domain/repositories/student_group_join_repository.dart';

class StudentGroupJoinController {
  StudentGroupJoinController({StudentGroupJoinRepository? repository})
    : _repository = repository ?? FirebaseStudentGroupJoinRepository();

  final StudentGroupJoinRepository _repository;

  Future<StudentGroupJoinResult> joinFromQr(String rawValue) {
    final payload = _parseQrPayload(rawValue);
    if (payload == null) {
      throw const AppException('QR invalido. Escanea el codigo correcto.');
    }

    if (payload.type != 'ALUMNO' && payload.type != 'PRIVILEGIADO') {
      throw const AppException('Este QR no es valido para unirse a grupos.');
    }

    final assignedRole =
        payload.type == 'PRIVILEGIADO' ? 'moderador' : 'alumno';

    return _repository.joinByGroupId(
      groupId: payload.groupId,
      fallbackGroupName: payload.groupName,
      assignedRole: assignedRole,
    );
  }

  Future<StudentGroupJoinResult> joinByManualCode(String rawCode) {
    final accessCode = _normalizeAccessCode(rawCode);
    if (accessCode.isEmpty) {
      throw const AppException('Ingresa un codigo de 6 digitos.');
    }

    return _repository.joinByAccessCode(accessCode);
  }

  String errorMessage(Object error) {
    if (error is AppException) {
      return error.message;
    }
    return 'Error inesperado: $error';
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

    return _ParsedQrPayload(type: type, groupId: groupId, groupName: groupName);
  }

  String _normalizeAccessCode(String rawCode) {
    return rawCode.replaceAll(RegExp(r'[^0-9]'), '').trim();
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
