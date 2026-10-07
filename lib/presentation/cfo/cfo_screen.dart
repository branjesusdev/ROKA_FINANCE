import 'package:finance_app/application/advisor/cfo_brief.dart';
import 'package:finance_app/bootstrap/providers.dart';
import 'package:finance_app/domain/savings/finance_settings.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/wisdom/wealth_wisdom.dart';
import 'package:finance_app/presentation/cfo/watchlist_card.dart';
import 'package:finance_app/presentation/shared/async_view.dart';
import 'package:finance_app/presentation/shared/data_providers.dart';
import 'package:finance_app/presentation/shared/formatters.dart';
import 'package:finance_app/presentation/shared/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "Tu CFO": qué está pasando con tu dinero, qué opciones hay, cuánto
/// cuesta cada una y frases para no perder el norte. Descriptivo: no es
/// asesoría financiera.
class CfoScreen extends ConsumerWidget {
  const new({super.key});

  static const _spacing = SizedBox(height: 16);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(clockProvider).now();
    return AsyncView(
      value: ref.watch(cfoBriefProvider),
      builder: (brief) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 160),
        children: [
          _QuoteCard(quote: WealthWisdom.quoteFor(today)),
          _spacing,
          _TipsCard(tips: brief.tips),
          if (brief.plan case final plan?) ...[_spacing, _PlanCard(plan: plan)],
          _spacing,
          const WatchlistCard(),
          _spacing,
          const _WisdomCard(),
          _spacing,
          Text(
            'Información descriptiva calculada con tus datos y precios '
            'públicos. No es asesoría financiera: tú decides.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const new({required this.quote});

  final Quote quote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.format_quote,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  'Frase del día',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              quote.text,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '— ${quote.author}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipsCard extends StatelessWidget {
  const new({required this.tips});

  final List<CoachTip> tips;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Qué está pasando',
      child: Column(
        children: [
          for (final tip in tips)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(_icon(tip)),
              title: Text(_title(tip)),
              subtitle: Text(_detail(tip)),
            ),
        ],
      ),
    );
  }

  static String _bufferHint(Money? suggested) => suggested == null
      ? ''
      : ' Aparta unos ${Formatters.money(suggested)} al mes para imprevistos '
            'de los niños (Ajustes › Mi hogar).';

  static IconData _icon(CoachTip tip) => switch (tip) {
    DeficitTip() => Icons.report_problem_outlined,
    PreviousCycleTip() => Icons.history,
    DependentsTip() => Icons.family_restroom,
    DailyCapTip(:final cap) =>
      cap.exceeded ? Icons.do_not_disturb_on_outlined : Icons.today,
    SmallLeaksTip() => Icons.water_drop_outlined,
    TopCategoryTip() => Icons.pie_chart_outline,
    IdleMoneyTip() => Icons.hourglass_bottom,
    EmergencyFundTip() => Icons.health_and_safety_outlined,
    ExpensiveDebtTip() => Icons.credit_card_off_outlined,
    SavingsBehindTip() => Icons.savings_outlined,
    PrincipleTip() => Icons.lightbulb_outline,
  };

  static String _title(CoachTip tip) => switch (tip) {
    DeficitTip(:final deficit) =>
      'Te faltan ${Formatters.money(deficit)} para tus fijos',
    PreviousCycleTip(:final result) =>
      result.isNegative
          ? 'El ciclo pasado cerró con déficit de '
                '${Formatters.money(result.abs)}'
          : 'El ciclo pasado tuvo gastos sin registrar',
    DependentsTip(:final dependents, :final soloProvider) =>
      '${dependents == 1 ? '1 hijo' : '$dependents hijos'} a cargo'
          '${soloProvider ? ' y un solo ingreso' : ''}',
    DailyCapTip(:final cap) =>
      cap.exceeded
          ? 'Hoy pasaste tu tope por '
                '${Formatters.money(cap.remainingToday.abs)}'
          : 'Hoy te quedan ${Formatters.money(cap.remainingToday)}',
    SmallLeaksTip(:final count, :final total) =>
      'Fugas: $count compras pequeñas suman ${Formatters.money(total)}',
    TopCategoryTip(:final category, :final share) =>
      '${category?.name ?? 'Una categoría'} se lleva el '
          '${Formatters.percent(share)} de tu día a día',
    IdleMoneyTip(:final amount) => 'Tienes ${Formatters.money(amount)} quietos',
    EmergencyFundTip(:final progress) =>
      progress == null
          ? 'Aún no tienes fondo de emergencia'
          : 'Fondo de emergencia al ${Formatters.percent(progress)}',
    ExpensiveDebtTip(:final debt, :final annualRate) =>
      '${debt.name} te cobra ${Formatters.percent(annualRate)} al año',
    SavingsBehindTip() => 'Tu ahorro va atrasado este ciclo',
    PrincipleTip(:final principle) => principle.title,
  };

  static String _detail(CoachTip tip) => switch (tip) {
    DeficitTip(:final daysLeft) =>
      'Con lo que tienes no alcanza para los fijos que faltan en los '
          'próximos $daysLeft días. Prioriza arriendo, servicios y comida; '
          'pausa todo lo demás hasta el sueldo.',
    PreviousCycleTip(:final untracked) =>
      untracked.isPositive
          ? '${Formatters.money(untracked)} salieron sin saber en qué. Este '
                'ciclo anota cada gasto (el micrófono toma 5 segundos) y '
                'ciérralo mejor.'
          : 'Meta de este ciclo: cerrar en cero o mejor. El tope diario ya '
                'te marca el ritmo.',
    DependentsTip(
      :final emergencyMonths,
      :final familySpent,
      :final suggestedBuffer,
    ) =>
      'Tu fondo de emergencia debería cubrir $emergencyMonths meses. '
          'Llevas ${Formatters.money(familySpent)} en Hijos/Familia este '
          'ciclo.${_bufferHint(suggestedBuffer)} Considera un seguro de '
          'vida: protege a quienes dependen de ti.',
    DailyCapTip(:final cap) =>
      cap.exceeded
          ? 'Pausa las compras no planeadas hasta mañana. Lo que pasaste '
                'baja el tope de los próximos días.'
          : 'De un tope de ${Formatters.money(cap.cap)}. Lo que no gastes '
                'hoy queda para ahorrar.',
    SmallLeaksTip(:final threshold, :final yearlyPace) =>
      'Cada una de ${Formatters.money(threshold)} o menos. A este ritmo '
          'serían ${Formatters.money(yearlyPace)} al año.',
    TopCategoryTip(:final amount) =>
      '${Formatters.money(amount)} en este ciclo. Es el primer lugar para '
          'recortar sin dolor.',
    IdleMoneyTip(:final yearlyLoss) =>
      'Con una inflación de ~$_inflation pierden unos '
          '${Formatters.money(yearlyLoss)} de poder de compra al año. Mira el '
          'plan de abajo.',
    EmergencyFundTip(:final missing, :final progress) =>
      progress == null
          ? 'Meta sugerida: ${Formatters.money(missing)} '
                '(${FinanceSettings.suggestedEmergencyMonths} meses de gastos '
                'esenciales). Créala en Metas.'
          : 'Faltan ${Formatters.money(missing)}. Es lo que te deja invertir '
                'sin miedo.',
    ExpensiveDebtTip(:final monthlyInterest, :final annualRate) =>
      'Unos ${Formatters.money(monthlyInterest)} de intereses al mes. Cada '
          'abono extra "rinde" ${Formatters.percent(annualRate)} seguro.',
    SavingsBehindTip(:final target, :final saved) =>
      'Referencia: ${Formatters.money(target)}; llevas '
          '${Formatters.money(saved)}. Págate primero: apártalo hoy.',
    PrincipleTip(:final principle) => principle.detail,
  };
}

String get _inflation => Formatters.percent(FinanceSettings.referenceInflation);

String get _illustrativeReturn =>
    Formatters.percent(FinanceSettings.illustrativeAnnualReturn);

class _PlanCard extends StatelessWidget {
  const new({required this.plan});

  final CyclePlan plan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return SectionCard(
      title: plan.fromPreviousCycle
          ? 'Plan para lo que sobró'
          : 'Plan para tu ahorro del ciclo',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Formatters.money(plan.amount),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            plan.fromPreviousCycle
                ? 'Sobró del ciclo anterior. Una opción para ponerlo a '
                      'trabajar:'
                : 'Es tu ahorro de referencia. Apártalo apenas llegue el '
                      'sueldo y repártelo así:',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          for (final slice in plan.slices)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(_icon(slice.kind)),
              title: Text(
                '${_title(slice)} · ${Formatters.money(slice.amount)}',
              ),
              subtitle: Text(_detail(slice, plan)),
            ),
          const Divider(),
          _Cost(
            icon: Icons.trending_down,
            text:
                'Si lo dejas quieto: pierde ~'
                '${Formatters.money(plan.idleCostPerYear)} de poder de compra '
                'en un año.',
          ),
          const SizedBox(height: 6),
          _Cost(
            icon: Icons.trending_up,
            text:
                'Invertido a $_illustrativeReturn anual por '
                '${FinanceSettings.illustrativeYears} años: ~'
                '${Formatters.money(plan.investedExample)}.',
          ),
          const SizedBox(height: 6),
          Text(
            'Ejemplo ilustrativo, no garantizado. Las acciones pueden bajar.',
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
        ],
      ),
    );
  }

  static IconData _icon(PlanSliceKind kind) => switch (kind) {
    PlanSliceKind.emergencyFund => Icons.health_and_safety_outlined,
    PlanSliceKind.debt => Icons.credit_card_off_outlined,
    PlanSliceKind.broadFund => Icons.public,
    PlanSliceKind.thematic => Icons.precision_manufacturing_outlined,
  };

  static String _title(PlanSlice slice) => switch (slice.kind) {
    PlanSliceKind.emergencyFund => 'Fondo de emergencia',
    PlanSliceKind.debt => 'Abono a ${slice.label ?? 'tu deuda'}',
    PlanSliceKind.broadFund => 'Fondo amplio',
    PlanSliceKind.thematic => 'Tecnología: IA y robótica',
  };

  static String _detail(PlanSlice slice, CyclePlan plan) {
    switch (slice.kind) {
      case PlanSliceKind.emergencyFund:
        return 'En algo líquido y seguro: cuenta de alto rendimiento o CDT '
            'corto.';
      case PlanSliceKind.debt:
        return 'Ganancia segura: los intereses que dejas de pagar.';
      case PlanSliceKind.broadFund:
        return 'La base de la cartera: miles de empresas en un solo fondo '
            '(p. ej. ${slice.label ?? 'un ETF global'}).';
      case PlanSliceKind.thematic:
        final pick = plan.thematicPick;
        final stats = pick?.stats;
        if (pick == null || stats == null) {
          return 'Para tu tesis de tecnología. Un fondo como BOTZ o ROBO '
              'reparte el riesgo. Consulta precios abajo para ver quién '
              'está en descuento.';
        }
        final fromHigh = stats.fromHigh;
        final change = stats.change1y;
        final belowHigh = fromHigh == null
            ? ''
            : ' está ${Formatters.percent(fromHigh.abs)} bajo su máximo del '
                  'año';
        final trend = change == null
            ? ''
            : ' y va ${Formatters.percent(change)} en 12 meses';
        return '${pick.item.name} (${pick.item.symbol})$belowHigh$trend. '
            'Investígala antes de decidir.';
    }
  }
}

class _Cost extends StatelessWidget {
  const new({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    );
  }
}

/// Principios para generar riqueza y más frases.
class _WisdomCard extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      title: 'Cómo se construye riqueza',
      child: Column(
        children: [
          for (final principle in WealthWisdom.principles)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.check_circle_outline),
              title: Text(principle.title),
              subtitle: Text(principle.detail),
            ),
          Theme(
            data: theme.copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              leading: const Icon(Icons.format_quote),
              title: const Text('Frases de grandes empresarios'),
              children: [
                for (final quote in WealthWisdom.quotes)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '«${quote.text}»',
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                    subtitle: Text(quote.author),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
