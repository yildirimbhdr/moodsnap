import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/custom_mood.dart';
import '../../services/custom_mood_service.dart';
import '../../core/utils/result.dart';
import '../../main.dart';

/// State for custom moods screen
class CustomMoodsState {
  final List<CustomMood> moods;
  final bool isLoading;
  final String? errorMessage;

  const CustomMoodsState({
    this.moods = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  CustomMoodsState copyWith({
    List<CustomMood>? moods,
    bool? isLoading,
    String? errorMessage,
  }) {
    return CustomMoodsState(
      moods: moods ?? this.moods,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  List<CustomMood> get defaultMoods => moods.where((m) => m.isDefault).toList();
  List<CustomMood> get customMoods => moods.where((m) => !m.isDefault).toList();
}

/// Notifier for managing custom moods
class CustomMoodsNotifier extends StateNotifier<CustomMoodsState> {
  final CustomMoodService _service;

  CustomMoodsNotifier(this._service) : super(const CustomMoodsState()) {
    loadMoods();
  }

  /// Load all moods
  Future<void> loadMoods() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final moods = _service.getAllMoods();
      state = CustomMoodsState(moods: moods, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load moods: $e',
      );
    }
  }

  /// Create a new custom mood
  Future<Result<void>> createMood(CustomMood mood) async {
    final result = await _service.createMood(mood);

    if (result.isSuccess) {
      await loadMoods(); // Refresh list
    }

    return result;
  }

  /// Update an existing mood
  Future<Result<void>> updateMood(CustomMood mood) async {
    final result = await _service.updateMood(mood);

    if (result.isSuccess) {
      await loadMoods(); // Refresh list
    }

    return result;
  }

  /// Delete a custom mood
  Future<Result<void>> deleteMood(String id) async {
    final result = await _service.deleteMood(id);

    if (result.isSuccess) {
      await loadMoods(); // Refresh list
    }

    return result;
  }

  /// Get mood color
  getMoodColor(String id) => _service.getMoodColor(id);

  /// Get mood emoji
  String getMoodEmoji(String id) => _service.getMoodEmoji(id);

  /// Get mood name
  String getMoodName(String id) => _service.getMoodName(id);
}

/// Provider for CustomMoodsNotifier
final customMoodsNotifierProvider =
    StateNotifierProvider<CustomMoodsNotifier, CustomMoodsState>((ref) {
  final service = ref.watch(customMoodServiceProvider);
  return CustomMoodsNotifier(service);
});
