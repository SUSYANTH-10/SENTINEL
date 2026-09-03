// lib/services/api_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl;

  ApiService({this.baseUrl = 'http://127.0.0.1:5000'});

  Future<Map<String, dynamic>> assessRisk({
    required String callStatus,
    required bool overlayDetected,
    required double touchVelocity,
    required double amount,
    required String recipientId,
    int failedLoginAttempts = 0,
  }) async {
    final url = Uri.parse('$baseUrl/api/v1/assess-risk');

    final body = jsonEncode({
      "telemetry": {
        "call_status": callStatus,
        "overlay_detected": overlayDetected,
        "touch_velocity": touchVelocity,
      },
      "transaction": {
        "amount": amount,
        "recipient_id": recipientId,
        "is_new_payee": true,
      },
      "user_context": {
        "failed_login_attempts": failedLoginAttempts,
      }
    });

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        return _fallbackLocalAssessment(callStatus, overlayDetected, touchVelocity, amount);
      }
    } catch (e) {
      debugPrint("[SENTINEL API] Backend unreachable. Running local SDK fallback: $e");
      return _fallbackLocalAssessment(callStatus, overlayDetected, touchVelocity, amount);
    }
  }

  Map<String, dynamic> _fallbackLocalAssessment(
      String callStatus, bool overlayDetected, double touchVelocity, double amount) {
    double score = 0.0;
    List<String> reasons = [];

    bool isCall = callStatus.contains("activeCall");
    if (isCall) {
      score += 30.0;
      reasons.add("Active call detected (Fallback)");
    }
    if (overlayDetected) {
      score += 40.0;
      reasons.add("Screen overlay active (Fallback)");
    }
    if (touchVelocity > 1000) {
      score += 30.0;
      reasons.add("High touch velocity (Fallback)");
    }

    if (amount > 0 && amount <= 500) {
      score = (score * 0.5).clamp(0.0, 65.0);
    }

    score = score.clamp(0.0, 100.0);

    String action = "ALLOW";
    if (score >= 70.0) {
      action = "BLOCK";
    } else if (score >= 40.0) {
      action = "WARN";
    }

    return {
      "score": score,
      "risk_level": score >= 70 ? "HIGH" : (score >= 40 ? "MEDIUM" : "LOW"),
      "action": action,
      "reasons": reasons,
      "evaluated_at": DateTime.now().toIso8601String(),
    };
  }
}