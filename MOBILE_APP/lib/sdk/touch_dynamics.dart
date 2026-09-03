import 'dart:ui';

class TouchMetric {
  final Offset position;
  final DateTime timestamp;
  final double pressure;

  TouchMetric({
    required this.position,
    required this.timestamp,
    this.pressure = 1.0,
  });
}

class TouchDynamicsDetector {
  final List<TouchMetric> _touchBuffer = [];

  void recordTouchDown(Offset position) {
    _touchBuffer.add(TouchMetric(
      position: position,
      timestamp: DateTime.now(),
    ));
    _analyzePattern();
  }

  void _analyzePattern() {
    if (_touchBuffer.length < 2) return;

    final last = _touchBuffer.last;
    final previous = _touchBuffer[_touchBuffer.length - 2];

    final timeDiffMs = last.timestamp.difference(previous.timestamp).inMilliseconds;
    final distance = (last.position - previous.position).distance;

    if (timeDiffMs > 0) {
      final velocity = distance / timeDiffMs;
      if (velocity > 3.0) {
        print("[SENTINEL SDK] Anomalous fast interaction detected! Velocity: $velocity");
      }
    }
  }

  void clearBuffer() {
    _touchBuffer.clear();
  }
}