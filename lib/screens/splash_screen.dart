import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../ui.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key, this.onDarkModeChanged});

  final Future<void> Function(bool enabled)? onDarkModeChanged;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 22),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const BrandLogo(size: 82),
                    const SizedBox(height: 8),
                    const _WelcomeMotionHero(),
                    const SizedBox(height: 8),
                    Text(
                      'Your school records,\nin order.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 32,
                        height: 1.08,
                        letterSpacing: -1.1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Request official documents, stay organized, and follow every request from start to finish.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 14,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 22),
                    PrimaryButton(
                      label: 'Get Started',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: () => Navigator.pushNamed(context, '/login'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 18,
            child: AppThemeToggle(onChanged: onDarkModeChanged),
          ),
        ],
      ),
    ),
  );
}

class _WelcomeMotionHero extends StatefulWidget {
  const _WelcomeMotionHero();

  @override
  State<_WelcomeMotionHero> createState() => _WelcomeMotionHeroState();
}

class _WelcomeMotionHeroState extends State<_WelcomeMotionHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  );
  bool? _animationsEnabled;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final enabled = !MediaQuery.disableAnimationsOf(context);
    if (_animationsEnabled == enabled) return;
    _animationsEnabled = enabled;
    if (enabled) {
      _motion.repeat();
    } else {
      _motion
        ..stop()
        ..value = .25;
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 226,
    child: AnimatedBuilder(
      animation: _motion,
      builder: (context, _) {
        final phase = _motion.value * math.pi * 2;
        final bob = math.sin(phase);
        final orbitX = math.cos(phase);
        final orbitY = math.sin(phase);
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Transform.scale(
              scale: 1 + .035 * bob,
              child: Container(
                width: 206,
                height: 206,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: .20),
                      AppColors.primary.withValues(alpha: .07),
                      AppColors.primary.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              width: 176,
              height: 176,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(
                    alpha: .10 + .06 * (bob + 1) / 2,
                  ),
                  width: 1,
                ),
              ),
            ),
            Transform.translate(
              offset: Offset(0, -5 * bob),
              child: Transform.rotate(
                angle: -.035 * bob,
                child: _DocumentIllustration(),
              ),
            ),
            Positioned(
              left: 13 + 5 * orbitX,
              top: 34 + 5 * orbitY,
              child: _FloatingBadge(
                icon: Icons.bolt_rounded,
                label: 'REQUEST',
                color: AppColors.primary,
              ),
            ),
            Positioned(
              right: 5 - 4 * orbitX,
              bottom: 38 - 5 * orbitY,
              child: _FloatingBadge(
                icon: Icons.check_circle_rounded,
                label: 'READY',
                color: AppColors.green,
              ),
            ),
            Positioned(
              right: 46 + 4 * orbitY,
              top: 20 + 4 * orbitX,
              child: _OrbitDot(
                size: 11,
                color: AppColors.orange,
                opacity: .65 + .25 * (bob + 1) / 2,
              ),
            ),
            Positioned(
              left: 50 - 4 * orbitY,
              bottom: 17 + 4 * orbitX,
              child: _OrbitDot(
                size: 7,
                color: AppColors.primary,
                opacity: .55 + .35 * (bob + 1) / 2,
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _DocumentIllustration extends StatelessWidget {
  const _DocumentIllustration();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 138,
    height: 170,
    child: Stack(
      children: [
        Positioned(
          left: 14,
          top: 8,
          child: Transform.rotate(
            angle: .105,
            child: Container(
              width: 116,
              height: 150,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: .20),
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 17, 14, 13),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .20),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: AppColors.paleBlue,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  Icons.description_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'OFFICIAL DOCUMENT',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 7,
                  letterSpacing: .7,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Container(
                width: 78,
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.text.withValues(alpha: .86),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 99,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.muted.withValues(alpha: .32),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 72,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.muted.withValues(alpha: .22),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    color: AppColors.primary,
                    size: 12,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'TRACK STATUS',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 7,
                      letterSpacing: .35,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _FloatingBadge extends StatelessWidget {
  const _FloatingBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: AppColors.border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .14),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: AppColors.text,
            fontSize: 8,
            letterSpacing: .55,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _OrbitDot extends StatelessWidget {
  const _OrbitDot({
    required this.size,
    required this.color,
    required this.opacity,
  });

  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color.withValues(alpha: opacity),
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(color: color.withValues(alpha: opacity * .5), blurRadius: 12),
      ],
    ),
  );
}
