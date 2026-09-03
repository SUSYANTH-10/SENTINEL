import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel/main.dart';
import 'package:sentinel/services/session_manager.dart';
import 'package:sentinel/theme/app_theme.dart';
import 'package:sentinel/theme/theme_manager.dart';
import 'package:sentinel/ui/circuit_breaker_screen.dart';
import 'package:sentinel/ui/payment_screen.dart';
import 'package:sentinel/ui/safe_exit_screen.dart';
import 'package:sentinel/ui/signup_screen.dart';
import 'package:sentinel/widgets/animated_balance.dart';
import 'package:sentinel/widgets/scale_button.dart';

void main() {
  setUp(() {
    themeManager.setThemeMode(ThemeMode.light);
    sessionManager.clearSession();
  });

  testWidgets('SENTINEL login screen loads and displays brand elements',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SentinelApp());

    expect(find.text('SENTINEL'), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('SIGN IN'), findsOneWidget);
    expect(find.text('CREATE NEW ACCOUNT'), findsOneWidget);
    expect(find.byType(ThemeToggleButton), findsOneWidget);
  });

  testWidgets('ThemeManager toggles theme and updates ThemeToggleButton',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SentinelApp());

    // Initially Light mode
    expect(themeManager.themeMode, ThemeMode.light);
    expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);

    // Tap theme toggle button
    await tester.tap(find.byType(ThemeToggleButton));
    await tester.pumpAndSettle();

    // Switched to Dark mode
    expect(themeManager.themeMode, ThemeMode.dark);
    expect(find.byIcon(Icons.light_mode_rounded), findsOneWidget);

    // Tap theme toggle button again
    await tester.tap(find.byType(ThemeToggleButton));
    await tester.pumpAndSettle();

    // Switched back to Light mode
    expect(themeManager.themeMode, ThemeMode.light);
    expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
  });

  testWidgets('SignupScreen renders cleanly with Ghost Mode Safety Password options',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: const SignupScreen(),
      ),
    );

    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('CREATE ACCOUNT'), findsOneWidget);
    expect(find.text('Enable Ghost Mode'), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);

    // Toggle Ghost Mode switch on
    await tester.ensureVisible(find.byType(Switch));
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(find.text('Safety Password'), findsOneWidget);
    expect(find.text('Confirm Safety Password'), findsOneWidget);
  });

  testWidgets('SessionManager discriminates Normal vs Ghost mode while keeping formatted balance',
      (WidgetTester tester) async {
    // Normal session
    sessionManager.startSession(
      userId: 'user_normal',
      loginMode: 'normal',
      balance: 50000.0,
    );

    expect(sessionManager.isGhostMode, isFalse);
    expect(sessionManager.displayBalanceText, '₹50000.00');

    // Ghost session (looks visually identical to deceive scammers)
    sessionManager.startSession(
      userId: 'user_ghost',
      loginMode: 'ghost',
      balance: 50000.0,
    );

    expect(sessionManager.isGhostMode, isTrue);
    expect(sessionManager.displayBalanceText, '₹50000.00');

    // Safe exit clears
    sessionManager.clearSession();
    expect(sessionManager.isAuthenticated, isFalse);
    expect(sessionManager.isGhostMode, isFalse);
  });

  testWidgets('PaymentScreen in Normal Mode renders unmasked balance and standard Logout button',
      (WidgetTester tester) async {
    sessionManager.startSession(
      userId: 'test_normal_user',
      loginMode: 'normal',
      balance: 75000.0,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: const PaymentScreen(
          userId: 'test_normal_user',
          balance: 75000.0,
        ),
      ),
    );

    expect(find.text('SENTINEL Secure Pay'), findsOneWidget);
    expect(find.text('test_normal_user'), findsOneWidget);
    expect(find.text('₹75000.00'), findsOneWidget);
    expect(find.byIcon(Icons.logout_rounded), findsOneWidget);
    expect(find.text('Exit Safely'), findsNothing);
  });

  testWidgets('PaymentScreen in Ghost Mode renders IDENTICAL UI to deceive scammer while using shadow state',
      (WidgetTester tester) async {
    sessionManager.startSession(
      userId: 'test_victim_01',
      loginMode: 'ghost',
      balance: 75000.0,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: const PaymentScreen(
          userId: 'test_victim_01',
          balance: 75000.0,
        ),
      ),
    );

    expect(find.text('SENTINEL Secure Pay'), findsOneWidget);
    // User ID is unmasked (looks identical to normal)
    expect(find.text('test_victim_01'), findsOneWidget);
    // Balance is unmasked (looks identical to normal)
    expect(find.text('₹75000.00'), findsOneWidget);
    // Standard Logout icon is present (not a suspicious "Exit Safely" button)
    expect(find.byIcon(Icons.logout_rounded), findsOneWidget);
    expect(find.text('Exit Safely'), findsNothing);
    // No suspicious warning badges
    expect(find.text('Protected Session Active'), findsNothing);
    expect(find.text('Session Ledger'), findsNothing);
  });

  testWidgets('SafeExitScreen renders neutral reassuring screen with no back navigation',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: const SafeExitScreen(),
      ),
    );

    expect(find.text("You're safe."), findsOneWidget);
    expect(find.text('Return to SENTINEL'), findsOneWidget);
    expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
  });

  testWidgets('User switching: User A Ghost Mode never leaks into User B Normal Mode',
      (WidgetTester tester) async {
    // 1. User A in Ghost Mode
    sessionManager.startSession(
      userId: 'user_a_duress',
      loginMode: 'ghost',
      balance: 50000.0,
    );
    sessionManager.updateBalance(42000.0); // Simulated shadow deduction
    sessionManager.addTransaction({
      'transaction_id': 'GHOST-01',
      'amount': 8000.0,
      'is_shadow': true,
    });

    expect(sessionManager.userId, 'user_a_duress');
    expect(sessionManager.isGhostMode, isTrue);
    expect(sessionManager.balance, 42000.0);
    expect(sessionManager.recentTransactions.length, 1);

    // 2. User A logs out
    sessionManager.clearSession();

    // 3. User B logs in normally
    sessionManager.startSession(
      userId: 'user_b_normal',
      loginMode: 'normal',
      balance: 100000.0,
    );

    expect(sessionManager.userId, 'user_b_normal');
    expect(sessionManager.isGhostMode, isFalse);
    expect(sessionManager.balance, 100000.0);
    expect(sessionManager.displayBalanceText, '₹100000.00');
    expect(sessionManager.recentTransactions.isEmpty, isTrue); // Zero leak from User A!
  });

  testWidgets('CircuitBreakerScreen renders lockdown details with reasons',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: const CircuitBreakerScreen(
          riskScore: 92.5,
          reasons: [
            'Active call detected during session',
            'Screen overlay / sharing active',
            'High-value transfer to unverified payee',
          ],
        ),
      ),
    );

    expect(find.text('CIRCUIT BREAKER TRIGGERED'), findsOneWidget);
    expect(find.text('92.5 / 100'), findsOneWidget);
    expect(find.text('Active call detected during session'), findsOneWidget);
    expect(find.text('RETURN TO SAFETY'), findsOneWidget);
  });

  testWidgets('ScaleButton animates scale down on tap and triggers callback',
      (WidgetTester tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScaleButton(
            onPressed: () => tapped = true,
            child: const Text('TAP ME'),
          ),
        ),
      ),
    );

    expect(find.text('TAP ME'), findsOneWidget);
    await tester.tap(find.text('TAP ME'));
    await tester.pumpAndSettle();
    expect(tapped, isTrue);
  });

  testWidgets('AnimatedBalanceText updates balance smoothly over time',
      (WidgetTester tester) async {
    double balance = 50000.0;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          return MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  AnimatedBalanceText(balance: balance),
                  ElevatedButton(
                    onPressed: () => setState(() => balance = 45000.0),
                    child: const Text('DEDUCT'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    expect(find.text('₹50000.00'), findsOneWidget);

    // Tap deduct
    await tester.tap(find.text('DEDUCT'));
    await tester.pump(); // Start animation
    await tester.pump(const Duration(milliseconds: 700)); // Complete animation

    expect(find.text('₹45000.00'), findsOneWidget);
  });

  testWidgets('PaymentScreen differentiates Sent to vs Received from transactions with correct signs and icons',
      (WidgetTester tester) async {
    // 1. Setup User B with one outgoing and one incoming transaction
    sessionManager.startSession(
      userId: 'USER_B',
      loginMode: 'normal',
      balance: 15000.0,
    );

    sessionManager.setTransactions([
      {
        'transaction_id': 'TX-RECV-01',
        'user_id': 'USER_B',
        'sender_id': 'USER_A',
        'recipient_id': 'USER_B',
        'counterparty': 'USER_A',
        'type': 'RECEIVED',
        'direction': 'INCOMING',
        'amount': 5000.0,
        'status': 'SUCCESS',
      },
      {
        'transaction_id': 'TX-SENT-02',
        'user_id': 'USER_B',
        'sender_id': 'USER_B',
        'recipient_id': 'USER_C',
        'counterparty': 'USER_C',
        'type': 'SENT',
        'direction': 'OUTGOING',
        'amount': 2000.0,
        'status': 'SUCCESS',
      },
    ]);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: const PaymentScreen(
          userId: 'USER_B',
          balance: 15000.0,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify incoming transfer
    expect(find.text('Received from USER_A'), findsOneWidget);
    expect(find.text('+₹5000.00'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_downward_rounded), findsOneWidget);

    // Verify outgoing transfer
    expect(find.text('Sent to USER_C'), findsOneWidget);
    expect(find.text('-₹2000.00'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);

    // Verify Refresh & Sync buttons are available
    expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
    expect(find.text('Sync'), findsOneWidget);
  });
}