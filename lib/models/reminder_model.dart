import 'dart:convert';

enum ReminderRepeat { none, daily, weekly, weekdays, custom }

class ReminderItem {
  final String id;
  final String title;
  final String? description;
  final DateTime dateTime;
  final ReminderRepeat repeat;
  final List<int>? repeatDays; // 1 = Mon, 7 = Sun
  final bool isEnabled;
  final int notificationId;
  final String? associatedTaskId;
  final String? associatedHabitId;
  final String? customAudioPath;
  final String? customAudioName;
  final DateTime createdAt;

  const ReminderItem({
    required this.id,
    required this.title,
    this.description,
    required this.dateTime,
    this.repeat = ReminderRepeat.none,
    this.repeatDays,
    this.isEnabled = true,
    required this.notificationId,
    this.associatedTaskId,
    this.associatedHabitId,
    this.customAudioPath,
    this.customAudioName,
    required this.createdAt,
  });

  ReminderItem copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dateTime,
    ReminderRepeat? repeat,
    List<int>? repeatDays,
    bool? isEnabled,
    int? notificationId,
    String? associatedTaskId,
    String? associatedHabitId,
    String? customAudioPath,
    String? customAudioName,
    DateTime? createdAt,
  }) {
    return ReminderItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
      repeat: repeat ?? this.repeat,
      repeatDays: repeatDays ?? this.repeatDays,
      isEnabled: isEnabled ?? this.isEnabled,
      notificationId: notificationId ?? this.notificationId,
      associatedTaskId: associatedTaskId ?? this.associatedTaskId,
      associatedHabitId: associatedHabitId ?? this.associatedHabitId,
      customAudioPath: customAudioPath ?? this.customAudioPath,
      customAudioName: customAudioName ?? this.customAudioName,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dateTime': dateTime.toIso8601String(),
      'repeat': repeat.index,
      'repeatDays': repeatDays != null ? jsonEncode(repeatDays) : null,
      'isEnabled': isEnabled ? 1 : 0,
      'notificationId': notificationId,
      'associatedTaskId': associatedTaskId,
      'associatedHabitId': associatedHabitId,
      'customAudioPath': customAudioPath,
      'customAudioName': customAudioName,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ReminderItem.fromMap(Map<String, dynamic> map) {
    List<int>? parsedRepeatDays;
    if (map['repeatDays'] != null) {
      try {
        final decoded =
            jsonDecode(map['repeatDays'] as String) as List<dynamic>;
        parsedRepeatDays = decoded.map((e) => (e as num).toInt()).toList();
      } catch (_) {}
    }

    return ReminderItem(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      dateTime: DateTime.parse(map['dateTime'] as String),
      repeat:
          ReminderRepeat.values[(map['repeat'] as num?)?.toInt() ?? 0],
      repeatDays: parsedRepeatDays,
      isEnabled: (map['isEnabled'] as num?) == 1,
      notificationId: (map['notificationId'] as num?)?.toInt() ?? 0,
      associatedTaskId: map['associatedTaskId'] as String?,
      associatedHabitId: map['associatedHabitId'] as String?,
      customAudioPath: map['customAudioPath'] as String?,
      customAudioName: map['customAudioName'] as String?,
      createdAt: DateTime.parse(
          map['createdAt'] as String? ?? DateTime.now().toIso8601String()),
    );
  }
}
