import 'package:flutter/material.dart';

class VernacularGuardModal extends StatelessWidget {
  final String language;
  final String warningText;
  final VoidCallback onAcknowledge;

  const VernacularGuardModal({
    super.key,
    this.language = "Hindi",
    required this.warningText,
    required this.onAcknowledge,
  });

  static Future<void> show({
    required BuildContext context,
    String language = "Hindi",
    required String warningText,
    required VoidCallback onAcknowledge,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => VernacularGuardModal(
        language: language,
        warningText: warningText,
        onAcknowledge: onAcknowledge,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.campaign_rounded,
                  color: colorScheme.error,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "SENTINEL Vernacular Guard",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      "Voice & Text Alert ($language)",
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Text(
              warningText,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onAcknowledge();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
              child: const Text("I UNDERSTAND - DO NOT TRANSFER"),
            ),
          ),
        ],
      ),
    );
  }
}
