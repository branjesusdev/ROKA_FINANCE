import 'package:finance_app/application/dashboard/salary_forecast.dart';
import 'package:finance_app/application/dashboard/spend_check.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/presentation/shared/data_providers.dart';
import 'package:finance_app/presentation/shared/forecast_chart.dart';
import 'package:finance_app/presentation/shared/form_widgets.dart';
import 'package:finance_app/presentation/shared/formatters.dart';
import 'package:finance_app/presentation/shared/status_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "¿Puedo gastar X hoy?": SÍ o NO con tu sueldo, tus pagos que faltan y
/// los próximos meses. No registra nada.
Future<void> showSpendCheckSheet(BuildContext context) =>
    showFormSheet<void>(context, const SpendCheckSheet());

class SpendCheckSheet extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<SpendCheckSheet> createState() => _SpendCheckSheetState();
}

class _SpendCheckSheetState extends ConsumerState<SpendCheckSheet> {
  final _amount = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(cycleSummaryProvider).value;
    final forecast = ref.watch(salaryForecastProvider).value;
    final amount = MoneyField.read(_amount) ?? Money.zero;
    final check = summary == null
        ? null
        : const SpendCheckBuilder().build(
            summary: summary,
            amount: amount,
            forecast: forecast,
          );
    return FormSheet(
      title: '¿Puedo gastar?',
      saveLabel: 'Listo',
      onSave: () => Navigator.pop(context),
      children: [
        MoneyField(
          controller: _amount,
          label: '¿Cuánto quieres gastar?',
          helperText: 'Ej: 600.000 de mantenimiento del carro',
          autofocus: true,
          onChanged: (_) => setState(() {}),
        ),
        if (check != null)
          _Result(check: check)
        else if (summary != null && summary.dailyCap == null)
          const Text(
            'El ciclo ya terminó: cuando llegue el sueldo podrás simularlo.',
          )
        else if (forecast != null) ...[
          Text(
            '¿Estaré corto los próximos meses?',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          ForecastSummary(forecast: forecast),
        ],
        Text(
          'Es una simulación con tu sueldo y tus pagos: no registra nada.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _Result extends StatelessWidget {
  const new({required this.check});

  final SpendCheck check;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final forecast = check.forecastAfter;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Verdict(check: check),
        const SizedBox(height: 16),
        _Bills(check: check),
        if (forecast != null) ...[
          const SizedBox(height: 16),
          Text(
            'Así quedarían tus próximos meses si lo pagas hoy',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          ForecastChart(forecast: forecast, before: check.forecast),
          const SizedBox(height: 4),
          Text(forecastBasis(forecast), style: theme.textTheme.bodySmall),
        ],
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.zero,
          title: Text('Tus opciones', style: theme.textTheme.titleSmall),
          children: [
            _Option(
              icon: Icons.today_outlined,
              title: 'Pagarlo todo hoy',
              body: _pathText(check.payAll),
            ),
            _Option(
              icon: Icons.call_split,
              title: 'La mitad hoy y la mitad con el sueldo',
              body: _pathText(check.payHalf),
            ),
            _Option(
              icon: Icons.event_available_outlined,
              title: 'Esperar al sueldo',
              body:
                  'El ${Formatters.shortDate(check.nextPayday)} llega el '
                  'sueldo: tu tope de hoy sigue en '
                  '${Formatters.money(check.capToday)}.',
            ),
          ],
        ),
      ],
    );
  }

  String _pathText(SpendPath path) {
    final after = path.dailyCapAfter;
    final spent = Formatters.money(path.spentNow);
    if (after == null) {
      return 'Pagas $spent hoy, último día del ciclo.';
    }
    final days = check.daysAfterToday;
    final cut = path.dailyCut;
    return 'Pagas $spent hoy y los próximos $days '
        '${days == 1 ? 'día' : 'días'} tu tope queda en '
        '${Formatters.money(after)} al día'
        '${cut.isPositive ? ' (${Formatters.money(cut)} menos que hoy)' : ''}.';
  }
}

/// El SÍ o el NO, grande, con la razón en una frase.
class _Verdict extends StatelessWidget {
  const new({required this.check});

  final SpendCheck check;

  static const _backgroundAlpha = 0.12;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final decision = check.decision;
    final yes = decision.canSpend;
    final color = yes ? StatusColors.okOf(scheme) : scheme.error;
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: _backgroundAlpha),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    yes ? Icons.check_circle : Icons.block,
                    color: color,
                    size: 36,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      yes ? 'SÍ, puedes' : 'NO lo gastes',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(_reason(), style: theme.textTheme.bodyLarge),
              if (_when() case final hint?) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.event_outlined, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(hint, style: theme.textTheme.titleSmall),
                    ),
                  ],
                ),
              ],
              if (decision.isBig) ...[
                const SizedBox(height: 8),
                Text(
                  'Es más del '
                  '${Formatters.percent(SpendCheckBuilder.bigShare)} de tu '
                  'sueldo: regla de las 24 horas. Si mañana lo sigues '
                  'queriendo, cómpralo sin culpa.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _reason() {
    final amount = Formatters.money(check.amount);
    final decision = check.decision;
    return switch (decision.reason) {
      null when check.verdict == SpendVerdict.fitsToday =>
        'Los $amount caben en lo que te queda del tope de hoy '
            '(${Formatters.money(check.remainingToday)}). Tus pagos y tus '
            'próximos meses no cambian.',
      null =>
        'Tus pagos que faltan siguen cubiertos y ningún mes queda en rojo. '
            'Eso sí: hasta el sueldo tu tope baja a '
            '${Formatters.money(check.payAll.dailyCapAfter ?? Money.zero)} '
            'al día.',
      SpendNoReason.touchesFixed =>
        'Te faltarían ${Formatters.money(check.shortfall)} para tus pagos '
            'fijos de este ciclo. Esa plata ya tiene dueño.',
      SpendNoReason.touchesReserves =>
        'Solo tienes ${Formatters.money(check.freeLeft)} libres hasta el '
            'sueldo. Los otros ${Formatters.money(check.fromReserves)} '
            'saldrían de tu ahorro, tus pagos del año o el mercado del mes.',
      SpendNoReason.tooTight =>
        'Hasta el sueldo te quedarían '
            '${Formatters.money(check.payAll.dailyCapAfter ?? Money.zero)} '
            'al día, menos de la mitad de tu tope de hoy '
            '(${Formatters.money(check.capToday)}). No vas a aguantar.',
      SpendNoReason.shortLater => _shortLater(decision.shortMonth),
    };
  }

  String _shortLater(ForecastMonth? month) {
    final after = check.forecastAfter;
    if (month == null || after == null || !after.shortThisCycle) {
      return month == null
          ? 'Con tu sueldo no alcanza para tus pagos de los próximos meses.'
          : 'Este ciclo alcanza, pero con tu sueldo en '
                '${Formatters.monthAbbr(month.payday)} te faltarían '
                '${Formatters.money(month.balance.abs)} para tus gastos.';
    }
    return 'Con tu ritmo de gasto este ciclo cerraría '
        '${Formatters.money(after.cycleEnd.abs)} en rojo.';
  }

  String? _when() {
    final decision = check.decision;
    if (decision.canSpend) return null;
    final when = decision.when;
    final date = when.date;
    final waitPayday =
        'Espera al sueldo del ${Formatters.shortDate(check.nextPayday)}: '
        'ahí sí cabe sin apretarte.';
    if (check.forecast == null || when.isNow) return waitPayday;
    if (when.reachable && date != null) {
      return 'Puedes desde el ${Formatters.shortDate(date)} (con ese sueldo) '
          'sin quedar corto ningún mes.';
    }
    if (check.forecast?.knowsSalary == false) {
      return 'Escribe tu sueldo en Ajustes › Mi sueldo para decirte cuándo '
          'sí.';
    }
    return when.reachable
        ? null
        : 'Con tu sueldo actual no alcanza en los próximos '
              '${SalaryForecastBuilder.horizon} meses: ahorra para esto '
              'primero o busca un ingreso extra.';
  }
}

/// "Antes del sueldo todavía debes pagar…": enfático, son plata con
/// dueño.
class _Bills extends StatelessWidget {
  const new({required this.check});

  final SpendCheck check;

  static const _maxShown = 5;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bills = check.billsBeforePayday;
    if (bills.isEmpty) {
      return Row(
        children: [
          Icon(Icons.task_alt, color: StatusColors.okOf(scheme)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Ya no te faltan pagos fijos antes del sueldo del '
              '${Formatters.shortDate(check.nextPayday)}.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      );
    }
    final hidden = bills.length - _maxShown;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              color: StatusColors.warningOf(scheme),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Antes del sueldo aún debes pagar '
                '${Formatters.money(check.billsTotal)}',
                style: theme.textTheme.titleSmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        for (final bill in bills.take(_maxShown))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                SizedBox(
                  width: 56,
                  child: Text(
                    Formatters.shortDate(bill.date),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                Expanded(
                  child: Text(
                    bill.movement.name,
                    style: theme.textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${bill.movement.isVariable ? '~' : ''}'
                  '${Formatters.money(bill.movement.amount)}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        if (hidden > 0)
          Text(
            'Y $hidden ${hidden == 1 ? 'pago' : 'pagos'} más.',
            style: theme.textTheme.bodySmall,
          ),
        const SizedBox(height: 4),
        Text(
          'Esa plata ya está separada: no es para gastar.',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _Option extends StatelessWidget {
  const new({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title, style: theme.textTheme.bodyLarge),
      subtitle: Text(body),
    );
  }
}

/// Atajo para abrir la simulación desde otras pantallas.
class SpendCheckButton extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: () => showSpendCheckSheet(context),
    icon: const Icon(Icons.help_outline),
    label: const Text('¿Puedo gastar…?'),
  );
}

/// Versión discreta para Movimientos.
class SpendCheckTextButton extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: () => showSpendCheckSheet(context),
    icon: const Icon(Icons.help_outline, size: 18),
    label: const Text('¿Puedo gastar…?'),
  );
}
