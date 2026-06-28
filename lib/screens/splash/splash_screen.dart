import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:tcs/screens/login/login_screen.dart';
import 'package:tcs/screens/homepage.dart';
import 'package:tcs/services/app_initializer.dart';
import 'package:tcs/services/auth_service.dart';
import 'package:tcs/utils/platform_utils.dart';

/// Splash screen that plays a Lottie animation while the app initializes.
///
/// Navigation only occurs once both the animation has finished AND
/// initialization has completed. If initialization fails, an error
/// dialog is shown with a retry button.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  /// Controls the splash animation.
  AnimationController? _animationController;

  /// Set to true once the animation has fully played through.
  bool _animationFinished = false;

  /// Set to true once app initialization has completed (success or failure).
  bool _initFinished = false;

  /// Set to true after navigation has been triggered (prevents duplicates).
  bool _navigated = false;

  /// The exception details if initialization failed (null = success).
  AppInitializationException? _initError;

  /// Whether we are currently showing the error dialog.
  bool _showingError = false;

  @override
  void initState() {
    super.initState();
    _startAnimation();
    _startInitialization();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _animationController = null;
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Animation
  // ---------------------------------------------------------------------------

  Future<void> _startAnimation() async {
    if (!mounted) return;

    setState(() {
      _animationController = AnimationController(vsync: this);
    });
  }

  void _onAnimationLoaded(LottieComposition composition) {
    final controller = _animationController;
    if (controller == null) return;

    controller
      ..duration = composition.duration
      ..removeStatusListener(_onAnimationStatusChanged)
      ..addStatusListener(_onAnimationStatusChanged)
      ..forward(from: 0);
  }

  void _onAnimationStatusChanged(AnimationStatus status) {
    if (_animationFinished) return;

    if (status == AnimationStatus.completed) {
      _animationFinished = true;
      _tryNavigate();
    }
  }

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  Future<void> _startInitialization() async {
    try {
      await AppInitializer.initialize();
    } catch (e, s) {
      debugPrint('SplashScreen: initialization error: $e');
      debugPrint('SplashScreen: stack trace: $s');
      if (!mounted) return;

      _initError = e is AppInitializationException
          ? e
          : AppInitializationException('App initialization failed', e, s);

      setState(() {
        _initFinished = true;
      });

      _showErrorDialog();
      return;
    }

    if (!mounted) return;
    _initFinished = true;
    _tryNavigate();
  }

  // ---------------------------------------------------------------------------
  // Navigation - fires at most once
  // ---------------------------------------------------------------------------

  void _tryNavigate() {
    if (_navigated) return;
    if (!_animationFinished) return;
    if (!_initFinished) return;
    if (!mounted) return;

    // Error path - handled by the dialog, so just return.
    if (_initError != null) return;

    _navigated = true;
    _navigateRoute();
  }

  Future<void> _navigateRoute() async {
    if (!AuthService.isLoggedIn) {
      Get.offAll(() => const LoginScreen());
      return;
    }

    final approved = await AuthService.getUserApprovalStatus(
      AuthService.currentUser!.id,
    );

    if (!mounted) return;

    if (approved) {
      Get.offAll(() => const HomePage());
    } else {
      Get.offAll(() => const LoginScreen());
    }
  }

  // ---------------------------------------------------------------------------
  // Error dialog
  // ---------------------------------------------------------------------------

  void _showErrorDialog() {
    if (_showingError) return;
    if (!mounted) return;
    _showingError = true;

    final error = _initError;
    final cause = error?.cause.toString() ?? 'Unknown error';
    final message = error?.message ?? 'Initialization failed';

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text('Initialization Error'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(message),
                const SizedBox(height: 8),
                SelectableText(
                  cause,
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[700],
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _showingError = false;
                _initError = null;
                _initFinished = false;
                _startInitialization();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    ).then((_) {
      _showingError = false;
    });
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    final isDesktop = PlatformUtils.isDesktop;
    final animationController = _animationController;
    final assetPath = isDesktop
        ? 'assets/desktop-splash.json'
        : 'assets/mobile-splash.json';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: ClipRect(
            child: Transform.scale(
              scale:
                  1.2, // Adjust: 1.02 - 1.15 depending on how much you want to zoom
              child: Lottie.asset(
                assetPath,
                controller: animationController,
                onLoaded: _onAnimationLoaded,
                repeat: false,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
