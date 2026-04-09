import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';
import 'app_theme.dart';

/// Аватар: загрузка с API через Dio (тот же токен, что и для запросов), затем память, иначе иконка.
class ProfileAvatarDisplay extends ConsumerStatefulWidget {
  const ProfileAvatarDisplay({
    super.key,
    required this.radius,
    this.networkUrl,
    this.memoryBytes,
    this.iconColor = AppTheme.brandRed,
  });

  final double radius;
  final String? networkUrl;
  final Uint8List? memoryBytes;
  final Color iconColor;

  @override
  ConsumerState<ProfileAvatarDisplay> createState() =>
      _ProfileAvatarDisplayState();
}

class _ProfileAvatarDisplayState extends ConsumerState<ProfileAvatarDisplay> {
  Uint8List? _fetched;
  bool _loading = false;
  CancelToken? _cancel;

  @override
  void initState() {
    super.initState();
    _scheduleFetch();
  }

  @override
  void didUpdateWidget(covariant ProfileAvatarDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.networkUrl != widget.networkUrl) {
      _scheduleFetch();
    }
  }

  void _scheduleFetch() {
    _cancel?.cancel();
    _cancel = CancelToken();
    final u = widget.networkUrl?.trim();
    if (u == null || u.isEmpty) {
      setState(() {
        _fetched = null;
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _fetched = null;
    });
    _fetch(u, _cancel!);
  }

  Future<void> _fetch(String url, CancelToken token) async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get<List<int>>(
        url,
        cancelToken: token,
        options: Options(
          responseType: ResponseType.bytes,
          validateStatus: (s) => s != null && s >= 200 && s < 400,
        ),
      );
      final raw = res.data;
      if (!mounted || token.isCancelled) return;
      if (raw == null || raw.isEmpty) {
        setState(() {
          _fetched = null;
          _loading = false;
        });
        return;
      }
      setState(() {
        _fetched = Uint8List.fromList(raw);
        _loading = false;
      });
    } catch (_) {
      if (!mounted || token.isCancelled) return;
      setState(() {
        _fetched = null;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _cancel?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.radius * 2;

    if (_fetched != null && _fetched!.isNotEmpty) {
      return ClipOval(
        child: Image.memory(
          _fetched!,
          width: d,
          height: d,
          fit: BoxFit.cover,
        ),
      );
    }

    final u = widget.networkUrl?.trim();
    if (u != null && u.isNotEmpty) {
      if (_loading) {
        return SizedBox(
          width: d,
          height: d,
          child: Center(
            child: SizedBox(
              width: widget.radius * 0.7,
              height: widget.radius * 0.7,
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      }
      if (widget.memoryBytes != null && widget.memoryBytes!.isNotEmpty) {
        return ClipOval(
          child: Image.memory(
            widget.memoryBytes!,
            width: d,
            height: d,
            fit: BoxFit.cover,
          ),
        );
      }
      return _placeholder(d);
    }

    if (widget.memoryBytes != null && widget.memoryBytes!.isNotEmpty) {
      return CircleAvatar(
        radius: widget.radius,
        backgroundColor: Colors.white,
        backgroundImage: MemoryImage(widget.memoryBytes!),
      );
    }

    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: Colors.white,
      child: Icon(
        Icons.person_rounded,
        color: widget.iconColor,
        size: widget.radius * 1.1,
      ),
    );
  }

  Widget _placeholder(double d) {
    return Container(
      width: d,
      height: d,
      color: Colors.white,
      child: Icon(
        Icons.person_rounded,
        color: widget.iconColor,
        size: widget.radius * 1.1,
      ),
    );
  }
}
