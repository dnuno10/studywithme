import 'package:flutter/material.dart';

import '../../../services/content_service.dart';
import '../data/generation_modes.dart';
import '../domain/output_fallbacks.dart';
import 'widgets/control_panel.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/output_panel.dart';
import 'widgets/reveal_panel.dart';
import 'widgets/retro_stage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _contentController = TextEditingController();
  final ContentService _contentService = ContentService();

  String _selectedMode = generationModes.first.id;
  Map<String, dynamic>? _output;
  bool _isLoading = false;

  String get _selectedLabel {
    return generationModes.firstWhere((mode) => mode.id == _selectedMode).label;
  }

  Future<void> _generate() async {
    final content = _contentController.text.trim();

    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega contenido antes de generar.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _output = null;
    });

    try {
      final result = await _contentService.generateContent(
        content: content,
        mode: _selectedMode,
      );

      setState(() {
        _output = ensureRenderableOutput(
          mode: _selectedMode,
          result: result,
          sourceText: content,
        );
      });
    } catch (_) {
      setState(() {
        _output = fallbackOutputForMode(_selectedMode, content);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 980;

    return Scaffold(
      body: RetroStage(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1240),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const RevealPanel(
                      delay: Duration(milliseconds: 40),
                      child: DashboardHeader(),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: isWide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 6,
                                  child: RevealPanel(
                                    delay: const Duration(milliseconds: 120),
                                    child: ControlPanel(
                                      controller: _contentController,
                                      selectedMode: _selectedMode,
                                      isLoading: _isLoading,
                                      onModeChanged: (value) {
                                        setState(() => _selectedMode = value);
                                      },
                                      onGenerate: _generate,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  flex: 5,
                                  child: RevealPanel(
                                    delay: const Duration(milliseconds: 220),
                                    child: OutputPanel(
                                      selectedMode: _selectedMode,
                                      selectedLabel: _selectedLabel,
                                      output: _output,
                                      isLoading: _isLoading,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : ListView(
                              children: [
                                RevealPanel(
                                  delay: const Duration(milliseconds: 120),
                                  child: ControlPanel(
                                    controller: _contentController,
                                    selectedMode: _selectedMode,
                                    isLoading: _isLoading,
                                    onModeChanged: (value) {
                                      setState(() => _selectedMode = value);
                                    },
                                    onGenerate: _generate,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                RevealPanel(
                                  delay: const Duration(milliseconds: 220),
                                  child: OutputPanel(
                                    selectedMode: _selectedMode,
                                    selectedLabel: _selectedLabel,
                                    output: _output,
                                    isLoading: _isLoading,
                                  ),
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
      ),
    );
  }
}
