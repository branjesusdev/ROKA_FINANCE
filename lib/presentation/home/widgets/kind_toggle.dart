import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:finance_app/presentation/app/app_theme.dart';
import 'package:flutter/material.dart';

/// Selector Gastos / Ingresos con la opción activa resaltada en lima.
class KindToggle extends StatelessWidget {
  const new({required this.selected, required this.onChanged, super.key});

  final TransactionKind selected;
  final ValueChanged<TransactionKind> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _option(context, TransactionKind.expense, 'Gastos'),
        _option(context, TransactionKind.income, 'Ingresos'),
      ],
    );
  }

  Widget _option(BuildContext context, TransactionKind kind, String label) {
    final isSelected = kind == selected;
    final theme = Theme.of(context);
    return Expanded(
      child: Semantics(
        selected: isSelected,
        button: true,
        child: Material(
          color: isSelected ? AppTheme.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => onChanged(kind),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isSelected ? AppTheme.onAccent : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
