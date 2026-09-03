import 'package:flutter/material.dart';

import '../sdk/call_detector.dart';
import '../sdk/overlay_detector.dart';
import '../sdk/touch_dynamics.dart';
import '../services/api_service.dart';

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

  final CallDetector _callDetector = CallDetector();
  final OverlayDetector _overlayDetector = OverlayDetector();
  final TouchDynamicsDetector _touchDetector = TouchDynamicsDetector();
  final ApiService _apiService = ApiService();

  bool _isCallActive = false;
  bool _isOverlayActive = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _callDetector.startMonitoring();
    _overlayDetector.startMonitoring();
  }

  // --- SCENARIO TRIGGERS ---

  void _triggerOverpaymentScam() {
    setState(() {
      _isCallActive = true;
      _isOverlayActive = true;
      _recipientController.text = "mule_account_scammer@upi";
      _amountController.text = "5000";
    });

    _showScamBanner(
      "SIMULATING: Overpayment / Refund Scam",
      "Scammer claims they sent ₹100 by mistake, demanding an immediate refund under high stress while keeping you on an active call with screen sharing.",
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
      "Scammer impersonating police claims your account will be frozen in 5 minutes unless you transfer savings to a 'Safe Government Holding Account'.",
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
        content: Text(description),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("UNDERSTOOD"),
          ),
        ],
      ),
    );
  }

  // --- PAYMENT PROCESSOR ---

  Future<void> _processPayment() async {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final recipient = _recipientController.text.trim();

    if (amount <= 0 || recipient.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a valid recipient and amount"),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final touchVelocity = _touchDetector.calculateVelocity();

    final response = await _apiService.assessRisk(
      callStatus: _isCallActive ? "CallStatus.activeCall" : "CallStatus.idle",
      overlayDetected: _isOverlayActive,
      touchVelocity: touchVelocity,
      amount: amount,
      recipientId: recipient,
      failedLoginAttempts: 0,
    );

    setState(() => _isLoading = false);

    final action = response["action"] ?? "ALLOW";
    final double score = (response["score"] as num?)?.toDouble() ?? 0.0;
    final List<dynamic> reasons = response["reasons"] ?? [];

    if (action == "BLOCK") {
      _showResultDialog(
        "TRANSACTION BLOCKED",
        "SENTINEL Enterprise Risk Engine detected high-confidence coercion (Risk Score: ${score.toStringAsFixed(1)}/100).\n\nRisk Vectors Identified:\n• ${reasons.join('\n• ')}",
        Colors.red,
      );
    } else if (action == "WARN") {
      _showResultDialog(
        "SUSPICIOUS TRANSACTION WARNING",
        "Moderate manipulation risk detected (Risk Score: ${score.toStringAsFixed(1)}/100).\n\nWarnings:\n• ${reasons.join('\n• ')}",
        Colors.orange,
      );
    } else {
      _showResultDialog(
        "PAYMENT SUCCESSFUL",
        "Transaction of ₹$amount to $recipient completed safely.",
        Colors.green,
      );
    }
  }

  void _showResultDialog(String title, String message, Color color) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          title,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
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
    return Listener(
      onPointerDown: (event) => _touchDetector.recordTouchDown(event.position),
      onPointerUp: (event) => _touchDetector.recordTouchUp(event.position),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("SENTINEL Secure Pay"),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Money Transfer",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _recipientController,
                        decoration: const InputDecoration(
                          labelText: "Recipient UPI / Account ID",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Amount (₹)",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _processPayment,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  "PAY NOW",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Card(
                color: Colors.grey.shade50,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.indigo.shade200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.bug_report_outlined, color: Colors.indigo),
                          SizedBox(width: 8),
                          Text(
                            "Scam Attack Manipulation Panel",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Divider(),

                      SwitchListTile(
                        title: const Text("Simulate Active Phone Call"),
                        subtitle: const Text("Coercion indicator"),
                        value: _isCallActive,
                        onChanged: (val) => setState(() => _isCallActive = val),
                      ),
                      SwitchListTile(
                        title: const Text("Simulate Screen Overlay / Sharing"),
                        subtitle: const Text("Remote desktop indicator"),
                        value: _isOverlayActive,
                        onChanged: (val) =>
                            setState(() => _isOverlayActive = val),
                      ),

                      const SizedBox(height: 12),
                      const Text(
                        "One-Click Demo Attack Scenarios:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _triggerOverpaymentScam,
                            icon: const Icon(Icons.currency_rupee, size: 16),
                            label: const Text("Refund Scam (₹5,000)"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade800,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _triggerPoliceCoercionScam,
                            icon: const Icon(Icons.local_police, size: 16),
                            label: const Text("Police Impersonation (₹50,000)"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade800,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: _resetSimulation,
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text("Reset to Safe"),
                          ),
                        ],
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
