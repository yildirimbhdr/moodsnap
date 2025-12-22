import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/achievement.dart';
import '../../main.dart';
import '../../l10n/app_localizations.dart';

class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initAchievements();
  }

  Future<void> _initAchievements() async {
    // Check for new achievements
    final storage = ref.read(storageServiceProvider);
    final achievementService = ref.read(achievementServiceProvider);
    await achievementService.checkAchievements(
      allEntries: storage.getAllMoodEntries(),
      currentStreak: storage.getCurrentStreak(),
    );

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.achievements),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final storage = ref.watch(storageServiceProvider);
    final achievementService = ref.watch(achievementServiceProvider);
    final achievements = achievementService.getAllAchievements();
    final unlockedCount = achievements.where((a) => a.isUnlocked).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.achievements,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildHeader(context, unlockedCount, achievements.length),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: achievements.length,
              itemBuilder: (context, index) {
                final achievement = achievements[index];
                final progress = achievementService.getProgress(
                  achievement,
                  allEntries: storage.getAllMoodEntries(),
                  currentStreak: storage.getCurrentStreak(),
                );

                return _buildAchievementCard(context, achievement, progress);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int unlocked, int total) {
    final l10n = AppLocalizations.of(context);
    final percentage = (unlocked / total * 100).toInt();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.8),
            AppColors.primary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '🏆',
            style: TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 12),
          Text(
            '$unlocked / $total',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${l10n.achievementsUnlocked} ($percentage%)',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: unlocked / total,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  String _getLocalizedTitle(BuildContext context, String achievementId) {
    final l10n = AppLocalizations.of(context);
    switch (achievementId) {
      case 'first_step':
        return l10n.achievementFirstStep;
      case 'streak_7':
        return l10n.achievementStreak7;
      case 'streak_30':
        return l10n.achievementStreak30;
      case 'streak_100':
        return l10n.achievementStreak100;
      case 'photo_10':
        return l10n.achievementPhoto10;
      default:
        return achievementId;
    }
  }

  String _getLocalizedDescription(BuildContext context, String achievementId) {
    final l10n = AppLocalizations.of(context);
    switch (achievementId) {
      case 'first_step':
        return l10n.achievementFirstStepDesc;
      case 'streak_7':
        return l10n.achievementStreak7Desc;
      case 'streak_30':
        return l10n.achievementStreak30Desc;
      case 'streak_100':
        return l10n.achievementStreak100Desc;
      case 'photo_10':
        return l10n.achievementPhoto10Desc;
      default:
        return achievementId;
    }
  }

  Widget _buildAchievementCard(BuildContext context, Achievement achievement, double progress) {
    final l10n = AppLocalizations.of(context);
    final isUnlocked = achievement.isUnlocked;
    final title = _getLocalizedTitle(context, achievement.id);
    final description = _getLocalizedDescription(context, achievement.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isUnlocked
            ? AppColors.cardBackground
            : AppColors.cardBackground.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUnlocked
              ? AppColors.primary.withOpacity(0.3)
              : AppColors.textHint.withOpacity(0.2),
          width: 2,
        ),
        boxShadow: isUnlocked
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: isUnlocked
                    ? LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.2),
                          AppColors.primary.withOpacity(0.1),
                        ],
                      )
                    : null,
                color: isUnlocked ? null : AppColors.textHint.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  achievement.emoji,
                  style: TextStyle(
                    fontSize: 32,
                    color: isUnlocked ? null : Colors.grey.withOpacity(0.3),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isUnlocked
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary.withOpacity(0.8),
                    ),
                  ),
                  if (!isUnlocked) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: AppColors.textHint.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary.withOpacity(0.6),
                        ),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(progress * 100).toInt()}% ${l10n.percentComplete}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary.withOpacity(0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isUnlocked)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
