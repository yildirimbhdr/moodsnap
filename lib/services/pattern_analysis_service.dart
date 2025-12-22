import '../data/models/mood_entry.dart';

class PatternInsight {
  final String trigger; // Tag that triggers the pattern
  final String affectedMood; // Mood that is affected
  final int occurrences; // How many times this pattern occurred
  final double confidence; // Confidence level (0-1)
  final String emoji;

  PatternInsight({
    required this.trigger,
    required this.affectedMood,
    required this.occurrences,
    required this.confidence,
    required this.emoji,
  });
}

class PatternAnalysisService {
  /// Analyzes mood entries to find patterns between tags and moods
  /// Returns a list of insights ordered by confidence
  List<PatternInsight> analyzePatterns(List<MoodEntry> entries) {
    if (entries.length < 5) {
      return []; // Need at least 5 entries to detect patterns
    }

    final insights = <PatternInsight>[];
    final tagMoodMap = <String, Map<String, int>>{};

    // Count tag-mood combinations
    for (var entry in entries) {
      if (entry.tags != null && entry.tags!.isNotEmpty) {
        for (var tag in entry.tags!) {
          tagMoodMap[tag] ??= {};
          tagMoodMap[tag]![entry.mood] = (tagMoodMap[tag]![entry.mood] ?? 0) + 1;
        }
      }
    }

    // Analyze each tag
    for (var tagEntry in tagMoodMap.entries) {
      final tag = tagEntry.key;
      final moodCounts = tagEntry.value;
      final totalOccurrences = moodCounts.values.reduce((a, b) => a + b);

      // Find the most common mood for this tag
      if (totalOccurrences >= 3) {
        // Need at least 3 occurrences
        final dominantMoodEntry = moodCounts.entries.reduce(
          (a, b) => a.value > b.value ? a : b,
        );

        final dominantMood = dominantMoodEntry.key;
        final dominantCount = dominantMoodEntry.value;

        // Calculate confidence (percentage of times this mood occurred with this tag)
        final confidence = dominantCount / totalOccurrences;

        // Only report if confidence is high enough (>= 60%)
        if (confidence >= 0.6 && dominantCount >= 3) {
          insights.add(
            PatternInsight(
              trigger: tag,
              affectedMood: dominantMood,
              occurrences: dominantCount,
              confidence: confidence,
              emoji: _getEmoji(tag, dominantMood),
            ),
          );
        }
      }
    }

    // Sort by confidence and occurrences
    insights.sort((a, b) {
      final confidenceDiff = b.confidence.compareTo(a.confidence);
      if (confidenceDiff != 0) return confidenceDiff;
      return b.occurrences.compareTo(a.occurrences);
    });

    return insights.take(3).toList(); // Return top 3 insights
  }

  /// Get mood trends over time
  Map<String, int> getMoodTrends(List<MoodEntry> entries) {
    final moodCounts = <String, int>{};
    for (var entry in entries) {
      moodCounts[entry.mood] = (moodCounts[entry.mood] ?? 0) + 1;
    }
    return moodCounts;
  }

  /// Get tag usage frequency
  Map<String, int> getTagFrequency(List<MoodEntry> entries) {
    final tagCounts = <String, int>{};
    for (var entry in entries) {
      if (entry.tags != null) {
        for (var tag in entry.tags!) {
          tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
        }
      }
    }
    return tagCounts;
  }

  /// Check for negative patterns (tags that correlate with negative moods)
  List<PatternInsight> getNegativePatterns(List<MoodEntry> entries) {
    final negativeMoods = ['sad', 'angry', 'anxious', 'tired'];
    final allPatterns = analyzePatterns(entries);

    return allPatterns
        .where((pattern) => negativeMoods.contains(pattern.affectedMood))
        .toList();
  }

  /// Check for positive patterns (tags that correlate with positive moods)
  List<PatternInsight> getPositivePatterns(List<MoodEntry> entries) {
    final positiveMoods = ['happy'];
    final allPatterns = analyzePatterns(entries);

    return allPatterns
        .where((pattern) => positiveMoods.contains(pattern.affectedMood))
        .toList();
  }

  String _getEmoji(String tag, String mood) {
    // Negative combinations
    if (['sad', 'angry', 'anxious', 'tired'].contains(mood)) {
      switch (tag) {
        case 'work':
          return '💼😰';
        case 'sleep':
          return '😴💤';
        case 'health':
          return '❤️‍🩹😔';
        case 'money':
          return '💰😰';
        case 'relationship':
          return '💔😢';
        default:
          return '⚠️';
      }
    }

    // Positive combinations
    if (mood == 'happy') {
      switch (tag) {
        case 'family':
          return '👨‍👩‍👧‍👦😊';
        case 'exercise':
          return '💪😄';
        case 'social':
          return '👥🎉';
        case 'food':
          return '🍽️😋';
        default:
          return '✨';
      }
    }

    return '📊';
  }
}
