import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import '../../data/models/custom_mood.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/haptic_utils.dart';
import '../../main.dart';

class CustomMoodFormScreen extends ConsumerStatefulWidget {
  final CustomMood? moodToEdit;
  const CustomMoodFormScreen({super.key, this.moodToEdit});

  @override
  ConsumerState<CustomMoodFormScreen> createState() => _CustomMoodFormScreenState();
}

class _CustomMoodFormScreenState extends ConsumerState<CustomMoodFormScreen> {
  late TextEditingController _nameController;
  String _selectedEmoji = '';
  Color _selectedColor = Colors.blue;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.moodToEdit?.name ?? '');
    _selectedEmoji = widget.moodToEdit?.emoji ?? '';
    if (widget.moodToEdit != null) {
      final customMoodService = ref.read(customMoodServiceProvider);
      _selectedColor = customMoodService.getMoodColor(widget.moodToEdit!.id);
    }
  }

  Future<void> _saveMood() async {
    final l10n = AppLocalizations.of(context);
    final customMoodService = ref.read(customMoodServiceProvider);

    if (_nameController.text.trim().isEmpty) {
      _showError(l10n.moodNameRequired);
      return;
    }
    if (_selectedEmoji.isEmpty) {
      _showError(l10n.moodEmojiRequired);
      return;
    }

    if (customMoodService.isNameUsed(_nameController.text, excludeId: widget.moodToEdit?.id)) {
      _showError(l10n.moodNameExists);
      return;
    }
    if (customMoodService.isEmojiUsed(_selectedEmoji, excludeId: widget.moodToEdit?.id)) {
      _showError(l10n.moodEmojiExists);
      return;
    }

    final colorHex = '#${_selectedColor.value.toRadixString(16).substring(2).toUpperCase()}';

    if (widget.moodToEdit != null) {
      final updated = widget.moodToEdit!.copyWith(name: _nameController.text, emoji: _selectedEmoji, colorHex: colorHex);
      await customMoodService.updateMood(updated);
    } else {
      final mood = CustomMood.create(name: _nameController.text, emoji: _selectedEmoji, colorHex: colorHex);
      await customMoodService.createMood(mood);
    }

    if (mounted) Navigator.pop(context, true);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.moodToEdit == null ? l10n.createCustomMood : l10n.editMood, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary), onPressed: () => Navigator.pop(context)),
        actions: widget.moodToEdit != null && !widget.moodToEdit!.isDefault
            ? [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    await HapticUtils.mediumImpact();
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(l10n.deleteMood),
                        content: Text(l10n.deleteMoodWarning),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true && mounted) {
                      final customMoodService = ref.read(customMoodServiceProvider);
                      await customMoodService.deleteMood(widget.moodToEdit!.id);
                      Navigator.pop(context, true);
                    }
                  },
                ),
              ]
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: l10n.moodName,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () async {
              await HapticUtils.lightImpact();
              _showEmojiPicker();
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.textHint.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Text(_selectedEmoji.isEmpty ? '🎭' : _selectedEmoji, style: const TextStyle(fontSize: 48)),
                  const SizedBox(width: 16),
                  Expanded(child: Text(_selectedEmoji.isEmpty ? l10n.selectEmoji : l10n.moodEmoji, style: const TextStyle(fontSize: 16))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(l10n.moodColor, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ColorPicker(
            color: _selectedColor,
            onColorChanged: (color) => setState(() => _selectedColor = color),
            pickersEnabled: const {ColorPickerType.wheel: true},
            width: 40,
            height: 40,
            borderRadius: 8,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveMood,
        label: Text(widget.moodToEdit == null ? l10n.create : l10n.update),
        icon: const Icon(Icons.check),
      ),
    );
  }

  void _showEmojiPicker() {
    final emojis = ['😊', '😐', '😔', '😡', '😰', '😴', '🥳', '😍', '🤗', '🙃', '😎', '🤩', '😴', '🥱', '😌', '😇', '🤔', '🙄', '😬', '🤐', '😏', '😤', '😪', '😮', '😲', '😵', '🤯', '😱', '😨', '😓', '😥', '😢', '😭', '😤', '😠', '😈', '👿'];
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, mainAxisSpacing: 10, crossAxisSpacing: 10),
          itemCount: emojis.length,
          itemBuilder: (context, index) => GestureDetector(
            onTap: () {
              setState(() => _selectedEmoji = emojis[index]);
              Navigator.pop(context);
            },
            child: Container(
              decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(12)),
              child: Center(child: Text(emojis[index], style: const TextStyle(fontSize: 32))),
            ),
          ),
        ),
      ),
    );
  }
}
