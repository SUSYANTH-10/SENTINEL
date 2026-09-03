import 'call_detector.dart';
import 'overlay_detector.dart';

enum RiskLevel { low, medium, high }

class RiskEngine {
  final CallDetector callDetector;
  final OverlayDetector overlayDetector;

  RiskEngine({required this.callDetector, required this.overlayDetector});

  /// Calculates a threat score from 0 (Safe) to 100 (Scam)
  int calculateRiskScore() {
    int score = 0;

    // Active call during transaction = high risk factor
    if (callDetector.currentStatus == CallStatus.activeCall) {
      score += 45;
    }

    // Active overlay / screen share = severe security risk
    if (overlayDetector.isOverlayDetected) {
      score += 50;
    }

    return score;
  }

  RiskLevel getRiskLevel() {
    final score = calculateRiskScore();
    if (score >= 70) return RiskLevel.high;
    if (score >= 30) return RiskLevel.medium;
    return RiskLevel.low;
  }
}