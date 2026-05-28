import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import 'mode_selector.dart';
import 'pixel_panel.dart';
import 'section_heading.dart';

class ControlPanel extends StatelessWidget {
  final TextEditingController controller;
  final String selectedMode;
  final ValueChanged<String> onModeChanged;
  final VoidCallback onGenerate;
  final bool isLoading;

  const ControlPanel({
    super.key,
    required this.controller,
    required this.selectedMode,
    required this.onModeChanged,
    required this.onGenerate,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeading(
          title: 'Entrada',
          description:
              'Pega apuntes, texto de clase o contenido limpio desde un documento.',
        ),
        const SizedBox(height: 14),
        TextField(
          controller: controller,
          maxLines: 16,
          style: theme.textTheme.bodyLarge,
          decoration: const InputDecoration(
            hintText: 'Pega aqui tu contenido de estudio...',
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.panel,
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            'Consejo: usa texto continuo o bloques bien separados para mejorar la estructura del resultado.',
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
        ),
        const SizedBox(height: 24),
        const SectionHeading(
          title: 'Salida',
          description:
              'Selecciona el formato que quieres generar para estudiar.',
        ),
        const SizedBox(height: 12),
        ModeSelector(selectedMode: selectedMode, onModeChanged: onModeChanged),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: isLoading ? null : onGenerate,
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('GENERAR MATERIAL'),
        ),
      ],
    );

    return PixelPanel(
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.hasBoundedHeight) {
            return SingleChildScrollView(child: content);
          }

          return content;
        },
      ),
    );
  }
}
