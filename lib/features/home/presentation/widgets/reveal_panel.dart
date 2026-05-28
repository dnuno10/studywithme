import 'package:flutter/material.dart';

class RevealPanel extends StatelessWidget {
  final Widget child;
  final Duration delay;

  const RevealPanel({super.key, required this.child, required this.delay});

  @override
  Widget build(BuildContext context) {
    final duration = Duration(milliseconds: 320 + delay.inMilliseconds);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 26),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
