import 'dart:convert';

enum HabitFrequency { daily, weekdays, specificDays, timesPerWeek }

class HabitItem {
  final String id;
  final String name;
  final int iconCodePoint;
  final int colorValue;
  final HabitFrequency frequency;
  final List<int> targetDays; // 1 = Monday, 7 = Sunday
  final int dailyTarget;
  final String? unit;
  final bool hasReminder;
  final String? reminderTime; // "HH:MM"
  final String? customAudioPath;
  final String? customAudioName;
  final DateTime createdAt;

  const HabitItem({
    required this.id,
    required this.name,
    this.iconCodePoint = 0xe57f, // Icons.star
    this.colorValue = 0xFF10B981,
    this.frequency = HabitFrequency.daily,
    this.targetDays = const [1, 2, 3, 4, 5, 6, 7],
    this.dailyTarget = 1,
    this.unit,
    this.hasReminder = false,
    this.reminderTime,
    this.customAudioPath,
    this.customAudioName,
    required this.createdAt,
  });

  bool appliesToDate(DateTime date) {
    switch (frequency) {
      case HabitFrequency.daily:
        return true;
      case HabitFrequency.weekdays:
        return date.weekday >= 1 && date.weekday <= 5;
      case HabitFrequency.specificDays:
      case HabitFrequency.timesPerWeek:
        return targetDays.contains(date.weekday);
    }
  }

  HabitItem copyWith({
    String? id,
    String? name,
    int? iconCodePoint,
    int? colorValue,
    HabitFrequency? frequency,
    List<int>? targetDays,
    int? dailyTarget,
    String? unit,
    bool? hasReminder,
    String? reminderTime,
    String? customAudioPath,
    String? customAudioName,
    DateTime? createdAt,
  }) {
    return HabitItem(
      id: id ?? this.id,
      name: name ?? this.name,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorValue: colorValue ?? this.colorValue,
      frequency: frequency ?? this.frequency,
      targetDays: targetDays ?? this.targetDays,
      dailyTarget: dailyTarget ?? this.dailyTarget,
      unit: unit ?? this.unit,
      hasReminder: hasReminder ?? this.hasReminder,
      reminderTime: reminderTime ?? this.reminderTime,
      customAudioPath: customAudioPath ?? this.customAudioPath,
      customAudioName: customAudioName ?? this.customAudioName,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconCodePoint': iconCodePoint,
      'colorValue': colorValue,
      'frequency': frequency.index,
      'targetDays': jsonEncode(targetDays),
      'dailyTarget': dailyTarget,
      'unit': unit,
      'hasReminder': hasReminder ? 1 : 0,
      'reminderTime': reminderTime,
      'customAudioPath': customAudioPath,
      'customAudioName': customAudioName,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory HabitItem.fromMap(Map<String, dynamic> map) {
    List<int> parsedDays = [1, 2, 3, 4, 5, 6, 7];
    if (map['targetDays'] != null) {
      try {
        final decoded =
            jsonDecode(map['targetDays'] as String) as List<dynamic>;
        parsedDays = decoded.map((e) => (e as num).toInt()).toList();
      } catch (_) {}
    }

    return HabitItem(
      id: map['id'] as String,
      name: map['name'] as String,
      iconCodePoint: (map['iconCodePoint'] as num?)?.toInt() ?? 0xe57f,
      colorValue: (map['colorValue'] as num?)?.toInt() ?? 0xFF10B981,
      frequency:
          HabitFrequency.values[(map['frequency'] as num?)?.toInt() ?? 0],
      targetDays: parsedDays,
      dailyTarget: (map['dailyTarget'] as num?)?.toInt() ?? 1,
      unit: map['unit'] as String?,
      hasReminder: (map['hasReminder'] as num?) == 1,
      reminderTime: map['reminderTime'] as String?,
      customAudioPath: map['customAudioPath'] as String?,
      customAudioName: map['customAudioName'] as String?,
      createdAt: DateTime.parse(
          map['createdAt'] as String? ?? DateTime.now().toIso8601String()),
    );
  }
}

class HabitCompletion {
  final String id;
  final String habitId;
  final String dateStr; // YYYY-MM-DD
  final int progress;
  final bool isCompleted;
  final DateTime timestamp;

  const HabitCompletion({
    required this.id,
    required this.habitId,
    required this.dateStr,
    this.progress = 1,
    this.isCompleted = true,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'habitId': habitId,
      'dateStr': dateStr,
      'progress': progress,
      'isCompleted': isCompleted ? 1 : 0,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory HabitCompletion.fromMap(Map<String, dynamic> map) {
    return HabitCompletion(
      id: map['id'] as String,
      habitId: map['habitId'] as String,
      dateStr: map['dateStr'] as String,
      progress: (map['progress'] as num?)?.toInt() ?? 1,
      isCompleted: (map['isCompleted'] as num?) == 1,
      timestamp: DateTime.parse(
          map['timestamp'] as String? ?? DateTime.now().toIso8601String()),
    );
  }
}
