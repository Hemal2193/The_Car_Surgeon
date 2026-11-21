import 'package:get/get.dart';
import 'package:tcs/screens/homepage.dart';
import 'package:tcs/screens/login/login_screen.dart';
import 'package:tcs/screens/splash/splash_screen.dart';

/// Centralized route configuration.
///
/// PROBLEMS THIS SOLVES:
/// 1. Using named routes with `opaque: true` ensures the previous route's
///    canvas is NOT visible during transitions, eliminating the black frame.
/// 2. GetX falls back to MaterialPageRoute for unnamed navigations, which
///    clears the canvas between frames. Named routes with GetPage avoid this.
/// 3. `transition: Transition.fadeIn` is faster than slide transitions and
///    doesn't create a momentary blank pixel buffer.
/// 4. `transitionDuration` is kept short (200ms) to minimize any perceived flash.
class AppRoutes {
  AppRoutes._();

  // Route names
  static const String splash = '/splash';
  static const String login = '/login';
  static const String home = '/home';
  static const String invoiceCreate = '/invoice/create';
  static const String invoicePreview = '/invoice/preview';
  static const String customerDetail = '/customer/detail';
  static const String vehicleDetail = '/vehicle/detail';
  static const String paymentHistory = '/payment/history';
  static const String reminders = '/reminders';

  /// All named routes with opaque transitions.
  ///
  /// Key properties preventing black frames:
  /// - `opaque: true` → Flutter skips compositing the previous frame behind
  ///   the new route, avoiding the momentary blank canvas.
  /// - `transition: Transition.fadeIn` → GPU-blended alpha transition,
  ///   no intermediate blank frame.
  /// - `maintainState: false` → old route's widgets are GC'd faster, freeing GPU
  ///   memory and preventing stale frame retention.
  static List<GetPage> get pages => [
    GetPage(
      name: splash,
      page: () => const SplashScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 50),
      opaque: true,
      maintainState: false,
    ),
    GetPage(
      name: login,
      page: () => const LoginScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 50),
      opaque: true,
      maintainState: false,
    ),
    GetPage(
      name: home,
      page: () => const HomePage(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 50),
      opaque: true,
      maintainState: false,
    ),
  ];

  /// Navigate with a named route—eliminates the black frame.
  static Future<T?>? to<T>(String route, {dynamic arguments}) {
    return Get.toNamed<T>(route, arguments: arguments);
  }

  /// Replace all with a named route—eliminates the black frame on replace.
  static Future<T?>? offAll<T>(String route, {dynamic arguments}) {
    return Get.offAllNamed<T>(route, arguments: arguments);
  }

  /// Replace current with a named route.
  static Future<T?>? off<T>(String route, {dynamic arguments}) {
    return Get.offNamed<T>(route, arguments: arguments);
  }
}