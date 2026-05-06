import 'package:flutter/material.dart';

enum DeviceType {
  mobile,    // < 600
  tablet,    // 600–1199
  desktop,   // ≥ 1200
}

class ResponsiveBreakpoints {
  static const double mobileMaxWidth = 600;
  static const double tabletMaxWidth = 1199;
  static const double desktopMinWidth = 1200;
  
  static DeviceType getDeviceType(double width) {
    if (width < mobileMaxWidth) {
      return DeviceType.mobile;
    } else if (width < desktopMinWidth) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }
  
  static bool isMobile(BuildContext context) =>
    MediaQuery.sizeOf(context).width < mobileMaxWidth;
  
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= mobileMaxWidth && width < desktopMinWidth;
  }
  
  static bool isDesktop(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= desktopMinWidth;
  
  static bool isPortrait(BuildContext context) =>
    MediaQuery.orientationOf(context) == Orientation.portrait;
  
  static bool isLandscape(BuildContext context) =>
    MediaQuery.orientationOf(context) == Orientation.landscape;
}

// Extension para acesso fácil
extension ResponsiveContext on BuildContext {
  DeviceType get deviceType =>
    ResponsiveBreakpoints.getDeviceType(
      MediaQuery.sizeOf(this).width,
    );
  
  bool get isMobile => ResponsiveBreakpoints.isMobile(this);
  bool get isTablet => ResponsiveBreakpoints.isTablet(this);
  bool get isDesktop => ResponsiveBreakpoints.isDesktop(this);
  bool get isPortrait => ResponsiveBreakpoints.isPortrait(this);
  bool get isLandscape => ResponsiveBreakpoints.isLandscape(this);
}
