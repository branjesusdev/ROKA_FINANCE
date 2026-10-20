import 'dart:async';

import 'package:finance_app/application/advisor/financial_alerts.dart';
import 'package:finance_app/application/fixed/fixed_movement_use_cases.dart';
import 'package:finance_app/application/reminders/reminder_scheduler.dart';
import 'package:finance_app/bootstrap/use_cases.dart';
import 'package:finance_app/core/result.dart';
import 'package:finance_app/domain/savings/finance_settings.dart';
import 'package:finance_app/presentation/app/app_theme.dart';
import 'package:finance_app/presentation/cfo/cfo_screen.dart';
import 'package:finance_app/presentation/fixed/bill_actions.dart';
import 'package:finance_app/presentation/home/home_screen.dart';
import 'package:finance_app/presentation/insights/insights_screen.dart';
import 'package:finance_app/presentation/plan/plan_screen.dart';
import 'package:finance_app/presentation/quick_entry/quick_entry_sheet.dart';
import 'package:finance_app/presentation/quick_entry/voice_entry_sheet.dart';
import 'package:finance_app/presentation/settings/settings_sheet.dart';
import 'package:finance_app/presentation/shared/data_providers.dart';
import 'package:finance_app/presentation/transactions/transactions_screen.dart';
import 'package:finance_app/presentation/wealth/wealth_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Navegación principal: 5 destinos con icono y nombre. Los botones de voz y
/// + están en todas las secciones para registrar en segundos.
class AppShell extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver {
  static const _homeIndex = 0;
  static const _transactionsIndex = 1;
  static const _wealthIndex = 3;
  static const _cfoIndex = 4;

  int _index = _homeIndex;

  static const _sections = [
    _Section('Inicio', Icons.home_outlined, Icons.home_rounded),
    _Section('Movimientos', Icons.receipt_long_outlined, Icons.receipt_long),
    _Section('Plan', Icons.track_changes_outlined, Icons.track_changes),
    _Section(
      'Patrimonio',
      Icons.account_balance_outlined,
      Icons.account_balance,
    ),
    _Section('Tu CFO', Icons.auto_awesome_outlined, Icons.auto_awesome),
  ];

  StreamSubscription<ReminderResponse>? _reminderTaps;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _reminderTaps = ref
        .read(reminderResponsesProvider)
        .listen((r) => unawaited(_onReminderTap(r)));
    unawaited(_onOpened());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_reminderTaps?.cancel());
    super.dispose();
  }

  /// Botones del aviso de una factura: "Ya lo pagué" abre el registro del
  /// valor; "Mañana" / "En 2 días" la posponen. Tocar el aviso = ver
  /// "Ya lo pagué".
  Future<void> _onReminderTap(ReminderResponse response) async {
    final movementId = response.payload;
    if (movementId == null) return;
    _select(_homeIndex);
    final days = switch (response.action) {
      ReminderAction.tomorrow => SnoozeFixedBill.tomorrow,
      ReminderAction.inTwoDays => SnoozeFixedBill.inTwoDays,
      ReminderAction.paid || null => null,
    };
    if (days == null) {
      await confirmBillById(context, ref, movementId);
      return;
    }
    final movements = await ref.read(fixedMovementsProvider.future);
    final movement = movements.where((m) => m.id == movementId).firstOrNull;
    if (movement == null || !mounted) return;
    await snoozeBill(context, ref, movement, days: days);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    unawaited(_postDueFixed());
    unawaited(_syncReminders());
    unawaited(_autoReview());
  }

  Future<void> _onOpened() async {
    await _postDueFixed();
    // Sin resumen aún: programa al menos el recordatorio diario.
    await _syncReminders();
    await ref.read(recordNetWorthProvider).call();
    await _autoReview();
  }

  /// Los avisos con montos (tope del día, fijos, cierre, alertas) se
  /// recalculan con cada cambio de datos.
  Future<void> _syncReminders([List<FinancialAlert>? alerts]) => ref
      .read(syncRemindersProvider)
      .call(
        summary: ref.read(cycleSummaryProvider).value,
        alerts: alerts ?? ref.read(financialAlertsProvider).value ?? const [],
      );

  bool _reviewing = false;

  /// Revisión periódica de la IA: solo si el usuario la activó y ya toca
  /// según la frecuencia elegida. Corre con la app abierta.
  Future<void> _autoReview() async {
    final useCase = ref.read(runAiReviewProvider);
    if (_reviewing || !await useCase.isDue()) return;
    _reviewing = true;
    try {
      final snapshot = await ref.read(financialSnapshotProvider.future);
      final result = await useCase(snapshot);
      if (result case Ok(:final value)) {
        final top = value.top;
        await ref
            .read(notifyAiReviewProvider)
            .call(
              title: top == null ? 'Tu CFO revisó tus finanzas' : top.title,
              body: top?.action.isNotEmpty ?? false
                  ? top!.action
                  : value.headline,
            );
      }
    } on Exception {
      // Sin datos o sin red: se reintenta la próxima vez que abras la app.
    } finally {
      _reviewing = false;
    }
  }

  Future<void> _postDueFixed() =>
      ref.read(postDueFixedMovementsProvider).call();

  void _select(int index) => setState(() => _index = index);

  void _openAnalysis() => Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => const InsightsScreen()));

  @override
  Widget build(BuildContext context) {
    ref.listen(financialAlertsProvider, (_, next) {
      if (next.value case final alerts?) unawaited(_syncReminders(alerts));
    });
    // Un fijo nuevo o editado reprograma sus avisos (víspera y día de pago).
    ref.listen(fixedMovementsProvider, (previous, next) {
      if (previous?.value != null && next.hasValue) {
        unawaited(_syncReminders());
      }
    });
    final isHome = _index == _homeIndex;
    // Atrás (gesto o botón) desde otra sección vuelve a Inicio; solo desde
    // Inicio sale de la app.
    return PopScope(
      canPop: isHome,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _select(_homeIndex);
      },
      child: _buildScaffold(isHome: isHome),
    );
  }

  Widget _buildScaffold({required bool isHome}) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: isHome ? null : Text(_sections[_index].label),
        actions: [
          const _AppearanceButton(),
          IconButton(
            tooltip: 'Análisis',
            icon: const Icon(Icons.insights),
            onPressed: _openAnalysis,
          ),
          IconButton(
            tooltip: 'Ajustes',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => showSettingsSheet(context),
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(
            onSeeAllTransactions: () => _select(_transactionsIndex),
            onOpenAnalysis: _openAnalysis,
            onOpenCfo: () => _select(_cfoIndex),
            onOpenWealth: () => _select(_wealthIndex),
          ),
          const TransactionsScreen(),
          const PlanScreen(),
          const WealthScreen(),
          const CfoScreen(),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'voice',
            tooltip: 'Registrar por voz',
            backgroundColor: AppTheme.accent,
            foregroundColor: AppTheme.onAccent,
            onPressed: () => showVoiceEntrySheet(context),
            child: const Icon(Icons.mic),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'add',
            tooltip: 'Registrar movimiento',
            onPressed: () => showQuickEntrySheet(context),
            child: const Icon(Icons.add),
          ),
        ],
      ),
      bottomNavigationBar: _IconNavBar(
        sections: _sections,
        selected: _index,
        onSelected: _select,
      ),
    );
  }
}

/// Cambia entre claro y oscuro (la primera vez parte del tema del teléfono).
class _AppearanceButton extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      tooltip: isDark ? 'Cambiar a modo claro' : 'Cambiar a modo oscuro',
      icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
      onPressed: () => ref
          .read(updateAppearanceProvider)
          .call(isDark ? Appearance.light : Appearance.dark),
    );
  }
}

class _Section {
  const new(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// Barra flotante oscura solo con iconos (el nombre de cada sección va en
/// el tooltip y en Semantics). Cada destino mide al menos 48 px.
class _IconNavBar extends StatelessWidget {
  const new({
    required this.sections,
    required this.selected,
    required this.onSelected,
  });

  final List<_Section> sections;
  final int selected;
  final ValueChanged<int> onSelected;

  static const _height = 60.0;
  static const _indicatorWidth = 52.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Container(
        height: _height,
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark
              ? AppTheme.inkOnDark
              : AppTheme.ink,
          borderRadius: BorderRadius.circular(_height / 2),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          children: [
            for (var i = 0; i < sections.length; i++)
              Expanded(
                child: Semantics(
                  selected: i == selected,
                  button: true,
                  label: sections[i].label,
                  excludeSemantics: true,
                  child: Tooltip(
                    message: sections[i].label,
                    excludeFromSemantics: true,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(_height / 2),
                      onTap: () => onSelected(i),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: _indicatorWidth,
                            height: 30,
                            decoration: BoxDecoration(
                              color: i == selected
                                  ? AppTheme.accent.withValues(alpha: 0.18)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Icon(
                              i == selected
                                  ? sections[i].selectedIcon
                                  : sections[i].icon,
                              color: i == selected
                                  ? AppTheme.accent
                                  : AppTheme.inkMuted,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
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
