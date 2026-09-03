import 'package:flutter/material.dart';
import '../sdk/call_detector.dart';
import '../sdk/overlay_detector.dart';
import '../sdk/touch_dynamics.dart';
import '../sdk/risk_engine.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final CallDetector _callDetector = CallDetector();
  final OverlayDetector _overlayDetector = OverlayDetector();
  final TouchDynamicsDetector _touchDetector = TouchDynamicsDetector();
  late RiskEngine _riskEngine;

  @override
  void initState() {
    super.initState();
    _callDetector.startMonitoring();
    _riskEngine = RiskEngine(
      callDetector: _callDetector,
      overlayDetector: _overlayDetector,
    );
  }

  void _triggerPayment() {
    final riskLevel = _riskEngine.getRiskLevel();
    final score = _riskEngine.calculateRiskScore();

    if (riskLevel == RiskLevel.high) {
      _showSecurityAlert("CRITICAL RISK ($score/100)", 
          "Active call & screen overlay detected! Payment blocked by SENTINEL.");
    } else if (riskLevel == RiskLevel.medium) {
      _showSecurityAlert("SUSPICIOUS ACTIVITY ($score/100)", 
          "An ongoing phone call was detected during this transfer. Please confirm you are not being instructed by a stranger.");
    } else {
      _showSecurityAlert("PAYMENT SUCCESSFUL", "Transaction processed safely.");
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
              const TextField(
                decoration: InputDecoration(
                  labelText: "Amount (₹)",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _triggerPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text("Pay Now", style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
              const Spacer(),
              const Divider(),
              const Text("Hackathon Demo Triggers:", style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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