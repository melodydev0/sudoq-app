import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

class LottieLoader {
  static final Map<String, bool> _cache = {};

  static Future<bool> assetExists(String path) async {
    if (_cache.containsKey(path)) return _cache[path]!;
    try {
      await rootBundle.load(path);
      _cache[path] = true;
      return true;
    } catch (_) {
      _cache[path] = false;
      return false;
    }
  }

  static Widget lottieOrFallback({
    required String assetPath,
    required Widget fallback,
    AnimationController? controller,
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    bool repeat = false,
    bool animate = true,
    void Function(LottieComposition)? onLoaded,
  }) {
    return _LottieOrFallback(
      assetPath: assetPath,
      fallback: fallback,
      controller: controller,
      width: width,
      height: height,
      fit: fit,
      repeat: repeat,
      animate: animate,
      onLoaded: onLoaded,
    );
  }
}

class _LottieOrFallback extends StatefulWidget {
  final String assetPath;
  final Widget fallback;
  final AnimationController? controller;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool repeat;
  final bool animate;
  final void Function(LottieComposition)? onLoaded;

  const _LottieOrFallback({
    required this.assetPath,
    required this.fallback,
    this.controller,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.repeat = false,
    this.animate = true,
    this.onLoaded,
  });

  @override
  State<_LottieOrFallback> createState() => _LottieOrFallbackState();
}

class _LottieOrFallbackState extends State<_LottieOrFallback> {
  bool? _exists;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final exists = await LottieLoader.assetExists(widget.assetPath);
    if (mounted) setState(() => _exists = exists);
  }

  @override
  Widget build(BuildContext context) {
    if (_exists == null) {
      return SizedBox(width: widget.width, height: widget.height);
    }
    if (_exists == false) return widget.fallback;

    return Lottie.asset(
      widget.assetPath,
      controller: widget.controller,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      repeat: widget.repeat,
      animate: widget.animate,
      onLoaded: widget.onLoaded,
      errorBuilder: (context, error, stackTrace) => widget.fallback,
    );
  }
}
