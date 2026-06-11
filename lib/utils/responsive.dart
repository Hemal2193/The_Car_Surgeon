// utils/responsive.dart

import 'package:flutter/material.dart';

class Responsive {
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 800;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 800;
  }
}
