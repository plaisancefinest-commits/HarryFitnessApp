import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';
import 'package:uuid/uuid.dart';
import '../models/personal_record.dart';
import '../models/picture_challenge.dart';
import '../models/program.dart';
import '../models/workout_session.dart';
import '../services/database_service.dart';
import '../services/picture_challenge_service.dart';
import '../services/pr_service.dart';

enum WeightUnit { lbs, kg }

/// Canonical lbs↔kg factor. Single source of truth — never use a raw literal.
const double kLbsPerKg = 2.20462;

enum TimerMode { stopwatch, countdown }

enum WorkoutState { idle, stretching, active, resting, rating, complete }

class _SetDraft {
  double weight;
  int reps;
  bool completed;

  _SetDraft({this.weight = 0, required this.reps, this.completed = false});
}

class WorkoutProvider extends ChangeNotifier {
  final _uuid = const Uuid();

  // ignore: unused_field — will be used when building workout history
  Program? _program;
  WorkoutDay? _currentDay;

  int _currentExerciseIndex = 0;
  int _currentSet = 1;

  Timer? _timer;
  int _timerSeconds = 0;
  TimerMode _timerMode = TimerMode.stopwatch;
  WorkoutState _state = WorkoutState.idle;

  Map<String, int> recommendedRest = {};
  DateTime? _restStartTime;

  // Per-set draft state: exerciseId → list of drafts indexed by set (0-based)
  final Map<String, List<_SetDraft>> _drafts = {};

  // Weight unit
  WeightUnit _weightUnit = WeightUnit.lbs;

  // Stretch state
  StretchPhase _currentStretchPhase = StretchPhase.warmUp;
  int _currentStretchIndex = 0;

  WorkoutSession? _session;

  // ─── Picture Reveal ─────────────────────────────────────────────────────
  bool _revealStepEarned = false;
  PictureChallenge? _activeChallenge;
  double _previousRevealProgress = 0.0;

  bool get revealStepEarned => _revealStepEarned;
  PictureChallenge? get activeChallenge => _activeChallenge;
  double get previousRevealProgress => _previousRevealProgress;

  // ─── Post-Workout Summary ──────────────────────────────────────────────
  List<ExerciseSummary>? _workoutSummary;
  List<ExerciseSummary>? get workoutSummary => _workoutSummary;

  WorkoutProvider() {
    _loadWeightUnit();
  }

  Future<void> _loadWeightUnit() async {
    final raw = await DatabaseService.instance.getWeightUnit();
    _weightUnit = raw == 'kg' ? WeightUnit.kg : WeightUnit.lbs;
    notifyListeners();
  }

  // ─── Getters ───────────────────────────────────────────────────────────────

  WorkoutSession? get session => _session;
  WorkoutDay? get currentDay => _currentDay;
  int get currentExerciseIndex => _currentExerciseIndex;
  int get currentSet => _currentSet;
  int get timerSeconds => _timerSeconds;
  TimerMode get timerMode => _timerMode;
  WorkoutState get state => _state;
  WeightUnit get weightUnit => _weightUnit;

  PlannedExercise? get currentExercise {
    if (_currentDay == null) return null;
    if (_currentExerciseIndex >= _currentDay!.exercises.length) return null;
    return _currentDay!.exercises[_currentExerciseIndex];
  }

  bool get isLastSet {
    if (currentExercise == null) return false;
    final draftCount =
        _drafts[currentExercise!.exercise.id]?.length ?? 0;
    return _currentSet >= draftCount;
  }

  bool get isLastExercise =>
      _currentDay != null &&
      _currentExerciseIndex >= _currentDay!.exercises.length - 1;

  StretchStep? get currentStretch {
    if (_currentDay == null) return null;
    if (_state != WorkoutState.stretching) return null;
    final list = _currentStretchPhase == StretchPhase.warmUp
        ? _currentDay!.warmUpStretches
        : _currentDay!.coolDownStretches;
    if (_currentStretchIndex >= list.length) return null;
    return list[_currentStretchIndex];
  }

  int get totalStretches {
    if (_currentDay == null) return 0;
    final list = _currentStretchPhase == StretchPhase.warmUp
        ? _currentDay!.warmUpStretches
        : _currentDay!.coolDownStretches;
    return list.length;
  }

  List<_SetDraft>? getDraftsForExercise(String exerciseId) =>
      _drafts[exerciseId];

  // ─── Weight Unit ──────────────────────────────────────────────────────────

  Future<void> toggleUnit() async {
    final newUnit =
        _weightUnit == WeightUnit.lbs ? WeightUnit.kg : WeightUnit.lbs;
    // Drafts always store canonical lbs — only the display changes.
    _weightUnit = newUnit;
    await DatabaseService.instance
        .saveWeightUnit(newUnit == WeightUnit.kg ? 'kg' : 'lbs');
    notifyListeners();
  }

  // ─── Draft Updates ────────────────────────────────────────────────────────

  void updateDraftWeight(String exerciseId, int setIndex, double displayWeight) {
    // Convert display-unit input back to canonical lbs for storage.
    final weightLbs = _weightUnit == WeightUnit.kg
        ? displayWeight * kLbsPerKg
        : displayWeight;
    _drafts[exerciseId]?[setIndex].weight = weightLbs;
    notifyListeners();
  }

  /// Get the weight for display, converted to current unit and rounded.
  double getDisplayWeight(String exerciseId, int setIndex) {
    final lbs = _drafts[exerciseId]?[setIndex].weight ?? 0;
    if (_weightUnit == WeightUnit.kg) {
      return (lbs / kLbsPerKg).roundToDouble();
    }
    return lbs.roundToDouble();
  }

  void updateDraftReps(String exerciseId, int setIndex, int reps) {
    _drafts[exerciseId]?[setIndex].reps = reps;
    notifyListeners();
  }

  // ─── Session Start ────────────────────────────────────────────────────────

  void startSession({
    required Program program,
    required WorkoutDay day,
    required bool isFirstWeek,
    Map<String, int>? previousRestAverages,
  }) {
    _program = program;
    _currentDay = day;
    _currentExerciseIndex = 0;
    _currentSet = 1;
    // Count down when rest is prescribed by the program or learned from
    // history; otherwise use a stopwatch for the first week to learn it.
    final hasPrescribedRest =
        day.exercises.any((pe) => pe.restSeconds != null);
    _timerMode = isFirstWeek && !hasPrescribedRest
        ? TimerMode.stopwatch
        : TimerMode.countdown;
    recommendedRest = previousRestAverages ?? {};

    _session = WorkoutSession(
      id: _uuid.v4(),
      programId: program.id,
      workoutDayId: day.id,
      date: DateTime.now(),
      sets: [],
      rests: [],
    );

    // Pre-populate drafts for every exercise × set, stored in canonical lbs.
    _drafts.clear();
    for (final pe in day.exercises) {
      final targetLbs = pe.targetWeightLbs ?? 0;
      _drafts[pe.exercise.id] = List.generate(
        pe.sets,
        (i) => _SetDraft(weight: targetLbs, reps: pe.reps),
      );
    }

    // Begin with warm-up stretches if any
    if (day.warmUpStretches.isNotEmpty) {
      _currentStretchPhase = StretchPhase.warmUp;
      _currentStretchIndex = 0;
      _state = WorkoutState.stretching;
    } else {
      _state = WorkoutState.active;
    }

    _saveProgress();
    notifyListeners();
  }

  // ─── Stretch Navigation ───────────────────────────────────────────────────

  void completeStretch() {
    if (_currentDay == null) return;

    final list = _currentStretchPhase == StretchPhase.warmUp
        ? _currentDay!.warmUpStretches
        : _currentDay!.coolDownStretches;

    if (_currentStretchIndex < list.length - 1) {
      _currentStretchIndex++;
    } else if (_currentStretchPhase == StretchPhase.warmUp) {
      // Done with warm-up → start workout
      _state = WorkoutState.active;
    } else {
      // Done with cool-down → show day rating
      _state = WorkoutState.rating;
    }

    _saveProgress();
    notifyListeners();
  }

  // ─── Set Completion ───────────────────────────────────────────────────────

  void completeSetByIndex(String exerciseId, int setIndex) {
    if (_session == null) return;
    final drafts = _drafts[exerciseId];
    if (drafts == null || setIndex >= drafts.length) return;

    final draft = drafts[setIndex];
    if (draft.completed) return;

    draft.completed = true;

    // Drafts always store canonical lbs — use directly.
    _session!.sets.add(SetLog(
      id: _uuid.v4(),
      exerciseId: exerciseId,
      setNumber: setIndex + 1,
      weight: draft.weight,
      reps: draft.reps,
      completedAt: DateTime.now(),
    ));

    // Rest after every completed set
    _currentSet = setIndex + 1;
    _restStartTime = DateTime.now();
    _state = WorkoutState.resting;
    _saveProgress();

    if (_timerMode == TimerMode.countdown) {
      // Prefer learned rest averages, then the program's prescribed rest.
      // Ignore learned values under 15s — those were skips, not real rest.
      final plannedRest = _currentDay?.exercises
          .where((pe) => pe.exercise.id == exerciseId)
          .firstOrNull
          ?.restSeconds;
      final learned = recommendedRest[exerciseId];
      _timerSeconds = (learned != null && learned >= 15)
          ? learned
          : plannedRest ?? 90;
      _timerInitialSeconds = _timerSeconds;
      _startCountdown();
    } else {
      _timerSeconds = 0;
      _startStopwatch();
    }

    notifyListeners();
  }

  /// Uncheck a completed set so it can be edited and re-completed.
  void uncompleteSetByIndex(String exerciseId, int setIndex) {
    if (_session == null) return;
    final drafts = _drafts[exerciseId];
    if (drafts == null || setIndex >= drafts.length) return;

    final draft = drafts[setIndex];
    if (!draft.completed) return;

    draft.completed = false;
    _session!.sets.removeWhere(
        (s) => s.exerciseId == exerciseId && s.setNumber == setIndex + 1);

    // If we were resting after this set, cancel the rest
    if (_state == WorkoutState.resting) {
      _timer?.cancel();
      _restStartTime = null;
      _state = WorkoutState.active;
    }

    _saveProgress();
    notifyListeners();
  }

  void endRest() {
    _timer?.cancel();

    if (_restStartTime != null && currentExercise != null) {
      final elapsed = DateTime.now().difference(_restStartTime!).inSeconds;
      // Only log rest if it was a real rest period (5s+). Skipped rests
      // pollute the learned-average and produce 1-second timer bugs.
      if (elapsed >= 5) {
        _session!.rests.add(RestLog(
          exerciseId: currentExercise!.exercise.id,
          setNumber: _currentSet,
          restSeconds: elapsed,
        ));
      }
      _restStartTime = null;
    }

    // Only move on once every set of this exercise is done; otherwise
    // stay here for the next set.
    final drafts = _drafts[currentExercise?.exercise.id];
    final allDone = drafts != null && drafts.every((d) => d.completed);
    if (allDone) {
      _advanceToNextExercise();
    } else {
      _state = WorkoutState.active;
      notifyListeners();
    }
    _saveProgress();
  }

  // ─── Manual Exercise Navigation ───────────────────────────────────────────

  void goToPreviousExercise() {
    if (_currentExerciseIndex <= 0 || _state == WorkoutState.stretching) return;
    _timer?.cancel();
    _restStartTime = null;
    _currentExerciseIndex--;
    _currentSet = 1;
    _state = WorkoutState.active;
    _saveProgress();
    notifyListeners();
  }

  void goToNextExercise() {
    if (isLastExercise || _state == WorkoutState.stretching) return;
    _timer?.cancel();
    _restStartTime = null;
    _currentExerciseIndex++;
    _currentSet = 1;
    _state = WorkoutState.active;
    _saveProgress();
    notifyListeners();
  }

  void _advanceToNextExercise() {
    if (isLastExercise) {
      _startCoolDown();
    } else {
      _currentExerciseIndex++;
      _currentSet = 1;
      _state = WorkoutState.active;
    }
    notifyListeners();
  }

  void _startCoolDown() {
    if (_currentDay != null && _currentDay!.coolDownStretches.isNotEmpty) {
      _currentStretchPhase = StretchPhase.coolDown;
      _currentStretchIndex = 0;
      _state = WorkoutState.stretching;
    } else {
      _state = WorkoutState.rating;
    }
  }

  Future<void> _finishWorkout() async {
    _session!.isComplete = true;
    _state = WorkoutState.complete;
    _timer?.cancel();

    // ── Picture Reveal: check BEFORE saving the session ──
    _revealStepEarned = false;
    _activeChallenge = null;
    if (_program != null) {
      final challenge =
          await PictureChallengeService.getActiveChallenge(_program!.id);
      if (challenge != null) {
        _previousRevealProgress = challenge.revealProgress;
        final isFirst =
            await PictureChallengeService.isFirstWorkoutToday(_program!.id);
        // Save session first (so it's persisted even if reveal logic fails)
        await DatabaseService.instance.saveSession(_session!);
        if (isFirst && challenge.completedWorkouts < challenge.totalWorkouts) {
          _activeChallenge = await PictureChallengeService.recordProgress();
          _revealStepEarned = true;
        } else {
          _activeChallenge = challenge;
        }
      } else {
        await DatabaseService.instance.saveSession(_session!);
      }
      await DatabaseService.instance
          .saveRestRecommendations(_program!.id, sessionRestAverages);
    } else {
      await DatabaseService.instance.saveSession(_session!);
    }

    // ── Compute post-workout summary with PR detection ──
    await _computeWorkoutSummary();

    // Clear in-progress data AFTER final persistence — a crash between these
    // lines loses at most the cleanup, not the completed session.
    await clearSavedProgress();

    notifyListeners();
  }

  Future<void> _computeWorkoutSummary() async {
    if (_session == null || _session!.sets.isEmpty) {
      _workoutSummary = null;
      return;
    }

    // Group this session's sets by exercise
    final byExercise = <String, List<SetLog>>{};
    for (final s in _session!.sets) {
      byExercise.putIfAbsent(s.exerciseId, () => []).add(s);
    }

    // For each exercise, load historical sets and compute PRs BEFORE this session
    final previousPRs = <String, ExercisePRSet>{};
    for (final exerciseId in byExercise.keys) {
      final allSets =
          await DatabaseService.instance.getSetLogsForExercise(exerciseId);
      // Exclude sets from the current session (they were just saved)
      final historicalSets = allSets
          .where((s) => !_session!.sets.any((ss) => ss.id == s.id))
          .toList();
      previousPRs[exerciseId] =
          PRService.computeAllTimePRs(exerciseId, historicalSets);
    }

    // Detect new PRs
    final newPRs = PRService.detectNewPRs(_session!.sets, previousPRs);

    // Build summaries
    _workoutSummary = byExercise.entries
        .map((e) => PRService.summarizeExercise(
              e.key,
              e.value,
              newPRs: newPRs[e.key] ?? [],
            ))
        .toList();
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timerSeconds <= 0) {
        t.cancel();
        _onTimerComplete();
      } else {
        _timerSeconds--;
        notifyListeners();
      }
    });
  }

  void _startStopwatch() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      _timerSeconds++;
      notifyListeners();
    });
  }

  Future<void> _onTimerComplete() async {
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(pattern: [0, 400, 100, 400]);
    }
    endRest();
  }

  // ─── Day Rating ──────────────────────────────────────────────────────────

  void setDayRating(int rating) {
    if (_session != null) {
      _session!.dayRating = rating;
      notifyListeners();
    }
  }

  Future<void> confirmRating() async {
    await _finishWorkout();
  }

  /// Skip rating and finish immediately.
  Future<void> skipRating() async {
    await _finishWorkout();
  }

  // ─── Rest Timer Helpers ─────────────────────────────────────────────────

  int? _timerInitialSeconds;

  int get timerInitialSeconds => _timerInitialSeconds ?? _timerSeconds;

  void addRestTime(int seconds) {
    if (_timerMode == TimerMode.countdown && _state == WorkoutState.resting) {
      _timerSeconds += seconds;
      _timerInitialSeconds = (_timerInitialSeconds ?? _timerSeconds) + seconds;
      notifyListeners();
    }
  }

  // ─── Mid-Session Workout Overview ─────────────────────────────────────────

  void jumpToExercise(int index) {
    if (_currentDay == null ||
        index < 0 ||
        index >= _currentDay!.exercises.length) return;
    _timer?.cancel();
    _restStartTime = null;
    _currentExerciseIndex = index;
    _currentSet = 1;
    _state = WorkoutState.active;
    _saveProgress();
    notifyListeners();
  }

  void reorderExercises(int oldIndex, int newIndex) {
    if (_currentDay == null) return;
    if (newIndex > oldIndex) newIndex--;
    final exercises = _currentDay!.exercises;
    final item = exercises.removeAt(oldIndex);
    exercises.insert(newIndex, item);
    for (var i = 0; i < exercises.length; i++) {
      exercises[i].order = i;
    }
    // Adjust _currentExerciseIndex if affected by the reorder
    if (_currentExerciseIndex == oldIndex) {
      _currentExerciseIndex = newIndex;
    } else if (oldIndex < _currentExerciseIndex &&
        newIndex >= _currentExerciseIndex) {
      _currentExerciseIndex--;
    } else if (oldIndex > _currentExerciseIndex &&
        newIndex <= _currentExerciseIndex) {
      _currentExerciseIndex++;
    }
    _saveProgress();
    notifyListeners();
    DatabaseService.instance.saveExerciseOrder(
        _currentDay!.id, exercises.map((e) => e.id).toList());
  }

  void addExerciseMidWorkout(PlannedExercise exercise) {
    if (_currentDay == null) return;
    _currentDay!.exercises.add(exercise);
    final targetLbs = exercise.targetWeightLbs ?? 0;
    _drafts[exercise.exercise.id] = List.generate(
      exercise.sets,
      (i) => _SetDraft(weight: targetLbs, reps: exercise.reps),
    );
    _saveProgress();
    notifyListeners();
  }

  void removeSetFromExercise(String exerciseId, int setIndex) {
    final drafts = _drafts[exerciseId];
    if (drafts == null || drafts.length <= 1) return; // keep at least 1 set
    if (setIndex < 0 || setIndex >= drafts.length) return;
    // Also remove any matching SetLog from the session
    if (_session != null) {
      _session!.sets.removeWhere(
          (s) => s.exerciseId == exerciseId && s.setNumber == setIndex + 1);
    }
    drafts.removeAt(setIndex);
    _saveProgress();
    notifyListeners();
  }

  void addSetToExercise(String exerciseId) {
    final drafts = _drafts[exerciseId];
    if (drafts == null || drafts.isEmpty) return;
    final last = drafts.last;
    drafts.add(_SetDraft(weight: last.weight, reps: last.reps));
    _saveProgress();
    notifyListeners();
  }

  bool isExerciseComplete(String exerciseId) {
    final drafts = _drafts[exerciseId];
    return drafts != null && drafts.every((d) => d.completed);
  }

  String? get programId => _program?.id;

  // ─── Save / Resume ──────────────────────────────────────────────────────

  Map<String, dynamic> toResumableJson() {
    return {
      'programId': _program?.id,
      'dayId': _currentDay?.id,
      'session': {
        'id': _session?.id,
        'programId': _session?.programId,
        'workoutDayId': _session?.workoutDayId,
        'date': _session?.date.toIso8601String(),
        'dayRating': _session?.dayRating,
        'sets': _session?.sets.map((s) => {
          'id': s.id,
          'exerciseId': s.exerciseId,
          'setNumber': s.setNumber,
          'weight': s.weight,
          'reps': s.reps,
          'notes': s.notes,
          'completedAt': s.completedAt.toIso8601String(),
        }).toList(),
        'rests': _session?.rests.map((r) => {
          'exerciseId': r.exerciseId,
          'setNumber': r.setNumber,
          'restSeconds': r.restSeconds,
        }).toList(),
      },
      'drafts': _drafts.map((k, v) => MapEntry(k, v.map((d) => {
        'weight': d.weight,
        'reps': d.reps,
        'completed': d.completed,
      }).toList())),
      'currentExerciseIndex': _currentExerciseIndex,
      'currentSet': _currentSet,
      'state': _state.name,
      'timerSeconds': _timerSeconds,
      'timerMode': _timerMode.name,
      'restStartTime': _restStartTime?.toIso8601String(),
      'stretchPhase': _currentStretchPhase.name,
      'stretchIndex': _currentStretchIndex,
      'recommendedRest': recommendedRest,
      'savedAt': DateTime.now().toIso8601String(),
    };
  }

  Future<void> _saveProgress() async {
    if (_session == null || _state == WorkoutState.idle ||
        _state == WorkoutState.complete) return;
    await DatabaseService.instance.saveInProgressWorkout(toResumableJson());
  }

  Future<void> clearSavedProgress() async {
    await DatabaseService.instance.clearInProgressWorkout();
  }

  /// Resume a previously saved workout. Call instead of startSession().
  void resumeFromJson({
    required Program program,
    required WorkoutDay day,
    required Map<String, dynamic> data,
  }) {
    _program = program;
    _currentDay = day;

    // Restore session
    final s = data['session'] as Map<String, dynamic>;
    _session = WorkoutSession(
      id: s['id'],
      programId: s['programId'],
      workoutDayId: s['workoutDayId'],
      date: DateTime.parse(s['date']),
      dayRating: s['dayRating'] as int?,
      sets: (s['sets'] as List).map((sl) => SetLog(
        id: sl['id'],
        exerciseId: sl['exerciseId'],
        setNumber: sl['setNumber'],
        weight: (sl['weight'] as num).toDouble(),
        reps: sl['reps'],
        notes: sl['notes'] as String?,
        completedAt: DateTime.parse(sl['completedAt']),
      )).toList(),
      rests: (s['rests'] as List).map((rl) => RestLog(
        exerciseId: rl['exerciseId'],
        setNumber: rl['setNumber'],
        restSeconds: rl['restSeconds'],
      )).toList(),
    );

    // Restore drafts
    _drafts.clear();
    final draftsMap = Map<String, dynamic>.from(data['drafts']);
    for (final entry in draftsMap.entries) {
      _drafts[entry.key] = (entry.value as List).map((d) => _SetDraft(
        weight: (d['weight'] as num).toDouble(),
        reps: d['reps'],
        completed: d['completed'] ?? false,
      )).toList();
    }

    // Restore position
    _currentExerciseIndex = data['currentExerciseIndex'] ?? 0;
    _currentSet = data['currentSet'] ?? 1;
    _timerSeconds = data['timerSeconds'] ?? 0;
    _timerMode = data['timerMode'] == 'countdown'
        ? TimerMode.countdown : TimerMode.stopwatch;
    _currentStretchPhase = data['stretchPhase'] == 'coolDown'
        ? StretchPhase.coolDown : StretchPhase.warmUp;
    _currentStretchIndex = data['stretchIndex'] ?? 0;
    recommendedRest = Map<String, int>.from(data['recommendedRest'] ?? {});

    // Restore rest start time
    final restStr = data['restStartTime'] as String?;
    _restStartTime = restStr != null ? DateTime.parse(restStr) : null;

    // Restore state — if was resting, go back to active (timer expired)
    final stateName = data['state'] as String? ?? 'active';
    if (stateName == 'resting') {
      // Rest likely expired while app was closed — resume as active
      _state = WorkoutState.active;
      _restStartTime = null;
    } else if (stateName == 'stretching') {
      _state = WorkoutState.stretching;
    } else if (stateName == 'rating') {
      _state = WorkoutState.rating;
    } else {
      _state = WorkoutState.active;
    }

    notifyListeners();
  }

  Map<String, int> get sessionRestAverages {
    return _session?.averageRestPerExercise.map(
          (id, duration) => MapEntry(id, duration.inSeconds),
        ) ??
        {};
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
