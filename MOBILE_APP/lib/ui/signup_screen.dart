import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/theme_manager.dart';
import '../widgets/scale_button.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _safetyPasswordController = TextEditingController();
  final TextEditingController _confirmSafetyPasswordController = TextEditingController();
  final TextEditingController _balanceController = TextEditingController(text: "50000");

  final ApiService _apiService = ApiService();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _enableSafetyPassword = false;
  bool _obscureSafetyPassword = true;
  bool _obscureConfirmSafetyPassword = true;
  bool _isLoading = false;

  String? _errorMessage;

  @override
  void dispose() {
    _userIdController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _safetyPasswordController.dispose();
    _confirmSafetyPasswordController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _errorMessage = null;
    });

    final userId = _userIdController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final safetyPassword = _safetyPasswordController.text;
    final confirmSafetyPassword = _confirmSafetyPasswordController.text;
    final balanceText = _balanceController.text.trim();

    if (userId.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty ||
        balanceText.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill in all required fields.';
      });
      return;
    }

    if (userId.length < 3) {
      setState(() {
        _errorMessage = 'User ID must contain at least 3 characters.';
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        _errorMessage = 'Password must contain at least 6 characters.';
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _errorMessage = 'Normal passwords do not match.';
      });
      return;
    }

    if (_enableSafetyPassword) {
      if (safetyPassword.isEmpty || confirmSafetyPassword.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter and confirm your Safety Password.';
        });
        return;
      }

      if (safetyPassword.length < 6) {
        setState(() {
          _errorMessage = 'Safety Password must contain at least 6 characters.';
        });
        return;
      }

      if (safetyPassword != confirmSafetyPassword) {
        setState(() {
          _errorMessage = 'Safety Passwords do not match.';
        });
        return;
      }

      if (safetyPassword == password) {
        setState(() {
          _errorMessage =
              'Safety Password must be distinct from your normal password.';
        });
        return;
      }
    }

    final balance = double.tryParse(balanceText);
    if (balance == null || balance < 0) {
      setState(() {
        _errorMessage = 'Please enter a valid non-negative starting balance.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _apiService.signup(
        userId: userId,
        password: password,
        safetyPassword: _enableSafetyPassword ? safetyPassword : null,
        balance: balance,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Account created for $userId. Please sign in.'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      final errorStr = e.toString();
      setState(() {
        if (errorStr.contains('Failed to fetch') ||
            errorStr.contains('Connection refused') ||
            errorStr.contains('SocketException')) {
          _errorMessage =
              'Unable to connect to SENTINEL server. Please verify backend status.';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        actions: const [
          ThemeToggleButton(),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Open New Account',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Set up your secure credentials and account safety protections.',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Section 1: Credentials
                  _buildSectionCard(
                    title: 'Account Identity',
                    icon: Icons.person_outline_rounded,
                    colorScheme: colorScheme,
                    children: [
                      _inputLabel('User ID', colorScheme),
                      TextField(
                        controller: _userIdController,
                        enabled: !_isLoading,
                        style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
                        decoration: const InputDecoration(
                          hintText: 'Choose a unique username',
                          prefixIcon: Icon(Icons.badge_outlined, size: 20),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _inputLabel('Initial Deposit Balance (₹)', colorScheme),
                      TextField(
                        controller: _balanceController,
                        enabled: !_isLoading,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
                        decoration: const InputDecoration(
                          hintText: 'e.g. 50000',
                          prefixIcon: Icon(Icons.account_balance_wallet_outlined, size: 20),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Section 2: Password
                  _buildSectionCard(
                    title: 'Normal Sign In Credentials',
                    icon: Icons.lock_outline_rounded,
                    colorScheme: colorScheme,
                    children: [
                      _inputLabel('Password', colorScheme),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        enabled: !_isLoading,
                        style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
                        decoration: InputDecoration(
                          hintText: 'Min. 6 characters',
                          prefixIcon: const Icon(Icons.key_outlined, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _inputLabel('Confirm Password', colorScheme),
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        enabled: !_isLoading,
                        style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
                        decoration: InputDecoration(
                          hintText: 'Re-enter your password',
                          prefixIcon: const Icon(Icons.lock_reset_rounded, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 20,
                            ),
                            onPressed: () => setState(() =>
                                _obscureConfirmPassword = !_obscureConfirmPassword),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Section 3: Safety Login (Ghost Mode)
                  _buildSectionCard(
                    title: 'Safety Login Protection',
                    icon: Icons.shield_outlined,
                    colorScheme: colorScheme,
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Enable Ghost Mode',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'Create an optional secondary password for situations where you need additional protection while using SENTINEL.',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                            height: 1.3,
                          ),
                        ),
                        value: _enableSafetyPassword,
                        activeThumbColor: colorScheme.primary,
                        onChanged: (val) => setState(() => _enableSafetyPassword = val),
                      ),

                      if (_enableSafetyPassword) ...[
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 12),
                        _inputLabel('Safety Password', colorScheme),
                        TextField(
                          controller: _safetyPasswordController,
                          obscureText: _obscureSafetyPassword,
                          enabled: !_isLoading,
                          style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
                          decoration: InputDecoration(
                            hintText: 'Separate duress password',
                            prefixIcon: const Icon(Icons.security_rounded, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureSafetyPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 20,
                              ),
                              onPressed: () => setState(() =>
                                  _obscureSafetyPassword = !_obscureSafetyPassword),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _inputLabel('Confirm Safety Password', colorScheme),
                        TextField(
                          controller: _confirmSafetyPasswordController,
                          obscureText: _obscureConfirmSafetyPassword,
                          enabled: !_isLoading,
                          style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
                          decoration: InputDecoration(
                            hintText: 'Re-enter your safety password',
                            prefixIcon: const Icon(Icons.verified_outlined, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmSafetyPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 20,
                              ),
                              onPressed: () => setState(() =>
                                  _obscureConfirmSafetyPassword =
                                      !_obscureConfirmSafetyPassword),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 20),

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
                    const SizedBox(height: 16),
                  ],

                  // Create Account Action
                  AppButton(
                    text: 'CREATE ACCOUNT',
                    isLoading: _isLoading,
                    onPressed: _signup,
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required ColorScheme colorScheme,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _inputLabel(String text, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }
}