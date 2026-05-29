import 'package:flutter/material.dart';

class Responsive {
  final BuildContext context;
  late final double _width;
  late final double _height;
  late final double _pixelRatio;

  Responsive(this.context) {
    final media = MediaQuery.of(context);
    _width = media.size.width;
    _height = media.size.height;
    _pixelRatio = media.devicePixelRatio;
  }

  // ── Tailles écran ──
  double get width => _width;
  double get height => _height;
  double get pixelRatio => _pixelRatio;

  // ── Types d'écran ──
  bool get isMobile => _width < 600;
  bool get isTablet => _width >= 600 && _width < 900;
  bool get isDesktop => _width >= 900;
  bool get isSmallPhone => _width < 360;
  bool get isLargePhone => _width >= 400;

  // ── Dimensions adaptatives ──
  double get horizontalPadding => isMobile ? 16 : isTablet ? 24 : 32;
  double get verticalPadding => isMobile ? 12 : 16;
  double get cardPadding => isMobile ? 12 : 16;
  double get borderRadius => isMobile ? 12 : 16;

  // ── Fonts adaptatifs ──
  double get fontXS => isSmallPhone ? 9 : 10;
  double get fontSm => isSmallPhone ? 10 : 11;
  double get fontMd => isSmallPhone ? 12 : 13;
  double get fontLg => isSmallPhone ? 14 : 15;
  double get fontXL => isSmallPhone ? 16 : 18;
  double get fontXXL => isSmallPhone ? 20 : 24;
  double get fontTitle => isSmallPhone ? 18 : 20;

  // ── Icônes adaptatives ──
  double get iconXS => isMobile ? 14 : 16;
  double get iconSm => isMobile ? 16 : 18;
  double get iconMd => isMobile ? 20 : 22;
  double get iconLg => isMobile ? 24 : 28;
  double get iconXL => isMobile ? 32 : 36;

  // ── Hauteurs ──
  double get appBarHeight => isMobile ? 56 : 64;
  double get bottomNavHeight => isSmallPhone ? 52 : 56;
  double get buttonHeight => isMobile ? 48 : 52;
  double get inputHeight => isMobile ? 48 : 52;
  double get cardHeight => isMobile ? 100 : 120;

  // ── Grilles ──
  int get gridColumns => isMobile ? 2 : isTablet ? 3 : 4;
  double get gridAspectRatio => isMobile ? 1.5 : 1.8;

  // ── Helpers ──
  // Pourcentage de la largeur
  double wp(double percent) => _width * percent / 100;
  // Pourcentage de la hauteur
  double hp(double percent) => _height * percent / 100;
  // Taille adaptative (mobile, tablet, desktop)
  double adaptive(double mobile, [double? tablet, double? desktop]) {
    if (isDesktop && desktop != null) return desktop;
    if (isTablet && tablet != null) return tablet;
    return mobile;
  }

  // ── Widget builder adaptatif ──
  static Widget builder({
    required BuildContext context,
    required Widget Function(Responsive r) builder,
  }) {
    return builder(Responsive(context));
  }
}

// ── Extension BuildContext ──
extension ResponsiveContext on BuildContext {
  Responsive get r => Responsive(this);
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  bool get isMobile => MediaQuery.of(this).size.width < 600;
  bool get isTablet => MediaQuery.of(this).size.width >= 600;
  bool get isSmallPhone => MediaQuery.of(this).size.width < 360;
  EdgeInsets get pagePadding => EdgeInsets.symmetric(
      horizontal: isMobile ? 16 : 24);
}

// ── Widget Responsive ──
class ResponsiveWidget extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveWidget({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 900 && desktop != null) return desktop!;
    if (width >= 600 && tablet != null) return tablet!;
    return mobile;
  }
}