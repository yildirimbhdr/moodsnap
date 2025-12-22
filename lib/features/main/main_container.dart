import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moodie/features/home/home_screen.dart';
import 'package:moodie/features/moon_entry/mood_entry_screen.dart';
import 'package:moodie/main.dart';
import '../../l10n/app_localizations.dart';
import '../calendar/calendar_screen.dart';
import '../settings/settings_screen.dart';

class MainContainer extends ConsumerStatefulWidget {
  const MainContainer({super.key});

  @override
  ConsumerState<MainContainer> createState() => _MainContainerState();
}

class _MainContainerState extends ConsumerState<MainContainer> {
  int _currentIndex = 0;

  late List<Widget> _screens =  [
    
  ];
  @override
  void initState() {
    super.initState();
    final storage = ref.read(storageServiceProvider);
    var todayEntry = storage.getTodayMood();
    if(todayEntry != null){
      _screens = const [
        HomeScreen(),
        CalendarScreen(),
        SettingsScreen(),
      ];
    } else {
      _screens =const [
        MoodEntryScreen(),
        CalendarScreen(),
        SettingsScreen(),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.mood_outlined),
            selectedIcon: const Icon(Icons.mood),
            label: "${l10n.today} ",
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: const Icon(Icons.calendar_month),
            label: l10n.calendar,
          ),
           NavigationDestination(
            icon:  const Icon(Icons.settings_outlined),
            selectedIcon:  const Icon(Icons.settings),
            label: l10n.settings,
          ),
        ],
      ),
    );
  }
}