import 'package:flutter/material.dart';

/// A micro-interaction button wrapper that scales down slightly on press
/// and returns smoothly on release, providing tactile native feedback.
class ScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double scaleFactor;
  final Duration duration;

  const ScaleButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.scaleFactor = 0.97,
    this.duration = const Duration(milliseconds: 100),
  });

  @override
  State<ScaleButton> createState() => _ScaleButtonState();
}

class _ScaleButtonState extends State<ScaleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      reverseDuration: widget.duration,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleFactor,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed != null) {
      _controller.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.onPressed != null) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onPressed,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

/// A professional pre-styled button that integrates [ScaleButton]
/// with loading indicators and consistent styling.
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final double height;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final bg = isOutlined
        ? Colors.transparent
        : (backgroundColor ?? colorScheme.primary);
    final fg = textColor ??
        (isOutlined
            ? colorScheme.onSurface
            : colorScheme.onPrimary);

    return ScaleButton(
      onPressed: isLoading ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: height,
        decoration: BoxDecoration(
          color: onPressed == null && !isOutlined
              ? colorScheme.surfaceContainerHighest
              : bg,
          borderRadius: BorderRadius.circular(12),
          border: isOutlined
              ? Border.all(
                  color: colorScheme.outline,
                  width: 1.2,
                )
              : null,
          boxShadow: isOutlined || onPressed == null
              ? null
              : [
                  BoxShadow(
                    color: (backgroundColor ?? colorScheme.primary)
                        .withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        alignment: Alignment.center,
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(fg),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: fg),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      color: fg,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
