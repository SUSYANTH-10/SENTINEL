import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl;

  ApiService({
    this.baseUrl = 'http://127.0.0.1:8000',
  });

  // ============================================================
  // SIGN UP
  // ============================================================

  Future<Map<String, dynamic>> signup({
    required String userId,
    required String password,
    String? safetyPassword,
    required double balance,
  }) async {
    final url = Uri.parse('$baseUrl/api/v1/auth/signup');

    final payload = <String, dynamic>{
      'user_id': userId,
      'password': password,
      'balance': balance,
    };

    if (safetyPassword != null && safetyPassword.trim().isNotEmpty) {
      payload['safety_password'] = safetyPassword.trim();
    }

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return data as Map<String, dynamic>;
      }

      throw Exception(
        data['detail'] ?? 'Unable to create account',
      );
    } catch (e) {
      debugPrint('[SENTINEL AUTH] Signup failed: $e');
      rethrow;
    }
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<Map<String, dynamic>> login({
    required String userId,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/api/v1/auth/login');

    final body = jsonEncode({
      'user_id': userId,
      'password': password,
    });

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: body,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data as Map<String, dynamic>;
      }

      if (response.statusCode == 401) {
        throw Exception('Invalid user ID or password');
      }

      throw Exception(
        data['detail'] ?? 'Login failed',
      );
    } catch (e) {
      debugPrint('[SENTINEL AUTH] Login failed: $e');
      rethrow;
    }
  }

  // ============================================================
  // TRANSACTION EXECUTION (REAL OR SHADOW)
  // ============================================================

  Future<Map<String, dynamic>> executeTransaction({
    required String userId,
    required String recipientId,
    required double amount,
    required String loginMode,
    Map<String, dynamic>? telemetry,
    bool confirmed = true,
  }) async {
    final url = Uri.parse('$baseUrl/api/v1/transactions');

    final body = jsonEncode({
      'user_id': userId,
      'recipient_id': recipientId,
      'amount': amount,
      'login_mode': loginMode,
      'telemetry': telemetry,
      'confirmed': confirmed,
    });

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: body,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data as Map<String, dynamic>;
      }

      throw Exception(data['detail'] ?? 'Transaction failed');
    } catch (e) {
      debugPrint('[SENTINEL TX] Execution failed: $e');
      rethrow;
    }
  }

  // ============================================================
  // ACCOUNT STATE & TRANSACTION HISTORY
  // ============================================================

  Future<Map<String, dynamic>> fetchAccountState({
    required String userId,
    required String loginMode,
  }) async {
    final url = Uri.parse(
      '$baseUrl/api/v1/transactions?user_id=$userId&login_mode=$loginMode',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final list = data['transactions'] as List<dynamic>? ?? [];
        final balance = (data['balance'] as num?)?.toDouble();
        return {
          'success': true,
          'balance': balance,
          'transactions': list.cast<Map<String, dynamic>>(),
        };
      }

      return {'success': false, 'balance': null, 'transactions': <Map<String, dynamic>>[]};
    } catch (e) {
      debugPrint('[SENTINEL TX] Fetch account state failed: $e');
      return {'success': false, 'balance': null, 'transactions': <Map<String, dynamic>>[]};
    }
  }

  Future<double?> fetchBalance({
    required String userId,
    required String loginMode,
  }) async {
    final url = Uri.parse(
      '$baseUrl/api/v1/user/balance?user_id=$userId&login_mode=$loginMode',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (data['balance'] as num?)?.toDouble();
      }
      return null;
    } catch (e) {
      debugPrint('[SENTINEL BAL] Fetch balance failed: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> fetchTransactions({
    required String userId,
    required String loginMode,
  }) async {
    final state = await fetchAccountState(
      userId: userId,
      loginMode: loginMode,
    );
    return (state['transactions'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>() ??
        [];
  }

  // ============================================================
  // GHOST SESSION SAFE EXIT
  // ============================================================

  Future<void> exitGhostSession(String userId) async {
    final url = Uri.parse('$baseUrl/api/v1/ghost/exit');
    try {
      await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'user_id': userId}),
      );
    } catch (e) {
      debugPrint('[SENTINEL GHOST] Exit call failed: $e');
    }
  }

  // ============================================================
  // STANDALONE RISK ASSESSMENT
  // ============================================================

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
      'telemetry': {
        'call_status': callStatus,
        'overlay_detected': overlayDetected,
        'touch_velocity': touchVelocity,
      },
      'transaction': {
        'amount': amount,
        'recipient_id': recipientId,
        'is_new_payee': true,
      },
      'user_context': {
        'failed_login_attempts': failedLoginAttempts,
      },
    });

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      return _fallbackLocalAssessment(
        callStatus,
        overlayDetected,
        touchVelocity,
        amount,
      );
    } catch (e) {
      debugPrint(
        '[SENTINEL API] Backend unreachable. Running local fallback: $e',
      );

      return _fallbackLocalAssessment(
        callStatus,
        overlayDetected,
        touchVelocity,
        amount,
      );
    }
  }

  // ============================================================
  // LOCAL FALLBACK
  // ============================================================

  Map<String, dynamic> _fallbackLocalAssessment(
    String callStatus,
    bool overlayDetected,
    double touchVelocity,
    double amount,
  ) {
    double score = 0.0;
    final List<String> reasons = [];
    final bool isCall = callStatus.contains('activeCall');

    if (isCall) {
      score += 30.0;
      reasons.add('Active call detected (Fallback)');
    }

    if (overlayDetected) {
      score += 40.0;
      reasons.add('Screen overlay active (Fallback)');
    }

    if (touchVelocity > 1000) {
      score += 30.0;
      reasons.add('High touch velocity (Fallback)');
    }

    if (amount > 0 && amount <= 500) {
      score = (score * 0.5).clamp(0.0, 65.0);
    }

    score = score.clamp(0.0, 100.0);
    String action = 'ALLOW';

    if (score >= 70.0) {
      action = 'BLOCK';
    } else if (score >= 40.0) {
      action = 'WARN';
    }

    return {
      'score': score,
      'risk_level': score >= 70
          ? 'HIGH'
          : (score >= 40 ? 'MEDIUM' : 'LOW'),
      'action': action,
      'reasons': reasons,
      'evaluated_at': DateTime.now().toIso8601String(),
    };
  }
}