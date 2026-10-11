import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/storage_service.dart';
import '../../../core/theme/dayflow_theme_context.dart';
import '../../../models/app_settings_model.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/dayflow_card.dart';
import '../../../shared/widgets/dayflow_text_field.dart';
import '../../theme_studio/presentation/theme_studio_screen.dart';
import '../../onboarding/presentation/dayflow_onboarding_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showSetPinDialog(BuildContext context, WidgetRef ref, AppSettings current) {
    final tokens = context.themeTokens;
    final pinController =
        TextEditingController(text: current.appLockPin ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tokens.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.cardRadius),
          side: BorderSide(color: tokens.borderColor),
        ),
        title: Text(
          'Set App Lock PIN',
          style: ctx.getTextStyle(
            fontSize: 18,
            fontWeight: tokens.headingWeight,
            color: tokens.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter a 4-digit PIN to secure your private diary and notes:',
              style: ctx.getTextStyle(fontSize: 13, color: tokens.textSecondary),
            ),
            const SizedBox(height: 12),
            DayFlowTextField(
              controller: pinController,
              hintText: 'e.g. 1234',
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel',
                style: ctx.getTextStyle(color: tokens.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final pin = pinController.text.trim();
              if (pin.length >= 4) {
                ref
                    .read(appSettingsProvider.notifier)
                    .toggleAppLock(true, pin);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('App Lock PIN set and activated!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PIN must be at least 4 digits.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: Text(
              'Save PIN',
              style: ctx.getTextStyle(
                color: tokens.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportBackup(BuildContext context) async {
    final jsonStr = await StorageService.instance.exportAllDataJson();
    final tokens = context.themeTokens;

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: tokens.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tokens.cardRadius),
            side: BorderSide(color: tokens.borderColor),
          ),
          title: Text(
            'Backup Export (JSON)',
            style: ctx.getTextStyle(
              fontSize: 18,
              fontWeight: tokens.headingWeight,
              color: tokens.textPrimary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Copy and store your complete DayFlow data backup safely:',
                style: ctx.getTextStyle(
                  fontSize: 13,
                  color: tokens.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: tokens.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: tokens.borderColor),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    jsonStr,
                    style: ctx.getTextStyle(
                      fontSize: 11,
                      color: tokens.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: jsonStr));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Backup copied to clipboard!'),
                    duration: Duration(seconds: 2),
                  ),
                );
                Navigator.of(ctx).pop();
              },
              child: Text(
                'Copy to Clipboard',
                style: ctx.getTextStyle(
                  color: tokens.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Close',
                  style: ctx.getTextStyle(color: tokens.textSecondary)),
            ),
          ],
        ),
      );
    }
  }

  void _restoreBackup(BuildContext context, WidgetRef ref) {
    final tokens = context.themeTokens;
    final restoreController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tokens.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.cardRadius),
          side: BorderSide(color: tokens.borderColor),
        ),
        title: Text(
          'Restore Data from Backup',
          style: ctx.getTextStyle(
            fontSize: 18,
            fontWeight: tokens.headingWeight,
            color: tokens.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paste your previously exported DayFlow backup JSON. This will merge existing items with the backup.',
              style: ctx.getTextStyle(
                fontSize: 13,
                color: tokens.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            DayFlowTextField(
              controller: restoreController,
              hintText: 'Paste backup JSON here...',
              maxLines: 5,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel',
                style: ctx.getTextStyle(color: tokens.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              final text = restoreController.text.trim();
              final success =
                  await StorageService.instance.restoreAllDataJson(text);
              if (ctx.mounted) Navigator.of(ctx).pop();

              if (success) {
                // Reload providers
                ref.read(tasksProvider.notifier).loadTasks();
                ref.read(habitsProvider.notifier).loadHabits();
                ref.read(habitCompletionsProvider.notifier).loadCompletions();
                ref.read(remindersProvider.notifier).loadReminders();
                ref.read(diaryProvider.notifier).loadEntries();
                ref.read(notesProvider.notifier).loadNotes();
                ref.read(appSettingsProvider.notifier).loadSettings();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Data restored successfully!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Invalid backup JSON format.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            child: Text(
              'Restore',
              style: ctx.getTextStyle(
                color: tokens.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmResetData(BuildContext context, WidgetRef ref) {
    final tokens = context.themeTokens;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tokens.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.cardRadius),
          side: BorderSide(color: tokens.borderColor),
        ),
        title: Text(
          'Reset Application Data?',
          style: ctx.getTextStyle(
            fontSize: 18,
            fontWeight: tokens.headingWeight,
            color: tokens.error,
          ),
        ),
        content: Text(
          'This will permanently delete all tasks, reminders, habits, and diary entries on this device. This cannot be undone.',
          style: ctx.getTextStyle(
            fontSize: 14,
            color: tokens.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel',
                style: ctx.getTextStyle(color: tokens.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              await StorageService.instance.resetAllData();
              if (ctx.mounted) Navigator.of(ctx).pop();

              // Reload
              ref.read(tasksProvider.notifier).loadTasks();
              ref.read(habitsProvider.notifier).loadHabits();
              ref.read(habitCompletionsProvider.notifier).loadCompletions();
              ref.read(remindersProvider.notifier).loadReminders();
              ref.read(diaryProvider.notifier).loadEntries();
              ref.read(notesProvider.notifier).loadNotes();
              ref.read(appSettingsProvider.notifier).loadSettings();

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All data has been reset.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: Text(
              'Reset Everything',
              style: ctx.getTextStyle(
                color: tokens.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.themeTokens;
    final settings = ref.watch(appSettingsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Settings & Preferences',
          style: context.getTextStyle(
            fontSize: 20,
            fontWeight: tokens.headingWeight,
            color: tokens.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            tokens.screenPadding,
            8,
            tokens.screenPadding,
            80,
          ),
          children: [
            // Theme Studio Banner
            DayFlowCard(
              padding: EdgeInsets.all(tokens.cardPadding),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ThemeStudioScreen()),
                );
              },
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: tokens.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.palette, color: tokens.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Theme Studio',
                          style: context.getTextStyle(
                            fontSize: 16,
                            fontWeight: tokens.headingWeight,
                            color: tokens.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Active: ${tokens.name} • 10 UI Design Systems & Studio',
                          style: context.getTextStyle(
                            fontSize: 12,
                            color: tokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Onboarding Tour Card
            DayFlowCard(
              padding: EdgeInsets.all(tokens.cardPadding),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const DayFlowOnboardingScreen()),
                );
              },
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: tokens.secondary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child:
                        Icon(Icons.explore_outlined, color: tokens.secondary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Feature Tour & Onboarding',
                          style: context.getTextStyle(
                            fontSize: 16,
                            fontWeight: tokens.headingWeight,
                            color: tokens.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'View 3D interactive slides & feature walkthrough',
                          style: context.getTextStyle(
                            fontSize: 12,
                            color: tokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Preferences Section
            _buildSectionHeader(context, 'Preferences'),
            DayFlowCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(
                      '24-Hour Time Format',
                      style: context.getTextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: tokens.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      settings.timeFormat24h
                          ? 'e.g. 14:30'
                          : 'e.g. 2:30 PM (12-hour format)',
                      style: context.getTextStyle(
                        fontSize: 12,
                        color: tokens.textSecondary,
                      ),
                    ),
                    value: settings.timeFormat24h,
                    activeColor: tokens.primary,
                    onChanged: (val) {
                      ref
                          .read(appSettingsProvider.notifier)
                          .updateSettings(settings.copyWith(timeFormat24h: val));
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: Text(
                      'Start Week on Monday',
                      style: context.getTextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: tokens.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      settings.startOfWeekMonday
                          ? 'Monday is first day of week'
                          : 'Sunday is first day of week',
                      style: context.getTextStyle(
                        fontSize: 12,
                        color: tokens.textSecondary,
                      ),
                    ),
                    value: settings.startOfWeekMonday,
                    activeColor: tokens.primary,
                    onChanged: (val) {
                      ref.read(appSettingsProvider.notifier).updateSettings(
                          settings.copyWith(startOfWeekMonday: val));
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: Text(
                      'Haptic Feedback',
                      style: context.getTextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: tokens.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      'Tactile vibrations on button clicks and task completion',
                      style: context.getTextStyle(
                        fontSize: 12,
                        color: tokens.textSecondary,
                      ),
                    ),
                    value: settings.hapticEnabled,
                    activeColor: tokens.primary,
                    onChanged: (val) {
                      ref
                          .read(appSettingsProvider.notifier)
                          .updateSettings(settings.copyWith(hapticEnabled: val));
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Privacy & Security
            _buildSectionHeader(context, 'Privacy & Security'),
            DayFlowCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(
                      'App Lock PIN for Journal',
                      style: context.getTextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: tokens.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      settings.appLockEnabled
                          ? 'PIN protection active'
                          : 'Require PIN to open personal journal',
                      style: context.getTextStyle(
                        fontSize: 12,
                        color: tokens.textSecondary,
                      ),
                    ),
                    value: settings.appLockEnabled,
                    activeColor: tokens.primary,
                    onChanged: (val) {
                      if (val) {
                        _showSetPinDialog(context, ref, settings);
                      } else {
                        ref
                            .read(appSettingsProvider.notifier)
                            .toggleAppLock(false, null);
                      }
                    },
                  ),
                  if (settings.appLockEnabled) ...[
                    const Divider(height: 1),
                    ListTile(
                      title: Text(
                        'Change PIN',
                        style: context.getTextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: tokens.primary,
                        ),
                      ),
                      trailing: const Icon(Icons.lock_reset),
                      onTap: () =>
                          _showSetPinDialog(context, ref, settings),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Data & Backup
            _buildSectionHeader(context, 'Data Backup & Restore'),
            DayFlowCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.cloud_upload_outlined,
                        color: tokens.primary),
                    title: Text(
                      'Export Data Backup',
                      style: context.getTextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: tokens.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      'Save complete JSON backup of all tasks, habits & notes',
                      style: context.getTextStyle(
                        fontSize: 12,
                        color: tokens.textSecondary,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _exportBackup(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.cloud_download_outlined,
                        color: tokens.secondary),
                    title: Text(
                      'Restore from Backup',
                      style: context.getTextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: tokens.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      'Import previously saved SANA JSON data',
                      style: context.getTextStyle(
                        fontSize: 12,
                        color: tokens.textSecondary,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _restoreBackup(context, ref),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading:
                        Icon(Icons.delete_forever, color: tokens.error),
                    title: Text(
                      'Reset All Application Data',
                      style: context.getTextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: tokens.error,
                      ),
                    ),
                    subtitle: Text(
                      'Wipe stored data with explicit confirmation',
                      style: context.getTextStyle(
                        fontSize: 12,
                        color: tokens.textSecondary,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _confirmResetData(context, ref),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // About Footer
            Center(
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black,
                      border: Border.all(
                        color: const Color(0xFFD4A373).withOpacity(0.4),
                        width: 1.2,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Image.asset(
                        'assets/images/sana_logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.spa_rounded,
                          color: Color(0xFFD4A373),
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'SANA — Personal Productivity & Life Organizer',
                    style: context.getTextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: tokens.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Version 1.0.0 • Offline First & Secure',
                    style: context.getTextStyle(
                      fontSize: 11,
                      color: tokens.textSecondary.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final tokens = context.themeTokens;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: context.getTextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: tokens.textSecondary,
        ),
      ),
    );
  }
}
