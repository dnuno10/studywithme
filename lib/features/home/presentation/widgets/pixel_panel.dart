import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class PixelPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const PixelPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.92),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
