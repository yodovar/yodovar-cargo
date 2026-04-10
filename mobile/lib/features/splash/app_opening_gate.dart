import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../auth/auth_root.dart';
import '../auth/auth_session.dart';
import 'cargo_preloader.dart' show kYodovarItFooter;

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
  static const _splashAnimMs = 2600;
  /// Дождаться окончания основной анимации, иначе переход рвёт картинку на полпути.
  static const _minSplashHoldMs = _splashAnimMs + 200;

  AnimationController? _master;
  Animation<double>? _logoReveal;
  Animation<double>? _line1;
  Animation<double>? _line2;
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
      duration: const Duration(milliseconds: _splashAnimMs),
    );
    _logoReveal = CurvedAnimation(
      parent: _master!,
      curve: const Interval(0.0, 0.44, curve: Curves.easeOutCubic),
    );
    _line1 = CurvedAnimation(
      parent: _master!,
      curve: const Interval(0.36, 0.62, curve: Curves.easeOutCubic),
    );
    _line2 = CurvedAnimation(
      parent: _master!,
      curve: const Interval(0.50, 0.76, curve: Curves.easeOutCubic),
    );
    _underlineWidth = CurvedAnimation(
      parent: _master!,
      curve: const Interval(0.68, 0.95, curve: Curves.easeOutCubic),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _master?.forward();
      _runGate();
    });
  }

  Future<void> _runGate() async {
    await Future.wait([
      Future.delayed(const Duration(milliseconds: _minSplashHoldMs)),
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
      duration: const Duration(milliseconds: 640),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.center,
          children: [
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      child: _splashVisible
          ? _OpeningSplashPage(
              key: const ValueKey('opening'),
              controller: _master!,
              logoReveal: _logoReveal!,
              line1: _line1!,
              line2: _line2!,
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
    required this.logoReveal,
    required this.line1,
    required this.line2,
    required this.underlineWidth,
  });

  final AnimationController controller;
  final Animation<double> logoReveal;
  final Animation<double> line1;
  final Animation<double> line2;
  final Animation<double> underlineWidth;

  static const _styleTop = TextStyle(
    color: Color(0xFF1A1D21),
    fontWeight: FontWeight.w900,
    fontSize: 34,
    letterSpacing: 5,
    height: 1.1,
  );

  static const _styleBottom = TextStyle(
    color: AppTheme.brandRedDark,
    fontWeight: FontWeight.w800,
    fontSize: 20,
    letterSpacing: 10,
    height: 1.15,
  );

  @override
  Widget build(BuildContext context) {
    const bg = Colors.white;
    final h = MediaQuery.sizeOf(context).height;
    final logoH = (h * 0.48).clamp(200.0, 440.0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: bg,
        body: AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            final t = logoReveal.value;
            final scale = 0.82 + 0.18 * t;
            final dyLogo = (1 - t) * 28.0;

            return ColoredBox(
              color: Colors.white,
              child: SafeArea(
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    RepaintBoundary(
                      child: Opacity(
                        opacity: t.clamp(0.0, 1.0),
                        child: Transform.translate(
                          offset: Offset(0, dyLogo),
                          child: Transform.scale(
                            scale: scale,
                            alignment: Alignment.center,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Image.asset(
                                'assets/images/logo.PNG',
                                height: logoH,
                                width: MediaQuery.sizeOf(context).width * 0.96,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                                errorBuilder: (_, __, ___) => Image.asset(
                                  'assets/images/logo.png',
                                  height: logoH,
                                  width:
                                      MediaQuery.sizeOf(context).width * 0.96,
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.high,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.local_shipping_rounded,
                                    size: 72,
                                    color: AppTheme.brandRed,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.translate(
                          offset: Offset(0, 18 * (1 - line1.value)),
                          child: Opacity(
                            opacity: line1.value.clamp(0.0, 1.0),
                            child: const Text('INSOF', style: _styleTop),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Transform.translate(
                          offset: Offset(0, 14 * (1 - line2.value)),
                          child: Opacity(
                            opacity: line2.value.clamp(0.0, 1.0),
                            child: const Text('CARGO', style: _styleBottom),
                          ),
                        ),
                        const SizedBox(height: 12),
                        LayoutBuilder(
                          builder: (context, c) {
                            final progress = underlineWidth.value;
                            final w = c.maxWidth.isFinite
                                ? c.maxWidth * 0.55 * progress
                                : 200.0 * progress;
                            return Center(
                              child: Container(
                                height: 3,
                                width: w.clamp(0.0, 280.0),
                                decoration: BoxDecoration(
                                  color: AppTheme.brandRed,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const Spacer(flex: 3),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        kYodovarItFooter,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.35,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
