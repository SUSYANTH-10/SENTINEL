import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Use http://localhost:5000 for Flutter Web / Chrome
  // Use http://10.0.2.2:5000 for Android Emulator
  // Use http://<YOUR_LOCAL_IP>:5000 for Physical Devices on Wi-Fi
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
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        print("[SENTINEL API] Server returned status code: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("[SENTINEL API] Network exception / offline: $e");
      return null;
    }
  }
}