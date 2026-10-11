import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/storage_service.dart';
import 'dayflow_theme_presets.dart';
import 'dayflow_theme_tokens.dart';

class ThemeState {
  final DayFlowThemeTokens currentTheme;
  final List<DayFlowThemeTokens> customThemes;
  final AppThemeModePreference modePreference;

  const ThemeState({
    required this.currentTheme,
    this.customThemes = const [],
    this.modePreference = AppThemeModePreference.system,
  });

  ThemeState copyWith({
    DayFlowThemeTokens? currentTheme,
    List<DayFlowThemeTokens>? customThemes,
    AppThemeModePreference? modePreference,
  }) {
    return ThemeState(
      currentTheme: currentTheme ?? this.currentTheme,
      customThemes: customThemes ?? this.customThemes,
      modePreference: modePreference ?? this.modePreference,
    );
  }
}

class DayFlowThemeNotifier extends Notifier<ThemeState> {
  static const _prefActiveThemeId = 'dayflow_active_theme_id';
  static const _prefActiveThemeJson = 'dayflow_active_theme_json';
  static const _prefCustomThemesJson = 'dayflow_custom_themes_json';
  static const _prefThemeModePref = 'dayflow_theme_mode_pref';

  static ThemeState? preloadedState;

  @override
  ThemeState build() {
    if (preloadedState != null) {
      return preloadedState!;
    }
    _loadFromPreferences();
    return const ThemeState(currentTheme: DayFlowThemePresets.obsidianAmoled);
  }

  static Future<ThemeState> loadInitialState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final activeId = prefs.getString(_prefActiveThemeId);
      final activeJson = prefs.getString(_prefActiveThemeJson);
      final customJsonList = prefs.getStringList(_prefCustomThemesJson) ?? [];
      final modeIndex = prefs.getInt(_prefThemeModePref) ?? 0;

      final customThemes = <DayFlowThemeTokens>[];
      for (final jsonStr in customJsonList) {
        try {
          final map = jsonDecode(jsonStr) as Map<String, dynamic>;
          customThemes.add(DayFlowThemeTokens.fromJson(map));
        } catch (_) {}
      }

      DayFlowThemeTokens? selected;
      if (activeJson != null && activeJson.isNotEmpty) {
        try {
          final map = jsonDecode(activeJson) as Map<String, dynamic>;
          selected = DayFlowThemeTokens.fromJson(map);
        } catch (_) {}
      }

      if (selected == null && activeId != null) {
        final matchedCustom =
            customThemes.where((t) => t.id == activeId).toList();
        if (matchedCustom.isNotEmpty) {
          selected = matchedCustom.first;
        } else {
          selected = DayFlowThemePresets.getById(activeId);
        }
      }

      // SQLite fallback check
      if (selected == null) {
        final dbPref = await StorageService.instance.getThemePreference();
        if (dbPref != null) {
          final dbJson = dbPref['activeThemeJson'] as String?;
          final dbId = dbPref['activeThemeId'] as String?;
          if (dbJson != null && dbJson.isNotEmpty) {
            try {
              final map = jsonDecode(dbJson) as Map<String, dynamic>;
              selected = DayFlowThemeTokens.fromJson(map);
            } catch (_) {}
          }
          if (selected == null && dbId != null) {
            selected = DayFlowThemePresets.getById(dbId);
          }
        }
      }

      final result = ThemeState(
        currentTheme: selected ?? DayFlowThemePresets.obsidianAmoled,
        customThemes: customThemes,
        modePreference: AppThemeModePreference.values[
            modeIndex.clamp(0, AppThemeModePreference.values.length - 1)],
      );
      preloadedState = result;
      return result;
    } catch (_) {
      const fallback =
          ThemeState(currentTheme: DayFlowThemePresets.obsidianAmoled);
      preloadedState = fallback;
      return fallback;
    }
  }

  Future<void> _loadFromPreferences() async {
    final loaded = await loadInitialState();
    state = loaded;
  }

  Future<void> _saveToPreferences() async {
    preloadedState = state;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefActiveThemeId, state.currentTheme.id);
      await prefs.setString(
          _prefActiveThemeJson, jsonEncode(state.currentTheme.toJson()));
      final jsonList =
          state.customThemes.map((t) => jsonEncode(t.toJson())).toList();
      await prefs.setStringList(_prefCustomThemesJson, jsonList);
      await prefs.setInt(_prefThemeModePref, state.modePreference.index);
    } catch (_) {}

    try {
      await StorageService.instance.saveThemePreference(
        activeThemeId: state.currentTheme.id,
        activeThemeJson: jsonEncode(state.currentTheme.toJson()),
        customThemesJson:
            jsonEncode(state.customThemes.map((t) => t.toJson()).toList()),
        modeIndex: state.modePreference.index,
      );
    } catch (_) {}
  }

  void selectPreset(String presetId) {
    final builtIn = DayFlowThemePresets.getById(presetId);
    state = state.copyWith(currentTheme: builtIn);
    _saveToPreferences();
  }

  void selectCustomTheme(String customId) {
    final match = state.customThemes.where((t) => t.id == customId).toList();
    if (match.isNotEmpty) {
      state = state.copyWith(currentTheme: match.first);
      _saveToPreferences();
    }
  }

  void updateCurrentTheme(DayFlowThemeTokens updatedTokens) {
    if (updatedTokens.isCustom) {
      final updatedList = state.customThemes.map((t) {
        return t.id == updatedTokens.id ? updatedTokens : t;
      }).toList();

      if (!updatedList.any((t) => t.id == updatedTokens.id)) {
        updatedList.add(updatedTokens);
      }

      state = state.copyWith(
        currentTheme: updatedTokens,
        customThemes: updatedList,
      );
    } else {
      state = state.copyWith(currentTheme: updatedTokens);
    }
    _saveToPreferences();
  }

  String createCustomTheme({
    required String name,
    DayFlowThemeTokens? basedOn,
  }) {
    final base = basedOn ?? state.currentTheme;
    final newId = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    final newCustom = base.copyWith(
      id: newId,
      name: name,
      description: 'Custom theme based on ${base.name}',
      isCustom: true,
    );

    final updatedList = [...state.customThemes, newCustom];
    state = state.copyWith(
      currentTheme: newCustom,
      customThemes: updatedList,
    );
    _saveToPreferences();
    return newId;
  }

  void duplicateTheme(DayFlowThemeTokens themeToDuplicate) {
    final newId = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    final duplicated = themeToDuplicate.copyWith(
      id: newId,
      name: '${themeToDuplicate.name} (Copy)',
      description: 'Copy of ${themeToDuplicate.name}',
      isCustom: true,
    );

    final updatedList = [...state.customThemes, duplicated];
    state = state.copyWith(
      currentTheme: duplicated,
      customThemes: updatedList,
    );
    _saveToPreferences();
  }

  void renameCustomTheme(String id, String newName) {
    final updatedList = state.customThemes.map((t) {
      if (t.id == id) {
        return t.copyWith(name: newName);
      }
      return t;
    }).toList();

    DayFlowThemeTokens current = state.currentTheme;
    if (current.id == id) {
      current = current.copyWith(name: newName);
    }

    state = state.copyWith(
      currentTheme: current,
      customThemes: updatedList,
    );
    _saveToPreferences();
  }

  void deleteCustomTheme(String id) {
    final updatedList = state.customThemes.where((t) => t.id != id).toList();
    DayFlowThemeTokens current = state.currentTheme;
    if (current.id == id) {
      current = DayFlowThemePresets.obsidianAmoled;
    }

    state = state.copyWith(
      currentTheme: current,
      customThemes: updatedList,
    );
    _saveToPreferences();
  }

  void resetToDefault() {
    state = state.copyWith(
      currentTheme: DayFlowThemePresets.obsidianAmoled,
    );
    _saveToPreferences();
  }

  void setModePreference(AppThemeModePreference pref) {
    state = state.copyWith(modePreference: pref);
    _saveToPreferences();
  }

  String exportThemeToJson(DayFlowThemeTokens theme) {
    return jsonEncode(theme.toJson());
  }

  bool importThemeFromJson(String jsonString) {
    try {
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      final imported = DayFlowThemeTokens.fromJson(map);
      final newId = 'custom_imported_${DateTime.now().millisecondsSinceEpoch}';
      final readyTheme = imported.copyWith(
        id: newId,
        isCustom: true,
      );
      final updatedList = [...state.customThemes, readyTheme];
      state = state.copyWith(
        currentTheme: readyTheme,
        customThemes: updatedList,
      );
      _saveToPreferences();
      return true;
    } catch (_) {
      return false;
    }
  }
}

final themeNotifierProvider =
    NotifierProvider<DayFlowThemeNotifier, ThemeState>(
  DayFlowThemeNotifier.new,
);

final activeThemeTokensProvider = Provider<DayFlowThemeTokens>((ref) {
  return ref.watch(themeNotifierProvider).currentTheme;
});
