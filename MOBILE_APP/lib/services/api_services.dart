import 'dart0:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Replace this base URL once Teammate 1 hosts or exposes their backend API
  final String baseUrl;

  ApiService({this.baseUrl = "http://localhost:5000"});

  Future<Map<String, dynamic>?> evaluateRisk({
    required String callStatus,
    required bool overlayDetected,
    required double touchVelocity,
    required double amount,
  }) async {
    final url = Uri.parse("$baseUrl/api/v1/assess-risk");

    final payload = {
      "telemetry": {
        "call_status": callStatus,
        "overlay_detected": overlayDetected,
        "touch_velocity": touchVelocity,
      },
      "transaction": {
        "amount": amount,
        "timestamp": DateTime.now().toIso8601String(),
      }
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        print("[SENTINEL API] Server error: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("[SENTINEL API] Failed to connect to risk server: $e");
      return null;
    }
  }
}