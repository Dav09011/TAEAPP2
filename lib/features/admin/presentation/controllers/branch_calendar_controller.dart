import 'package:tae_app/core/errors/app_exception.dart';
import 'package:tae_app/features/admin/data/repositories/firebase_branch_calendar_repository.dart';
import 'package:tae_app/features/admin/domain/entities/admin_branch_calendar_event.dart';
import 'package:tae_app/features/admin/domain/repositories/branch_calendar_repository.dart';

class BranchCalendarController {
  BranchCalendarController({BranchCalendarRepository? repository})
    : _repository = repository ?? FirebaseBranchCalendarRepository();

  final BranchCalendarRepository _repository;

  Stream<List<AdminBranchCalendarEvent>> watchEvents(String branchId) {
    return _repository.watchEvents(branchId);
  }

  Future<void> saveEvent({
    required String branchId,
    required AdminBranchCalendarEventRequest request,
    String? eventId,
  }) {
    return _repository.saveEvent(
      branchId: branchId,
      request: request,
      eventId: eventId,
    );
  }

  Future<void> deleteEvent({
    required String branchId,
    required String eventId,
  }) {
    return _repository.deleteEvent(branchId: branchId, eventId: eventId);
  }

  String errorMessage(Object? error) {
    if (error is AppException) {
      return error.message;
    }
    return 'No pudimos completar la accion del calendario.';
  }
}
