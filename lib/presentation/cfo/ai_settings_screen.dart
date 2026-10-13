import 'package:finance_app/bootstrap/use_cases.dart';
import 'package:finance_app/domain/savings/finance_settings.dart';
import 'package:finance_app/presentation/shared/data_providers.dart';
import 'package:finance_app/presentation/shared/form_widgets.dart';
import 'package:finance_app/presentation/shared/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Activar "Tu CFO con IA": qué se envía, a quién, con qué llave y cada
/// cuánto. Nada sale del teléfono hasta que el usuario lo activa.
class AiSettingsScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends ConsumerState<AiSettingsScreen> {
  final _key = TextEditingController();
  bool _showKey = false;

  @override
  void dispose() {
    _key.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings =
        ref.watch(settingsProvider).value ?? const FinanceSettings();
    final hasKey = ref.watch(hasAiKeyProvider).value ?? false;
    return Scaffold(
      appBar: AppBar(title: const Text('Tu CFO con IA')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const SectionCard(
            title: 'Cómo funciona',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Point(
                  icon: Icons.calculate_outlined,
                  text:
                      'Las cuentas (cuánto te queda, reservas, deudas, '
                      'patrimonio) las hace la app en tu teléfono, con reglas '
                      'fijas. Funcionan sin internet.',
                ),
                _Point(
                  icon: Icons.auto_awesome_outlined,
                  text:
                      'La IA (modelo gpt-oss-120b en Groq) solo lee ese '
                      'resumen y te explica qué hacer. Nunca cambia tus datos '
                      'sin que confirmes.',
                ),
                _Point(
                  icon: Icons.cloud_upload_outlined,
                  text:
                      'Se envía a Groq: totales por categoría, fijos, deudas '
                      '(saldo y tasa), bienes, metas y patrimonio. NO se '
                      'envían descripciones, notas, movimientos uno por uno '
                      'ni los nombres que escribiste.',
                ),
                _Point(
                  icon: Icons.schedule,
                  text:
                      'La revisión periódica corre cuando abres la app (el '
                      'teléfono no deja que corra sola con la app cerrada). '
                      'Las alertas por reglas sí llegan solas.',
                ),
                _Point(
                  icon: Icons.gavel_outlined,
                  text:
                      'Es información para decidir, no asesoría financiera. '
                      'Los rendimientos nunca están garantizados.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Tu llave de Groq',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  hasKey
                      ? 'Hay una llave guardada en este teléfono. Pega otra '
                            'para reemplazarla.'
                      : 'Créala gratis en console.groq.com › API Keys y '
                            'pégala aquí. Se guarda solo en este teléfono: no '
                            'va en la copia de seguridad.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _key,
                  obscureText: !_showKey,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    labelText: 'Llave (empieza por gsk_)',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      tooltip: _showKey ? 'Ocultar llave' : 'Mostrar llave',
                      icon: Icon(
                        _showKey ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () => setState(() => _showKey = !_showKey),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    FilledButton.icon(
                      icon: const Icon(Icons.key),
                      label: const Text('Guardar llave'),
                      onPressed: _saveKey,
                    ),
                    if (hasKey)
                      TextButton.icon(
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Borrar llave'),
                        onPressed: () async {
                          final result = await ref
                              .read(saveAiKeyProvider)
                              .call(null);
                          if (context.mounted) {
                            showResult(
                              context,
                              result,
                              success: 'Llave borrada',
                            );
                          }
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Revisión de tus finanzas',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Activar Tu CFO con IA'),
                  subtitle: const Text(
                    'Acepto enviar el resumen descrito arriba a Groq.',
                  ),
                  value: settings.aiEnabled,
                  onChanged: (enabled) async {
                    if (enabled && !await _confirmConsent(context)) return;
                    final result = await ref
                        .read(updateAiSettingsProvider)
                        .call(enabled: enabled);
                    if (context.mounted) showResult(context, result);
                  },
                ),
                const SizedBox(height: 8),
                Text('Cada cuánto revisa', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                SegmentedButton<ReviewFrequency>(
                  segments: const [
                    ButtonSegment(
                      value: ReviewFrequency.daily,
                      label: Text('Diaria'),
                    ),
                    ButtonSegment(
                      value: ReviewFrequency.weekly,
                      label: Text('Semanal'),
                    ),
                    ButtonSegment(
                      value: ReviewFrequency.monthly,
                      label: Text('Mensual'),
                    ),
                  ],
                  selected: {settings.aiReviewFrequency},
                  onSelectionChanged: settings.aiEnabled
                      ? (selection) => ref
                            .read(updateAiSettingsProvider)
                            .call(frequency: selection.first)
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _PreviewCard(),
        ],
      ),
    );
  }

  Future<void> _saveKey() async {
    final key = _key.text.trim();
    if (key.isEmpty) return;
    final result = await ref.read(saveAiKeyProvider).call(key);
    if (!mounted) return;
    if (showResult(context, result, success: 'Llave guardada')) {
      _key.clear();
      FocusScope.of(context).unfocus();
    }
  }

  static Future<bool> _confirmConsent(BuildContext context) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.cloud_upload_outlined),
          title: const Text('¿Enviar tu resumen a Groq?'),
          content: const Text(
            'Tus totales, fijos, deudas, bienes y metas (sin descripciones ni '
            'nombres) saldrán del teléfono hacia Groq cada vez que se haga '
            'una revisión o una pregunta. Puedes desactivarlo cuando '
            'quieras. Revisa abajo exactamente qué se envía.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Acepto'),
            ),
          ],
        ),
      ) ??
      false;
}

class _Point extends StatelessWidget {
  const new({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

/// El JSON exacto que se enviaría hoy.
class _PreviewCard extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(financialSnapshotProvider).value;
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: const Icon(Icons.visibility_outlined),
          title: const Text('Ver exactamente qué se envía'),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            SelectableText(
              snapshot?.toJson() ?? 'Calculando…',
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
