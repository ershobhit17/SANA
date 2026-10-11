import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/alarm_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/dayflow_theme_context.dart';
import '../../../models/habit_model.dart';
import '../../../models/reminder_model.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/dayflow_button.dart';
import '../../../shared/widgets/dayflow_chip.dart';
import '../../../shared/widgets/dayflow_text_field.dart';

class HabitFormDialog extends ConsumerStatefulWidget {
  final HabitItem? initialHabit;

  const HabitFormDialog({super.key, this.initialHabit});

  @override
  ConsumerState<HabitFormDialog> createState() => _HabitFormDialogState();
}

class _HabitFormDialogState extends ConsumerState<HabitFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _targetController;
  late TextEditingController _unitController;

  late int _selectedIconCode;
  late int _selectedColorValue;
  HabitFrequency _frequency = HabitFrequency.daily;
  List<int> _targetDays = [1, 2, 3, 4, 5, 6, 7];
  bool _hasReminder = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 8, minute: 0);
  String? _customAudioPath;
  String? _customAudioName;
  bool _isPlayingAudio = false;

  final List<Map<String, dynamic>> _iconChoices = [
    {'name': 'Fitness', 'icon': Icons.fitness_center},
    {'name': 'Water', 'icon': Icons.local_drink},
    {'name': 'Book', 'icon': Icons.menu_book},
    {'name': 'Code', 'icon': Icons.code},
    {'name': 'Self Care', 'icon': Icons.spa},
    {'name': 'Running', 'icon': Icons.directions_run},
    {'name': 'Bedtime', 'icon': Icons.bedtime},
    {'name': 'Notes', 'icon': Icons.edit_note},
    {'name': 'Focus', 'icon': Icons.timer},
    {'name': 'Heart', 'icon': Icons.favorite},
  ];

  final List<Color> _colorChoices = [
    const Color(0xFF10B981), // Emerald
    const Color(0xFF06B6D4), // Cyan
    const Color(0xFF6366F1), // Indigo
    const Color(0xFF8B5CF6), // Violet
    const Color(0xFFEC4899), // Pink
    const Color(0xFFF59E0B), // Amber
    const Color(0xFFEF4444), // Coral Red
    const Color(0xFF14B8A6), // Teal
  ];

  @override
  void initState() {
    super.initState();
    final h = widget.initialHabit;
    _nameController = TextEditingController(text: h?.name ?? '');
    _targetController =
        TextEditingController(text: (h?.dailyTarget ?? 1).toString());
    _unitController = TextEditingController(text: h?.unit ?? '');

    _selectedIconCode = h?.iconCodePoint ?? Icons.fitness_center.codePoint;
    _selectedColorValue = h?.colorValue ?? 0xFF10B981;
    _frequency = h?.frequency ?? HabitFrequency.daily;
    _targetDays = h?.targetDays ?? [1, 2, 3, 4, 5, 6, 7];
    _hasReminder = h?.hasReminder ?? false;
    _customAudioPath = h?.customAudioPath;
    _customAudioName = h?.customAudioName;

    if (h?.reminderTime != null) {
      try {
        final parts = h!.reminderTime!.split(':');
        _reminderTime =
            TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    if (_isPlayingAudio) {
      AlarmService.instance.stopAudio();
    }
    _nameController.dispose();
    _targetController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _pickAudioFile() async {
    try {
      final pickedFiles = await FilePicker.pickFiles(
        type: FileType.audio,
      );
      if (pickedFiles.isNotEmpty && pickedFiles.first.path != null) {
        final file = pickedFiles.first;
        setState(() {
          _customAudioPath = file.path;
          _customAudioName = file.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick audio file: $e')),
        );
      }
    }
  }

  Future<void> _toggleAudioPreview() async {
    if (_customAudioPath == null) return;
    if (_isPlayingAudio) {
      await AlarmService.instance.stopAudio();
      setState(() => _isPlayingAudio = false);
    } else {
      setState(() => _isPlayingAudio = true);
      await AlarmService.instance.previewAudio(_customAudioPath!);
    }
  }

  void _clearCustomAudio() {
    if (_isPlayingAudio) {
      AlarmService.instance.stopAudio();
    }
    setState(() {
      _customAudioPath = null;
      _customAudioName = null;
      _isPlayingAudio = false;
    });
  }

  void _saveHabit() {
    if (!_formKey.currentState!.validate()) return;

    final targetVal = int.tryParse(_targetController.text.trim()) ?? 1;
    final remTimeStr = _hasReminder
        ? '${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}'
        : null;

    final now = DateTime.now();
    final habitId = widget.initialHabit?.id ?? const Uuid().v4();

    final habit = HabitItem(
      id: habitId,
      name: _nameController.text.trim(),
      iconCodePoint: _selectedIconCode,
      colorValue: _selectedColorValue,
      frequency: _frequency,
      targetDays: _targetDays,
      dailyTarget: targetVal,
      unit: _unitController.text.trim().isEmpty
          ? null
          : _unitController.text.trim(),
      hasReminder: _hasReminder,
      reminderTime: remTimeStr,
      customAudioPath: _customAudioPath,
      customAudioName: _customAudioName,
      createdAt: widget.initialHabit?.createdAt ?? now,
    );

    if (widget.initialHabit != null) {
      ref.read(habitsProvider.notifier).updateHabit(habit);
    } else {
      ref.read(habitsProvider.notifier).createHabit(habit);
    }

    // Schedule or update associated reminder if requested
    if (_hasReminder) {
      NotificationService.instance.requestPermissions();
      final remDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        _reminderTime.hour,
        _reminderTime.minute,
      );
      final reminder = ReminderItem(
        id: 'rem_habit_$habitId',
        title: '⏰ Habit Alarm: ${habit.name}',
        description: 'Time to complete ${habit.dailyTarget} ${habit.unit ?? "times"} of ${habit.name}!',
        dateTime: remDateTime,
        repeat: ReminderRepeat.daily,
        isEnabled: true,
        associatedHabitId: habitId,
        customAudioPath: _customAudioPath,
        customAudioName: _customAudioName,
        notificationId: habitId.hashCode.abs().remainder(100000),
        createdAt: now,
      );
      ref.read(remindersProvider.notifier).createReminder(reminder);
    } else {
      final reminders = ref.read(remindersProvider);
      final existing =
          reminders.where((r) => r.associatedHabitId == habitId).toList();
      for (final r in existing) {
        ref.read(remindersProvider.notifier).deleteReminder(r.id);
      }
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.themeTokens;
    final isEditing = widget.initialHabit != null;
    final weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Dialog(
      backgroundColor: tokens.cardColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.cardRadius),
        side: BorderSide(color: tokens.borderColor, width: tokens.borderWidth),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
        child: Padding(
          padding: EdgeInsets.all(tokens.cardPadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(_selectedColorValue).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        IconData(_selectedIconCode,
                            fontFamily: 'MaterialIcons'),
                        color: Color(_selectedColorValue),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isEditing ? 'Edit Habit' : 'Create New Habit',
                        style: context.getTextStyle(
                          fontSize: 18,
                          fontWeight: tokens.headingWeight,
                          color: tokens.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: tokens.textSecondary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Form Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DayFlowTextField(
                          controller: _nameController,
                          labelText: 'Habit Name *',
                          hintText: 'e.g., 20 Pushups, Drink 2L Water...',
                          autofocus: !isEditing,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Please enter a habit name'
                              : null,
                        ),
                        const SizedBox(height: 14),

                        // Icon Selector
                        Text(
                          'Choose Icon',
                          style: context.getTextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: tokens.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _iconChoices.map((item) {
                              final IconData iconData = item['icon'];
                              final isSelected =
                                  _selectedIconCode == iconData.codePoint;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: InkWell(
                                  onTap: () => setState(() =>
                                      _selectedIconCode = iconData.codePoint),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Color(_selectedColorValue)
                                          : tokens.surface,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isSelected
                                            ? Color(_selectedColorValue)
                                            : tokens.borderColor,
                                      ),
                                    ),
                                    child: Icon(
                                      iconData,
                                      size: 20,
                                      color: isSelected
                                          ? Colors.white
                                          : tokens.textSecondary,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Color Selector
                        Text(
                          'Accent Color',
                          style: context.getTextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: tokens.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: _colorChoices.map((color) {
                            final isSelected =
                                _selectedColorValue == color.value;
                            return Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: InkWell(
                                onTap: () => setState(
                                    () => _selectedColorValue = color.value),
                                customBorder: const CircleBorder(),
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: isSelected
                                        ? Border.all(
                                            color: Colors.white, width: 2.5)
                                        : null,
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: color.withOpacity(0.5),
                                              blurRadius: 6,
                                            )
                                          ]
                                        : null,
                                  ),
                                  child: isSelected
                                      ? const Icon(Icons.check,
                                          size: 16, color: Colors.white)
                                      : null,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),

                        // Target and Unit
                        Row(
                          children: [
                            Expanded(
                              child: DayFlowTextField(
                                controller: _targetController,
                                labelText: 'Daily Goal Target',
                                hintText: '1, 20, 2000...',
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DayFlowTextField(
                                controller: _unitController,
                                labelText: 'Unit (Optional)',
                                hintText: 'reps, ml, pages, min',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Frequency
                        Text(
                          'Frequency Schedule',
                          style: context.getTextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: tokens.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            DayFlowChip(
                              label: 'Every Day',
                              isSelected: _frequency == HabitFrequency.daily,
                              onTap: () => setState(() {
                                _frequency = HabitFrequency.daily;
                                _targetDays = [1, 2, 3, 4, 5, 6, 7];
                              }),
                            ),
                            DayFlowChip(
                              label: 'Weekdays (Mon-Fri)',
                              isSelected: _frequency == HabitFrequency.weekdays,
                              onTap: () => setState(() {
                                _frequency = HabitFrequency.weekdays;
                                _targetDays = [1, 2, 3, 4, 5];
                              }),
                            ),
                            DayFlowChip(
                              label: 'Specific Days',
                              isSelected:
                                  _frequency == HabitFrequency.specificDays,
                              onTap: () => setState(
                                  () => _frequency = HabitFrequency.specificDays),
                            ),
                          ],
                        ),

                        if (_frequency == HabitFrequency.specificDays) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            children: List.generate(7, (index) {
                              final dayNum = index + 1;
                              final isSelected = _targetDays.contains(dayNum);
                              return DayFlowChip(
                                label: weekdayNames[index],
                                isSelected: isSelected,
                                onTap: () {
                                  setState(() {
                                    if (isSelected) {
                                      if (_targetDays.length > 1) {
                                        _targetDays.remove(dayNum);
                                      }
                                    } else {
                                      _targetDays.add(dayNum);
                                    }
                                  });
                                },
                              );
                            }),
                          ),
                        ],
                        const SizedBox(height: 16),

                        // Daily Reminder
                        Row(
                          children: [
                            Icon(Icons.alarm,
                                size: 18, color: tokens.textSecondary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Daily Alarm Reminder',
                                    style: context.getTextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: tokens.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Exact alarm notification (e.g. 9:00 AM pushups)',
                                    style: context.getTextStyle(
                                      fontSize: 11,
                                      color: tokens.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _hasReminder,
                              activeColor: Color(_selectedColorValue),
                              onChanged: (val) {
                                setState(() => _hasReminder = val);
                                if (val) {
                                  NotificationService.instance.requestPermissions();
                                }
                              },
                            ),
                          ],
                        ),

                        if (_hasReminder) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              DayFlowChip(
                                label: '9:00 AM (Morning)',
                                isSelected: _reminderTime.hour == 9 &&
                                    _reminderTime.minute == 0,
                                onTap: () => setState(() =>
                                    _reminderTime =
                                        const TimeOfDay(hour: 9, minute: 0)),
                              ),
                              DayFlowChip(
                                label: '1:00 PM (Afternoon)',
                                isSelected: _reminderTime.hour == 13 &&
                                    _reminderTime.minute == 0,
                                onTap: () => setState(() =>
                                    _reminderTime =
                                        const TimeOfDay(hour: 13, minute: 0)),
                              ),
                              DayFlowChip(
                                label: '6:00 PM (Evening)',
                                isSelected: _reminderTime.hour == 18 &&
                                    _reminderTime.minute == 0,
                                onTap: () => setState(() =>
                                    _reminderTime =
                                        const TimeOfDay(hour: 18, minute: 0)),
                              ),
                              DayFlowChip(
                                label: '9:00 PM (Night)',
                                isSelected: _reminderTime.hour == 21 &&
                                    _reminderTime.minute == 0,
                                onTap: () => setState(() =>
                                    _reminderTime =
                                        const TimeOfDay(hour: 21, minute: 0)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          InkWell(
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: _reminderTime,
                              );
                              if (picked != null) {
                                setState(() => _reminderTime = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: tokens.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: tokens.borderColor),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Custom Time',
                                    style: context.getTextStyle(
                                      fontSize: 13,
                                      color: tokens.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    _reminderTime.format(context),
                                    style: context.getTextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(_selectedColorValue),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Custom Alarm Sound
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: tokens.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _customAudioPath != null
                                    ? Color(_selectedColorValue).withOpacity(0.5)
                                    : tokens.borderColor,
                                width: _customAudioPath != null ? 1.5 : 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: (_customAudioPath != null
                                                ? Color(_selectedColorValue)
                                                : tokens.textSecondary)
                                            .withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        _customAudioPath != null
                                            ? Icons.music_note
                                            : Icons.notifications_active,
                                        color: _customAudioPath != null
                                            ? Color(_selectedColorValue)
                                            : tokens.textSecondary,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _customAudioName ??
                                                'Default Loud Habit Alarm',
                                            style: context.getTextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: tokens.textPrimary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            _customAudioPath != null
                                                ? 'Custom audio will ring at habit time'
                                                : 'Rings loud alarm when habit is due',
                                            style: context.getTextStyle(
                                              fontSize: 11,
                                              color: tokens.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (_customAudioPath != null) ...[
                                      IconButton(
                                        icon: Icon(
                                          _isPlayingAudio
                                              ? Icons.stop_circle
                                              : Icons.play_circle_fill,
                                          color: Color(_selectedColorValue),
                                          size: 26,
                                        ),
                                        tooltip: _isPlayingAudio
                                            ? 'Stop Preview'
                                            : 'Play Preview',
                                        onPressed: _toggleAudioPreview,
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.close,
                                            color: tokens.textSecondary,
                                            size: 20),
                                        tooltip: 'Remove Custom Sound',
                                        onPressed: _clearCustomAudio,
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 10),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.audio_file_outlined,
                                      size: 16),
                                  label: Text(
                                    _customAudioPath != null
                                        ? 'Change Device Audio (MP3/WAV)'
                                        : 'Select Custom Audio from Device',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor:
                                        Color(_selectedColorValue),
                                    side: BorderSide(
                                        color: Color(_selectedColorValue)
                                            .withOpacity(0.4)),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                  ),
                                  onPressed: _pickAudioFile,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (isEditing)
                      IconButton(
                        icon: Icon(Icons.delete_outline,
                            color: tokens.error, size: 22),
                        tooltip: 'Delete Habit',
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: tokens.cardColor,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(tokens.cardRadius),
                                side: BorderSide(color: tokens.borderColor),
                              ),
                              title: Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded,
                                      color: tokens.error),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Delete Habit?',
                                    style: ctx.getTextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: tokens.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              content: Text(
                                'Are you sure you want to delete "${widget.initialHabit!.name}"? This will cancel its reminders and clear completion records.',
                                style: ctx.getTextStyle(
                                  color: tokens.textSecondary,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: Text('Cancel',
                                      style: ctx.getTextStyle(
                                          color: tokens.textSecondary)),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  child: Text('Delete Habit',
                                      style: ctx.getTextStyle(
                                          color: tokens.error,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true && mounted) {
                            await ref
                                .read(habitsProvider.notifier)
                                .deleteHabit(widget.initialHabit!.id);
                            if (mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Habit "${widget.initialHabit!.name}" deleted.'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          }
                        },
                      )
                    else
                      const SizedBox.shrink(),
                    Row(
                      children: [
                        DayFlowButton(
                          label: 'Cancel',
                          variant: DayFlowButtonVariant.outline,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 10),
                        DayFlowButton(
                          label: isEditing ? 'Save Habit' : 'Create Habit',
                          icon: Icons.check,
                          variant: DayFlowButtonVariant.primary,
                          onPressed: _saveHabit,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
