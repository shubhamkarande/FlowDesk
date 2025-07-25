import 'dart:convert';
import 'dart:io';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../models/note.dart';
import '../models/todo.dart';
import '../models/calendar_event.dart';

class GoogleDriveService {
  static final GoogleDriveService _instance = GoogleDriveService._internal();
  factory GoogleDriveService() => _instance;
  GoogleDriveService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveFileScope],
  );

  drive.DriveApi? _driveApi;

  Future<bool> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return false;

      final authHeaders = await account.authHeaders;
      final authenticateClient = GoogleAuthClient(authHeaders);
      _driveApi = drive.DriveApi(authenticateClient);

      return true;
    } catch (e) {
      print('Google Drive sign-in failed: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _driveApi = null;
  }

  bool get isSignedIn => _driveApi != null;

  Future<String?> createFlowDeskFolder() async {
    if (_driveApi == null) return null;

    try {
      // Check if FlowDesk folder already exists
      final query =
          "name='FlowDesk' and mimeType='application/vnd.google-apps.folder' and trashed=false";
      final fileList = await _driveApi!.files.list(q: query);

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        return fileList.files!.first.id;
      }

      // Create FlowDesk folder
      final folder = drive.File()
        ..name = 'FlowDesk'
        ..mimeType = 'application/vnd.google-apps.folder';

      final createdFolder = await _driveApi!.files.create(folder);
      return createdFolder.id;
    } catch (e) {
      print('Error creating FlowDesk folder: $e');
      return null;
    }
  }

  Future<bool> exportNotesToDrive(List<Note> notes) async {
    if (_driveApi == null) return false;

    try {
      final folderId = await createFlowDeskFolder();
      if (folderId == null) return false;

      for (final note in notes) {
        await _uploadNoteFile(note, folderId);
      }

      return true;
    } catch (e) {
      print('Error exporting notes to Drive: $e');
      return false;
    }
  }

  Future<bool> exportAllDataToDrive({
    required List<Note> notes,
    required List<Todo> todos,
    required List<CalendarEvent> events,
  }) async {
    if (_driveApi == null) return false;

    try {
      final folderId = await createFlowDeskFolder();
      if (folderId == null) return false;

      // Export notes
      for (final note in notes) {
        await _uploadNoteFile(note, folderId);
      }

      // Export todos as JSON
      final todosJson = {
        'todos': todos.map((todo) => todo.toMap()).toList(),
        'exportedAt': DateTime.now().toIso8601String(),
      };

      await _uploadJsonFile('todos_backup.json', todosJson, folderId);

      // Export calendar events as JSON
      final eventsJson = {
        'events': events.map((event) => event.toMap()).toList(),
        'exportedAt': DateTime.now().toIso8601String(),
      };

      await _uploadJsonFile(
        'calendar_events_backup.json',
        eventsJson,
        folderId,
      );

      // Export complete backup
      final completeBackup = {
        'notes': notes.map((note) => note.toMap()).toList(),
        'todos': todos.map((todo) => todo.toMap()).toList(),
        'events': events.map((event) => event.toMap()).toList(),
        'exportedAt': DateTime.now().toIso8601String(),
        'version': '1.0.0',
      };

      await _uploadJsonFile(
        'flowdesk_complete_backup.json',
        completeBackup,
        folderId,
      );

      return true;
    } catch (e) {
      print('Error exporting all data to Drive: $e');
      return false;
    }
  }

  Future<void> _uploadNoteFile(Note note, String folderId) async {
    if (_driveApi == null) return;

    try {
      // Create markdown content
      final markdownContent =
          '''# ${note.title}

${note.content}

---
Created: ${note.createdAt.toIso8601String()}
Updated: ${note.updatedAt.toIso8601String()}
Tags: ${note.tags.join(', ')}
''';

      final fileName = '${_sanitizeFileName(note.title)}.md';

      final file = drive.File()
        ..name = fileName
        ..parents = [folderId];

      final media = drive.Media(
        Stream.fromIterable([utf8.encode(markdownContent)]),
        markdownContent.length,
      );

      await _driveApi!.files.create(file, uploadMedia: media);
    } catch (e) {
      print('Error uploading note ${note.title}: $e');
    }
  }

  Future<void> _uploadJsonFile(
    String fileName,
    Map<String, dynamic> data,
    String folderId,
  ) async {
    if (_driveApi == null) return;

    try {
      final jsonContent = const JsonEncoder.withIndent('  ').convert(data);

      final file = drive.File()
        ..name = fileName
        ..parents = [folderId];

      final media = drive.Media(
        Stream.fromIterable([utf8.encode(jsonContent)]),
        jsonContent.length,
      );

      await _driveApi!.files.create(file, uploadMedia: media);
    } catch (e) {
      print('Error uploading JSON file $fileName: $e');
    }
  }

  String _sanitizeFileName(String fileName) {
    // Remove or replace invalid characters for file names
    return fileName
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .substring(0, fileName.length > 100 ? 100 : fileName.length);
  }

  Future<List<String>> listFlowDeskFiles() async {
    if (_driveApi == null) return [];

    try {
      final folderId = await createFlowDeskFolder();
      if (folderId == null) return [];

      final query = "'$folderId' in parents and trashed=false";
      final fileList = await _driveApi!.files.list(q: query);

      return fileList.files?.map((file) => file.name ?? 'Unknown').toList() ??
          [];
    } catch (e) {
      print('Error listing FlowDesk files: $e');
      return [];
    }
  }
}

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }

  @override
  void close() {
    _client.close();
  }
}
