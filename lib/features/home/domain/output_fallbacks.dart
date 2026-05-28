Map<String, dynamic> ensureRenderableOutput({
  required String mode,
  required Map<String, dynamic> result,
  required String sourceText,
}) {
  if (_hasRenderableData(mode, result)) {
    return result;
  }
  return fallbackOutputForMode(mode, sourceText);
}

Map<String, dynamic> fallbackOutputForMode(String mode, String sourceText) {
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

List<String> _extractStudyLines(String text) {
  final paragraphs = text
      .replaceAll('\r', '')
      .split(RegExp(r'\n\s*\n+'))
      .expand((block) => block.split(RegExp(r'(?<=[.!?])\s+')))
      .map(_cleanStudyLine)
      .where((line) => line.length >= 24)
      .toList();

  if (paragraphs.isNotEmpty) {
    return paragraphs;
  }

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
  if (lower.contains('perdi') || lower.contains('perdio')) {
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

String _buildActionTitle(String idea) =>
    'Revisar ${_buildKeyword(idea).toLowerCase()}';

String _buildInsightTitle(String idea) => _buildSectionHeading(idea);

String _buildSectionHeading(String idea) => _limitWords(_extractTopic(idea), 8);

String _buildKeyword(String idea) => _extractTopic(idea);

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
          r'\s+(es|son|fue|fueron|incluye|incluyen|provoco|quedaron|se|paso|vivio|recibio)\s+',
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
  if (words.length <= maxWords) {
    return words.join(' ');
  }
  return '${words.take(maxWords).join(' ')}...';
}

const _genericDistractors = [
  'Una idea secundaria que no responde directamente la pregunta.',
  'Una interpretación demasiado general del contenido.',
  'Una conclusión que no se sostiene con el texto.',
];
