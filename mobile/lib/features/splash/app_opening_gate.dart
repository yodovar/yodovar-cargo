import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

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
              logoScale: _logoScale!,
              logoOpacity: _logoOpacity!,
              titleSlide: _titleSlide!,
              underlineWidth: _underlineWidth!,
            )
          : const AuthRoot(key: ValueKey('auth')),
    );
  }
}

class _OpeningSplashPage extends StatefulWidget {
  const _OpeningSplashPage({
    super.key,
    required this.controller,
    required this.logoScale,
    required this.logoOpacity,
    required this.titleSlide,
    required this.underlineWidth,
  });

  final AnimationController controller;
  final Animation<double> logoScale;
  final Animation<double> logoOpacity;
  final Animation<double> titleSlide;
  final Animation<double> underlineWidth;

  @override
  State<_OpeningSplashPage> createState() => _OpeningSplashPageState();
}

class _OpeningSplashPageState extends State<_OpeningSplashPage> {
  bool _brandTyped = false;

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
          animation: widget.controller,
          builder: (context, child) {
            return ColoredBox(
              color: Colors.white,
              child: SafeArea(
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    Opacity(
                      opacity: widget.logoOpacity.value,
                      child: Transform.scale(
                        scale: widget.logoScale.value,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Image.asset(
                            'assets/images/logo.PNG',
                            height: logoH,
                            width: MediaQuery.sizeOf(context).width * 0.96,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Image.asset(
                              'assets/images/logo.png',
                              height: logoH,
                              width: MediaQuery.sizeOf(context).width * 0.96,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(
                                Icons.local_shipping_rounded,
                                size: 72,
                                color: AppTheme.brandRed,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Transform.translate(
                      offset: Offset(0, 20 * (1 - widget.titleSlide.value)),
                      child: Opacity(
                        opacity: widget.titleSlide.value,
                        child: Column(
                          children: [
                            _TypewriterBrandBlock(
                              onComplete: () {
                                if (_brandTyped) return;
                                setState(() => _brandTyped = true);
                              },
                            ),
                            const SizedBox(height: 12),
                            LayoutBuilder(
                              builder: (context, c) {
                                final progress = _brandTyped
                                    ? widget.underlineWidth.value
                                    : 0.0;
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
                      ),
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

/// Печатает «INSOF», затем «CARGO» по буквам; мигающий курсор.
class _TypewriterBrandBlock extends StatefulWidget {
  const _TypewriterBrandBlock({required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<_TypewriterBrandBlock> createState() => _TypewriterBrandBlockState();
}

class _TypewriterBrandBlockState extends State<_TypewriterBrandBlock> {
  static const _line1 = 'INSOF';
  static const _line2 = 'CARGO';

  Timer? _tick;
  int _i1 = 0;
  int _i2 = 0;
  bool _phase2 = false;
  bool _finished = false;
  bool _cursorOn = true;
  Timer? _cursorBlink;

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
  void initState() {
    super.initState();
    _cursorBlink = Timer.periodic(const Duration(milliseconds: 530), (_) {
      if (!mounted || _finished) return;
      setState(() => _cursorOn = !_cursorOn);
    });
    Future<void>.delayed(const Duration(milliseconds: 380), () {
      if (!mounted) return;
      _tick = Timer.periodic(const Duration(milliseconds: 72), (t) {
        if (!mounted) return;
        if (_i1 < _line1.length) {
          setState(() => _i1++);
          return;
        }
        if (!_phase2) {
          _phase2 = true;
          t.cancel();
          Future<void>.delayed(const Duration(milliseconds: 220), () {
            if (!mounted) return;
            _tick = Timer.periodic(const Duration(milliseconds: 72), (t2) {
              if (!mounted) return;
              if (_i2 < _line2.length) {
                setState(() => _i2++);
              } else {
                t2.cancel();
                if (!_finished) {
                  _finished = true;
                  widget.onComplete();
                }
                setState(() {});
              }
            });
          });
          return;
        }
      });
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _cursorBlink?.cancel();
    super.dispose();
  }

  bool get _line1Done => _i1 >= _line1.length;
  bool get _line2Done => _i2 >= _line2.length;

  @override
  Widget build(BuildContext context) {
    final n1 = _i1.clamp(0, _line1.length);
    final n2 = _i2.clamp(0, _line2.length);
    final s1 = _line1.substring(0, n1);
    final s2 = _line2.substring(0, n2);
    final showCursor = !_finished && _cursorOn;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(s1, style: _styleTop),
            if (!_line1Done && showCursor)
              Text(
                '|',
                style: _styleTop.copyWith(color: AppTheme.brandRed),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(s2, style: _styleBottom),
            if (_line1Done && !_line2Done && showCursor)
              Text(
                '|',
                style: _styleBottom.copyWith(color: AppTheme.brandRed),
              ),
          ],
        ),
      ],
    );
  }
}
