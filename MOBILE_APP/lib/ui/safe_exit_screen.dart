import 'package:flutter/material.dart';
import '../theme/theme_manager.dart';
import 'login_screen.dart';

/// Calm, neutral reassurance screen presented immediately after Safe Exit.
/// Replaces the navigation stack and prevents back-button re-entry into Ghost Mode.
class SafeExitScreen extends StatelessWidget {
  const SafeExitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      canPop: false, // Disallow Android back button navigation to ghost screens
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          automaticallyImplyLeading: false, // No back button
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: const [
            ThemeToggleButton(),
            SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                    ),
                    child: Icon(
                      Icons.shield_outlined,
                      size: 52,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    "You're safe.",
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your private banking session has ended.\nAll temporary session records and balances have been securely cleared.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: () {
                        // Completely wipe navigation stack and return to Login
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.lock_outline, size: 20),
                      label: const Text(
                        'Return to SENTINEL',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
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
