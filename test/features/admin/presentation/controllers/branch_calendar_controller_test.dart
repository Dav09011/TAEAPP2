import 'package:flutter_test/flutter_test.dart';
import 'package:tae_app/core/errors/app_exception.dart';
import 'package:tae_app/features/admin/domain/entities/admin_branch_calendar_event.dart';
import 'package:tae_app/features/admin/domain/repositories/branch_calendar_repository.dart';
import 'package:tae_app/features/admin/presentation/controllers/branch_calendar_controller.dart';

void main() {
  test('watches, saves, and deletes branch calendar events', () async {
    final event = AdminBranchCalendarEvent(
      id: 'event-1',
      title: 'Examen',
      type: 'Examen',
      date: DateTime(2026, 6, 1),
      timeLabel: '18:00',
      notes: 'Traer equipo',
      repeatModeName: 'none',
      repeatInterval: 0,
      repeatUnitName: 'days',
    );
    final repository = _FakeBranchCalendarRepository(events: [event]);
    final controller = BranchCalendarController(repository: repository);

    final events = await controller.watchEvents('branch-1').first;
    await controller.saveEvent(
      branchId: 'branch-1',
      eventId: 'event-1',
      request: AdminBranchCalendarEventRequest(
        title: 'Clase',
        type: 'Clase',
        date: DateTime(2026, 6, 2),
        timeLabel: '19:00',
        notes: '',
        repeatModeName: 'weekly',
        repeatInterval: 1,
        repeatUnitName: 'weeks',
      ),
    );
    await controller.deleteEvent(branchId: 'branch-1', eventId: 'event-1');

    expect(repository.watchedBranchId, 'branch-1');
    expect(events.single.title, 'Examen');
    expect(repository.savedBranchId, 'branch-1');
    expect(repository.savedEventId, 'event-1');
    expect(repository.savedRequest?.repeatModeName, 'weekly');
    expect(repository.deletedBranchId, 'branch-1');
    expect(repository.deletedEventId, 'event-1');
    expect(
      controller.errorMessage(const AppException('Calendario roto')),
      'Calendario roto',
    );
  });
}

class _FakeBranchCalendarRepository implements BranchCalendarRepository {
  _FakeBranchCalendarRepository({required this.events});

  final List<AdminBranchCalendarEvent> events;

  String? watchedBranchId;
  String? savedBranchId;
  String? savedEventId;
  AdminBranchCalendarEventRequest? savedRequest;
  String? deletedBranchId;
  String? deletedEventId;

  @override
  Stream<List<AdminBranchCalendarEvent>> watchEvents(String branchId) {
    watchedBranchId = branchId;
    return Stream.value(events);
  }

  @override
  Future<void> saveEvent({
    required String branchId,
    required AdminBranchCalendarEventRequest request,
    String? eventId,
  }) async {
    savedBranchId = branchId;
    savedEventId = eventId;
    savedRequest = request;
  }

  @override
  Future<void> deleteEvent({
    required String branchId,
    required String eventId,
  }) async {
    deletedBranchId = branchId;
    deletedEventId = eventId;
  }
}
