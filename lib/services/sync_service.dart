import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../models/todo.dart';
import '../models/note.dart';
import '../models/calendar_event.dart';
import 'database_service.dart';
import 'auth_service.dart';
import 'encryption_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  FirebaseFirestore? _firestore;
  final DatabaseService _dbService = DatabaseService();
  final AuthService _authService = AuthService();
  final EncryptionService _encryptionService = EncryptionService();
  bool _isFirebaseAvailable = false;
  bool _initialized = false;

  bool _isSyncing = false;

  void _initializeFirebase() {
    if (_initialized) return;

    try {
      _firestore = FirebaseFirestore.instance;
      _isFirebaseAvailable = true;
      debugPrint('Firebase Firestore initialized successfully');
    } catch (e) {
      debugPrint('Firebase Firestore not available: $e');
      _isFirebaseAvailable = false;
      _firestore = null;
    }
    _initialized = true;
  }

  bool get isSyncing => _isSyncing;

  Future<bool> isOnline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<void> syncAll() async {
    _initializeFirebase();
    if (_isSyncing ||
        !_authService.isSignedIn ||
        !await isOnline() ||
        !_isFirebaseAvailable) {
      return;
    }

    _isSyncing = true;
    try {
      await Future.wait([syncTodos(), syncNotes(), syncCalendarEvents()]);
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> syncTodos() async {
    _initializeFirebase();
    if (!_authService.isSignedIn || !_isFirebaseAvailable) return;

    final userId = _authService.currentUser!.uid;
    final todosCollection = _firestore!
        .collection('users')
        .doc(userId)
        .collection('todos');

    // Upload unsynced local todos
    final unsyncedTodos = await _dbService.getUnsyncedTodos();
    for (final todo in unsyncedTodos) {
      try {
        await todosCollection.doc(todo.id).set(todo.toFirestore());
        await _dbService.updateTodo(todo.copyWith(isSynced: true));
      } catch (e) {
        print('Error syncing todo ${todo.id}: $e');
      }
    }

    // Download remote todos
    try {
      final snapshot = await todosCollection.get();
      for (final doc in snapshot.docs) {
        final remoteTodo = Todo.fromFirestore(doc.data());
        final localTodo = await _dbService.getTodoById(remoteTodo.id);

        if (localTodo == null) {
          // New remote todo
          await _dbService.insertTodo(remoteTodo);
        } else if (remoteTodo.updatedAt.isAfter(localTodo.updatedAt)) {
          // Remote is newer - update local (last-write-wins)
          await _dbService.updateTodo(remoteTodo);
        } else if (localTodo.updatedAt.isAfter(remoteTodo.updatedAt) &&
            !localTodo.isSynced) {
          // Local is newer - update remote
          await todosCollection.doc(localTodo.id).set(localTodo.toFirestore());
          await _dbService.updateTodo(localTodo.copyWith(isSynced: true));
        }
      }
    } catch (e) {
      print('Error downloading todos: $e');
    }
  }

  Future<void> syncNotes() async {
    _initializeFirebase();
    if (!_authService.isSignedIn ||
        !_encryptionService.isInitialized ||
        !_isFirebaseAvailable)
      return;

    final userId = _authService.currentUser!.uid;
    final notesCollection = _firestore!
        .collection('users')
        .doc(userId)
        .collection('notes');

    // Upload unsynced local notes
    final unsyncedNotes = await _dbService.getUnsyncedNotes();
    for (final note in unsyncedNotes) {
      try {
        // Encrypt content before uploading
        final encryptedNote = note.copyWith(
          content: _encryptionService.encryptText(note.content),
        );
        await notesCollection.doc(note.id).set(encryptedNote.toFirestore());
        await _dbService.updateNote(note.copyWith(isSynced: true));
      } catch (e) {
        print('Error syncing note ${note.id}: $e');
      }
    }

    // Download remote notes
    try {
      final snapshot = await notesCollection.get();
      for (final doc in snapshot.docs) {
        final remoteNote = Note.fromFirestore(doc.data());
        final localNote = await _dbService.getNoteById(remoteNote.id);

        // Decrypt content after downloading
        final decryptedNote = remoteNote.copyWith(
          content: _encryptionService.decryptText(remoteNote.content),
        );

        if (localNote == null) {
          // New remote note
          await _dbService.insertNote(decryptedNote);
        } else if (remoteNote.updatedAt.isAfter(localNote.updatedAt)) {
          // Remote is newer - update local
          await _dbService.updateNote(decryptedNote);
        } else if (localNote.updatedAt.isAfter(remoteNote.updatedAt) &&
            !localNote.isSynced) {
          // Local is newer - update remote
          final encryptedNote = localNote.copyWith(
            content: _encryptionService.encryptText(localNote.content),
          );
          await notesCollection
              .doc(localNote.id)
              .set(encryptedNote.toFirestore());
          await _dbService.updateNote(localNote.copyWith(isSynced: true));
        }
      }
    } catch (e) {
      print('Error downloading notes: $e');
    }
  }

  Future<void> syncCalendarEvents() async {
    _initializeFirebase();
    if (!_authService.isSignedIn || !_isFirebaseAvailable) return;

    final userId = _authService.currentUser!.uid;
    final eventsCollection = _firestore!
        .collection('users')
        .doc(userId)
        .collection('calendar_events');

    // Upload unsynced local events
    final unsyncedEvents = await _dbService.getUnsyncedCalendarEvents();
    for (final event in unsyncedEvents) {
      try {
        await eventsCollection.doc(event.id).set(event.toFirestore());
        await _dbService.updateCalendarEvent(event.copyWith(isSynced: true));
      } catch (e) {
        print('Error syncing calendar event ${event.id}: $e');
      }
    }

    // Download remote events
    try {
      final snapshot = await eventsCollection.get();
      for (final doc in snapshot.docs) {
        final remoteEvent = CalendarEvent.fromFirestore(doc.data());
        final localEvent = await _dbService.getCalendarEventsForDate(
          remoteEvent.startTime,
        );
        final existingEvent = localEvent
            .where((e) => e.id == remoteEvent.id)
            .firstOrNull;

        if (existingEvent == null) {
          // New remote event
          await _dbService.insertCalendarEvent(remoteEvent);
        } else if (remoteEvent.updatedAt.isAfter(existingEvent.updatedAt)) {
          // Remote is newer - update local
          await _dbService.updateCalendarEvent(remoteEvent);
        } else if (existingEvent.updatedAt.isAfter(remoteEvent.updatedAt) &&
            !existingEvent.isSynced) {
          // Local is newer - update remote
          await eventsCollection
              .doc(existingEvent.id)
              .set(existingEvent.toFirestore());
          await _dbService.updateCalendarEvent(
            existingEvent.copyWith(isSynced: true),
          );
        }
      }
    } catch (e) {
      print('Error downloading calendar events: $e');
    }
  }

  // Background sync setup
  void startPeriodicSync() {
    // Sync every 5 minutes when online
    Stream.periodic(const Duration(minutes: 5)).listen((_) async {
      if (await isOnline()) {
        await syncAll();
      }
    });
  }
}
