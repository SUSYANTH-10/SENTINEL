import 'package:flutter/material.dart';
import '../sdk/call_detector.dart';
import '../sdk/overlay_detector.dart';
import '../sdk/touch_dynamics.dart';
import '../sdk/risk_engine.dart';
import '../services/api_service.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final CallDetector _callDetector = CallDetector();
  final OverlayDetector _overlayDetector = OverlayDetector();
  final TouchDynamicsDetector _touchDetector = TouchDynamicsDetector();
  final ApiService _apiService = ApiService();
  final TextEditingController _amountController = TextEditingController();

  late RiskEngine _riskEngine;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _callDetector.startMonitoring();
    _riskEngine = RiskEngine(
      callDetector: _callDetector,
      overlayDetector: _overlayDetector,
    );
  }

  Future<void> _triggerPayment() async {
    setState(() => _isProcessing = true);

    final amount = double.tryParse(_amountController.text) ?? 0.0;
    
    // Extract real-time touch dynamics velocity calculated by SDK
    final touchVelocity = _touchDetector.calculateVelocity();

    // 1. Local SDK Risk Metrics
    final localRiskLevel = _riskEngine.getRiskLevel();
    final localScore = _riskEngine.calculateRiskScore();

    // 2. Transmit Telemetry Payload to Backend API
    final apiResult = await _apiService.evaluateRisk(
      callStatus: _callDetector.currentStatus.toString(),
      overlayDetected: _overlayDetector.isOverlayDetected,
      touchVelocity: touchVelocity,
      amount: amount,
    );

    setState(() => _isProcessing = false);

    // 3. Backend Response handling or Local Fallback
    if (apiResult != null) {
      final backendScore = apiResult['score'] ?? localScore;
      final backendAction = apiResult['action'] ?? 'ALLOW';
      final reasons = (apiResult['reasons'] as List?)?.join("\n• ") ?? "";

      if (backendAction == 'BLOCK') {
        _showSecurityAlert(
          "CRITICAL RISK DETECTED ($backendScore/100)",
          "Transaction blocked by SENTINEL Threat Engine.\n\nReasons:\n• $reasons",
          isError: true,
        );
      } else if (backendAction == 'WARN') {
        _showSecurityAlert(
          "SUSPICIOUS TRANSACTION ($backendScore/100)",
          "Caution advised before proceeding.\n\nReasons:\n• $reasons",
          isError: false,
        );
      } else {
        _showSecurityAlert(
          "PAYMENT SUCCESSFUL",
          "Backend verified transaction as safe. Risk Score: $backendScore/100",
          isError: false,
        );
      }
    } else {
      // Local SDK Fallback when backend server is offline
      if (localRiskLevel == RiskLevel.high) {
        _showSecurityAlert(
          "CRITICAL RISK ($localScore/100)",
          "Active call & screen overlay detected! Blocked locally by SENTINEL SDK.",
          isError: true,
        );
      } else if (localRiskLevel == RiskLevel.medium) {
        _showSecurityAlert(
          "SUSPICIOUS ACTIVITY ($localScore/100)",
          "Ongoing phone call detected. Please verify you are not being coerced.",
          isError: false,
        );
      } else {
        _showSecurityAlert(
          "PAYMENT SUCCESSFUL",
          "Transaction processed safely (Local SDK Fallback).",
          isError: false,
        );
      }
    }
  }

  void _showSecurityAlert(String title, String message, {required bool isError}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          title,
          style: TextStyle(
            color: isError ? Colors.red.shade800 : Colors.indigo.shade900,
            fontWeight: FontWeight.bold,
          ),
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
    final currentScore = _riskEngine.calculateRiskScore();

    return Listener(
      onPointerDown: (event) => _touchDetector.recordTouchDown(event.position),
      onPointerUp: (event) => _touchDetector.recordTouchUp(event.position),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("SENTINEL Secure Pay"),
          backgroundColor: Colors.indigo,
          elevation: 2,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: currentScore > 40 ? Colors.red.shade100 : Colors.green.shade100,
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Live Threat Index:",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "$currentScore / 100",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: currentScore > 40 ? Colors.red.shade900 : Colors.green.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const TextField(
                decoration: InputDecoration(
                  labelText: "Recipient UPI ID / Phone Number",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: "Amount (₹)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isProcessing ? null : _triggerPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text("Pay Now", style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
              const Spacer(),
              const Divider(thickness: 1.5),
              const Text(
                "Hackathon Attack Simulation Controls:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton.icon(
                    icon: Icon(_callDetector.currentStatus == CallStatus.activeCall
                        ? Icons.call_end
                        : Icons.call),
                    label: Text(_callDetector.currentStatus == CallStatus.activeCall
                        ? "End Call"
                        : "Simulate Call"),
                    onPressed: () {
                      setState(() {
                        _callDetector.simulateIncomingCall(
                          _callDetector.currentStatus == CallStatus.activeCall
                              ? CallStatus.idle
                              : CallStatus.activeCall,
                        );
                      });
                    },
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.layers),
                    label: Text(_overlayDetector.isOverlayDetected
                        ? "Clear Overlay"
                        : "Simulate Overlay"),
                    onPressed: () {
                      setState(() {
                        _overlayDetector.simulateOverlayDetected(
                          !_overlayDetector.isOverlayDetected,
                        );
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}