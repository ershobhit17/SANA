import 'package:flutter/material.dart';
import 'dayflow_theme_tokens.dart';

class DayFlowThemePresets {
  // The 10 Official UI Design Systems
  static const String obsidianAmoledId = 'obsidian_amoled';
  static const String swissMinimalId = 'swiss_minimal';
  static const String glassAtelierId = 'glass_atelier';
  static const String vectorStudioId = 'vector_studio';
  static const String neoBrutalistId = 'neo_brutalist';
  static const String paperJournalId = 'paper_journal';
  static const String nordicCalmId = 'nordic_calm';
  static const String modernEditorialId = 'modern_editorial';
  static const String softNeoModernId = 'soft_neo_modern';
  static const String futuristicSpatialId = 'futuristic_spatial';
  static const String customThemeId = 'custom_theme';

  // Legacy alias constants for backwards compatibility with previous saved settings
  static const String cyberNeonId = 'cyber_neon';
  static const String tokyoSynthwaveId = 'tokyo_synthwave';
  static const String draculaNoirId = 'dracula_noir';
  static const String nordDarkFrostId = 'nord_dark_frost';
  static const String midnightAuroraId = 'midnight_aurora';
  static const String emeraldOledId = 'emerald_oled';
  static const String neoBrutalistDarkId = 'neo_brutalist_dark';
  static const String highContrastId = 'high_contrast';

  // -------------------------------------------------------------
  // UI Style 01 — Obsidian AMOLED (Pure black OLED, razor emerald green)
  // -------------------------------------------------------------
  static const obsidianAmoled = DayFlowThemeTokens(
    id: obsidianAmoledId,
    name: 'Obsidian AMOLED',
    description: 'Pure pitch black OLED surfaces, glowing emerald accents, razor clean contrast',
    designStyle: AppDesignStyle.obsidianAmoled,
    navigationStyle: AppNavigationStyle.dockedBar,
    primary: Color(0xFF10B981), // Emerald
    secondary: Color(0xFF06B6D4), // Cyan
    accent: Color(0xFF8B5CF6), // Violet
    background: Color(0xFF000000), // Pure Black OLED
    surface: Color(0xFF0A0A0A),
    cardColor: Color(0xFF141414),
    textPrimary: Color(0xFFF9FAFB),
    textSecondary: Color(0xFF9CA3AF),
    borderColor: Color(0xFF262626),
    dividerColor: Color(0xFF1F2937),
    success: Color(0xFF10B981),
    warning: Color(0xFFF59E0B),
    error: Color(0xFFEF4444),
    cardRadius: 12.0,
    buttonRadius: 10.0,
    borderWidth: 1.0,
    elevation: 0.0,
    shadowColor: Colors.transparent,
    shadowBlurRadius: 0.0,
    density: ThemeDensity.comfortable,
    cardStyle: CardVisualVariant.outlined,
    fontFamily: 'Inter',
    fontScale: 1.0,
    headingWeight: FontWeight.w700,
    bodyWeight: FontWeight.w400,
    isDark: true,
    isAmoled: true,
  );

  // -------------------------------------------------------------
  // UI Style 02 — Swiss Minimal (International typography, generous whitespace)
  // -------------------------------------------------------------
  static const swissMinimal = DayFlowThemeTokens(
    id: swissMinimalId,
    name: 'Swiss Minimal',
    description: 'Editorial clean whitespace, high contrast hierarchy, signature Swiss red accent',
    designStyle: AppDesignStyle.swissMinimal,
    navigationStyle: AppNavigationStyle.editorialMinimal,
    primary: Color(0xFFE11D48), // Swiss Red
    secondary: Color(0xFF0F172A), // Deep Slate
    accent: Color(0xFF475569), // Neutral Gray
    background: Color(0xFFF8FAFC),
    surface: Color(0xFFFFFFFF),
    cardColor: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF64748B),
    borderColor: Color(0xFFE2E8F0),
    dividerColor: Color(0xFFF1F5F9),
    success: Color(0xFF16A34A),
    warning: Color(0xFFD97706),
    error: Color(0xFFDC2626),
    cardRadius: 6.0,
    buttonRadius: 4.0,
    borderWidth: 1.2,
    elevation: 0.0,
    shadowColor: Colors.transparent,
    shadowBlurRadius: 0.0,
    density: ThemeDensity.comfortable,
    cardStyle: CardVisualVariant.outlined,
    fontFamily: 'Inter',
    fontScale: 1.0,
    headingWeight: FontWeight.w800,
    bodyWeight: FontWeight.w400,
    isDark: false,
    isAmoled: false,
  );

  // -------------------------------------------------------------
  // UI Style 03 — Glass Atelier (Frosted glassmorphism, depth & refraction)
  // -------------------------------------------------------------
  static const glassAtelier = DayFlowThemeTokens(
    id: glassAtelierId,
    name: 'Glass Atelier',
    description: 'Translucent frosted glass blur, glowing ambient light, cosmic depth',
    designStyle: AppDesignStyle.glassAtelier,
    navigationStyle: AppNavigationStyle.floatingPill,
    primary: Color(0xFF6366F1), // Electric Indigo
    secondary: Color(0xFF38BDF8), // Sky Blue
    accent: Color(0xFFA855F7), // Purple
    background: Color(0xFF080C14), // Cosmic Dark
    surface: Color(0xFF0F172A),
    cardColor: Color(0xFF1E293B),
    textPrimary: Color(0xFFF8FAFC),
    textSecondary: Color(0xFF94A3B8),
    borderColor: Color(0x33FFFFFF), // Translucent frosted border
    dividerColor: Color(0x1AFFFFFF),
    success: Color(0xFF34D399),
    warning: Color(0xFFFBBF24),
    error: Color(0xFFF87171),
    cardRadius: 18.0,
    buttonRadius: 14.0,
    borderWidth: 1.0,
    elevation: 0.0,
    shadowColor: Color(0x33000000),
    shadowBlurRadius: 16.0,
    shadowOffset: Offset(0, 8),
    isGlass: true,
    glassOpacity: 0.22,
    glassBlur: 16.0,
    hasBackgroundGradient: true,
    backgroundGradient: [
      Color(0xFF080C14),
      Color(0xFF131131),
      Color(0xFF0D1424),
    ],
    accentGradient: [
      Color(0xFF6366F1),
      Color(0xFF8B5CF6),
    ],
    density: ThemeDensity.comfortable,
    cardStyle: CardVisualVariant.glass,
    fontFamily: 'Outfit',
    fontScale: 1.0,
    headingWeight: FontWeight.w700,
    bodyWeight: FontWeight.w400,
    isDark: true,
    isAmoled: false,
  );

  // -------------------------------------------------------------
  // UI Style 04 — Vector Studio (Crisp modern geometric color blocks)
  // -------------------------------------------------------------
  static const vectorStudio = DayFlowThemeTokens(
    id: vectorStudioId,
    name: 'Vector Studio',
    description: 'Geometric vector shapes, crisp flat color blocks, modern compositional energy',
    designStyle: AppDesignStyle.vectorStudio,
    navigationStyle: AppNavigationStyle.dockedBar,
    hasGeometricDecorations: true,
    primary: Color(0xFF06B6D4), // Cyan Vector
    secondary: Color(0xFFF43F5E), // Rose Coral
    accent: Color(0xFFF59E0B), // Electric Amber
    background: Color(0xFF0E131F),
    surface: Color(0xFF161F33),
    cardColor: Color(0xFF1C2740),
    textPrimary: Color(0xFFF0F4FC),
    textSecondary: Color(0xFF94A3B8),
    borderColor: Color(0xFF2C3E66),
    dividerColor: Color(0xFF223152),
    success: Color(0xFF10B981),
    warning: Color(0xFFF59E0B),
    error: Color(0xFFF43F5E),
    cardRadius: 14.0,
    buttonRadius: 10.0,
    borderWidth: 1.4,
    elevation: 0.0,
    shadowColor: Color(0x2406B6D4),
    shadowBlurRadius: 10.0,
    density: ThemeDensity.comfortable,
    cardStyle: CardVisualVariant.flat,
    fontFamily: 'Space Grotesk',
    fontScale: 1.0,
    headingWeight: FontWeight.w700,
    bodyWeight: FontWeight.w400,
    isDark: true,
    isAmoled: false,
  );

  // -------------------------------------------------------------
  // UI Style 05 — Neo-Brutalist (Solid 2.5px borders, hard drop shadows)
  // -------------------------------------------------------------
  static const neoBrutalist = DayFlowThemeTokens(
    id: neoBrutalistId,
    name: 'Neo-Brutalist',
    description: 'Dark carbon background, solid 2.5px borders, electric yellow punch, hard shadows',
    designStyle: AppDesignStyle.neoBrutalist,
    navigationStyle: AppNavigationStyle.brutalistSolid,
    isBrutalist: true,
    primary: Color(0xFFFACC15), // Electric Canary Yellow
    secondary: Color(0xFF38BDF8), // Cyan
    accent: Color(0xFFFB7185), // Coral
    background: Color(0xFF0F0F10),
    surface: Color(0xFF1A1A1C),
    cardColor: Color(0xFF222226),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFA1A1AA),
    borderColor: Color(0xFFFFFFFF), // Bold Solid White border
    dividerColor: Color(0xFF3F3F46),
    success: Color(0xFF22C55E),
    warning: Color(0xFFEAB308),
    error: Color(0xFFEF4444),
    cardRadius: 4.0,
    buttonRadius: 4.0,
    borderWidth: 2.5,
    elevation: 0.0,
    shadowColor: Color(0xFFFACC15),
    shadowBlurRadius: 0.0,
    shadowOffset: Offset(4, 4),
    brutalistShadowOffset: Offset(4, 4),
    density: ThemeDensity.comfortable,
    cardStyle: CardVisualVariant.brutalist,
    fontFamily: 'Space Grotesk',
    fontScale: 1.0,
    headingWeight: FontWeight.w800,
    bodyWeight: FontWeight.w600,
    isDark: true,
    isAmoled: false,
  );

  // -------------------------------------------------------------
  // UI Style 06 — Paper Journal (Warm cream paper, serif typography)
  // -------------------------------------------------------------
  static const paperJournal = DayFlowThemeTokens(
    id: paperJournalId,
    name: 'Paper Journal',
    description: 'Warm cream parchment, ruled notebook lines, elegant serif editorial writing feel',
    designStyle: AppDesignStyle.paperJournal,
    navigationStyle: AppNavigationStyle.editorialMinimal,
    hasPaperTexture: true,
    primary: Color(0xFF9A3412), // Warm Terracotta Sepia
    secondary: Color(0xFF3F6212), // Forest Olive Sage
    accent: Color(0xFFB45309), // Cognac Gold
    background: Color(0xFFFDFBF7), // Warm Parchment
    surface: Color(0xFFF5EFE6), // Warm paper surface
    cardColor: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF292524), // Warm Charcoal Ink
    textSecondary: Color(0xFF78716C), // Muted Stone
    borderColor: Color(0xFFE7DFD5), // Fine notebook rule
    dividerColor: Color(0xFFEFE8DE),
    success: Color(0xFF15803D),
    warning: Color(0xFFB45309),
    error: Color(0xFFB91C1C),
    cardRadius: 10.0,
    buttonRadius: 8.0,
    borderWidth: 1.0,
    elevation: 0.0,
    shadowColor: Color(0x0F000000),
    shadowBlurRadius: 6.0,
    shadowOffset: Offset(0, 2),
    density: ThemeDensity.comfortable,
    cardStyle: CardVisualVariant.paper,
    fontFamily: 'Merriweather',
    fontScale: 1.0,
    headingWeight: FontWeight.w700,
    bodyWeight: FontWeight.w400,
    isDark: false,
    isAmoled: false,
  );

  // -------------------------------------------------------------
  // UI Style 07 — Nordic Calm (Scandinavian natural serenity, sage green)
  // -------------------------------------------------------------
  static const nordicCalm = DayFlowThemeTokens(
    id: nordicCalmId,
    name: 'Nordic Calm',
    description: 'Scandinavian simplicity, soft arctic neutrals, eucalyptus sage, tranquil harmony',
    designStyle: AppDesignStyle.nordicCalm,
    navigationStyle: AppNavigationStyle.dockedBar,
    primary: Color(0xFF4A7C59), // Nordic Eucalyptus Sage
    secondary: Color(0xFF5B8296), // Muted Fjord Blue
    accent: Color(0xFF9FB1BC), // Mist Gray
    background: Color(0xFFF4F6F4), // Arctic Mist
    surface: Color(0xFFEBEFEA),
    cardColor: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF1E2824),
    textSecondary: Color(0xFF67776E),
    borderColor: Color(0xFFDCE3DC),
    dividerColor: Color(0xFFE5ECE5),
    success: Color(0xFF4A7C59),
    warning: Color(0xFFD97706),
    error: Color(0xFFDC2626),
    cardRadius: 16.0,
    buttonRadius: 12.0,
    borderWidth: 1.0,
    elevation: 0.0,
    shadowColor: Color(0x0A000000),
    shadowBlurRadius: 10.0,
    shadowOffset: Offset(0, 3),
    density: ThemeDensity.spacious,
    cardStyle: CardVisualVariant.outlined,
    fontFamily: 'Inter',
    fontScale: 1.0,
    headingWeight: FontWeight.w600,
    bodyWeight: FontWeight.w400,
    isDark: false,
    isAmoled: false,
  );

  // -------------------------------------------------------------
  // UI Style 08 — Modern Editorial (High-end publication, bold serif)
  // -------------------------------------------------------------
  static const modernEditorial = DayFlowThemeTokens(
    id: modernEditorialId,
    name: 'Modern Editorial',
    description: 'High-end publication aesthetics, Playfair typography, bordeaux and gold accents',
    designStyle: AppDesignStyle.modernEditorial,
    navigationStyle: AppNavigationStyle.editorialMinimal,
    primary: Color(0xFFD97706), // Cognac Gold
    secondary: Color(0xFF991B1B), // Bordeaux Red
    accent: Color(0xFF38BDF8), // Editorial Cyan
    background: Color(0xFF121316), // Dark Slate Charcoal
    surface: Color(0xFF1A1C21),
    cardColor: Color(0xFF22242B),
    textPrimary: Color(0xFFFAF9F6), // Warm Off-White
    textSecondary: Color(0xFFA1A1AA),
    borderColor: Color(0xFF323640),
    dividerColor: Color(0xFF292C35),
    success: Color(0xFF22C55E),
    warning: Color(0xFFD97706),
    error: Color(0xFFEF4444),
    cardRadius: 10.0,
    buttonRadius: 8.0,
    borderWidth: 1.0,
    elevation: 0.0,
    shadowColor: Colors.transparent,
    shadowBlurRadius: 0.0,
    density: ThemeDensity.comfortable,
    cardStyle: CardVisualVariant.outlined,
    fontFamily: 'Playfair Display',
    fontScale: 1.0,
    headingWeight: FontWeight.w700,
    bodyWeight: FontWeight.w400,
    isDark: true,
    isAmoled: false,
  );

  // -------------------------------------------------------------
  // UI Style 09 — Soft Neo-Modern (Pillowy 24px curves, playful pastels)
  // -------------------------------------------------------------
  static const softNeoModern = DayFlowThemeTokens(
    id: softNeoModernId,
    name: 'Soft Neo-Modern',
    description: 'Pillowy rounded components, soft lavender and peach palette, diffuse lighting',
    designStyle: AppDesignStyle.softNeoModern,
    navigationStyle: AppNavigationStyle.floatingPill,
    primary: Color(0xFF8B5CF6), // Soft Violet Lavender
    secondary: Color(0xFFFB7185), // Peach Rose
    accent: Color(0xFF38BDF8), // Powder Blue
    background: Color(0xFF0F121C),
    surface: Color(0xFF171B2B),
    cardColor: Color(0xFF20263C),
    textPrimary: Color(0xFFF8FAFC),
    textSecondary: Color(0xFFA5B4CB),
    borderColor: Color(0xFF313A5C),
    dividerColor: Color(0xFF262E48),
    success: Color(0xFF34D399),
    warning: Color(0xFFFBBF24),
    error: Color(0xFFFB7185),
    cardRadius: 24.0, // Pillowy curves
    buttonRadius: 18.0,
    borderWidth: 1.0,
    elevation: 0.0,
    shadowColor: Color(0x33000000),
    shadowBlurRadius: 18.0,
    shadowOffset: Offset(0, 6),
    density: ThemeDensity.comfortable,
    cardStyle: CardVisualVariant.flat,
    fontFamily: 'Outfit',
    fontScale: 1.0,
    headingWeight: FontWeight.w700,
    bodyWeight: FontWeight.w400,
    isDark: true,
    isAmoled: false,
  );

  // -------------------------------------------------------------
  // UI Style 10 — Futuristic Spatial (VisionOS layered surfaces, cyan luminescence)
  // -------------------------------------------------------------
  static const futuristicSpatial = DayFlowThemeTokens(
    id: futuristicSpatialId,
    name: 'Futuristic Spatial',
    description: 'Spatial dimensional surfaces, luminescent cyan and violet specular depth',
    designStyle: AppDesignStyle.futuristicSpatial,
    navigationStyle: AppNavigationStyle.floatingPill,
    primary: Color(0xFF06B6D4), // Spatial Cyan
    secondary: Color(0xFFA855F7), // Nebula Purple
    accent: Color(0xFF3B82F6), // Photon Blue
    background: Color(0xFF05070D), // Space Void
    surface: Color(0xFF0B101E),
    cardColor: Color(0xFF11182D),
    textPrimary: Color(0xFFF0FDF4),
    textSecondary: Color(0xFF94A3B8),
    borderColor: Color(0xFF1E293B),
    dividerColor: Color(0xFF172033),
    success: Color(0xFF06B6D4),
    warning: Color(0xFFFBBF24),
    error: Color(0xFFF43F5E),
    cardRadius: 18.0,
    buttonRadius: 14.0,
    borderWidth: 1.2,
    elevation: 0.0,
    shadowColor: Color(0x3D06B6D4),
    shadowBlurRadius: 16.0,
    shadowOffset: Offset(0, 4),
    hasBackgroundGradient: true,
    backgroundGradient: [
      Color(0xFF05070D),
      Color(0xFF0C1326),
      Color(0xFF070B18),
    ],
    density: ThemeDensity.comfortable,
    cardStyle: CardVisualVariant.spatial,
    fontFamily: 'Outfit',
    fontScale: 1.0,
    headingWeight: FontWeight.w700,
    bodyWeight: FontWeight.w400,
    isDark: true,
    isAmoled: false,
  );

  // -------------------------------------------------------------
  // Custom Theme Seed Default
  // -------------------------------------------------------------
  static const customThemeSeed = DayFlowThemeTokens(
    id: customThemeId,
    name: 'Custom Theme',
    description: 'Fully personalized theme tailored to your preferences',
    isCustom: true,
    designStyle: AppDesignStyle.custom,
    navigationStyle: AppNavigationStyle.dockedBar,
    primary: Color(0xFF6366F1),
    secondary: Color(0xFF06B6D4),
    accent: Color(0xFFF59E0B),
    background: Color(0xFF0F172A),
    surface: Color(0xFF1E293B),
    cardColor: Color(0xFF1E293B),
    textPrimary: Color(0xFFF8FAFC),
    textSecondary: Color(0xFF94A3B8),
    borderColor: Color(0xFF334155),
    dividerColor: Color(0xFF1E293B),
    success: Color(0xFF10B981),
    warning: Color(0xFFF59E0B),
    error: Color(0xFFEF4444),
    cardRadius: 16.0,
    buttonRadius: 12.0,
    borderWidth: 1.0,
    elevation: 0.0,
    shadowColor: Color(0x1F000000),
    shadowBlurRadius: 8.0,
    shadowOffset: Offset(0, 2),
    density: ThemeDensity.comfortable,
    cardStyle: CardVisualVariant.outlined,
    fontFamily: 'Inter',
    fontScale: 1.0,
    headingWeight: FontWeight.w700,
    bodyWeight: FontWeight.w400,
    isDark: true,
    isAmoled: false,
  );

  /// All 10 Distinct UI Design Systems in official order
  static List<DayFlowThemeTokens> get allBuiltInPresets => [
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
      ];

  static DayFlowThemeTokens getById(String id) {
    for (final preset in allBuiltInPresets) {
      if (preset.id == id) return preset;
    }
    // Backward compatibility mappings
    switch (id) {
      case 'cyber_neon':
      case 'tokyo_synthwave':
        return vectorStudio;
      case 'draculaNoir':
      case 'midnight_aurora':
      case 'emerald_oled':
        return obsidianAmoled;
      case 'nord_dark_frost':
        return nordicCalm;
      case 'neo_brutalist_dark':
        return neoBrutalist;
      case 'high_contrast':
        return obsidianAmoled;
      default:
        return obsidianAmoled;
    }
  }
}
