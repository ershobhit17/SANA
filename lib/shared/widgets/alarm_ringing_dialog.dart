import 'package:flutter/material.dart';
import '../../core/services/alarm_service.dart';
import '../../core/theme/dayflow_theme_context.dart';
import 'dayflow_button.dart';

class AlarmRingingDialog extends StatefulWidget {
  final AlarmEvent event;

  const AlarmRingingDialog({
    super.key,
    required this.event,
  });

  static void show(BuildContext context, AlarmEvent event) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlarmRingingDialog(event: event),
    );
  }

  @override
  State<AlarmRingingDialog> createState() => _AlarmRingingDialogState();
}

class _AlarmRingingDialogState extends State<AlarmRingingDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _scaleAnim = Tween<double>(begin: 0.9, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.themeTokens;

    return WillPopScope(
      onWillPop: () async {
        AlarmService.instance.stopAlarm();
        return true;
      },
      child: Dialog(
        backgroundColor: tokens.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.cardRadius),
          side: BorderSide(color: tokens.error, width: 2),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pulsing Alarm Bell Icon
              ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: tokens.error.withOpacity(0.15),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: tokens.error.withOpacity(0.4),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.alarm_on_rounded,
                    color: tokens.error,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              Text(
                '⏰ ALARM RINGING',
                style: TextStyle(
                  fontFamily: tokens.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: tokens.error,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                widget.event.title,
                textAlign: TextAlign.center,
                style: context.getTextStyle(
                  fontSize: 22,
                  fontWeight: tokens.headingWeight,
                  color: tokens.textPrimary,
                ),
              ),
              const SizedBox(height: 6),

              Text(
                widget.event.subtitle,
                textAlign: TextAlign.center,
                style: context.getTextStyle(
                  fontSize: 14,
                  color: tokens.textSecondary,
                ),
              ),
              const SizedBox(height: 14),

              // Audio source badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: tokens.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: tokens.borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.music_note_rounded, size: 16, color: tokens.primary),
                    const SizedBox(width: 6),
                    Text(
                      widget.event.customAudioName ?? 'System Alarm Sound',
                      style: context.getTextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: tokens.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: DayFlowButton(
                      label: 'Snooze (5m)',
                      icon: Icons.snooze_rounded,
                      variant: DayFlowButtonVariant.secondary,
                      onPressed: () {
                        AlarmService.instance.snoozeAlarm(const Duration(minutes: 5));
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DayFlowButton(
                      label: 'Turn Off',
                      icon: Icons.alarm_off_rounded,
                      variant: DayFlowButtonVariant.primary,
                      onPressed: () {
                        AlarmService.instance.stopAlarm();
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
