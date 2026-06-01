import 'package:flutter/foundation.dart';
import 'package:tae_app/features/admin/data/repositories/firebase_notes_repository.dart';
import 'package:tae_app/features/admin/domain/entities/admin_grouped_student.dart';
import 'package:tae_app/features/admin/domain/entities/admin_note_entry.dart';
import 'package:tae_app/features/admin/domain/entities/admin_notes_student.dart';
import 'package:tae_app/features/admin/domain/repositories/notes_repository.dart';

class NotesController extends ChangeNotifier {
  NotesController({NotesRepository? notesRepository})
    : _notesRepository = notesRepository ?? FirebaseNotesRepository();

  final NotesRepository _notesRepository;

  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  List<AdminNotesStudent> _students = const [];

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  List<AdminNotesStudent> get students => _students;

  Stream<List<AdminGroupedStudent>> watchLegacyStudents() {
    return _notesRepository.watchLegacyStudents();
  }

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _students = await _notesRepository.loadStudentsWithNotes();
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reload() => load();

  Future<AdminNoteEntry> createEntry({
    required AdminNotesStudent student,
    required String content,
    required bool isPinned,
  }) async {
    _isSaving = true;
    notifyListeners();
    try {
      final created = await _notesRepository.createEntry(
        student: student,
        content: content,
        isPinned: isPinned,
      );
      _students =
          _students.map((item) {
            if (item.id != student.id) {
              return item;
            }
            final entries = [created, ...item.entries]..sort(_sortEntries);
            return item.copyWith(entries: entries);
          }).toList();
      return created;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<AdminNoteEntry> updateEntry({
    required AdminNotesStudent student,
    required AdminNoteEntry entry,
    required String content,
    required bool isPinned,
  }) async {
    _isSaving = true;
    notifyListeners();
    try {
      final updated = await _notesRepository.updateEntry(
        student: student,
        entry: entry,
        content: content,
        isPinned: isPinned,
      );
      _students =
          _students.map((item) {
            if (item.id != student.id) {
              return item;
            }
            final entries =
                item.entries
                    .map(
                      (current) => current.id == entry.id ? updated : current,
                    )
                    .toList()
                  ..sort(_sortEntries);
            return item.copyWith(entries: entries);
          }).toList();
      return updated;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> togglePinned({
    required AdminNotesStudent student,
    required AdminNoteEntry entry,
  }) async {
    _isSaving = true;
    notifyListeners();
    try {
      await _notesRepository.setEntryPinned(
        student: student,
        entry: entry,
        isPinned: !entry.isPinned,
      );
      _students =
          _students.map((item) {
            if (item.id != student.id) {
              return item;
            }
            final entries =
                item.entries
                    .map(
                      (current) =>
                          current.id == entry.id
                              ? current.copyWith(
                                isPinned: !current.isPinned,
                                updatedAt: DateTime.now(),
                              )
                              : current,
                    )
                    .toList()
                  ..sort(_sortEntries);
            return item.copyWith(entries: entries);
          }).toList();
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> deleteEntry({
    required AdminNotesStudent student,
    required AdminNoteEntry entry,
  }) async {
    _isSaving = true;
    notifyListeners();
    try {
      await _notesRepository.deleteEntry(student: student, entry: entry);
      _students =
          _students.map((item) {
            if (item.id != student.id) {
              return item;
            }
            final entries =
                item.entries.where((current) => current.id != entry.id).toList()
                  ..sort(_sortEntries);
            return item.copyWith(entries: entries);
          }).toList();
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> restoreEntry({
    required AdminNotesStudent student,
    required AdminNoteEntry entry,
  }) async {
    _isSaving = true;
    notifyListeners();
    try {
      await _notesRepository.restoreEntry(student: student, entry: entry);
      _students =
          _students.map((item) {
            if (item.id != student.id) {
              return item;
            }
            final entries = [entry, ...item.entries]..sort(_sortEntries);
            return item.copyWith(entries: entries);
          }).toList();
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  int _sortEntries(AdminNoteEntry a, AdminNoteEntry b) {
    if (a.isPinned != b.isPinned) {
      return a.isPinned ? -1 : 1;
    }
    return b.updatedAt.compareTo(a.updatedAt);
  }
}
