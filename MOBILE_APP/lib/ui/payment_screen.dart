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
    
    // 1. Local SDK Risk Assessment
    final localRiskLevel = _riskEngine.getRiskLevel();
    final localScore = _riskEngine.calculateRiskScore();

    // 2. Call Backend API
    final apiResult = await _apiService.evaluateRisk(
      callStatus: _callDetector.currentStatus.toString(),
      overlayDetected: _overlayDetector.isOverlayDetected,
      touchVelocity: 0.0, // Expanded when touch telemetry is active
      amount: amount,
    );

    setState(() => _isProcessing = false);

    // If backend response is received, use backend risk evaluation; otherwise use local SDK engine
    if (apiResult != null) {
      final backendScore = apiResult['score'] ?? localScore;
      final backendAction = apiResult['action'] ?? 'ALLOW';

      if (backendAction == 'BLOCK') {
        _showSecurityAlert("CRITICAL RISK DETECTED ($backendScore/100)", 
            "Backend Threat Engine blocked this transaction due to social engineering signals.");
      } else {
        _showSecurityAlert("PAYMENT SUCCESSFUL", "Backend verified transaction as safe.");
      }
    } else {
      // Fallback to local SDK risk engine if backend is offline
      if (localRiskLevel == RiskLevel.high) {
        _showSecurityAlert("CRITICAL RISK ($localScore/100)", 
            "Active call & screen overlay detected! Payment blocked locally by SENTINEL SDK.");
      } else if (localRiskLevel == RiskLevel.medium) {
        _showSecurityAlert("SUSPICIOUS ACTIVITY ($localScore/100)", 
            "An ongoing phone call was detected. Please confirm you are not being coerced.");
      } else {
        _showSecurityAlert("PAYMENT SUCCESSFUL", "Transaction processed safely (Local SDK).");
      }
    }
  }

  void _showSecurityAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
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
    final score = _riskEngine.calculateRiskScore();

    return Listener(
      onPointerDown: (event) => _touchDetector.recordTouchDown(event.position),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("SENTINEL Secure Pay"),
          backgroundColor: Colors.indigo,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: score > 40 ? Colors.red.shade100 : Colors.green.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "Current Threat Score: $score / 100",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const TextField(
                decoration: InputDecoration(
                  labelText: "Recipient UPI ID / Phone",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: "Amount (₹)",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isProcessing ? null : _triggerPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Pay Now", style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
              const Spacer(),
              const Divider(),
              const Text("Hackathon Demo Triggers:", style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                mainAxisAlignment: MainSpacer.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _callDetector.simulateIncomingCall(
                          _callDetector.currentStatus == CallStatus.activeCall
                              ? CallStatus.idle
                              : CallStatus.activeCall,
                        );
                      });
                    },
                    child: Text(_callDetector.currentStatus == CallStatus.activeCall
                        ? "End Call"
                        : "Simulate Call"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _overlayDetector.simulateOverlayDetected(
                          !_overlayDetector.isOverlayDetected,
                        );
                      });
                    },
                    child: Text(_overlayDetector.isOverlayDetected
                        ? "Clear Overlay"
                        : "Simulate Overlay"),
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