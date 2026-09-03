import 'package:flutter/material.dart';
import 'scale_button.dart';

/// Shows a polished transaction success receipt dialog with a smooth
/// animated checkmark circle, clear transaction details, and tactile Done button.
void showTransactionSuccessDialog({
  required BuildContext context,
  required String txId,
  required String recipient,
  required double amount,
  required double remainingBalance,
  VoidCallback? onDismiss,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final colorScheme = theme.colorScheme;

      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated Checkmark
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutBack,
                builder: (context, val, child) => Transform.scale(
                  scale: val,
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF10B981),
                      size: 44,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                "Payment Successful",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Your transfer has been processed securely.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),

              // Amount Callout
              Text(
                "₹${amount.toStringAsFixed(2)}",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Sent to $recipient",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 14),

              // Key metadata rows
              _receiptRow(
                label: "Reference ID",
                value: txId.length > 18 ? "${txId.substring(0, 16)}..." : txId,
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 8),
              _receiptRow(
                label: "Payment Method",
                value: "UPI Instant Transfer",
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 8),
              _receiptRow(
                label: "Available Balance",
                value: "₹${remainingBalance.toStringAsFixed(2)}",
                valueWeight: FontWeight.bold,
                colorScheme: colorScheme,
              ),

              const SizedBox(height: 24),

              // Action button
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: "Done",
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    if (onDismiss != null) onDismiss();
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Shows a realistic banking security decline dialog.
void showTransactionDeclineDialog({
  required BuildContext context,
  String errorCode = "SEC_REJECT_701",
  String explanation = "Security verification threshold not met. No funds have been debited.",
  VoidCallback? onDismiss,
}) {
  showDialog(
    context: context,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final colorScheme = theme.colorScheme;

      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFEF4444),
                  size: 38,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Transaction Declined",
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Your bank security system declined this payment request.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  "Error: $errorCode — $explanation",
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFDC2626),
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: "Dismiss",
                  isOutlined: true,
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    if (onDismiss != null) onDismiss();
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Shows a realistic banking timeout/gateway failure dialog.
void showTransactionFailureDialog({
  required BuildContext context,
  String title = "Transaction Failed",
  String message = "We couldn't complete this transaction due to a banking network timeout.\n\nNo funds have been debited from your account. Please try again later.",
  VoidCallback? onDismiss,
}) {
  showDialog(
    context: context,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final colorScheme = theme.colorScheme;

      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                ),
                child: const Icon(
                  Icons.cloud_off_rounded,
                  color: Color(0xFFF59E0B),
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: "Dismiss",
                  isOutlined: true,
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    if (onDismiss != null) onDismiss();
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _receiptRow({
  required String label,
  required String value,
  FontWeight valueWeight = FontWeight.w500,
  required ColorScheme colorScheme,
}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 13,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      Text(
        value,
        style: TextStyle(
          fontSize: 13,
          fontWeight: valueWeight,
          color: colorScheme.onSurface,
        ),
      ),
    ],
  );
}
