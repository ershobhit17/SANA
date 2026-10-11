import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/dayflow_theme_context.dart';

enum DayFlowButtonVariant { primary, secondary, outline, ghost, danger }

class DayFlowButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final DayFlowButtonVariant variant;
  final bool isFullWidth;
  final double? height;
  final double? width;
  final bool isLoading;

  const DayFlowButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.variant = DayFlowButtonVariant.primary,
    this.isFullWidth = false,
    this.height,
    this.width,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.themeTokens;
    final radius = tokens.buttonRadius;

    Color bg;
    Color fg;
    Border? border;

    switch (variant) {
      case DayFlowButtonVariant.primary:
        bg = tokens.primary;
        fg = bg.computeLuminance() > 0.4 ? Colors.black : Colors.white;
        break;
      case DayFlowButtonVariant.secondary:
        bg = tokens.secondary;
        fg = bg.computeLuminance() > 0.4 ? Colors.black : Colors.white;
        break;
      case DayFlowButtonVariant.outline:
        bg = Colors.transparent;
        fg = tokens.textPrimary;
        border = Border.all(
          color: tokens.borderColor,
          width: tokens.borderWidth > 1.0 ? tokens.borderWidth : 1.2,
        );
        break;
      case DayFlowButtonVariant.ghost:
        bg = Colors.transparent;
        fg = tokens.textPrimary;
        break;
      case DayFlowButtonVariant.danger:
        bg = tokens.error;
        fg = Colors.white;
        break;
    }

    final isBrutalist = tokens.isBrutalist;
    if (isBrutalist && variant != DayFlowButtonVariant.ghost) {
      border = Border.all(
        color: tokens.borderColor,
        width: tokens.borderWidth > 1.5 ? tokens.borderWidth : 2.0,
      );
    }

    final borderRadius = BorderRadius.circular(radius);

    Widget content = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          ),
          const SizedBox(width: 8),
        ] else if (icon != null) ...[
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: context.getTextStyle(
            fontSize: 14,
            fontWeight: tokens.headingWeight,
            color: fg,
          ),
        ),
      ],
    );

    Widget buttonBody = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: height ?? 44.0,
      width: isFullWidth ? double.infinity : width,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: borderRadius,
        border: border,
        boxShadow: isBrutalist && variant != DayFlowButtonVariant.ghost
            ? [
                BoxShadow(
                  color: tokens.shadowColor,
                  offset: tokens.brutalistShadowOffset,
                  blurRadius: 0,
                ),
              ]
            : null,
      ),
      child: Center(child: content),
    );

    return Material(
      color: Colors.transparent,
      borderRadius: borderRadius,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onPressed == null || isLoading
            ? null
            : () {
                HapticFeedback.lightImpact();
                onPressed!();
              },
        child: buttonBody,
      ),
    );
  }
}
