import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../auth/auth_root.dart';
import '../auth/auth_session.dart';
import 'cargo_preloader.dart';

/// Заставка при старте с анимацией, затем переход в [AuthRoot].
/// [skipSplash] — для тестов и автоматизации.
class AppOpeningGate extends ConsumerStatefulWidget {
  const AppOpeningGate({super.key, this.skipSplash = false});

  final bool skipSplash;

  @override
  ConsumerState<AppOpeningGate> createState() => _AppOpeningGateState();
}

class _AppOpeningGateState extends ConsumerState<AppOpeningGate>
    with TickerProviderStateMixin {
  AnimationController? _master;
  Animation<double>? _bgFade;
  Animation<double>? _logoScale;
  Animation<double>? _logoOpacity;
  Animation<double>? _titleSlide;
  Animation<double>? _underlineWidth;
  bool _splashVisible = true;

  @override
  void initState() {
    super.initState();
    if (widget.skipSplash) {
      _splashVisible = false;
      return;
    }
    _master = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    _bgFade = CurvedAnimation(
      parent: _master!,
      curve: const Interval(0, 0.4, curve: Curves.easeOut),
    );
    _logoScale = CurvedAnimation(
      parent: _master!,
      curve: const Interval(0.05, 0.55, curve: Curves.easeOutBack),
    );
    _logoOpacity = CurvedAnimation(
      parent: _master!,
      curve: const Interval(0.05, 0.45, curve: Curves.easeIn),
    );
    _titleSlide = CurvedAnimation(
      parent: _master!,
      curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
    );
    _underlineWidth = CurvedAnimation(
      parent: _master!,
      curve: const Interval(0.35, 0.85, curve: Curves.easeOutCubic),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _master?.forward();
      _runGate();
    });
  }

  Future<void> _runGate() async {
    await Future.wait([
      Future.delayed(const Duration(milliseconds: 2200)),
      _waitAuthReady(),
    ]);
    if (!mounted) return;
    setState(() => _splashVisible = false);
  }

  Future<void> _waitAuthReady() async {
    while (mounted) {
      final s = ref.read(authSessionProvider);
      if (!s.isLoading) break;
      await Future.delayed(const Duration(milliseconds: 24));
    }
  }

  @override
  void dispose() {
    _master?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.skipSplash) {
      return const AuthRoot();
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: _splashVisible
          ? _OpeningSplashPage(
              key: const ValueKey('opening'),
              controller: _master!,
              bgFade: _bgFade!,
              logoScale: _logoScale!,
              logoOpacity: _logoOpacity!,
              titleSlide: _titleSlide!,
              underlineWidth: _underlineWidth!,
            )
          : const AuthRoot(key: ValueKey('auth')),
    );
  }
}

class _OpeningSplashPage extends StatelessWidget {
  const _OpeningSplashPage({
    super.key,
    required this.controller,
    required this.bgFade,
    required this.logoScale,
    required this.logoOpacity,
    required this.titleSlide,
    required this.underlineWidth,
  });

  final AnimationController controller;
  final Animation<double> bgFade;
  final Animation<double> logoScale;
  final Animation<double> logoOpacity;
  final Animation<double> titleSlide;
  final Animation<double> underlineWidth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1D21),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          return Stack(
            fit: StackFit.expand,
            children: [
              Opacity(
                opacity: bgFade.value,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.brandRedDark,
                        AppTheme.brandRed,
                        AppTheme.brandRed.withValues(alpha: 0.85),
                      ],
                    ),
                  ),
                ),
              ),
              // Декоративные «пути»
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 120,
                child: CustomPaint(
                  painter: _RoadPainter(progress: controller.value),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    Opacity(
                      opacity: logoOpacity.value,
                      child: Transform.scale(
                        scale: logoScale.value,
                        child: Container(
                          width: MediaQuery.sizeOf(context).width * 0.9,
                          constraints: const BoxConstraints(maxWidth: 460),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 18,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.22),
                                blurRadius: 28,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/logo.png',
                            height: MediaQuery.sizeOf(context).height * 0.28,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.local_shipping_rounded,
                              size: 52,
                              color: AppTheme.brandRed,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Transform.translate(
                      offset: Offset(0, 20 * (1 - titleSlide.value)),
                      child: Opacity(
                        opacity: titleSlide.value,
                        child: Column(
                          children: [
                            const Text(
                              'INSOF',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 32,
                                letterSpacing: 4,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'CARGO',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.92),
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                                letterSpacing: 8,
                              ),
                            ),
                            const SizedBox(height: 12),
                            LayoutBuilder(
                              builder: (context, c) {
                                final w = c.maxWidth.isFinite
                                    ? c.maxWidth * 0.55 * underlineWidth.value
                                    : 200.0 * underlineWidth.value;
                                return Center(
                                  child: Container(
                                    height: 3,
                                    width: w.clamp(0.0, 280.0),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(flex: 3),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        kYodovarItFooter,
                        textAlign: TextAlign.center,
                        style: kFooterWhiteStyle.copyWith(
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.45),
                              blurRadius: 8,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RoadPainter extends CustomPainter {
  _RoadPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final y = size.height * 0.55;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    final dashW = 18.0;
    final gap = 14.0;
    final shift = (progress * (dashW + gap) * 6) % (dashW + gap);
    var x = -shift;
    final dashPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    while (x < size.width + dashW) {
      canvas.drawLine(Offset(x, y), Offset(x + dashW, y), dashPaint);
      x += dashW + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _RoadPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
