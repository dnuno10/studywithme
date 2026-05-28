import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../widgets/output_card.dart';
import 'pixel_panel.dart';
import 'section_heading.dart';

class OutputPanel extends StatelessWidget {
  final String selectedMode;
  final String selectedLabel;
  final Map<String, dynamic>? output;
  final bool isLoading;

  const OutputPanel({
    super.key,
    required this.selectedMode,
    required this.selectedLabel,
    required this.output,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTitle = isLoading
        ? 'Procesando'
        : output == null
        ? 'Resultado'
        : selectedLabel;
    final effectiveMode = isLoading || output == null ? 'estado' : selectedMode;
    final effectiveData = isLoading
        ? const {
            'message':
                'Compilando contenido de estudio y preparando la salida.',
          }
        : output ??
              const {
                'message':
                    'Aqui aparecera el material generado despues de procesar tus apuntes.',
              };

    return PixelPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeading(
            title: 'Vista de salida',
            description:
                'Resultados interactivos con estructura legible y respuesta inmediata.',
          ),
          const SizedBox(height: 14),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.04, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: Container(
                key: ValueKey(
                  '${effectiveTitle}_${effectiveMode}_${effectiveData.hashCode}',
                ),
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.panel,
                  border: Border.all(color: AppColors.border),
                ),
                child: OutputCard(
                  title: effectiveTitle,
                  mode: effectiveMode,
                  data: effectiveData,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
