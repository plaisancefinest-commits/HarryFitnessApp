import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../data/program_json.dart';
import '../models/body_weight.dart';
import '../models/exercise.dart';
import '../models/recovery_check.dart';
import '../models/program.dart';
import '../models/week_rating.dart';
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
    return openDatabase(path, version: 2, onCreate: (db, v) async {
      await db.execute('''
        CREATE TABLE sessions (
          id TEXT PRIMARY KEY, program_id TEXT, workout_day_id TEXT,
          date TEXT, is_complete INTEGER DEFAULT 0, day_rating INTEGER
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
      await db.execute('''
        CREATE TABLE week_ratings (
          id TEXT PRIMARY KEY, program_id TEXT, week_start TEXT,
          rating INTEGER, created_at TEXT
        )''');
    }, onUpgrade: (db, oldVersion, newVersion) async {
      if (oldVersion < 2) {
        await db.execute('ALTER TABLE sessions ADD COLUMN day_rating INTEGER');
        await db.execute('''
          CREATE TABLE week_ratings (
            id TEXT PRIMARY KEY, program_id TEXT, week_start TEXT,
            rating INTEGER, created_at TEXT
          )''');
      }
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
        if (session.dayRating != null) 'day_rating': session.dayRating,
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
          'day_rating': session.dayRating,
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
                dayRating: s['day_rating'] as int?,
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
          dayRating: row['day_rating'] as int?,
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

  // ─── Body-weight goal & weigh-ins ───────────────────────────────────────────

  static const _weightGoalKey = 'weight_goal';
  static const _weightEntriesKey = 'weight_entries';

  Future<WeightGoal?> getWeightGoal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_weightGoalKey);
    if (raw == null) return null;
    return WeightGoal.fromJson(jsonDecode(raw));
  }

  Future<void> saveWeightGoal(WeightGoal goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_weightGoalKey, jsonEncode(goal.toJson()));
  }

  /// Weigh-ins sorted by date ascending.
  Future<List<WeightEntry>> getWeightEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_weightEntriesKey);
    if (raw == null) return [];
    final list = List<Map<String, dynamic>>.from(jsonDecode(raw));
    return list.map(WeightEntry.fromJson).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Adds a weigh-in; replaces any existing entry on the same calendar day.
  Future<void> addWeightEntry(WeightEntry entry) async {
    final entries = await getWeightEntries();
    entries.removeWhere((e) =>
        e.date.year == entry.date.year &&
        e.date.month == entry.date.month &&
        e.date.day == entry.date.day);
    entries.add(entry);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _weightEntriesKey, jsonEncode(entries.map((e) => e.toJson()).toList()));
  }

  // ─── Cardio & sauna logs (manual minute entries) ────────────────────────────

  static const _cardioKey = 'cardio_entries';
  static const _saunaKey = 'sauna_entries';

  Future<List<Map<String, dynamic>>> _getMinuteEntries(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(raw));
  }

  Future<void> _addMinuteEntry(
      String key, DateTime date, int minutes, String? label) async {
    final entries = await _getMinuteEntries(key);
    entries.add({
      'date': date.toIso8601String(),
      'minutes': minutes,
      if (label != null && label.isNotEmpty) 'label': label,
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(entries));
  }

  /// Entries since Monday 00:00 of the current week, oldest first.
  Future<List<Map<String, dynamic>>> _getEntriesThisWeek(String key) async {
    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final entries = await _getMinuteEntries(key);
    return entries
        .where((e) => DateTime.parse(e['date']).isAfter(startOfWeek))
        .toList()
      ..sort((a, b) => a['date'].compareTo(b['date']));
  }

  Future<void> addCardioEntry(DateTime date, int minutes, String? label) =>
      _addMinuteEntry(_cardioKey, date, minutes, label);

  Future<List<Map<String, dynamic>>> getCardioEntriesThisWeek() =>
      _getEntriesThisWeek(_cardioKey);

  Future<void> addSaunaEntry(DateTime date, int minutes, String? label) =>
      _addMinuteEntry(_saunaKey, date, minutes, label);

  Future<List<Map<String, dynamic>>> getSaunaEntriesThisWeek() =>
      _getEntriesThisWeek(_saunaKey);

  // ─── Day activity overrides (added/removed sauna/swim on the day of) ───────

  static const _activityOverridesKey = 'activity_overrides';

  /// Map of WorkoutDay.id → replacement activity list (serialized).
  /// A day with no entry uses the program's planned activities.
  Future<Map<String, List<PlannedActivity>>> getActivityOverrides() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_activityOverridesKey);
    if (raw == null) return {};
    return Map<String, dynamic>.from(jsonDecode(raw)).map((k, v) => MapEntry(
          k,
          (v as List)
              .map((a) => activityFromJson(Map<String, dynamic>.from(a)))
              .toList(),
        ));
  }

  Future<void> saveActivityOverride(
      String dayId, List<PlannedActivity> activities) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_activityOverridesKey);
    final decoded = raw == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(jsonDecode(raw));
    decoded[dayId] = activities.map(activityToJson).toList();
    await prefs.setString(_activityOverridesKey, jsonEncode(decoded));
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

  // ─── Exercise order overrides (user dragged exercises into a new order) ────

  static const _orderOverridesKey = 'exercise_order_overrides';

  /// Map of WorkoutDay.id → ordered list of PlannedExercise.ids
  Future<Map<String, List<String>>> getExerciseOrderOverrides() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_orderOverridesKey);
    if (raw == null) return {};
    return Map<String, dynamic>.from(jsonDecode(raw))
        .map((k, v) => MapEntry(k, List<String>.from(v)));
  }

  Future<void> saveExerciseOrder(
      String dayId, List<String> orderedPlannedExerciseIds) async {
    final overrides = await getExerciseOrderOverrides();
    overrides[dayId] = orderedPlannedExerciseIds;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_orderOverridesKey, jsonEncode(overrides));
  }

  // ─── Custom programs ────────────────────────────────────────────────────────

  static const _customProgramsKey = 'custom_programs';
  static const _selectedProgramKey = 'selected_program_id';

  Future<List<Program>> getCustomPrograms() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_customProgramsKey);
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(raw))
        .map(programFromJson)
        .toList();
  }

  /// Inserts or replaces (matched by program id).
  Future<void> saveCustomProgram(Program program) async {
    final programs = await getCustomPrograms();
    programs.removeWhere((p) => p.id == program.id);
    programs.add(program);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _customProgramsKey, jsonEncode(programs.map(programToJson).toList()));
  }

  Future<void> deleteCustomProgram(String programId) async {
    final programs = await getCustomPrograms();
    programs.removeWhere((p) => p.id == programId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _customProgramsKey, jsonEncode(programs.map(programToJson).toList()));
  }

  /// Id of the program shown on the home dashboard (built-in or custom).
  Future<String?> getSelectedProgramId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedProgramKey);
  }

  Future<void> saveSelectedProgramId(String programId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedProgramKey, programId);
  }

  // ─── In-Progress Workout ────────────────────────────────────────────────────

  static const _inProgressKey = 'in_progress_workout';

  Future<void> saveInProgressWorkout(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_inProgressKey, jsonEncode(data));
  }

  Future<Map<String, dynamic>?> getInProgressWorkout() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_inProgressKey);
    if (raw == null) return null;
    return Map<String, dynamic>.from(jsonDecode(raw));
  }

  Future<void> clearInProgressWorkout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_inProgressKey);
  }

  // ─── Recovery Checks ────────────────────────────────────────────────────────

  static const _recoveryChecksKey = 'recovery_checks';

  Future<void> saveRecoveryCheck(RecoveryCheck check) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_recoveryChecksKey);
    final list = raw == null
        ? <Map<String, dynamic>>[]
        : List<Map<String, dynamic>>.from(jsonDecode(raw));
    list.removeWhere((r) => r['id'] == check.id);
    list.add({
      'id': check.id,
      'program_id': check.programId,
      'week_start': check.weekStart.toIso8601String(),
      'is_pre_week': check.isPreWeek,
      'ratings': check.ratings.map((r) => {
        'muscle_group': r.muscleGroup.name,
        'status': r.status.name,
      }).toList(),
      'created_at': check.createdAt.toIso8601String(),
    });
    await prefs.setString(_recoveryChecksKey, jsonEncode(list));
  }

  Future<RecoveryCheck?> getRecoveryCheckForWeek(
      String programId, DateTime weekStart, bool isPreWeek) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_recoveryChecksKey);
    if (raw == null) return null;
    final list = List<Map<String, dynamic>>.from(jsonDecode(raw));
    final match = list.where((r) =>
        r['program_id'] == programId &&
        r['is_pre_week'] == isPreWeek &&
        DateTime.parse(r['week_start']).isAtSameMomentAs(weekStart));
    if (match.isEmpty) return null;
    final r = match.first;
    return RecoveryCheck(
      id: r['id'],
      programId: r['program_id'],
      weekStart: DateTime.parse(r['week_start']),
      isPreWeek: r['is_pre_week'],
      ratings: (r['ratings'] as List).map((rt) => MuscleRecoveryRating(
        muscleGroup: MuscleGroup.values.byName(rt['muscle_group']),
        status: RecoveryStatus.values.byName(rt['status']),
      )).toList(),
      createdAt: DateTime.parse(r['created_at']),
    );
  }

  // ─── Week Ratings ───────────────────────────────────────────────────────────

  static const _weekRatingsKey = 'week_ratings';

  Future<void> saveWeekRating(WeekRating rating) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_weekRatingsKey);
      final list = raw == null
          ? <Map<String, dynamic>>[]
          : List<Map<String, dynamic>>.from(jsonDecode(raw));
      list.removeWhere((r) => r['id'] == rating.id);
      list.add({
        'id': rating.id,
        'program_id': rating.programId,
        'week_start': rating.weekStart.toIso8601String(),
        'rating': rating.rating,
        'created_at': rating.createdAt.toIso8601String(),
      });
      await prefs.setString(_weekRatingsKey, jsonEncode(list));
    } else {
      final db = await _sqlite;
      await db.insert('week_ratings', {
        'id': rating.id,
        'program_id': rating.programId,
        'week_start': rating.weekStart.toIso8601String(),
        'rating': rating.rating,
        'created_at': rating.createdAt.toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  /// Returns the week rating for the current Monday-to-Sunday window, if any.
  Future<WeekRating?> getWeekRatingForCurrentWeek(String programId) async {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));

    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_weekRatingsKey);
      if (raw == null) return null;
      final list = List<Map<String, dynamic>>.from(jsonDecode(raw));
      final match = list.where((r) =>
          r['program_id'] == programId &&
          DateTime.parse(r['week_start']).isAtSameMomentAs(monday));
      if (match.isEmpty) return null;
      final r = match.first;
      return WeekRating(
        id: r['id'],
        programId: r['program_id'],
        weekStart: DateTime.parse(r['week_start']),
        rating: r['rating'],
        createdAt: DateTime.parse(r['created_at']),
      );
    } else {
      final db = await _sqlite;
      final rows = await db.query('week_ratings',
          where: 'program_id = ? AND week_start = ?',
          whereArgs: [programId, monday.toIso8601String()]);
      if (rows.isEmpty) return null;
      final r = rows.first;
      return WeekRating(
        id: r['id'] as String,
        programId: r['program_id'] as String,
        weekStart: DateTime.parse(r['week_start'] as String),
        rating: r['rating'] as int,
        createdAt: DateTime.parse(r['created_at'] as String),
      );
    }
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
