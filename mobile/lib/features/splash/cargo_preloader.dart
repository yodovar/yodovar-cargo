import 'package:flutter/material.dart';

import '../../core/app_theme.dart';

/// Подпись внизу экранов загрузки / заставки.
const String kYodovarItFooter = 'Developed by Yodovar IT';

/// Белый текст подписи (на тёмном или полупрозрачной плашке).
const TextStyle kFooterWhiteStyle = TextStyle(
  color: Colors.white,
  fontSize: 11,
  fontWeight: FontWeight.w500,
  letterSpacing: 0.35,
  height: 1.2,
);

/// Прелоадер в стиле грузоперевозок: фура + коробки, лёгкое «дыхание».
/// Для долгих операций (сеть, инициализация).
class CargoPreloader extends StatefulWidget {
  const CargoPreloader({
    super.key,
    this.message,
    this.size = 56,
  });

  final String? message;
  final double size;

  @override
  State<CargoPreloader> createState() => _CargoPreloaderState();
}

class _CargoPreloaderState extends State<CargoPreloader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = _c.value;
            final bob = 5 * (1 - (t - 0.5).abs() * 2);
            return Transform.translate(
              offset: Offset(0, -bob),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    width: s * 2.5,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.inventory_2_rounded,
                        size: s * 0.45,
                        color: AppTheme.brandRed.withValues(alpha: 0.35 + t * 0.15),
                      ),
                      SizedBox(width: s * 0.08),
                      Icon(
                        Icons.local_shipping_rounded,
                        size: s,
                        color: AppTheme.brandRed,
                      ),
                      SizedBox(width: s * 0.08),
                      Icon(
                        Icons.inventory_2_rounded,
                        size: s * 0.45,
                        color: AppTheme.brandRed.withValues(alpha: 0.5 - t * 0.15),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        if (widget.message != null) ...[
          const SizedBox(height: 20),
          Text(
            widget.message!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }
}

/// Полноэкранная загрузка (например, пока читается сессия).
class CargoFullScreenLoader extends StatelessWidget {
  const CargoFullScreenLoader({super.key, this.message = 'Загрузка...'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F8),
      body: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.brandRed.withValues(alpha: 0.09),
                  const Color(0xFFF3F5F8),
                ],
              ),
            ),
          ),
          Center(
            child: CargoPreloader(message: message),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                ),
                child: const Text(
                  kYodovarItFooter,
                  textAlign: TextAlign.center,
                  style: kFooterWhiteStyle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
