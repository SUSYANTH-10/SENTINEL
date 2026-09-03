import 'package:flutter/material.dart';

import '../sdk/call_detector.dart';
import '../sdk/overlay_detector.dart';
import '../sdk/touch_dynamics.dart';
import '../services/api_service.dart';
import '../services/session_manager.dart';
import '../theme/theme_manager.dart';
import '../widgets/animated_balance.dart';
import '../widgets/scale_button.dart';
import '../widgets/transaction_status_dialogs.dart';
import 'login_screen.dart';

class PaymentScreen extends StatefulWidget {
  final String userId;
  final double balance;

  const PaymentScreen({
    super.key,
    required this.userId,
    required this.balance,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _recipientController = TextEditingController();

  final ApiService _apiService = ApiService();
  final TouchDynamicsDetector _touchDetector = TouchDynamicsDetector();
  final CallDetector _callDetector = CallDetector();
  final OverlayDetector _overlayDetector = OverlayDetector();

  bool _isProcessing = false;
  bool _isCallActive = false;
  bool _isOverlayActive = false;
  bool _isSimPanelExpanded = false;

  @override
  void initState() {
    super.initState();

    _callDetector.startMonitoring();
    _overlayDetector.startMonitoring();

    if (!sessionManager.isAuthenticated) {
      sessionManager.startSession(
        userId: widget.userId,
        loginMode: 'normal',
        balance: widget.balance,
      );
    }

    _loadTransactionHistory();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _recipientController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactionHistory() async {
    final txs = await _apiService.fetchTransactions(
      userId: sessionManager.userId ?? widget.userId,
      loginMode: sessionManager.loginMode,
    );
    if (mounted) {
      sessionManager.setTransactions(txs);
    }
  }

  String _greetingText() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good morning";
    if (hour < 17) return "Good afternoon";
    return "Good evening";
  }

  // ============================================================
  // SCENARIO ATTACK TRIGGERS
  // ============================================================

  void _triggerOverpaymentScam() {
    setState(() {
      _isCallActive = true;
      _isOverlayActive = true;
      _recipientController.text = "mule_account_scammer@upi";
      _amountController.text = "5000";
    });

    _showScamBanner(
      "SIMULATING: Overpayment / Refund Scam",
      "Scammer claims they sent money by mistake, demanding an immediate refund while keeping you on an active phone call with remote screen sharing.",
    );
  }

  void _triggerPoliceCoercionScam() {
    setState(() {
      _isCallActive = true;
      _isOverlayActive = true;
      _recipientController.text = "safe_vault_police@upi";
      _amountController.text = "50000";
    });

    _showScamBanner(
      "SIMULATING: Law Enforcement Coercion",
      "Scammer impersonating law enforcement claims your account will be frozen immediately unless you transfer funds to a 'Safe Government Holding Account'.",
    );
  }

  void _triggerGatewayFailureScam() {
    setState(() {
      _isCallActive = false;
      _isOverlayActive = false;
      _recipientController.text = "server_timeout_sim@upi";
      _amountController.text = "8000";
    });

    _showScamBanner(
      "SIMULATING: Banking Gateway Timeout",
      "Simulating an unexpected banking network timeout during transfer. The scammer sees a realistic transaction failure screen while your real funds remain 100% untouched.",
    );
  }

  void _resetSimulation() {
    setState(() {
      _isCallActive = false;
      _isOverlayActive = false;
      _recipientController.clear();
      _amountController.clear();
    });
  }

  void _showScamBanner(String title, String description) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(description, style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("UNDERSTOOD"),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TRANSACTION EXECUTION
  // ============================================================

  Future<void> _processPayment({bool confirmed = false}) async {
    FocusScope.of(context).unfocus();

    final recipient = _recipientController.text.trim();
    final amountText = _amountController.text.trim();

    // 1. Input Validation
    if (recipient.isEmpty) {
      _showSnackBar("Please specify a valid recipient UPI ID or account.");
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      _showSnackBar("Please enter a valid positive payment amount.");
      return;
    }

    final currentAvailable = sessionManager.balance;
    if (amount > currentAvailable) {
      _showSnackBar(
        "Insufficient balance. You don't have enough available balance for this payment.",
      );
      return;
    }

    // 2. Prevent Double Submission
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    // Simulated Gateway Timeout Scenario
    if (recipient.contains('server_timeout') || recipient.contains('timeout')) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      setState(() => _isProcessing = false);
      showTransactionFailureDialog(context: context);
      return;
    }

    try {
      final touchVelocity = _touchDetector.calculateVelocity();

      final telemetry = {
        'call_status': _isCallActive ? "CallStatus.activeCall" : "CallStatus.idle",
        'overlay_detected': _isOverlayActive,
        'touch_velocity': touchVelocity,
      };

      final result = await _apiService.executeTransaction(
        userId: sessionManager.userId ?? widget.userId,
        recipientId: recipient,
        amount: amount,
        loginMode: sessionManager.loginMode,
        telemetry: telemetry,
        confirmed: confirmed,
      );

      if (!mounted) return;

      final status = result['status'] as String? ?? 'SUCCESS';
      final reasons = (result['reasons'] as List<dynamic>?)?.cast<String>() ?? [];
      final newBal = (result['balance'] as num?)?.toDouble() ?? currentAvailable;

      // Handle Medium Risk Confirmation Step
      if (status == 'REQUIRES_VERIFICATION') {
        setState(() => _isProcessing = false);
        _showMediumRiskSafetyCheck(recipient, amount);
        return;
      }

      // Handle High Risk Block
      if (status == 'BLOCKED') {
        setState(() => _isProcessing = false);
        showTransactionDeclineDialog(
          context: context,
          errorCode: "SEC_REJECT_701",
          explanation: reasons.isNotEmpty
              ? reasons.first
              : "Security verification threshold not met. No funds have been debited.",
        );
        return;
      }

      // SUCCESS PATH (Real or Shadow)
      sessionManager.updateBalance(newBal);
      sessionManager.addTransaction({
        'transaction_id': result['transaction_id'],
        'recipient_id': recipient,
        'amount': amount,
        'status': 'SUCCESS',
        'created_at': DateTime.now().toIso8601String(),
        'is_shadow': sessionManager.isGhostMode,
      });

      _recipientController.clear();
      _amountController.clear();

      showTransactionSuccessDialog(
        context: context,
        txId: result['transaction_id'] ?? 'TXN-${DateTime.now().millisecondsSinceEpoch}',
        recipient: recipient,
        amount: amount,
        remainingBalance: newBal,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar("Transaction error: ${e.toString().replaceFirst('Exception: ', '')}");
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showMediumRiskSafetyCheck(String recipient, double amount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.verified_user_outlined, color: Colors.orange, size: 48),
        title: const Text(
          "Safety Check",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Please take a moment to verify this payment before proceeding:",
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            _checklistTile("Do you know and trust this recipient?"),
            _checklistTile("Did you personally initiate this transfer?"),
            _checklistTile("Is anyone pressuring you to transfer urgently?"),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Paying: ₹${amount.toStringAsFixed(2)} to $recipient",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("CANCEL PAYMENT"),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _processPayment(confirmed: true);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.orange.shade800),
            child: const Text("CONFIRM & PROCEED"),
          ),
        ],
      ),
    );
  }

  Widget _checklistTile(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, size: 18, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  // ============================================================
  // SECURE LOGOUT FLOW
  // ============================================================

  void _promptLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Leave SENTINEL?"),
        content: const Text(
          "Your banking session will end securely and all sensitive cached data will be cleared.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("CANCEL"),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              if (sessionManager.isGhostMode) {
                final userId = sessionManager.userId ?? widget.userId;
                await _apiService.exitGhostSession(userId);
              }
              sessionManager.clearSession();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text("LOGOUT SECURELY"),
          ),
        ],
      ),
    );
  }

  void _handleRestrictedSecuritySettings() {
    _showSnackBar("Security settings: All SENTINEL protections active and up to date.");
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 3)),
    );
  }

  // ============================================================
  // BUILD METHOD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: sessionManager,
      builder: (context, _) {
        final displayUser = sessionManager.userId ?? widget.userId;

        return Listener(
          onPointerDown: (event) => _touchDetector.recordTouchDown(event.position),
          onPointerUp: (event) => _touchDetector.recordTouchUp(event.position),
          child: Scaffold(
            appBar: AppBar(
              title: const Text("SENTINEL Secure Pay"),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout_rounded),
                  tooltip: "Logout",
                  onPressed: _promptLogout,
                ),
                const ThemeToggleButton(),
                const SizedBox(width: 6),
              ],
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 540),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // --- 1. USER GREETING & STATUS ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${_greetingText()},",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  displayUser,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.25),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.verified_rounded,
                                    size: 14,
                                    color: Color(0xFF10B981),
                                  ),
                                  SizedBox(width: 5),
                                  Text(
                                    "Protected",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF10B981),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // --- 2. AVAILABLE BALANCE CARD ---
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF151D2E)
                                : const Color(0xFF0F2744),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Available Balance",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withValues(alpha: 0.75),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      "Primary Account",
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Smooth Animated Balance Counter
                              AnimatedBalanceText(
                                balance: sessionManager.balance,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                  color: Colors.white,
                                ),
                              ),

                              const SizedBox(height: 20),
                              const Divider(color: Colors.white12),
                              const SizedBox(height: 14),

                              // Quick Actions Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _quickActionButton(
                                    icon: Icons.send_rounded,
                                    label: "Transfer",
                                    onTap: () {},
                                  ),
                                  _quickActionButton(
                                    icon: Icons.qr_code_scanner_rounded,
                                    label: "Scan & Pay",
                                    onTap: () => _showSnackBar("QR Scanner is ready."),
                                  ),
                                  _quickActionButton(
                                    icon: Icons.history_rounded,
                                    label: "History",
                                    onTap: _loadTransactionHistory,
                                  ),
                                  _quickActionButton(
                                    icon: Icons.shield_outlined,
                                    label: "Safety",
                                    onTap: _handleRestrictedSecuritySettings,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // --- 3. MONEY TRANSFER CARD ---
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.payments_outlined,
                                      size: 20,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Instant Transfer",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.2,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Recipient Field
                                Text(
                                  "Payee UPI ID or Account",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _recipientController,
                                  enabled: !_isProcessing,
                                  style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
                                  decoration: const InputDecoration(
                                    hintText: "e.g. store@upi or name@bank",
                                    prefixIcon: Icon(Icons.alternate_email_rounded, size: 18),
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // Amount Field
                                Text(
                                  "Amount",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _amountController,
                                  enabled: !_isProcessing,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.onSurface,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: "0.00",
                                    prefixIcon: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 14),
                                      child: Text(
                                        "₹",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                                  ),
                                ),

                                const SizedBox(height: 12),

                                // Quick Amount Chips
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    _amountChip(500),
                                    _amountChip(1000),
                                    _amountChip(5000),
                                    _maxAmountChip(sessionManager.balance),
                                  ],
                                ),

                                const SizedBox(height: 20),

                                // Transfer Action Button
                                AppButton(
                                  text: "PAY NOW",
                                  isLoading: _isProcessing,
                                  icon: Icons.lock_outline_rounded,
                                  onPressed: _processPayment,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // --- 4. RECENT ACTIVITY CARD ---
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Recent Activity",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.2,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                    Text(
                                      "All transfers",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),

                                if (sessionManager.recentTransactions.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                                    child: Center(
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.receipt_long_outlined,
                                            size: 32,
                                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            "No recent transactions.",
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                else
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: sessionManager.recentTransactions.length > 5
                                        ? 5
                                        : sessionManager.recentTransactions.length,
                                    separatorBuilder: (_, _) => const Divider(height: 20),
                                    itemBuilder: (context, index) {
                                      final tx = sessionManager.recentTransactions[index];
                                      final txAmount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
                                      final recipient = tx['recipient_id'] ?? 'Recipient';
                                      final status = tx['status'] ?? 'SUCCESS';

                                      return Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                width: 40,
                                                height: 40,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                                ),
                                                child: const Icon(
                                                  Icons.arrow_upward_rounded,
                                                  color: Color(0xFF10B981),
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    recipient,
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 14,
                                                      color: colorScheme.onSurface,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    status,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: Color(0xFF10B981),
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          Text(
                                            "-₹${txAmount.toStringAsFixed(2)}",
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: colorScheme.onSurface,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // --- 5. SECURITY CENTER CARD ---
                        Card(
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            leading: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.admin_panel_settings_outlined,
                                color: colorScheme.primary,
                                size: 20,
                              ),
                            ),
                            title: const Text(
                              "Security Center & Account Controls",
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              "Manage credentials and safety settings",
                              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                            ),
                            trailing: const Icon(Icons.chevron_right, size: 20),
                            onTap: _handleRestrictedSecuritySettings,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // --- 6. DEVELOPER / DEMO ATTACK SIMULATION PANEL ---
                        Card(
                          child: Theme(
                            data: theme.copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              initiallyExpanded: _isSimPanelExpanded,
                              onExpansionChanged: (val) =>
                                  setState(() => _isSimPanelExpanded = val),
                              leading: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.bug_report_outlined,
                                  color: colorScheme.primary,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                "Scam Attack Manipulation Panel",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              subtitle: Text(
                                "Demonstrate heuristic risk detection & failure responses",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              children: [
                                const Divider(),
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text("Simulate Active Phone Call", style: TextStyle(fontSize: 13)),
                                  subtitle: Text(
                                    "Coercion indicator (+30 pts)",
                                    style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                                  ),
                                  value: _isCallActive,
                                  activeThumbColor: colorScheme.primary,
                                  onChanged: (val) => setState(() => _isCallActive = val),
                                ),
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text("Simulate Screen Overlay / Sharing", style: TextStyle(fontSize: 13)),
                                  subtitle: Text(
                                    "Remote desktop indicator (+40 pts)",
                                    style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                                  ),
                                  value: _isOverlayActive,
                                  activeThumbColor: colorScheme.primary,
                                  onChanged: (val) =>
                                      setState(() => _isOverlayActive = val),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "One-Click Demo Attack Scenarios:",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    ScaleButton(
                                      onPressed: _triggerOverpaymentScam,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF59E0B),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.currency_rupee, size: 14, color: Colors.white),
                                            SizedBox(width: 4),
                                            Text(
                                              "Refund Scam (₹5,000)",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    ScaleButton(
                                      onPressed: _triggerPoliceCoercionScam,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEF4444),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.local_police_rounded, size: 14, color: Colors.white),
                                            SizedBox(width: 4),
                                            Text(
                                              "Police Impersonation (₹50,000)",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    ScaleButton(
                                      onPressed: _triggerGatewayFailureScam,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF475569),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.cloud_off_rounded, size: 14, color: Colors.white),
                                            SizedBox(width: 4),
                                            Text(
                                              "Simulate Bank Timeout (₹8,000)",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    ScaleButton(
                                      onPressed: _resetSimulation,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.transparent,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: colorScheme.outline),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.refresh_rounded, size: 14, color: colorScheme.onSurface),
                                            const SizedBox(width: 4),
                                            Text(
                                              "Reset to Safe",
                                              style: TextStyle(
                                                color: colorScheme.onSurface,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _quickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ScaleButton(
      onPressed: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _amountChip(double value) {
    return ActionChip(
      label: Text(
        "+₹${value.toStringAsFixed(0)}",
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      onPressed: () {
        final current = double.tryParse(_amountController.text) ?? 0.0;
        _amountController.text = (current + value).toStringAsFixed(0);
      },
    );
  }

  Widget _maxAmountChip(double maxBalance) {
    return ActionChip(
      label: const Text(
        "Max",
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      onPressed: () {
        _amountController.text = maxBalance.toStringAsFixed(0);
      },
    );
  }
}
