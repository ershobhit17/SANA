import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/dayflow_theme_context.dart';
import '../../../models/task_model.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/dayflow_button.dart';
import '../../../shared/widgets/dayflow_chip.dart';
import '../../../shared/widgets/dayflow_text_field.dart';

class TaskFormDialog extends ConsumerStatefulWidget {
  final TaskItem? initialTask;
  final DateTime? defaultDate;

  const TaskFormDialog({
    super.key,
    this.initialTask,
    this.defaultDate,
  });

  @override
  ConsumerState<TaskFormDialog> createState() => _TaskFormDialogState();
}

class _TaskFormDialogState extends ConsumerState<TaskFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _subtaskController;

  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  TaskPriority _priority = TaskPriority.medium;
  String _category = 'Work';
  TaskRecurrence _recurrence = TaskRecurrence.none;
  List<int> _recurringDays = [1, 2, 3, 4, 5]; // Mon-Fri default
  List<Subtask> _subtasks = [];

  final List<String> _commonCategories = [
    'Work',
    'Personal',
    'Health',
    'Study',
    'Finance',
    'Home',
  ];

  @override
  void initState() {
    super.initState();
    final task = widget.initialTask;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descController = TextEditingController(text: task?.description ?? '');
    _subtaskController = TextEditingController();

    if (task != null) {
      _dueDate = task.dueDate;
      if (task.dueTime != null) {
        try {
          final parts = task.dueTime!.split(':');
          final hour = int.parse(parts[0]);
          final minParts = parts[1].split(' ');
          final minute = int.parse(minParts[0]);
          _dueTime = TimeOfDay(hour: hour, minute: minute);
        } catch (_) {}
      }
      _priority = task.priority;
      _category = task.category;
      _recurrence = task.recurrence;
      _recurringDays = task.recurringDays ?? [1, 2, 3, 4, 5];
      _subtasks = List.from(task.subtasks);
    } else {
      _dueDate = widget.defaultDate ?? DateTime.now();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _subtaskController.dispose();
    super.dispose();
  }

  void _addSubtask() {
    final text = _subtaskController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _subtasks.add(
        Subtask(
          id: const Uuid().v4(),
          title: text,
          isCompleted: false,
        ),
      );
      _subtaskController.clear();
    });
  }

  void _removeSubtask(String id) {
    setState(() {
      _subtasks.removeWhere((s) => s.id == id);
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _dueTime = picked);
    }
  }

  void _saveTask() {
    if (!_formKey.currentState!.validate()) return;

    final dueTimeStr = _dueTime != null
        ? '${_dueTime!.hour.toString().padLeft(2, '0')}:${_dueTime!.minute.toString().padLeft(2, '0')}'
        : null;

    final now = DateTime.now();
    if (widget.initialTask != null) {
      final updated = widget.initialTask!.copyWith(
        title: _titleController.text.trim(),
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        dueDate: _dueDate,
        dueTime: dueTimeStr,
        priority: _priority,
        category: _category,
        recurrence: _recurrence,
        recurringDays:
            _recurrence == TaskRecurrence.custom ? _recurringDays : null,
        subtasks: _subtasks,
        updatedAt: now,
      );
      ref.read(tasksProvider.notifier).updateTask(updated);
    } else {
      final newTask = TaskItem(
        id: const Uuid().v4(),
        title: _titleController.text.trim(),
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        dueDate: _dueDate,
        dueTime: dueTimeStr,
        priority: _priority,
        category: _category,
        recurrence: _recurrence,
        recurringDays:
            _recurrence == TaskRecurrence.custom ? _recurringDays : null,
        subtasks: _subtasks,
        createdAt: now,
        updatedAt: now,
      );
      ref.read(tasksProvider.notifier).createTask(newTask);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.themeTokens;
    final isEditing = widget.initialTask != null;

    final weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Dialog(
      backgroundColor: tokens.cardColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.cardRadius),
        side: BorderSide(
          color: tokens.borderColor,
          width: tokens.borderWidth,
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 680),
        child: Padding(
          padding: EdgeInsets.all(tokens.cardPadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: tokens.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isEditing ? Icons.edit_note : Icons.add_task,
                        color: tokens.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isEditing ? 'Edit Task' : 'Create New Task',
                        style: context.getTextStyle(
                          fontSize: 18,
                          fontWeight: tokens.headingWeight,
                          color: tokens.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: tokens.textSecondary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Form Scrollable Area
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        DayFlowTextField(
                          controller: _titleController,
                          labelText: 'Task Title *',
                          hintText: 'What needs to be done?',
                          autofocus: !isEditing,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Please enter a task title'
                              : null,
                        ),
                        const SizedBox(height: 14),

                        // Description
                        DayFlowTextField(
                          controller: _descController,
                          labelText: 'Description (Optional)',
                          hintText: 'Add context, links, or notes...',
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),

                        // Priority Selector
                        Text(
                          'Priority',
                          style: context.getTextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: tokens.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: DayFlowChip(
                                label: 'Low',
                                icon: Icons.arrow_downward,
                                color: tokens.success,
                                isSelected: _priority == TaskPriority.low,
                                onTap: () => setState(
                                    () => _priority = TaskPriority.low),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DayFlowChip(
                                label: 'Medium',
                                icon: Icons.remove,
                                color: tokens.warning,
                                isSelected: _priority == TaskPriority.medium,
                                onTap: () => setState(
                                    () => _priority = TaskPriority.medium),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DayFlowChip(
                                label: 'High',
                                icon: Icons.priority_high,
                                color: tokens.error,
                                isSelected: _priority == TaskPriority.high,
                                onTap: () => setState(
                                    () => _priority = TaskPriority.high),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Category Selector
                        Text(
                          'Category',
                          style: context.getTextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: tokens.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _commonCategories.map((cat) {
                            return DayFlowChip(
                              label: cat,
                              isSelected: _category == cat,
                              onTap: () => setState(() => _category = cat),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),

                        // Date & Time Picker
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: _pickDate,
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: tokens.surface,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: tokens.borderColor),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.calendar_today,
                                          size: 16, color: tokens.primary),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _dueDate != null
                                              ? DateFormat('EEE, MMM d')
                                                  .format(_dueDate!)
                                              : 'Set Due Date',
                                          style: context.getTextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: tokens.textPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: InkWell(
                                onTap: _pickTime,
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: tokens.surface,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: tokens.borderColor),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.access_time,
                                          size: 16, color: tokens.primary),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _dueTime != null
                                              ? _dueTime!.format(context)
                                              : 'Set Time',
                                          style: context.getTextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: tokens.textPrimary,
                                          ),
                                        ),
                                      ),
                                      if (_dueTime != null)
                                        InkWell(
                                          onTap: () =>
                                              setState(() => _dueTime = null),
                                          child: Icon(Icons.clear,
                                              size: 14,
                                              color: tokens.textSecondary),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Recurrence Selection
                        Text(
                          'Recurrence',
                          style: context.getTextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: tokens.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            DayFlowChip(
                              label: 'One-time',
                              isSelected: _recurrence == TaskRecurrence.none,
                              onTap: () => setState(
                                  () => _recurrence = TaskRecurrence.none),
                            ),
                            DayFlowChip(
                              label: 'Daily',
                              isSelected: _recurrence == TaskRecurrence.daily,
                              onTap: () => setState(
                                  () => _recurrence = TaskRecurrence.daily),
                            ),
                            DayFlowChip(
                              label: 'Weekly',
                              isSelected: _recurrence == TaskRecurrence.weekly,
                              onTap: () => setState(
                                  () => _recurrence = TaskRecurrence.weekly),
                            ),
                            DayFlowChip(
                              label: 'Custom Days',
                              isSelected: _recurrence == TaskRecurrence.custom,
                              onTap: () => setState(
                                  () => _recurrence = TaskRecurrence.custom),
                            ),
                          ],
                        ),

                        // Custom Weekday Checkers
                        if (_recurrence == TaskRecurrence.custom) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            children: List.generate(7, (index) {
                              final dayNum = index + 1; // 1 = Mon, 7 = Sun
                              final isSelected =
                                  _recurringDays.contains(dayNum);
                              return DayFlowChip(
                                label: weekdayNames[index],
                                isSelected: isSelected,
                                onTap: () {
                                  setState(() {
                                    if (isSelected) {
                                      _recurringDays.remove(dayNum);
                                    } else {
                                      _recurringDays.add(dayNum);
                                    }
                                  });
                                },
                              );
                            }),
                          ),
                        ],
                        const SizedBox(height: 18),

                        // Subtasks / Checklist
                        Text(
                          'Checklist / Subtasks (${_subtasks.length})',
                          style: context.getTextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: tokens.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: DayFlowTextField(
                                controller: _subtaskController,
                                hintText: 'Add checklist step...',
                              ),
                            ),
                            const SizedBox(width: 8),
                            DayFlowButton(
                              label: 'Add',
                              icon: Icons.add,
                              variant: DayFlowButtonVariant.secondary,
                              onPressed: _addSubtask,
                            ),
                          ],
                        ),
                        if (_subtasks.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _subtasks.length,
                            itemBuilder: (context, index) {
                              final sub = _subtasks[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline,
                                      size: 16,
                                      color: tokens.textSecondary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        sub.title,
                                        style: context.getTextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: tokens.textPrimary,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 16),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      color: tokens.error,
                                      onPressed: () => _removeSubtask(sub.id),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    DayFlowButton(
                      label: 'Cancel',
                      variant: DayFlowButtonVariant.outline,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 10),
                    DayFlowButton(
                      label: isEditing ? 'Save Changes' : 'Create Task',
                      icon: isEditing ? Icons.check : Icons.add,
                      variant: DayFlowButtonVariant.primary,
                      onPressed: _saveTask,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
