import 'package:flutter/material.dart';

import '../theme/theme_manager.dart';
import '../widgets/scale_button.dart';

class CircuitBreakerScreen extends StatelessWidget {
  final double riskScore;
  final List<String> reasons;
  final VoidCallback? onDismiss;

  const CircuitBreakerScreen({
    super.key,
    required this.riskScore,
    this.reasons = const [],
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("SENTINEL Security Lockdown"),
        actions: const [
          ThemeToggleButton(),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_person_rounded,
                  size: 44,
                  color: colorScheme.error,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "CIRCUIT BREAKER TRIGGERED",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: colorScheme.error,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "SENTINEL detected high coercion or unauthorized access patterns. Your session has been temporarily paused to protect your funds.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Threat Confidence Score",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            "${riskScore.toStringAsFixed(1)} / 100",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                      if (reasons.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        const Divider(),
                        const SizedBox(height: 14),
                        Text(
                          "Triggered Indicators:",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...reasons.map(
                          (r) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  size: 16,
                                  color: colorScheme.error,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    r,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: "RETURN TO SAFETY",
                  icon: Icons.arrow_back_rounded,
                  onPressed: () {
                    if (onDismiss != null) {
                      onDismiss!();
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
