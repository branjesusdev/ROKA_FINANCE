import 'dart:async';

import 'package:finance_app/bootstrap/use_cases.dart';
import 'package:finance_app/presentation/app/app_theme.dart';
import 'package:finance_app/presentation/budgets/budget_screen.dart';
import 'package:finance_app/presentation/goals/goals_screen.dart';
import 'package:finance_app/presentation/home/home_screen.dart';
import 'package:finance_app/presentation/insights/insights_screen.dart';
import 'package:finance_app/presentation/quick_entry/quick_entry_sheet.dart';
import 'package:finance_app/presentation/quick_entry/voice_entry_sheet.dart';
import 'package:finance_app/presentation/settings/settings_sheet.dart';
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
    if (state == AppLifecycleState.resumed) unawaited(_postDueFixed());
  }

  Future<void> _onOpened() async {
    await _postDueFixed();
    await ref.read(syncDailyReminderProvider).call();
  }

  Future<void> _postDueFixed() =>
      ref.read(postDueFixedMovementsProvider).call();

  void _select(int index) => setState(() => _index = index);

  void _openAnalysis() => Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => const InsightsScreen()));

  @override
  Widget build(BuildContext context) {
    final isHome = _index == _homeIndex;
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: isHome ? null : Text(_sections[_index].label),
        actions: [
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
  static const _inactive = Color(0xFF8E8E93);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        height: _height,
        decoration: BoxDecoration(
          color: AppTheme.ink,
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
                      color: i == selected ? Colors.white : _inactive,
                      size: 28,
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
