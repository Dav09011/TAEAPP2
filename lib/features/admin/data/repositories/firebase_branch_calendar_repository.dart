import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tae_app/core/services/firestore_service.dart';
import 'package:tae_app/features/admin/domain/entities/admin_branch_calendar_event.dart';
import 'package:tae_app/features/admin/domain/repositories/branch_calendar_repository.dart';

class FirebaseBranchCalendarRepository implements BranchCalendarRepository {
  FirebaseBranchCalendarRepository({FirestoreService? firestoreService})
    : _firestoreService = firestoreService ?? FirestoreService();

  final FirestoreService _firestoreService;

  @override
  Stream<List<AdminBranchCalendarEvent>> watchEvents(String branchId) {
    return _events(branchId).orderBy('event_date').snapshots().map((snapshot) {
      return snapshot.docs.map(_mapEvent).toList();
    });
  }

  @override
  Future<void> saveEvent({
    required String branchId,
    required AdminBranchCalendarEventRequest request,
    String? eventId,
  }) {
    final payload = {
      'title': request.title,
      'time_label': request.timeLabel,
      'notes': request.notes,
      'type': request.type,
      'event_date': Timestamp.fromDate(_normalizeDay(request.date)),
      'repeat_mode': request.repeatModeName,
      'repeat_interval': request.repeatInterval,
      'repeat_unit': request.repeatUnitName,
      'updated_at': FieldValue.serverTimestamp(),
    };

    final events = _events(branchId);
    if (eventId == null || eventId.isEmpty) {
      return events.add({
        ...payload,
        'created_at': FieldValue.serverTimestamp(),
      });
    }

    return events.doc(eventId).set(payload, SetOptions(merge: true));
  }

  @override
  Future<void> deleteEvent({
    required String branchId,
    required String eventId,
  }) {
    return _events(branchId).doc(eventId).delete();
  }

  CollectionReference<Map<String, dynamic>> _events(String branchId) {
    return _firestoreService.branches().doc(branchId).collection('eventos');
  }

  AdminBranchCalendarEvent _mapEvent(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return AdminBranchCalendarEvent(
      id: doc.id,
      title: data['title']?.toString() ?? 'Evento',
      type: data['type']?.toString() ?? 'Otro',
      date: _normalizeDay(
        (data['event_date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      ),
      timeLabel: data['time_label']?.toString() ?? '',
      notes: data['notes']?.toString() ?? '',
      repeatModeName: data['repeat_mode']?.toString() ?? 'none',
      repeatInterval: (data['repeat_interval'] as num?)?.toInt() ?? 0,
      repeatUnitName: data['repeat_unit']?.toString() ?? 'days',
    );
  }

  DateTime _normalizeDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
