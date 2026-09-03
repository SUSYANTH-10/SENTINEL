import 'package:flutter/foundation.dart';

class OverlayDetector {
  bool _isOverlayDetected = false;

  bool get isOverlayDetected => _isOverlayDetected;

  void startMonitoring() {
    debugPrint("[SENTINEL SDK] Overlay detection service initialized.");
  }

  void setOverlayStatus(bool status) {
    _isOverlayDetected = status;
    debugPrint("[SENTINEL SDK] Overlay status updated: $_isOverlayDetected");
  }
}