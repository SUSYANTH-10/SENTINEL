class OverlayDetector {
  bool _isOverlayDetected = false;

  bool get isOverlayDetected => _isOverlayDetected;

  /// Checks if an active screen overlay or screen sharing is present
  Future<bool> checkForOverlay() async {
    // Platform channel integration point for native Android Accessibility API checks
    return _isOverlayDetected;
  }

  /// Helper to toggle state for presentation/demo testing
  void simulateOverlayDetected(bool detected) {
    _isOverlayDetected = detected;
    print("[SENTINEL SDK] Overlay Detection state set to: $detected");
  }
}