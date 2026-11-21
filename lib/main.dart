import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tcs/routes/app_routes.dart';
import 'package:tcs/utils/platform_utils.dart';
import 'package:window_manager/window_manager.dart';

// 1. Declare the global snackbar key
final GlobalKey<ScaffoldMessengerState> snackbarKey =
    GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (PlatformUtils.isDesktop) {
    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      center: true,
      backgroundColor: Colors.white, // FIX: Colors.transparent → Colors.white
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: snackbarKey, // 2. Register the key here
      // =====================================================================
      // FIX 1: Use ONLY initialRoute + getPages (no `home`).
      // When both `home` and `initialRoute` are set, GetX creates two routes:
      // one from `home` and one from `initialRoute`, causing a double-navigate
      // flash. Using only initialRoute eliminates this.
      // =====================================================================
      initialRoute: AppRoutes.splash,
      getPages: AppRoutes.pages,

      // =====================================================================
      // FIX 2: Explicit default transition for any dynamic Get.to()/Get.off().
      // Without this, GetX falls back to MaterialPageRoute which uses a slide
      // transition that clears the canvas between frames.
      // =====================================================================
      defaultTransition: Transition.fadeIn,

      // =====================================================================
      // FIX 3: SmartManagement.keepFactory prevents controllers from being
      // disposed and re-instantiated during route transitions, which can
      // cause a rebuild storm and blank frames on heavy pages.
      // =====================================================================
      smartManagement: SmartManagement.keepFactory,

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          extendedSizeConstraints: BoxConstraints(minHeight: 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          extendedPadding: EdgeInsets.symmetric(horizontal: 12),
          extendedIconLabelSpacing: 4,
          iconSize: 12,
          extendedTextStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
