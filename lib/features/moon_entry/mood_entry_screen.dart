import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/tag_constants.dart';
import '../../core/utils/haptic_utils.dart';
import '../../data/models/mood_entry.dart';
import '../../main.dart';

class MoodEntryScreen extends ConsumerStatefulWidget {
  final MoodEntry? editEntry;

  const MoodEntryScreen({super.key, this.editEntry});

  @override
  ConsumerState<MoodEntryScreen> createState() => _MoodEntryScreenState();
}

class _MoodEntryScreenState extends ConsumerState<MoodEntryScreen> {
  String? _selectedMood;
  MoodEntry? todayEntry;
  String imagePath = "";
  TextEditingController noteController = TextEditingController();
  List<String> _selectedTags = [];

  @override
  void initState() {
    super.initState();
    _checkTodayEntry();
  }

  void _checkTodayEntry() {
    final storage = ref.read(storageServiceProvider);

    // If editing an existing entry, use it
    if (widget.editEntry != null) {
      todayEntry = widget.editEntry;
      setState(() {
        _selectedMood = todayEntry!.mood;
        _selectedTags = todayEntry!.tags ?? [];
        noteController.text = todayEntry!.note ?? "";
      });
      imagePath = todayEntry?.photoPath ?? "";
    } else {
      // Otherwise check for today's entry
      todayEntry = storage.getTodayMood();

      if (todayEntry != null) {
        setState(() {
          _selectedMood = todayEntry!.mood;
          _selectedTags = todayEntry!.tags ?? [];
          noteController.text = todayEntry!.note ?? "";
        });
      }
      imagePath = todayEntry?.photoPath ?? "";
    }
  }

  Future<void> _saveMood() async {
    if (_selectedMood == null || _selectedMood!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).pleaseSelectMood),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await HapticUtils.success();

    final storage = ref.read(storageServiceProvider);
    final achievementService = ref.read(achievementServiceProvider);

    // If editing an existing entry, preserve its date
    final MoodEntry entry;
    if (widget.editEntry != null) {
      entry = MoodEntry(
        id: widget.editEntry!.id,
        mood: _selectedMood ?? "",
        date: widget.editEntry!.date, // Preserve original date
        note: noteController.text.isEmpty ? null : noteController.text,
        photoPath: imagePath.isNotEmpty ? imagePath : null,
        tags: _selectedTags.isEmpty ? null : _selectedTags,
      );
    } else {
      entry = MoodEntry.create(
        mood: _selectedMood ?? "",
        note: noteController.text,
        photoPath: imagePath.isNotEmpty ? imagePath : null,
        tags: _selectedTags.isEmpty ? null : _selectedTags,
      );
    }

    await storage.saveMoodEntry(entry);

    final streak = storage.getCurrentStreak();
    await storage.updateLongestStreak(streak);
    todayEntry = entry;

    // Check for new achievements
    final allEntries = storage.getAllMoodEntries();
    final newAchievements = await achievementService.checkAchievements(
      allEntries: allEntries,
      currentStreak: streak,
    );

    if (!mounted) return;

    // Show achievement notification if any new achievements unlocked
    if (newAchievements.isNotEmpty && mounted) {
      final l10n = AppLocalizations.of(context);
      for (var achievement in newAchievements) {
        if (!mounted) break;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Text(
                  achievement.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.achievementsUnlocked,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        achievement.title,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final storage = ref.watch(storageServiceProvider);
    final userName = storage.getUserName();
    final streak = storage.getCurrentStreak();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [streakBadge(l10n, streak)],
      ),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    8,
                    24,
                    MediaQuery.of(context).viewInsets.bottom + 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      title(userName, l10n),
                      const SizedBox(height: 32),
                      _buildMoodSectionLabel(l10n),
                      const SizedBox(height: 16),
                      emojies,
                      const SizedBox(height: 32),
                      _buildNoteSectionLabel(l10n),
                      const SizedBox(height: 16),
                      note(l10n),
                      const SizedBox(height: 32),
                      _buildTagSectionLabel(l10n),
                      const SizedBox(height: 16),
                      _buildTagSection(l10n),
                      const SizedBox(height: 32),
                      _buildPhotoSectionLabel(l10n),
                      const SizedBox(height: 16),
                      _buildPhotoSection(l10n),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildSaveButton(l10n),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildMoodSectionLabel(AppLocalizations l10n) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.mood,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          l10n.todayQuestion,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildNoteSectionLabel(AppLocalizations l10n) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.note_alt_outlined,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          l10n.optionalNote,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoSectionLabel(AppLocalizations l10n) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.photo_camera_outlined,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          l10n.addPhoto,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(AppLocalizations l10n) {
    return Container(
      width: MediaQuery.of(context).size.width - 48,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _saveMood,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.save,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget title(userName, l10n) {
    // Show different title if editing
    String titleText;
    if (widget.editEntry != null) {
      final monthNames = [
        l10n.january, l10n.february, l10n.march, l10n.april,
        l10n.may, l10n.june, l10n.july, l10n.august,
        l10n.september, l10n.october, l10n.november, l10n.december,
      ];
      final date = widget.editEntry!.date;
      titleText = '${l10n.edit} - ${date.day} ${monthNames[date.month - 1]}';
    } else {
      titleText = userName != null
          ? l10n.todayQuestionWithName.replaceAll('{name}', userName)
          : l10n.todayQuestion;
    }

    return Text(
      titleText,
      style: Theme.of(context).textTheme.displayMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
      textAlign: TextAlign.start,
    );
  }
  Widget get emojies {
    final customMoodService = ref.read(customMoodServiceProvider);
    final allMoods = customMoodService.getAllMoods();

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: allMoods.map((mood) {
        final isSelected = _selectedMood == mood.id;

        final color = customMoodService.getMoodColor(mood.id);

        return GestureDetector(
          onTap: () async {
            await HapticUtils.lightImpact();
            setState(() {
              _selectedMood = mood.id;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: isSelected ? 85 : 75,
            height: isSelected ? 85 : 75,
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        color.withOpacity(0.15),
                        color.withOpacity(0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isSelected ? null : AppColors.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? color
                    : AppColors.textHint.withOpacity(0.2),
                width: isSelected ? 3 : 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Center(
              child: Text(
                mood.emoji,
                style: TextStyle(fontSize: isSelected ? 48 : 40),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
  Widget note(l10n) => Container(
    decoration: BoxDecoration(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: AppColors.textHint.withOpacity(0.2),
        width: 1.5,
      ),
    ),
    child: TextFormField(
      controller: noteController,
      minLines: 4,
      maxLines: 6,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      style: const TextStyle(
        fontSize: 15,
        color: AppColors.textPrimary,
        height: 1.5,
      ),
      decoration: InputDecoration(
        hintText: l10n.howDoYouFeelToday,
        hintStyle: TextStyle(
          color: AppColors.textSecondary.withOpacity(0.5),
          fontSize: 14,
        ),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.all(16),
      ),
    ),
  );

  Widget _buildTagSectionLabel(AppLocalizations l10n) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.psychology_outlined,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            l10n.whyThisMood,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagSection(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.textHint.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.selectReasons,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary.withOpacity(0.9),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: TagConstants.all.map((tag) {
              final isSelected = _selectedTags.contains(tag);
              final tagColor = TagConstants.getTagColor(tag);

              return GestureDetector(
                onTap: () async {
                  await HapticUtils.lightImpact();
                  setState(() {
                    if (isSelected) {
                      _selectedTags.remove(tag);
                    } else {
                      _selectedTags.add(tag);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? tagColor.withOpacity(0.15)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? tagColor.withOpacity(0.5)
                          : AppColors.textHint.withOpacity(0.25),
                      width: isSelected ? 2 : 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: tagColor.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Opacity(
                        opacity: isSelected ? 1.0 : 0.7,
                        child: Text(
                          TagConstants.getTagEmoji(tag),
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        TagConstants.getLocalizedTag(tag, l10n),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected
                              ? tagColor
                              : AppColors.textSecondary,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: tagColor,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          if (_selectedTags.isEmpty) ...[
            const SizedBox(height: 12),
            Center(
              child: Text(
                l10n.selectReasons,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary.withOpacity(0.5),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhotoSection(AppLocalizations l10n) {
    return GestureDetector(
      onTap: () async {
        await HapticUtils.lightImpact();
        _showPhotoOptions(l10n);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        height: imagePath.isNotEmpty ? 240 : 180,
        decoration: BoxDecoration(
          color: imagePath.isNotEmpty
              ? Colors.transparent
              : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: imagePath.isNotEmpty
                ? AppColors.primary.withOpacity(0.3)
                : AppColors.textHint.withOpacity(0.2),
            width: imagePath.isNotEmpty ? 2 : 1.5,
          ),
          boxShadow: imagePath.isNotEmpty
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ]
              : [],
        ),
        child: imagePath.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(
                      File(imagePath),
                      fit: BoxFit.cover,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.0),
                            Colors.black.withOpacity(0.3),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            imagePath = "";
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.15),
                          AppColors.primary.withOpacity(0.08),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_photo_alternate_rounded,
                      size: 48,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.tapToAddPhoto,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      l10n.addMomentFromDay,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _showPhotoOptions(AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.camera_alt, color: AppColors.primary),
              ),
              title: Text(l10n.takePhoto),
              onTap: () async {
                Navigator.pop(context);
                await _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.photo_library, color: AppColors.primary),
              ),
              title: Text(l10n.chooseFromGallery),
              onTap: () async {
                Navigator.pop(context);
                await _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    await HapticUtils.lightImpact();
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1920,
      maxHeight: 1920,
    );

    if (pickedFile != null) {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = path.basename(pickedFile.path);
      final File savedImage = await File(pickedFile.path)
          .copy('${directory.path}/$fileName');

      setState(() {
        imagePath = savedImage.path;
      });
    }
  }

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
