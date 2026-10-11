import 'package:flutter/material.dart';
import '../../core/theme/dayflow_theme_context.dart';

class DayFlowChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final bool isSelected;
  final VoidCallback? onTap;
  final double fontSize;
  final EdgeInsetsGeometry? padding;

  const DayFlowChip({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.isSelected = false,
    this.onTap,
    this.fontSize = 12.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.themeTokens;
    final effectiveColor = color ?? tokens.primary;

    Color bg;
    Color fg;
    Border? border;

    if (isSelected) {
      bg = effectiveColor;
      fg = bg.computeLuminance() > 0.4 ? Colors.black : Colors.white;
      if (tokens.isBrutalist) {
        border = Border.all(color: Colors.black, width: 2.0);
      }
    } else {
      bg = effectiveColor.withOpacity(tokens.isDark ? 0.15 : 0.08);
      fg = tokens.isDark ? effectiveColor : effectiveColor;
      border = Border.all(
        color: tokens.isBrutalist
            ? Colors.black
            : effectiveColor.withOpacity(0.35),
        width: tokens.isBrutalist ? 1.5 : 1.0,
      );
    }

    final radius = tokens.cardRadius > 14 ? 12.0 : tokens.cardRadius;
    final borderRadius = BorderRadius.circular(radius);

    return InkWell(
      onTap: onTap,
      borderRadius: borderRadius,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: padding ??
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: borderRadius,
          border: border,
          boxShadow: tokens.isBrutalist && isSelected
              ? const [
                  BoxShadow(
                    color: Colors.black,
                    offset: Offset(2, 2),
                    blurRadius: 0,
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: fontSize + 2, color: fg),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: context.getTextStyle(
                fontSize: fontSize,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
