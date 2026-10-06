import 'package:finance_app/domain/categories/category.dart';
import 'package:flutter/material.dart';

/// Traduce el `iconKey` semántico de una categoría a icono y color. El
/// color identifica la categoría en gráficos, listas y selectores; siempre
/// va acompañado del nombre (nunca solo color).
abstract final class CategoryStyle {
  static const _styles = <String, (IconData, Color)>{
    'food': (Icons.restaurant, Color(0xFFF57C00)),
    'housing': (Icons.home, Color(0xFF6D4C41)),
    'transport': (Icons.directions_bus, Color(0xFF1E88E5)),
    'education': (Icons.school, Color(0xFF3949AB)),
    'health': (Icons.local_hospital, Color(0xFFE53935)),
    'sports': (Icons.sports_soccer, Color(0xFF43A047)),
    'entertainment': (Icons.movie, Color(0xFF8E24AA)),
    'debts': (Icons.credit_card, Color(0xFFD81B60)),
    'services': (Icons.bolt, Color(0xFFFFB300)),
    'shopping': (Icons.shopping_bag, Color(0xFF00ACC1)),
    'family': (Icons.family_restroom, Color(0xFFF06292)),
    'investments': (Icons.trending_up, Color(0xFF00897B)),
    'salary': (Icons.payments, Color(0xFF2E7D32)),
    'additional_income': (Icons.work, Color(0xFF7CB342)),
    'extraordinary_income': (Icons.card_giftcard, Color(0xFFC0CA33)),
    'other': (Icons.more_horiz, Color(0xFF757575)),
  };

  static const _fallback = Color(0xFF9E9E9E);

  static IconData icon(String? iconKey) =>
      _styles[iconKey]?.$1 ?? Icons.label_outline;

  static Color color(String? iconKey) => _styles[iconKey]?.$2 ?? _fallback;
}

/// Icono de categoría en círculo de su color (estilo de las listas).
class CategoryAvatar extends StatelessWidget {
  const new({required this.category, this.size = 44, super.key});

  final Category? category;
  final double size;

  static const _backgroundAlpha = 0.16;
  static const _iconFactor = 0.5;

  @override
  Widget build(BuildContext context) {
    final color = CategoryStyle.color(category?.iconKey);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: _backgroundAlpha),
        shape: BoxShape.circle,
      ),
      child: Icon(
        CategoryStyle.icon(category?.iconKey),
        size: size * _iconFactor,
        color: color,
      ),
    );
  }
}
