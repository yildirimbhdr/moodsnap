import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/emoji_constants.dart';
import '../../main.dart';
import 'widgets/day_detail_sheet.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  void _showDayDetail(DateTime date) {
    final storage = ref.read(storageServiceProvider);
    final entry = storage.getMoodEntry(date);

    if (entry != null) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => DayDetailSheet(entry: entry),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final storage = ref.watch(storageServiceProvider);
    final entries = storage.getMoodEntriesForMonth(
      _currentMonth.year,
      _currentMonth.month,
    );
    final streak = storage.getCurrentStreak();

    // Get month name
    final monthNames = [
      l10n.january,
      l10n.february,
      l10n.march,
      l10n.april,
      l10n.may,
      l10n.june,
      l10n.july,
      l10n.august,
      l10n.september,
      l10n.october,
      l10n.november,
      l10n.december,
    ];
    final monthName = monthNames[_currentMonth.month - 1];

    // Calculate most common mood
    final moodCounts = <String, int>{};
    for (var entry in entries) {
      moodCounts[entry.mood] = (moodCounts[entry.mood] ?? 0) + 1;
    }
    final mostCommonMood = moodCounts.isEmpty
        ? null
        : moodCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.calendar,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Month selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _previousMonth,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(
                  '$monthName ${_currentMonth.year}',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: _nextMonth,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Stats card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    icon: '🔥',
                    label: l10n.streak,
                    value: '$streak ${l10n.days}',
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: AppColors.textHint.withOpacity(0.3),
                  ),
                  _buildStatItem(
                    icon: mostCommonMood != null
                        ? EmojiConstants.getEmoji(mostCommonMood)
                        : '📊',
                    label: l10n.mostCommon,
                    value: '${entries.length} ${l10n.days}',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Calendar grid
            _buildCalendarGrid(entries),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 32)),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid(List entries) {
    final l10n = AppLocalizations.of(context);
    final daysInMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      0,
    ).day;
    final firstDayOfMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month,
      1,
    );
    final firstWeekday = firstDayOfMonth.weekday;

    final dayNames = [
      l10n.monday,
      l10n.tuesday,
      l10n.wednesday,
      l10n.thursday,
      l10n.friday,
      l10n.saturday,
      l10n.sunday,
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Day names header
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 7,
            childAspectRatio: 1.6,
            children: dayNames.map((day) {
              return Center(
                child: Text(
                  day,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Calendar days
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              mainAxisExtent: 50,
              crossAxisSpacing: 8,
            ),
            itemCount: firstWeekday - 1 + daysInMonth,
            itemBuilder: (context, index) {
              if (index < firstWeekday - 1) {
                return const SizedBox();
              }

              final day = index - firstWeekday + 2;
              final date = DateTime(
                _currentMonth.year,
                _currentMonth.month,
                day,
              );
              final storage = ref.read(storageServiceProvider);
              final entry = storage.getMoodEntry(date);

              final isToday =
                  date.year == DateTime.now().year &&
                  date.month == DateTime.now().month &&
                  date.day == DateTime.now().day;

              return GestureDetector(
                onTap: entry != null ? () => _showDayDetail(date) : null,
                child: Container(
                  decoration: BoxDecoration(
                    color: isToday
                        ? AppColors.primary.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: isToday
                        ? Border.all(color: AppColors.primary, width: 2)
                        : null,
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isToday
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isToday
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(
                        height: 20,
                        child: Center(
                          child: Text(
                            entry != null
                                ? EmojiConstants.getEmoji(entry.mood)
                                : '',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              height: 1.0,
                              leadingDistribution: TextLeadingDistribution.even,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
