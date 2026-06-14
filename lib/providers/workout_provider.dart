import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';
import 'package:uuid/uuid.dart';
import '../models/program.dart';
import '../models/workout_session.dart';
import '../services/database_service.dart';

enum WeightUnit { lbs, kg }

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

  bool get isLastSet =>
      currentExercise != null && _currentSet >= currentExercise!.sets;

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
    final factor =
        newUnit == WeightUnit.kg ? 1 / 2.20462 : 2.20462;

    // Convert all draft weights. Drafts are display values in the current
    // unit; saved SetLogs are always normalized to lbs at completion time.
    for (final drafts in _drafts.values) {
      for (final d in drafts) {
        d.weight = double.parse((d.weight * factor).toStringAsFixed(1));
      }
    }

    _weightUnit = newUnit;
    await DatabaseService.instance
        .saveWeightUnit(newUnit == WeightUnit.kg ? 'kg' : 'lbs');
    notifyListeners();
  }

  // ─── Draft Updates ────────────────────────────────────────────────────────

  void updateDraftWeight(String exerciseId, int setIndex, double weight) {
    _drafts[exerciseId]?[setIndex].weight = weight;
    notifyListeners();
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

    // Pre-populate drafts for every exercise × set, prefilled with the
    // program's target weight (converted to the display unit).
    _drafts.clear();
    for (final pe in day.exercises) {
      final targetLbs = pe.targetWeightLbs ?? 0;
      final displayWeight = _weightUnit == WeightUnit.kg
          ? double.parse((targetLbs / 2.20462).toStringAsFixed(1))
          : targetLbs;
      _drafts[pe.exercise.id] = List.generate(
        pe.sets,
        (i) => _SetDraft(weight: displayWeight, reps: pe.reps),
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

    // Always store weight in lbs; display converts to the chosen unit.
    final weightLbs = _weightUnit == WeightUnit.kg
        ? double.parse((draft.weight * 2.20462).toStringAsFixed(1))
        : draft.weight;

    _session!.sets.add(SetLog(
      id: _uuid.v4(),
      exerciseId: exerciseId,
      setNumber: setIndex + 1,
      weight: weightLbs,
      reps: draft.reps,
      completedAt: DateTime.now(),
    ));

    // Rest after every completed set
    _currentSet = setIndex + 1;
    _restStartTime = DateTime.now();
    _state = WorkoutState.resting;

    if (_timerMode == TimerMode.countdown) {
      // Prefer learned rest averages, then the program's prescribed rest.
      final plannedRest = _currentDay?.exercises
          .where((pe) => pe.exercise.id == exerciseId)
          .firstOrNull
          ?.restSeconds;
      _timerSeconds = recommendedRest[exerciseId] ?? plannedRest ?? 90;
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

    notifyListeners();
  }

  void endRest() {
    _timer?.cancel();

    if (_restStartTime != null && currentExercise != null) {
      final elapsed = DateTime.now().difference(_restStartTime!).inSeconds;
      _session!.rests.add(RestLog(
        exerciseId: currentExercise!.exercise.id,
        setNumber: _currentSet,
        restSeconds: elapsed,
      ));
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
  }

  // ─── Manual Exercise Navigation ───────────────────────────────────────────

  void goToPreviousExercise() {
    if (_currentExerciseIndex <= 0 || _state == WorkoutState.stretching) return;
    _timer?.cancel();
    _restStartTime = null;
    _currentExerciseIndex--;
    _currentSet = 1;
    _state = WorkoutState.active;
    notifyListeners();
  }

  void goToNextExercise() {
    if (isLastExercise || _state == WorkoutState.stretching) return;
    _timer?.cancel();
    _restStartTime = null;
    _currentExerciseIndex++;
    _currentSet = 1;
    _state = WorkoutState.active;
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

    await DatabaseService.instance.saveSession(_session!);
    if (_program != null) {
      await DatabaseService.instance
          .saveRestRecommendations(_program!.id, sessionRestAverages);
    }

    notifyListeners();
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
    notifyListeners();
    DatabaseService.instance.saveExerciseOrder(
        _currentDay!.id, exercises.map((e) => e.id).toList());
  }

  void addExerciseMidWorkout(PlannedExercise exercise) {
    if (_currentDay == null) return;
    _currentDay!.exercises.add(exercise);
    final targetLbs = exercise.targetWeightLbs ?? 0;
    final displayWeight = _weightUnit == WeightUnit.kg
        ? double.parse((targetLbs / 2.20462).toStringAsFixed(1))
        : targetLbs;
    _drafts[exercise.exercise.id] = List.generate(
      exercise.sets,
      (i) => _SetDraft(weight: displayWeight, reps: exercise.reps),
    );
    notifyListeners();
  }

  bool isExerciseComplete(String exerciseId) {
    final drafts = _drafts[exerciseId];
    return drafts != null && drafts.every((d) => d.completed);
  }

  String? get programId => _program?.id;

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
