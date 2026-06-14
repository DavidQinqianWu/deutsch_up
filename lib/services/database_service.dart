import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/user_progress.dart';
import '../models/word.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;
  bool _ffiInitialized = false;

  Future<void> _ensureInitialized() async {
    if (_ffiInitialized) return;
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    _ffiInitialized = true;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    await _ensureInitialized();
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'deutsch_up.db');

    return openDatabase(
      path,
      version: 5,
      onCreate: (db, version) async {
        await _createTables(db);
        await _seedWords(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE user_progress ADD COLUMN lastDwellMs INTEGER NOT NULL DEFAULT 0',
          );
        }
        if (oldVersion < 3) {
          // A1 词库扩充，清空 words 表并重新导入
          await db.delete('words');
          await _seedWords(db);
        }
        if (oldVersion < 4) {
          // 词库迁移到 JSON，清空 words 表并从 JSON 重新导入
          await db.delete('words');
          await _seedWords(db);
        }
        if (oldVersion < 5) {
          // A1 词库补全到歌德学院官方词表，清空 words 表并重新导入
          await db.delete('words');
          await _seedWords(db);
        }
      },
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE words (
        id TEXT PRIMARY KEY,
        german TEXT NOT NULL,
        chinese TEXT NOT NULL,
        level TEXT NOT NULL,
        exampleSentence TEXT NOT NULL,
        exampleChinese TEXT NOT NULL,
        tags TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE user_progress (
        wordId TEXT PRIMARY KEY,
        easinessFactor REAL NOT NULL,
        repetitions INTEGER NOT NULL,
        intervalDays REAL NOT NULL,
        lastReviewedAt INTEGER,
        nextReviewAt INTEGER,
        totalDwellMs INTEGER NOT NULL,
        lastDwellMs INTEGER NOT NULL,
        reviewCount INTEGER NOT NULL
      )
    ''');
  }

  Future<List<Word>> _loadWordsFromAssets() async {
    final jsonString = await rootBundle.loadString('assets/data/all_words.json');
    final jsonList = jsonDecode(jsonString) as List<dynamic>;
    return jsonList.map((m) => Word.fromMap(m as Map<String, dynamic>)).toList();
  }

  Future<void> _seedWords(Database db) async {
    final words = await _loadWordsFromAssets();
    final batch = db.batch();
    for (final word in words) {
      batch.insert('words', word.toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<List<Word>> getWords({CEFRLevel? level}) async {
    final db = await database;
    final maps = level == null
        ? await db.query('words')
        : await db.query('words', where: 'level = ?', whereArgs: [level.label]);
    return maps.map((m) => Word.fromMap(m)).toList();
  }

  Future<List<Word>> getDueWords({CEFRLevel? level, int limit = 50}) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    final query = '''
      SELECT w.* FROM words w
      LEFT JOIN user_progress p ON w.id = p.wordId
      WHERE (?1 IS NULL OR w.level = ?1)
        AND (p.nextReviewAt IS NULL OR p.nextReviewAt <= ?2)
      ORDER BY p.nextReviewAt ASC, w.level ASC
      LIMIT ?3
    ''';

    final maps = await db.rawQuery(query, [
      level?.label,
      now,
      limit,
    ]);
    return maps.map((m) => Word.fromMap(m)).toList();
  }

  Future<UserProgress?> getProgress(String wordId) async {
    final db = await database;
    final maps = await db.query(
      'user_progress',
      where: 'wordId = ?',
      whereArgs: [wordId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return UserProgress.fromMap(maps.first);
  }

  Future<void> saveProgress(UserProgress progress) async {
    final db = await database;
    await db.insert(
      'user_progress',
      progress.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, UserProgress>> getAllProgress() async {
    final db = await database;
    final maps = await db.query('user_progress');
    return {
      for (final m in maps)
        m['wordId'] as String: UserProgress.fromMap(m),
    };
  }

  Future<int> countWords({CEFRLevel? level}) async {
    final db = await database;
    final result = level == null
        ? await db.rawQuery('SELECT COUNT(*) as count FROM words')
        : await db.rawQuery(
            'SELECT COUNT(*) as count FROM words WHERE level = ?',
            [level.label],
          );
    return (result.first['count'] as num).toInt();
  }

  Future<int> countMasteredWords() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM user_progress WHERE intervalDays >= ?',
      [7.0],
    );
    return (result.first['count'] as num).toInt();
  }
}
