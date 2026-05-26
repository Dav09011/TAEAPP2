import 'package:tae_app/features/admin/domain/entities/admin_note_entry.dart';
import 'package:tae_app/features/admin/domain/entities/admin_notes_student.dart';

abstract class NotesRepository {
  Future<List<AdminNotesStudent>> loadStudentsWithNotes();

  Future<AdminNoteEntry> createEntry({
    required AdminNotesStudent student,
    required String content,
    required bool isPinned,
  });

  Future<AdminNoteEntry> updateEntry({
    required AdminNotesStudent student,
    required AdminNoteEntry entry,
    required String content,
    required bool isPinned,
  });

  Future<void> setEntryPinned({
    required AdminNotesStudent student,
    required AdminNoteEntry entry,
    required bool isPinned,
  });

  Future<void> deleteEntry({
    required AdminNotesStudent student,
    required AdminNoteEntry entry,
  });

  Future<void> restoreEntry({
    required AdminNotesStudent student,
    required AdminNoteEntry entry,
  });
}
