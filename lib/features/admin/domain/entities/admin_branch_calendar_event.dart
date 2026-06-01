class AdminBranchCalendarEvent {
  const AdminBranchCalendarEvent({
    required this.id,
    required this.title,
    required this.type,
    required this.date,
    required this.timeLabel,
    required this.notes,
    required this.repeatModeName,
    required this.repeatInterval,
    required this.repeatUnitName,
  });

  final String id;
  final String title;
  final String type;
  final DateTime date;
  final String timeLabel;
  final String notes;
  final String repeatModeName;
  final int repeatInterval;
  final String repeatUnitName;
}

class AdminBranchCalendarEventRequest {
  const AdminBranchCalendarEventRequest({
    required this.title,
    required this.type,
    required this.date,
    required this.timeLabel,
    required this.notes,
    required this.repeatModeName,
    required this.repeatInterval,
    required this.repeatUnitName,
  });

  final String title;
  final String type;
  final DateTime date;
  final String timeLabel;
  final String notes;
  final String repeatModeName;
  final int repeatInterval;
  final String repeatUnitName;
}
