import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';

/// A widget that automatically scrolls text horizontally when it overflows.
/// Uses the marquee package for reliable scrolling animation.
class AutoScrollText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Duration pauseDuration;
  final double velocity;

  const AutoScrollText({
    super.key,
    required this.text,
    this.style,
    this.pauseDuration = const Duration(milliseconds: 500),
    this.velocity = 35.0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Measure text width
        final textPainter = TextPainter(
          text: TextSpan(text: text, style: style),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout(minWidth: 0, maxWidth: double.infinity);

        final textWidth = textPainter.size.width;
        final containerWidth = constraints.maxWidth;

        // If text fits within container, just show static text
        if (textWidth <= containerWidth || containerWidth <= 0) {
          return Text(
            text,
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        }

        // Text overflows, use marquee
        return SizedBox(
          height: textPainter.size.height + 2, // Add a bit of padding
          child: Marquee(
            text: text,
            style: style,
            scrollAxis: Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.start,
            blankSpace: 50.0,
            velocity: velocity,
            pauseAfterRound: pauseDuration,
            startPadding: 0,
            accelerationDuration: const Duration(milliseconds: 500),
            accelerationCurve: Curves.easeOut,
            decelerationDuration: const Duration(milliseconds: 500),
            decelerationCurve: Curves.easeIn,
          ),
        );
      },
    );
  }
}
