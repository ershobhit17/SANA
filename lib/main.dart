import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/services/alarm_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/storage_service.dart';
import 'core/theme/dayflow_theme_context.dart';
import 'core/theme/dayflow_theme_notifier.dart';
import 'features/splash/presentation/dayflow_splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Storage (SQLite with FFI on desktop, SharedPreferences fallback on web)
  await StorageService.instance.init();

  // Preload saved theme so app launches immediately with user's selected theme
  await DayFlowThemeNotifier.loadInitialState();

  // Initialize Notification Service
  await NotificationService.instance.init();

  // Initialize Alarm Service for loud ringing and audio
  await AlarmService.instance.init();

  runApp(
    const ProviderScope(
      child: DayFlowApp(),
    ),
  );
}

class DayFlowApp extends ConsumerWidget {
  const DayFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeTokens = ref.watch(activeThemeTokensProvider);

    return DayFlowThemeScope(
      tokens: themeTokens,
      child: MaterialApp(
        title: 'SANA',
        debugShowCheckedModeBanner: false,
        theme: themeTokens.toThemeData(),
        home: const DayFlowSplashScreen(),
      ),
    );
  }
}
