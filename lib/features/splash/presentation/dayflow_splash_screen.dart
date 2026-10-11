import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/dayflow_theme_context.dart';
import '../../navigation/main_navigation_shell.dart';
import '../../onboarding/presentation/dayflow_onboarding_screen.dart';

class DayFlowSplashScreen extends ConsumerStatefulWidget {
  const DayFlowSplashScreen({super.key});

  @override
  ConsumerState<DayFlowSplashScreen> createState() =>
      _DayFlowSplashScreenState();
}

class _DayFlowSplashScreenState extends ConsumerState<DayFlowSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _glowAnimation;
  Timer? _fallbackTimer;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.9, curve: Curves.easeInOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _controller.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 400), () {
        _navigateToNextScreen();
      });
    });

    // Safety fallback so the user is never stuck on splash under any circumstance
    _fallbackTimer = Timer(const Duration(milliseconds: 2400), () {
      _navigateToNextScreen();
    });
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _navigateToNextScreen() async {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    bool onboardingSeen = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      onboardingSeen = prefs.getBool('onboarding_completed') ?? false;
    } catch (_) {
      // Default to true on error so user enters app safely
      onboardingSeen = true;
    }

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            onboardingSeen
                ? const MainNavigationShell()
                : const DayFlowOnboardingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 450),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.themeTokens;

    return Scaffold(
      backgroundColor: tokens.background,
      body: SafeArea(
        child: SizedBox.expand(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Ambient radial glow behind the logo
              AnimatedBuilder(
                animation: _glowAnimation,
                builder: (context, _) {
                  return Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFD4A373)
                              .withOpacity(0.22 * _glowAnimation.value),
                          tokens.primary
                              .withOpacity(0.12 * _glowAnimation.value),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Centered Brand Content (Logo + SANA + Subtitle)
              Center(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Sleek SANA Monogram Icon
                            Container(
                              width: 104,
                              height: 104,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFD4A373).withOpacity(0.35),
                                    blurRadius: 28,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 8),
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.5),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                                border: Border.all(
                                  color: const Color(0xFFD4A373).withOpacity(0.4),
                                  width: 1.5,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Image.asset(
                                  'assets/images/sana_logo.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(
                                      child: Text(
                                        'S',
                                        style: TextStyle(
                                          color: Color(0xFFD4A373),
                                          fontSize: 48,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),

                            // Brand Name
                            Text(
                              'SANA',
                              style: context.getTextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 4.0,
                                color: tokens.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Tagline
                            Text(
                              'Elevate Your Focus & Flow',
                              style: context.getTextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: tokens.textSecondary,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Bottom subtle indicator that does NOT overlap and looks premium
              Positioned(
                bottom: 36,
                child: AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, _) {
                    return Opacity(
                      opacity: _fadeAnimation.value * 0.7,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(3, (i) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: tokens.primary.withOpacity(0.5 + (i * 0.2)),
                            ),
                          );
                        }),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
