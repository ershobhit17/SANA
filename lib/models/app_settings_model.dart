import 'dart:convert';

class AppSettings {
  final bool timeFormat24h;
  final bool startOfWeekMonday;
  final bool hapticEnabled;
  final bool appLockEnabled;
  final String? appLockPin;
  final bool notificationsEnabled;
  final List<String> dashboardSectionOrder;
  final List<String> visibleDashboardSections;

  const AppSettings({
    this.timeFormat24h = false,
    this.startOfWeekMonday = true,
    this.hapticEnabled = true,
    this.appLockEnabled = false,
    this.appLockPin,
    this.notificationsEnabled = true,
    this.dashboardSectionOrder = const [
      'progress_ring',
      'today_tasks',
      'today_habits',
      'upcoming_reminders',
      'quick_stats',
    ],
    this.visibleDashboardSections = const [
      'progress_ring',
      'today_tasks',
      'today_habits',
      'upcoming_reminders',
      'quick_stats',
    ],
  });

  AppSettings copyWith({
    bool? timeFormat24h,
    bool? startOfWeekMonday,
    bool? hapticEnabled,
    bool? appLockEnabled,
    String? appLockPin,
    bool? notificationsEnabled,
    List<String>? dashboardSectionOrder,
    List<String>? visibleDashboardSections,
  }) {
    return AppSettings(
      timeFormat24h: timeFormat24h ?? this.timeFormat24h,
      startOfWeekMonday: startOfWeekMonday ?? this.startOfWeekMonday,
      hapticEnabled: hapticEnabled ?? this.hapticEnabled,
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
      appLockPin: appLockPin ?? this.appLockPin,
      notificationsEnabled:
          notificationsEnabled ?? this.notificationsEnabled,
      dashboardSectionOrder:
          dashboardSectionOrder ?? this.dashboardSectionOrder,
      visibleDashboardSections:
          visibleDashboardSections ?? this.visibleDashboardSections,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'timeFormat24h': timeFormat24h ? 1 : 0,
      'startOfWeekMonday': startOfWeekMonday ? 1 : 0,
      'hapticEnabled': hapticEnabled ? 1 : 0,
      'appLockEnabled': appLockEnabled ? 1 : 0,
      'appLockPin': appLockPin,
      'notificationsEnabled': notificationsEnabled ? 1 : 0,
      'dashboardSectionOrder': jsonEncode(dashboardSectionOrder),
      'visibleDashboardSections': jsonEncode(visibleDashboardSections),
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    List<String> parseList(dynamic raw, List<String> fallback) {
      if (raw == null) return fallback;
      try {
        final decoded = jsonDecode(raw.toString()) as List<dynamic>;
        return decoded.map((e) => e.toString()).toList();
      } catch (_) {
        return fallback;
      }
    }

    return AppSettings(
      timeFormat24h: (map['timeFormat24h'] as num?) == 1,
      startOfWeekMonday: (map['startOfWeekMonday'] as num?) == 1,
      hapticEnabled: (map['hapticEnabled'] as num?) == 1,
      appLockEnabled: (map['appLockEnabled'] as num?) == 1,
      appLockPin: map['appLockPin'] as String?,
      notificationsEnabled: (map['notificationsEnabled'] as num?) == 1,
      dashboardSectionOrder: parseList(
        map['dashboardSectionOrder'],
        [
          'progress_ring',
          'today_tasks',
          'today_habits',
          'upcoming_reminders',
          'quick_stats',
        ],
      ),
      visibleDashboardSections: parseList(
        map['visibleDashboardSections'],
        [
          'progress_ring',
          'today_tasks',
          'today_habits',
          'upcoming_reminders',
          'quick_stats',
        ],
      ),
    );
  }
}
