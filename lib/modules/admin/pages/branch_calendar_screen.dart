import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class BranchCalendarScreen extends StatefulWidget {
  const BranchCalendarScreen({
    super.key,
    this.branchId,
    this.branchName,
    this.isReadOnly = false,
  });

  final String? branchId;
  final String? branchName;
  final bool isReadOnly;

  @override
  State<BranchCalendarScreen> createState() => _BranchCalendarScreenState();
}

class _BranchCalendarScreenState extends State<BranchCalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = _normalizeDay(DateTime.now());
  DateTime _selectedDay = _normalizeDay(DateTime.now());
  static final DateTime _calendarFirstDay =
      _normalizeDay(DateTime.now().subtract(const Duration(days: 365)));
  static final DateTime _calendarLastDay =
      _normalizeDay(DateTime.now().add(const Duration(days: 730)));

  CollectionReference<Map<String, dynamic>>? get _eventsCollection {
    final branchId = widget.branchId?.trim() ?? '';
    if (branchId.isEmpty) {
      return null;
    }
    return FirebaseFirestore.instance
        .collection('sucursales')
        .doc(branchId)
        .collection('eventos');
  }

  void _showSnackBar(String message, {Color? backgroundColor}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showEventDialog({
    _CalendarEvent? event,
    DateTime? initialDate,
  }) async {
    final titleController = TextEditingController(text: event?.title ?? '');
    final timeController = TextEditingController(text: event?.timeLabel ?? '');
    final notesController = TextEditingController(text: event?.notes ?? '');
    final typeOptions = const ['Clase', 'Examen', 'Torneo', 'Seminario', 'Otro'];
    final repeatOptions = const [
      _RepeatMode.none,
      _RepeatMode.daily,
      _RepeatMode.weekly,
      _RepeatMode.monthly,
      _RepeatMode.yearly,
      _RepeatMode.custom,
    ];
    final customUnitOptions = const [
      _RepeatUnit.days,
      _RepeatUnit.weeks,
      _RepeatUnit.months,
      _RepeatUnit.years,
    ];
    var selectedType = event?.type ?? 'Clase';
    var selectedDate = initialDate ?? event?.date ?? _selectedDay;
    var selectedRepeatMode = event?.repeatMode ?? _RepeatMode.none;
    var selectedCustomUnit = event?.repeatCustomUnit ?? _RepeatUnit.days;
    final intervalController = TextEditingController(
      text: (event?.repeatInterval ?? 2).toString(),
    );
    var isSaving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> saveEvent() async {
              final collection = _eventsCollection;
              if (collection == null || isSaving) return;

              final title = titleController.text.trim();
              final time = timeController.text.trim();
              final notes = notesController.text.trim();

              if (title.isEmpty) {
                _showSnackBar(
                  'Escribe el nombre del evento.',
                  backgroundColor: Colors.orange,
                );
                return;
              }

              setDialogState(() => isSaving = true);
              try {
                final payload = {
                  'title': title,
                  'time_label': time,
                  'notes': notes,
                  'type': selectedType,
                  'event_date': Timestamp.fromDate(_normalizeDay(selectedDate)),
                  'repeat_mode': selectedRepeatMode.name,
                  'repeat_interval':
                      selectedRepeatMode == _RepeatMode.custom
                          ? int.tryParse(intervalController.text.trim()) ?? 1
                          : _repeatIntervalForMode(selectedRepeatMode),
                  'repeat_unit':
                      selectedRepeatMode == _RepeatMode.custom
                          ? selectedCustomUnit.name
                          : _repeatUnitForMode(selectedRepeatMode).name,
                  'updated_at': FieldValue.serverTimestamp(),
                };

                if (event == null) {
                  await collection.add({
                    ...payload,
                    'created_at': FieldValue.serverTimestamp(),
                  });
                } else {
                  await collection.doc(event.id).set(payload, SetOptions(merge: true));
                }

                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
                _showSnackBar(
                  event == null
                      ? 'Evento guardado para ${DateFormat('d MMM').format(selectedDate)}.'
                      : 'Evento actualizado.',
                  backgroundColor: Colors.green,
                );
              } catch (error) {
                _showSnackBar(
                  'No pudimos guardar el evento: $error',
                  backgroundColor: Colors.red,
                );
              } finally {
                if (dialogContext.mounted) {
                  setDialogState(() => isSaving = false);
                }
              }
            }

            return AlertDialog(
              title: Text(event == null ? 'Nuevo evento' : 'Editar evento'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del evento',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Tipo',
                        border: OutlineInputBorder(),
                      ),
                      items:
                          typeOptions
                              .map(
                                (type) => DropdownMenuItem<String>(
                                  value: type,
                                  child: Text(type),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedType = value ?? 'Clase';
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 730)),
                        );
                        if (pickedDate != null) {
                          setDialogState(() {
                            selectedDate = _normalizeDay(pickedDate);
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Fecha',
                          border: OutlineInputBorder(),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 18),
                            const SizedBox(width: 10),
                            Text(DateFormat('EEEE d MMMM y').format(selectedDate)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<_RepeatMode>(
                      value: selectedRepeatMode,
                      decoration: const InputDecoration(
                        labelText: 'Repetir',
                        border: OutlineInputBorder(),
                      ),
                      items:
                          repeatOptions
                              .map(
                                (mode) => DropdownMenuItem<_RepeatMode>(
                                  value: mode,
                                  child: Text(_repeatModeLabel(mode)),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedRepeatMode = value ?? _RepeatMode.none;
                        });
                      },
                    ),
                    if (selectedRepeatMode == _RepeatMode.custom) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: intervalController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Cada cuanto',
                                hintText: 'Ej. 2',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<_RepeatUnit>(
                              value: selectedCustomUnit,
                              decoration: const InputDecoration(
                                labelText: 'Unidad',
                                border: OutlineInputBorder(),
                              ),
                              items:
                                  customUnitOptions
                                      .map(
                                        (unit) => DropdownMenuItem<_RepeatUnit>(
                                          value: unit,
                                          child: Text(_repeatUnitLabel(unit)),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (value) {
                                setDialogState(() {
                                  selectedCustomUnit =
                                      value ?? _RepeatUnit.days;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: timeController,
                      decoration: const InputDecoration(
                        labelText: 'Horario o hora',
                        hintText: 'Ej. 18:00 - 19:30',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Notas',
                        hintText: 'Detalles, materiales, recordatorios...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: isSaving ? null : saveEvent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                  child:
                      isSaving
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showEventDetails(_CalendarEvent event) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(event.title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailLine(label: 'Tipo', value: event.type),
                _DetailLine(
                  label: 'Fecha',
                  value: DateFormat('EEEE d MMMM y').format(event.date),
                ),
                if (event.timeLabel.isNotEmpty)
                  _DetailLine(label: 'Horario', value: event.timeLabel),
                _DetailLine(label: 'Repeticion', value: event.repeatLabel),
                if (event.notes.isNotEmpty)
                  _DetailLine(label: 'Notas', value: event.notes),
              ],
            ),
          ),
          actions: [
            if (!widget.isReadOnly)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    _showEventDialog(event: event);
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar evento'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
            if (!widget.isReadOnly) const SizedBox(height: 10),
            if (!widget.isReadOnly)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    _deleteEvent(event);
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Eliminar evento'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC0392B),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
            if (widget.isReadOnly)
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cerrar'),
              ),
          ],
        );
      },
    );
  }

  Future<void> _deleteEvent(_CalendarEvent event) async {
    final collection = _eventsCollection;
    if (collection == null) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Eliminar evento'),
            content: Text('Se eliminara "${event.title}". Esta accion no se puede deshacer.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );

    if (shouldDelete != true) {
      return;
    }

    try {
      await collection.doc(event.id).delete();
      _showSnackBar('Evento eliminado.', backgroundColor: Colors.green);
    } catch (error) {
      _showSnackBar(
        'No pudimos eliminar el evento: $error',
        backgroundColor: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final branchId = widget.branchId?.trim() ?? '';

    if (branchId.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.calendar_month_outlined, size: 54, color: Colors.black38),
                SizedBox(height: 16),
                Text(
                  'Selecciona una sucursal para ver su calendario.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF7F4EF),
        iconTheme: const IconThemeData(color: Colors.black),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Calendario',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w800,
              ),
            ),
            if ((widget.branchName ?? '').trim().isNotEmpty)
              Text(
                widget.branchName!,
                style: const TextStyle(
                  color: Color(0xFF6D645B),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _eventsCollection!.orderBy('event_date').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('No pudimos cargar el calendario de esta sucursal.'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final events =
              snapshot.data?.docs
                  .map((doc) => _CalendarEvent.fromFirestore(doc))
                  .toList() ??
              const <_CalendarEvent>[];
          final eventsByDay = _groupEventsByDay(events);
          final selectedEvents = eventsByDay[_selectedDay] ?? const <_CalendarEvent>[];

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x12000000),
                        blurRadius: 18,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(14),
                  child: TableCalendar<_CalendarEvent>(
                    firstDay: _calendarFirstDay,
                    lastDay: _calendarLastDay,
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
                    eventLoader:
                        (day) => eventsByDay[_normalizeDay(day)] ?? const [],
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = _normalizeDay(selectedDay);
                        _focusedDay = _normalizeDay(focusedDay);
                      });
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = _normalizeDay(focusedDay);
                    },
                    onFormatChanged: (format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    },
                    availableCalendarFormats: const {
                      CalendarFormat.month: 'Mes',
                      CalendarFormat.twoWeeks: '2 semanas',
                      CalendarFormat.week: 'Semana',
                    },
                    headerStyle: HeaderStyle(
                      titleCentered: true,
                      formatButtonDecoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      formatButtonTextStyle: const TextStyle(color: Colors.white),
                    ),
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                      markerDecoration: const BoxDecoration(
                        color: Color(0xFFC63D2F),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Agenda del dia',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('EEEE d MMMM').format(_selectedDay),
                            style: const TextStyle(
                              color: Color(0xFF6D645B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!widget.isReadOnly)
                      ElevatedButton.icon(
                        onPressed:
                            () => _showEventDialog(initialDate: _selectedDay),
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                if (selectedEvents.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.isReadOnly
                          ? 'No hay eventos programados para este dia.'
                          : 'No hay eventos para este dia. Puedes agregar clases, examenes, torneos o recordatorios.',
                      style: TextStyle(
                        color: Color(0xFF6D645B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                else
                  Column(
                    children:
                        selectedEvents
                            .map(
                              (event) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _EventCard(
                                  event: event,
                                  onTap: () => _showEventDetails(event),
                                ),
                              ),
                            )
                            .toList(),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.onTap,
  });

  final _CalendarEvent event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 10,
                height: 62,
                decoration: BoxDecoration(
                  color: _eventTypeColor(event.type),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        _TypeBadge(label: event.type),
                      ],
                    ),
                    if (event.timeLabel.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        event.timeLabel,
                        style: const TextStyle(
                          color: Color(0xFF574F47),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      event.repeatLabel,
                      style: const TextStyle(
                        color: Color(0xFF8E6E53),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF8A8178)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final color = _eventTypeColor(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CalendarEvent {
  const _CalendarEvent({
    required this.id,
    required this.title,
    required this.type,
    required this.date,
    required this.timeLabel,
    required this.notes,
    required this.repeatMode,
    required this.repeatInterval,
    required this.repeatUnit,
  });

  factory _CalendarEvent.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return _CalendarEvent(
      id: doc.id,
      title: data['title']?.toString() ?? 'Evento',
      type: data['type']?.toString() ?? 'Otro',
      date: _normalizeDay((data['event_date'] as Timestamp?)?.toDate() ?? DateTime.now()),
      timeLabel: data['time_label']?.toString() ?? '',
      notes: data['notes']?.toString() ?? '',
      repeatMode: _repeatModeFromString(data['repeat_mode']?.toString()),
      repeatInterval: (data['repeat_interval'] as num?)?.toInt() ?? 0,
      repeatUnit: _repeatUnitFromString(data['repeat_unit']?.toString()),
    );
  }

  final String id;
  final String title;
  final String type;
  final DateTime date;
  final String timeLabel;
  final String notes;
  final _RepeatMode repeatMode;
  final int repeatInterval;
  final _RepeatUnit repeatUnit;

  _RepeatUnit get repeatCustomUnit => repeatUnit;

  String get repeatLabel {
    switch (repeatMode) {
      case _RepeatMode.none:
        return 'Sin repeticion';
      case _RepeatMode.daily:
        return 'Se repite cada dia';
      case _RepeatMode.weekly:
        return 'Se repite cada semana';
      case _RepeatMode.monthly:
        return 'Se repite cada mes';
      case _RepeatMode.yearly:
        return 'Se repite cada año';
      case _RepeatMode.custom:
        return 'Cada $repeatInterval ${_repeatUnitLabel(repeatUnit).toLowerCase()}';
    }
  }
}

Map<DateTime, List<_CalendarEvent>> _groupEventsByDay(List<_CalendarEvent> events) {
  final grouped = <DateTime, List<_CalendarEvent>>{};
  for (final event in events) {
    for (final occurrence in _expandOccurrences(event)) {
      grouped.putIfAbsent(occurrence, () => <_CalendarEvent>[]).add(event);
    }
  }
  return grouped;
}

DateTime _normalizeDay(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

Color _eventTypeColor(String type) {
  switch (type.toLowerCase()) {
    case 'clase':
      return const Color(0xFF2874A6);
    case 'examen':
      return const Color(0xFFC0392B);
    case 'torneo':
      return const Color(0xFF7D3C98);
    case 'seminario':
      return const Color(0xFF117864);
    default:
      return const Color(0xFF8E6E53);
  }
}

List<DateTime> _expandOccurrences(_CalendarEvent event) {
  final occurrences = <DateTime>[];
  var cursor = _normalizeDay(event.date);

  if (event.repeatMode == _RepeatMode.none) {
    if (!_isOutsideCalendarRange(cursor)) {
      occurrences.add(cursor);
    }
    return occurrences;
  }

  while (!cursor.isAfter(_BranchCalendarScreenState._calendarLastDay)) {
    if (!cursor.isBefore(_BranchCalendarScreenState._calendarFirstDay)) {
      occurrences.add(cursor);
    }
    cursor = _advanceDate(
      cursor,
      interval: event.repeatInterval <= 0 ? 1 : event.repeatInterval,
      unit: event.repeatUnit,
    );
    if (occurrences.length > 500) {
      break;
    }
  }
  return occurrences;
}

bool _isOutsideCalendarRange(DateTime day) {
  return day.isBefore(_BranchCalendarScreenState._calendarFirstDay) ||
      day.isAfter(_BranchCalendarScreenState._calendarLastDay);
}

DateTime _advanceDate(
  DateTime current, {
  required int interval,
  required _RepeatUnit unit,
}) {
  switch (unit) {
    case _RepeatUnit.days:
      return _normalizeDay(current.add(Duration(days: interval)));
    case _RepeatUnit.weeks:
      return _normalizeDay(current.add(Duration(days: interval * 7)));
    case _RepeatUnit.months:
      return _normalizeDay(
        DateTime(current.year, current.month + interval, current.day),
      );
    case _RepeatUnit.years:
      return _normalizeDay(DateTime(current.year + interval, current.month, current.day));
  }
}

int _repeatIntervalForMode(_RepeatMode mode) {
  switch (mode) {
    case _RepeatMode.none:
      return 0;
    case _RepeatMode.daily:
    case _RepeatMode.weekly:
    case _RepeatMode.monthly:
    case _RepeatMode.yearly:
    case _RepeatMode.custom:
      return 1;
  }
}

_RepeatUnit _repeatUnitForMode(_RepeatMode mode) {
  switch (mode) {
    case _RepeatMode.none:
      return _RepeatUnit.days;
    case _RepeatMode.daily:
      return _RepeatUnit.days;
    case _RepeatMode.weekly:
      return _RepeatUnit.weeks;
    case _RepeatMode.monthly:
      return _RepeatUnit.months;
    case _RepeatMode.yearly:
      return _RepeatUnit.years;
    case _RepeatMode.custom:
      return _RepeatUnit.days;
  }
}

String _repeatModeLabel(_RepeatMode mode) {
  switch (mode) {
    case _RepeatMode.none:
      return 'No repetir';
    case _RepeatMode.daily:
      return 'Cada dia';
    case _RepeatMode.weekly:
      return 'Cada semana';
    case _RepeatMode.monthly:
      return 'Cada mes';
    case _RepeatMode.yearly:
      return 'Cada año';
    case _RepeatMode.custom:
      return 'Personalizado';
  }
}

String _repeatUnitLabel(_RepeatUnit unit) {
  switch (unit) {
    case _RepeatUnit.days:
      return 'Dias';
    case _RepeatUnit.weeks:
      return 'Semanas';
    case _RepeatUnit.months:
      return 'Meses';
    case _RepeatUnit.years:
      return 'Años';
  }
}

_RepeatMode _repeatModeFromString(String? value) {
  switch (value) {
    case 'daily':
      return _RepeatMode.daily;
    case 'weekly':
      return _RepeatMode.weekly;
    case 'monthly':
      return _RepeatMode.monthly;
    case 'yearly':
      return _RepeatMode.yearly;
    case 'custom':
      return _RepeatMode.custom;
    default:
      return _RepeatMode.none;
  }
}

_RepeatUnit _repeatUnitFromString(String? value) {
  switch (value) {
    case 'weeks':
      return _RepeatUnit.weeks;
    case 'months':
      return _RepeatUnit.months;
    case 'years':
      return _RepeatUnit.years;
    default:
      return _RepeatUnit.days;
  }
}

enum _RepeatMode { none, daily, weekly, monthly, yearly, custom }

enum _RepeatUnit { days, weeks, months, years }

class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF7A7068),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
