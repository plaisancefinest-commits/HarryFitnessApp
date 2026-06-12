import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/workout_session.dart';

/// Unified persistence layer.
/// - Web: SharedPreferences (JSON in localStorage)
/// - Mobile: SQLite via sqflite
class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  DatabaseService._internal();

  Database? _db;

  // ─── SQLite (mobile) ────────────────────────────────────────────────────────

  Future<Database> get _sqlite async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'harry_fitness.db');
    return openDatabase(path, version: 1, onCreate: (db, v) async {
      await db.execute('''
        CREATE TABLE sessions (
          id TEXT PRIMARY KEY, program_id TEXT, workout_day_id TEXT,
          date TEXT, is_complete INTEGER DEFAULT 0
        )''');
      await db.execute('''
        CREATE TABLE set_logs (
          id TEXT PRIMARY KEY, session_id TEXT, exercise_id TEXT,
          set_number INTEGER, weight REAL, reps INTEGER, notes TEXT,
          completed_at TEXT
        )''');
      await db.execute('''
        CREATE TABLE rest_logs (
          id INTEGER PRIMARY KEY AUTOINCREMENT, session_id TEXT,
          exercise_id TEXT, set_number INTEGER, rest_seconds INTEGER
        )''');
      await db.execute('''
        CREATE TABLE rest_recommendations (
          program_id TEXT, exercise_id TEXT, recommended_seconds INTEGER,
          PRIMARY KEY (program_id, exercise_id)
        )''');
    });
  }

  // ─── SharedPreferences helpers (web) ────────────────────────────────────────

  static const _sessionsKey = 'sessions';
  static const _restsKey = 'rest_recommendations';
  static const _weightUnitKey = 'weight_unit';

  Future<List<Map<String, dynamic>>> _prefGetSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionsKey);
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(raw));
  }

  Future<void> _prefSaveSessions(List<Map<String, dynamic>> sessions) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionsKey, jsonEncode(sessions));
  }

  Future<Map<String, Map<String, int>>> _prefGetRecs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_restsKey);
    if (raw == null) return {};
    final decoded = Map<String, dynamic>.from(jsonDecode(raw));
    return decoded.map((k, v) => MapEntry(
          k,
          Map<String, int>.from((v as Map).map((ek, ev) => MapEntry(ek as String, ev as int))),
        ));
  }

  Future<void> _prefSaveRecs(Map<String, Map<String, int>> recs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_restsKey, jsonEncode(recs));
  }

  // ─── Public API ─────────────────────────────────────────────────────────────

  Future<void> saveSession(WorkoutSession session) async {
    if (kIsWeb) {
      final sessions = await _prefGetSessions();
      sessions.removeWhere((s) => s['id'] == session.id);
      sessions.add({
        'id': session.id,
        'program_id': session.programId,
        'workout_day_id': session.workoutDayId,
        'date': session.date.toIso8601String(),
        'is_complete': session.isComplete,
        'sets': session.sets
            .map((s) => {
                  'id': s.id,
                  'exercise_id': s.exerciseId,
                  'set_number': s.setNumber,
                  'weight': s.weight,
                  'reps': s.reps,
                  'notes': s.notes,
                  'completed_at': s.completedAt.toIso8601String(),
                })
            .toList(),
        'rests': session.rests
            .map((r) => {
                  'exercise_id': r.exerciseId,
                  'set_number': r.setNumber,
                  'rest_seconds': r.restSeconds,
                })
            .toList(),
      });
      await _prefSaveSessions(sessions);
    } else {
      final db = await _sqlite;
      await db.transaction((txn) async {
        await txn.insert('sessions', {
          'id': session.id,
          'program_id': session.programId,
          'workout_day_id': session.workoutDayId,
          'date': session.date.toIso8601String(),
          'is_complete': session.isComplete ? 1 : 0,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
        for (final s in session.sets) {
          await txn.insert('set_logs', {
            'id': s.id, 'session_id': session.id,
            'exercise_id': s.exerciseId, 'set_number': s.setNumber,
            'weight': s.weight, 'reps': s.reps, 'notes': s.notes,
            'completed_at': s.completedAt.toIso8601String(),
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
        for (final r in session.rests) {
          await txn.insert('rest_logs', {
            'session_id': session.id, 'exercise_id': r.exerciseId,
            'set_number': r.setNumber, 'rest_seconds': r.restSeconds,
          });
        }
      });
    }
  }

  Future<void> saveRestRecommendations(String programId, Map<String, int> averages) async {
    if (kIsWeb) {
      final recs = await _prefGetRecs();
      recs[programId] = {...(recs[programId] ?? {}), ...averages};
      await _prefSaveRecs(recs);
    } else {
      final db = await _sqlite;
      for (final e in averages.entries) {
        await db.insert('rest_recommendations', {
          'program_id': programId, 'exercise_id': e.key,
          'recommended_seconds': e.value,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }
  }

  Future<Map<String, int>> getRestRecommendations(String programId) async {
    if (kIsWeb) {
      final recs = await _prefGetRecs();
      return recs[programId] ?? {};
    } else {
      final db = await _sqlite;
      final rows = await db.query('rest_recommendations',
          where: 'program_id = ?', whereArgs: [programId]);
      return {for (final r in rows) r['exercise_id'] as String: r['recommended_seconds'] as int};
    }
  }

  Future<List<WorkoutSession>> getCompletedSessions() async {
    if (kIsWeb) {
      final all = await _prefGetSessions();
      return all
          .where((s) => s['is_complete'] == true)
          .map((s) => WorkoutSession(
                id: s['id'],
                programId: s['program_id'],
                workoutDayId: s['workout_day_id'],
                date: DateTime.parse(s['date']),
                isComplete: true,
                sets: (s['sets'] as List)
                    .map((sl) => SetLog(
                          id: sl['id'],
                          exerciseId: sl['exercise_id'],
                          setNumber: sl['set_number'],
                          weight: (sl['weight'] as num).toDouble(),
                          reps: sl['reps'],
                          notes: sl['notes'],
                          completedAt: DateTime.parse(sl['completed_at']),
                        ))
                    .toList(),
                rests: (s['rests'] as List)
                    .map((rl) => RestLog(
                          exerciseId: rl['exercise_id'],
                          setNumber: rl['set_number'],
                          restSeconds: rl['rest_seconds'],
                        ))
                    .toList(),
              ))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    } else {
      final db = await _sqlite;
      final sessionRows = await db.query('sessions',
          where: 'is_complete = 1', orderBy: 'date DESC');
      final sessions = <WorkoutSession>[];
      for (final row in sessionRows) {
        final sid = row['id'] as String;
        final setRows = await db.query('set_logs',
            where: 'session_id = ?', whereArgs: [sid], orderBy: 'completed_at ASC');
        final restRows = await db.query('rest_logs',
            where: 'session_id = ?', whereArgs: [sid]);
        sessions.add(WorkoutSession(
          id: sid,
          programId: row['program_id'] as String,
          workoutDayId: row['workout_day_id'] as String,
          date: DateTime.parse(row['date'] as String),
          isComplete: true,
          sets: setRows.map((r) => SetLog(
                id: r['id'] as String, exerciseId: r['exercise_id'] as String,
                setNumber: r['set_number'] as int, weight: r['weight'] as double,
                reps: r['reps'] as int, notes: r['notes'] as String?,
                completedAt: DateTime.parse(r['completed_at'] as String),
              )).toList(),
          rests: restRows.map((r) => RestLog(
                exerciseId: r['exercise_id'] as String,
                setNumber: r['set_number'] as int,
                restSeconds: r['rest_seconds'] as int,
              )).toList(),
        ));
      }
      return sessions;
    }
  }

  Future<int> getSessionsThisWeek() async {
    final sessions = await getCompletedSessions();
    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    return sessions.where((s) => s.date.isAfter(startOfWeek)).length;
  }

  Future<bool> hasCompletedSessionForProgram(String programId) async {
    final sessions = await getCompletedSessions();
    return sessions.any((s) => s.programId == programId);
  }

  /// The workout_day_id of the most recently completed session for [programId],
  /// or null if no session has been completed yet.
  Future<String?> getLastCompletedDayId(String programId) async {
    final sessions = await getCompletedSessions(); // already sorted date DESC
    for (final s in sessions) {
      if (s.programId == programId) return s.workoutDayId;
    }
    return null;
  }

  // ─── Exercise overrides (user swapped an exercise in a program day) ────────

  static const _overridesKey = 'exercise_overrides';

  /// Map of PlannedExercise.id → substituted Exercise.id
  Future<Map<String, String>> getExerciseOverrides() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_overridesKey);
    if (raw == null) return {};
    return Map<String, String>.from(jsonDecode(raw));
  }

  Future<void> saveExerciseOverride(
      String plannedExerciseId, String exerciseId) async {
    final prefs = await SharedPreferences.getInstance();
    final overrides = await getExerciseOverrides();
    overrides[plannedExerciseId] = exerciseId;
    await prefs.setString(_overridesKey, jsonEncode(overrides));
  }

  Future<String> getWeightUnit() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_weightUnitKey) ?? 'lbs';
  }

  Future<void> saveWeightUnit(String unit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_weightUnitKey, unit);
  }
}
