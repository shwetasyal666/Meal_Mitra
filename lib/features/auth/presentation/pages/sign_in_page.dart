import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mealmitra/features/auth/data/auth_repository.dart';

class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _error;
  bool _obscurePassword = true;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref
          .read(authRepositoryProvider)
          .signInWithEmail(
            _emailController.text.trim(),
            _passwordController.text,
          );
    } catch (e) {
      if (mounted) {
        setState(() {
          String errorMsg = e.toString();
          if (errorMsg.contains('API Error')) {
            final regExp = RegExp(r'"error"\s*:\s*"([^"]+)"');
            final match = regExp.firstMatch(errorMsg);
            if (match != null) {
              errorMsg = match.group(1)!;
            }
          }
          _error = errorMsg.replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Gradient background
          // Container(
          //   decoration: const BoxDecoration(
          //     gradient: LinearGradient(
          //       begin: Alignment.topLeft,
          //       end: Alignment.bottomRight,
          //       colors: [
          //         Color(0xFF0D5C4B),
          //         Color(0xFF147A5E),
          //         Color(0xFF1A8F6E),
          //       ],
          //     ),
          //   ),
          // ),

          // Floating bubble decorations
          ..._buildFloatingBubbles(),

          // Main content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom -
                      32.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated Logo
                    FadeTransition(
                      opacity: _fadeAnim,
                      child: ScaleTransition(
                        scale: _pulseAnim,
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: Color(0xFF027B3D).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Color(0xFF027B3D).withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.restaurant_menu,
                            size: 44,
                            color: Color(0xFF027B3D),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title
                    FadeTransition(
                      opacity: _fadeAnim,
                      child: Text(
                        'Welcome Back',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          color: Color(0xFF027B3D),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FadeTransition(
                      opacity: _fadeAnim,
                      child: Text(
                        'Sign in to continue tracking your meals',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Color(0xFF027B3D).withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Glassmorphic form card
                    SlideTransition(
                      position: _slideAnim,
                      child: FadeTransition(
                        opacity: _fadeAnim,
                        child: Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: Color(0xFF027B3D).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: Color(0xFF027B3D).withValues(alpha: 0.2),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF027B3D).withValues(alpha: 0.1),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Email field
                                _buildStaggeredField(
                                  delay: 0,
                                  child: TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    validator: _validateEmail,
                                    style: const TextStyle(
                                      color: Colors.black87,
                                    ),
                                    decoration: _inputDecoration(
                                      label: 'Email',
                                      hint: 'Enter your email address',
                                      icon: Icons.email_outlined,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),

                                // Password field
                                _buildStaggeredField(
                                  delay: 1,
                                  child: TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    textInputAction: TextInputAction.done,
                                    validator: _validatePassword,
                                    onFieldSubmitted: (_) => _submit(),
                                    style: const TextStyle(
                                      color: Colors.black87,
                                    ),
                                    decoration: _inputDecoration(
                                      label: 'Password',
                                      hint: 'Enter your password',
                                      icon: Icons.lock_outline,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          color: Colors.black87,
                                        ),
                                        onPressed: () => setState(
                                          () => _obscurePassword =
                                              !_obscurePassword,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // Error message
                                if (_error != null) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: Colors.redAccent.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.error_outline,
                                          color: Color(0xFFFF6B6B),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            _error!,
                                            style: const TextStyle(
                                              color: Color(0xFFFF6B6B),
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 26),

                                // Sign In button
                                _buildStaggeredField(
                                  delay: 2,
                                  child: _buildPrimaryButton(
                                    label: 'Sign In',
                                    onPressed: _isLoading ? null : _submit,
                                    isLoading: _isLoading,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Navigate to register
                    FadeTransition(
                      opacity: _fadeAnim,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: TextStyle(
                              color: Colors.black.withValues(alpha: 0.7),
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.go('/sign-up'),
                            child: const Text(
                              'Sign Up',
                              style: TextStyle(
                                color: Color(0xFF027B3D),
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(color: Colors.black.withValues(alpha: 0.8)),
      hintStyle: TextStyle(color: Colors.black.withValues(alpha: 0.4)),
      prefixIcon: Icon(icon, color: const Color(0xFF027B3D)),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.black.withValues(alpha: 0.08),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.15)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF027B3D), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFFF6B6B)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 2),
      ),
      errorStyle: const TextStyle(color: Color(0xFFFF6B6B)),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF027B3D), Color(0xFF027B3D)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF027B3D).withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0D3B2E),
                ),
              ),
      ),
    );
  }

  Widget _buildStaggeredField({required int delay, required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + (delay * 150)),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
    );
  }

  List<Widget> _buildFloatingBubbles() {
    final random = Random(42); // Fixed seed for consistent layout
    return List.generate(6, (index) {
      final size = 40.0 + random.nextDouble() * 80;
      final top = random.nextDouble() * 800;
      final left = random.nextDouble() * 400;
      return Positioned(
        top: top,
        left: left,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color(
              0xFF027B3D,
            ).withValues(alpha: 0.03 + random.nextDouble() * 0.04),
          ),
        ),
      );
    });
  }
}
