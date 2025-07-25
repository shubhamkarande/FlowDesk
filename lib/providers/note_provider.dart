import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/note.dart';
import '../services/database_service.dart';
import '../services/encryption_service.dart';
import '../services/sync_service.dart';

class NoteProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final EncryptionService _encryptionService = EncryptionService();
  final SyncService _syncService = SyncService();
  final Uuid _uuid = const Uuid();

  List<Note> _notes = [];
  bool _isLoading = false;
  String? _error;

  List<Note> get notes => _notes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Note> get recentNotes {
    final sortedNotes = List<Note>.from(_notes);
    sortedNotes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sortedNotes.take(5).toList();
  }

  NoteProvider() {
    loadNotes();
  }

  Future<void> loadNotes() async {
    _setLoading(true);
    _clearError();

    try {
      final encryptedNotes = await _dbService.getNotes();
      _notes = [];

      for (final note in encryptedNotes) {
        if (_encryptionService.isInitialized && note.isEncrypted) {
          try {
            final decryptedContent = _encryptionService.decryptText(
              note.content,
            );
            _notes.add(note.copyWith(content: decryptedContent));
          } catch (e) {
            // If decryption fails, keep the encrypted content
            _notes.add(note);
          }
        } else {
          _notes.add(note);
        }
      }

      _notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } catch (e) {
      _setError('Failed to load notes: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addNote({
    required String title,
    required String content,
    List<String> tags = const [],
  }) async {
    _clearError();

    try {
      final now = DateTime.now();
      String finalContent = content;

      // Encrypt content if encryption is enabled
      if (_encryptionService.isInitialized) {
        finalContent = _encryptionService.encryptText(content);
      }

      final note = Note(
        id: _uuid.v4(),
        title: title,
        content: finalContent,
        tags: tags,
        createdAt: now,
        updatedAt: now,
        isEncrypted: _encryptionService.isInitialized,
      );

      await _dbService.insertNote(note);

      // Add decrypted version to local list
      final displayNote = note.copyWith(content: content);
      _notes.insert(0, displayNote);
      notifyListeners();

      // Trigger background sync
      _syncService.syncNotes();
    } catch (e) {
      _setError('Failed to add note: $e');
    }
  }

  Future<void> updateNote(
    Note note, {
    String? title,
    String? content,
    List<String>? tags,
  }) async {
    _clearError();

    try {
      final updatedContent = content ?? note.content;
      String finalContent = updatedContent;

      // Encrypt content if encryption is enabled
      if (_encryptionService.isInitialized) {
        finalContent = _encryptionService.encryptText(updatedContent);
      }

      final updatedNote = note.copyWith(
        title: title ?? note.title,
        content: finalContent,
        tags: tags ?? note.tags,
        updatedAt: DateTime.now(),
        isSynced: false,
        isEncrypted: _encryptionService.isInitialized,
      );

      await _dbService.updateNote(updatedNote);

      final index = _notes.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        // Update local list with decrypted version
        _notes[index] = updatedNote.copyWith(content: updatedContent);
        notifyListeners();
      }

      // Trigger background sync
      _syncService.syncNotes();
    } catch (e) {
      _setError('Failed to update note: $e');
    }
  }

  Future<void> deleteNote(String noteId) async {
    _clearError();

    try {
      await _dbService.deleteNote(noteId);
      _notes.removeWhere((note) => note.id == noteId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete note: $e');
    }
  }

  List<Note> searchNotes(String query) {
    if (query.isEmpty) return _notes;

    final lowercaseQuery = query.toLowerCase();
    return _notes.where((note) {
      return note.title.toLowerCase().contains(lowercaseQuery) ||
          note.content.toLowerCase().contains(lowercaseQuery) ||
          note.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }

  List<Note> getNotesByTag(String tag) {
    return _notes.where((note) => note.tags.contains(tag)).toList();
  }

  List<String> getAllTags() {
    final allTags = <String>{};
    for (final note in _notes) {
      allTags.addAll(note.tags);
    }
    return allTags.toList()..sort();
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
