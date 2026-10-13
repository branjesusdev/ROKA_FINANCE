import 'package:finance_app/bootstrap/use_cases.dart';
import 'package:finance_app/core/result.dart';
import 'package:finance_app/presentation/shared/data_providers.dart';
import 'package:finance_app/presentation/shared/form_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showAskCfoSheet(BuildContext context, {String? question}) =>
    showFormSheet<void>(context, AskCfoSheet(initialQuestion: question));

/// Pregunta libre a Tu CFO (con tu resumen como contexto).
class AskCfoSheet extends ConsumerStatefulWidget {
  const new({this.initialQuestion, super.key});

  final String? initialQuestion;

  @override
  ConsumerState<AskCfoSheet> createState() => _AskCfoSheetState();
}

class _AskCfoSheetState extends ConsumerState<AskCfoSheet> {
  late final _question = TextEditingController(text: widget.initialQuestion);
  String? _answer;
  bool _asking = false;

  static const suggestions = [
    '¿Cuánto puedo invertir este mes sin arriesgar mis pagos?',
    '¿Me conviene abonar a la deuda o ahorrar?',
    '¿Cómo reparto mi prima?',
    '¿Qué riesgo tiene concentrarme en mis acciones de tecnología?',
    '¿En qué estoy gastando de más?',
  ];

  @override
  void dispose() {
    _question.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Pregúntale a tu CFO', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in suggestions)
                  ActionChip(
                    label: Text(s, maxLines: 2),
                    onPressed: () => setState(() => _question.text = s),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _question,
              minLines: 2,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Tu pregunta',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: _asking
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: Text(_asking ? 'Pensando…' : 'Preguntar'),
              onPressed: _asking ? null : _ask,
            ),
            if (_answer case final answer?) ...[
              const SizedBox(height: 16),
              Card(
                margin: EdgeInsets.zero,
                color: theme.colorScheme.secondaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SelectableText(
                    answer,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Respuesta generada por IA: puede equivocarse y no es asesoría '
                'financiera.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _ask() async {
    final question = _question.text.trim();
    if (question.isEmpty) return;
    setState(() => _asking = true);
    final snapshot = await ref.read(financialSnapshotProvider.future);
    final result = await ref
        .read(askCfoProvider)
        .call(snapshot: snapshot, question: question);
    if (!mounted) return;
    setState(() {
      _asking = false;
      if (result case Ok(:final value)) _answer = value;
    });
    if (result case Err()) showResult(context, result);
  }
}
