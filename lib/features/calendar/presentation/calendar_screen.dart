import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/dayflow_theme_context.dart';
import '../../../models/task_model.dart';
import '../../../models/reminder_model.dart';
import '../../../models/diary_entry_model.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/dayflow_card.dart';
import '../../tasks/presentation/task_form_dialog.dart';
import '../../journal/presentation/journal_editor_screen.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _selectedDay;
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDay = DateTime(now.year, now.month, now.day);
    _displayedMonth = DateTime(now.year, now.month, 1);
  }

  void _prevMonth() {
    setState(() {
      _displayedMonth =
          DateTime(_displayedMonth.year, _displayedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _displayedMonth =
          DateTime(_displayedMonth.year, _displayedMonth.month + 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.themeTokens;
    final allTasks = ref.watch(tasksProvider);
    final allReminders = ref.watch(remindersProvider);
    final allEntries = ref.watch(diaryProvider);

    // Selected day items
    final tasksForDay =
        allTasks.where((t) => t.appliesToDate(_selectedDay)).toList();

    final remindersForDay = allReminders.where((r) {
      return r.dateTime.year == _selectedDay.year &&
          r.dateTime.month == _selectedDay.month &&
          r.dateTime.day == _selectedDay.day;
    }).toList();

    final entriesForDay = allEntries.where((e) {
      return e.entryDate.year == _selectedDay.year &&
          e.entryDate.month == _selectedDay.month &&
          e.entryDate.day == _selectedDay.day;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Calendar Schedule',
          style: context.getTextStyle(
            fontSize: 20,
            fontWeight: tokens.headingWeight,
            color: tokens.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: 'Go to Today',
            onPressed: () {
              final now = DateTime.now();
              setState(() {
                _selectedDay = DateTime(now.year, now.month, now.day);
                _displayedMonth = DateTime(now.year, now.month, 1);
              });
            },
          ),
          IconButton.filled(
            style: IconButton.styleFrom(
              backgroundColor: tokens.primary,
              foregroundColor: tokens.primary.computeLuminance() > 0.4
                  ? Colors.black
                  : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(tokens.buttonRadius),
              ),
            ),
            icon: const Icon(Icons.add),
            tooltip: 'Add Task for Date',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => TaskFormDialog(defaultDate: _selectedDay),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Month Header & Navigation
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: tokens.screenPadding,
                vertical: 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _prevMonth,
                  ),
                  Text(
                    DateFormat('MMMM y').format(_displayedMonth),
                    style: context.getTextStyle(
                      fontSize: 17,
                      fontWeight: tokens.headingWeight,
                      color: tokens.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _nextMonth,
                  ),
                ],
              ),
            ),

            // Calendar Month Grid Card
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: tokens.screenPadding,
                vertical: 4,
              ),
              child: DayFlowCard(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                child: _buildMonthGrid(
                  tasks: allTasks,
                  reminders: allReminders,
                  entries: allEntries,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Schedule for Selected Day Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: tokens.screenPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('EEEE, MMM d').format(_selectedDay),
                    style: context.getTextStyle(
                      fontSize: 15,
                      fontWeight: tokens.headingWeight,
                      color: tokens.textPrimary,
                    ),
                  ),
                  Text(
                    '${tasksForDay.length} tasks • ${remindersForDay.length} reminders',
                    style: context.getTextStyle(
                      fontSize: 12,
                      color: tokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Selected Day Agenda List
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  tokens.screenPadding,
                  4,
                  tokens.screenPadding,
                  80,
                ),
                children: [
                  if (tasksForDay.isEmpty &&
                      remindersForDay.isEmpty &&
                      entriesForDay.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 36),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.event_available,
                                size: 36,
                                color: tokens.textSecondary.withOpacity(0.5)),
                            const SizedBox(height: 10),
                            Text(
                              'Nothing scheduled for this day',
                              style: context.getTextStyle(
                                fontSize: 14,
                                color: tokens.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Tasks Section
                  if (tasksForDay.isNotEmpty) ...[
                    ...tasksForDay.map((task) {
                      final isDone = task.isCompletedForDate(_selectedDay);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: DayFlowCard(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              InkWell(
                                onTap: () {
                                  ref
                                      .read(tasksProvider.notifier)
                                      .toggleTaskCompletion(
                                          task.id, _selectedDay);
                                },
                                child: Icon(
                                  isDone
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  size: 20,
                                  color: isDone
                                      ? tokens.primary
                                      : tokens.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  task.title,
                                  style: context.getTextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: isDone
                                        ? tokens.textSecondary
                                        : tokens.textPrimary,
                                    decoration: isDone
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                              ),
                              if (task.dueTime != null)
                                Text(
                                  task.dueTime!,
                                  style: context.getTextStyle(
                                    fontSize: 12,
                                    color: tokens.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],

                  // Reminders Section
                  if (remindersForDay.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...remindersForDay.map((rem) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: DayFlowCard(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              Icon(Icons.alarm,
                                  size: 18, color: tokens.secondary),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  rem.title,
                                  style: context.getTextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: tokens.textPrimary,
                                  ),
                                ),
                              ),
                              Text(
                                DateFormat('h:mm a').format(rem.dateTime),
                                style: context.getTextStyle(
                                  fontSize: 12,
                                  color: tokens.secondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],

                  // Diary Entries for this day
                  if (entriesForDay.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...entriesForDay.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: DayFlowCard(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    JournalEditorScreen(initialEntry: entry),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              Icon(Icons.menu_book,
                                  size: 18, color: tokens.accent),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.title,
                                      style: context.getTextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: tokens.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'Journal Entry • ${entry.mood}',
                                      style: context.getTextStyle(
                                        fontSize: 11,
                                        color: tokens.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, size: 16),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthGrid({
    required List<TaskItem> tasks,
    required List<ReminderItem> reminders,
    required List<DiaryEntry> entries,
  }) {
    final tokens = context.themeTokens;
    final weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    final firstDayOfMonth =
        DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final daysInMonth =
        DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0).day;

    final startOffset = firstDayOfMonth.weekday - 1; // 0 = Mon, 6 = Sun
    final totalCells = ((startOffset + daysInMonth + 6) ~/ 7) * 7;

    return Column(
      children: [
        // Weekday header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: weekdays.map((w) {
            return SizedBox(
              width: 32,
              child: Center(
                child: Text(
                  w,
                  style: context.getTextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: tokens.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),

        // Grid of days
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: totalCells,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 1.1,
          ),
          itemBuilder: (context, index) {
            final dayNumber = index - startOffset + 1;
            if (dayNumber < 1 || dayNumber > daysInMonth) {
              return const SizedBox();
            }

            final cellDate = DateTime(
                _displayedMonth.year, _displayedMonth.month, dayNumber);
            final isSelected = cellDate.year == _selectedDay.year &&
                cellDate.month == _selectedDay.month &&
                cellDate.day == _selectedDay.day;
            final isToday = cellDate.year == DateTime.now().year &&
                cellDate.month == DateTime.now().month &&
                cellDate.day == DateTime.now().day;

            final hasTasks = tasks.any((t) => t.appliesToDate(cellDate));
            final hasReminders = reminders.any((r) =>
                r.dateTime.year == cellDate.year &&
                r.dateTime.month == cellDate.month &&
                r.dateTime.day == cellDate.day);
            final hasJournal = entries.any((e) =>
                e.entryDate.year == cellDate.year &&
                e.entryDate.month == cellDate.month &&
                e.entryDate.day == cellDate.day);

            return InkWell(
              onTap: () {
                setState(() => _selectedDay = cellDate);
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? tokens.primary
                      : isToday
                          ? tokens.primary.withOpacity(0.12)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: isToday && !isSelected
                      ? Border.all(color: tokens.primary, width: 1.2)
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$dayNumber',
                      style: context.getTextStyle(
                        fontSize: 12,
                        fontWeight: isSelected || isToday
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isSelected
                            ? (tokens.primary.computeLuminance() > 0.4
                                ? Colors.black
                                : Colors.white)
                            : tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (hasTasks)
                          Container(
                            width: 4,
                            height: 4,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : tokens.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        if (hasReminders)
                          Container(
                            width: 4,
                            height: 4,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : tokens.secondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        if (hasJournal)
                          Container(
                            width: 4,
                            height: 4,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : tokens.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
