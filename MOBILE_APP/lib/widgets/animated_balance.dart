import 'package:flutter/material.dart';

/// A widget that smoothly animates balance transitions (e.g. ₹50,000.00 -> ₹45,000.00)
/// with natural number interpolation and standard Indian Rupee currency formatting.
class AnimatedBalanceText extends StatefulWidget {
  final double balance;
  final TextStyle? style;
  final Duration duration;

  const AnimatedBalanceText({
    super.key,
    required this.balance,
    this.style,
    this.duration = const Duration(milliseconds: 650),
  });

  @override
  State<AnimatedBalanceText> createState() => _AnimatedBalanceTextState();
}

class _AnimatedBalanceTextState extends State<AnimatedBalanceText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late double _oldBalance;

  @override
  void initState() {
    super.initState();
    _oldBalance = widget.balance;
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = Tween<double>(begin: _oldBalance, end: widget.balance).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void didUpdateWidget(covariant AnimatedBalanceText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.balance != widget.balance) {
      _oldBalance = _animation.value;
      _animation = Tween<double>(
        begin: _oldBalance,
        end: widget.balance,
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Text(
          _formatCurrency(_animation.value),
          style: widget.style,
        );
      },
    );
  }
}
