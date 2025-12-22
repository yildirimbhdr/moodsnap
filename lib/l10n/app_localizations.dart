import 'package:flutter/material.dart';
import 'app_tr.dart';
import 'app_en.dart';
import 'app_de.dart';

abstract class AppLocalizations {
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  // Supported locales
  static const supportedLocales = [
    Locale('tr'),
    Locale('en'),
    Locale('de'),
  ];

  static LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  // Common
  String get appName;
  String get skip;
  String get next;
  String get start;
  String get save;
  String get cancel;
  String get delete;
  String get edit;
  String get today;
  
  // Onboarding
  String get onboarding1Title;
  String get onboarding1Desc;
  String get onboarding2Title;
  String get onboarding2Desc;
  String get onboarding3Title;
  String get onboarding3Desc;
  
  // Notification Permission
  String get notifPermissionTitle;
  String get notifPermissionYes;
  String get notifPermissionNo;
  
  // Name Input
  String get nameInputTitle;
  String get nameInputHint;
  
  // Mood Entry
  String get todayQuestion;
  String get todayQuestionWithName;
  String get saved;
  String get addDetail;
  
  // Moods
  String get moodHappy;
  String get moodNeutral;
  String get moodSad;
  String get moodAngry;
  String get moodAnxious;
  String get moodTired;
  
  // Streak
  String get streak;
  String get days;
  String get streakBroken;
  String get previousRecord;
  String get noWorries;
  String get recordToday;
  
  // Calendar
  String get calendar;
  String get mostCommon;
  
  // Days
  String get monday;
  String get tuesday;
  String get wednesday;
  String get thursday;
  String get friday;
  String get saturday;
  String get sunday;
  
  // Months
  String get january;
  String get february;
  String get march;
  String get april;
  String get may;
  String get june;
  String get july;
  String get august;
  String get september;
  String get october;
  String get november;
  String get december;
  String get todayMoodIs;
  String get optionalNote;
  String get howDoYouFeelToday;
  String get rank;
  String get day;
  String get touchToChange;
  String get youLookGreat;
  String get recentEntries;
  String get settings;
  String get language;
  String get notifications;
  String get dailyMoodReminder;
  String get everyDayNotificationSequence;
  String get stats;
  String get longestStreak;
  String get totalEntries;
  String get dangerZone;
  String get deleteAllData;
  String get deleteAllDataWarning;
  String get confirmDeleteAllData;
  String get name;
  String get nameInput;
  String get deleteAllDataConfirmation;
  

}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  @override
  bool isSupported(Locale locale) {
    return ['tr', 'en', 'de'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    switch (locale.languageCode) {
      case 'tr':
        return AppLocalizationsTR();
      case 'de':
        return AppLocalizationsDE();
      case 'en':
      default:
        return AppLocalizationsEN();
    }
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}