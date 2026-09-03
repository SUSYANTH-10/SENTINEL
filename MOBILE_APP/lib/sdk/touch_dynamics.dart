import 'package:flutter/material.dart';

class TouchDynamicsDetector {
  Offset? _touchDownPosition;
  DateTime? _touchDownTime;
  double _lastVelocity = 0.0;

  void recordTouchDown(Offset position) {
    _touchDownPosition = position;
    _touchDownTime = DateTime.now();
  }

  void recordTouchUp(Offset position) {
    if (_touchDownPosition != null && _touchDownTime != null) {
      final distance = (position - _touchDownPosition!).distance;
      final duration = DateTime.now()
          .difference(_touchDownTime!)
          .inMilliseconds;

      if (duration > 0) {
        _lastVelocity = distance / duration;
      }
    }
  }

  double calculateVelocity() {
    return _lastVelocity;
  }
}
