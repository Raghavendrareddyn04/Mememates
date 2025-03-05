import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userCredential = await _authService.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      final isNewUser = await _authService.isNewUser(userCredential.user!.uid);

      if (isNewUser) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/onboarding');
      } else {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSocialLogin(
      Future<UserCredential> Function() loginMethod) async {
    setState(() => _isLoading = true);
    try {
      final userCredential = await loginMethod();
      if (!mounted) return;

      final isNewUser = await _authService.isNewUser(userCredential.user!.uid);

      if (isNewUser) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/onboarding');
      } else {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFC0CB), // Pink
                  Color(0xFFE6E6FA), // Light purple
                ],
              ),
            ),
            child: SafeArea(
              bottom: false, // Extend gradient to bottom edge
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight -
                        MediaQuery.of(context).padding.top,
                  ),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            SizedBox(height: constraints.maxHeight * 0.08),
                            // Profile Image
                            Container(
                              width: constraints.maxWidth * 0.25,
                              height: constraints.maxWidth * 0.25,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF8B5CF6),
                                border:
                                    Border.all(color: Colors.white, width: 2),
                              ),
                              child: ClipOval(
                                child: Image.network(
                                  'https://framerusercontent.com/images/Bjhfi4AxayEYZvnp5W50C4tgQ.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            SizedBox(height: constraints.maxHeight * 0.03),
                            // Welcome Text
                            Text(
                              'Welcome Back',
                              style: TextStyle(
                                fontSize: constraints.maxWidth * 0.07,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1A1A1A),
                                fontFamily: 'SF Pro Display',
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Find your perfect match through memes',
                              style: TextStyle(
                                fontSize: constraints.maxWidth * 0.035,
                                color: const Color(0xFF666666),
                                fontFamily: 'SF Pro Text',
                              ),
                            ),
                            SizedBox(height: constraints.maxHeight * 0.04),
                            // Google Sign In Button
                            Container(
                              width: double.infinity,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: TextButton.icon(
                                onPressed: () => _handleSocialLogin(
                                    () => _authService.signInWithGoogle()),
                                icon: Image.network(
                                  'https://cdn1.iconfinder.com/data/icons/google-s-logo/150/Google_Icons-09-512.png',
                                  height: 20,
                                ),
                                label: const Text(
                                  'Continue with Google',
                                  style: TextStyle(
                                    color: Color(0xFF1A1A1A),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'SF Pro Text',
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: constraints.maxHeight * 0.04),
                            // Email Field
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Email Address',
                                style: TextStyle(
                                  color: Color(0xFF1A1A1A),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'SF Pro Text',
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _emailController,
                              style: const TextStyle(
                                color: Color(0xFF1A1A1A),
                                fontFamily: 'SF Pro Text',
                              ),
                              decoration: InputDecoration(
                                hintText: 'Enter your email...',
                                hintStyle: TextStyle(
                                  color:
                                      const Color(0xFF1A1A1A).withOpacity(0.5),
                                  fontFamily: 'SF Pro Text',
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.5),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!value.contains('@')) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            // Password Field
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Password',
                                style: TextStyle(
                                  color: Color(0xFF1A1A1A),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'SF Pro Text',
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: const TextStyle(
                                color: Color(0xFF1A1A1A),
                                fontFamily: 'SF Pro Text',
                              ),
                              decoration: InputDecoration(
                                hintText: '••••••••',
                                hintStyle: TextStyle(
                                  color:
                                      const Color(0xFF1A1A1A).withOpacity(0.5),
                                  fontFamily: 'SF Pro Text',
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.5),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: const Color(0xFF1A1A1A)
                                        .withOpacity(0.5),
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() =>
                                      _obscurePassword = !_obscurePassword),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            // Forgot Password
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  // Handle forgot password
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    color: Color(0xFF666666),
                                    fontSize: 14,
                                    fontFamily: 'SF Pro Text',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Sign In Button
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF8B5CF6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'Sign In',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'SF Pro Text',
                                        ),
                                      ),
                              ),
                            ),
                            const Spacer(),
                            // Sign Up Link
                            Padding(
                              padding: EdgeInsets.only(
                                  bottom:
                                      MediaQuery.of(context).padding.bottom +
                                          16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    "Don't have an account yet? ",
                                    style: TextStyle(
                                      color: Color(0xFF666666),
                                      fontSize: 14,
                                      fontFamily: 'SF Pro Text',
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pushReplacementNamed(
                                            context, '/signup'),
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      'Sign up',
                                      style: TextStyle(
                                        color: Color(0xFF8B5CF6),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'SF Pro Text',
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
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
