import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';

class AnalysisRecord {
  final int? id;
  final String date;
  final List<String> labels;
  final double confidence;

  AnalysisRecord({
    this.id,
    required this.date,
    required this.labels,
    required this.confidence,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'labels': jsonEncode(labels),
      'confidence': confidence,
    };
  }

  factory AnalysisRecord.fromMap(Map<String, dynamic> map) {
    return AnalysisRecord(
      id: map['id'],
      date: map['date'],
      labels: List<String>.from(jsonDecode(map['labels'])),
      confidence: map['confidence'],
    );
  }
}

class HistoryService {
  static final HistoryService _instance = HistoryService._internal();
  factory HistoryService() => _instance;
  HistoryService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'palmistry_history.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE history(id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT, labels TEXT, confidence REAL)',
        );
      },
    );
  }

  Future<void> saveAnalysis(AnalysisRecord record) async {
    final db = await database;
    await db.insert('history', record.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<AnalysisRecord>> getHistory() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('history', orderBy: 'id DESC');
    return List.generate(maps.length, (i) => AnalysisRecord.fromMap(maps[i]));
  }

  Future<void> deleteRecord(int id) async {
    final db = await database;
    await db.delete('history', where: 'id = ?', whereArgs: [id]);
  }
}
