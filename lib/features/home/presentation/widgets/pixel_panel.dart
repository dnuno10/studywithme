import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class PixelPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? accentColor;

  const PixelPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? AppColors.borderStrong;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.92),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(height: 2, color: accent.withValues(alpha: 0.85)),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Row(
              children: [
                _CornerDot(color: accent),
                const SizedBox(width: 6),
                _CornerDot(color: AppColors.warning),
              ],
            ),
          ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

class _CornerDot extends StatelessWidget {
  final Color color;

  const _CornerDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(width: 8, height: 8, color: color);
  }
}
