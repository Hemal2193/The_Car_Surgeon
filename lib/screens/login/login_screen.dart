import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tcs/screens/homepage.dart';
import 'package:tcs/services/auth_service.dart';
import 'package:tcs/utils/responsive.dart';
import 'package:tcs/widgets/app_titlebar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ---------- Controllers ----------
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // ---------- State ----------
  bool _isSignUp = true; // default to Sign Up for new users
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  String? _isApprovedMessage;
  RealtimeChannel? _approvalChannel;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    _approvalChannel?.unsubscribe();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isSignUp = !_isSignUp;
      _errorMessage = null;
      _isApprovedMessage = null;
    });
    _approvalChannel?.unsubscribe();
  }

  void _navigateToDashboard() {
    Get.offAll(() => const HomePage());
  }

  Future<void> _startApprovalListener(String userId) async {
    _approvalChannel?.unsubscribe();
    _approvalChannel = AuthService.watchUserApproval(userId, (approved) {
      if (approved && mounted) {
        setState(() {
          _isLoading = false;
          _isApprovedMessage = null;
        });
        _navigateToDashboard();
      }
    });
  }

  Future<void> _handleLoginSuccess(User user) async {
    await AuthService.ensureUserRow(user);
    final isApproved = await AuthService.getUserApprovalStatus(user.id);

    if (isApproved) {
      if (mounted) {
        _navigateToDashboard();
      }
    } else {
      if (mounted) {
        setState(() {
          _isApprovedMessage = 'waiting';
          _isLoading = false;
          _errorMessage = null;
        });
        await _startApprovalListener(user.id);
      }
    }
  }

  Future<void> _submit() async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    // ---------- Validation ----------
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Please enter your email');
      return;
    }
    if (!email.contains('@')) {
      setState(() => _errorMessage = 'Please enter a valid email');
      return;
    }
    if (password.isEmpty) {
      setState(() => _errorMessage = 'Please enter your password');
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters');
      return;
    }
    if (_isSignUp && password != confirmPassword) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isSignUp) {
        final user = await AuthService.register(
          email: email,
          password: password,
        );
        if (user != null && mounted) {
          debugPrint('Registered: ${user.email}');
          // Just switch to login mode after sign up
          setState(() {
            _isSignUp = false;
            _errorMessage = 'Account created! Please log in.';
            passwordController.clear();
            confirmPasswordController.clear();
          });
        }
      } else {
        final user = await AuthService.login(email: email, password: password);
        if (user != null && mounted) {
          debugPrint('Logged in: ${user.email}');
          await _handleLoginSuccess(user);
        }
      }
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: isDesktop
          ? Column(
              children: [
                const AppTitleBar(),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 32,
                      ),
                      child: _buildDesktopLayout(),
                    ),
                  ),
                ),
              ],
            )
          : SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: _buildMobileLayout(),
                ),
              ),
            ),
    );
  }

  // ===========================================================================
  // DESKTOP LAYOUT
  // ===========================================================================
  Widget _buildDesktopLayout() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 50,
              spreadRadius: 8,
              offset: const Offset(0, 22),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 22,
              spreadRadius: 2,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
          child: _buildContent(),
        ),
      ),
    );
  }

  // ===========================================================================
  // MOBILE LAYOUT
  // ===========================================================================
  Widget _buildMobileLayout() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarDividerColor: Colors.white,
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light, // For iOS
      ),
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        _buildContent(),
        const SizedBox(height: 40),
      ],
    );
  }

  // ===========================================================================
  // SHARED CONTENT
  // ===========================================================================
  Widget _buildContent() {
    final isDesktop = MediaQuery.of(context).size.width > 700;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // // ---------- LOGO ----------
        // Container(
        //   width: isDesktop ? 100 : 80,
        //   height: isDesktop ? 100 : 80,
        //   decoration: BoxDecoration(
        //     shape: BoxShape.circle,
        //     boxShadow: [
        //       BoxShadow(
        //         color: Colors.black.withValues(alpha: 0.08),
        //         blurRadius: 16,
        //         offset: const Offset(0, 6),
        //       ),
        //     ],
        //   ),
        //   child: ClipRRect(
        //     borderRadius: BorderRadius.circular(12),
        //     child: Container(
        //       color: Colors.black,
        //       child: Padding(
        //         padding: const EdgeInsets.all(8.0),
        //         child: Image.asset('assets/logo.jpeg', fit: BoxFit.contain),
        //       ),
        //     ),
        //   ),
        // ),

        // SizedBox(height: isDesktop ? 28 : 24),

        // ---------- LOTTIE ANIMATION ----------
        ClipRect(
          child: SizedBox(
            width: 200,
            height: 100,
            child: OverflowBox(
              maxWidth: 250,
              maxHeight: 250,
              child: Lottie.asset(
                'assets/car.json',
                alignment: Alignment.center,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),

        // ---------- APP NAME ----------
        Text(
          'The Car Surgeon',
          style: TextStyle(
            fontSize: isDesktop ? 26 : 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            letterSpacing: -0.5,
          ),
        ),

        SizedBox(height: isDesktop ? 10 : 8),

        // ---------- SUBTITLE ----------
        Text(
          'Simple · Powerful · Reliable.\nEverything you need, when you need it.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isDesktop ? 15 : 14,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
        ),

        SizedBox(height: isDesktop ? 28 : 24),

        // ---------- TITLE (Sign Up / Login) ----------
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            _isSignUp ? 'Create your account' : 'Welcome back',
            style: TextStyle(
              fontSize: isDesktop ? 16 : 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),

        SizedBox(height: isDesktop ? 16 : 14),

        // ---------- EMAIL FIELD ----------
        _buildTextField(
          controller: emailController,
          hintText: 'Email address',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),

        SizedBox(height: isDesktop ? 16 : 14),

        // ---------- PASSWORD FIELD ----------
        _buildTextField(
          controller: passwordController,
          hintText: 'Password',
          icon: Icons.lock_outlined,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 20,
              color: Colors.grey.shade500,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),

        // ---------- CONFIRM PASSWORD FIELD (Sign Up only) ----------
        if (_isSignUp) ...[
          SizedBox(height: isDesktop ? 16 : 14),
          _buildTextField(
            controller: confirmPasswordController,
            hintText: 'Confirm password',
            icon: Icons.lock_outlined,
            obscureText: _obscureConfirmPassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
                color: Colors.grey.shade500,
              ),
              onPressed: () => setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword,
              ),
            ),
          ),
        ],

        // ---------- WAITING FOR APPROVAL MESSAGE ----------
        if (_isApprovedMessage != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Logged in successfully.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your account is waiting for administrator approval.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'You will automatically enter the application once your account is approved.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],

        // ---------- ERROR MESSAGE ----------
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _errorMessage!.startsWith('Account created')
                  ? Colors.green.shade50
                  : Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _errorMessage!,
              style: TextStyle(
                fontSize: 13,
                color: _errorMessage!.startsWith('Account created')
                    ? Colors.green.shade700
                    : Colors.red.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],

        SizedBox(height: isDesktop ? 20 : 18),

        // ---------- SUBMIT BUTTON ----------
        _buildSubmitButton(isDesktop),

        SizedBox(height: isDesktop ? 20 : 18),

        // ---------- TOGGLE MODE ----------
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isSignUp ? 'Already have an account?' : "Don't have an account?",
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: _toggleMode,
              mouseCursor: SystemMouseCursors.click,
              child: Text(
                _isSignUp ? 'Login' : 'Sign Up',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),

        // SizedBox(height: isDesktop ? 24 : 20),

        // // ---------- FOOTER ----------
        // Text(
        //   'Secure sign-in powered by Supabase',
        //   style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
        // ),
      ],
    );
  }

  // ===========================================================================
  // TEXT FIELD
  // ===========================================================================
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        enableInteractiveSelection: true,
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade500),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // SUBMIT BUTTON
  // ===========================================================================
  Widget _buildSubmitButton(bool isDesktop) {
    return AnimatedScale(
      scale: _isLoading ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 100),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        elevation: 3,
        shadowColor: Colors.black.withValues(alpha: 0.2),
        child: InkWell(
          onTap: _isLoading ? null : _submit,
          borderRadius: BorderRadius.circular(12),
          mouseCursor: SystemMouseCursors.click,
          hoverColor: Colors.grey.shade50,
          splashColor: Colors.grey.shade200,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: isDesktop ? 16 : 15),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _isSignUp ? 'Create Account' : 'Login',
                      style: TextStyle(
                        fontSize: isDesktop ? 15 : 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
