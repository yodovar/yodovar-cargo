import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Точка, после которой показываем боковую навигацию вместо нижней панели.
bool useWideNavigation(BuildContext context) {
  final w = MediaQuery.sizeOf(context).width;
  return w >= 600;
}

/// Максимальная ширина основного контента на планшете / десктопе (читаемость).
double contentMaxWidth(BuildContext context) {
  final w = MediaQuery.sizeOf(context).width;
  if (!w.isFinite || w <= 0) return 560;
  return math.min(960, w);
}

/// Ширина одной карточки в горизонтальной карусели статусов.
double statusCarouselCardWidth(double viewportWidth) {
  if (!viewportWidth.isFinite || viewportWidth < 120) {
    return 280;
  }
  return math.min(400, math.max(240, viewportWidth * 0.42));
}
