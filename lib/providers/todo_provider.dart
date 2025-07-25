import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/todo.dart';
import '../services/database_service.dart';
import '../services/sync_service.dart';

class TodoProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final SyncService _syncService = SyncService();
  final Uuid _uuid = const Uuid();

  List<Todo> _todos = [];
  bool _isLoading = false;
  String? _error;

  List<Todo> get todos => _todos;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Todo> get todayTodos {
    final today = DateTime.now();
    return _todos.where((todo) {
      if (todo.dueDate == null) return false;
      final dueDate = todo.dueDate!;
      return dueDate.year == today.year &&
          dueDate.month == today.month &&
          dueDate.day == today.day;
    }).toList();
  }

  List<Todo> get completedTodos =>
      _todos.where((todo) => todo.isCompleted).toList();
  List<Todo> get pendingTodos =>
      _todos.where((todo) => !todo.isCompleted).toList();

  List<Todo> get overdueTodos {
    final now = DateTime.now();
    return _todos.where((todo) {
      if (todo.dueDate == null || todo.isCompleted) return false;
      return todo.dueDate!.isBefore(now);
    }).toList();
  }

  TodoProvider() {
    loadTodos();
  }

  Future<void> loadTodos() async {
    _setLoading(true);
    _clearError();

    try {
      _todos = await _dbService.getTodos();
      _todos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      _setError('Failed to load todos: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addTodo({
    required String title,
    String? description,
    DateTime? dueDate,
    String? colorTag,
  }) async {
    _clearError();

    try {
      final now = DateTime.now();
      final todo = Todo(
        id: _uuid.v4(),
        title: title,
        description: description,
        dueDate: dueDate,
        colorTag: colorTag,
        createdAt: now,
        updatedAt: now,
      );

      await _dbService.insertTodo(todo);
      _todos.insert(0, todo);
      notifyListeners();

      // Trigger background sync
      _syncService.syncTodos();
    } catch (e) {
      _setError('Failed to add todo: $e');
    }
  }

  Future<void> updateTodo(Todo todo) async {
    _clearError();

    try {
      final updatedTodo = todo.copyWith(
        updatedAt: DateTime.now(),
        isSynced: false,
      );

      await _dbService.updateTodo(updatedTodo);

      final index = _todos.indexWhere((t) => t.id == todo.id);
      if (index != -1) {
        _todos[index] = updatedTodo;
        notifyListeners();
      }

      // Trigger background sync
      _syncService.syncTodos();
    } catch (e) {
      _setError('Failed to update todo: $e');
    }
  }

  Future<void> toggleTodoComplete(String todoId) async {
    final todo = _todos.firstWhere((t) => t.id == todoId);
    await updateTodo(todo.copyWith(isCompleted: !todo.isCompleted));
  }

  Future<void> deleteTodo(String todoId) async {
    _clearError();

    try {
      await _dbService.deleteTodo(todoId);
      _todos.removeWhere((todo) => todo.id == todoId);
      notifyListeners();

      // Note: For Firebase sync, we might want to implement soft delete
      // or handle deletion in sync service
    } catch (e) {
      _setError('Failed to delete todo: $e');
    }
  }

  List<Todo> getTodosByDate(DateTime date) {
    return _todos.where((todo) {
      if (todo.dueDate == null) return false;
      final dueDate = todo.dueDate!;
      return dueDate.year == date.year &&
          dueDate.month == date.month &&
          dueDate.day == date.day;
    }).toList();
  }

  List<Todo> getTodosByDateRange(DateTime start, DateTime end) {
    return _todos.where((todo) {
      if (todo.dueDate == null) return false;
      return todo.dueDate!.isAfter(start.subtract(const Duration(days: 1))) &&
          todo.dueDate!.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  List<Todo> searchTodos(String query) {
    if (query.isEmpty) return _todos;

    final lowercaseQuery = query.toLowerCase();
    return _todos.where((todo) {
      return todo.title.toLowerCase().contains(lowercaseQuery) ||
          (todo.description?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();
  }

  List<Todo> getTodosByTag(String tag) {
    return _todos.where((todo) => todo.colorTag == tag).toList();
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
