import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

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
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasBoundedHeight = constraints.hasBoundedHeight;
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
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 16),
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

    if (!scrollable) {
      return content;
    }
    return SingleChildScrollView(child: content);
  }
}

class _StatusView extends StatelessWidget {
  final Map<String, dynamic> data;

  const _StatusView({required this.data});

  @override
  Widget build(BuildContext context) {
    return _PanelBlock(
      child: Text(
        (data['message'] ?? 'Sin contenido.').toString(),
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(color: AppColors.muted),
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
        message: 'No llegaron secciones validas para el resumen.',
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
          _MicroLabel(text: 'Repaso Rapido'),
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
            'No llegaron flashcards validas. Vuelve a generar o revisa el formato del backend.',
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
            'No llegaron preguntas validas para el quiz. Vuelve a generar o revisa el formato del backend.',
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
        message: 'No llegaron items validos para el checklist.',
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
        message: 'No llegaron conclusiones validas.',
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

class _PanelBlock extends StatelessWidget {
  final Widget child;
  final Color? color;
  final Color? borderColor;

  const _PanelBlock({required this.child, this.color, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? AppColors.surfaceAlt,
        border: Border.all(color: borderColor ?? AppColors.border),
      ),
      child: child,
    );
  }
}

class _BannerText extends StatelessWidget {
  final String text;

  const _BannerText({required this.text});

  @override
  Widget build(BuildContext context) {
    return _PanelBlock(
      color: AppColors.primary.withValues(alpha: 0.08),
      borderColor: AppColors.primary.withValues(alpha: 0.35),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(color: AppColors.text, height: 1.5),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _expanded ? AppColors.surfaceAlt : AppColors.panel,
          border: Border.all(
            color: _expanded ? AppColors.secondary : AppColors.border,
          ),
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
                    (widget.section['heading'] ?? 'Seccion').toString(),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Icon(
                  _expanded ? Icons.remove : Icons.add,
                  color: AppColors.secondary,
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
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(top: 7),
                                color: AppColors.warning,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  point,
                                  style: Theme.of(context).textTheme.bodyMedium,
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _showBack ? AppColors.primary : AppColors.panel,
          border: Border.all(
            color: _showBack ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _MicroLabel(
                  text: _showBack
                      ? 'Reverso ${widget.index}'
                      : 'Frente ${widget.index}',
                  inverted: _showBack,
                ),
                const Spacer(),
                Text(
                  _showBack ? 'Toca para regresar' : 'Toca para voltear',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _showBack ? AppColors.background : AppColors.muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.02, 0.08),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: Container(
                key: ValueKey('${widget.index}_$_showBack'),
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 108),
                alignment: Alignment.centerLeft,
                child: Text(
                  _showBack ? back : front,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 17,
                    height: 1.5,
                    color: _showBack ? AppColors.background : AppColors.text,
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

    return _PanelBlock(
      color: AppColors.panel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _MicroLabel(text: 'Quiz ${widget.questionNumber}'),
              const Spacer(),
              if (_selectedIndex != null)
                Text(
                  _selectedIndex == correctIndex ? 'Correcta' : 'Incorrecta',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: _selectedIndex == correctIndex
                        ? AppColors.success
                        : AppColors.danger,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            (widget.item['question'] ?? '').toString(),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(height: 1.45),
          ),
          const SizedBox(height: 16),
          for (int i = 0; i < options.length; i++)
            _buildOption(context, i, options[i], correctIndex),
          if (_selectedIndex != null && explanation.isNotEmpty) ...[
            const SizedBox(height: 8),
            _PanelBlock(
              color: AppColors.surfaceAlt,
              child: Text(
                explanation,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context,
    int index,
    String text,
    int correctIndex,
  ) {
    final hasAnswered = _selectedIndex != null;
    final isSelected = _selectedIndex == index;
    final isCorrect = correctIndex == index;

    Color background = AppColors.surface;
    Color border = AppColors.border;
    Color label = AppColors.text;
    Color badge = AppColors.secondary;

    if (hasAnswered && isCorrect) {
      background = AppColors.success.withValues(alpha: 0.14);
      border = AppColors.success;
      label = AppColors.success;
      badge = AppColors.success;
    } else if (hasAnswered && isSelected && !isCorrect) {
      background = AppColors.danger.withValues(alpha: 0.14);
      border = AppColors.danger;
      label = AppColors.danger;
      badge = AppColors.danger;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: hasAnswered
            ? null
            : () => setState(() => _selectedIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: background,
            border: Border.all(color: border, width: 1.2),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: badge),
                child: Text(
                  String.fromCharCode(65 + index),
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: AppColors.background),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: label),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _checked
              ? AppColors.success.withValues(alpha: 0.12)
              : AppColors.panel,
          border: Border.all(
            color: _checked ? AppColors.success : AppColors.border,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _checked ? AppColors.success : Colors.transparent,
                border: Border.all(
                  color: _checked ? AppColors.success : AppColors.muted,
                ),
              ),
              child: _checked
                  ? const Icon(
                      Icons.check,
                      size: 14,
                      color: AppColors.background,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (widget.item['text'] ?? '').toString(),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: _checked ? AppColors.success : AppColors.text,
                    ),
                  ),
                  if ((widget.item['why'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      widget.item['why'].toString(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _checked ? AppColors.success : AppColors.muted,
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _expanded ? AppColors.surfaceAlt : AppColors.panel,
          border: Border.all(
            color: _expanded ? AppColors.warning : AppColors.border,
          ),
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
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: AppColors.warning,
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
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
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
      decoration: const BoxDecoration(color: AppColors.secondary),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(color: AppColors.background),
      ),
    );
  }
}

class _MicroLabel extends StatelessWidget {
  final String text;
  final bool inverted;

  const _MicroLabel({required this.text, this.inverted = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: inverted ? AppColors.background : AppColors.warning,
      ),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: inverted ? AppColors.text : AppColors.background,
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
        color: AppColors.surfaceAlt,
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: AppColors.text),
      ),
    );
  }
}

class _EmptyStructuredState extends StatelessWidget {
  final String message;

  const _EmptyStructuredState({required this.message});

  @override
  Widget build(BuildContext context) {
    return _PanelBlock(
      child: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
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
