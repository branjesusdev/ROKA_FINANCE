import 'package:finance_app/application/insights/category_report.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:finance_app/domain/transactions/fuel_economy.dart';
import 'package:finance_app/presentation/cfo/ask_cfo_sheet.dart';
import 'package:finance_app/presentation/shared/async_view.dart';
import 'package:finance_app/presentation/shared/category_style.dart';
import 'package:finance_app/presentation/shared/data_providers.dart';
import 'package:finance_app/presentation/shared/formatters.dart';
import 'package:finance_app/presentation/shared/section_card.dart';
import 'package:finance_app/presentation/shared/status_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> openCategoryReport(BuildContext context, String categoryId) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CategoryReportScreen(categoryId: categoryId),
      ),
    );

/// Análisis de una categoría en los últimos 12 meses: en qué mes gastaste
/// más, qué cosas pesan más y, si es de vehículo, cuánto te cuesta el km.
class CategoryReportScreen extends ConsumerWidget {
  const new({required this.categoryId, super.key});

  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiEnabled = ref.watch(settingsProvider).value?.aiEnabled ?? false;
    return AsyncView(
      value: ref.watch(categoryReportProvider(categoryId)),
      builder: (report) => Scaffold(
        appBar: AppBar(title: Text(report?.category.name ?? 'Categoría')),
        body: report == null
            ? const Center(child: Text('Esta categoría ya no existe.'))
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  _Header(report: report),
                  const SizedBox(height: 12),
                  if (report.isEmpty)
                    const SectionCard(
                      title: 'Sin movimientos',
                      child: Text(
                        'No hay movimientos en esta categoría en los '
                        'últimos 12 meses.',
                      ),
                    )
                  else ...[
                    _MonthsCard(report: report),
                    const SizedBox(height: 12),
                    _ItemsCard(report: report),
                  ],
                  if (FuelEconomyCalculator.appliesTo(report.category)) ...[
                    const SizedBox(height: 12),
                    _FuelCard(fuel: report.fuel),
                  ],
                  if (aiEnabled && !report.isEmpty) ...[
                    const SizedBox(height: 12),
                    _AiCard(report: report),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'Calculado con lo que registras en el teléfono. No es '
                    'asesoría financiera.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
      ),
    );
  }
}

String _signed(Percentage p) =>
    '${p.isNegative ? '' : '+'}${Formatters.percent(p)}';

class _Header extends StatelessWidget {
  const new({required this.report});

  final CategoryReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final change = report.currentVsAverage;
    final average = report.monthlyAverage;
    final above = change != null && !change.isNegative;
    final color = change == null
        ? theme.colorScheme.onSurfaceVariant
        : above
        ? StatusColors.warningOf(theme.colorScheme)
        : StatusColors.okOf(theme.colorScheme);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CategoryAvatar(category: report.category, size: 48),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Este mes', style: theme.textTheme.labelLarge),
                  Text(
                    Formatters.money(report.current.total),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (average != null)
                    Row(
                      children: [
                        if (change != null)
                          Icon(
                            above ? Icons.trending_up : Icons.trending_down,
                            size: 16,
                            color: color,
                          ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            change == null
                                ? 'Promedio mensual '
                                      '${Formatters.money(average)}'
                                : '${_signed(change)} frente a tu promedio '
                                      'de ${Formatters.money(average)} al mes',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Barras de los 12 meses; el mes con más gasto resaltado.
class _MonthsCard extends StatelessWidget {
  const new({required this.report});

  final CategoryReport report;

  static const _barHeight = 120.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final peak = report.peak;
    final max = peak?.total.cents ?? 0;
    final months = report.months;
    return SectionCard(
      title: '¿En qué mes gasté más?',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (peak != null)
            Text(
              '${Formatters.month(peak.month)} fue el mes más alto: '
              '${Formatters.money(peak.total)} en ${peak.count} '
              '${peak.count == 1 ? 'compra' : 'compras'}.',
              style: theme.textTheme.bodyMedium,
            ),
          const SizedBox(height: 12),
          Semantics(
            label: [
              for (final m in months.where((m) => m.count > 0))
                '${Formatters.month(m.month)}: ${Formatters.money(m.total)}',
            ].join('. '),
            child: ExcludeSemantics(
              child: SizedBox(
                height: _barHeight + 32,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final m in months)
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              height: max == 0
                                  ? 0
                                  : _barHeight * m.total.cents / max,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                color: m == peak
                                    ? theme.colorScheme.tertiary
                                    : m == report.current
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.primary.withValues(
                                        alpha: 0.35,
                                      ),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _initial(m.month.month),
                              style: theme.textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'En 12 meses: ${Formatters.money(report.total)} en '
            '${report.count} ${report.count == 1 ? 'compra' : 'compras'}'
            '${report.averageTicket == null ? '' : ' · promedio por compra '
                      '${Formatters.money(report.averageTicket!)}'}.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  static const _initials = 'EFMAMJJASOND';
  static String _initial(int month) => _initials[month - 1];
}

class _ItemsCard extends StatelessWidget {
  const new({required this.report});

  final CategoryReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final biggest = report.biggest;
    final what = biggest?.description;
    return SectionCard(
      title: '¿En qué cosas gasto más?',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final item in report.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name ?? 'Sin descripción',
                          style: item.name == null
                              ? theme.textTheme.bodyMedium?.copyWith(
                                  fontStyle: FontStyle.italic,
                                )
                              : theme.textTheme.bodyMedium,
                        ),
                      ),
                      Text(
                        '${Formatters.money(item.total)}'
                        '${item.share == null ? '' : ' · '
                                  '${Formatters.percent(item.share!)}'}',
                        style: theme.textTheme.labelLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: (item.share?.fraction ?? 0).clamp(0, 1).toDouble(),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  Text(
                    '${item.count} ${item.count == 1 ? 'vez' : 'veces'} · '
                    'promedio ${Formatters.money(item.average)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          if (report.items.any((i) => i.name == null))
            Text(
              'Tip: escribe una descripción al anotar (ej: "carne", '
              '"aseo") para ver en qué se va el dinero.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          if (biggest != null) ...[
            const Divider(height: 24),
            Text(
              'Compra más grande: ${Formatters.money(biggest.amount)}'
              '${what == null ? '' : ' ($what)'}'
              ' el ${Formatters.shortDate(biggest.date)}.',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

class _FuelCard extends StatelessWidget {
  const new({required this.fuel});

  final FuelEconomy? fuel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fuel = this.fuel;
    if (fuel == null || !fuel.hasData) {
      return const SectionCard(
        title: 'Gasolina de tu vehículo',
        child: Text(
          'Al anotar gasolina, escribe el kilometraje del vehículo. Desde la '
          'segunda tanqueada verás cuánto te cuesta cada kilómetro.',
        ),
      );
    }
    final last = fuel.lastCostPerKm;
    final change = fuel.lastVsAverage;
    final up = change != null && !change.isNegative;
    return SectionCard(
      title: 'Gasolina de tu vehículo',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${Formatters.money(fuel.costPerKm!)} por km',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            '${Formatters.money(fuel.costPer100Km!)} cada 100 km · '
            '${Formatters.pesos(fuel.kmDriven)} km en ${fuel.fills} '
            'tanqueadas',
            style: theme.textTheme.bodyMedium,
          ),
          if (fuel.kmPerFill case final km?)
            Text(
              'Andas unos ${Formatters.pesos(km)} km entre tanqueadas.',
              style: theme.textTheme.bodySmall,
            ),
          if (last != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (change != null)
                  Icon(
                    up ? Icons.trending_up : Icons.trending_down,
                    size: 16,
                    color: up
                        ? StatusColors.warningOf(theme.colorScheme)
                        : StatusColors.okOf(theme.colorScheme),
                  ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Última tanqueada: ${Formatters.money(last)} por km en '
                    '${Formatters.pesos(fuel.lastSegmentKm!)} km'
                    '${change == null ? '' : ' (${_signed(change)} '
                              'frente a tu promedio)'}.',
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Se calcula con el método de tanque lleno: lo que pagas al '
            'tanquear repone lo que gastaste desde la tanqueada anterior.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pide la opinión de la IA con los totales por mes. Los nombres de lo que
/// compras solo se envían si el usuario lo marca.
class _AiCard extends StatefulWidget {
  const new({required this.report});

  final CategoryReport report;

  @override
  State<_AiCard> createState() => _AiCardState();
}

class _AiCardState extends State<_AiCard> {
  bool _includeNames = false;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Opinión de Tu CFO con IA',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Envía a Groq los totales por mes de esta categoría para que te '
            'diga cómo bajar el gasto. Verás la pregunta antes de enviarla.',
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _includeNames,
            title: const Text('Incluir lo que más compras'),
            subtitle: const Text(
              'Envía también tus descripciones (ej: "carne"). Apagado, solo '
              'van montos.',
            ),
            onChanged: (on) => setState(() => _includeNames = on),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Preguntarle a Tu CFO'),
            onPressed: () => showAskCfoSheet(
              context,
              question: categoryQuestion(
                widget.report,
                includeNames: _includeNames,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const _closingQuestion =
    '¿Por qué subió en los meses altos y qué puedo hacer para gastar menos '
    'sin dejar de cubrir lo necesario?';

/// Pregunta para la IA: totales por mes y, si se autoriza, las cosas que
/// más pesan.
String categoryQuestion(CategoryReport report, {required bool includeNames}) {
  final months = [
    for (final m in report.months.where((m) => m.count > 0))
      '${Formatters.month(m.month)} ${Formatters.money(m.total)}',
  ].join(', ');
  final items = includeNames
      ? [
          for (final i in report.items.where((i) => i.name != null))
            '${i.name} ${Formatters.money(i.total)} (${i.count} veces)',
        ].join(', ')
      : '';
  final fuel = report.fuel;
  return [
    'Mi gasto en ${report.category.name} por mes: $months.',
    if (report.monthlyAverage case final avg?)
      'Promedio ${Formatters.money(avg)} al mes.',
    if (items.isNotEmpty) 'Lo que más compro: $items.',
    if (fuel != null && fuel.hasData)
      'Gasolina: ${Formatters.money(fuel.costPerKm!)} por km.',
    _closingQuestion,
  ].join(' ');
}
