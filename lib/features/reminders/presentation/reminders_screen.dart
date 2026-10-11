import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/services/notification_service.dart';
import '../../../core/theme/dayflow_theme_context.dart';
import '../../../models/reminder_model.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/dayflow_button.dart';
import '../../../shared/widgets/dayflow_card.dart';
import '../../../shared/widgets/dayflow_empty_state.dart';
import 'reminder_form_dialog.dart';

class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key});

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen> {
  void _openCreateReminderDialog() {
    showDialog(
      context: context,
      builder: (_) => const ReminderFormDialog(),
    );
  }

  void _openEditReminderDialog(ReminderItem reminder) {
    showDialog(
      context: context,
      builder: (_) => ReminderFormDialog(initialReminder: reminder),
    );
  }

  Future<void> _requestNotificationPermission() async {
    final granted =
        await NotificationService.instance.requestPermissions();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            granted
                ? 'Notification permissions enabled!'
                : 'Permissions were not granted or not required on this platform.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _sendTestNotification() async {
    await NotificationService.instance.showInstantNotification(
      id: 999,
      title: 'DayFlow Reminder Test',
      body: 'Your device notification channel is active and functioning properly!',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test notification triggered on your device!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.themeTokens;
    final reminders = ref.watch(remindersProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Reminders',
          style: context.getTextStyle(
            fontSize: 20,
            fontWeight: tokens.headingWeight,
            color: tokens.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined),
            tooltip: 'Send Test Notification',
            onPressed: _sendTestNotification,
          ),
          IconButton(
            icon: const Icon(Icons.security),
            tooltip: 'Check Permissions',
            onPressed: _requestNotificationPermission,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: tokens.primary,
        foregroundColor: tokens.primary.computeLuminance() > 0.4
            ? Colors.black
            : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.buttonRadius),
          side: tokens.isBrutalist
              ? const BorderSide(color: Colors.black, width: 2)
              : BorderSide.none,
        ),
        onPressed: _openCreateReminderDialog,
        child: const Icon(Icons.add_alert),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Permission & Test Banner
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: tokens.screenPadding,
                vertical: 6,
              ),
              child: DayFlowCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: tokens.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Actual device notifications are scheduled via system channels.',
                        style: context.getTextStyle(
                          fontSize: 12,
                          color: tokens.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    DayFlowButton(
                      label: 'Test',
                      icon: Icons.send,
                      variant: DayFlowButtonVariant.secondary,
                      onPressed: _sendTestNotification,
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: reminders.isEmpty
                  ? DayFlowEmptyState(
                      icon: Icons.notifications_none,
                      title: 'No reminders yet',
                      message:
                          'Set reminders for daily habits, tasks, or important times so you never lose flow.',
                      actionLabel: 'Set Reminder',
                      onAction: _openCreateReminderDialog,
                    )
                  : ListView.builder(
                      padding: EdgeInsets.fromLTRB(
                        tokens.screenPadding,
                        8,
                        tokens.screenPadding,
                        80,
                      ),
                      itemCount: reminders.length,
                      itemBuilder: (context, index) {
                        final rem = reminders[index];
                        return _buildReminderCard(rem);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmDeleteReminder(ReminderItem rem) async {
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
            Icon(Icons.warning_amber_rounded, color: tokens.error),
            const SizedBox(width: 8),
            Text(
              'Delete Reminder?',
              style: ctx.getTextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: tokens.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${rem.title}"? This will cancel its scheduled device notifications and remove it permanently.',
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
              'Delete Reminder',
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

  Widget _buildReminderCard(ReminderItem rem) {
    final tokens = context.themeTokens;
    final timeStr = DateFormat('h:mm a').format(rem.dateTime);
    final dateStr = DateFormat('EEE, MMM d').format(rem.dateTime);

    String repeatLabel;
    switch (rem.repeat) {
      case ReminderRepeat.none:
        repeatLabel = 'One-time';
        break;
      case ReminderRepeat.daily:
        repeatLabel = 'Daily';
        break;
      case ReminderRepeat.weekly:
        repeatLabel = 'Weekly';
        break;
      case ReminderRepeat.weekdays:
        repeatLabel = 'Mon - Fri';
        break;
      case ReminderRepeat.custom:
        repeatLabel = 'Custom Days';
        break;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: tokens.itemSpacing),
      child: Dismissible(
        key: ValueKey(rem.id),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) => _confirmDeleteReminder(rem),
        onDismissed: (_) {
          ref.read(remindersProvider.notifier).deleteReminder(rem.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Reminder "${rem.title}" deleted.'),
              action: SnackBarAction(
                label: 'Undo',
                textColor: tokens.primary,
                onPressed: () {
                  ref.read(remindersProvider.notifier).createReminder(rem);
                },
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: tokens.error.withOpacity(0.85),
            borderRadius: BorderRadius.circular(tokens.cardRadius),
          ),
          child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
        ),
        child: DayFlowCard(
          padding: EdgeInsets.all(tokens.cardPadding),
          onTap: () => _openEditReminderDialog(rem),
          child: Row(
            children: [
              // Time Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: rem.isEnabled
                      ? tokens.primary.withOpacity(0.12)
                      : tokens.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: rem.isEnabled ? tokens.primary : tokens.borderColor,
                    width: 1.0,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.alarm,
                      size: 18,
                      color: rem.isEnabled ? tokens.primary : tokens.textSecondary,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeStr,
                      style: context.getTextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: rem.isEnabled
                            ? tokens.primary
                            : tokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Title and Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rem.title,
                      style: context.getTextStyle(
                        fontSize: 15,
                        fontWeight: tokens.headingWeight,
                        color: rem.isEnabled
                            ? tokens.textPrimary
                            : tokens.textSecondary,
                      ),
                    ),
                    if (rem.description != null && rem.description!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        rem.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.getTextStyle(
                          fontSize: 12,
                          color: tokens.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: tokens.surface,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: tokens.borderColor),
                          ),
                          child: Text(
                            repeatLabel,
                            style: context.getTextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: tokens.textSecondary,
                            ),
                          ),
                        ),
                        Text(
                          dateStr,
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

              // Toggle Switch
              Switch(
                value: rem.isEnabled,
                activeColor: tokens.primary,
                onChanged: (_) {
                  ref.read(remindersProvider.notifier).toggleReminder(rem.id);
                },
              ),

              // Delete action with confirmation
              IconButton(
                icon: Icon(Icons.delete_outline,
                    size: 20, color: tokens.textSecondary),
                tooltip: 'Delete Reminder',
                onPressed: () async {
                  final ok = await _confirmDeleteReminder(rem);
                  if (ok && mounted) {
                    ref.read(remindersProvider.notifier).deleteReminder(rem.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Reminder "${rem.title}" deleted.'),
                        action: SnackBarAction(
                          label: 'Undo',
                          textColor: tokens.primary,
                          onPressed: () {
                            ref
                                .read(remindersProvider.notifier)
                                .createReminder(rem);
                          },
                        ),
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
