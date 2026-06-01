import 'package:tae_app/features/admin/domain/entities/admin_branch_calendar_event.dart';

abstract class BranchCalendarRepository {
  Stream<List<AdminBranchCalendarEvent>> watchEvents(String branchId);

  Future<void> saveEvent({
    required String branchId,
    required AdminBranchCalendarEventRequest request,
    String? eventId,
  });

  Future<void> deleteEvent({required String branchId, required String eventId});
}
