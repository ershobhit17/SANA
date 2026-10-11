import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../models/task_model.dart';
import '../../models/reminder_model.dart';
import '../../models/diary_entry_model.dart';
import '../../models/habit_model.dart';
import '../../models/app_settings_model.dart';
import '../../models/study_note_model.dart';

class StorageService {
  static final StorageService instance = StorageService._internal();
  StorageService._internal();

  sqflite.Database? _db;
  bool _usePreferencesFallback = false;

  // Fallback in-memory stores for web/unsupported environments
  final Map<String, TaskItem> _memTasks = {};
  final Map<String, ReminderItem> _memReminders = {};
  final Map<String, DiaryEntry> _memEntries = {};
  final Map<String, HabitItem> _memHabits = {};
  final Map<String, HabitCompletion> _memCompletions = {};
  final Map<String, StudyNoteItem> _memNotes = {};
  AppSettings _memSettings = const AppSettings();

  static const _prefTasksKey = 'dayflow_store_tasks_v1';
  static const _prefRemindersKey = 'dayflow_store_reminders_v1';
  static const _prefEntriesKey = 'dayflow_store_entries_v1';
  static const _prefHabitsKey = 'dayflow_store_habits_v1';
  static const _prefCompletionsKey = 'dayflow_store_completions_v1';
  static const _prefNotesKey = 'dayflow_store_notes_v1';
  static const _prefSettingsKey = 'dayflow_store_settings_v1';

  Future<void> init() async {
    if (kIsWeb) {
      _usePreferencesFallback = true;
      await _loadFromPreferencesFallback();
      _seedDefaultDataIfEmpty();
      return;
    }

    try {
      // For desktop (Windows/Linux/macOS), initialize FFI
      if (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        sqfliteFfiInit();
        sqflite.databaseFactory = databaseFactoryFfi;
      }

      final docDir = await getApplicationDocumentsDirectory();
      final dbPath = p.join(docDir.path, 'dayflow_database_v1.db');

      _db = await sqflite.openDatabase(
        dbPath,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE tasks (
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              description TEXT,
              dueDate TEXT,
              dueTime TEXT,
              priority INTEGER NOT NULL,
              category TEXT NOT NULL,
              isCompleted INTEGER NOT NULL,
              completedAt TEXT,
              recurrence INTEGER NOT NULL,
              recurringDays TEXT,
              subtasks TEXT,
              completedDates TEXT,
              createdAt TEXT NOT NULL,
              updatedAt TEXT NOT NULL
            )
          ''');

          await db.execute('''
            CREATE TABLE reminders (
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              description TEXT,
              dateTime TEXT NOT NULL,
              repeat INTEGER NOT NULL,
              repeatDays TEXT,
              isEnabled INTEGER NOT NULL,
              notificationId INTEGER NOT NULL,
              associatedTaskId TEXT,
              associatedHabitId TEXT,
              customAudioPath TEXT,
              customAudioName TEXT,
              createdAt TEXT NOT NULL
            )
          ''');

          await db.execute('''
            CREATE TABLE diary_entries (
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              content TEXT NOT NULL,
              entryDate TEXT NOT NULL,
              tags TEXT,
              imagePaths TEXT,
              mood TEXT NOT NULL,
              isFavorite INTEGER NOT NULL,
              createdAt TEXT NOT NULL,
              updatedAt TEXT NOT NULL
            )
          ''');

          await db.execute('''
            CREATE TABLE habits (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              iconCodePoint INTEGER NOT NULL,
              colorValue INTEGER NOT NULL,
              frequency INTEGER NOT NULL,
              targetDays TEXT NOT NULL,
              dailyTarget INTEGER NOT NULL,
              unit TEXT,
              hasReminder INTEGER NOT NULL,
              reminderTime TEXT,
              customAudioPath TEXT,
              customAudioName TEXT,
              createdAt TEXT NOT NULL
            )
          ''');

          await db.execute('''
            CREATE TABLE habit_completions (
              id TEXT PRIMARY KEY,
              habitId TEXT NOT NULL,
              dateStr TEXT NOT NULL,
              progress INTEGER NOT NULL,
              isCompleted INTEGER NOT NULL,
              timestamp TEXT NOT NULL
            )
          ''');

          await db.execute('''
            CREATE TABLE app_settings (
              id TEXT PRIMARY KEY,
              settingsJson TEXT NOT NULL
            )
          ''');

          await db.execute('''
            CREATE TABLE study_notes (
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              content TEXT NOT NULL,
              category TEXT NOT NULL,
              tags TEXT,
              links TEXT,
              isPinned INTEGER NOT NULL,
              colorValue INTEGER,
              createdAt TEXT NOT NULL,
              updatedAt TEXT NOT NULL
            )
          ''');

          await db.execute('''
            CREATE TABLE theme_settings (
              id TEXT PRIMARY KEY,
              activeThemeId TEXT NOT NULL,
              activeThemeJson TEXT NOT NULL,
              customThemesJson TEXT,
              modeIndex INTEGER NOT NULL
            )
          ''');
        },
      );

      // Migrations for existing SQLite database
      try {
        await _db!.execute('ALTER TABLE diary_entries ADD COLUMN imagePaths TEXT');
      } catch (_) {}
      try {
        await _db!.execute('ALTER TABLE reminders ADD COLUMN customAudioPath TEXT');
      } catch (_) {}
      try {
        await _db!.execute('ALTER TABLE reminders ADD COLUMN customAudioName TEXT');
      } catch (_) {}
      try {
        await _db!.execute('ALTER TABLE habits ADD COLUMN customAudioPath TEXT');
      } catch (_) {}
      try {
        await _db!.execute('ALTER TABLE habits ADD COLUMN customAudioName TEXT');
      } catch (_) {}
      try {
        await _db!.execute('''
          CREATE TABLE IF NOT EXISTS study_notes (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            category TEXT NOT NULL,
            tags TEXT,
            links TEXT,
            isPinned INTEGER NOT NULL,
            colorValue INTEGER,
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL
          )
        ''');
      } catch (_) {}
      try {
        await _db!.execute('''
          CREATE TABLE IF NOT EXISTS theme_settings (
            id TEXT PRIMARY KEY,
            activeThemeId TEXT NOT NULL,
            activeThemeJson TEXT NOT NULL,
            customThemesJson TEXT,
            modeIndex INTEGER NOT NULL
          )
        ''');
      } catch (_) {}

      // Check if data is empty to seed initial sample items
      final countResult = await _db!.rawQuery('SELECT COUNT(*) as c FROM tasks');
      final taskCount = sqflite.Sqflite.firstIntValue(countResult) ?? 0;
      if (taskCount == 0) {
        await _seedDefaultDataToSqlite();
      }
    } catch (e) {
      debugPrint('SQLite init error ($e). Falling back to preferences storage.');
      _usePreferencesFallback = true;
      await _loadFromPreferencesFallback();
      _seedDefaultDataIfEmpty();
    }
  }

  Future<void> _loadFromPreferencesFallback() async {
    final prefs = await SharedPreferences.getInstance();

    final tasksRaw = prefs.getStringList(_prefTasksKey) ?? [];
    for (final s in tasksRaw) {
      try {
        final item = TaskItem.fromMap(jsonDecode(s) as Map<String, dynamic>);
        _memTasks[item.id] = item;
      } catch (_) {}
    }

    final remindersRaw = prefs.getStringList(_prefRemindersKey) ?? [];
    for (final s in remindersRaw) {
      try {
        final item = ReminderItem.fromMap(jsonDecode(s) as Map<String, dynamic>);
        _memReminders[item.id] = item;
      } catch (_) {}
    }

    final entriesRaw = prefs.getStringList(_prefEntriesKey) ?? [];
    for (final s in entriesRaw) {
      try {
        final item = DiaryEntry.fromMap(jsonDecode(s) as Map<String, dynamic>);
        _memEntries[item.id] = item;
      } catch (_) {}
    }

    final habitsRaw = prefs.getStringList(_prefHabitsKey) ?? [];
    for (final s in habitsRaw) {
      try {
        final item = HabitItem.fromMap(jsonDecode(s) as Map<String, dynamic>);
        _memHabits[item.id] = item;
      } catch (_) {}
    }

    final compRaw = prefs.getStringList(_prefCompletionsKey) ?? [];
    for (final s in compRaw) {
      try {
        final item = HabitCompletion.fromMap(jsonDecode(s) as Map<String, dynamic>);
        _memCompletions[item.id] = item;
      } catch (_) {}
    }

    final notesRaw = prefs.getStringList(_prefNotesKey) ?? [];
    for (final s in notesRaw) {
      try {
        final item = StudyNoteItem.fromMap(jsonDecode(s) as Map<String, dynamic>);
        _memNotes[item.id] = item;
      } catch (_) {}
    }

    final setRaw = prefs.getString(_prefSettingsKey);
    if (setRaw != null) {
      try {
        _memSettings = AppSettings.fromMap(jsonDecode(setRaw) as Map<String, dynamic>);
      } catch (_) {}
    }
  }

  Future<void> _savePreferencesFallback() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _prefTasksKey, _memTasks.values.map((t) => jsonEncode(t.toMap())).toList());
    await prefs.setStringList(_prefRemindersKey,
        _memReminders.values.map((r) => jsonEncode(r.toMap())).toList());
    await prefs.setStringList(_prefEntriesKey,
        _memEntries.values.map((e) => jsonEncode(e.toMap())).toList());
    await prefs.setStringList(
        _prefHabitsKey, _memHabits.values.map((h) => jsonEncode(h.toMap())).toList());
    await prefs.setStringList(_prefCompletionsKey,
        _memCompletions.values.map((c) => jsonEncode(c.toMap())).toList());
    await prefs.setStringList(_prefNotesKey,
        _memNotes.values.map((n) => jsonEncode(n.toMap())).toList());
    await prefs.setString(_prefSettingsKey, jsonEncode(_memSettings.toMap()));
  }

  void _seedDefaultDataIfEmpty() {
    if (_memTasks.isNotEmpty || _memHabits.isNotEmpty) return;
    final now = DateTime.now();

    final task1 = TaskItem(
      id: 'task_seed_1',
      title: 'Review weekly productivity goals',
      description: 'Check progress on DayFlow tasks and plan upcoming schedule.',
      dueDate: DateTime(now.year, now.month, now.day),
      dueTime: '10:00 AM',
      priority: TaskPriority.high,
      category: 'Work',
      isCompleted: false,
      subtasks: const [
        Subtask(id: 's1', title: 'Prioritize top 3 tasks', isCompleted: true),
        Subtask(id: 's2', title: 'Schedule reminder for team catch-up', isCompleted: false),
      ],
      createdAt: now.subtract(const Duration(hours: 2)),
      updatedAt: now,
    );

    final task2 = TaskItem(
      id: 'task_seed_2',
      title: 'Morning workout session',
      description: 'Core exercises, stretching and quick cardio.',
      dueDate: DateTime(now.year, now.month, now.day),
      dueTime: '07:30 AM',
      priority: TaskPriority.medium,
      category: 'Health',
      isCompleted: true,
      completedAt: now.subtract(const Duration(hours: 3)),
      createdAt: now.subtract(const Duration(hours: 4)),
      updatedAt: now,
    );

    final task3 = TaskItem(
      id: 'task_seed_3',
      title: 'Read chapter 4 of Clean Architecture',
      description: 'Take notes in DayFlow Journal.',
      dueDate: DateTime(now.year, now.month, now.day),
      dueTime: '08:00 PM',
      priority: TaskPriority.low,
      category: 'Learning',
      isCompleted: false,
      recurrence: TaskRecurrence.daily,
      createdAt: now.subtract(const Duration(days: 1)),
      updatedAt: now,
    );

    _memTasks[task1.id] = task1;
    _memTasks[task2.id] = task2;
    _memTasks[task3.id] = task3;

    final habit1 = HabitItem(
      id: 'habit_seed_1',
      name: '20 Pushups',
      iconCodePoint: 0xe25a, // fitness_center
      colorValue: 0xFF10B981,
      dailyTarget: 20,
      unit: 'reps',
      createdAt: now.subtract(const Duration(days: 5)),
    );

    final habit2 = HabitItem(
      id: 'habit_seed_2',
      name: 'Drink 2L Water',
      iconCodePoint: 0xe3e0, // local_drink
      colorValue: 0xFF06B6D4,
      dailyTarget: 2000,
      unit: 'ml',
      createdAt: now.subtract(const Duration(days: 4)),
    );

    final habit3 = HabitItem(
      id: 'habit_seed_3',
      name: 'Evening Journaling',
      iconCodePoint: 0xe108, // book / edit
      colorValue: 0xFF8B5CF6,
      dailyTarget: 1,
      unit: 'entry',
      createdAt: now.subtract(const Duration(days: 3)),
    );

    _memHabits[habit1.id] = habit1;
    _memHabits[habit2.id] = habit2;
    _memHabits[habit3.id] = habit3;

    // Seed completion for today
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final comp1 = HabitCompletion(
      id: 'comp_1',
      habitId: habit1.id,
      dateStr: todayStr,
      progress: 20,
      isCompleted: true,
      timestamp: now.subtract(const Duration(hours: 3)),
    );
    _memCompletions[comp1.id] = comp1;

    final entry1 = DiaryEntry(
      id: 'entry_seed_1',
      title: 'Welcome to DayFlow',
      content:
          'Today starts a new journey with DayFlow. Organizing tasks, creating intentional habits, and writing daily thoughts in one unified place. The interface feels tactile and calm.',
      entryDate: now,
      tags: const ['welcome', 'focus', 'clarity'],
      mood: 'Great',
      isFavorite: true,
      createdAt: now.subtract(const Duration(hours: 1)),
      updatedAt: now,
    );
    _memEntries[entry1.id] = entry1;

    final rem1 = ReminderItem(
      id: 'rem_seed_1',
      title: 'Review today\'s accomplishments',
      description: 'Wind down and check completed habits.',
      dateTime: DateTime(now.year, now.month, now.day, 21, 0),
      repeat: ReminderRepeat.daily,
      isEnabled: true,
      notificationId: 101,
      createdAt: now,
    );
    _memReminders[rem1.id] = rem1;

    final note1 = StudyNoteItem(
      id: 'note_seed_1',
      title: 'DSA & Coding Interview Roadmap',
      content: 'Essential study links and topic roadmap for Data Structures & Algorithms. Revise arrays, trees, and dynamic programming patterns.',
      category: 'Computer Science',
      tags: const ['DSA', 'LeetCode', 'Interview'],
      isPinned: true,
      links: const [
        StudyNoteLink(
          id: 'link_1',
          url: 'https://leetcode.com/problemset/all/',
          label: 'Practice Problems & Daily Challenge',
          category: 'Practice',
        ),
        StudyNoteLink(
          id: 'link_2',
          url: 'https://github.com',
          label: 'Project Repositories & Implementation Code',
          category: 'Repo',
        ),
      ],
      createdAt: now.subtract(const Duration(hours: 1)),
      updatedAt: now,
    );
    _memNotes[note1.id] = note1;

    _savePreferencesFallback();
  }

  Future<void> _seedDefaultDataToSqlite() async {
    final now = DateTime.now();

    final task1 = TaskItem(
      id: 'task_seed_1',
      title: 'Review weekly productivity goals',
      description: 'Check progress on DayFlow tasks and plan upcoming schedule.',
      dueDate: DateTime(now.year, now.month, now.day),
      dueTime: '10:00 AM',
      priority: TaskPriority.high,
      category: 'Work',
      isCompleted: false,
      subtasks: const [
        Subtask(id: 's1', title: 'Prioritize top 3 tasks', isCompleted: true),
        Subtask(id: 's2', title: 'Schedule reminder for team catch-up', isCompleted: false),
      ],
      createdAt: now.subtract(const Duration(hours: 2)),
      updatedAt: now,
    );

    final task2 = TaskItem(
      id: 'task_seed_2',
      title: 'Morning workout session',
      description: 'Core exercises, stretching and quick cardio.',
      dueDate: DateTime(now.year, now.month, now.day),
      dueTime: '07:30 AM',
      priority: TaskPriority.medium,
      category: 'Health',
      isCompleted: true,
      completedAt: now.subtract(const Duration(hours: 3)),
      createdAt: now.subtract(const Duration(hours: 4)),
      updatedAt: now,
    );

    final task3 = TaskItem(
      id: 'task_seed_3',
      title: 'Read chapter 4 of Clean Architecture',
      description: 'Take notes in DayFlow Journal.',
      dueDate: DateTime(now.year, now.month, now.day),
      dueTime: '08:00 PM',
      priority: TaskPriority.low,
      category: 'Learning',
      isCompleted: false,
      recurrence: TaskRecurrence.daily,
      createdAt: now.subtract(const Duration(days: 1)),
      updatedAt: now,
    );

    await _db!.insert('tasks', task1.toMap());
    await _db!.insert('tasks', task2.toMap());
    await _db!.insert('tasks', task3.toMap());

    final habit1 = HabitItem(
      id: 'habit_seed_1',
      name: '20 Pushups',
      iconCodePoint: 0xe25a,
      colorValue: 0xFF10B981,
      dailyTarget: 20,
      unit: 'reps',
      createdAt: now.subtract(const Duration(days: 5)),
    );

    final habit2 = HabitItem(
      id: 'habit_seed_2',
      name: 'Drink 2L Water',
      iconCodePoint: 0xe3e0,
      colorValue: 0xFF06B6D4,
      dailyTarget: 2000,
      unit: 'ml',
      createdAt: now.subtract(const Duration(days: 4)),
    );

    final habit3 = HabitItem(
      id: 'habit_seed_3',
      name: 'Evening Journaling',
      iconCodePoint: 0xe108,
      colorValue: 0xFF8B5CF6,
      dailyTarget: 1,
      unit: 'entry',
      createdAt: now.subtract(const Duration(days: 3)),
    );

    await _db!.insert('habits', habit1.toMap());
    await _db!.insert('habits', habit2.toMap());
    await _db!.insert('habits', habit3.toMap());

    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final comp1 = HabitCompletion(
      id: 'comp_1',
      habitId: habit1.id,
      dateStr: todayStr,
      progress: 20,
      isCompleted: true,
      timestamp: now.subtract(const Duration(hours: 3)),
    );
    await _db!.insert('habit_completions', comp1.toMap());

    final entry1 = DiaryEntry(
      id: 'entry_seed_1',
      title: 'Welcome to DayFlow',
      content:
          'Today starts a new journey with DayFlow. Organizing tasks, creating intentional habits, and writing daily thoughts in one unified place. The interface feels tactile and calm.',
      entryDate: now,
      tags: const ['welcome', 'focus', 'clarity'],
      mood: 'Great',
      isFavorite: true,
      createdAt: now.subtract(const Duration(hours: 1)),
      updatedAt: now,
    );
    await _db!.insert('diary_entries', entry1.toMap());

    final rem1 = ReminderItem(
      id: 'rem_seed_1',
      title: 'Review today\'s accomplishments',
      description: 'Wind down and check completed habits.',
      dateTime: DateTime(now.year, now.month, now.day, 21, 0),
      repeat: ReminderRepeat.daily,
      isEnabled: true,
      notificationId: 101,
      createdAt: now,
    );
    await _db!.insert('reminders', rem1.toMap());

    final note1 = StudyNoteItem(
      id: 'note_seed_1',
      title: 'DSA & Coding Interview Roadmap',
      content: 'Essential study links and topic roadmap for Data Structures & Algorithms. Revise arrays, trees, and dynamic programming patterns.',
      category: 'Computer Science',
      tags: const ['DSA', 'LeetCode', 'Interview'],
      isPinned: true,
      links: const [
        StudyNoteLink(
          id: 'link_1',
          url: 'https://leetcode.com/problemset/all/',
          label: 'Practice Problems & Daily Challenge',
          category: 'Practice',
        ),
        StudyNoteLink(
          id: 'link_2',
          url: 'https://github.com',
          label: 'Project Repositories & Implementation Code',
          category: 'Repo',
        ),
      ],
      createdAt: now.subtract(const Duration(hours: 1)),
      updatedAt: now,
    );
    await _db!.insert('study_notes', note1.toMap());
  }

  // ================= TASKS CRUD =================
  Future<List<TaskItem>> getAllTasks() async {
    if (_usePreferencesFallback || _db == null) {
      return _memTasks.values.toList();
    }
    final maps = await _db!.query('tasks', orderBy: 'createdAt DESC');
    return maps.map((m) => TaskItem.fromMap(m)).toList();
  }

  Future<void> saveTask(TaskItem task) async {
    if (_usePreferencesFallback || _db == null) {
      _memTasks[task.id] = task;
      await _savePreferencesFallback();
      return;
    }
    await _db!.insert(
      'tasks',
      task.toMap(),
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteTask(String id) async {
    if (_usePreferencesFallback || _db == null) {
      _memTasks.remove(id);
      await _savePreferencesFallback();
      return;
    }
    await _db!.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  // ================= REMINDERS CRUD =================
  Future<List<ReminderItem>> getAllReminders() async {
    if (_usePreferencesFallback || _db == null) {
      return _memReminders.values.toList();
    }
    final maps = await _db!.query('reminders', orderBy: 'dateTime ASC');
    return maps.map((m) => ReminderItem.fromMap(m)).toList();
  }

  Future<void> saveReminder(ReminderItem reminder) async {
    if (_usePreferencesFallback || _db == null) {
      _memReminders[reminder.id] = reminder;
      await _savePreferencesFallback();
      return;
    }
    await _db!.insert(
      'reminders',
      reminder.toMap(),
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteReminder(String id) async {
    if (_usePreferencesFallback || _db == null) {
      _memReminders.remove(id);
      await _savePreferencesFallback();
      return;
    }
    await _db!.delete('reminders', where: 'id = ?', whereArgs: [id]);
  }

  // ================= DIARY ENTRIES CRUD =================
  Future<List<DiaryEntry>> getAllDiaryEntries() async {
    if (_usePreferencesFallback || _db == null) {
      final list = _memEntries.values.toList();
      list.sort((a, b) => b.entryDate.compareTo(a.entryDate));
      return list;
    }
    final maps = await _db!.query('diary_entries', orderBy: 'entryDate DESC');
    return maps.map((m) => DiaryEntry.fromMap(m)).toList();
  }

  Future<void> saveDiaryEntry(DiaryEntry entry) async {
    if (_usePreferencesFallback || _db == null) {
      _memEntries[entry.id] = entry;
      await _savePreferencesFallback();
      return;
    }
    await _db!.insert(
      'diary_entries',
      entry.toMap(),
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteDiaryEntry(String id) async {
    if (_usePreferencesFallback || _db == null) {
      _memEntries.remove(id);
      await _savePreferencesFallback();
      return;
    }
    await _db!.delete('diary_entries', where: 'id = ?', whereArgs: [id]);
  }

  // ================= HABITS CRUD =================
  Future<List<HabitItem>> getAllHabits() async {
    if (_usePreferencesFallback || _db == null) {
      return _memHabits.values.toList();
    }
    final maps = await _db!.query('habits', orderBy: 'createdAt ASC');
    return maps.map((m) => HabitItem.fromMap(m)).toList();
  }

  Future<void> saveHabit(HabitItem habit) async {
    if (_usePreferencesFallback || _db == null) {
      _memHabits[habit.id] = habit;
      await _savePreferencesFallback();
      return;
    }
    await _db!.insert(
      'habits',
      habit.toMap(),
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteHabit(String id) async {
    if (_usePreferencesFallback || _db == null) {
      _memHabits.remove(id);
      _memCompletions.removeWhere((k, v) => v.habitId == id);
      await _savePreferencesFallback();
      return;
    }
    await _db!.delete('habits', where: 'id = ?', whereArgs: [id]);
    await _db!.delete('habit_completions', where: 'habitId = ?', whereArgs: [id]);
  }

  // ================= HABIT COMPLETIONS CRUD =================
  Future<List<HabitCompletion>> getAllHabitCompletions() async {
    if (_usePreferencesFallback || _db == null) {
      return _memCompletions.values.toList();
    }
    final maps = await _db!.query('habit_completions');
    return maps.map((m) => HabitCompletion.fromMap(m)).toList();
  }

  Future<void> saveHabitCompletion(HabitCompletion completion) async {
    if (_usePreferencesFallback || _db == null) {
      _memCompletions[completion.id] = completion;
      await _savePreferencesFallback();
      return;
    }
    await _db!.insert(
      'habit_completions',
      completion.toMap(),
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteHabitCompletion(String id) async {
    if (_usePreferencesFallback || _db == null) {
      _memCompletions.remove(id);
      await _savePreferencesFallback();
      return;
    }
    await _db!.delete('habit_completions', where: 'id = ?', whereArgs: [id]);
  }

  // ================= SETTINGS =================
  Future<AppSettings> getAppSettings() async {
    if (_usePreferencesFallback || _db == null) {
      return _memSettings;
    }
    final maps = await _db!.query('app_settings', where: 'id = ?', whereArgs: ['main']);
    if (maps.isNotEmpty) {
      final jsonStr = maps.first['settingsJson'] as String;
      return AppSettings.fromMap(jsonDecode(jsonStr) as Map<String, dynamic>);
    }
    return const AppSettings();
  }

  Future<void> saveAppSettings(AppSettings settings) async {
    if (_usePreferencesFallback || _db == null) {
      _memSettings = settings;
      await _savePreferencesFallback();
      return;
    }
    await _db!.insert(
      'app_settings',
      {'id': 'main', 'settingsJson': jsonEncode(settings.toMap())},
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
  }

  // ================= STUDY NOTES CRUD =================
  Future<List<StudyNoteItem>> getAllNotes() async {
    if (_usePreferencesFallback || _db == null) {
      final list = _memNotes.values.toList();
      list.sort((a, b) {
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });
      return list;
    }
    final maps = await _db!.query(
      'study_notes',
      orderBy: 'isPinned DESC, updatedAt DESC',
    );
    return maps.map((m) => StudyNoteItem.fromMap(m)).toList();
  }

  Future<void> saveNote(StudyNoteItem note) async {
    if (_usePreferencesFallback || _db == null) {
      _memNotes[note.id] = note;
      await _savePreferencesFallback();
      return;
    }
    await _db!.insert(
      'study_notes',
      note.toMap(),
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteNote(String id) async {
    if (_usePreferencesFallback || _db == null) {
      _memNotes.remove(id);
      await _savePreferencesFallback();
      return;
    }
    await _db!.delete('study_notes', where: 'id = ?', whereArgs: [id]);
  }

  // ================= THEME SETTINGS (SQLITE BACKUP) =================
  Future<void> saveThemePreference({
    required String activeThemeId,
    required String activeThemeJson,
    String? customThemesJson,
    required int modeIndex,
  }) async {
    if (_db != null && !_usePreferencesFallback) {
      try {
        await _db!.insert(
          'theme_settings',
          {
            'id': 'active',
            'activeThemeId': activeThemeId,
            'activeThemeJson': activeThemeJson,
            'customThemesJson': customThemesJson ?? '[]',
            'modeIndex': modeIndex,
          },
          conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
        );
      } catch (_) {}
    }
  }

  Future<Map<String, dynamic>?> getThemePreference() async {
    if (_db != null && !_usePreferencesFallback) {
      try {
        final maps = await _db!.query(
          'theme_settings',
          where: 'id = ?',
          whereArgs: ['active'],
        );
        if (maps.isNotEmpty) {
          return maps.first;
        }
      } catch (_) {}
    }
    return null;
  }

  // ================= BACKUP & RESTORE =================
  Future<String> exportAllDataJson() async {
    final tasks = await getAllTasks();
    final reminders = await getAllReminders();
    final entries = await getAllDiaryEntries();
    final habits = await getAllHabits();
    final completions = await getAllHabitCompletions();
    final notes = await getAllNotes();
    final settings = await getAppSettings();

    final exportMap = {
      'version': '1.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'tasks': tasks.map((t) => t.toMap()).toList(),
      'reminders': reminders.map((r) => r.toMap()).toList(),
      'diary_entries': entries.map((e) => e.toMap()).toList(),
      'habits': habits.map((h) => h.toMap()).toList(),
      'habit_completions': completions.map((c) => c.toMap()).toList(),
      'study_notes': notes.map((n) => n.toMap()).toList(),
      'app_settings': settings.toMap(),
    };

    return jsonEncode(exportMap);
  }

  Future<bool> restoreAllDataJson(String jsonStr) async {
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      if (!map.containsKey('tasks') && !map.containsKey('habits') && !map.containsKey('study_notes')) {
        return false;
      }

      if (map['tasks'] != null) {
        for (final m in (map['tasks'] as List<dynamic>)) {
          await saveTask(TaskItem.fromMap(m as Map<String, dynamic>));
        }
      }

      if (map['reminders'] != null) {
        for (final m in (map['reminders'] as List<dynamic>)) {
          await saveReminder(ReminderItem.fromMap(m as Map<String, dynamic>));
        }
      }

      if (map['diary_entries'] != null) {
        for (final m in (map['diary_entries'] as List<dynamic>)) {
          await saveDiaryEntry(DiaryEntry.fromMap(m as Map<String, dynamic>));
        }
      }

      if (map['habits'] != null) {
        for (final m in (map['habits'] as List<dynamic>)) {
          await saveHabit(HabitItem.fromMap(m as Map<String, dynamic>));
        }
      }

      if (map['habit_completions'] != null) {
        for (final m in (map['habit_completions'] as List<dynamic>)) {
          await saveHabitCompletion(
              HabitCompletion.fromMap(m as Map<String, dynamic>));
        }
      }

      if (map['study_notes'] != null) {
        for (final m in (map['study_notes'] as List<dynamic>)) {
          await saveNote(StudyNoteItem.fromMap(m as Map<String, dynamic>));
        }
      }

      if (map['app_settings'] != null) {
        await saveAppSettings(
            AppSettings.fromMap(map['app_settings'] as Map<String, dynamic>));
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> resetAllData() async {
    if (_usePreferencesFallback || _db == null) {
      _memTasks.clear();
      _memReminders.clear();
      _memEntries.clear();
      _memHabits.clear();
      _memCompletions.clear();
      _memNotes.clear();
      _memSettings = const AppSettings();
      await _savePreferencesFallback();
      return;
    }

    await _db!.delete('tasks');
    await _db!.delete('reminders');
    await _db!.delete('diary_entries');
    await _db!.delete('habits');
    await _db!.delete('habit_completions');
    await _db!.delete('study_notes');
    await _db!.delete('app_settings');
  }
}
