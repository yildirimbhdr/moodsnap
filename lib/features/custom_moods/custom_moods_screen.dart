import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/haptic_utils.dart';
import '../../main.dart';
import 'custom_mood_form_screen.dart';

class CustomMoodsScreen extends ConsumerWidget {
  const CustomMoodsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final customMoodService = ref.watch(customMoodServiceProvider);
    final allMoods = customMoodService.getAllMoods();
    final customMoods = allMoods.where((m) => !m.isDefault).toList();
    final defaultMoods = allMoods.where((m) => m.isDefault).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(l10n.customMoods, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary), onPressed: () => Navigator.pop(context)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (defaultMoods.isNotEmpty) ...[
            Text(l10n.defaultMoods, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...defaultMoods.map((mood) => _MoodCard(mood: mood, isDefault: true)),
            const SizedBox(height: 24),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.customMoodsCount, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('${customMoods.length}', style: TextStyle(fontSize: 16, color: AppColors.primary, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          if (customMoods.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Icon(Icons.mood_outlined, size: 64, color: AppColors.textHint),
                    const SizedBox(height: 16),
                    Text(l10n.noCustomMoods, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text(l10n.tapToCreateFirst, style: TextStyle(color: AppColors.textSecondary), textAlign: TextAlign.center),
                  ],
                ),
              ),
            )
          else
            ...customMoods.map((mood) => _MoodCard(mood: mood, isDefault: false)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await HapticUtils.lightImpact();
          final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomMoodFormScreen()));
          // Refresh is handled automatically by ConsumerWidget (ref.watch)
          // but we can force a rebuild if needed
          if (result == true && context.mounted) {
            // Force rebuild by invalidating the provider
            ref.invalidate(customMoodServiceProvider);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _MoodCard extends ConsumerWidget {
  final mood;
  final bool isDefault;
  const _MoodCard({required this.mood, required this.isDefault});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final customMoodService = ref.read(customMoodServiceProvider);
    final color = customMoodService.getMoodColor(mood.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Text(mood.emoji, style: const TextStyle(fontSize: 32)),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(mood.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
          if (!isDefault)
            IconButton(
              icon: const Icon(Icons.edit, color: AppColors.primary),
              onPressed: () async {
                await HapticUtils.lightImpact();
                final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => CustomMoodFormScreen(moodToEdit: mood)));
                // Force rebuild if mood was updated or deleted
                if (result == true && context.mounted) {
                  ref.invalidate(customMoodServiceProvider);
                }
              },
            ),
        ],
      ),
    );
  }
}
