import 'package:flutter/material.dart';
import '../../core/theme/dayflow_theme_context.dart';
import 'dayflow_button.dart';

class DayFlowEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const DayFlowEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.themeTokens;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: tokens.primary.withOpacity(tokens.isDark ? 0.15 : 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: tokens.isBrutalist
                      ? Colors.black
                      : tokens.primary.withOpacity(0.2),
                  width: tokens.isBrutalist ? 2.0 : 1.0,
                ),
                boxShadow: tokens.isBrutalist
                    ? const [
                        BoxShadow(
                          color: Colors.black,
                          offset: Offset(3, 3),
                          blurRadius: 0,
                        )
                      ]
                    : null,
              ),
              child: Icon(
                icon,
                size: 36,
                color: tokens.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: context.getTextStyle(
                fontSize: 17,
                fontWeight: tokens.headingWeight,
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.getTextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: tokens.textSecondary,
                height: 1.4,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              DayFlowButton(
                label: actionLabel!,
                icon: Icons.add,
                onPressed: onAction,
                variant: DayFlowButtonVariant.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
