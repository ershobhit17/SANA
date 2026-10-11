import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/dayflow_theme_context.dart';
import '../../../models/task_model.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/dayflow_card.dart';
import '../../../shared/widgets/dayflow_chip.dart';
import '../../../shared/widgets/dayflow_empty_state.dart';
import '../../../shared/widgets/dayflow_text_field.dart';
import 'task_form_dialog.dart';

enum TaskTabFilter { all, today, upcoming, completed, overdue }

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  TaskTabFilter _activeTab = TaskTabFilter.today;
  String _searchQuery = '';
  String? _selectedCategory;
  TaskPriority? _selectedPriority;
  final TextEditingController _searchController = TextEditingController();

  final Set<String> _expandedTaskIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openCreateTaskDialog() {
    showDialog(
      context: context,
      builder: (_) => const TaskFormDialog(),
    );
  }

  void _openEditTaskDialog(TaskItem task) {
    showDialog(
      context: context,
      builder: (_) => TaskFormDialog(initialTask: task),
    );
  }

  Future<void> _rescheduleTask(TaskItem task) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: task.dueDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
    );
    if (pickedDate != null && mounted) {
      ref.read(tasksProvider.notifier).rescheduleTask(
            task.id,
            pickedDate,
            task.dueTime,
          );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Task rescheduled to ${DateFormat('MMM d, y').format(pickedDate)}',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<bool> _confirmDeleteTask(TaskItem task) async {
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
              'Delete Task',
              style: ctx.getTextStyle(
                fontSize: 18,
                fontWeight: tokens.headingWeight,
                color: tokens.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${task.title}"? This action cannot be undone.',
          style: ctx.getTextStyle(
            fontSize: 14,
            color: tokens.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: ctx.getTextStyle(color: tokens.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
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

    if (res == true && mounted) {
      final deletedTask = task;
      ref.read(tasksProvider.notifier).deleteTask(task.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Task "${task.title}" deleted'),
          action: SnackBarAction(
            label: 'UNDO',
            textColor: tokens.primary,
            onPressed: () {
              ref.read(tasksProvider.notifier).createTask(deletedTask);
            },
          ),
        ),
      );
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.themeTokens;
    final allTasks = ref.watch(tasksProvider);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Filter tasks based on search, category, priority, and tab
    final filteredTasks = allTasks.where((task) {
      // Search
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesTitle = task.title.toLowerCase().contains(q);
        final matchesDesc =
            task.description?.toLowerCase().contains(q) ?? false;
        if (!matchesTitle && !matchesDesc) return false;
      }

      // Category filter
      if (_selectedCategory != null && task.category != _selectedCategory) {
        return false;
      }

      // Priority filter
      if (_selectedPriority != null && task.priority != _selectedPriority) {
        return false;
      }

      final isCompletedToday = task.isCompletedForDate(now);

      // Tab filter
      switch (_activeTab) {
        case TaskTabFilter.all:
          return true;
        case TaskTabFilter.today:
          return task.appliesToDate(now);
        case TaskTabFilter.upcoming:
          if (task.isRecurring) return true;
          if (task.dueDate == null) return false;
          final due = DateTime(
              task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
          return due.isAfter(today) && !task.isCompleted;
        case TaskTabFilter.completed:
          return isCompletedToday || task.isCompleted;
        case TaskTabFilter.overdue:
          if (task.isRecurring) return false;
          if (task.dueDate == null || task.isCompleted) return false;
          final due = DateTime(
              task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
          return due.isBefore(today);
      }
    }).toList();

    // Collect all distinct categories for chips
    final categories = allTasks.map((t) => t.category).toSet().toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // Header Bar
            Padding(
              padding: EdgeInsets.fromLTRB(
                tokens.screenPadding,
                tokens.screenPadding,
                tokens.screenPadding,
                8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Task Management',
                          style: context.getTextStyle(
                            fontSize: 22,
                            fontWeight: tokens.headingWeight,
                            color: tokens.textPrimary,
                          ),
                        ),
                        Text(
                          '${allTasks.where((t) => !t.isCompletedForDate(now)).length} pending tasks',
                          style: context.getTextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: tokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
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
                    onPressed: _openCreateTaskDialog,
                    tooltip: 'Add Task',
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: tokens.screenPadding,
                vertical: 4,
              ),
              child: DayFlowTextField(
                controller: _searchController,
                hintText: 'Search tasks by title or notes...',
                prefixIcon: Icon(Icons.search, color: tokens.textSecondary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        color: tokens.textSecondary,
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
              ),
            ),

            const SizedBox(height: 6),

            // Tabs Row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: tokens.screenPadding),
              child: Row(
                children: [
                  _buildTabChip('Today', TaskTabFilter.today),
                  const SizedBox(width: 8),
                  _buildTabChip('Upcoming', TaskTabFilter.upcoming),
                  const SizedBox(width: 8),
                  _buildTabChip('Overdue', TaskTabFilter.overdue),
                  const SizedBox(width: 8),
                  _buildTabChip('Completed', TaskTabFilter.completed),
                  const SizedBox(width: 8),
                  _buildTabChip('All', TaskTabFilter.all),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // Category & Priority Filter Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: tokens.screenPadding),
              child: Row(
                children: [
                  DayFlowChip(
                    label: 'All Categories',
                    isSelected: _selectedCategory == null,
                    onTap: () => setState(() => _selectedCategory = null),
                  ),
                  const SizedBox(width: 6),
                  ...categories.map((cat) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: DayFlowChip(
                        label: cat,
                        isSelected: _selectedCategory == cat,
                        onTap: () => setState(() {
                          _selectedCategory =
                              _selectedCategory == cat ? null : cat;
                        }),
                      ),
                    );
                  }),
                  const SizedBox(width: 6),
                  // Priority filter chips
                  DayFlowChip(
                    label: 'High Priority',
                    icon: Icons.priority_high,
                    color: tokens.error,
                    isSelected: _selectedPriority == TaskPriority.high,
                    onTap: () => setState(() {
                      _selectedPriority =
                          _selectedPriority == TaskPriority.high
                              ? null
                              : TaskPriority.high;
                    }),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Task List View
            Expanded(
              child: filteredTasks.isEmpty
                  ? DayFlowEmptyState(
                      icon: Icons.checklist,
                      title: _searchQuery.isNotEmpty
                          ? 'No matching tasks'
                          : 'No tasks in this section',
                      message: _searchQuery.isNotEmpty
                          ? 'Try adjusting your search or filters.'
                          : 'Add your first task to stay organized and clear.',
                      actionLabel: 'Add Task',
                      onAction: _openCreateTaskDialog,
                    )
                  : ListView.builder(
                      padding: EdgeInsets.fromLTRB(
                        tokens.screenPadding,
                        4,
                        tokens.screenPadding,
                        80,
                      ),
                      itemCount: filteredTasks.length,
                      itemBuilder: (context, index) {
                        final task = filteredTasks[index];
                        final isDone = task.isCompletedForDate(now);
                        final isExpanded = _expandedTaskIds.contains(task.id);

                        return _buildTaskCard(
                          task: task,
                          isDone: isDone,
                          isExpanded: isExpanded,
                          now: now,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabChip(String label, TaskTabFilter tab) {
    final isSelected = _activeTab == tab;
    return DayFlowChip(
      label: label,
      isSelected: isSelected,
      onTap: () => setState(() => _activeTab = tab),
    );
  }

  Widget _buildTaskCard({
    required TaskItem task,
    required bool isDone,
    required bool isExpanded,
    required DateTime now,
  }) {
    final tokens = context.themeTokens;

    Color priorityColor;
    String priorityText;
    switch (task.priority) {
      case TaskPriority.high:
        priorityColor = tokens.error;
        priorityText = 'HIGH';
        break;
      case TaskPriority.medium:
        priorityColor = tokens.warning;
        priorityText = 'MED';
        break;
      case TaskPriority.low:
        priorityColor = tokens.success;
        priorityText = 'LOW';
        break;
    }

    final hasSubtasks = task.subtasks.isNotEmpty;
    final completedSubCount = task.subtasks.where((s) => s.isCompleted).length;

    return Padding(
      padding: EdgeInsets.only(bottom: tokens.itemSpacing),
      child: Dismissible(
        key: Key('task_${task.id}'),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) => _confirmDeleteTask(task),
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
          onTap: () => _openEditTaskDialog(task),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Completion Checkbox with Spring Animation & Haptic
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ref
                        .read(tasksProvider.notifier)
                        .toggleTaskCompletion(task.id, now);
                  },
                  child: AnimatedScale(
                    scale: isDone ? 1.05 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutBack,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 24,
                      height: 24,
                      margin: const EdgeInsets.only(top: 2, right: 12),
                      decoration: BoxDecoration(
                        color: isDone ? tokens.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isDone ? tokens.primary : tokens.borderColor,
                          width: 1.8,
                        ),
                      ),
                      child: isDone
                          ? Icon(
                              Icons.check,
                              size: 16,
                              color: tokens.primary.computeLuminance() > 0.4
                                  ? Colors.black
                                  : Colors.white,
                            )
                          : null,
                    ),
                  ),
                ),

                // Title and Metadata
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: context.getTextStyle(
                          fontSize: 15,
                          fontWeight: tokens.headingWeight,
                          color: isDone
                              ? tokens.textSecondary
                              : tokens.textPrimary,
                          decoration: isDone
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      if (task.description != null &&
                          task.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          task.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.getTextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: tokens.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Popup Options Menu
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    size: 18,
                    color: tokens.textSecondary,
                  ),
                  color: tokens.cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: tokens.borderColor),
                  ),
                  onSelected: (val) {
                    if (val == 'edit') {
                      _openEditTaskDialog(task);
                    } else if (val == 'reschedule') {
                      _rescheduleTask(task);
                    } else if (val == 'delete') {
                      _confirmDeleteTask(task);
                    }
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 16, color: tokens.textPrimary),
                          const SizedBox(width: 8),
                          Text('Edit',
                              style: ctx.getTextStyle(color: tokens.textPrimary)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'reschedule',
                      child: Row(
                        children: [
                          Icon(Icons.event, size: 16, color: tokens.textPrimary),
                          const SizedBox(width: 8),
                          Text('Reschedule',
                              style: ctx.getTextStyle(color: tokens.textPrimary)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline,
                              size: 16, color: tokens.error),
                          const SizedBox(width: 8),
                          Text('Delete',
                              style: ctx.getTextStyle(color: tokens.error)),
                        ],
                      ),
                    ),
                  ],
                ),

                // Direct Delete Button
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    size: 19,
                    color: tokens.textSecondary.withOpacity(0.7),
                  ),
                  tooltip: 'Delete Task',
                  onPressed: () => _confirmDeleteTask(task),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Metadata Badges (Category, Priority, Recurrence, Due Date)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Category
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: tokens.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: tokens.borderColor, width: 0.8),
                  ),
                  child: Text(
                    task.category,
                    style: context.getTextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: tokens.textSecondary,
                    ),
                  ),
                ),

                // Priority Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: priorityColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        priorityText,
                        style: context.getTextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: priorityColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // Recurring Badge
                if (task.isRecurring)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: tokens.secondary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.repeat, size: 12, color: tokens.secondary),
                        const SizedBox(width: 4),
                        Text(
                          task.recurrence.name.toUpperCase(),
                          style: context.getTextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: tokens.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Due Date & Time
                if (task.dueDate != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today,
                          size: 12, color: tokens.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM d').format(task.dueDate!),
                        style: context.getTextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: tokens.textSecondary,
                        ),
                      ),
                      if (task.dueTime != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          '• ${task.dueTime}',
                          style: context.getTextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: tokens.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),

                // Subtask Counter Pill
                if (hasSubtasks)
                  InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () {
                      setState(() {
                        if (isExpanded) {
                          _expandedTaskIds.remove(task.id);
                        } else {
                          _expandedTaskIds.add(task.id);
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: tokens.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.checklist,
                              size: 13, color: tokens.primary),
                          const SizedBox(width: 4),
                          Text(
                            '$completedSubCount/${task.subtasks.length}',
                            style: context.getTextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: tokens.primary,
                            ),
                          ),
                          Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            size: 14,
                            color: tokens.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // Expandable Checklist Section
            if (hasSubtasks && isExpanded) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: tokens.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: tokens.borderColor, width: 0.6),
                ),
                child: Column(
                  children: task.subtasks.map((st) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () {
                              ref
                                  .read(tasksProvider.notifier)
                                  .toggleSubtask(task.id, st.id);
                            },
                            child: Icon(
                              st.isCompleted
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank,
                              size: 18,
                              color: st.isCompleted
                                  ? tokens.primary
                                  : tokens.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              st.title,
                              style: context.getTextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: st.isCompleted
                                    ? tokens.textSecondary
                                    : tokens.textPrimary,
                                decoration: st.isCompleted
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
}
