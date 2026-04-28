import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants.dart';
import '../../data/models/daily_log.dart';
import '../../data/models/food.dart';
import '../../data/models/macro_totals.dart';
import '../../data/models/meal_entry.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/food_repository.dart';
import '../../data/repositories/log_repository.dart';
import '../../domain/parsing/fuzzy_matcher.dart';
import '../../domain/parsing/voice_parser.dart';

// ---------------------------------------------------------------------------
// Foods
// ---------------------------------------------------------------------------

final foodsProvider =
    AsyncNotifierProvider<FoodsNotifier, List<Food>>(FoodsNotifier.new);

class FoodsNotifier extends AsyncNotifier<List<Food>> {
  @override
  Future<List<Food>> build() => FoodRepository.instance.getAllFoods();
}

// ---------------------------------------------------------------------------
// FuzzyMatcher — derived from foods, synchronous after load
// ---------------------------------------------------------------------------

final fuzzyMatcherProvider = Provider<FuzzyMatcher>((ref) {
  final foods = ref.watch(foodsProvider).valueOrNull ?? [];
  return FuzzyMatcher(foods);
});

// ---------------------------------------------------------------------------
// Daily log (family by date string "YYYY-MM-DD")
// ---------------------------------------------------------------------------

final logProvider = AsyncNotifierProviderFamily<LogNotifier, DailyLog, String>(
  LogNotifier.new,
);

class LogNotifier extends FamilyAsyncNotifier<DailyLog, String> {
  @override
  Future<DailyLog> build(String date) =>
      LogRepository.instance.getDailyLog(date);

  Future<void> addEntries(List<MealEntry> entries) async {
    await LogRepository.instance.addEntries(entries);
    ref.invalidateSelf();
  }

  Future<void> deleteEntry(String id) async {
    await LogRepository.instance.deleteEntry(id);
    ref.invalidateSelf();
  }

  Future<void> deleteEntries(List<String> ids) async {
    await LogRepository.instance.deleteEntries(ids);
    ref.invalidateSelf();
  }

  Future<void> updateEntry(MealEntry entry) async {
    await LogRepository.instance.updateEntry(entry);
    ref.invalidateSelf();
  }
}

// ---------------------------------------------------------------------------
// Monthly calendar data (map of date → calories)
// ---------------------------------------------------------------------------

final monthlyCaloriesProvider = FutureProvider.family<Map<String, double>, String>(
  (ref, month) => LogRepository.instance.getMonthlyCalories(month),
);

// ---------------------------------------------------------------------------
// Goals
// ---------------------------------------------------------------------------

final goalsProvider =
    AsyncNotifierProvider<GoalsNotifier, MacroGoals>(GoalsNotifier.new);

class GoalsNotifier extends AsyncNotifier<MacroGoals> {
  @override
  Future<MacroGoals> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppStrings.goalsKey);
    if (raw == null) return MacroGoals.defaults();
    try {
      return MacroGoals.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Failed to load goals: $e — clearing corrupted data');
      await prefs.remove(AppStrings.goalsKey);
      return MacroGoals.defaults();
    }
  }

  Future<void> save(MacroGoals goals) async {
    state = AsyncData(goals);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppStrings.goalsKey, jsonEncode(goals.toJson()));
  }
}

// ---------------------------------------------------------------------------
// User profile
// ---------------------------------------------------------------------------

final profileProvider =
    AsyncNotifierProvider<ProfileNotifier, UserProfile?>(ProfileNotifier.new);

class ProfileNotifier extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppStrings.profileKey);
    if (raw == null) return null;
    try {
      return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Failed to load profile: $e — clearing corrupted data');
      await prefs.remove(AppStrings.profileKey);
      return null;
    }
  }

  Future<void> save(UserProfile profile) async {
    state = AsyncData(profile);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppStrings.profileKey, jsonEncode(profile.toJson()));
  }
}

// ---------------------------------------------------------------------------
// Voice state
// ---------------------------------------------------------------------------

class VoiceState {
  final bool isListening;
  final String transcript;
  final double soundLevel;
  final List<ParseCandidate> candidates;
  final String? errorMessage;

  const VoiceState({
    this.isListening = false,
    this.transcript = '',
    this.soundLevel = 0.0,
    this.candidates = const [],
    this.errorMessage,
  });

  VoiceState copyWith({
    bool? isListening,
    String? transcript,
    double? soundLevel,
    List<ParseCandidate>? candidates,
    String? errorMessage,
  }) =>
      VoiceState(
        isListening: isListening ?? this.isListening,
        transcript: transcript ?? this.transcript,
        soundLevel: soundLevel ?? this.soundLevel,
        candidates: candidates ?? this.candidates,
        errorMessage: errorMessage,
      );

  VoiceState reset() => const VoiceState();
}

final voiceProvider =
    StateNotifierProvider<VoiceNotifier, VoiceState>((ref) => VoiceNotifier());

class VoiceNotifier extends StateNotifier<VoiceState> {
  VoiceNotifier() : super(const VoiceState());

  final _parser = VoiceParser();

  void updateTranscript(String text, bool isFinal) {
    final candidates = isFinal ? _parser.parse(text) : state.candidates;
    state = state.copyWith(
      transcript: text,
      candidates: candidates,
      isListening: !isFinal,
    );
  }

  void updateSoundLevel(double level) {
    state = state.copyWith(soundLevel: level);
  }

  void setListening(bool v) {
    state = state.copyWith(isListening: v);
  }

  void setError(String msg) {
    state = state.copyWith(errorMessage: msg, isListening: false);
  }

  void reset() {
    state = const VoiceState();
  }

  /// Run parser on current transcript (called when user manually stops).
  void finalize() {
    final candidates = _parser.parse(state.transcript);
    state = state.copyWith(isListening: false, candidates: candidates);
  }
}
