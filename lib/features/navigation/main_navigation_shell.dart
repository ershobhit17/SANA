import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/alarm_service.dart';
import '../../core/theme/dayflow_theme_context.dart';
import '../../core/theme/dayflow_theme_tokens.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/widgets/alarm_ringing_dialog.dart';
import '../dashboard/presentation/dashboard_screen.dart';
import '../tasks/presentation/tasks_screen.dart';
import '../journal/presentation/journal_screen.dart';
import '../analytics/presentation/analytics_screen.dart';
import '../quick_add/quick_add_sheet.dart';

class MainNavigationShell extends ConsumerStatefulWidget {
  const MainNavigationShell({super.key});

  @override
  ConsumerState<MainNavigationShell> createState() =>
      _MainNavigationShellState();
}

class _MainNavigationShellState extends ConsumerState<MainNavigationShell> {
  int _currentIndex = 0;
  Timer? _alarmCheckTimer;

  final List<Widget> _pages = const [
    DashboardScreen(),
    TasksScreen(),
    JournalScreen(),
    AnalyticsScreen(),
  ];

  @override
  void initState() {
    super.initState();

    AlarmService.instance.activeAlarmNotifier.addListener(_onAlarmTriggered);

    // Periodic check every 5 seconds for due alarms
    _alarmCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      final reminders = ref.read(remindersProvider);
      final habits = ref.read(habitsProvider);
      AlarmService.instance.checkAlarms(reminders: reminders, habits: habits);
    });
  }

  void _onAlarmTriggered() {
    final event = AlarmService.instance.activeAlarmNotifier.value;
    if (event != null && mounted) {
      AlarmRingingDialog.show(context, event);
    }
  }

  @override
  void dispose() {
    _alarmCheckTimer?.cancel();
    AlarmService.instance.activeAlarmNotifier.removeListener(_onAlarmTriggered);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.themeTokens;
    final navStyle = tokens.navigationStyle;

    return Scaffold(
      backgroundColor: tokens.background,
      body: Stack(
        children: [
          // Background gradient if active theme specifies
          if (tokens.hasBackgroundGradient &&
              tokens.backgroundGradient != null)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: tokens.backgroundGradient!,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),

          // Ambient Glow Spheres for Glassmorphism & Spatial Depth
          if (tokens.isGlass || tokens.isSpatial || tokens.isDark) ...[
            Positioned(
              top: -60,
              right: -50,
              child: IgnorePointer(
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        tokens.primary.withOpacity(tokens.isGlass ? 0.30 : 0.14),
                        tokens.primary.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 280,
              left: -70,
              child: IgnorePointer(
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        tokens.secondary.withOpacity(tokens.isGlass ? 0.22 : 0.10),
                        tokens.secondary.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 100,
              right: -40,
              child: IgnorePointer(
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        tokens.accent.withOpacity(tokens.isGlass ? 0.18 : 0.08),
                        tokens.accent.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],

          // Preserved Page Stack
          IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),

          // Floating Pill Navigation Variant
          if (navStyle == AppNavigationStyle.floatingPill)
            Positioned(
              left: 20,
              right: 20,
              bottom: 18,
              child: _buildFloatingPillNav(tokens),
            ),
        ],
      ),
      floatingActionButton: navStyle == AppNavigationStyle.floatingPill
          ? null // Integrated inside floating pill
          : FloatingActionButton(
              backgroundColor: tokens.primary,
              foregroundColor: tokens.primary.computeLuminance() > 0.4
                  ? Colors.black
                  : Colors.white,
              elevation: tokens.elevation > 0 ? tokens.elevation : 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(tokens.buttonRadius),
                side: tokens.isBrutalist
                    ? const BorderSide(color: Colors.black, width: 2)
                    : BorderSide.none,
              ),
              onPressed: () => QuickAddSheet.show(context),
              tooltip: 'Quick Add',
              child: const Icon(Icons.add, size: 28),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: navStyle == AppNavigationStyle.floatingPill
          ? const SizedBox.shrink()
          : _buildStandardBottomNav(tokens),
    );
  }

  // 1. Floating Pill Navigation (Spatial, Glass Atelier, Soft Neo)
  Widget _buildFloatingPillNav(DayFlowThemeTokens tokens) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: tokens.cardColor.withOpacity(tokens.isGlass ? 0.35 : 0.85),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: tokens.isSpatial
                  ? tokens.primary.withOpacity(0.4)
                  : tokens.borderColor.withOpacity(0.5),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: tokens.isSpatial
                    ? tokens.primary.withOpacity(0.2)
                    : tokens.shadowColor,
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard,
                label: 'Home',
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.checklist_outlined,
                activeIcon: Icons.checklist,
                label: 'Tasks',
              ),
              // Floating Action in Pill Center
              GestureDetector(
                onTap: () => QuickAddSheet.show(context),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: tokens.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: tokens.primary.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.add,
                    color: tokens.primary.computeLuminance() > 0.4
                        ? Colors.black
                        : Colors.white,
                    size: 24,
                  ),
                ),
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.menu_book_outlined,
                activeIcon: Icons.menu_book,
                label: 'Journal',
              ),
              _buildNavItem(
                index: 3,
                icon: Icons.insights_outlined,
                activeIcon: Icons.insights,
                label: 'Insights',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 2. Standard / Editorial / Brutalist Bottom Navigation
  Widget _buildStandardBottomNav(DayFlowThemeTokens tokens) {
    return Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border(
          top: BorderSide(
            color: tokens.borderColor,
            width: tokens.isBrutalist ? 2.5 : tokens.borderWidth,
          ),
        ),
        boxShadow: tokens.isBrutalist
            ? [
                BoxShadow(
                  color: Colors.black,
                  offset: tokens.brutalistShadowOffset,
                  blurRadius: 0,
                )
              ]
            : tokens.shadowBlurRadius > 0
                ? [
                    BoxShadow(
                      color: tokens.shadowColor,
                      blurRadius: 6,
                      offset: const Offset(0, -2),
                    )
                  ]
                : null,
      ),
      child: BottomAppBar(
        color: tokens.surface,
        elevation: 0,
        notchMargin: 8,
        shape: const CircularNotchedRectangle(),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        height: 64,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              index: 0,
              icon: Icons.dashboard_outlined,
              activeIcon: Icons.dashboard,
              label: 'Home',
            ),
            _buildNavItem(
              index: 1,
              icon: Icons.checklist_outlined,
              activeIcon: Icons.checklist,
              label: 'Tasks',
            ),
            const SizedBox(width: 48), // Spacer for center FloatingActionButton
            _buildNavItem(
              index: 2,
              icon: Icons.menu_book_outlined,
              activeIcon: Icons.menu_book,
              label: 'Journal',
            ),
            _buildNavItem(
              index: 3,
              icon: Icons.insights_outlined,
              activeIcon: Icons.insights,
              label: 'Insights',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final tokens = context.themeTokens;
    final isSelected = _currentIndex == index;

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 22,
              color: isSelected ? tokens.primary : tokens.textSecondary,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: context.getTextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? tokens.primary : tokens.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
