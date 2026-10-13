import 'package:finance_app/presentation/budgets/budget_screen.dart';
import 'package:finance_app/presentation/goals/goals_screen.dart';
import 'package:flutter/material.dart';

/// Plan del dinero: presupuesto del mes y metas de ahorro, juntos para que la
/// barra inferior tenga 5 destinos con nombre.
class PlanScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(icon: Icon(Icons.pie_chart_outline), text: 'Presupuesto'),
              Tab(icon: Icon(Icons.savings_outlined), text: 'Metas'),
            ],
          ),
          Expanded(
            child: TabBarView(children: [BudgetScreen(), GoalsScreen()]),
          ),
        ],
      ),
    );
  }
}
