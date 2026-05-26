import 'package:flutter/material.dart';

class OutputCard extends StatelessWidget {
  final String title;
  final String mode;
  final Map<String, dynamic> data;

  const OutputCard({
    super.key,
    required this.title,
    required this.mode,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool hasBoundedHeight = constraints.hasBoundedHeight;
        final body = _OutputRenderer(
          mode: mode,
          data: data,
          scrollable: hasBoundedHeight,
        );

        return SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: hasBoundedHeight
                ? MainAxisSize.max
                : MainAxisSize.min,
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
              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFE5E7EB)),
              const SizedBox(height: 18),
              if (hasBoundedHeight) Expanded(child: body) else body,
            ],
          ),
        );
      },
    );
  }
}

class _OutputRenderer extends StatelessWidget {
  final String mode;
  final Map<String, dynamic> data;
  final bool scrollable;

  const _OutputRenderer({
    required this.mode,
    required this.data,
    required this.scrollable,
  });

  @override
  Widget build(BuildContext context) {
    final content = switch (mode) {
      'quiz' => _QuizView(data: data),
      'flashcards' => _FlashcardsView(data: data),
      'checklist' => _ChecklistView(data: data),
      'conclusiones' => _ConclusionsView(data: data),
      'resumen' => _SummaryView(data: data),
      _ => _StatusView(data: data),
    };

    if (!scrollable) return content;
    return SingleChildScrollView(child: content);
  }
}

class _StatusView extends StatelessWidget {
  final Map<String, dynamic> data;

  const _StatusView({required this.data});

  @override
  Widget build(BuildContext context) {
    return Text(
      (data['message'] ?? 'Sin contenido.').toString(),
      style: const TextStyle(
        fontSize: 14,
        height: 1.55,
        color: Color(0xFF374151),
      ),
    );
  }
}

class _SummaryView extends StatelessWidget {
  final Map<String, dynamic> data;

  const _SummaryView({required this.data});

  @override
  Widget build(BuildContext context) {
    final sections = _asList(data['sections']);
    final quickReview = _asStringList(data['quick_review']);
    final headline = data['headline']?.toString() ?? '';

    if (sections.isEmpty && quickReview.isEmpty && headline.trim().isEmpty) {
      return const _EmptyStructuredState(
        message: 'No llegaron secciones válidas para el resumen.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (headline.trim().isNotEmpty) ...[
          _BannerText(text: headline),
          const SizedBox(height: 16),
        ],
        for (int i = 0; i < sections.length; i++) ...[
          _SummarySectionCard(section: sections[i], index: i + 1),
          if (i != sections.length - 1) const SizedBox(height: 14),
        ],
        if (quickReview.isNotEmpty) ...[
          const SizedBox(height: 18),
          const Text(
            'Repaso Rápido',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: quickReview
                .map((item) => _CapsuleLabel(text: item))
                .toList(),
          ),
        ],
      ],
    );
  }
}

class _FlashcardsView extends StatelessWidget {
  final Map<String, dynamic> data;

  const _FlashcardsView({required this.data});

  @override
  Widget build(BuildContext context) {
    final cards = _asList(data['cards']);
    if (cards.isEmpty) {
      return const _EmptyStructuredState(
        message:
            'No llegaron flashcards válidas. Vuelve a generar o revisa el formato del backend.',
      );
    }

    return Column(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          _FlashcardTile(index: i + 1, item: cards[i]),
          if (i != cards.length - 1) const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _QuizView extends StatelessWidget {
  final Map<String, dynamic> data;

  const _QuizView({required this.data});

  @override
  Widget build(BuildContext context) {
    final questions = _asList(data['questions']);
    if (questions.isEmpty) {
      return const _EmptyStructuredState(
        message:
            'No llegaron preguntas válidas para el quiz. Vuelve a generar o revisa el formato del backend.',
      );
    }

    return Column(
      children: [
        for (int i = 0; i < questions.length; i++) ...[
          _QuizQuestionCard(questionNumber: i + 1, item: questions[i]),
          if (i != questions.length - 1) const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _ChecklistView extends StatelessWidget {
  final Map<String, dynamic> data;

  const _ChecklistView({required this.data});

  @override
  Widget build(BuildContext context) {
    final items = _asList(data['items']);
    if (items.isEmpty) {
      return const _EmptyStructuredState(
        message: 'No llegaron items válidos para el checklist.',
      );
    }

    return Column(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          _ChecklistItemCard(item: items[i]),
          if (i != items.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _ConclusionsView extends StatelessWidget {
  final Map<String, dynamic> data;

  const _ConclusionsView({required this.data});

  @override
  Widget build(BuildContext context) {
    final insights = _asList(data['insights']);
    if (insights.isEmpty) {
      return const _EmptyStructuredState(
        message: 'No llegaron conclusiones válidas.',
      );
    }

    return Column(
      children: [
        for (int i = 0; i < insights.length; i++) ...[
          _InsightCard(index: i + 1, item: insights[i]),
          if (i != insights.length - 1) const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _BannerText extends StatelessWidget {
  final String text;

  const _BannerText({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.zero,
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          height: 1.45,
          fontWeight: FontWeight.w600,
          color: Color(0xFF111827),
        ),
      ),
    );
  }
}

class _SummarySectionCard extends StatefulWidget {
  final Map<String, dynamic> section;
  final int index;

  const _SummarySectionCard({required this.section, required this.index});

  @override
  State<_SummarySectionCard> createState() => _SummarySectionCardState();
}

class _SummarySectionCardState extends State<_SummarySectionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final points = _asStringList(widget.section['points']);
    return InkWell(
      onTap: () => setState(() => _expanded = !_expanded),
      borderRadius: BorderRadius.zero,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _expanded ? const Color(0xFFF9FAFB) : Colors.white,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _IndexPill(text: '${widget.index}'),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    (widget.section['heading'] ?? 'Sección').toString(),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
                Icon(
                  _expanded ? Icons.remove : Icons.add,
                  color: const Color(0xFF111827),
                ),
              ],
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 180),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox(height: 0),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: points
                      .map(
                        (point) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 6),
                                child: Icon(
                                  Icons.circle,
                                  size: 7,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  point,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.45,
                                    color: Color(0xFF374151),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlashcardTile extends StatefulWidget {
  final int index;
  final Map<String, dynamic> item;

  const _FlashcardTile({required this.index, required this.item});

  @override
  State<_FlashcardTile> createState() => _FlashcardTileState();
}

class _FlashcardTileState extends State<_FlashcardTile> {
  bool _showBack = false;

  @override
  Widget build(BuildContext context) {
    final front = (widget.item['front'] ?? '').toString();
    final back = (widget.item['back'] ?? '').toString();

    return InkWell(
      onTap: () => setState(() => _showBack = !_showBack),
      borderRadius: BorderRadius.zero,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.zero,
          color: _showBack ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
          border: Border.all(
            color: _showBack
                ? const Color(0xFF111827)
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _showBack
                        ? const Color(0x33FFFFFF)
                        : const Color(0xFF111827),
                    borderRadius: BorderRadius.zero,
                  ),
                  child: Text(
                    _showBack
                        ? 'Reverso ${widget.index}'
                        : 'Frente ${widget.index}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _showBack ? Colors.white : const Color(0xFFF9FAFB),
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _showBack ? 'Toca para regresar' : 'Toca para voltear',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _showBack
                        ? const Color(0xFFD1D5DB)
                        : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: Text(
                _showBack ? back : front,
                key: ValueKey(_showBack),
                style: TextStyle(
                  fontSize: 17,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                  color: _showBack ? Colors.white : const Color(0xFF111827),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizQuestionCard extends StatefulWidget {
  final int questionNumber;
  final Map<String, dynamic> item;

  const _QuizQuestionCard({required this.questionNumber, required this.item});

  @override
  State<_QuizQuestionCard> createState() => _QuizQuestionCardState();
}

class _QuizQuestionCardState extends State<_QuizQuestionCard> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final options = _asStringList(widget.item['options']);
    final correctIndex = (widget.item['correctIndex'] as num?)?.toInt() ?? -1;
    final explanation = (widget.item['explanation'] ?? '').toString();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.zero,
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.zero,
                ),
                child: Text(
                  'Quiz ${widget.questionNumber}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              if (_selectedIndex != null)
                Text(
                  _selectedIndex == correctIndex ? 'Correcta' : 'Incorrecta',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _selectedIndex == correctIndex
                        ? const Color(0xFF15803D)
                        : const Color(0xFFB91C1C),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            (widget.item['question'] ?? '').toString(),
            style: const TextStyle(
              fontSize: 16,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          for (int i = 0; i < options.length; i++)
            _buildOption(i, options[i], correctIndex),
          if (_selectedIndex != null && explanation.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.zero,
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Text(
                explanation,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Color(0xFF4B5563),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOption(int index, String text, int correctIndex) {
    final hasAnswered = _selectedIndex != null;
    final isSelected = _selectedIndex == index;
    final isCorrect = correctIndex == index;

    Color background = Colors.white;
    Color border = const Color(0xFFD1D5DB);
    Color label = const Color(0xFF111827);

    if (hasAnswered && isCorrect) {
      background = const Color(0xFFDCFCE7);
      border = const Color(0xFF22C55E);
      label = const Color(0xFF166534);
    } else if (hasAnswered && isSelected && !isCorrect) {
      background = const Color(0xFFFEE2E2);
      border = const Color(0xFFEF4444);
      label = const Color(0xFF991B1B);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: hasAnswered
            ? null
            : () => setState(() => _selectedIndex = index),
        borderRadius: BorderRadius.zero,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.zero,
            border: Border.all(color: border, width: 1.2),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: hasAnswered && isCorrect
                      ? const Color(0xFF22C55E)
                      : const Color(0xFF111827),
                  border: Border.all(color: Colors.transparent),
                ),
                child: Text(
                  String.fromCharCode(65 + index),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                    color: label,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChecklistItemCard extends StatefulWidget {
  final Map<String, dynamic> item;

  const _ChecklistItemCard({required this.item});

  @override
  State<_ChecklistItemCard> createState() => _ChecklistItemCardState();
}

class _ChecklistItemCardState extends State<_ChecklistItemCard> {
  bool _checked = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => setState(() => _checked = !_checked),
      borderRadius: BorderRadius.zero,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _checked ? const Color(0xFFECFDF5) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.zero,
          border: Border.all(
            color: _checked ? const Color(0xFF34D399) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              _checked ? Icons.check_circle : Icons.radio_button_unchecked,
              color: _checked
                  ? const Color(0xFF059669)
                  : const Color(0xFF6B7280),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (widget.item['text'] ?? '').toString(),
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                      color: _checked
                          ? const Color(0xFF065F46)
                          : const Color(0xFF111827),
                    ),
                  ),
                  if ((widget.item['why'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      widget.item['why'].toString(),
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: _checked
                            ? const Color(0xFF047857)
                            : const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightCard extends StatefulWidget {
  final int index;
  final Map<String, dynamic> item;

  const _InsightCard({required this.index, required this.item});

  @override
  State<_InsightCard> createState() => _InsightCardState();
}

class _InsightCardState extends State<_InsightCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => setState(() => _expanded = !_expanded),
      borderRadius: BorderRadius.zero,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.zero,
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _IndexPill(text: '${widget.index}'),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    (widget.item['title'] ?? 'Insight').toString(),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: const Color(0xFF111827),
                ),
              ],
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 180),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox(height: 0),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  (widget.item['detail'] ?? '').toString(),
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: Color(0xFF374151),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IndexPill extends StatelessWidget {
  final String text;

  const _IndexPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: Color(0xFF111827)),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _CapsuleLabel extends StatelessWidget {
  final String text;

  const _CapsuleLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.zero,
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF374151),
        ),
      ),
    );
  }
}

class _EmptyStructuredState extends StatelessWidget {
  final String message;

  const _EmptyStructuredState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.zero,
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 14,
          height: 1.45,
          color: Color(0xFF6B7280),
        ),
      ),
    );
  }
}

List<Map<String, dynamic>> _asList(dynamic value) {
  if (value is List) {
    return value.whereType<Map>().map((item) {
      return item.map((key, value) => MapEntry(key.toString(), value));
    }).toList();
  }
  return const [];
}

List<String> _asStringList(dynamic value) {
  if (value is List) {
    return value.map((item) => item.toString()).toList();
  }
  return const [];
}
