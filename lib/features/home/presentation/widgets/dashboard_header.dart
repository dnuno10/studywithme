import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import 'pixel_panel.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PixelPanel(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
      accentColor: AppColors.secondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STUDYWITHME',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontSize: 30,
                        letterSpacing: 1.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Convierte apuntes en material interactivo con una interfaz editorial de ritmo retro y estructura profesional.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              const _StatusBadge(),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(),
          const SizedBox(height: 14),
          const Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InfoStrip(label: 'MODO', value: 'EDITORIAL HUD'),
              _InfoStrip(label: 'FUENTES', value: 'IBM PLEX / ARIMO'),
              _InfoStrip(label: 'ESTILO', value: 'RETRO SYSTEM UI'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SYSTEM',
            style: theme.textTheme.labelSmall?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 10, height: 10, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'READY',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoStrip extends StatelessWidget {
  final String label;
  final String value;

  const _InfoStrip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(color: AppColors.border),
      ),
      child: RichText(
        text: TextSpan(
          style: theme.textTheme.bodyMedium,
          children: [
            TextSpan(
              text: '$label  ',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.secondary,
              ),
            ),
            TextSpan(
              text: value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
