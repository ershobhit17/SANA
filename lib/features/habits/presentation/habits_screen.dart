import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/services/notification_service.dart';
import '../../../core/theme/dayflow_theme_context.dart';
import '../../../models/habit_model.dart';
import '../../../models/reminder_model.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/dayflow_card.dart';
import '../../../shared/widgets/dayflow_empty_state.dart';
import 'habit_form_dialog.dart';

class HabitsScreen extends ConsumerStatefulWidget {
  const HabitsScreen({super.key});

  @override
  ConsumerState<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends ConsumerState<HabitsScreen> {
  void _openCreateHabitDialog() {
    showDialog(
      context: context,
      builder: (_) => const HabitFormDialog(),
    );
  }

  void _openEditHabitDialog(HabitItem habit) {
    showDialog(
      context: context,
      builder: (_) => HabitFormDialog(initialHabit: habit),
    );
  }

  Future<void> _openAlarmQuickPicker(HabitItem habit) async {
    final tokens = context.themeTokens;
    TimeOfDay initial = const TimeOfDay(hour: 9, minute: 0);
    if (habit.reminderTime != null) {
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
        initial = TimeOfDay(hour: h, minute: m);
      } catch (_) {}
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: 'Set Daily Alarm for ${habit.name}',
      builder: (ctx, child) {
        return MediaQuery(
          data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: false),
          child: child ?? const SizedBox(),
        );
      },
    );

    if (picked != null && mounted) {
      final timeStr = picked.format(context);
      final updated = habit.copyWith(hasReminder: true, reminderTime: timeStr);
      ref.read(habitsProvider.notifier).updateHabit(updated);

      final now = DateTime.now();
      final remDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        picked.hour,
        picked.minute,
      );

      final reminder = ReminderItem(
        id: 'rem_habit_${habit.id}',
        title: '⏰ Habit Alarm: ${habit.name}',
        description: 'Time to complete ${habit.dailyTarget} ${habit.unit ?? "times"} of ${habit.name}!',
        dateTime: remDateTime,
        repeat: ReminderRepeat.daily,
        isEnabled: true,
        associatedHabitId: habit.id,
        notificationId: habit.id.hashCode.abs().remainder(100000),
        createdAt: now,
      );

      await ref.read(remindersProvider.notifier).createReminder(reminder);
      await NotificationService.instance.requestPermissions();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: tokens.cardColor,
            content: Text(
              'Daily alarm scheduled for $timeStr for "${habit.name}"!',
              style: context.getTextStyle(color: tokens.textPrimary),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<bool> _confirmDeleteHabit(HabitItem habit) async {
    final tokens = context.themeTokens;
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tokens.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.cardRadius),
          side: BorderSide(color: tokens.borderColor),
        ),
        title: Row(
          children: [
            Icon(Icons.delete_outline, color: tokens.error, size: 24),
            const SizedBox(width: 8),
            Text(
              'Delete Habit',
              style: ctx.getTextStyle(
                fontSize: 18,
                fontWeight: tokens.headingWeight,
                color: tokens.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${habit.name}" and all its history?',
          style: ctx.getTextStyle(
            fontSize: 14,
            color: tokens.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel',
                style: ctx.getTextStyle(color: tokens.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              ref.read(habitsProvider.notifier).deleteHabit(habit.id);
              Navigator.of(ctx).pop(true);
            },
            child: Text(
              'Delete',
              style: ctx.getTextStyle(
                color: tokens.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    return res ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.themeTokens;
    final habits = ref.watch(habitsProvider);
    final completions = ref.watch(habitCompletionsProvider);

    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final completedTodayCount = habits.where((h) {
      return completions.any(
          (c) => c.habitId == h.id && c.dateStr == todayStr && c.isCompleted);
    }).length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Habit Tracker',
          style: context.getTextStyle(
            fontSize: 20,
            fontWeight: tokens.headingWeight,
            color: tokens.textPrimary,
          ),
        ),
        actions: [
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
            tooltip: 'Add Habit',
            onPressed: _openCreateHabitDialog,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Consistency & Today Summary Header
            if (habits.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: tokens.screenPadding,
                  vertical: 6,
                ),
                child: DayFlowCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: tokens.primary.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.local_fire_department,
                            color: tokens.primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$completedTodayCount of ${habits.length} habits completed today',
                              style: context.getTextStyle(
                                fontSize: 14,
                                fontWeight: tokens.headingWeight,
                                color: tokens.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: habits.isNotEmpty
                                    ? completedTodayCount / habits.length
                                    : 0,
                                backgroundColor: tokens.surface,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(tokens.primary),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            Expanded(
              child: habits.isEmpty
                  ? DayFlowEmptyState(
                      icon: Icons.repeat,
                      title: 'Build Consistent Daily Habits',
                      message:
                          'Track habits like 20 daily pushups at 9 AM, drinking water, or meditation.',
                      actionLabel: 'Create First Habit',
                      onAction: _openCreateHabitDialog,
                    )
                  : ListView.builder(
                      padding: EdgeInsets.fromLTRB(
                        tokens.screenPadding,
                        8,
                        tokens.screenPadding,
                        80,
                      ),
                      itemCount: habits.length,
                      itemBuilder: (context, index) {
                        final habit = habits[index];
                        final streakInfo =
                            calculateHabitStreak(habit, completions);
                        return _buildHabitCard(
                          habit: habit,
                          streakInfo: streakInfo,
                          completions: completions,
                          now: now,
                          todayStr: todayStr,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitCard({
    required HabitItem habit,
    required HabitStreakInfo streakInfo,
    required List<HabitCompletion> completions,
    required DateTime now,
    required String todayStr,
  }) {
    final tokens = context.themeTokens;
    final habitColor = Color(habit.colorValue);

    final todayComp = completions.firstWhere(
      (c) => c.habitId == habit.id && c.dateStr == todayStr,
      orElse: () => HabitCompletion(
        id: '',
        habitId: habit.id,
        dateStr: todayStr,
        progress: 0,
        isCompleted: false,
        timestamp: now,
      ),
    );

    final isDoneToday = todayComp.isCompleted;

    // Past 7 days calculation
    final pastDays = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      final dStr =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final isDone = completions.any(
          (c) => c.habitId == habit.id && c.dateStr == dStr && c.isCompleted);
      final isScheduled = habit.appliesToDate(d);
      return {'date': d, 'isDone': isDone, 'isScheduled': isScheduled};
    });

    return Padding(
      padding: EdgeInsets.only(bottom: tokens.itemSpacing),
      child: Dismissible(
        key: Key('habit_${habit.id}'),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) => _confirmDeleteHabit(habit),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: tokens.error.withOpacity(0.85),
            borderRadius: BorderRadius.circular(tokens.cardRadius),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(Icons.delete_outline, color: Colors.white, size: 24),
              SizedBox(width: 6),
              Text(
                'Delete',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        child: DayFlowCard(
          padding: EdgeInsets.all(tokens.cardPadding),
          onTap: () => _openEditHabitDialog(habit),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Habit Icon Badge
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: habitColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: habitColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      IconData(habit.iconCodePoint, fontFamily: 'MaterialIcons'),
                      color: habitColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Name & Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          habit.name,
                          style: context.getTextStyle(
                            fontSize: 16,
                            fontWeight: tokens.headingWeight,
                            color: tokens.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${habit.dailyTarget} ${habit.unit ?? "times"} • ${habit.frequency == HabitFrequency.daily ? "Every day" : habit.frequency == HabitFrequency.weekdays ? "Weekdays" : "Custom days"}',
                          style: context.getTextStyle(
                            fontSize: 12,
                            color: tokens.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Alarm Badge / Quick Set Alarm
                        if (habit.hasReminder && habit.reminderTime != null)
                          InkWell(
                            onTap: () => _openAlarmQuickPicker(habit),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: tokens.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: tokens.primary.withOpacity(0.25),
                                    width: 0.6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.alarm,
                                      size: 12, color: tokens.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Daily Alarm: ${habit.reminderTime}',
                                    style: context.getTextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: tokens.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          InkWell(
                            onTap: () => _openAlarmQuickPicker(habit),
                            borderRadius: BorderRadius.circular(6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.alarm_add,
                                    size: 13, color: tokens.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  '+ Set Alarm',
                                  style: context.getTextStyle(
                                    fontSize: 11,
                                    color: tokens.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Streak Flame Badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: tokens.warning.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: tokens.warning.withOpacity(0.3),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_fire_department,
                            size: 16, color: tokens.warning),
                        const SizedBox(width: 2),
                        Text(
                          '${streakInfo.currentStreak}d',
                          style: context.getTextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: tokens.warning,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Complete Action Button with Spring Bounce & Haptic
                  InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      ref
                          .read(habitCompletionsProvider.notifier)
                          .toggleHabitCompletion(
                              habit.id, now, habit.dailyTarget);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedScale(
                      scale: isDoneToday ? 1.08 : 1.0,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutBack,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isDoneToday ? habitColor : tokens.surface,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDoneToday ? habitColor : tokens.borderColor,
                            width: 1.5,
                          ),
                          boxShadow: isDoneToday
                              ? [
                                  BoxShadow(
                                    color: habitColor.withOpacity(0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.check,
                            size: 20,
                            color: isDoneToday
                                ? Colors.white
                                : tokens.textSecondary.withOpacity(0.4),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Direct Delete Button
                  IconButton(
                    icon: Icon(Icons.delete_outline,
                        size: 20, color: tokens.textSecondary.withOpacity(0.7)),
                    tooltip: 'Delete Habit',
                    onPressed: () => _confirmDeleteHabit(habit),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 7-Day Mini Heatmap / History Dots
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: tokens.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: tokens.borderColor, width: 0.6),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: pastDays.map((item) {
                    final DateTime d = item['date'] as DateTime;
                    final bool isDone = item['isDone'] as bool;
                    final bool isScheduled = item['isScheduled'] as bool;
                    final isToday = d.day == now.day && d.month == now.month;

                    return Column(
                      children: [
                        Text(
                          DateFormat('E').format(d).substring(0, 1),
                          style: context.getTextStyle(
                            fontSize: 10,
                            fontWeight:
                                isToday ? FontWeight.bold : FontWeight.w500,
                            color: isToday
                                ? tokens.primary
                                : tokens.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: isDone
                                ? habitColor
                                : isScheduled
                                    ? habitColor.withOpacity(0.15)
                                    : tokens.borderColor.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: isToday
                                ? Border.all(color: tokens.primary, width: 1.5)
                                : null,
                          ),
                          child: isDone
                              ? const Icon(Icons.check,
                                  size: 12, color: Colors.white)
                              : null,
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
