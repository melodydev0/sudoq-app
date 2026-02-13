import 'package:flutter/material.dart';

/// Responsive utilities for adaptive layouts and scalable typography
class ResponsiveUtils {
  static late MediaQueryData _mediaQueryData;
  static late double screenWidth;
  static late double screenHeight;
  static late double blockSizeHorizontal;
  static late double blockSizeVertical;
  static late double _safeAreaHorizontal;
  static late double _safeAreaVertical;
  static late double safeBlockHorizontal;
  static late double safeBlockVertical;
  static late double textScaleFactor;
  static late bool isSmallScreen;
  static late bool isMediumScreen;
  static late bool isLargeScreen;
  static late bool isTablet;

  /// Initialize responsive utils - call this in build method
  static void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;

    // Block sizes for percentage-based sizing
    blockSizeHorizontal = screenWidth / 100;
    blockSizeVertical = screenHeight / 100;

    // Safe area calculations
    _safeAreaHorizontal =
        _mediaQueryData.padding.left + _mediaQueryData.padding.right;
    _safeAreaVertical =
        _mediaQueryData.padding.top + _mediaQueryData.padding.bottom;
    safeBlockHorizontal = (screenWidth - _safeAreaHorizontal) / 100;
    safeBlockVertical = (screenHeight - _safeAreaVertical) / 100;

    // Text scale factor (clamped for accessibility)
    textScaleFactor = _mediaQueryData.textScaler.scale(1.0).clamp(0.8, 1.4);

    // Screen size categories
    isSmallScreen = screenWidth < 360;
    isMediumScreen = screenWidth >= 360 && screenWidth < 600;
    isLargeScreen = screenWidth >= 600;
    isTablet = screenWidth >= 600;
  }

  /// Get scaled font size based on screen width
  static double fontSize(double size) {
    // Base design width is 375 (iPhone SE/8 width)
    const double baseWidth = 375.0;
    double scaleFactor = screenWidth / baseWidth;

    // Clamp scale factor to prevent extreme sizes
    scaleFactor = scaleFactor.clamp(0.8, 1.3);

    return (size * scaleFactor).roundToDouble();
  }

  /// Get scaled size for general UI elements
  static double scale(double size) {
    const double baseWidth = 375.0;
    double scaleFactor = screenWidth / baseWidth;
    scaleFactor = scaleFactor.clamp(0.85, 1.25);
    return size * scaleFactor;
  }

  /// Get scaled horizontal padding
  static double horizontalPadding([double base = 20]) {
    if (isSmallScreen) return base * 0.8;
    if (isLargeScreen) return base * 1.2;
    return base;
  }

  /// Get scaled vertical padding
  static double verticalPadding([double base = 20]) {
    if (isSmallScreen) return base * 0.8;
    if (isLargeScreen) return base * 1.2;
    return base;
  }

  /// Get icon size based on screen
  static double iconSize([double base = 24]) {
    return scale(base);
  }

  /// Get button height
  static double buttonHeight([double base = 48]) {
    if (isSmallScreen) return base * 0.9;
    if (isLargeScreen) return base * 1.1;
    return base;
  }

  /// Get border radius
  static double borderRadius([double base = 16]) {
    return scale(base);
  }

  /// Adaptive grid columns
  static int gridColumns() {
    if (screenWidth < 400) return 2;
    if (screenWidth < 600) return 2;
    if (screenWidth < 900) return 3;
    return 4;
  }

  /// Get aspect ratio for difficulty cards
  static double difficultyCardAspectRatio() {
    if (isSmallScreen) return 1.4;
    if (isLargeScreen) return 1.8;
    return 1.6;
  }
}

/// Extension for easy access to responsive values
extension ResponsiveExtension on num {
  /// Scaled font size
  double get sp => ResponsiveUtils.fontSize(toDouble());

  /// Scaled size
  double get w => ResponsiveUtils.scale(toDouble());

  /// Percentage of screen width
  double get wp => ResponsiveUtils.blockSizeHorizontal * toDouble();

  /// Percentage of screen height
  double get hp => ResponsiveUtils.blockSizeVertical * toDouble();
}

/// Scalable Text Styles
class AppTextStyles {
  static TextStyle headline1(BuildContext context, {Color? color}) {
    ResponsiveUtils.init(context);
    return TextStyle(
      fontSize: 28.sp,
      fontWeight: FontWeight.bold,
      color: color,
      height: 1.2,
    );
  }

  static TextStyle headline2(BuildContext context, {Color? color}) {
    ResponsiveUtils.init(context);
    return TextStyle(
      fontSize: 24.sp,
      fontWeight: FontWeight.bold,
      color: color,
      height: 1.2,
    );
  }

  static TextStyle headline3(BuildContext context, {Color? color}) {
    ResponsiveUtils.init(context);
    return TextStyle(
      fontSize: 20.sp,
      fontWeight: FontWeight.bold,
      color: color,
      height: 1.3,
    );
  }

  static TextStyle title(BuildContext context, {Color? color}) {
    ResponsiveUtils.init(context);
    return TextStyle(
      fontSize: 18.sp,
      fontWeight: FontWeight.w600,
      color: color,
      height: 1.3,
    );
  }

  static TextStyle subtitle(BuildContext context, {Color? color}) {
    ResponsiveUtils.init(context);
    return TextStyle(
      fontSize: 16.sp,
      fontWeight: FontWeight.w500,
      color: color,
      height: 1.4,
    );
  }

  static TextStyle body(BuildContext context, {Color? color}) {
    ResponsiveUtils.init(context);
    return TextStyle(
      fontSize: 14.sp,
      fontWeight: FontWeight.normal,
      color: color,
      height: 1.5,
    );
  }

  static TextStyle bodySmall(BuildContext context, {Color? color}) {
    ResponsiveUtils.init(context);
    return TextStyle(
      fontSize: 13.sp,
      fontWeight: FontWeight.normal,
      color: color,
      height: 1.4,
    );
  }

  static TextStyle caption(BuildContext context, {Color? color}) {
    ResponsiveUtils.init(context);
    return TextStyle(
      fontSize: 12.sp,
      fontWeight: FontWeight.normal,
      color: color,
      height: 1.4,
    );
  }

  static TextStyle button(BuildContext context, {Color? color}) {
    ResponsiveUtils.init(context);
    return TextStyle(
      fontSize: 15.sp,
      fontWeight: FontWeight.w600,
      color: color,
      letterSpacing: 0.5,
    );
  }

  static TextStyle number(BuildContext context, {Color? color, double? size}) {
    ResponsiveUtils.init(context);
    return TextStyle(
      fontSize: (size ?? 20).sp,
      fontWeight: FontWeight.w600,
      color: color,
    );
  }
}

/// Responsive spacing constants
class AppSpacing {
  static double get xs => 4.w;
  static double get sm => 8.w;
  static double get md => 12.w;
  static double get lg => 16.w;
  static double get xl => 20.w;
  static double get xxl => 24.w;
  static double get xxxl => 32.w;
}

/// Responsive widget wrapper
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ResponsiveUtils utils) builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    ResponsiveUtils.init(context);
    return builder(context, ResponsiveUtils());
  }
}

/// Adaptive padding widget
class AdaptivePadding extends StatelessWidget {
  final Widget child;
  final double? horizontal;
  final double? vertical;
  final double? all;

  const AdaptivePadding({
    super.key,
    required this.child,
    this.horizontal,
    this.vertical,
    this.all,
  });

  @override
  Widget build(BuildContext context) {
    ResponsiveUtils.init(context);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal:
            horizontal?.w ?? all?.w ?? ResponsiveUtils.horizontalPadding(),
        vertical: vertical?.w ?? all?.w ?? 0,
      ),
      child: child,
    );
  }
}

/// Scalable text widget that handles overflow gracefully
class ScalableText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool softWrap;

  const ScalableText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap = true,
  });

  @override
  Widget build(BuildContext context) {
    ResponsiveUtils.init(context);

    return Text(
      text,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow ?? (maxLines != null ? TextOverflow.ellipsis : null),
      softWrap: softWrap,
    );
  }
}

/// Fitted text that scales down if needed
class FittedText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final double minFontSize;
  final double maxFontSize;
  final int? maxLines;

  const FittedText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.minFontSize = 10,
    this.maxFontSize = 100,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        text,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
      ),
    );
  }
}
