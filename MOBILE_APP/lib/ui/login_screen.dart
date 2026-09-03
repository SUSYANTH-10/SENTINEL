import 'package:flutter/material.dart';
import 'payment_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isObscured = true;
  int _failedAttempts = 0;
  static const int _maxAttempts = 5;
  bool _isLockedOut = false;

  static const String _validUsername = "tamil";
  static const String _validPassword = "9999";

  void _handleLogin() {
    if (_isLockedOut) return;

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showSnackBar("Please enter both username and password.", Colors.orange);
      return;
    }

    if (username == _validUsername && password == _validPassword) {
      setState(() {
        _failedAttempts = 0;
      });

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const PaymentScreen()),
      );
    } else {
      setState(() {
        _failedAttempts++;
        if (_failedAttempts >= _maxAttempts) {
          _isLockedOut = true;
        }
      });

      if (_isLockedOut) {
        _showSecurityDialog(
          "ACCOUNT LOCKED OUT",
          "You have exceeded the maximum limit of 5 login attempts. Your account has been temporarily locked for security reasons.",
        );
      } else {
        final remaining = _maxAttempts - _failedAttempts;
        _showSnackBar(
          "Invalid username or password. $remaining attempt(s) remaining.",
          Colors.red,
        );
      }
    }
  }

  void _showSnackBar(String text, Color color) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSecurityDialog(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(
          title,
          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.shield_outlined,
                size: 80,
                color: Colors.indigo,
              ),
              const SizedBox(height: 12),
              const Text(
                "SENTINEL BANK",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                  letterSpacing: 1.2,
                ),
              ),
              const Text(
                "Real-Time Threat & Coercion Guard",
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 32),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: _usernameController,
                        enabled: !_isLockedOut,
                        decoration: const InputDecoration(
                          labelText: "Username / Customer ID",
                          hintText: "demo_user",
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        enabled: !_isLockedOut,
                        obscureText: _isObscured,
                        decoration: InputDecoration(
                          labelText: "Password",
                          hintText: "password123",
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isObscured ? Icons.visibility_off : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() => _isObscured = !_isObscured);
                            },
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_failedAttempts > 0 && !_isLockedOut)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Failed attempts: $_failedAttempts / $_maxAttempts",
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLockedOut ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            disabledBackgroundColor: Colors.grey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            _isLockedOut ? "Account Locked" : "Secure Login",
                            style: const TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}