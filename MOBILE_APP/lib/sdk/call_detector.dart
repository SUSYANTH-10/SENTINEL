import 'package:flutter/foundation.dart';

enum CallStatus { idle, activeCall, incomingCall }

class CallDetector {
  CallStatus _currentStatus = CallStatus.idle;

  CallStatus get currentStatus => _currentStatus;

  void startMonitoring() {
    debugPrint("[SENTINEL SDK] Call monitoring service initialized.");
  }

  void simulateIncomingCall(CallStatus status) {
    _currentStatus = status;
    debugPrint("[SENTINEL SDK] Call status changed to: $_currentStatus");
  }

  bool isCallActive() {
    return _currentStatus == CallStatus.activeCall;
  }
}
