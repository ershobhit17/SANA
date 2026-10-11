import 'package:flutter/material.dart';
import 'dayflow_theme_context.dart';

enum ThemeDensity { compact, comfortable, spacious }

enum CardVisualVariant { elevated, outlined, flat, glass, brutalist, spatial, paper }

enum AppThemeModePreference { system, light, dark, amoled }

enum AppDesignStyle {
  obsidianAmoled,
  swissMinimal,
  glassAtelier,
  vectorStudio,
  neoBrutalist,
  paperJournal,
  nordicCalm,
  modernEditorial,
  softNeoModern,
  futuristicSpatial,
  custom,
}

enum AppNavigationStyle {
  dockedBar,
  floatingPill,
  editorialMinimal,
  brutalistSolid,
}

class DayFlowThemeTokens {
  final String id;
  final String name;
  final String description;
  final bool isCustom;

  // Design System & Navigation Identity
  final AppDesignStyle designStyle;
  final AppNavigationStyle navigationStyle;

  // Colors
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color background;
  final Color surface;
  final Color cardColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color borderColor;
  final Color dividerColor;
  final Color success;
  final Color warning;
  final Color error;

  // Visual Style
  final double cardRadius;
  final double buttonRadius;
  final double borderWidth;
  final double elevation;
  final Color shadowColor;
  final double shadowBlurRadius;
  final Offset shadowOffset;

  // Visual Effects
  final bool isGlass;
  final double glassOpacity;
  final double glassBlur;
  final bool isBrutalist;
  final Offset brutalistShadowOffset;
  final bool hasBackgroundGradient;
  final List<Color>? backgroundGradient;
  final List<Color>? accentGradient;

  // Specific Style Attributes
  final bool hasPaperTexture;
  final bool hasGeometricDecorations;

  // Layout & Density
  final ThemeDensity density;
  final CardVisualVariant cardStyle;

  // Typography
  final String fontFamily;
  final double fontScale;
  final FontWeight headingWeight;
  final FontWeight bodyWeight;

  // Mode
  final bool isDark;
  final bool isAmoled;

  const DayFlowThemeTokens({
    required this.id,
    required this.name,
    required this.description,
    this.isCustom = false,
    this.designStyle = AppDesignStyle.obsidianAmoled,
    this.navigationStyle = AppNavigationStyle.dockedBar,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.background,
    required this.surface,
    required this.cardColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.borderColor,
    required this.dividerColor,
    required this.success,
    required this.warning,
    required this.error,
    this.cardRadius = 16.0,
    this.buttonRadius = 12.0,
    this.borderWidth = 1.0,
    this.elevation = 0.0,
    this.shadowColor = const Color(0x1A000000),
    this.shadowBlurRadius = 8.0,
    this.shadowOffset = const Offset(0, 2),
    this.isGlass = false,
    this.glassOpacity = 0.15,
    this.glassBlur = 12.0,
    this.isBrutalist = false,
    this.brutalistShadowOffset = const Offset(3, 3),
    this.hasBackgroundGradient = false,
    this.backgroundGradient,
    this.accentGradient,
    this.hasPaperTexture = false,
    this.hasGeometricDecorations = false,
    this.density = ThemeDensity.comfortable,
    this.cardStyle = CardVisualVariant.flat,
    this.fontFamily = 'Inter',
    this.fontScale = 1.0,
    this.headingWeight = FontWeight.w700,
    this.bodyWeight = FontWeight.w400,
    this.isDark = false,
    this.isAmoled = false,
  });

  bool get isPaperJournal => designStyle == AppDesignStyle.paperJournal || hasPaperTexture;
  bool get isSpatial => designStyle == AppDesignStyle.futuristicSpatial;
  bool get isVectorStudio => designStyle == AppDesignStyle.vectorStudio || hasGeometricDecorations;
  bool get isEditorial => designStyle == AppDesignStyle.modernEditorial;
  bool get isSoftNeo => designStyle == AppDesignStyle.softNeoModern;
  bool get isSwissMinimal => designStyle == AppDesignStyle.swissMinimal;
  bool get isNordicCalm => designStyle == AppDesignStyle.nordicCalm;

  double get cardPadding {
    switch (density) {
      case ThemeDensity.compact:
        return 12.0;
      case ThemeDensity.comfortable:
        return 16.0;
      case ThemeDensity.spacious:
        return 22.0;
    }
  }

  double get screenPadding {
    switch (density) {
      case ThemeDensity.compact:
        return 12.0;
      case ThemeDensity.comfortable:
        return 16.0;
      case ThemeDensity.spacious:
        return 24.0;
    }
  }

  double get itemSpacing {
    switch (density) {
      case ThemeDensity.compact:
        return 8.0;
      case ThemeDensity.comfortable:
        return 14.0;
      case ThemeDensity.spacious:
        return 20.0;
    }
  }

  DayFlowThemeTokens copyWith({
    String? id,
    String? name,
    String? description,
    bool? isCustom,
    AppDesignStyle? designStyle,
    AppNavigationStyle? navigationStyle,
    Color? primary,
    Color? secondary,
    Color? accent,
    Color? background,
    Color? surface,
    Color? cardColor,
    Color? textPrimary,
    Color? textSecondary,
    Color? borderColor,
    Color? dividerColor,
    Color? success,
    Color? warning,
    Color? error,
    double? cardRadius,
    double? buttonRadius,
    double? borderWidth,
    double? elevation,
    Color? shadowColor,
    double? shadowBlurRadius,
    Offset? shadowOffset,
    bool? isGlass,
    double? glassOpacity,
    double? glassBlur,
    bool? isBrutalist,
    Offset? brutalistShadowOffset,
    bool? hasBackgroundGradient,
    List<Color>? backgroundGradient,
    List<Color>? accentGradient,
    bool? hasPaperTexture,
    bool? hasGeometricDecorations,
    ThemeDensity? density,
    CardVisualVariant? cardStyle,
    String? fontFamily,
    double? fontScale,
    FontWeight? headingWeight,
    FontWeight? bodyWeight,
    bool? isDark,
    bool? isAmoled,
  }) {
    return DayFlowThemeTokens(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isCustom: isCustom ?? this.isCustom,
      designStyle: designStyle ?? this.designStyle,
      navigationStyle: navigationStyle ?? this.navigationStyle,
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      accent: accent ?? this.accent,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      cardColor: cardColor ?? this.cardColor,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      borderColor: borderColor ?? this.borderColor,
      dividerColor: dividerColor ?? this.dividerColor,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      cardRadius: cardRadius ?? this.cardRadius,
      buttonRadius: buttonRadius ?? this.buttonRadius,
      borderWidth: borderWidth ?? this.borderWidth,
      elevation: elevation ?? this.elevation,
      shadowColor: shadowColor ?? this.shadowColor,
      shadowBlurRadius: shadowBlurRadius ?? this.shadowBlurRadius,
      shadowOffset: shadowOffset ?? this.shadowOffset,
      isGlass: isGlass ?? this.isGlass,
      glassOpacity: glassOpacity ?? this.glassOpacity,
      glassBlur: glassBlur ?? this.glassBlur,
      isBrutalist: isBrutalist ?? this.isBrutalist,
      brutalistShadowOffset:
          brutalistShadowOffset ?? this.brutalistShadowOffset,
      hasBackgroundGradient:
          hasBackgroundGradient ?? this.hasBackgroundGradient,
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
      accentGradient: accentGradient ?? this.accentGradient,
      hasPaperTexture: hasPaperTexture ?? this.hasPaperTexture,
      hasGeometricDecorations:
          hasGeometricDecorations ?? this.hasGeometricDecorations,
      density: density ?? this.density,
      cardStyle: cardStyle ?? this.cardStyle,
      fontFamily: fontFamily ?? this.fontFamily,
      fontScale: fontScale ?? this.fontScale,
      headingWeight: headingWeight ?? this.headingWeight,
      bodyWeight: bodyWeight ?? this.bodyWeight,
      isDark: isDark ?? this.isDark,
      isAmoled: isAmoled ?? this.isAmoled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'isCustom': isCustom,
      'designStyle': designStyle.index,
      'navigationStyle': navigationStyle.index,
      'primary': primary.value,
      'secondary': secondary.value,
      'accent': accent.value,
      'background': background.value,
      'surface': surface.value,
      'cardColor': cardColor.value,
      'textPrimary': textPrimary.value,
      'textSecondary': textSecondary.value,
      'borderColor': borderColor.value,
      'dividerColor': dividerColor.value,
      'success': success.value,
      'warning': warning.value,
      'error': error.value,
      'cardRadius': cardRadius,
      'buttonRadius': buttonRadius,
      'borderWidth': borderWidth,
      'elevation': elevation,
      'shadowColor': shadowColor.value,
      'shadowBlurRadius': shadowBlurRadius,
      'shadowOffsetX': shadowOffset.dx,
      'shadowOffsetY': shadowOffset.dy,
      'isGlass': isGlass,
      'glassOpacity': glassOpacity,
      'glassBlur': glassBlur,
      'isBrutalist': isBrutalist,
      'brutalistShadowOffsetX': brutalistShadowOffset.dx,
      'brutalistShadowOffsetY': brutalistShadowOffset.dy,
      'hasBackgroundGradient': hasBackgroundGradient,
      'backgroundGradient': backgroundGradient?.map((c) => c.value).toList(),
      'accentGradient': accentGradient?.map((c) => c.value).toList(),
      'hasPaperTexture': hasPaperTexture,
      'hasGeometricDecorations': hasGeometricDecorations,
      'density': density.index,
      'cardStyle': cardStyle.index,
      'fontFamily': fontFamily,
      'fontScale': fontScale,
      'headingWeight': headingWeight.index,
      'bodyWeight': bodyWeight.index,
      'isDark': isDark,
      'isAmoled': isAmoled,
    };
  }

  factory DayFlowThemeTokens.fromJson(Map<String, dynamic> json) {
    return DayFlowThemeTokens(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      isCustom: json['isCustom'] as bool? ?? false,
      designStyle: json['designStyle'] != null
          ? AppDesignStyle.values[(json['designStyle'] as int).clamp(0, AppDesignStyle.values.length - 1)]
          : AppDesignStyle.obsidianAmoled,
      navigationStyle: json['navigationStyle'] != null
          ? AppNavigationStyle.values[(json['navigationStyle'] as int).clamp(0, AppNavigationStyle.values.length - 1)]
          : AppNavigationStyle.dockedBar,
      primary: Color(json['primary'] as int),
      secondary: Color(json['secondary'] as int),
      accent: Color(json['accent'] as int),
      background: Color(json['background'] as int),
      surface: Color(json['surface'] as int),
      cardColor: Color(json['cardColor'] as int),
      textPrimary: Color(json['textPrimary'] as int),
      textSecondary: Color(json['textSecondary'] as int),
      borderColor: Color(json['borderColor'] as int),
      dividerColor: Color(json['dividerColor'] as int),
      success: Color(json['success'] as int),
      warning: Color(json['warning'] as int),
      error: Color(json['error'] as int),
      cardRadius: (json['cardRadius'] as num?)?.toDouble() ?? 16.0,
      buttonRadius: (json['buttonRadius'] as num?)?.toDouble() ?? 12.0,
      borderWidth: (json['borderWidth'] as num?)?.toDouble() ?? 1.0,
      elevation: (json['elevation'] as num?)?.toDouble() ?? 0.0,
      shadowColor: json['shadowColor'] != null
          ? Color(json['shadowColor'] as int)
          : const Color(0x1A000000),
      shadowBlurRadius:
          (json['shadowBlurRadius'] as num?)?.toDouble() ?? 8.0,
      shadowOffset: Offset(
        (json['shadowOffsetX'] as num?)?.toDouble() ?? 0.0,
        (json['shadowOffsetY'] as num?)?.toDouble() ?? 2.0,
      ),
      isGlass: json['isGlass'] as bool? ?? false,
      glassOpacity: (json['glassOpacity'] as num?)?.toDouble() ?? 0.15,
      glassBlur: (json['glassBlur'] as num?)?.toDouble() ?? 12.0,
      isBrutalist: json['isBrutalist'] as bool? ?? false,
      brutalistShadowOffset: Offset(
        (json['brutalistShadowOffsetX'] as num?)?.toDouble() ?? 3.0,
        (json['brutalistShadowOffsetY'] as num?)?.toDouble() ?? 3.0,
      ),
      hasBackgroundGradient: json['hasBackgroundGradient'] as bool? ?? false,
      backgroundGradient: (json['backgroundGradient'] as List<dynamic>?)
          ?.map((c) => Color(c as int))
          .toList(),
      accentGradient: (json['accentGradient'] as List<dynamic>?)
          ?.map((c) => Color(c as int))
          .toList(),
      hasPaperTexture: json['hasPaperTexture'] as bool? ?? false,
      hasGeometricDecorations: json['hasGeometricDecorations'] as bool? ?? false,
      density: ThemeDensity.values[(json['density'] as int?) ?? 1],
      cardStyle: CardVisualVariant.values[(json['cardStyle'] as int?) ?? 2],
      fontFamily: json['fontFamily'] as String? ?? 'Inter',
      fontScale: (json['fontScale'] as num?)?.toDouble() ?? 1.0,
      headingWeight:
          FontWeight.values[(json['headingWeight'] as int?) ?? 6],
      bodyWeight: FontWeight.values[(json['bodyWeight'] as int?) ?? 3],
      isDark: json['isDark'] as bool? ?? false,
      isAmoled: json['isAmoled'] as bool? ?? false,
    );
  }

  ThemeData toThemeData() {
    final colorScheme = ColorScheme(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primary: primary,
      onPrimary: _contrastColor(primary),
      secondary: secondary,
      onSecondary: _contrastColor(secondary),
      error: error,
      onError: Colors.white,
      surface: surface,
      onSurface: textPrimary,
    );

    final baseTextTheme = isDark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;

    final fontStyle =
        DayFlowThemeContextExtension.getGoogleFontStyle(fontFamily);
    final googleTextTheme = baseTextTheme.apply(
      fontFamily: fontStyle.fontFamily,
      fontFamilyFallback: fontStyle.fontFamilyFallback,
      bodyColor: textPrimary,
      displayColor: textPrimary,
      fontSizeFactor: fontScale,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      cardColor: cardColor,
      dividerColor: dividerColor,
      textTheme: googleTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: googleTextTheme.titleLarge?.copyWith(
          color: textPrimary,
          fontWeight: headingWeight,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        hintStyle: TextStyle(color: textSecondary.withOpacity(0.6)),
        labelStyle: TextStyle(color: textSecondary),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: BorderSide(color: borderColor),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: primary.withOpacity(0.15),
        labelStyle: TextStyle(color: textPrimary, fontSize: 12 * fontScale),
        side: BorderSide(color: borderColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardColor,
        contentTextStyle: TextStyle(color: textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static Color _contrastColor(Color background) {
    return background.computeLuminance() > 0.4 ? Colors.black : Colors.white;
  }
}
