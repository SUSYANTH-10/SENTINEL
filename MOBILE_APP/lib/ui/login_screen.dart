import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/session_manager.dart';
import '../theme/theme_manager.dart';
import '../widgets/scale_button.dart';
import 'payment_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final ApiService _apiService = ApiService();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _userIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _errorMessage = null;
    });

    final userId = _userIdController.text.trim();
    final password = _passwordController.text;

    if (userId.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your user ID and password.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _apiService.login(
        userId: userId,
        password: password,
      );

      if (!mounted) return;

      final loginMode = result['login_mode'] as String? ?? 'normal';
      final balance = (result['balance'] as num?)?.toDouble() ?? 0.0;

      sessionManager.startSession(
        userId: userId,
        loginMode: loginMode,
        balance: balance,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentScreen(
            userId: userId,
            balance: balance,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      final errorStr = e.toString();
      setState(() {
        if (errorStr.contains('Failed to fetch') ||
            errorStr.contains('Connection refused') ||
            errorStr.contains('SocketException')) {
          _errorMessage =
              'Unable to connect to SENTINEL server. Please ensure the backend is running at http://127.0.0.1:8000.';
        } else {
          _errorMessage = errorStr.replaceFirst('Exception: ', '');
        }
      });
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
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Row with Theme Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: 20,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "SENTINEL BANK",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const ThemeToggleButton(),
                    ],
                  ),

                  const SizedBox(height: 36),

                  // Brand Emblem
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFF0F2744),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.12),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.shield_rounded,
                          color: Colors.white,
                          size: 38,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    'SENTINEL',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: colorScheme.onSurface,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Welcome back',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    'Sign in to securely access your account.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // User ID Input
                  Text(
                    "User ID",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _userIdController,
                    enabled: !_isLoading,
                    textInputAction: TextInputAction.next,
                    style: TextStyle(fontSize: 15, color: colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Enter your User ID (e.g. tamil)',
                      prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Password Input
                  Text(
                    "Password",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    enabled: !_isLoading,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _login(),
                    style: TextStyle(fontSize: 15, color: colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Enter your account password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Error Banner
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: colorScheme.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color: colorScheme.error,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: colorScheme.onErrorContainer,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  const SizedBox(height: 10),

                  // Sign In Action (Micro-interaction button)
                  AppButton(
                    text: 'SIGN IN',
                    isLoading: _isLoading,
                    onPressed: _login,
                  ),

                  const SizedBox(height: 16),

                  // Create New Account Action
                  AppButton(
                    text: 'CREATE NEW ACCOUNT',
                    isOutlined: true,
                    onPressed: _isLoading
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SignupScreen(),
                              ),
                            );
                          },
                  ),

                  const SizedBox(height: 28),

                  // Security reassurance footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'End-to-End Encrypted Financial Security',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
