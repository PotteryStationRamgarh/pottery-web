import 'package:flutter/widgets.dart';

class ResponsiveBreakpoints {
  ResponsiveBreakpoints._();

  static const double mobile = 600;
  static const double desktop = 1024;

  static bool isMobileWidth(double width) => width < mobile;
  static bool isTabletWidth(double width) => width >= mobile && width < desktop;
  static bool isDesktopWidth(double width) => width >= desktop;

  static bool isMobile(BuildContext context) =>
      isMobileWidth(MediaQuery.sizeOf(context).width);
  static bool isTablet(BuildContext context) =>
      isTabletWidth(MediaQuery.sizeOf(context).width);
  static bool isDesktop(BuildContext context) =>
      isDesktopWidth(MediaQuery.sizeOf(context).width);
}
