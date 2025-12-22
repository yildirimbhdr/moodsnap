class EmojiConstants {
  static const Map<String, String> moods = {
    'happy': '😊',
    'neutral': '😐',
    'sad': '😔',
    'angry': '😡',
    'anxious': '😰',
    'tired': '😴',
  };
  
  static const Map<String, String> moodLabels = {
    'happy': 'mood_happy',
    'neutral': 'mood_neutral',
    'sad': 'mood_sad',
    'angry': 'mood_angry',
    'anxious': 'mood_anxious',
    'tired': 'mood_tired',
  };
  
  static String getEmoji(String mood) => moods[mood] ?? '😐';
  static String getLabel(String mood) => moodLabels[mood] ?? 'mood_neutral';
}