import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dayflow_theme_tokens.dart';

class DayFlowThemeScope extends InheritedWidget {
  final DayFlowThemeTokens tokens;

  const DayFlowThemeScope({
    super.key,
    required this.tokens,
    required super.child,
  });

  static DayFlowThemeTokens of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<DayFlowThemeScope>();
    if (scope == null) {
      throw FlutterError(
          'DayFlowThemeScope.of() called with a context that does not contain a DayFlowThemeScope.');
    }
    return scope.tokens;
  }

  @override
  bool updateShouldNotify(DayFlowThemeScope oldWidget) {
    return tokens != oldWidget.tokens;
  }
}

extension DayFlowThemeContextExtension on BuildContext {
  DayFlowThemeTokens get themeTokens => DayFlowThemeScope.of(this);

  TextStyle getTextStyle({
    double fontSize = 14.0,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
    TextDecoration? decoration,
  }) {
    final tokens = themeTokens;
    final scale = tokens.fontScale;
    final weight = fontWeight ?? tokens.bodyWeight;
    final effectiveColor = color ?? tokens.textPrimary;

    try {
      return getGoogleFontStyle(
        tokens.fontFamily,
        fontSize: fontSize * scale,
        fontWeight: weight,
        color: effectiveColor,
        letterSpacing: letterSpacing,
        height: height,
        decoration: decoration,
      );
    } catch (_) {
      return _getFallbackStyle(
        tokens.fontFamily,
        fontSize: fontSize * scale,
        fontWeight: weight,
        color: effectiveColor,
        letterSpacing: letterSpacing,
        height: height,
        decoration: decoration,
      );
    }
  }

  static TextStyle getGoogleFontStyle(
    String family, {
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
    TextDecoration? decoration,
  }) {
    try {
      switch (family) {
        case 'Outfit':
          return GoogleFonts.outfit(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
            letterSpacing: letterSpacing ?? 0.2,
            height: height,
            decoration: decoration,
          );
        case 'Space Grotesk':
          return GoogleFonts.spaceGrotesk(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
            letterSpacing: letterSpacing ?? -0.3,
            height: height,
            decoration: decoration,
          );
        case 'Playfair Display':
          return GoogleFonts.playfairDisplay(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
            letterSpacing: letterSpacing ?? 0.3,
            height: height,
            decoration: decoration,
          );
        case 'JetBrains Mono':
          return GoogleFonts.jetBrainsMono(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
            letterSpacing: letterSpacing ?? -0.2,
            height: height,
            decoration: decoration,
          );
        case 'Poppins':
          return GoogleFonts.poppins(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
            letterSpacing: letterSpacing,
            height: height,
            decoration: decoration,
          );
        case 'Roboto':
          return GoogleFonts.roboto(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
            letterSpacing: letterSpacing,
            height: height,
            decoration: decoration,
          );
        case 'Merriweather':
          return GoogleFonts.merriweather(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
            letterSpacing: letterSpacing ?? 0.2,
            height: height,
            decoration: decoration,
          );
        case 'Inter':
        default:
          return GoogleFonts.inter(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
            letterSpacing: letterSpacing,
            height: height,
            decoration: decoration,
          );
      }
    } catch (_) {
      return _getFallbackStyle(
        family,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
        decoration: decoration,
      );
    }
  }

  static TextStyle _getFallbackStyle(
    String family, {
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
    TextDecoration? decoration,
  }) {
    List<String> fallbacks;
    switch (family) {
      case 'Playfair Display':
      case 'Merriweather':
        fallbacks = ['serif', 'Georgia', 'Times New Roman'];
        break;
      case 'JetBrains Mono':
        fallbacks = ['monospace', 'Courier New', 'Courier'];
        break;
      case 'Space Grotesk':
        fallbacks = ['monospace', 'sans-serif'];
        break;
      case 'Outfit':
      case 'Poppins':
        fallbacks = ['sans-serif-medium', 'sans-serif'];
        break;
      default:
        fallbacks = ['sans-serif'];
        break;
    }

    return TextStyle(
      fontFamily: family,
      fontFamilyFallback: fallbacks,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      decoration: decoration,
    );
  }

  /// Get the registered font family string for Flutter ThemeData
  static String? getFontFamily(String family) {
    try {
      return getGoogleFontStyle(family).fontFamily;
    } catch (_) {
      return null;
    }
  }
}
