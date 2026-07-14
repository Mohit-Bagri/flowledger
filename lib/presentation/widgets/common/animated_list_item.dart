import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A wrapper widget that adds staggered fade-slide animation to list items.
/// Use this to wrap individual list items for a smooth appearance effect.
class AnimatedListItem extends StatelessWidget {
  final Widget child;
  final int index;
  final Duration delay;
  final Duration duration;

  const AnimatedListItem({
    super.key,
    required this.child,
    required this.index,
    this.delay = const Duration(milliseconds: 50),
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    return child
        .animate()
        .fadeIn(
          duration: duration,
          delay: Duration(milliseconds: delay.inMilliseconds * index),
        )
        .slideY(
          begin: 0.1,
          end: 0,
          duration: duration,
          delay: Duration(milliseconds: delay.inMilliseconds * index),
          curve: Curves.easeOutCubic,
        );
  }
}

/// A wrapper widget that adds a press scale animation to interactive cards.
/// Preserves all existing functionality while adding visual feedback.
class PressableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressedScale;
  final Duration animationDuration;

  const PressableCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.98,
    this.animationDuration = const Duration(milliseconds: 100),
  });

  @override
  State<PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<PressableCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.pressedScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
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

/// Animated progress bar that fills from left to right
class AnimatedProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final Color backgroundColor;
  final Color progressColor;
  final double height;
  final BorderRadius? borderRadius;
  final Duration animationDuration;

  const AnimatedProgressBar({
    super.key,
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    this.height = 8.0,
    this.borderRadius,
    this.animationDuration = const Duration(milliseconds: 800),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius ?? BorderRadius.circular(height / 2),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              AnimatedContainer(
                duration: animationDuration,
                curve: Curves.easeOutCubic,
                width: constraints.maxWidth * progress.clamp(0.0, 1.0),
                height: height,
                decoration: BoxDecoration(
                  color: progressColor,
                  borderRadius: borderRadius ?? BorderRadius.circular(height / 2),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Animated counter that smoothly transitions between numbers
class AnimatedCounter extends StatelessWidget {
  final double value;
  final TextStyle? style;
  final String Function(double)? formatter;
  final Duration duration;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.style,
    this.formatter,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) {
        final displayText = formatter?.call(animatedValue) ??
            animatedValue.toStringAsFixed(0);
        return Text(displayText, style: style);
      },
    );
  }
}

/// Extension to easily add stagger animation to any widget in a list
extension AnimatedListExtension on Widget {
  Widget animateListItem(int index, {
    Duration delay = const Duration(milliseconds: 50),
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return AnimatedListItem(
      index: index,
      delay: delay,
      duration: duration,
      child: this,
    );
  }
}
