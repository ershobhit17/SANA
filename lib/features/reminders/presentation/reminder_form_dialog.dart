import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/alarm_service.dart';
import '../../../core/theme/dayflow_theme_context.dart';
import '../../../models/reminder_model.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/dayflow_button.dart';
import '../../../shared/widgets/dayflow_chip.dart';
import '../../../shared/widgets/dayflow_text_field.dart';

class ReminderFormDialog extends ConsumerStatefulWidget {
  final ReminderItem? initialReminder;
  final DateTime? defaultDateTime;

  const ReminderFormDialog({
    super.key,
    this.initialReminder,
    this.defaultDateTime,
  });

  @override
  ConsumerState<ReminderFormDialog> createState() => _ReminderFormDialogState();
}

class _ReminderFormDialogState extends ConsumerState<ReminderFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  ReminderRepeat _repeat = ReminderRepeat.none;
  List<int> _repeatDays = [1, 2, 3, 4, 5]; // Mon-Fri
  String? _customAudioPath;
  String? _customAudioName;
  bool _isPlayingAudio = false;

  @override
  void initState() {
    super.initState();
    final rem = widget.initialReminder;
    _titleController = TextEditingController(text: rem?.title ?? '');
    _descController = TextEditingController(text: rem?.description ?? '');

    if (rem != null) {
      _selectedDate = rem.dateTime;
      _selectedTime =
          TimeOfDay(hour: rem.dateTime.hour, minute: rem.dateTime.minute);
      _repeat = rem.repeat;
      _repeatDays = rem.repeatDays ?? [1, 2, 3, 4, 5];
      _customAudioPath = rem.customAudioPath;
      _customAudioName = rem.customAudioName;
    } else {
      final base = widget.defaultDateTime ??
          DateTime.now().add(const Duration(minutes: 30));
      _selectedDate = base;
      _selectedTime = TimeOfDay(hour: base.hour, minute: base.minute);
    }
  }

  @override
  void dispose() {
    if (_isPlayingAudio) {
      AlarmService.instance.stopAudio();
    }
    _titleController.dispose();
    _descController.dispose();
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _saveReminder() {
    if (!_formKey.currentState!.validate()) return;

    final combinedDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final notificationId = widget.initialReminder?.notificationId ??
        (DateTime.now().millisecondsSinceEpoch ~/ 1000).remainder(100000);

    if (widget.initialReminder != null) {
      final updated = widget.initialReminder!.copyWith(
        title: _titleController.text.trim(),
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        dateTime: combinedDateTime,
        repeat: _repeat,
        repeatDays:
            _repeat == ReminderRepeat.custom ? _repeatDays : null,
        customAudioPath: _customAudioPath,
        customAudioName: _customAudioName,
      );
      ref.read(remindersProvider.notifier).updateReminder(updated);
    } else {
      final newRem = ReminderItem(
        id: const Uuid().v4(),
        title: _titleController.text.trim(),
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        dateTime: combinedDateTime,
        repeat: _repeat,
        repeatDays:
            _repeat == ReminderRepeat.custom ? _repeatDays : null,
        isEnabled: true,
        customAudioPath: _customAudioPath,
        customAudioName: _customAudioName,
        notificationId: notificationId,
        createdAt: DateTime.now(),
      );
      ref.read(remindersProvider.notifier).createReminder(newRem);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.themeTokens;
    final isEditing = widget.initialReminder != null;
    final weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Dialog(
      backgroundColor: tokens.cardColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.cardRadius),
        side: BorderSide(color: tokens.borderColor, width: tokens.borderWidth),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
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
                        color: tokens.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isEditing
                            ? Icons.notification_important
                            : Icons.add_alert,
                        color: tokens.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isEditing ? 'Edit Reminder' : 'Set New Reminder',
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
                          controller: _titleController,
                          labelText: 'Reminder Title *',
                          hintText: 'e.g., Do 20 pushups, Call dentist...',
                          autofocus: !isEditing,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Please enter a reminder title'
                              : null,
                        ),
                        const SizedBox(height: 14),

                        DayFlowTextField(
                          controller: _descController,
                          labelText: 'Notes (Optional)',
                          hintText: 'Additional details or instructions...',
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),

                        // Date & Time Buttons
                        Text(
                          'Schedule Date & Time',
                          style: context.getTextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: tokens.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: _pickDate,
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: tokens.surface,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: tokens.borderColor),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.calendar_today,
                                          size: 16, color: tokens.primary),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          DateFormat('EEE, MMM d')
                                              .format(_selectedDate),
                                          style: context.getTextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: tokens.textPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: InkWell(
                                onTap: _pickTime,
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: tokens.surface,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: tokens.borderColor),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.access_time,
                                          size: 16, color: tokens.primary),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _selectedTime.format(context),
                                          style: context.getTextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: tokens.textPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Repeat Selector
                        Text(
                          'Repeat Frequency',
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
                              label: 'Does not repeat',
                              isSelected: _repeat == ReminderRepeat.none,
                              onTap: () => setState(
                                  () => _repeat = ReminderRepeat.none),
                            ),
                            DayFlowChip(
                              label: 'Daily',
                              isSelected: _repeat == ReminderRepeat.daily,
                              onTap: () => setState(
                                  () => _repeat = ReminderRepeat.daily),
                            ),
                            DayFlowChip(
                              label: 'Weekly',
                              isSelected: _repeat == ReminderRepeat.weekly,
                              onTap: () => setState(
                                  () => _repeat = ReminderRepeat.weekly),
                            ),
                            DayFlowChip(
                              label: 'Weekdays (Mon-Fri)',
                              isSelected: _repeat == ReminderRepeat.weekdays,
                              onTap: () => setState(
                                  () => _repeat = ReminderRepeat.weekdays),
                            ),
                            DayFlowChip(
                              label: 'Custom Days',
                              isSelected: _repeat == ReminderRepeat.custom,
                              onTap: () => setState(
                                  () => _repeat = ReminderRepeat.custom),
                            ),
                          ],
                        ),

                        if (_repeat == ReminderRepeat.custom) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            children: List.generate(7, (index) {
                              final dayNum = index + 1;
                              final isSelected = _repeatDays.contains(dayNum);
                              return DayFlowChip(
                                label: weekdayNames[index],
                                isSelected: isSelected,
                                onTap: () {
                                  setState(() {
                                    if (isSelected) {
                                      _repeatDays.remove(dayNum);
                                    } else {
                                      _repeatDays.add(dayNum);
                                    }
                                  });
                                },
                              );
                            }),
                          ),
                        ],
                        const SizedBox(height: 16),

                        // Custom Alarm Sound Section
                        Text(
                          'Alarm Ringtone / Sound 🎵',
                          style: context.getTextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: tokens.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: tokens.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _customAudioPath != null
                                  ? tokens.primary.withOpacity(0.5)
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
                                              ? tokens.primary
                                              : tokens.textSecondary)
                                          .withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      _customAudioPath != null
                                          ? Icons.music_note
                                          : Icons.notifications_active,
                                      color: _customAudioPath != null
                                          ? tokens.primary
                                          : tokens.textSecondary,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _customAudioName ??
                                              'Default System Loud Alarm',
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
                                              ? 'Device audio file configured'
                                              : 'Rings persistent alarm at scheduled time',
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
                                        color: tokens.primary,
                                        size: 26,
                                      ),
                                      tooltip: _isPlayingAudio
                                          ? 'Stop Preview'
                                          : 'Play Preview',
                                      onPressed: _toggleAudioPreview,
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.close,
                                          color: tokens.textSecondary, size: 20),
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
                                      : 'Choose Custom Audio from Device (MP3/WAV)',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: tokens.primary,
                                  side: BorderSide(
                                      color: tokens.primary.withOpacity(0.4)),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                                onPressed: _pickAudioFile,
                              ),
                            ],
                          ),
                        ),
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
                        tooltip: 'Delete Reminder',
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
                                    'Delete Reminder?',
                                    style: ctx.getTextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: tokens.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              content: Text(
                                'Are you sure you want to delete "${widget.initialReminder!.title}"? This will cancel its scheduled device notification.',
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
                                  child: Text('Delete Reminder',
                                      style: ctx.getTextStyle(
                                          color: tokens.error,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true && mounted) {
                            await ref
                                .read(remindersProvider.notifier)
                                .deleteReminder(widget.initialReminder!.id);
                            if (mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Reminder "${widget.initialReminder!.title}" deleted.'),
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
                          label: isEditing ? 'Save Reminder' : 'Set Reminder',
                          icon: Icons.check,
                          variant: DayFlowButtonVariant.primary,
                          onPressed: _saveReminder,
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
