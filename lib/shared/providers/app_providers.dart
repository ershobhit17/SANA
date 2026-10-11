import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/notification_service.dart';
import '../../models/task_model.dart';
import '../../models/reminder_model.dart';
import '../../models/diary_entry_model.dart';
import '../../models/habit_model.dart';
import '../../models/app_settings_model.dart';
import '../../models/study_note_model.dart';

// ================= TASKS NOTIFIER =================
class TasksNotifier extends Notifier<List<TaskItem>> {
  @override
  List<TaskItem> build() {
    loadTasks();
    return [];
  }

  Future<void> loadTasks() async {
    final list = await StorageService.instance.getAllTasks();
    state = list;
  }

  Future<void> createTask(TaskItem task) async {
    state = [task, ...state];
    await StorageService.instance.saveTask(task);
  }

  Future<void> updateTask(TaskItem updatedTask) async {
    state = [
      for (final t in state)
        if (t.id == updatedTask.id) updatedTask else t,
    ];
    await StorageService.instance.saveTask(updatedTask);
  }

  Future<void> deleteTask(String id) async {
    state = state.where((t) => t.id != id).toList();
    await StorageService.instance.deleteTask(id);
  }

  Future<void> toggleTaskCompletion(String id, [DateTime? forDate]) async {
    final taskIndex = state.indexWhere((t) => t.id == id);
    if (taskIndex == -1) return;

    final task = state[taskIndex];
    final checkDate = forDate ?? DateTime.now();
    final dateStr =
        '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';

    TaskItem updated;
    if (task.isRecurring) {
      final currentDates = List<String>.from(task.completedDates);
      if (currentDates.contains(dateStr)) {
        currentDates.remove(dateStr);
      } else {
        currentDates.add(dateStr);
      }
      updated = task.copyWith(
        completedDates: currentDates,
        updatedAt: DateTime.now(),
      );
    } else {
      final newStatus = !task.isCompleted;
      updated = task.copyWith(
        isCompleted: newStatus,
        completedAt: newStatus ? DateTime.now() : null,
        updatedAt: DateTime.now(),
      );
    }

    state = [
      for (int i = 0; i < state.length; i++)
        if (i == taskIndex) updated else state[i]
    ];
    await StorageService.instance.saveTask(updated);
  }

  Future<void> toggleSubtask(String taskId, String subtaskId) async {
    final taskIndex = state.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) return;

    final task = state[taskIndex];
    final updatedSubtasks = task.subtasks.map((st) {
      if (st.id == subtaskId) {
        return st.copyWith(isCompleted: !st.isCompleted);
      }
      return st;
    }).toList();

    final updated = task.copyWith(
      subtasks: updatedSubtasks,
      updatedAt: DateTime.now(),
    );

    state = [
      for (int i = 0; i < state.length; i++)
        if (i == taskIndex) updated else state[i]
    ];
    await StorageService.instance.saveTask(updated);
  }

  Future<void> rescheduleTask(
      String id, DateTime newDate, String? newTime) async {
    final taskIndex = state.indexWhere((t) => t.id == id);
    if (taskIndex == -1) return;

    final updated = state[taskIndex].copyWith(
      dueDate: newDate,
      dueTime: newTime,
      updatedAt: DateTime.now(),
    );

    state = [
      for (int i = 0; i < state.length; i++)
        if (i == taskIndex) updated else state[i]
    ];
    await StorageService.instance.saveTask(updated);
  }
}

final tasksProvider =
    NotifierProvider<TasksNotifier, List<TaskItem>>(TasksNotifier.new);

// ================= REMINDERS NOTIFIER =================
class RemindersNotifier extends Notifier<List<ReminderItem>> {
  @override
  List<ReminderItem> build() {
    loadReminders();
    return [];
  }

  Future<void> loadReminders() async {
    final list = await StorageService.instance.getAllReminders();
    state = list;
  }

  Future<void> createReminder(ReminderItem reminder) async {
    state = [...state, reminder];
    await StorageService.instance.saveReminder(reminder);
    if (reminder.isEnabled) {
      await NotificationService.instance
          .scheduleReminderNotification(reminder);
    }
  }

  Future<void> updateReminder(ReminderItem updated) async {
    state = [
      for (final r in state)
        if (r.id == updated.id) updated else r,
    ];
    await StorageService.instance.saveReminder(updated);
    await NotificationService.instance
        .cancelReminderNotification(updated.notificationId);
    if (updated.isEnabled) {
      await NotificationService.instance
          .scheduleReminderNotification(updated);
    }
  }

  Future<void> toggleReminder(String id) async {
    final idx = state.indexWhere((r) => r.id == id);
    if (idx == -1) return;

    final reminder = state[idx];
    final updated = reminder.copyWith(isEnabled: !reminder.isEnabled);

    state = [
      for (int i = 0; i < state.length; i++)
        if (i == idx) updated else state[i]
    ];
    await StorageService.instance.saveReminder(updated);

    if (updated.isEnabled) {
      await NotificationService.instance
          .scheduleReminderNotification(updated);
    } else {
      await NotificationService.instance
          .cancelReminderNotification(updated.notificationId);
    }
  }

  Future<void> deleteReminder(String id) async {
    final match = state.where((r) => r.id == id).toList();
    if (match.isNotEmpty) {
      await NotificationService.instance
          .cancelReminderNotification(match.first.notificationId);
    }
    state = state.where((r) => r.id != id).toList();
    await StorageService.instance.deleteReminder(id);
  }
}

final remindersProvider =
    NotifierProvider<RemindersNotifier, List<ReminderItem>>(
        RemindersNotifier.new);

// ================= HABITS & COMPLETIONS NOTIFIERS =================
class HabitsNotifier extends Notifier<List<HabitItem>> {
  @override
  List<HabitItem> build() {
    loadHabits();
    return [];
  }

  Future<void> loadHabits() async {
    final list = await StorageService.instance.getAllHabits();
    state = list;
  }

  Future<void> createHabit(HabitItem habit) async {
    state = [...state, habit];
    await StorageService.instance.saveHabit(habit);
  }

  Future<void> updateHabit(HabitItem updated) async {
    state = [
      for (final h in state)
        if (h.id == updated.id) updated else h,
    ];
    await StorageService.instance.saveHabit(updated);
  }

  Future<void> deleteHabit(String id) async {
    final habitMatch = state.where((h) => h.id == id).toList();
    final habit = habitMatch.isNotEmpty ? habitMatch.first : null;
    state = state.where((h) => h.id != id).toList();
    await StorageService.instance.deleteHabit(id);
    if (habit != null) {
      final allReminders = ref.read(remindersProvider);
      for (final r in allReminders) {
        if (r.title.toLowerCase().contains(habit.name.toLowerCase())) {
          await ref.read(remindersProvider.notifier).deleteReminder(r.id);
        }
      }
    }
    await ref.read(habitCompletionsProvider.notifier).loadCompletions();
  }
}

final habitsProvider =
    NotifierProvider<HabitsNotifier, List<HabitItem>>(HabitsNotifier.new);

class HabitCompletionsNotifier extends Notifier<List<HabitCompletion>> {
  @override
  List<HabitCompletion> build() {
    loadCompletions();
    return [];
  }

  Future<void> loadCompletions() async {
    final list = await StorageService.instance.getAllHabitCompletions();
    state = list;
  }

  Future<void> toggleHabitCompletion(
      String habitId, DateTime date, int target) async {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final existingIdx = state.indexWhere(
        (c) => c.habitId == habitId && c.dateStr == dateStr);

    if (existingIdx != -1) {
      final existing = state[existingIdx];
      if (existing.isCompleted) {
        // Toggle off
        final idToRemove = existing.id;
        state = state.where((c) => c.id != idToRemove).toList();
        await StorageService.instance.deleteHabitCompletion(idToRemove);
      } else {
        // Mark complete
        final updated = HabitCompletion(
          id: existing.id,
          habitId: habitId,
          dateStr: dateStr,
          progress: target,
          isCompleted: true,
          timestamp: DateTime.now(),
        );
        state = [
          for (int i = 0; i < state.length; i++)
            if (i == existingIdx) updated else state[i]
        ];
        await StorageService.instance.saveHabitCompletion(updated);
      }
    } else {
      // Create new completion
      final newComp = HabitCompletion(
        id: 'comp_${DateTime.now().millisecondsSinceEpoch}',
        habitId: habitId,
        dateStr: dateStr,
        progress: target,
        isCompleted: true,
        timestamp: DateTime.now(),
      );
      state = [...state, newComp];
      await StorageService.instance.saveHabitCompletion(newComp);
    }
  }

  Future<void> updateProgress(
      String habitId, DateTime date, int newProgress, int target) async {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final existingIdx = state.indexWhere(
        (c) => c.habitId == habitId && c.dateStr == dateStr);

    final isCompleted = newProgress >= target;
    if (existingIdx != -1) {
      final updated = HabitCompletion(
        id: state[existingIdx].id,
        habitId: habitId,
        dateStr: dateStr,
        progress: newProgress,
        isCompleted: isCompleted,
        timestamp: DateTime.now(),
      );
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == existingIdx) updated else state[i]
      ];
      await StorageService.instance.saveHabitCompletion(updated);
    } else {
      final newComp = HabitCompletion(
        id: 'comp_${DateTime.now().millisecondsSinceEpoch}',
        habitId: habitId,
        dateStr: dateStr,
        progress: newProgress,
        isCompleted: isCompleted,
        timestamp: DateTime.now(),
      );
      state = [...state, newComp];
      await StorageService.instance.saveHabitCompletion(newComp);
    }
  }
}

final habitCompletionsProvider =
    NotifierProvider<HabitCompletionsNotifier, List<HabitCompletion>>(
        HabitCompletionsNotifier.new);

// ================= DIARY NOTIFIER =================
class DiaryNotifier extends Notifier<List<DiaryEntry>> {
  @override
  List<DiaryEntry> build() {
    loadEntries();
    return [];
  }

  Future<void> loadEntries() async {
    final list = await StorageService.instance.getAllDiaryEntries();
    state = list;
  }

  Future<void> createEntry(DiaryEntry entry) async {
    state = [entry, ...state];
    await StorageService.instance.saveDiaryEntry(entry);
  }

  Future<void> updateEntry(DiaryEntry updated) async {
    state = [
      for (final e in state)
        if (e.id == updated.id) updated else e,
    ];
    await StorageService.instance.saveDiaryEntry(updated);
  }

  Future<void> deleteEntry(String id) async {
    state = state.where((e) => e.id != id).toList();
    await StorageService.instance.deleteDiaryEntry(id);
  }

  Future<void> toggleFavorite(String id) async {
    final idx = state.indexWhere((e) => e.id == id);
    if (idx == -1) return;

    final entry = state[idx];
    final updated = entry.copyWith(isFavorite: !entry.isFavorite);

    state = [
      for (int i = 0; i < state.length; i++)
        if (i == idx) updated else state[i]
    ];
    await StorageService.instance.saveDiaryEntry(updated);
  }
}

final diaryProvider =
    NotifierProvider<DiaryNotifier, List<DiaryEntry>>(DiaryNotifier.new);

// ================= SETTINGS NOTIFIER =================
class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    loadSettings();
    return const AppSettings();
  }

  Future<void> loadSettings() async {
    final s = await StorageService.instance.getAppSettings();
    state = s;
  }

  Future<void> updateSettings(AppSettings newSettings) async {
    state = newSettings;
    await StorageService.instance.saveAppSettings(newSettings);
  }

  Future<void> toggleAppLock(bool enabled, String? pin) async {
    final updated = state.copyWith(
      appLockEnabled: enabled,
      appLockPin: pin,
    );
    state = updated;
    await StorageService.instance.saveAppSettings(updated);
  }
}

final appSettingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

// ================= STUDY NOTES NOTIFIER =================
class NotesNotifier extends Notifier<List<StudyNoteItem>> {
  @override
  List<StudyNoteItem> build() {
    loadNotes();
    return [];
  }

  Future<void> loadNotes() async {
    final list = await StorageService.instance.getAllNotes();
    state = list;
  }

  Future<void> createNote(StudyNoteItem note) async {
    state = [note, ...state];
    await StorageService.instance.saveNote(note);
    await loadNotes();
  }

  Future<void> updateNote(StudyNoteItem updatedNote) async {
    state = [
      for (final n in state)
        if (n.id == updatedNote.id) updatedNote else n,
    ];
    await StorageService.instance.saveNote(updatedNote);
    await loadNotes();
  }

  Future<void> deleteNote(String id) async {
    state = state.where((n) => n.id != id).toList();
    await StorageService.instance.deleteNote(id);
  }

  Future<void> togglePin(String id) async {
    final index = state.indexWhere((n) => n.id == id);
    if (index == -1) return;
    final note = state[index];
    final updated = note.copyWith(
      isPinned: !note.isPinned,
      updatedAt: DateTime.now(),
    );
    await updateNote(updated);
  }
}

final notesProvider =
    NotifierProvider<NotesNotifier, List<StudyNoteItem>>(NotesNotifier.new);

// Helper for Habit Streak calculation
class HabitStreakInfo {
  final int currentStreak;
  final int longestStreak;
  final double completionRate;

  HabitStreakInfo({
    required this.currentStreak,
    required this.longestStreak,
    required this.completionRate,
  });
}

HabitStreakInfo calculateHabitStreak(
    HabitItem habit, List<HabitCompletion> completions) {
  final habitComps = completions
      .where((c) => c.habitId == habit.id && c.isCompleted)
      .toList();

  final Set<String> completedDateStrings =
      habitComps.map((c) => c.dateStr).toSet();

  int currentStreak = 0;
  int longestStreak = 0;
  int tempStreak = 0;

  final now = DateTime.now();

  var cursor = DateTime(now.year, now.month, now.day);
  final todayStr =
      '${cursor.year}-${cursor.month.toString().padLeft(2, '0')}-${cursor.day.toString().padLeft(2, '0')}';

  bool countingCurrent = true;
  if (!completedDateStrings.contains(todayStr)) {
    cursor = cursor.subtract(const Duration(days: 1));
  }

  for (int i = 0; i < 365; i++) {
    if (!habit.appliesToDate(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
      continue;
    }

    final dStr =
        '${cursor.year}-${cursor.month.toString().padLeft(2, '0')}-${cursor.day.toString().padLeft(2, '0')}';
    if (completedDateStrings.contains(dStr)) {
      if (countingCurrent) currentStreak++;
    } else {
      countingCurrent = false;
      break;
    }
    cursor = cursor.subtract(const Duration(days: 1));
  }

  var scanCursor = DateTime(now.year, now.month, now.day)
      .subtract(const Duration(days: 90));
  int scheduledCount = 0;
  int completedCount = 0;

  for (int i = 0; i <= 90; i++) {
    if (habit.appliesToDate(scanCursor)) {
      scheduledCount++;
      final sStr =
          '${scanCursor.year}-${scanCursor.month.toString().padLeft(2, '0')}-${scanCursor.day.toString().padLeft(2, '0')}';
      if (completedDateStrings.contains(sStr)) {
        completedCount++;
        tempStreak++;
        if (tempStreak > longestStreak) longestStreak = tempStreak;
      } else {
        tempStreak = 0;
      }
    }
    scanCursor = scanCursor.add(const Duration(days: 1));
  }

  if (currentStreak > longestStreak) longestStreak = currentStreak;

  final rate = scheduledCount > 0 ? (completedCount / scheduledCount) : 0.0;

  return HabitStreakInfo(
    currentStreak: currentStreak,
    longestStreak: longestStreak,
    completionRate: rate,
  );
}
