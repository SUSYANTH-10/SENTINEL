import 'dart:async';

enum CallStatus { idle, ringing, activeCall }

class CallDetector {
  CallStatus _currentStatus = CallStatus.idle;
  final StreamController<CallStatus> _statusController =
      StreamController<CallStatus>.broadcast();

  Stream<CallStatus> get callStatusStream => _statusController.stream;
  CallStatus get currentStatus => _currentStatus;

  /// Simulates active call monitoring for local UI & testing.
  /// On real Android/iOS, this will invoke Platform Channels (MethodChannel).
  void startMonitoring() {
    // Basic polling or native event listener logic stub
    print("[SENTINEL SDK] Call Detector Started...");
  }

  /// Helper trigger to simulate scam call detection during hackathon demo
  void simulateIncomingCall(CallStatus status) {
    _currentStatus = status;
    _statusController.add(_currentStatus);
    print("[SENTINEL SDK] Simulated Call State Change: $status");
  }

  void stopMonitoring() {
    _statusController.close();
  }
}