import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/dayflow_theme_context.dart';
import '../../../models/task_model.dart';
import '../../../models/reminder_model.dart';
import '../../../models/habit_model.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/dayflow_card.dart';
import '../../tasks/presentation/task_form_dialog.dart';
import '../../tasks/presentation/tasks_screen.dart';
import '../../habits/presentation/habit_form_dialog.dart';
import '../../habits/presentation/habits_screen.dart';
import '../../reminders/presentation/reminder_form_dialog.dart';
import '../../reminders/presentation/reminders_screen.dart';
import '../../journal/presentation/journal_screen.dart';
import '../../calendar/presentation/calendar_screen.dart';
import '../../theme_studio/presentation/theme_studio_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../notes/presentation/notes_screen.dart';
import '../../notes/presentation/note_form_dialog.dart';
import '../../../models/study_note_model.dart';
import '../../../core/utils/url_launcher_helper.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good morning';
    if (hour >= 12 && hour < 17) return 'Good afternoon';
    if (hour >= 17 && hour < 22) return 'Good evening';
    return 'Good night';
  }

  String _getGreetingEmoji() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return '☀️';
    if (hour >= 12 && hour < 17) return '🌤️';
    if (hour >= 17 && hour < 22) return '🌙';
    return '✨';
  }

  Future<void> _confirmDeleteHabit(HabitItem habit) async {
    final tokens = context.themeTokens;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tokens.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.cardRadius),
          side: BorderSide(color: tokens.borderColor, width: 1.5),
        ),
        title: Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: tokens.error, size: 24),
            const SizedBox(width: 8),
            Text(
              'Delete Habit?',
              style: ctx.getTextStyle(
                fontSize: 18,
                fontWeight: tokens.headingWeight,
                color: tokens.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${habit.name}" and all its recorded data?',
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
            onPressed: () => Navigator.of(ctx).pop(true),
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

    if (confirm == true && mounted) {
      ref.read(habitsProvider.notifier).deleteHabit(habit.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: tokens.cardColor,
          content: Text(
            'Habit "${habit.name}" deleted successfully.',
            style: context.getTextStyle(color: tokens.textPrimary),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _confirmDeleteReminder(ReminderItem reminder) async {
    final tokens = context.themeTokens;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tokens.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.cardRadius),
          side: BorderSide(color: tokens.borderColor, width: 1.5),
        ),
        title: Row(
          children: [
            Icon(Icons.delete_outline, color: tokens.error, size: 24),
            const SizedBox(width: 8),
            Text(
              'Delete Reminder?',
              style: ctx.getTextStyle(
                fontSize: 18,
                fontWeight: tokens.headingWeight,
                color: tokens.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          'Remove reminder "${reminder.title}"?',
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
            onPressed: () => Navigator.of(ctx).pop(true),
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

    if (confirm == true && mounted) {
      ref.read(remindersProvider.notifier).deleteReminder(reminder.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: tokens.cardColor,
          content: Text(
            'Reminder deleted.',
            style: context.getTextStyle(color: tokens.textPrimary),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.themeTokens;
    final allTasks = ref.watch(tasksProvider);
    final allHabits = ref.watch(habitsProvider);
    final completions = ref.watch(habitCompletionsProvider);
    final allReminders = ref.watch(remindersProvider);
    final allNotes = ref.watch(notesProvider);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedStr =
        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

    final activeTasks = allTasks.where((t) => t.appliesToDate(_selectedDate)).toList();
    final completedCount =
        activeTasks.where((t) => t.isCompletedForDate(_selectedDate)).length;
    final pendingCount = activeTasks.length - completedCount;

    final overdueCount = allTasks.where((t) {
      if (t.isRecurring || t.isCompleted || t.dueDate == null) return false;
      final due = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
      return due.isBefore(today);
    }).length;

    final completionPct = activeTasks.isNotEmpty
        ? ((completedCount / activeTasks.length) * 100).round()
        : 0;

    final scheduledHabits =
        allHabits.where((h) => h.appliesToDate(_selectedDate)).toList();

    final upcomingReminders = allReminders.where((r) {
      return r.isEnabled;
    }).take(5).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    tokens.screenPadding + 4,
                    tokens.screenPadding + 4,
                    tokens.screenPadding,
                    8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black,
                          border: Border.all(
                            color: const Color(0xFFD4A373).withOpacity(0.5),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD4A373).withOpacity(0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Image.asset(
                            'assets/images/sana_logo.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Center(
                              child: Text(
                                'S',
                                style: TextStyle(
                                  color: Color(0xFFD4A373),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_getGreeting()} ${_getGreetingEmoji()}',
                              style: context.getTextStyle(
                                fontSize: 24,
                                fontWeight: tokens.headingWeight,
                                color: tokens.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('EEEE, MMMM d').format(_selectedDate),
                              style: context.getTextStyle(
                                fontSize: 14,
                                color: tokens.textSecondary,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          _HeaderIcon(
                            icon: Icons.calendar_month_rounded,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const CalendarScreen()),
                            ),
                          ),
                          const SizedBox(width: 4),
                          _HeaderIcon(
                            icon: Icons.menu_book_rounded,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const NotesScreen()),
                            ),
                          ),
                          const SizedBox(width: 4),
                          _HeaderIcon(
                            icon: Icons.palette_rounded,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const ThemeStudioScreen()),
                            ),
                          ),
                          const SizedBox(width: 4),
                          _HeaderIcon(
                            icon: Icons.settings_rounded,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const SettingsScreen()),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Content
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  tokens.screenPadding,
                  0,
                  tokens.screenPadding,
                  100,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // 1. Prominent Quick Category Navigation Hub (Direct access to Habits, Reminders, Tasks, Journal, Study Notes)
                    _buildQuickHubBar(
                      allHabits.length,
                      allReminders.length,
                      allTasks.length,
                      allNotes.length,
                    ),

                    SizedBox(height: tokens.itemSpacing),

                    // 2. Interactive Week Calendar Strip Selector (Animated & Reactive)
                    _buildWeekStripSelector(now, allTasks, allHabits),

                    SizedBox(height: tokens.itemSpacing),

                    // 3. Glowing Streak Momentum Card (Inspired by reference screenshot 1 & 3)
                    _buildStreakMomentumCard(allHabits, completions),

                    SizedBox(height: tokens.itemSpacing),

                    // 4. Progress Ring Card
                    _buildProgressCard(
                      completedCount: completedCount,
                      totalCount: activeTasks.length,
                      pendingCount: pendingCount,
                      overdueCount: overdueCount,
                      completionPct: completionPct,
                    ),

                    SizedBox(height: tokens.itemSpacing),

                    // 5. Tasks for selected date
                    _buildTodayTasksCard(activeTasks, _selectedDate),

                    SizedBox(height: tokens.itemSpacing),

                    // 6. Habits for selected date (with direct delete & manage options)
                    _buildTodayHabitsCard(
                      scheduledHabits,
                      completions,
                      selectedStr,
                      _selectedDate,
                    ),

                    SizedBox(height: tokens.itemSpacing),

                    // 7. Upcoming Reminders (with direct delete & manage options)
                    _buildUpcomingRemindersCard(upcomingReminders),

                    SizedBox(height: tokens.itemSpacing),

                    // 8. Study Material & Notes Knowledge Hub
                    _buildStudyNotesPreviewCard(allNotes),

                    SizedBox(height: tokens.itemSpacing),

                    // 9. Focus Summary
                    _buildQuickStatsCard(
                      completedCount,
                      pendingCount,
                      scheduledHabits.length,
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickHubBar(
      int habitsCount, int remindersCount, int tasksCount, int notesCount) {
    final tokens = context.themeTokens;
    final categories = [
      {
        'label': 'Study Notes ($notesCount)',
        'icon': Icons.menu_book_rounded,
        'color': tokens.primary,
        'action': () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotesScreen()),
            ),
      },
      {
        'label': 'Habits ($habitsCount)',
        'icon': Icons.local_fire_department_rounded,
        'color': tokens.secondary,
        'action': () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HabitsScreen()),
            ),
      },
      {
        'label': 'Reminders ($remindersCount)',
        'icon': Icons.notifications_active_rounded,
        'color': tokens.warning,
        'action': () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RemindersScreen()),
            ),
      },
      {
        'label': 'Tasks ($tasksCount)',
        'icon': Icons.task_alt_rounded,
        'color': tokens.primary,
        'action': () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TasksScreen()),
            ),
      },
      {
        'label': 'Journal',
        'icon': Icons.auto_stories_rounded,
        'color': tokens.accent,
        'action': () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const JournalScreen()),
            ),
      },
      {
        'label': 'Theme Studio',
        'icon': Icons.palette_rounded,
        'color': tokens.primary,
        'action': () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ThemeStudioScreen()),
            ),
      },
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (ctx, idx) {
          final item = categories[idx];
          final color = item['color'] as Color;
          final icon = item['icon'] as IconData;
          final label = item['label'] as String;
          final action = item['action'] as VoidCallback;

          return Material(
            color: tokens.cardColor,
            borderRadius: BorderRadius.circular(tokens.buttonRadius),
            child: InkWell(
              onTap: action,
              borderRadius: BorderRadius.circular(tokens.buttonRadius),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(tokens.buttonRadius),
                  border: Border.all(color: tokens.borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 16, color: color),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: ctx.getTextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: tokens.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWeekStripSelector(
    DateTime now,
    List<TaskItem> allTasks,
    List<HabitItem> allHabits,
  ) {
    final tokens = context.themeTokens;
    final firstDayOfWeek = now.subtract(Duration(days: now.weekday % 7));
    final weekDays = List.generate(7, (i) => firstDayOfWeek.add(Duration(days: i)));

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: tokens.cardColor,
        borderRadius: BorderRadius.circular(tokens.cardRadius),
        border: Border.all(color: tokens.borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: weekDays.map((d) {
          final isSelected = _selectedDate.year == d.year &&
              _selectedDate.month == d.month &&
              _selectedDate.day == d.day;
          final isToday = now.year == d.year && now.month == d.month && now.day == d.day;
          final hasTasks = allTasks.any((t) => t.appliesToDate(d));
          final hasHabits = allHabits.any((h) => h.appliesToDate(d));
          final dayName = DateFormat('E').format(d); // Sun, Mon...

          return GestureDetector(
            onTap: () => setState(() => _selectedDate = d),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? tokens.primary
                    : (isToday ? tokens.primary.withOpacity(0.12) : Colors.transparent),
                borderRadius: BorderRadius.circular(tokens.buttonRadius),
                border: Border.all(
                  color: isSelected
                      ? tokens.primary
                      : (isToday ? tokens.primary.withOpacity(0.4) : Colors.transparent),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: tokens.primary.withOpacity(0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    dayName,
                    style: TextStyle(
                      fontFamily: tokens.fontFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? (tokens.primary.computeLuminance() > 0.4
                              ? Colors.black
                              : Colors.white)
                          : tokens.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${d.day}',
                    style: TextStyle(
                      fontFamily: tokens.fontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? (tokens.primary.computeLuminance() > 0.4
                              ? Colors.black
                              : Colors.white)
                          : tokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (hasTasks || hasHabits)
                          ? (isSelected
                              ? (tokens.primary.computeLuminance() > 0.4
                                  ? Colors.black
                                  : Colors.white)
                              : tokens.secondary)
                          : Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStreakMomentumCard(
    List<HabitItem> habits,
    List<HabitCompletion> completions,
  ) {
    final tokens = context.themeTokens;
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final yesterdayStr = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1)));

    // Real dynamic streak calculation
    final completedDates = completions
        .where((c) => c.isCompleted)
        .map((c) => c.dateStr)
        .toSet();

    int streakDays = 0;
    if (habits.isNotEmpty && completedDates.isNotEmpty) {
      DateTime cursor;
      if (completedDates.contains(todayStr)) {
        cursor = DateTime(now.year, now.month, now.day);
      } else if (completedDates.contains(yesterdayStr)) {
        cursor = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
      } else {
        cursor = DateTime(now.year, now.month, now.day);
      }

      if (completedDates.contains(DateFormat('yyyy-MM-dd').format(cursor))) {
        for (int i = 0; i < 365; i++) {
          final dStr = DateFormat('yyyy-MM-dd').format(cursor);
          if (completedDates.contains(dStr)) {
            streakDays++;
          } else {
            break;
          }
          cursor = cursor.subtract(const Duration(days: 1));
        }
      }
    }

    final scheduledToday = habits.where((h) => h.appliesToDate(now)).length;
    final completedToday = completions.where((c) => c.dateStr == todayStr && c.isCompleted).length;
    final habitProgress = scheduledToday > 0 ? (completedToday / scheduledToday).clamp(0.0, 1.0) : (habits.isNotEmpty ? 0.0 : 0.0);

    // Build the past 7 days ending today
    final past7Days = List.generate(7, (i) {
      return DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - i));
    });

    String statusBadge;
    String statusSubtitle;
    if (streakDays == 0) {
      statusBadge = 'Start Your Streak!';
      statusSubtitle = 'Complete your scheduled habits today to spark your daily momentum.';
    } else if (streakDays == 1) {
      statusBadge = 'Streak Sparked! 🔥';
      statusSubtitle = 'Great job! Check in again tomorrow to keep the flame alive.';
    } else {
      statusBadge = 'Keep it glowing! 🔥';
      statusSubtitle = 'You are on an active $streakDays-day streak! Consistency creates mastery.';
    }

    return Container(
      padding: EdgeInsets.all(tokens.cardPadding),
      decoration: BoxDecoration(
        color: tokens.cardColor,
        borderRadius: BorderRadius.circular(tokens.cardRadius),
        border: Border.all(
          color: tokens.borderColor,
          width: tokens.isBrutalist ? 2.5 : tokens.borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: tokens.primary.withOpacity(0.12),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    streakDays == 1 ? '1 Day Streak' : '$streakDays Days Streak',
                    style: context.getTextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: tokens.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ScaleTransition(
                    scale: _pulseAnim,
                    child: Text(
                      streakDays > 0 ? '🔥' : '⚡',
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: tokens.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusBadge,
                  style: context.getTextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: tokens.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            statusSubtitle,
            style: context.getTextStyle(
              fontSize: 12,
              color: tokens.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Today\'s Goal: $completedToday / $scheduledToday habits completed',
                style: context.getTextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: tokens.textSecondary,
                ),
              ),
              Text(
                '${(habitProgress * 100).round()}%',
                style: context.getTextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: tokens.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: habitProgress,
              minHeight: 8,
              backgroundColor: tokens.surface,
              valueColor: AlwaysStoppedAnimation<Color>(tokens.primary),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: past7Days.map((d) {
              final dStr = DateFormat('yyyy-MM-dd').format(d);
              final isDone = completedDates.contains(dStr);
              final isToday = d.year == now.year && d.month == now.month && d.day == now.day;
              final dayChar = DateFormat('E').format(d)[0];

              return Tooltip(
                message: '${DateFormat('EEE, MMM d').format(d)}: ${isDone ? 'Completed' : 'Not completed'}',
                child: Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isDone
                            ? tokens.primary
                            : (isToday ? tokens.primary.withOpacity(0.15) : tokens.surface),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isToday
                              ? tokens.primary
                              : (isDone ? tokens.primary : tokens.borderColor),
                          width: isToday ? 2.0 : 1.0,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: isDone
                          ? Icon(
                              Icons.check,
                              size: 16,
                              color: tokens.primary.computeLuminance() > 0.4
                                  ? Colors.black
                                  : Colors.white,
                            )
                          : Text(
                              dayChar,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isToday ? tokens.primary : tokens.textSecondary,
                              ),
                            ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${d.day}',
                      style: TextStyle(
                        fontSize: 9,
                        color: isToday ? tokens.primary : tokens.textSecondary,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard({
    required int completedCount,
    required int totalCount,
    required int pendingCount,
    required int overdueCount,
    required int completionPct,
  }) {
    final tokens = context.themeTokens;
    final progress = totalCount > 0 ? (completedCount / totalCount) : 0.0;

    return DayFlowCard(
      padding: EdgeInsets.all(tokens.cardPadding + 2),
      child: Row(
        children: [
          // Animated Circular Ring
          SizedBox(
            width: 76,
            height: 76,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: value,
                      strokeWidth: 6,
                      strokeCap: StrokeCap.round,
                      backgroundColor: tokens.surface,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(tokens.primary),
                    ),
                    Center(
                      child: Text(
                        '$completionPct%',
                        style: context.getTextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: tokens.textPrimary,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 20),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$completedCount of $totalCount completed',
                  style: context.getTextStyle(
                    fontSize: 16,
                    fontWeight: tokens.headingWeight,
                    color: tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _StatusPill(
                      text: '$pendingCount pending',
                      color: tokens.secondary,
                    ),
                    if (overdueCount > 0)
                      _StatusPill(
                        text: '$overdueCount overdue',
                        color: tokens.error,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayTasksCard(List<TaskItem> tasks, DateTime now) {
    final tokens = context.themeTokens;

    return DayFlowCard(
      padding: EdgeInsets.all(tokens.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.task_alt_rounded,
            iconColor: tokens.primary,
            title: "Tasks (${tasks.length})",
            onManage: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TasksScreen()),
            ),
            manageLabel: 'View All',
            onAdd: () => showDialog(
              context: context,
              builder: (_) => TaskFormDialog(defaultDate: now),
            ),
          ),
          const SizedBox(height: 10),
          if (tasks.isEmpty)
            _EmptyHint(text: 'No tasks for this day — enjoy your flow! ✨')
          else
            ...tasks.take(5).map((task) {
              final isDone = task.isCompletedForDate(now);
              return _TaskRow(
                title: task.title,
                time: task.dueTime,
                isDone: isDone,
                onToggle: () => ref
                    .read(tasksProvider.notifier)
                    .toggleTaskCompletion(task.id, now),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildTodayHabitsCard(
    List<HabitItem> habits,
    List<HabitCompletion> completions,
    String todayStr,
    DateTime now,
  ) {
    final tokens = context.themeTokens;

    return DayFlowCard(
      padding: EdgeInsets.all(tokens.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.loop_rounded,
            iconColor: tokens.secondary,
            title: "Habits (${habits.length})",
            onManage: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HabitsScreen()),
            ),
            manageLabel: 'Manage Habits',
            onAdd: () => showDialog(
              context: context,
              builder: (_) => const HabitFormDialog(),
            ),
          ),
          const SizedBox(height: 10),
          if (habits.isEmpty)
            _EmptyHint(text: 'No habits scheduled for this day')
          else ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: habits.map((habit) {
                final habitColor = Color(habit.colorValue);
                final isDone = completions.any((c) =>
                    c.habitId == habit.id &&
                    c.dateStr == todayStr &&
                    c.isCompleted);

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(tokens.buttonRadius),
                    onLongPress: () => _confirmDeleteHabit(habit),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
                      decoration: BoxDecoration(
                        color: isDone
                            ? habitColor.withOpacity(0.15)
                            : tokens.surface,
                        borderRadius:
                            BorderRadius.circular(tokens.buttonRadius),
                        border: Border.all(
                          color: isDone ? habitColor : tokens.borderColor,
                          width: isDone ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () => ref
                                .read(habitCompletionsProvider.notifier)
                                .toggleHabitCompletion(
                                    habit.id, now, habit.dailyTarget),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  IconData(habit.iconCodePoint,
                                      fontFamily: 'MaterialIcons'),
                                  size: 18,
                                  color: habitColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  habit.name,
                                  style: context.getTextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        isDone ? habitColor : tokens.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  isDone
                                      ? Icons.check_circle_rounded
                                      : Icons.circle_outlined,
                                  size: 18,
                                  color: isDone
                                      ? habitColor
                                      : tokens.textSecondary.withOpacity(0.4),
                                ),
                              ],
                            ),
                          ),
                          // 3-dots Menu for Edit / Delete / Toggle
                          PopupMenuButton<String>(
                            icon: Icon(
                              Icons.more_vert,
                              size: 16,
                              color: tokens.textSecondary,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 120),
                            color: tokens.cardColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: tokens.borderColor),
                            ),
                            onSelected: (val) {
                              if (val == 'toggle') {
                                ref
                                    .read(habitCompletionsProvider.notifier)
                                    .toggleHabitCompletion(
                                        habit.id, now, habit.dailyTarget);
                              } else if (val == 'edit') {
                                showDialog(
                                  context: context,
                                  builder: (_) =>
                                      HabitFormDialog(initialHabit: habit),
                                );
                              } else if (val == 'delete') {
                                _confirmDeleteHabit(habit);
                              }
                            },
                            itemBuilder: (ctx) => [
                              PopupMenuItem(
                                value: 'toggle',
                                child: Text(
                                  isDone ? 'Mark Incomplete' : 'Mark Done',
                                  style: ctx.getTextStyle(
                                      fontSize: 12,
                                      color: tokens.textPrimary),
                                ),
                              ),
                              PopupMenuItem(
                                value: 'edit',
                                child: Text(
                                  'Edit Habit',
                                  style: ctx.getTextStyle(
                                      fontSize: 12,
                                      color: tokens.textPrimary),
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline,
                                        size: 16, color: tokens.error),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Delete Habit',
                                      style: ctx.getTextStyle(
                                        fontSize: 12,
                                        color: tokens.error,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 6),
            Text(
              '💡 Tip: Tap to toggle • Tap ⋮ or long-press to delete habit',
              style: context.getTextStyle(
                fontSize: 11,
                color: tokens.textSecondary.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUpcomingRemindersCard(List<ReminderItem> reminders) {
    final tokens = context.themeTokens;

    return DayFlowCard(
      padding: EdgeInsets.all(tokens.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.notifications_active_rounded,
            iconColor: tokens.warning,
            title: 'Upcoming Reminders',
            onManage: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RemindersScreen()),
            ),
            manageLabel: 'Manage',
            onAdd: () => showDialog(
              context: context,
              builder: (_) => const ReminderFormDialog(),
            ),
          ),
          const SizedBox(height: 10),
          if (reminders.isEmpty)
            _EmptyHint(text: 'No upcoming reminders')
          else
            ...reminders.map((rem) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: tokens.warning.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        DateFormat('h:mm a').format(rem.dateTime),
                        style: context.getTextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: tokens.warning,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rem.title,
                            style: context.getTextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: tokens.textPrimary,
                            ),
                          ),
                          if (rem.repeat != ReminderRepeat.none)
                            Text(
                              'Repeats: ${rem.repeat.name}',
                              style: context.getTextStyle(
                                fontSize: 11,
                                color: tokens.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline,
                          size: 19, color: tokens.error),
                      tooltip: 'Delete Reminder',
                      onPressed: () => _confirmDeleteReminder(rem),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildStudyNotesPreviewCard(List<StudyNoteItem> notes) {
    final tokens = context.themeTokens;
    final displayNotes = notes.take(3).toList();

    return DayFlowCard(
      padding: EdgeInsets.all(tokens.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.menu_book_rounded,
            iconColor: tokens.primary,
            title: 'Study Material & Notes (${notes.length})',
            onManage: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotesScreen()),
            ),
            manageLabel: 'View All',
            onAdd: () => showDialog(
              context: context,
              builder: (_) => const NoteFormDialog(),
            ),
          ),
          const SizedBox(height: 10),
          if (notes.isEmpty)
            _EmptyHint(
                text: 'No study notes or links yet. Tap + to add study material.')
          else
            ...displayNotes.map((note) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: tokens.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: note.isPinned
                        ? tokens.primary.withOpacity(0.5)
                        : tokens.borderColor,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: tokens.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            note.category,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: tokens.primary,
                            ),
                          ),
                        ),
                        if (note.isPinned) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.push_pin, size: 12, color: tokens.warning),
                        ],
                        const Spacer(),
                        InkWell(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const NotesScreen()),
                          ),
                          child: Text(
                            'Open Notes →',
                            style: TextStyle(
                              fontSize: 11,
                              color: tokens.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      note.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: tokens.textPrimary,
                      ),
                    ),
                    if (note.links.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: note.links.take(2).map((link) {
                          return InkWell(
                            onTap: () =>
                                UrlLauncherHelper.openUrl(context, link.url),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: tokens.cardColor,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: tokens.borderColor),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.link,
                                      size: 12, color: tokens.primary),
                                  const SizedBox(width: 4),
                                  ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 160),
                                    child: Text(
                                      link.label,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: tokens.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.open_in_new,
                                      size: 10, color: tokens.primary),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildQuickStatsCard(int done, int pending, int habits) {
    final tokens = context.themeTokens;

    return DayFlowCard(
      padding: EdgeInsets.all(tokens.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Focus Summary',
            style: context.getTextStyle(
              fontSize: 16,
              fontWeight: tokens.headingWeight,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _StatColumn(label: 'Completed', value: '$done', color: tokens.primary)),
              Container(width: 1, height: 36, color: tokens.borderColor),
              Expanded(child: _StatColumn(label: 'Pending', value: '$pending', color: tokens.secondary)),
              Container(width: 1, height: 36, color: tokens.borderColor),
              Expanded(child: _StatColumn(label: 'Habits', value: '$habits', color: tokens.accent)),
            ],
          ),
        ],
      ),
    );
  }
}

// ===== Reusable Mini Widgets =====

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tokens = context.themeTokens;
    return Material(
      color: tokens.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20, color: tokens.textSecondary),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback? onAdd;
  final VoidCallback? onManage;
  final String? manageLabel;

  const _SectionHeader({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.onAdd,
    this.onManage,
    this.manageLabel,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.themeTokens;
    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: context.getTextStyle(
              fontSize: 16,
              fontWeight: tokens.headingWeight,
              color: tokens.textPrimary,
            ),
          ),
        ),
        if (onManage != null)
          TextButton(
            onPressed: onManage,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              visualDensity: VisualDensity.compact,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  manageLabel ?? 'Manage',
                  style: context.getTextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: tokens.primary,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(Icons.arrow_forward_ios_rounded, size: 10, color: tokens.primary),
              ],
            ),
          ),
        if (onAdd != null)
          IconButton(
            icon: Icon(Icons.add_rounded, size: 20, color: iconColor),
            onPressed: onAdd,
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    final tokens = context.themeTokens;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          text,
          style: context.getTextStyle(
            fontSize: 13,
            color: tokens.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String text;
  final Color color;
  const _StatusPill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  final String title;
  final String? time;
  final bool isDone;
  final VoidCallback onToggle;

  const _TaskRow({
    required this.title,
    this.time,
    required this.isDone,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.themeTokens;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isDone ? tokens.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isDone ? tokens.primary : tokens.borderColor,
                  width: 1.5,
                ),
              ),
              child: isDone
                  ? Icon(Icons.check, size: 14,
                      color: tokens.primary.computeLuminance() > 0.4
                          ? Colors.black
                          : Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: context.getTextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDone ? tokens.textSecondary : tokens.textPrimary,
                decoration: isDone ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          if (time != null)
            Text(
              time!,
              style: context.getTextStyle(
                fontSize: 12,
                color: tokens.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatColumn(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final tokens = context.themeTokens;
    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: double.tryParse(value) ?? 0),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOut,
          builder: (context, val, _) {
            return Text(
              val.toInt().toString(),
              style: context.getTextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            );
          },
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: context.getTextStyle(
            fontSize: 12,
            color: tokens.textSecondary,
          ),
        ),
      ],
    );
  }
}
