import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dayflow/main.dart';
import 'package:dayflow/models/task_model.dart';
import 'package:dayflow/models/habit_model.dart';
import 'package:dayflow/shared/providers/app_providers.dart';
import 'package:dayflow/core/services/storage_service.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await StorageService.instance.init();
  });

  group('DayFlow Unit & Model Logic Tests', () {
    test('TaskItem recurrence and completion check', () {
      final task = TaskItem(
        id: 'test_task_1',
        title: 'Daily Morning Meditation',
        recurrence: TaskRecurrence.daily,
        priority: TaskPriority.high,
        category: 'Mindfulness',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final today = DateTime.now();
      expect(task.appliesToDate(today), isTrue);
      expect(task.isCompletedForDate(today), isFalse);

      final dateStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final completedTask = task.copyWith(
        completedDates: [dateStr],
      );
      expect(completedTask.isCompletedForDate(today), isTrue);
    });

    test('Habit streak calculation', () {
      final habit = HabitItem(
        id: 'habit_run',
        name: 'Morning Jog',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      );

      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      final twoDaysAgo = today.subtract(const Duration(days: 2));

      String toDateStr(DateTime d) =>
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

      final completions = <HabitCompletion>[
        HabitCompletion(
          id: 'c1',
          habitId: 'habit_run',
          dateStr: toDateStr(today),
          isCompleted: true,
          timestamp: today,
        ),
        HabitCompletion(
          id: 'c2',
          habitId: 'habit_run',
          dateStr: toDateStr(yesterday),
          isCompleted: true,
          timestamp: yesterday,
        ),
        HabitCompletion(
          id: 'c3',
          habitId: 'habit_run',
          dateStr: toDateStr(twoDaysAgo),
          isCompleted: true,
          timestamp: twoDaysAgo,
        ),
      ];

      final streak = calculateHabitStreak(habit, completions);
      expect(streak.currentStreak, 3);
      expect(streak.longestStreak, 3);
    });
  });

  group('DayFlow App Widget Smoke Tests', () {
    testWidgets('DayFlowApp renders shell with navigation destinations and FAB', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(
        const ProviderScope(
          child: DayFlowApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify bottom navigation destinations
      expect(find.text('Home'), findsWidgets);
      expect(find.text('Tasks'), findsWidgets);
      expect(find.text('Journal'), findsWidgets);
      expect(find.text('Insights'), findsWidgets);

      // Verify Quick Add floating action button exists
      expect(find.byType(FloatingActionButton), findsOneWidget);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });
  });
}
