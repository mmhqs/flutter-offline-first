import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tasks.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    // Tabela principal
    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        completed INTEGER NOT NULL,
        priority TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        localOnly INTEGER NOT NULL
      )
    ''');

    // Tabela de fila de sincronização
    await db.execute('''
    CREATE TABLE sync_queue (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      taskId TEXT NOT NULL,
      action TEXT NOT NULL, -- create / update / delete
      data TEXT,            -- JSON com o objeto completo ou null
      timestamp TEXT NOT NULL
    )
  ''');
  }

  Future<Task> create(Task task) async {
    final db = await database;
    await db.insert('tasks', task.toMap());

    // Salva no sync_queue
    await _addToSyncQueue(
      taskId: task.id,
      action: 'create',
      data: task.toMap(),
    );

    return task;
  }

  Future<Task?> read(String id) async {
    final db = await database;
    final maps = await db.query('tasks', where: 'id = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      return Task.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Task>> readAll() async {
    final db = await database;
    const orderBy = 'createdAt DESC';
    final result = await db.query('tasks', orderBy: orderBy);
    return result.map((map) => Task.fromMap(map)).toList();
  }

  Future<int> update(Task task) async {
    final db = await database;
    final result = await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );

    // Salva no sync_queue
    await _addToSyncQueue(
      taskId: task.id,
      action: 'update',
      data: task.toMap(),
    );

    return result;
  }

  Future<int> delete(String id) async {
    final db = await database;

    final result = await db.delete('tasks', where: 'id = ?', whereArgs: [id]);

    // Registra no sync_queue
    await _addToSyncQueue(
      taskId: id,
      action: 'delete',
      data: null, // DELETE não precisa mandar o objeto completo
    );

    return result;
  }

  Future<void> _addToSyncQueue({
    required String taskId,
    required String action,
    required Map<String, dynamic>? data,
  }) async {
    final db = await database;

    await db.insert('sync_queue', {
      'taskId': taskId,
      'action': action,
      'data': data != null ? jsonEncode(data) : null,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> syncChanges() async {
    final db = await database;

    await db.transaction((txn) async {
      final queue = await txn.query('sync_queue', orderBy: 'timestamp ASC');

      for (var item in queue) {
        final taskId = item['taskId'] as String;
        final action = item['action'] as String;
        final dataString = item['data'] as String?;

        Map<String, dynamic>? localData = dataString != null
            ? jsonDecode(dataString) as Map<String, dynamic>
            : null;

        final serverRows = await txn.query(
          'tasks',
          where: 'id = ?',
          whereArgs: [taskId],
        );

        Task? serverTask = serverRows.isNotEmpty
            ? Task.fromMap(serverRows.first)
            : null;

        if (action == 'delete') {
          if (serverTask != null) {
            await txn.delete('tasks', where: 'id = ?', whereArgs: [taskId]);
          }
          continue;
        }

        if (localData == null) continue;
        final localTask = Task.fromMap(localData);

        bool shouldUpdate =
            serverTask == null ||
            serverTask.localOnly ||
            localTask.updatedAt.isAfter(serverTask.updatedAt);

        if (shouldUpdate) {
          final Task syncedTask = localTask.copyWith(localOnly: false);

          if (serverTask == null) {
            print('SYNC: Criando nova tarefa online: ${syncedTask.title}');
            await txn.insert('tasks', syncedTask.toMap());
          } else {
            print(
              'SYNC: Atualizando tarefa (removendo flag offline): ${syncedTask.title}',
            );
            await txn.update(
              'tasks',
              syncedTask.toMap(),
              where: 'id = ?',
              whereArgs: [taskId],
            );
          }
        } else {
          print(
            'SYNC: Ignorando update local (Servidor venceu ou dados iguais).',
          );
        }
      }
      await txn.delete('sync_queue');
    });
  }
}
