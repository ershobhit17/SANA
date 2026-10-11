import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/dayflow_theme_context.dart';
import '../../../shared/widgets/dayflow_button.dart';
import '../../navigation/main_navigation_shell.dart';

class DayFlowOnboardingScreen extends ConsumerStatefulWidget {
  const DayFlowOnboardingScreen({super.key});

  @override
  ConsumerState<DayFlowOnboardingScreen> createState() =>
      _DayFlowOnboardingScreenState();
}

class _DayFlowOnboardingScreenState
    extends ConsumerState<DayFlowOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingSlideData> _slides = const [
    _OnboardingSlideData(
      icon: Icons.checklist_rounded,
      title: 'Master Tasks & Flow',
      subtitle:
          'Organize priorities with smart recurring schedules, subtasks, and instant satisfaction completion feedback.',
      colorHex: 0xFF10B981,
    ),
    _OnboardingSlideData(
      icon: Icons.repeat_rounded,
      title: 'Build Unstoppable Habits',
      subtitle:
          'Track streaks, schedule real system alarms for your routines, and watch your daily momentum grow.',
      colorHex: 0xFF6366F1,
    ),
    _OnboardingSlideData(
      icon: Icons.menu_book_rounded,
      title: 'Aesthetic Personal Journal',
      subtitle:
          'Write peaceful reflections, track your emotional mood, and preserve life memories with distraction-free autosave.',
      colorHex: 0xFFF59E0B,
    ),
    _OnboardingSlideData(
      icon: Icons.palette_rounded,
      title: '10 Distinct UI Systems',
      subtitle:
          'Switch between 10 professionally engineered design systems — from Obsidian AMOLED to Glass Atelier & Paper Journal.',
      colorHex: 0xFF06B6D4,
    ),
  ];

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MainNavigationShell(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.themeTokens;

    return Scaffold(
      backgroundColor: tokens.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Skip Action
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: tokens.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'SANA',
                        style: context.getTextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: tokens.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: _completeOnboarding,
                    child: Text(
                      'Skip',
                      style: context.getTextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: tokens.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Page View
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return _buildSlideContent(slide, tokens);
                },
              ),
            ),

            // Bottom Controls & Dots
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  // Animated Dots Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (index) {
                      final isSelected = _currentPage == index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: isSelected ? 24 : 8,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? tokens.primary
                              : tokens.borderColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),

                  // Next / Get Started Button
                  DayFlowButton(
                    label: _currentPage == _slides.length - 1
                        ? 'Get Started'
                        : 'Continue',
                    icon: _currentPage == _slides.length - 1
                        ? Icons.rocket_launch
                        : Icons.arrow_forward,
                    isFullWidth: true,
                    height: 50,
                    variant: DayFlowButtonVariant.primary,
                    onPressed: _nextPage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlideContent(_OnboardingSlideData slide, dynamic tokens) {
    final slideColor = Color(slide.colorHex);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 3D Dimensional Hero Element
          Transform(
            alignment: FractionalOffset.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateX(-0.1)
              ..rotateY(0.08),
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    slideColor,
                    slideColor.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(36),
                boxShadow: [
                  BoxShadow(
                    color: slideColor.withOpacity(0.35),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                slide.icon,
                size: 70,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 48),

          // Slide Title
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: context.getTextStyle(
              fontSize: 24,
              fontWeight: tokens.headingWeight,
              color: tokens.textPrimary,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 14),

          // Slide Subtitle
          Text(
            slide.subtitle,
            textAlign: TextAlign.center,
            style: context.getTextStyle(
              fontSize: 14,
              color: tokens.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingSlideData {
  final IconData icon;
  final String title;
  final String subtitle;
  final int colorHex;

  const _OnboardingSlideData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colorHex,
  });
}
