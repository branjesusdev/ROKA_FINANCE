import 'package:finance_app/domain/categories/category.dart';
import 'package:flutter/material.dart';

/// Traduce el `iconKey` semántico de una categoría a icono y color. El
/// color identifica la categoría en gráficos, listas y selectores; siempre
/// va acompañado del nombre (nunca solo color).
abstract final class CategoryStyle {
  // Paleta sin rosados ni morados; colores distinguibles entre sí.
  static const _styles = <String, (IconData, Color)>{
    'food': (Icons.restaurant, Color(0xFFEA580C)),
    'groceries': (Icons.shopping_cart, Color(0xFF65A30D)),
    'housing': (Icons.home, Color(0xFF78350F)),
    'transport': (Icons.directions_bus, Color(0xFF2563EB)),
    'education': (Icons.school, Color(0xFF3730A3)),
    'health': (Icons.local_hospital, Color(0xFFDC2626)),
    'sports': (Icons.sports_soccer, Color(0xFF16A34A)),
    'entertainment': (Icons.movie, Color(0xFF0369A1)),
    'debts': (Icons.credit_card, Color(0xFF475569)),
    'services': (Icons.bolt, Color(0xFFCA8A04)),
    'shopping': (Icons.shopping_bag, Color(0xFF0891B2)),
    'family': (Icons.family_restroom, Color(0xFF0D9488)),
    'investments': (Icons.trending_up, Color(0xFF047857)),
    'provisions': (Icons.event_repeat, Color(0xFF0F766E)),
    'salary': (Icons.payments, Color(0xFF15803D)),
    'additional_income': (Icons.work, Color(0xFF4D7C0F)),
    'extraordinary_income': (Icons.card_giftcard, Color(0xFFA16207)),
    'other': (Icons.more_horiz, Color(0xFF6B7280)),
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
