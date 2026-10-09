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
    // Para categorías propias.
    'pets': (Icons.pets, Color(0xFF92400E)),
    'beauty': (Icons.content_cut, Color(0xFFF59E0B)),
    'clothes': (Icons.checkroom, Color(0xFF7C2D12)),
    'travel': (Icons.flight, Color(0xFF0E7490)),
    'tech': (Icons.phone_iphone, Color(0xFF334155)),
    'coffee': (Icons.local_cafe, Color(0xFF854D0E)),
    'gifts': (Icons.redeem, Color(0xFFB45309)),
    'car': (Icons.directions_car, Color(0xFF1E40AF)),
    'fuel': (Icons.local_gas_station, Color(0xFFC2410C)),
    'baby': (Icons.child_friendly, Color(0xFF0F766E)),
    'subscriptions': (Icons.subscriptions, Color(0xFF1D4ED8)),
    'savings': (Icons.savings, Color(0xFF166534)),
    'business': (Icons.storefront, Color(0xFF3F6212)),
    'church': (Icons.volunteer_activism, Color(0xFF57534E)),
  };

  /// Iconos que se pueden elegir al crear o editar una categoría.
  static List<String> get choosableKeys => _styles.keys
      .where((key) => !_reserved.contains(key))
      .toList(growable: false);

  /// Con significado especial en la app: no se ofrecen al elegir.
  static const _reserved = {
    'debts',
    'investments',
    'provisions',
    'untracked',
    'balance',
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
