import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fastshare/routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  // Brand color from design system
  static const Color _backgroundColor = Color(0xFF0F3D33);

  // Total animation duration: 1500ms (1.5s) for fast app feel
  // This is optimized for human perception and modern UI standards
  static const Duration _animationDuration = Duration(milliseconds: 1500);

  @override
  void initState() {
    super.initState();
    _configureSystemUI();
    _setupAnimations();
    _startSequence();
  }

  void _configureSystemUI() {
    // Match system UI colors to splash background for seamless transition
    // This prevents jarring color flashes during app launch
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: _backgroundColor,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: _backgroundColor,
      systemNavigationBarIconBrightness: Brightness.light,
    ));
    // Use edge-to-edge mode for modern Android UIs instead of immersive.
    // Replaces previous usage of `SystemUiMode.immersive` to allow
    // gesture navigation and proper insets handling.
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );
  }

  void _setupAnimations() {
    _controller = AnimationController(
      vsync: this,
      duration: _animationDuration,
    );

    // Opacity sequence: fade in (0-400ms) → hold (400-1100ms) → fade out (1100-1500ms)
    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 27, // 400ms / 1500ms ≈ 27%
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: 47, // 700ms / 1500ms ≈ 47%
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 27, // 400ms / 1500ms ≈ 27%
      ),
    ]).animate(_controller);

    // Scale sequence: grow (0-400ms) → hold (400-1500ms)
    // Subtle growth (0.9 → 1.0) for elegant entrance
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.9, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 27, // 400ms / 1500ms ≈ 27%
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: 73, // 1100ms / 1500ms ≈ 73%
      ),
    ]).animate(_controller);
  }

  Future<void> _startSequence() async {
    // Play animation
    await _controller.forward();

    // Engine settle buffer: minimal delay for Flutter to stabilize frame before nav
    // This prevents jank when pushing the new route
    await Future.delayed(const Duration(milliseconds: 100));

    // Navigate only if widget is still mounted (handles early disposal)
    if (mounted) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              ),
            );
          },
          // Logo asset - pre-loaded in pubspec.yaml
          child: Image.asset(
            'assets/images/splash_logo.png',
            width: 140,
            height: 140,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
