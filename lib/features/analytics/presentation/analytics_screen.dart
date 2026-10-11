import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/dayflow_theme_context.dart';
import '../../../models/task_model.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/dayflow_card.dart';

enum AnalyticsActivityFilter { all, tasks, habits }

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  AnalyticsActivityFilter _activityFilter = AnalyticsActivityFilter.all;

  @override
  Widget build(BuildContext context) {
    final tokens = context.themeTokens;
    final allTasks = ref.watch(tasksProvider);
    final allHabits = ref.watch(habitsProvider);
    final completions = ref.watch(habitCompletionsProvider);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    // 1. Task Metrics
    final completedTodayTasks =
        allTasks.where((t) => t.isCompletedForDate(now)).length;
    final totalTodayTasks = allTasks.where((t) => t.appliesToDate(now)).length;

    // 2. Habit Metrics
    final completedTodayHabits = allHabits.where((h) {
      return completions.any(
          (c) => c.habitId == h.id && c.dateStr == todayStr && c.isCompleted);
    }).length;
    final totalTodayHabits =
        allHabits.where((h) => h.appliesToDate(now)).length;

    // 3. Combined Today Completion
    final combinedDoneToday = completedTodayTasks + completedTodayHabits;
    final combinedTotalToday = totalTodayTasks + totalTodayHabits;
    final todayRate = combinedTotalToday > 0
        ? ((combinedDoneToday / combinedTotalToday) * 100).round()
        : (combinedDoneToday > 0 ? 100 : 0);

    // 4. Past 7 days combined / filtered trend calculation
    final past7Days = List.generate(7, (i) {
      final date = today.subtract(Duration(days: 6 - i));
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final isToday = i == 6;

      final tasksDone =
          allTasks.where((t) => t.isCompletedForDate(date)).length;
      final habitsDone = allHabits.where((h) {
        return completions.any(
            (c) => c.habitId == h.id && c.dateStr == dateStr && c.isCompleted);
      }).length;

      int displayValue;
      switch (_activityFilter) {
        case AnalyticsActivityFilter.tasks:
          displayValue = tasksDone;
          break;
        case AnalyticsActivityFilter.habits:
          displayValue = habitsDone;
          break;
        case AnalyticsActivityFilter.all:
          displayValue = tasksDone + habitsDone;
          break;
      }

      return {
        'date': date,
        'label': DateFormat('E').format(date),
        'value': displayValue,
        'tasksDone': tasksDone,
        'habitsDone': habitsDone,
        'isToday': isToday,
      };
    });

    final int totalActivityWeek = past7Days.fold<int>(
        0, (acc, item) => acc + (item['value'] as int));

    // 5. Total Tasks Statistics
    final totalTasksCount = allTasks.length;
    final totalCompletedTasksCount =
        allTasks.where((t) => t.isCompleted).length;
    final overallTaskRate = totalTasksCount > 0
        ? (totalCompletedTasksCount / totalTasksCount * 100).round()
        : 0;

    // 6. Habit Streaks & Reliability Statistics
    int totalHabitStreaks = 0;
    int maxSingleStreak = 0;
    double sumReliability = 0.0;
    for (final h in allHabits) {
      final s = calculateHabitStreak(h, completions);
      totalHabitStreaks += s.currentStreak;
      if (s.currentStreak > maxSingleStreak) {
        maxSingleStreak = s.currentStreak;
      }
      sumReliability += s.completionRate;
    }

    final avgStreak = allHabits.isNotEmpty
        ? (totalHabitStreaks / allHabits.length).toStringAsFixed(1)
        : '0';
    final avgReliability = allHabits.isNotEmpty
        ? ((sumReliability / allHabits.length) * 100).round()
        : 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Productivity Insights',
          style: context.getTextStyle(
            fontSize: 20,
            fontWeight: tokens.headingWeight,
            color: tokens.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            tokens.screenPadding,
            8,
            tokens.screenPadding,
            80,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 4 Key Metric Cards
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      context: context,
                      title: 'Done Today',
                      value: '$combinedDoneToday',
                      subtext:
                          '$completedTodayTasks tasks, $completedTodayHabits habits',
                      icon: Icons.check_circle_outline,
                      iconColor: tokens.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricTile(
                      context: context,
                      title: '7-Day Activity',
                      value: '$totalActivityWeek',
                      subtext: 'completions this week',
                      icon: Icons.date_range,
                      iconColor: tokens.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      context: context,
                      title: 'Today Score',
                      value: '$todayRate%',
                      subtext:
                          '$combinedDoneToday of $combinedTotalToday done • $overallTaskRate% tasks',
                      icon: Icons.speed,
                      iconColor: tokens.accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricTile(
                      context: context,
                      title: 'Avg Streak',
                      value: '${avgStreak}d',
                      subtext: 'Max: ${maxSingleStreak}d • $avgReliability% rate',
                      icon: Icons.local_fire_department,
                      iconColor: tokens.warning,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Weekly Activity Animated Bar Chart
              DayFlowCard(
                padding: EdgeInsets.all(tokens.cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Activity Momentum',
                          style: context.getTextStyle(
                            fontSize: 16,
                            fontWeight: tokens.headingWeight,
                            color: tokens.textPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: tokens.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Past 7 Days',
                            style: context.getTextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: tokens.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Filter Selector (All, Tasks, Habits)
                    Row(
                      children: [
                        _buildFilterChip(
                          label: 'All Activity',
                          filter: AnalyticsActivityFilter.all,
                        ),
                        const SizedBox(width: 6),
                        _buildFilterChip(
                          label: 'Tasks Only',
                          filter: AnalyticsActivityFilter.tasks,
                        ),
                        const SizedBox(width: 6),
                        _buildFilterChip(
                          label: 'Habits Only',
                          filter: AnalyticsActivityFilter.habits,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Animated Bar Chart
                    SizedBox(
                      height: 180,
                      child: _AnimatedWeeklyBarChart(
                        key: ValueKey('chart_$_activityFilter'),
                        days: past7Days,
                        primaryColor: tokens.primary,
                        surfaceColor: tokens.surface,
                        textSecondary: tokens.textSecondary,
                        tokens: tokens,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Habit Consistency Scoreboard
              DayFlowCard(
                padding: EdgeInsets.all(tokens.cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Habits Consistency Scoreboard',
                          style: context.getTextStyle(
                            fontSize: 16,
                            fontWeight: tokens.headingWeight,
                            color: tokens.textPrimary,
                          ),
                        ),
                        Text(
                          '${allHabits.length} habits',
                          style: context.getTextStyle(
                            fontSize: 12,
                            color: tokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Live completion rates and active consecutive streaks',
                      style: context.getTextStyle(
                        fontSize: 12,
                        color: tokens.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (allHabits.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            'No habits tracked yet. Create daily habits like 20 pushups to see insights!',
                            style: context.getTextStyle(
                              color: tokens.textSecondary,
                            ),
                          ),
                        ),
                      )
                    else
                      ...allHabits.map((habit) {
                        final streak =
                            calculateHabitStreak(habit, completions);
                        final habitColor = Color(habit.colorValue);
                        final pct = (streak.completionRate * 100).round();

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: habitColor.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      IconData(habit.iconCodePoint,
                                          fontFamily: 'MaterialIcons'),
                                      size: 14,
                                      color: habitColor,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      habit.name,
                                      style: context.getTextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: tokens.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: tokens.warning.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.local_fire_department,
                                            size: 13, color: tokens.warning),
                                        const SizedBox(width: 2),
                                        Text(
                                          '${streak.currentStreak}d',
                                          style: context.getTextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: tokens.warning,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$pct%',
                                    style: context.getTextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: tokens.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween<double>(
                                      begin: 0.0,
                                      end: streak.completionRate
                                          .clamp(0.0, 1.0)),
                                  duration: const Duration(milliseconds: 700),
                                  curve: Curves.easeOutCubic,
                                  builder: (ctx, animVal, _) {
                                    return LinearProgressIndicator(
                                      value: animVal,
                                      backgroundColor: tokens.surface,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                              habitColor),
                                      minHeight: 7,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Category Breakdown Card
              DayFlowCard(
                padding: EdgeInsets.all(tokens.cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Task Category Breakdown',
                      style: context.getTextStyle(
                        fontSize: 16,
                        fontWeight: tokens.headingWeight,
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildCategoryDistribution(context, allTasks),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required AnalyticsActivityFilter filter,
  }) {
    final tokens = context.themeTokens;
    final isSelected = _activityFilter == filter;
    return InkWell(
      onTap: () => setState(() => _activityFilter = filter),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? tokens.primary : tokens.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? tokens.primary : tokens.borderColor,
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: context.getTextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? (tokens.primary.computeLuminance() > 0.4
                    ? Colors.black
                    : Colors.white)
                : tokens.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required BuildContext context,
    required String title,
    required String value,
    required String subtext,
    required IconData icon,
    required Color iconColor,
  }) {
    final tokens = context.themeTokens;
    return DayFlowCard(
      padding: EdgeInsets.all(tokens.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: context.getTextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: tokens.textSecondary,
                ),
              ),
              Icon(icon, size: 18, color: iconColor),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: context.getTextStyle(
              fontSize: 22,
              fontWeight: tokens.headingWeight,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.getTextStyle(
              fontSize: 11,
              color: tokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDistribution(
      BuildContext context, List<TaskItem> tasks) {
    final tokens = context.themeTokens;
    final Map<String, int> counts = {};
    for (final t in tasks) {
      counts[t.category] = (counts[t.category] ?? 0) + 1;
    }

    if (counts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'No tasks categorized yet.',
            style: context.getTextStyle(color: tokens.textSecondary),
          ),
        ),
      );
    }

    final total = tasks.length;
    return Column(
      children: counts.entries.map((entry) {
        final pct = (entry.value / total * 100).round();
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: tokens.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.key,
                  style: context.getTextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: tokens.textPrimary,
                  ),
                ),
              ),
              Text(
                '${entry.value} tasks ($pct%)',
                style: context.getTextStyle(
                  fontSize: 12,
                  color: tokens.textSecondary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _AnimatedWeeklyBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> days;
  final Color primaryColor;
  final Color surfaceColor;
  final Color textSecondary;
  final dynamic tokens;

  const _AnimatedWeeklyBarChart({
    super.key,
    required this.days,
    required this.primaryColor,
    required this.surfaceColor,
    required this.textSecondary,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    int maxVal = 1;
    for (final d in days) {
      final c = d['value'] as int;
      if (c > maxVal) maxVal = c;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: days.map((item) {
        final count = item['value'] as int;
        final label = item['label'] as String;
        final isToday = item['isToday'] as bool;
        final targetRatio = (count / maxVal).clamp(0.08, 1.0);

        return Expanded(
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.08, end: targetRatio),
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeOutCubic,
            builder: (ctx, animRatio, _) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          isToday ? FontWeight.bold : FontWeight.w600,
                      color: count > 0 ? primaryColor : textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 22,
                    height: 110 * animRatio,
                    decoration: BoxDecoration(
                      gradient: count > 0
                          ? LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                primaryColor,
                                primaryColor.withOpacity(isToday ? 0.9 : 0.7),
                              ],
                            )
                          : null,
                      color: count == 0
                          ? surfaceColor.withOpacity(0.8)
                          : null,
                      borderRadius: BorderRadius.circular(6),
                      border: isToday
                          ? Border.all(
                              color: primaryColor,
                              width: 1.5,
                            )
                          : null,
                      boxShadow: isToday && count > 0
                          ? [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.35),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: isToday
                          ? primaryColor.withOpacity(0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            isToday ? FontWeight.bold : FontWeight.w500,
                        color: isToday ? primaryColor : textSecondary,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      }).toList(),
    );
  }
}
