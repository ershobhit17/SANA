import 'package:flutter/material.dart';
import '../../core/theme/dayflow_theme_context.dart';

class DayFlowTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final int maxLines;
  final int? minLines;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final FocusNode? focusNode;
  final bool autofocus;

  const DayFlowTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.onChanged,
    this.onFieldSubmitted,
    this.validator,
    this.keyboardType,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.themeTokens;
    final radius = tokens.cardRadius > 14 ? 12.0 : tokens.cardRadius;

    final borderSide = BorderSide(
      color: tokens.borderColor,
      width: tokens.isBrutalist ? 2.0 : tokens.borderWidth,
    );

    final focusedBorderSide = BorderSide(
      color: tokens.primary,
      width: tokens.isBrutalist ? 2.5 : 1.8,
    );

    final borderRadius = BorderRadius.circular(radius);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (labelText != null) ...[
          Text(
            labelText!,
            style: context.getTextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: tokens.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
        ],
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          maxLines: maxLines,
          minLines: minLines,
          onChanged: onChanged,
          onFieldSubmitted: onFieldSubmitted,
          validator: validator,
          keyboardType: keyboardType,
          focusNode: focusNode,
          autofocus: autofocus,
          style: context.getTextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: tokens.textPrimary,
          ),
          cursorColor: tokens.primary,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: context.getTextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: tokens.textSecondary.withOpacity(0.7),
            ),
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: tokens.isGlass
                ? tokens.surface.withOpacity(tokens.glassOpacity)
                : tokens.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: borderSide,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: borderSide,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: focusedBorderSide,
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: BorderSide(color: tokens.error, width: 1.2),
            ),
          ),
        ),
      ],
    );
  }
}
