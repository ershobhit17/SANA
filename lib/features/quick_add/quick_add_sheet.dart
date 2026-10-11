import 'package:flutter/material.dart';
import '../../core/theme/dayflow_theme_context.dart';
import '../tasks/presentation/task_form_dialog.dart';
import '../habits/presentation/habit_form_dialog.dart';
import '../reminders/presentation/reminder_form_dialog.dart';
import '../journal/presentation/journal_editor_screen.dart';
import '../notes/presentation/note_form_dialog.dart';

class QuickAddSheet extends StatelessWidget {
  const QuickAddSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const QuickAddSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.themeTokens;

    return Container(
      padding: EdgeInsets.fromLTRB(
        tokens.screenPadding,
        16,
        tokens.screenPadding,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: tokens.cardColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(tokens.cardRadius),
        ),
        border: Border(
          top: BorderSide(color: tokens.borderColor, width: tokens.borderWidth),
          left: BorderSide(color: tokens.borderColor, width: tokens.borderWidth),
          right: BorderSide(color: tokens.borderColor, width: tokens.borderWidth),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: tokens.textSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Quick Add to DayFlow',
            style: context.getTextStyle(
              fontSize: 18,
              fontWeight: tokens.headingWeight,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Capture what\'s on your mind instantly',
            style: context.getTextStyle(
              fontSize: 13,
              color: tokens.textSecondary,
            ),
          ),
          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _buildActionTile(
                  context: context,
                  title: 'Task',
                  subtitle: 'To-do item',
                  icon: Icons.check_circle_outline,
                  color: tokens.primary,
                  onTap: () {
                    Navigator.of(context).pop();
                    showDialog(
                      context: context,
                      builder: (_) => const TaskFormDialog(),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionTile(
                  context: context,
                  title: 'Habit',
                  subtitle: 'Routine',
                  icon: Icons.repeat,
                  color: tokens.secondary,
                  onTap: () {
                    Navigator.of(context).pop();
                    showDialog(
                      context: context,
                      builder: (_) => const HabitFormDialog(),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionTile(
                  context: context,
                  title: 'Journal',
                  subtitle: 'Daily thought',
                  icon: Icons.edit_note,
                  color: tokens.accent,
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const JournalEditorScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionTile(
                  context: context,
                  title: 'Reminder',
                  subtitle: 'Scheduled alert',
                  icon: Icons.alarm,
                  color: tokens.warning,
                  onTap: () {
                    Navigator.of(context).pop();
                    showDialog(
                      context: context,
                      builder: (_) => const ReminderFormDialog(),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildActionTile(
            context: context,
            title: 'Study Material & Note',
            subtitle: 'Save links, video lectures, and revision notes',
            icon: Icons.menu_book_rounded,
            color: tokens.primary,
            onTap: () {
              Navigator.of(context).pop();
              showDialog(
                context: context,
                builder: (_) => const NoteFormDialog(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final tokens = context.themeTokens;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: tokens.borderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.getTextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: tokens.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: context.getTextStyle(
                    fontSize: 11,
                    color: tokens.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
