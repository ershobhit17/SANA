import 'dart:convert';

enum TaskPriority { low, medium, high }

enum TaskRecurrence { none, daily, weekly, custom }

class Subtask {
  final String id;
  final String title;
  final bool isCompleted;

  const Subtask({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });

  Subtask copyWith({
    String? id,
    String? title,
    bool? isCompleted,
  }) {
    return Subtask(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted ? 1 : 0,
    };
  }

  factory Subtask.fromMap(Map<String, dynamic> map) {
    return Subtask(
      id: map['id'] as String,
      title: map['title'] as String,
      isCompleted: (map['isCompleted'] as num?) == 1,
    );
  }
}

class TaskItem {
  final String id;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final String? dueTime;
  final TaskPriority priority;
  final String category;
  final bool isCompleted;
  final DateTime? completedAt;
  final TaskRecurrence recurrence;
  final List<int>? recurringDays; // 1 = Monday, 7 = Sunday
  final List<Subtask> subtasks;
  final List<String> completedDates; // For recurring tasks: YYYY-MM-DD strings
  final DateTime createdAt;
  final DateTime updatedAt;

  const TaskItem({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.dueTime,
    this.priority = TaskPriority.medium,
    this.category = 'General',
    this.isCompleted = false,
    this.completedAt,
    this.recurrence = TaskRecurrence.none,
    this.recurringDays,
    this.subtasks = const [],
    this.completedDates = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isRecurring => recurrence != TaskRecurrence.none;

  /// Determines whether today's occurrence of a task is completed.
  /// For recurring tasks, checks if today's date is in [completedDates].
  /// For one-time tasks, checks [isCompleted].
  bool isCompletedForDate(DateTime date) {
    if (!isRecurring) {
      return isCompleted;
    }
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return completedDates.contains(dateStr);
  }

  /// Checks if the task is due on or applies to a given date.
  bool appliesToDate(DateTime date) {
    if (!isRecurring) {
      if (dueDate == null) return false;
      return dueDate!.year == date.year &&
          dueDate!.month == date.month &&
          dueDate!.day == date.day;
    }

    // Recurring task checks
    if (dueDate != null) {
      final taskStart = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
      final checkDate = DateTime(date.year, date.month, date.day);
      if (checkDate.isBefore(taskStart)) return false;
    }

    switch (recurrence) {
      case TaskRecurrence.daily:
        return true;
      case TaskRecurrence.weekly:
        final originalWeekday = (dueDate ?? createdAt).weekday;
        return date.weekday == originalWeekday;
      case TaskRecurrence.custom:
        if (recurringDays == null || recurringDays!.isEmpty) return true;
        return recurringDays!.contains(date.weekday);
      case TaskRecurrence.none:
        return false;
    }
  }

  TaskItem copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    String? dueTime,
    TaskPriority? priority,
    String? category,
    bool? isCompleted,
    DateTime? completedAt,
    TaskRecurrence? recurrence,
    List<int>? recurringDays,
    List<Subtask>? subtasks,
    List<String>? completedDates,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      recurrence: recurrence ?? this.recurrence,
      recurringDays: recurringDays ?? this.recurringDays,
      subtasks: subtasks ?? this.subtasks,
      completedDates: completedDates ?? this.completedDates,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate?.toIso8601String(),
      'dueTime': dueTime,
      'priority': priority.index,
      'category': category,
      'isCompleted': isCompleted ? 1 : 0,
      'completedAt': completedAt?.toIso8601String(),
      'recurrence': recurrence.index,
      'recurringDays':
          recurringDays != null ? jsonEncode(recurringDays) : null,
      'subtasks': jsonEncode(subtasks.map((s) => s.toMap()).toList()),
      'completedDates': jsonEncode(completedDates),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory TaskItem.fromMap(Map<String, dynamic> map) {
    List<Subtask> parsedSubtasks = [];
    if (map['subtasks'] != null) {
      try {
        final decoded = jsonDecode(map['subtasks'] as String) as List<dynamic>;
        parsedSubtasks = decoded
            .map((s) => Subtask.fromMap(s as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    List<String> parsedCompletedDates = [];
    if (map['completedDates'] != null) {
      try {
        final decoded =
            jsonDecode(map['completedDates'] as String) as List<dynamic>;
        parsedCompletedDates = decoded.map((e) => e.toString()).toList();
      } catch (_) {}
    }

    List<int>? parsedRecurringDays;
    if (map['recurringDays'] != null) {
      try {
        final decoded =
            jsonDecode(map['recurringDays'] as String) as List<dynamic>;
        parsedRecurringDays = decoded.map((e) => (e as num).toInt()).toList();
      } catch (_) {}
    }

    return TaskItem(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      dueDate: map['dueDate'] != null
          ? DateTime.tryParse(map['dueDate'] as String)
          : null,
      dueTime: map['dueTime'] as String?,
      priority: TaskPriority.values[(map['priority'] as num?)?.toInt() ?? 1],
      category: map['category'] as String? ?? 'General',
      isCompleted: (map['isCompleted'] as num?) == 1,
      completedAt: map['completedAt'] != null
          ? DateTime.tryParse(map['completedAt'] as String)
          : null,
      recurrence:
          TaskRecurrence.values[(map['recurrence'] as num?)?.toInt() ?? 0],
      recurringDays: parsedRecurringDays,
      subtasks: parsedSubtasks,
      completedDates: parsedCompletedDates,
      createdAt: DateTime.parse(
          map['createdAt'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(
          map['updatedAt'] as String? ?? DateTime.now().toIso8601String()),
    );
  }
}
