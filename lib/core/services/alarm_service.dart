import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../models/reminder_model.dart';
import '../../models/habit_model.dart';

class AlarmEvent {
  final String id;
  final String title;
  final String subtitle;
  final String? customAudioPath;
  final String? customAudioName;
  final bool isHabit;

  const AlarmEvent({
    required this.id,
    required this.title,
    required this.subtitle,
    this.customAudioPath,
    this.customAudioName,
    this.isHabit = false,
  });
}

class AlarmService {
  static final AlarmService instance = AlarmService._internal();
  AlarmService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _previewPlayer = AudioPlayer();

  bool _isRinging = false;
  bool get isRinging => _isRinging;

  AlarmEvent? _currentAlarm;
  AlarmEvent? get currentAlarm => _currentAlarm;

  Timer? _vibrationTimer;
  final Set<String> _triggeredIdsToday = {};

  final ValueNotifier<AlarmEvent?> activeAlarmNotifier = ValueNotifier<AlarmEvent?>(null);

  Future<void> init() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(1.0);
    } catch (e) {
      debugPrint('AlarmService init notice: $e');
    }
  }

  /// Preview custom device audio or preset for 4 seconds
  Future<void> previewAudio(String? audioPath) async {
    try {
      await _previewPlayer.stop();
      if (audioPath != null && audioPath.isNotEmpty && File(audioPath).existsSync()) {
        await _previewPlayer.play(DeviceFileSource(audioPath));
      } else {
        // Fallback gentle test chime via system sound
        SystemSound.play(SystemSoundType.alert);
      }
    } catch (e) {
      debugPrint('Error previewing audio: $e');
    }
  }

  Future<void> stopPreview() async {
    try {
      await _previewPlayer.stop();
    } catch (_) {}
  }

  Future<void> stopAudio() async {
    await stopPreview();
    await stopAlarm();
  }

  /// Start ringing alarm for habit or reminder
  Future<void> startAlarm(AlarmEvent event) async {
    if (_isRinging && _currentAlarm?.id == event.id) return;

    _isRinging = true;
    _currentAlarm = event;
    activeAlarmNotifier.value = event;

    try {
      // 1. Play audio loop
      if (event.customAudioPath != null &&
          event.customAudioPath!.isNotEmpty &&
          File(event.customAudioPath!).existsSync()) {
        await _audioPlayer.setReleaseMode(ReleaseMode.loop);
        await _audioPlayer.play(DeviceFileSource(event.customAudioPath!));
      } else {
        // If no custom audio file is picked, repeat system notification sound
        SystemSound.play(SystemSoundType.alert);
      }

      // 2. Start repeating haptic vibration
      _vibrationTimer?.cancel();
      _vibrationTimer = Timer.periodic(const Duration(milliseconds: 1200), (_) {
        HapticFeedback.heavyImpact();
        if (event.customAudioPath == null || !File(event.customAudioPath!).existsSync()) {
          SystemSound.play(SystemSoundType.alert);
        }
      });
    } catch (e) {
      debugPrint('Error starting alarm: $e');
    }
  }

  /// Dismiss / turn off ringing alarm
  Future<void> stopAlarm() async {
    _isRinging = false;
    _currentAlarm = null;
    activeAlarmNotifier.value = null;

    _vibrationTimer?.cancel();
    _vibrationTimer = null;

    try {
      await _audioPlayer.stop();
    } catch (e) {
      debugPrint('Error stopping alarm: $e');
    }
  }

  /// Snooze alarm for 5 minutes
  Future<void> snoozeAlarm(Duration duration) async {
    final event = _currentAlarm;
    await stopAlarm();
    if (event != null) {
      Timer(duration, () {
        startAlarm(event);
      });
    }
  }

  /// Check scheduled habits and reminders against current device time
  void checkAlarms({
    required List<ReminderItem> reminders,
    required List<HabitItem> habits,
  }) {
    if (_isRinging) return;

    final now = DateTime.now();
    final todayPrefix = '${now.year}-${now.month}-${now.day}';

    // 1. Check Reminders
    for (final rem in reminders) {
      if (!rem.isEnabled) continue;

      final remTime = rem.dateTime;
      final isSameDate = remTime.year == now.year &&
          remTime.month == now.month &&
          remTime.day == now.day;

      final isDueNow = isSameDate &&
          remTime.hour == now.hour &&
          remTime.minute == now.minute;

      final triggerKey = '$todayPrefix-rem-${rem.id}-${now.hour}:${now.minute}';
      if (isDueNow && !_triggeredIdsToday.contains(triggerKey)) {
        _triggeredIdsToday.add(triggerKey);
        startAlarm(
          AlarmEvent(
            id: rem.id,
            title: rem.title,
            subtitle: rem.description ?? 'Scheduled Reminder Alarm',
            customAudioPath: rem.customAudioPath,
            customAudioName: rem.customAudioName,
            isHabit: false,
          ),
        );
        return;
      }
    }

    // 2. Check Habits with Reminders
    for (final habit in habits) {
      if (!habit.hasReminder || habit.reminderTime == null) continue;

      try {
        final parts = habit.reminderTime!.split(' ');
        final hm = parts[0].split(':');
        int h = int.parse(hm[0]);
        final m = int.parse(hm[1]);
        if (parts.length > 1 && parts[1].toUpperCase() == 'PM' && h < 12) {
          h += 12;
        } else if (parts.length > 1 && parts[1].toUpperCase() == 'AM' && h == 12) {
          h = 0;
        }

        if (h == now.hour && m == now.minute && habit.appliesToDate(now)) {
          final triggerKey = '$todayPrefix-habit-${habit.id}-$h:$m';
          if (!_triggeredIdsToday.contains(triggerKey)) {
            _triggeredIdsToday.add(triggerKey);
            startAlarm(
              AlarmEvent(
                id: habit.id,
                title: 'Habit Alarm: ${habit.name}',
                subtitle: 'Time to complete ${habit.name}!',
                customAudioPath: habit.customAudioPath,
                customAudioName: habit.customAudioName,
                isHabit: true,
              ),
            );
            return;
          }
        }
      } catch (_) {}
    }
  }
}
