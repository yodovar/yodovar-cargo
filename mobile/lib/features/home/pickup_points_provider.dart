import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/pickup_points.dart';

final pickupPointsProvider = FutureProvider<List<PickupPoint>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final res = await dio.get<List<dynamic>>('/tariffs/pickup-points');
    final raw = res.data ?? const [];
    final parsed = raw
        .whereType<Map>()
        .map((e) => PickupPoint.fromJson(e.cast<String, dynamic>()))
        .where((p) => p.id.isNotEmpty && p.city.isNotEmpty)
        .toList(growable: false);
    if (parsed.isNotEmpty) return parsed;
  } catch (_) {
    // Fallback to embedded defaults when API is unavailable.
  }
  return pickupPoints;
});
