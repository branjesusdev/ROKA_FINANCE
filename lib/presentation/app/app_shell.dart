import 'dart:async';

import 'package:finance_app/application/dashboard/cycle_summary.dart';
import 'package:finance_app/bootstrap/use_cases.dart';
import 'package:finance_app/domain/savings/finance_settings.dart';
import 'package:finance_app/presentation/app/app_theme.dart';
import 'package:finance_app/presentation/budgets/budget_screen.dart';
import 'package:finance_app/presentation/cfo/cfo_screen.dart';
import 'package:finance_app/presentation/goals/goals_screen.dart';
import 'package:finance_app/presentation/home/home_screen.dart';
import 'package:finance_app/presentation/insights/insights_screen.dart';
import 'package:finance_app/presentation/quick_entry/quick_entry_sheet.dart';
import 'package:finance_app/presentation/quick_entry/voice_entry_sheet.dart';
import 'package:finance_app/presentation/settings/settings_sheet.dart';
import 'package:finance_app/presentation/shared/data_providers.dart';
import 'package:finance_app/presentation/transactions/transactions_screen.dart';
import 'package:finance_app/presentation/wealth/wealth_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Navegación principal: barra inferior solo con iconos. Los botones de voz
/// y + están en todas las secciones para registrar en segundos.
class AppShell extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver {
  static const _homeIndex = 0;
  static const _transactionsIndex = 1;

  int _index = _homeIndex;

  static const _sections = [
    _Section('Inicio', Icons.home_outlined, Icons.home_rounded),
    _Section('Movimientos', Icons.receipt_long_outlined, Icons.receipt_long),
    _Section('Presupuesto', Icons.pie_chart_outline, Icons.pie_chart),
    _Section(
      'Patrimonio',
      Icons.account_balance_outlined,
      Icons.account_balance,
    ),
    _Section('Metas', Icons.savings_outlined, Icons.savings),
    _Section('Tu CFO', Icons.auto_awesome_outlined, Icons.auto_awesome),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_onOpened());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    unawaited(_postDueFixed());
    unawaited(_syncReminders(ref.read(cycleSummaryProvider).value));
  }

  Future<void> _onOpened() async {
    await _postDueFixed();
    // Sin resumen aún: programa al menos el recordatorio diario.
    await _syncReminders(ref.read(cycleSummaryProvider).value);
  }

  /// Los avisos con montos (tope del día, fijos, cierre) se recalculan con
  /// cada cambio de datos.
  Future<void> _syncReminders(CycleSummary? summary) =>
      ref.read(syncRemindersProvider).call(summary: summary);

  Future<void> _postDueFixed() =>
      ref.read(postDueFixedMovementsProvider).call();

  void _select(int index) => setState(() => _index = index);

  void _openAnalysis() => Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => const InsightsScreen()));

  @override
  Widget build(BuildContext context) {
    ref.listen(cycleSummaryProvider, (_, next) {
      if (next.value case final summary?) unawaited(_syncReminders(summary));
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
          ),
          const TransactionsScreen(),
          const BudgetScreen(),
          const WealthScreen(),
          const GoalsScreen(),
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

/// Barra flotante oscura con solo iconos. El nombre de cada sección queda
/// en el tooltip y en la semántica (lectores de pantalla).
class _IconNavBar extends StatelessWidget {
  const new({
    required this.sections,
    required this.selected,
    required this.onSelected,
  });

  final List<_Section> sections;
  final int selected;
  final ValueChanged<int> onSelected;

  static const _height = 64.0;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        height: _height,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppTheme.inkOnDark
              : AppTheme.ink,
          borderRadius: BorderRadius.circular(_height / 2),
        ),
        child: Row(
          children: [
            for (var i = 0; i < sections.length; i++)
              Expanded(
                child: Semantics(
                  selected: i == selected,
                  button: true,
                  label: sections[i].label,
                  excludeSemantics: true,
                  child: IconButton(
                    tooltip: sections[i].label,
                    onPressed: () => onSelected(i),
                    icon: Icon(
                      i == selected
                          ? sections[i].selectedIcon
                          : sections[i].icon,
                      color: i == selected
                          ? AppTheme.accent
                          : AppTheme.inkMuted,
                      size: 26,
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
