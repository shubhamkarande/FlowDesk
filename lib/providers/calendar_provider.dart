import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/calendar_event.dart';
import '../models/todo.dart';
import '../models/note.dart';
import '../services/database_service.dart';
import '../services/sync_service.dart';

class CalendarProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final SyncService _syncService = SyncService();
  final Uuid _uuid = const Uuid();

  List<CalendarEvent> _events = [];
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String? _error;

  List<CalendarEvent> get events => _events;
  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<CalendarEvent> get todayEvents {
    final today = DateTime.now();
    return getEventsForDate(today);
  }

  CalendarProvider() {
    loadEvents();
  }

  Future<void> loadEvents() async {
    _setLoading(true);
    _clearError();

    try {
      _events = await _dbService.getCalendarEvents();
      _events.sort((a, b) => a.startTime.compareTo(b.startTime));
    } catch (e) {
      _setError('Failed to load calendar events: $e');
    } finally {
      _setLoading(false);
    }
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  List<CalendarEvent> getEventsForDate(DateTime date) {
    return _events.where((event) {
      final eventDate = event.startTime;
      return eventDate.year == date.year &&
          eventDate.month == date.month &&
          eventDate.day == date.day;
    }).toList();
  }

  List<CalendarEvent> getEventsForDateRange(DateTime start, DateTime end) {
    return _events.where((event) {
      return event.startTime.isAfter(start.subtract(const Duration(days: 1))) &&
          event.startTime.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  Future<void> addEvent({
    required String title,
    String? description,
    required DateTime startTime,
    required DateTime endTime,
    String? todoId,
    String? noteId,
  }) async {
    _clearError();

    try {
      final now = DateTime.now();
      final event = CalendarEvent(
        id: _uuid.v4(),
        title: title,
        description: description,
        startTime: startTime,
        endTime: endTime,
        todoId: todoId,
        noteId: noteId,
        createdAt: now,
        updatedAt: now,
      );

      await _dbService.insertCalendarEvent(event);
      _events.add(event);
      _events.sort((a, b) => a.startTime.compareTo(b.startTime));
      notifyListeners();

      // Trigger background sync
      _syncService.syncCalendarEvents();
    } catch (e) {
      _setError('Failed to add event: $e');
    }
  }

  Future<void> updateEvent(CalendarEvent event) async {
    _clearError();

    try {
      final updatedEvent = event.copyWith(
        updatedAt: DateTime.now(),
        isSynced: false,
      );

      await _dbService.updateCalendarEvent(updatedEvent);

      final index = _events.indexWhere((e) => e.id == event.id);
      if (index != -1) {
        _events[index] = updatedEvent;
        _events.sort((a, b) => a.startTime.compareTo(b.startTime));
        notifyListeners();
      }

      // Trigger background sync
      _syncService.syncCalendarEvents();
    } catch (e) {
      _setError('Failed to update event: $e');
    }
  }

  Future<void> deleteEvent(String eventId) async {
    _clearError();

    try {
      await _dbService.deleteCalendarEvent(eventId);
      _events.removeWhere((event) => event.id == eventId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete event: $e');
    }
  }

  // Create event from todo
  Future<void> createEventFromTodo(Todo todo) async {
    if (todo.dueDate == null) return;

    await addEvent(
      title: todo.title,
      description: todo.description,
      startTime: todo.dueDate!,
      endTime: todo.dueDate!.add(const Duration(hours: 1)),
      todoId: todo.id,
    );
  }

  // Create event from note
  Future<void> createEventFromNote(Note note, DateTime startTime) async {
    await addEvent(
      title: note.title,
      description: 'Note: ${note.title}',
      startTime: startTime,
      endTime: startTime.add(const Duration(hours: 1)),
      noteId: note.id,
    );
  }

  // Get events linked to a specific todo
  List<CalendarEvent> getEventsForTodo(String todoId) {
    return _events.where((event) => event.todoId == todoId).toList();
  }

  // Get events linked to a specific note
  List<CalendarEvent> getEventsForNote(String noteId) {
    return _events.where((event) => event.noteId == noteId).toList();
  }

  // Get upcoming events (next 7 days)
  List<CalendarEvent> getUpcomingEvents() {
    final now = DateTime.now();
    final nextWeek = now.add(const Duration(days: 7));

    return _events.where((event) {
      return event.startTime.isAfter(now) && event.startTime.isBefore(nextWeek);
    }).toList();
  }

  // Check if a date has events
  bool hasEventsOnDate(DateTime date) {
    return _events.any((event) {
      final eventDate = event.startTime;
      return eventDate.year == date.year &&
          eventDate.month == date.month &&
          eventDate.day == date.day;
    });
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void clearError() => _clearError();
}
