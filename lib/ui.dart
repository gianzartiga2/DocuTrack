import 'package:flutter/material.dart';

class AppColors {
  static final ValueNotifier<bool> _appearance = ValueNotifier(true);
  static final ValueNotifier<double> _themeDarkness = ValueNotifier(1);

  static bool get isDarkMode => _appearance.value;
  static set isDarkMode(bool enabled) {
    _appearance.value = enabled;
    _themeDarkness.value = enabled ? 1 : 0;
  }

  static double get darkness => _themeDarkness.value;

  static void setThemeTransition(bool isDarkMode, double darkness) {
    _appearance.value = isDarkMode;
    _themeDarkness.value = darkness.clamp(0, 1);
  }

  static Color _lerp(Color light, Color dark) =>
      Color.lerp(light, dark, darkness)!;

  static Color get primary =>
      _lerp(const Color(0xFF1D5FD0), const Color(0xFF72A5FF));
  static const primaryDark = Color(0xFF4F86EE);
  static Color get background =>
      _lerp(const Color(0xFFF4F7FC), const Color(0xFF0A1020));
  static Color get surface => _lerp(Colors.white, const Color(0xFF111A2C));
  static Color get surfaceRaised =>
      _lerp(const Color(0xFFEAF0F8), const Color(0xFF17233A));
  static Color get text =>
      _lerp(const Color(0xFF14233E), const Color(0xFFEAF1FF));
  static Color get brandText {
    const darkText = Colors.black;
    const lightText = Colors.white;
    final backgroundLuminance = background.computeLuminance();
    final darkLuminance = darkText.computeLuminance();
    final lightLuminance = lightText.computeLuminance();
    final darkContrast = _contrastRatio(darkLuminance, backgroundLuminance);
    final lightContrast = _contrastRatio(lightLuminance, backgroundLuminance);
    return darkContrast >= lightContrast ? darkText : lightText;
  }

  static Color get brandAccent {
    final backgroundLuminance = background.computeLuminance();
    final primaryContrast = _contrastRatio(
      primary.computeLuminance(),
      backgroundLuminance,
    );
    if (primaryContrast >= 3) return primary;

    final darkContrast = _contrastRatio(
      Colors.black.computeLuminance(),
      backgroundLuminance,
    );
    final lightContrast = _contrastRatio(
      Colors.white.computeLuminance(),
      backgroundLuminance,
    );
    return darkContrast >= lightContrast ? Colors.black : Colors.white;
  }

  static double _contrastRatio(double firstLuminance, double secondLuminance) {
    final lighter = firstLuminance > secondLuminance
        ? firstLuminance
        : secondLuminance;
    final darker = firstLuminance > secondLuminance
        ? secondLuminance
        : firstLuminance;
    return (lighter + 0.05) / (darker + 0.05);
  }

  static Color get muted =>
      _lerp(const Color(0xFF71809A), const Color(0xFF9AAAC4));
  static Color get border =>
      _lerp(const Color(0xFFE2E9F4), const Color(0xFF293750));
  static Color get paleBlue =>
      _lerp(const Color(0xFFEAF2FF), const Color(0xFF1A2B49));
  static const green = Color(0xFF4BD49A);
  static const orange = Color(0xFFFFBD66);
  static const red = Color(0xFFFF7183);
}

class AppBackdrop extends StatefulWidget {
  const AppBackdrop({super.key, required this.child});

  final Widget child;

  @override
  State<AppBackdrop> createState() => _AppBackdropState();
}

class _AppBackdropState extends State<AppBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  );

  bool _animationsEnabled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animationsEnabled = !MediaQuery.disableAnimationsOf(context);
    if (animationsEnabled == _animationsEnabled) return;
    _animationsEnabled = animationsEnabled;
    if (animationsEnabled) {
      _animation.repeat(reverse: true);
    } else {
      _animation.stop(canceled: false);
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Positioned.fill(
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, _) => CustomPaint(
              key: const ValueKey('app-ambient-backdrop'),
              painter: _AppBackdropPainter(
                _animation.value,
                darkness: AppColors.darkness,
              ),
            ),
          ),
        ),
      ),
      widget.child,
    ],
  );
}

class AppAnimatedSwitcher extends StatelessWidget {
  const AppAnimatedSwitcher({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 240),
  });

  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final animationsEnabled = !MediaQuery.disableAnimationsOf(context);
    return AnimatedSwitcher(
      duration: animationsEnabled ? duration : Duration.zero,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, .025),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class AnimatedIndexedStack extends StatefulWidget {
  const AnimatedIndexedStack({
    super.key,
    required this.index,
    required this.children,
  });

  final int index;
  final List<Widget> children;

  @override
  State<AnimatedIndexedStack> createState() => _AnimatedIndexedStackState();
}

class _AnimatedIndexedStackState extends State<AnimatedIndexedStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _transition = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
    value: 1,
  );
  int? _previousIndex;
  int _direction = 1;

  @override
  void didUpdateWidget(covariant AnimatedIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index == widget.index) return;
    _previousIndex = oldWidget.index;
    _direction = widget.index > oldWidget.index ? 1 : -1;
    _transition.forward(from: 0);
  }

  @override
  void initState() {
    super.initState();
    _transition.addStatusListener(_handleTransitionStatus);
  }

  void _handleTransitionStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      setState(() => _previousIndex = null);
    }
  }

  @override
  void dispose() {
    _transition
      ..removeStatusListener(_handleTransitionStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _transition,
    builder: (context, _) {
      final animationsEnabled = !MediaQuery.disableAnimationsOf(context);
      final progress = animationsEnabled ? _transition.value : 1.0;
      final hiddenPages = List<int>.generate(widget.children.length, (index) {
        return index;
      });
      final pageOrder = hiddenPages
          .where((index) => index != widget.index && index != _previousIndex)
          .toList();
      if (_previousIndex case final previousIndex?) {
        pageOrder.add(previousIndex);
      }
      pageOrder.add(widget.index);
      return Stack(
        fit: StackFit.expand,
        children: pageOrder
            .map(
              (index) => _page(
                index: index,
                isCurrent: index == widget.index,
                visible:
                    index == widget.index ||
                    (animationsEnabled && index == _previousIndex),
                opacity: index == widget.index ? progress : 1 - progress,
                offset: index == widget.index
                    ? Offset(_direction * .06 * (1 - progress), 0)
                    : Offset(-_direction * .06 * progress, 0),
                width: MediaQuery.sizeOf(context).width,
              ),
            )
            .toList(),
      );
    },
  );

  Widget _page({
    required int index,
    required bool visible,
    required double opacity,
    required Offset offset,
    required double width,
    required bool isCurrent,
  }) => Positioned.fill(
    key: ValueKey('animated-page-$index'),
    child: Offstage(
      offstage: !visible,
      child: IgnorePointer(
        ignoring: !isCurrent,
        child: ExcludeSemantics(
          excluding: !isCurrent,
          child: TickerMode(
            enabled: isCurrent,
            child: Opacity(
              opacity: opacity,
              child: Transform.translate(
                offset: Offset(offset.dx * width, 0),
                child: widget.children[index],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({super.key, this.size = 24});

  final double size;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return Icon(
        Icons.hourglass_empty_rounded,
        size: size,
        color: AppColors.muted,
      );
    }
    return SizedBox(
      width: size,
      height: size,
      child: const CircularProgressIndicator(strokeWidth: 2.5),
    );
  }
}

class AnimatedEmptyState extends StatelessWidget {
  const AnimatedEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => WhiteCard(
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.paleBlue,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: AppColors.primary, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                message,
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _AppBackdropPainter extends CustomPainter {
  const _AppBackdropPainter(this.progress, {required this.darkness});

  final double progress;
  final double darkness;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(
              const Color(0xFFF5F8FE),
              const Color(0xFF0A1020),
              darkness,
            )!,
            Color.lerp(
              const Color(0xFFF0F5FC),
              const Color(0xFF0D1728),
              darkness,
            )!,
            Color.lerp(
              const Color(0xFFF8FAFE),
              const Color(0xFF0A1020),
              darkness,
            )!,
          ],
          stops: [0, .52, 1],
        ).createShader(bounds),
    );

    final drift = progress * 2 - 1;
    final glowPulse = (progress - .5).abs() * 2;
    _paintGlow(
      canvas,
      Offset(
        size.width * (.04 + drift * .09),
        size.height * (.10 + drift * .025),
      ),
      size.shortestSide * (.82 + glowPulse * .08),
      Color.lerp(const Color(0xFF8AB5FF), const Color(0xFF1D5FD0), darkness)!,
      .14 + .05 * darkness,
    );
    _paintGlow(
      canvas,
      Offset(
        size.width * (.97 - drift * .08),
        size.height * (.45 - drift * .07),
      ),
      size.shortestSide * (.78 - glowPulse * .06),
      Color.lerp(const Color(0xFFB5A6FF), const Color(0xFF354E9A), darkness)!,
      .12 + .015 * darkness,
    );
    _paintGlow(
      canvas,
      Offset(
        size.width * (.42 + drift * .06),
        size.height * (1.02 - drift * .035),
      ),
      size.shortestSide * (.82 + glowPulse * .05),
      Color.lerp(const Color(0xFF75D4CF), const Color(0xFF287EAC), darkness)!,
      .10 + .015 * darkness,
    );

    final rings = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final upperCenter = Offset(
      size.width * (.98 - drift * .045),
      size.height * (.08 + drift * .025),
    );
    rings.color = const Color(0xFF72A5FF)
        .withValues(alpha: .10 + .025 * darkness);
    canvas.drawCircle(
      upperCenter,
      size.shortestSide * (.22 + glowPulse * .025),
      rings,
    );
    rings.color = const Color(0xFF72A5FF)
        .withValues(alpha: .065 + .015 * darkness);
    canvas.drawCircle(
      upperCenter,
      size.shortestSide * (.31 - glowPulse * .02),
      rings,
    );

    final lowerCenter = Offset(
      size.width * (.02 + drift * .035),
      size.height * (.96 - drift * .025),
    );
    rings.color = const Color(0xFF72A5FF)
        .withValues(alpha: .075 + .015 * darkness);
    canvas.drawCircle(
      lowerCenter,
      size.shortestSide * (.26 + glowPulse * .025),
      rings,
    );

    final particlePaint = Paint();
    const particles = <(double, double, double)>[
      (.10, .22, 1.5),
      (.22, .72, 1.2),
      (.69, .14, 1.5),
      (.82, .28, 1.1),
      (.93, .58, 1.7),
      (.78, .82, 1.4),
      (.44, .91, 1.1),
      (.12, .48, 1.2),
      (.57, .35, 1),
      (.33, .12, 1.2),
      (.91, .9, 1.1),
      (.59, .68, 1.4),
    ];
    for (var index = 0; index < particles.length; index++) {
      final (x, y, radius) = particles[index];
      final pulse = .22 + .28 * ((progress + index * .13) % 1);
      particlePaint.color = Color.lerp(
        const Color(0xFF5679B5),
        const Color(0xFF91B6FF),
        darkness,
      )!.withValues(alpha: pulse);
      canvas.drawCircle(
        Offset(
          size.width * (x + drift * .012 * (index.isEven ? 1 : -1)),
          size.height * (y + drift * .016 * (index % 3 - 1)),
        ),
        radius + glowPulse * .25,
        particlePaint,
      );
    }
  }

  void _paintGlow(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
    double opacity,
  ) {
    final bounds = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: 0),
          ],
        ).createShader(bounds),
    );
  }

  @override
  bool shouldRepaint(_AppBackdropPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.darkness != darkness;
}

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 72, this.showName = true});

  final double size;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/DocuTrack Logo.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
        ),
        if (showName) ...[
          const SizedBox(height: 6),
          ValueListenableBuilder<double>(
            valueListenable: AppColors._themeDarkness,
            builder: (context, _, _) => RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
                children: [
                  TextSpan(
                    text: 'Docu',
                    style: TextStyle(color: AppColors.brandText),
                  ),
                  TextSpan(
                    text: 'Track',
                    style: TextStyle(color: AppColors.brandAccent),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class AppThemeToggle extends StatelessWidget {
  const AppThemeToggle({super.key, required this.onChanged});

  final Future<void> Function(bool enabled)? onChanged;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: AppColors._appearance,
    builder: (context, isDarkMode, _) => IconButton(
      tooltip: isDarkMode ? 'Switch to light theme' : 'Switch to dark theme',
      onPressed: onChanged == null
          ? null
          : () async {
              try {
                await onChanged!(!isDarkMode);
              } catch (error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        error.toString().replaceFirst('Exception: ', ''),
                      ),
                    ),
                  );
                }
              }
            },
      style: IconButton.styleFrom(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primary,
        side: BorderSide(color: AppColors.border),
      ),
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 520),
        reverseDuration: const Duration(milliseconds: 360),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => RotationTransition(
          turns: Tween<double>(begin: -.18, end: 0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: ScaleTransition(scale: animation, child: child),
        ),
        child: Icon(
          isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          key: ValueKey(isDarkMode),
          size: 20,
        ),
      ),
    ),
  );
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.outlined = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: outlined
          ? OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon ?? Icons.close, size: 17),
              label: Text(label),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            )
          : icon == null
          ? FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          : FilledButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 17),
              label: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
    );
  }
}

class ScreenHeader extends StatelessWidget {
  const ScreenHeader({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: TextStyle(
          color: AppColors.text,
          fontSize: 27,
          height: 1.1,
          letterSpacing: -.9,
          fontWeight: FontWeight.w800,
        ),
      ),
      Container(
        margin: const EdgeInsets.only(top: 9),
        width: 27,
        height: 3,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: .75),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      if (subtitle != null) ...[
        const SizedBox(height: 8),
        Text(
          subtitle!,
          style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.45),
        ),
      ],
    ],
  );
}

class BackHeader extends StatelessWidget {
  const BackHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.text),
        ),
      ),
      const SizedBox(width: 13),
      Expanded(
        child: Text(
          title,
          style: TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w800,
            letterSpacing: -.2,
          ),
        ),
      ),
    ],
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        title,
        style: TextStyle(
          color: AppColors.text,
          fontSize: 16,
          letterSpacing: -.25,
          fontWeight: FontWeight.w700,
        ),
      ),
      if (action != null)
        TextButton(
          onPressed: onAction,
          child: Text(
            action!,
            style: TextStyle(color: AppColors.primary, fontSize: 12),
          ),
        ),
    ],
  );
}

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final Color color = switch (label.toLowerCase()) {
      'processing' => AppColors.orange,
      'ready for claim' || 'completed' || 'verified' => AppColors.green,
      'active' => AppColors.green,
      'inactive' => AppColors.muted,
      'rejected' => AppColors.red,
      _ => AppColors.orange,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withValues(alpha: .12)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          letterSpacing: .15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class WhiteCard extends StatelessWidget {
  const WhiteCard({super.key, required this.child, this.padding = 14});

  final Widget child;
  final double padding;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(padding),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.border.withValues(alpha: .72)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .12),
          blurRadius: 16,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: child,
  );
}

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
    super.key,
    required this.index,
    required this.onTap,
    this.unreadCount = 0,
  });

  final int index;
  final ValueChanged<int> onTap;
  final int unreadCount;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppColors.border.withValues(alpha: .72)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .24),
            blurRadius: 22,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: onTap,
          backgroundColor: Colors.transparent,
          indicatorColor: AppColors.paleBlue,
          height: 70,
          elevation: 0,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: const Icon(Icons.description_outlined),
              selectedIcon: const Icon(Icons.description_rounded),
              label: 'Requests',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: unreadCount > 0,
                label: Text(unreadCount > 99 ? '99+' : '$unreadCount'),
                child: const Icon(Icons.notifications_none_rounded),
              ),
              selectedIcon: Badge(
                isLabelVisible: unreadCount > 0,
                label: Text(unreadCount > 99 ? '99+' : '$unreadCount'),
                child: const Icon(Icons.notifications_rounded),
              ),
              label: 'Updates',
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline_rounded),
              selectedIcon: const Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    ),
  );
}
