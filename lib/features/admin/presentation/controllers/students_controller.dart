import 'package:flutter/foundation.dart';
import 'package:tae_app/features/admin/data/repositories/firebase_student_repository.dart';
import 'package:tae_app/features/admin/domain/entities/admin_student.dart';
import 'package:tae_app/features/admin/domain/repositories/student_repository.dart';

class StudentsController extends ChangeNotifier {
  StudentsController({StudentRepository? studentRepository})
    : _studentRepository = studentRepository ?? FirebaseStudentRepository();

  final StudentRepository _studentRepository;

  String _searchQuery = '';
  bool _isMutating = false;

  String get searchQuery => _searchQuery;
  bool get isMutating => _isMutating;

  Stream<List<AdminStudent>> watchStudentsByGroup(String groupId) {
    return _studentRepository.watchStudentsByGroup(groupId);
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Map<String, List<AdminStudent>> groupByBelt(List<AdminStudent> students) {
    final grouped = <String, List<AdminStudent>>{};
    for (final student in students) {
      grouped.putIfAbsent(student.belt, () => []);
      grouped[student.belt]!.add(student);
    }
    return grouped;
  }

  Map<String, List<AdminStudent>> filterGroupedStudents(
    Map<String, List<AdminStudent>> grouped,
  ) {
    if (_searchQuery.isEmpty) return grouped;

    final normalized = _searchQuery.toLowerCase();
    final result = <String, List<AdminStudent>>{};

    for (final entry in grouped.entries) {
      final matches =
          entry.value
              .where((student) => student.name.toLowerCase().contains(normalized))
              .toList();
      if (matches.isNotEmpty) {
        result[entry.key] = matches;
      }
    }

    return result;
  }

  Future<void> deleteStudents({
    required String groupId,
    required List<String> studentIds,
  }) async {
    _isMutating = true;
    notifyListeners();
    try {
      await _studentRepository.deleteStudents(
        groupId: groupId,
        studentIds: studentIds,
      );
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }
}
