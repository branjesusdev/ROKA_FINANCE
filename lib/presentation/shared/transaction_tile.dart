import 'package:finance_app/domain/categories/category.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:finance_app/presentation/shared/category_style.dart';
import 'package:finance_app/presentation/shared/formatters.dart';
import 'package:flutter/material.dart';

/// Fila de un movimiento: icono de categoría, descripción y monto con signo.
class TransactionTile extends StatelessWidget {
  const new({
    required this.transaction,
    required this.category,
    this.showDate = true,
    super.key,
  });

  static const incomeColor = Color(0xFF2E7D32);

  final Transaction transaction;
  final Category? category;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryName = category?.name ?? 'Sin categoría';
    final description = transaction.description;
    final amount = transaction.isIncome
        ? '+${Formatters.money(transaction.amount)}'
        : '-${Formatters.money(transaction.amount)}';
    final subtitle = [
      if (description != null) categoryName,
      if (showDate) Formatters.shortDate(transaction.date),
    ].join(' · ');

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CategoryAvatar(category: category, size: 40),
      title: Text(
        description ?? categoryName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: subtitle.isEmpty ? null : Text(subtitle),
      trailing: Text(
        amount,
        style: theme.textTheme.titleSmall?.copyWith(
          color: transaction.isIncome ? incomeColor : null,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
