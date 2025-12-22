import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/emoji_constants.dart';
import '../../core/utils/haptic_utils.dart';
import '../../data/models/mood_entry.dart';
import '../../main.dart';

class MoodEntryScreen extends ConsumerStatefulWidget {
  const MoodEntryScreen({super.key});

  @override
  ConsumerState<MoodEntryScreen> createState() => _MoodEntryScreenState();
}

class _MoodEntryScreenState extends ConsumerState<MoodEntryScreen> {
  String? _selectedMood;
  MoodEntry? todayEntry;
  String imagePath = "";
  TextEditingController noteController = TextEditingController();
  @override
  void initState() {
    super.initState();
    _checkTodayEntry();
  }

  void _checkTodayEntry() {
    final storage = ref.read(storageServiceProvider);
    todayEntry = storage.getTodayMood();

    if (todayEntry != null) {
      setState(() => _selectedMood = todayEntry!.mood);
    }
    imagePath = todayEntry?.photoPath ?? "";
  }

  Future<void> _saveMood() async {
    await HapticUtils.success();

    final storage = ref.read(storageServiceProvider);
    final entry = MoodEntry.create(
      mood: _selectedMood ?? "",
      note: noteController.text,
      photoPath: imagePath.isNotEmpty ? imagePath : null,
    );
    await storage.saveMoodEntry(entry);

    final streak = storage.getCurrentStreak();
    await storage.updateLongestStreak(streak);
    todayEntry = entry;
    // ignore: use_build_context_synchronously
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final storage = ref.watch(storageServiceProvider);
    final userName = storage.getUserName();
    final streak = storage.getCurrentStreak();

    return Scaffold(
      appBar: AppBar(actions: [streakBadge(l10n, streak)]),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              24,
              24,
              24,
              MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                title(userName, l10n),
                const SizedBox(height: 12),
                emojies,
                const Divider(height: 40, thickness: 1.5),
                note(l10n),
                const Divider(height: 40, thickness: 1.5),
                GestureDetector(
                  child: Container(width: 100, height: 100, color: Colors.grey , child: imagePath != "" ? Image.file(File(imagePath)) : null,),
                  onTap: () async {
                    final picker = ImagePicker();
                    final XFile? pickedFile = await picker.pickImage(
                      source: ImageSource.gallery,
                    );

                    if (pickedFile != null) {
                      // Cihazın doküman klasörünü bulalım
                      final directory =
                          await getApplicationDocumentsDirectory();

                      // Dosya adını alalım
                      final fileName = path.basename(pickedFile.path);

                      // Dosyayı yeni konuma kopyalayalım
                      final File savedImage = await File(
                        pickedFile.path,
                      ).copy('${directory.path}/$fileName');

                      setState(() {
                        imagePath = savedImage.path;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.save),
        onPressed: () {
          _saveMood();
        },
      ),
    );
  }

  Widget title(userName, l10n) => Text(
    userName != null
        ? l10n.todayQuestionWithName.replaceAll('{name}', userName)
        : l10n.todayQuestion,
    style: Theme.of(context).textTheme.displayMedium,
    textAlign: TextAlign.start,
  );
  Widget get emojies => Wrap(
    spacing: 12,
    runSpacing: 12,
    alignment: WrapAlignment.start,
    children: EmojiConstants.moods.entries.map((entry) {
      final isSelected = _selectedMood == entry.key;

      return GestureDetector(
        onTap: () => {
          setState(() {
            _selectedMood = entry.key;
          }),
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isSelected ? 75 : 70,
          height: isSelected ? 75 : 70,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.1)
                : AppColors.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.textHint.withOpacity(0.3),
              width: isSelected ? 3 : 1,
            ),
          ),
          child: Center(
            child: Text(
              entry.value,
              style: TextStyle(fontSize: isSelected ? 50 : 40),
            ),
          ),
        ),
      );
    }).toList(),
  );
  Widget note(l10n) => TextFormField(
    controller: noteController,
    minLines: 4,
    maxLines: 6,
    keyboardType: TextInputType.multiline,
    textInputAction: TextInputAction.newline,
    decoration: InputDecoration(
      labelText: l10n.optionalNote,
      hintText:
          l10n.howDoYouFeelToday, // "Bugün seni etkileyen bir şey var mı?"
      alignLabelWithHint: true,
    ),
  );
  Widget streakBadge(l10n, streak) => Container(
    margin: const EdgeInsets.only(right: 16),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.streakFire.withOpacity(0.1),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('🔥', style: TextStyle(fontSize: 12)),
        const SizedBox(width: 4),
        Text(
          '${l10n.streak}: $streak ${l10n.days}',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.streakFire,
          ),
        ),
      ],
    ),
  );
}
