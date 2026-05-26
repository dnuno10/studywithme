import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/content_service.dart';
import 'widgets/output_card.dart';

void main() {
  runApp(const StudyWithMeApp());
}

class StudyWithMeApp extends StatelessWidget {
  const StudyWithMeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StudyWithMe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFFFFFF),
        textTheme: GoogleFonts.interTextTheme(),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF111827),
          brightness: Brightness.light,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFFFFFFFF),
          contentPadding: EdgeInsets.all(14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: Color(0xFFD1D5DB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: Color(0xFFD1D5DB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: Color(0xFF111827), width: 1.2),
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class GenerationMode {
  final String id;
  final String label;
  final String description;

  const GenerationMode({
    required this.id,
    required this.label,
    required this.description,
  });
}

final List<GenerationMode> modes = [
  const GenerationMode(
    id: 'resumen',
    label: 'Resumen',
    description: 'Bloques clave para repasar por secciones.',
  ),
  const GenerationMode(
    id: 'quiz',
    label: 'Quiz',
    description: 'Preguntas interactivas con respuesta inmediata.',
  ),
  const GenerationMode(
    id: 'flashcards',
    label: 'Flashcards',
    description: 'Tarjetas volteables para memorizar conceptos.',
  ),
  const GenerationMode(
    id: 'checklist',
    label: 'Checklist',
    description: 'Lista marcable de puntos que debes dominar.',
  ),
  const GenerationMode(
    id: 'conclusiones',
    label: 'Conclusiones',
    description: 'Insights clave en tarjetas desplegables.',
  ),
];

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _contentController = TextEditingController();
  final ContentService _contentService = ContentService();

  String selectedMode = 'resumen';
  Map<String, dynamic>? output;
  bool isLoading = false;

  Future<void> generate() async {
    final content = _contentController.text.trim();

    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega contenido antes de generar.')),
      );
      return;
    }

    setState(() {
      isLoading = true;
      output = null;
    });

    try {
      final result = await _contentService.generateContent(
        content: content,
        mode: selectedMode,
      );

      setState(() {
        output = _ensureRenderableOutput(
          mode: selectedMode,
          result: result,
          sourceText: content,
        );
      });
    } catch (e) {
      setState(() {
        output = _fallbackOutputForMode(selectedMode, content);
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  String get selectedLabel {
    return modes.firstWhere((mode) => mode.id == selectedMode).label;
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Header(),
                  const SizedBox(height: 28),
                  Expanded(
                    child: isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 6,
                                child: _InputSection(
                                  controller: _contentController,
                                  selectedMode: selectedMode,
                                  onModeChanged: (value) {
                                    setState(() {
                                      selectedMode = value;
                                    });
                                  },
                                  onGenerate: generate,
                                  isLoading: isLoading,
                                ),
                              ),
                              const SizedBox(width: 32),
                              Expanded(
                                flex: 4,
                                child: _OutputSection(
                                  selectedMode: selectedMode,
                                  selectedLabel: selectedLabel,
                                  output: output,
                                  isLoading: isLoading,
                                ),
                              ),
                            ],
                          )
                        : ListView(
                            children: [
                              _InputSection(
                                controller: _contentController,
                                selectedMode: selectedMode,
                                onModeChanged: (value) {
                                  setState(() {
                                    selectedMode = value;
                                  });
                                },
                                onGenerate: generate,
                                isLoading: isLoading,
                              ),
                              const SizedBox(height: 28),
                              _OutputSection(
                                selectedMode: selectedMode,
                                selectedLabel: selectedLabel,
                                output: output,
                                isLoading: isLoading,
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Map<String, dynamic> _ensureRenderableOutput({
  required String mode,
  required Map<String, dynamic> result,
  required String sourceText,
}) {
  if (_hasRenderableData(mode, result)) return result;
  return _fallbackOutputForMode(mode, sourceText);
}

bool _hasRenderableData(String mode, Map<String, dynamic> result) {
  bool hasList(String key) {
    final value = result[key];
    return value is List && value.isNotEmpty;
  }

  return switch (mode) {
    'quiz' => hasList('questions'),
    'flashcards' => hasList('cards'),
    'checklist' => hasList('items'),
    'conclusiones' => hasList('insights'),
    'resumen' =>
      hasList('sections') ||
          hasList('quick_review') ||
          (result['headline']?.toString().trim().isNotEmpty ?? false),
    _ => result.isNotEmpty,
  };
}

Map<String, dynamic> _fallbackOutputForMode(String mode, String sourceText) {
  final lines = _extractStudyLines(sourceText);
  final ideas = lines.isEmpty ? ['Contenido de estudio'] : lines;

  return switch (mode) {
    'quiz' => {
      'type': 'quiz',
      'questions': [
        for (int i = 0; i < ideas.take(6).length; i++)
          {
            'question': _buildFallbackQuestion(ideas[i]),
            'options': _buildFallbackOptions(ideas[i], ideas, i),
            'correctIndex': 0,
            'explanation': ideas[i],
          },
      ],
    },
    'flashcards' => {
      'type': 'flashcards',
      'cards': [
        for (final idea in ideas.take(10))
          {'front': _buildFlashcardFront(idea), 'back': idea},
      ],
    },
    'checklist' => {
      'type': 'checklist',
      'items': [
        for (final idea in ideas.take(8))
          {'text': _buildActionTitle(idea), 'why': idea},
      ],
    },
    'conclusiones' => {
      'type': 'conclusiones',
      'insights': [
        for (final idea in ideas.take(6))
          {'title': _buildInsightTitle(idea), 'detail': idea},
      ],
    },
    _ => {
      'type': 'resumen',
      'headline': ideas.first,
      'sections': [
        for (int i = 0; i < ideas.take(9).length; i += 3)
          {
            'heading': _buildSectionHeading(ideas[i]),
            'points': ideas.skip(i).take(3).toList(),
          },
      ],
      'quick_review': [for (final idea in ideas.take(6)) _buildKeyword(idea)],
    },
  };
}

List<String> _extractStudyLines(String text) {
  final paragraphs = text
      .replaceAll('\r', '')
      .split(RegExp(r'\n\s*\n+'))
      .expand((block) => block.split(RegExp(r'(?<=[.!?])\s+')))
      .map(_cleanStudyLine)
      .where((line) => line.length >= 24)
      .toList();

  if (paragraphs.isNotEmpty) return paragraphs;

  return text
      .split('\n')
      .map(_cleanStudyLine)
      .where((line) => line.isNotEmpty)
      .toList();
}

String _cleanStudyLine(String value) {
  return value
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'^\s*[-*•]\s*'), '')
      .replaceAll(RegExp(r'^\s*\d+[).:-]\s*'), '')
      .trim();
}

String _buildFallbackQuestion(String idea) {
  final topic = _extractTopic(idea);
  final lower = _cleanForMatch(idea);

  if (lower.contains('fallec')) {
    return '¿Qué se menciona sobre su fallecimiento?';
  }
  if (lower.contains('perdi') || lower.contains('perdió')) {
    return '¿Qué consecuencia importante se describe?';
  }
  if (lower.contains('abuso') || lower.contains('adiccion')) {
    return '¿Qué efecto tuvieron sus problemas personales?';
  }
  if (lower.contains('legado') || lower.contains('inmortaliz')) {
    return '¿Cómo se conservó su legado?';
  }
  if (lower.contains('homenaje') || lower.contains('estatua')) {
    return '¿Qué tipo de reconocimiento recibió?';
  }
  if (lower.contains('entre ') || lower.contains('durante ')) {
    return '¿Qué ocurrió en ese periodo?';
  }

  return '¿Cuál es la idea principal de "$topic"?';
}

String _buildFlashcardFront(String idea) {
  final lower = _cleanForMatch(idea);

  if (lower.contains('fallec')) {
    return '¿Cuándo y por qué falleció?';
  }
  if (lower.contains('abuso') || lower.contains('adiccion')) {
    return '¿Qué consecuencias tuvieron sus adicciones?';
  }
  if (lower.contains('legado') || lower.contains('inmortaliz')) {
    return '¿Cómo quedó preservado su legado?';
  }
  if (lower.contains('retirar') || lower.contains('retiro')) {
    return '¿Por qué se retiró de su actividad principal?';
  }

  return '¿Cuál es la idea clave de ${_extractTopic(idea).toLowerCase()}?';
}

String _buildActionTitle(String idea) {
  return 'Revisar ${_buildKeyword(idea).toLowerCase()}';
}

String _buildInsightTitle(String idea) {
  return _buildSectionHeading(idea);
}

String _buildSectionHeading(String idea) {
  return _limitWords(_extractTopic(idea), 8);
}

String _buildKeyword(String idea) {
  return _extractTopic(idea);
}

List<String> _buildFallbackOptions(
  String correctAnswer,
  List<String> ideas,
  int currentIndex,
) {
  final distractors = ideas
      .asMap()
      .entries
      .where((entry) => entry.key != currentIndex)
      .map((entry) => _summarizeAnswer(entry.value))
      .take(3)
      .toList();

  while (distractors.length < 3) {
    distractors.add(_genericDistractors[distractors.length]);
  }

  return [_summarizeAnswer(correctAnswer), ...distractors];
}

String _summarizeAnswer(String idea) {
  final cleaned = _removeReferences(idea);
  final clauses = cleaned
      .split(RegExp(r'[,;]'))
      .map((part) => part.trim())
      .toList();

  if (clauses.length >= 2 && clauses.first.length < 90) {
    return _limitWords('${clauses.first}: ${clauses[1]}', 24);
  }

  return _limitWords(cleaned, 24);
}

String _extractTopic(String idea) {
  final cleaned = _removeReferences(idea);
  final beforeVerb = cleaned
      .split(
        RegExp(
          r'\s+(es|son|fue|fueron|incluye|incluyen|provocó|provoco|quedaron|se|pasó|paso|vivió|vivio|recibió|recibio)\s+',
          caseSensitive: false,
        ),
      )
      .first
      .trim();
  final beforeComma = cleaned.split(RegExp(r'[,;:]')).first.trim();
  final candidate = beforeVerb.length >= 8 && beforeVerb.length <= 80
      ? beforeVerb
      : beforeComma;

  return _limitWords(candidate.isEmpty ? cleaned : candidate, 7);
}

String _removeReferences(String value) {
  return value
      .replaceAll(RegExp(r'\[[^\]]*\]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String _cleanForMatch(String value) {
  return _removeReferences(value)
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u');
}

String _limitWords(String text, int maxWords) {
  final words = text
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();
  if (words.length <= maxWords) return words.join(' ');
  return '${words.take(maxWords).join(' ')}...';
}

const List<String> _genericDistractors = [
  'Una idea secundaria que no responde directamente la pregunta.',
  'Una interpretación demasiado general del contenido.',
  'Una conclusión que no se sostiene con el texto.',
];

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'StudyWithMe',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.8,
            color: Color(0xFF111827),
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Material de estudio interactivo a partir de tus apuntes.',
          style: TextStyle(
            fontSize: 14,
            height: 1.45,
            color: Color(0xFF6B7280),
          ),
        ),
        SizedBox(height: 22),
        Divider(height: 1, color: Color(0xFFE5E7EB)),
      ],
    );
  }
}

class _InputSection extends StatelessWidget {
  final TextEditingController controller;
  final String selectedMode;
  final ValueChanged<String> onModeChanged;
  final VoidCallback onGenerate;
  final bool isLoading;

  const _InputSection({
    required this.controller,
    required this.selectedMode,
    required this.onModeChanged,
    required this.onGenerate,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const _SectionTitle(
          title: 'Contenido',
          description:
              'Pega apuntes, texto de clase o contenido extraído de un documento.',
        ),
        const SizedBox(height: 14),
        TextField(
          controller: controller,
          maxLines: 15,
          style: const TextStyle(
            fontSize: 14,
            height: 1.45,
            color: Color(0xFF111827),
          ),
          decoration: const InputDecoration(
            hintText: 'Pega aquí tu contenido de estudio...',
            hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
          ),
        ),
        const SizedBox(height: 26),
        const _SectionTitle(
          title: 'Tipo de generación',
          description: 'Selecciona el resultado que quieres obtener.',
        ),
        const SizedBox(height: 12),
        _ModeSelector(selectedMode: selectedMode, onModeChanged: onModeChanged),
        const SizedBox(height: 26),
        SizedBox(
          height: 46,
          child: FilledButton(
            onPressed: isLoading ? null : onGenerate,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF111827),
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Generar',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
          ),
        ),
      ],
    );
  }
}

class _OutputSection extends StatelessWidget {
  final String selectedMode;
  final String selectedLabel;
  final Map<String, dynamic>? output;
  final bool isLoading;

  const _OutputSection({
    required this.selectedMode,
    required this.selectedLabel,
    required this.output,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const OutputCard(
        title: 'Procesando',
        mode: 'estado',
        data: {
          'type': 'estado',
          'message': 'Generando el contenido solicitado.',
        },
      );
    }

    if (output == null) {
      return const OutputCard(
        title: 'Resultado',
        mode: 'estado',
        data: {
          'type': 'estado',
          'message':
              'Aquí aparecerá el contenido generado después de procesar tus apuntes.',
        },
      );
    }

    return OutputCard(title: selectedLabel, mode: selectedMode, data: output!);
  }
}

class _ModeSelector extends StatelessWidget {
  final String selectedMode;
  final ValueChanged<String> onModeChanged;

  const _ModeSelector({
    required this.selectedMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: modes.map((mode) {
        final bool selected = selectedMode == mode.id;

        return InkWell(
          onTap: () => onModeChanged(mode.id),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF111827) : Colors.transparent,
              border: Border(
                bottom: BorderSide(
                  color: selected
                      ? const Color(0xFF111827)
                      : const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    mode.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected ? Colors.white : const Color(0xFF111827),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    mode.description,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: selected
                          ? const Color(0xFFE5E7EB)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.check, size: 18, color: Colors.white),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String description;

  const _SectionTitle({required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          description,
          style: const TextStyle(
            fontSize: 13,
            height: 1.4,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }
}
