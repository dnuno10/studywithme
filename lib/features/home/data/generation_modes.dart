import '../models/generation_mode.dart';

const generationModes = [
  GenerationMode(
    id: 'resumen',
    label: 'Resumen',
    description: 'Bloques clave para repasar por secciones.',
  ),
  GenerationMode(
    id: 'quiz',
    label: 'Quiz',
    description: 'Preguntas interactivas con respuesta inmediata.',
  ),
  GenerationMode(
    id: 'flashcards',
    label: 'Flashcards',
    description: 'Tarjetas volteables para memorizar conceptos.',
  ),
  GenerationMode(
    id: 'checklist',
    label: 'Checklist',
    description: 'Lista marcable de puntos que debes dominar.',
  ),
  GenerationMode(
    id: 'conclusiones',
    label: 'Conclusiones',
    description: 'Insights clave en tarjetas desplegables.',
  ),
];
