import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  static const int _mobileMax = 600;
  static const int _tabletMax = 1024;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < _mobileMax;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= _mobileMax &&
      MediaQuery.of(context).size.width < _tabletMax;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= _tabletMax;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= _tabletMax) return desktop;
    if (width >= _mobileMax) return tablet ?? desktop;
    return mobile;
  }
}
