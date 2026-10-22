import 'package:finance_app/domain/categories/category.dart';
import 'package:flutter/material.dart';

/// Traduce el `iconKey` semántico de una categoría a icono y color. El
/// color identifica la categoría en gráficos, listas y selectores; siempre
/// va acompañado del nombre (nunca solo color).
abstract final class CategoryStyle {
  // Paleta sin rosados ni morados; colores distinguibles entre sí. Las
  // claves se guardan en la base y en las copias: nunca renombrarlas.
  static const _styles = <String, _IconSpec>{
    'food': _IconSpec(
      Icons.restaurant,
      Color(0xFFEA580C),
      'comida restaurante almuerzo',
    ),
    'groceries': _IconSpec(
      Icons.shopping_cart,
      Color(0xFF65A30D),
      'mercado supermercado compras',
    ),
    'housing': _IconSpec(
      Icons.home,
      Color(0xFF78350F),
      'casa arriendo vivienda hogar',
    ),
    'transport': _IconSpec(
      Icons.directions_bus,
      Color(0xFF2563EB),
      'transporte bus pasaje',
    ),
    'education': _IconSpec(
      Icons.school,
      Color(0xFF3730A3),
      'educacion colegio universidad estudio',
    ),
    'health': _IconSpec(
      Icons.local_hospital,
      Color(0xFFDC2626),
      'salud medico hospital eps',
    ),
    'sports': _IconSpec(
      Icons.sports_soccer,
      Color(0xFF16A34A),
      'deporte futbol',
    ),
    'entertainment': _IconSpec(
      Icons.movie,
      Color(0xFF0369A1),
      'entretenimiento cine pelicula',
    ),
    'debts': _IconSpec(
      Icons.credit_card,
      Color(0xFF475569),
      'deudas tarjeta credito',
    ),
    'services': _IconSpec(
      Icons.bolt,
      Color(0xFFCA8A04),
      'servicios luz energia',
    ),
    'shopping': _IconSpec(
      Icons.shopping_bag,
      Color(0xFF0891B2),
      'compras tienda bolsa',
    ),
    'family': _IconSpec(
      Icons.family_restroom,
      Color(0xFF0D9488),
      'familia hijos',
    ),
    'investments': _IconSpec(
      Icons.trending_up,
      Color(0xFF047857),
      'inversiones',
    ),
    'provisions': _IconSpec(
      Icons.event_repeat,
      Color(0xFF0F766E),
      'pagos del ano',
    ),
    'salary': _IconSpec(
      Icons.payments,
      Color(0xFF15803D),
      'sueldo salario nomina',
    ),
    'additional_income': _IconSpec(
      Icons.work,
      Color(0xFF4D7C0F),
      'trabajo ingreso extra',
    ),
    'extraordinary_income': _IconSpec(
      Icons.card_giftcard,
      Color(0xFFA16207),
      'extraordinario',
    ),
    'other': _IconSpec(Icons.more_horiz, Color(0xFF6B7280), 'otros varios'),
    // Ingresos extraordinarios.
    'bonus': _IconSpec(
      Icons.workspace_premium,
      Color(0xFFB45309),
      'prima bono premio',
    ),
    'severance': _IconSpec(
      Icons.account_balance_wallet,
      Color(0xFF166534),
      'cesantias billetera',
    ),
    'interest': _IconSpec(
      Icons.percent,
      Color(0xFF4D7C0F),
      'intereses rendimientos',
    ),
    'commission': _IconSpec(
      Icons.handshake,
      Color(0xFF0E7490),
      'comision acuerdo',
    ),
    'refund': _IconSpec(
      Icons.replay,
      Color(0xFF0369A1),
      'reembolso devolucion',
    ),
    'asset_sale': _IconSpec(Icons.sell, Color(0xFF92400E), 'venta vender'),
    // Para categorías propias.
    'pets': _IconSpec(
      Icons.pets,
      Color(0xFF92400E),
      'mascotas perro gato veterinario',
    ),
    'beauty': _IconSpec(
      Icons.content_cut,
      Color(0xFFF59E0B),
      'belleza peluqueria corte barberia',
    ),
    'clothes': _IconSpec(Icons.checkroom, Color(0xFF7C2D12), 'ropa vestido'),
    'travel': _IconSpec(Icons.flight, Color(0xFF0E7490), 'viajes avion vuelo'),
    'tech': _IconSpec(
      Icons.phone_iphone,
      Color(0xFF334155),
      'tecnologia celular telefono',
    ),
    'coffee': _IconSpec(Icons.local_cafe, Color(0xFF854D0E), 'cafe tinto'),
    'gifts': _IconSpec(Icons.redeem, Color(0xFFB45309), 'regalos'),
    'car': _IconSpec(
      Icons.directions_car,
      Color(0xFF1E40AF),
      'carro auto vehiculo',
    ),
    'fuel': _IconSpec(
      Icons.local_gas_station,
      Color(0xFFC2410C),
      'gasolina combustible tanqueo',
    ),
    'baby': _IconSpec(
      Icons.child_friendly,
      Color(0xFF0F766E),
      'bebe coche panales',
    ),
    'subscriptions': _IconSpec(
      Icons.subscriptions,
      Color(0xFF1D4ED8),
      'suscripciones streaming netflix',
    ),
    'savings': _IconSpec(Icons.savings, Color(0xFF166534), 'ahorro alcancia'),
    'business': _IconSpec(
      Icons.storefront,
      Color(0xFF3F6212),
      'negocio tienda emprendimiento',
    ),
    'church': _IconSpec(
      Icons.volunteer_activism,
      Color(0xFF57534E),
      'iglesia diezmo ofrenda',
    ),
    // Comida y bebida.
    'fast_food': _IconSpec(
      Icons.fastfood,
      Color(0xFFEA580C),
      'comida rapida hamburguesa',
    ),
    'pizza': _IconSpec(Icons.local_pizza, Color(0xFFDC2626), 'pizza'),
    'bakery': _IconSpec(
      Icons.bakery_dining,
      Color(0xFFB45309),
      'panaderia pan',
    ),
    'lunch': _IconSpec(
      Icons.lunch_dining,
      Color(0xFFC2410C),
      'almuerzo corrientazo',
    ),
    'breakfast': _IconSpec(Icons.free_breakfast, Color(0xFF92400E), 'desayuno'),
    'drinks': _IconSpec(
      Icons.local_bar,
      Color(0xFF0E7490),
      'trago bar licor rumba',
    ),
    'beer': _IconSpec(Icons.sports_bar, Color(0xFFCA8A04), 'cerveza pola'),
    'icecream': _IconSpec(Icons.icecream, Color(0xFF0891B2), 'helado postre'),
    'cake': _IconSpec(Icons.cake, Color(0xFFB45309), 'torta cumpleanos ponque'),
    'delivery': _IconSpec(
      Icons.delivery_dining,
      Color(0xFFEA580C),
      'domicilio rappi delivery',
    ),
    'kitchen': _IconSpec(Icons.kitchen, Color(0xFF65A30D), 'cocina nevera'),
    'snacks': _IconSpec(
      Icons.cookie,
      Color(0xFF92400E),
      'onces mecato galletas antojo',
    ),
    'fruits': _IconSpec(Icons.eco, Color(0xFF16A34A), 'frutas verduras plaza'),
    'water_bottle': _IconSpec(
      Icons.local_drink,
      Color(0xFF0284C7),
      'bebida botella gaseosa',
    ),
    // Hogar y servicios.
    'water': _IconSpec(Icons.water_drop, Color(0xFF0284C7), 'agua acueducto'),
    'gas': _IconSpec(
      Icons.local_fire_department,
      Color(0xFFEA580C),
      'gas natural',
    ),
    'internet': _IconSpec(Icons.wifi, Color(0xFF2563EB), 'internet wifi'),
    'phone_plan': _IconSpec(
      Icons.sim_card,
      Color(0xFF0369A1),
      'plan celular minutos datos',
    ),
    'tv': _IconSpec(Icons.tv, Color(0xFF334155), 'television cable'),
    'cleaning': _IconSpec(
      Icons.cleaning_services,
      Color(0xFF0D9488),
      'aseo limpieza empleada',
    ),
    'laundry': _IconSpec(
      Icons.local_laundry_service,
      Color(0xFF0891B2),
      'lavanderia lavar',
    ),
    'furniture': _IconSpec(Icons.chair, Color(0xFF78350F), 'muebles sofa'),
    'repairs': _IconSpec(
      Icons.handyman,
      Color(0xFF57534E),
      'arreglos reparaciones ferreteria',
    ),
    'garden': _IconSpec(Icons.yard, Color(0xFF16A34A), 'jardin plantas'),
    'building': _IconSpec(
      Icons.apartment,
      Color(0xFF475569),
      'administracion edificio conjunto',
    ),
    'appliances': _IconSpec(
      Icons.blender,
      Color(0xFF64748B),
      'electrodomesticos licuadora',
    ),
    'lightbulb': _IconSpec(
      Icons.lightbulb,
      Color(0xFFCA8A04),
      'bombillo ideas',
    ),
    'mortgage': _IconSpec(Icons.house, Color(0xFF92400E), 'hipoteca vivienda'),
    // Transporte.
    'motorcycle': _IconSpec(
      Icons.two_wheeler,
      Color(0xFF1E40AF),
      'moto motocicleta',
    ),
    'taxi': _IconSpec(Icons.local_taxi, Color(0xFFCA8A04), 'taxi uber didi'),
    'bike': _IconSpec(Icons.pedal_bike, Color(0xFF16A34A), 'bicicleta cicla'),
    'metro': _IconSpec(
      Icons.subway,
      Color(0xFF2563EB),
      'metro tren transmilenio',
    ),
    'parking': _IconSpec(
      Icons.local_parking,
      Color(0xFF1D4ED8),
      'parqueadero parqueo',
    ),
    'car_repair': _IconSpec(
      Icons.car_repair,
      Color(0xFF475569),
      'taller mecanico revision',
    ),
    'car_wash': _IconSpec(Icons.local_car_wash, Color(0xFF0891B2), 'lavadero'),
    'toll': _IconSpec(Icons.toll, Color(0xFF64748B), 'peaje'),
    'ev': _IconSpec(Icons.ev_station, Color(0xFF16A34A), 'carga electrica'),
    'ship': _IconSpec(Icons.directions_boat, Color(0xFF0E7490), 'barco lancha'),
    // Salud y cuidado.
    'pharmacy': _IconSpec(
      Icons.local_pharmacy,
      Color(0xFF16A34A),
      'farmacia drogueria medicamentos',
    ),
    'dentist': _IconSpec(
      Icons.medical_services,
      Color(0xFFDC2626),
      'odontologo dentista',
    ),
    'glasses': _IconSpec(
      Icons.visibility,
      Color(0xFF0369A1),
      'optica gafas lentes',
    ),
    'gym': _IconSpec(Icons.fitness_center, Color(0xFF0F766E), 'gimnasio gym'),
    'spa': _IconSpec(Icons.spa, Color(0xFF0D9488), 'spa masaje relajacion'),
    'insurance': _IconSpec(
      Icons.health_and_safety,
      Color(0xFF15803D),
      'seguro poliza prepagada',
    ),
    'psychology': _IconSpec(
      Icons.psychology,
      Color(0xFF0E7490),
      'psicologo terapia',
    ),
    'run': _IconSpec(Icons.directions_run, Color(0xFF16A34A), 'correr'),
    'swim': _IconSpec(Icons.pool, Color(0xFF0284C7), 'piscina natacion'),
    'yoga': _IconSpec(
      Icons.self_improvement,
      Color(0xFF0D9488),
      'yoga meditacion',
    ),
    // Personas y familia.
    'kids': _IconSpec(Icons.child_care, Color(0xFF0F766E), 'ninos'),
    'toys': _IconSpec(Icons.toys, Color(0xFFEA580C), 'juguetes'),
    'partner': _IconSpec(
      Icons.favorite,
      Color(0xFFDC2626),
      'pareja novia novio amor',
    ),
    'elderly': _IconSpec(
      Icons.elderly,
      Color(0xFF57534E),
      'papas abuelos padres',
    ),
    'people': _IconSpec(Icons.groups, Color(0xFF0369A1), 'amigos grupo'),
    'celebration': _IconSpec(
      Icons.celebration,
      Color(0xFFCA8A04),
      'fiesta celebracion',
    ),
    'nanny': _IconSpec(Icons.escalator_warning, Color(0xFF0D9488), 'ninera'),
    // Ocio.
    'games': _IconSpec(
      Icons.sports_esports,
      Color(0xFF1D4ED8),
      'videojuegos juegos consola',
    ),
    'music': _IconSpec(
      Icons.music_note,
      Color(0xFF0369A1),
      'musica spotify concierto',
    ),
    'books': _IconSpec(Icons.menu_book, Color(0xFF3730A3), 'libros lectura'),
    'theater': _IconSpec(
      Icons.theater_comedy,
      Color(0xFFB45309),
      'teatro show',
    ),
    'camera': _IconSpec(
      Icons.photo_camera,
      Color(0xFF334155),
      'fotografia camara',
    ),
    'beach': _IconSpec(
      Icons.beach_access,
      Color(0xFF0891B2),
      'playa vacaciones',
    ),
    'hotel': _IconSpec(Icons.hotel, Color(0xFF1E40AF), 'hotel hospedaje'),
    'luggage': _IconSpec(Icons.luggage, Color(0xFF0E7490), 'maleta'),
    'casino': _IconSpec(
      Icons.casino,
      Color(0xFF7C2D12),
      'apuestas loteria chance',
    ),
    'park': _IconSpec(Icons.park, Color(0xFF16A34A), 'parque paseo'),
    'art': _IconSpec(
      Icons.palette,
      Color(0xFFB45309),
      'arte pintura manualidades',
    ),
    'stadium': _IconSpec(Icons.stadium, Color(0xFF16A34A), 'estadio partido'),
    'hiking': _IconSpec(Icons.hiking, Color(0xFF65A30D), 'caminata montana'),
    // Compras y personal.
    'jewelry': _IconSpec(Icons.diamond, Color(0xFF0E7490), 'joyas accesorios'),
    'watch': _IconSpec(Icons.watch, Color(0xFF334155), 'reloj'),
    'cosmetics': _IconSpec(
      Icons.face,
      Color(0xFFF59E0B),
      'maquillaje cosmeticos cuidado personal',
    ),
    'computer': _IconSpec(
      Icons.computer,
      Color(0xFF334155),
      'computador portatil',
    ),
    'headphones': _IconSpec(Icons.headphones, Color(0xFF1D4ED8), 'audifonos'),
    'cloud': _IconSpec(
      Icons.cloud,
      Color(0xFF0284C7),
      'nube almacenamiento apps',
    ),
    'online_shop': _IconSpec(
      Icons.local_shipping,
      Color(0xFF0891B2),
      'envio online amazon',
    ),
    'mall': _IconSpec(Icons.local_mall, Color(0xFF0E7490), 'centro comercial'),
    'stationery': _IconSpec(
      Icons.edit_note,
      Color(0xFF3730A3),
      'papeleria utiles',
    ),
    'smoking': _IconSpec(
      Icons.smoking_rooms,
      Color(0xFF57534E),
      'cigarrillo vape',
    ),
    // Dinero y trabajo.
    'bank': _IconSpec(
      Icons.account_balance,
      Color(0xFF475569),
      'banco cuota manejo',
    ),
    'taxes': _IconSpec(
      Icons.receipt_long,
      Color(0xFF7C2D12),
      'impuestos predial dian',
    ),
    'fees': _IconSpec(
      Icons.request_quote,
      Color(0xFF64748B),
      'comisiones cobros',
    ),
    'loan': _IconSpec(Icons.money_off, Color(0xFF475569), 'prestamo'),
    'cash': _IconSpec(Icons.attach_money, Color(0xFF15803D), 'efectivo plata'),
    'crypto': _IconSpec(
      Icons.currency_bitcoin,
      Color(0xFFCA8A04),
      'cripto bitcoin',
    ),
    'freelance': _IconSpec(
      Icons.laptop_mac,
      Color(0xFF0369A1),
      'freelance independiente',
    ),
    'rent_income': _IconSpec(
      Icons.key,
      Color(0xFF92400E),
      'arriendo recibido renta',
    ),
    'office': _IconSpec(
      Icons.business_center,
      Color(0xFF334155),
      'oficina maletin',
    ),
    'pension': _IconSpec(
      Icons.elderly_woman,
      Color(0xFF166534),
      'pension jubilacion',
    ),
    'charity': _IconSpec(
      Icons.diversity_3,
      Color(0xFF0D9488),
      'donacion ayuda',
    ),
    'legal': _IconSpec(
      Icons.gavel,
      Color(0xFF57534E),
      'abogado tramites notaria',
    ),
    'documents': _IconSpec(
      Icons.description,
      Color(0xFF64748B),
      'documentos pasaporte',
    ),
    'security': _IconSpec(Icons.shield, Color(0xFF15803D), 'seguridad'),
    'emergency': _IconSpec(
      Icons.emergency,
      Color(0xFFDC2626),
      'emergencia imprevistos',
    ),
    'star': _IconSpec(Icons.star, Color(0xFFCA8A04), 'favorito especial'),
  };

  /// Iconos que se pueden elegir al crear o editar una categoría.
  static List<String> get choosableKeys => _styles.keys
      .where((key) => !_reserved.contains(key))
      .toList(growable: false);

  /// Iconos elegibles cuyo nombre o palabras clave contienen [query] (sin
  /// tildes ni mayúsculas). Vacío = todos.
  static List<String> search(String query) {
    final words = _normalize(query).split(' ').where((w) => w.isNotEmpty);
    if (words.isEmpty) return choosableKeys;
    return [
      for (final key in choosableKeys)
        if (words.every(
          (w) => _styles[key]!.words.contains(w) || key.contains(w),
        ))
          key,
    ];
  }

  /// Icono que mejor encaja con el nombre de una categoría (`null` si no
  /// hay ninguno claro): "Gasolina" → surtidor.
  static String? suggest(String name) {
    final words = _normalize(name)
        .split(' ')
        .where((w) => w.length >= _minSuggestLength);
    for (final word in words) {
      for (final key in choosableKeys) {
        final keywords = _styles[key]!.words.split(' ');
        if (keywords.any((k) => k.startsWith(word) || _stemOf(word, k))) {
          return key;
        }
      }
    }
    return null;
  }

  /// Palabras más cortas no sugieren icono ("de", "la", "mi").
  static const _minSuggestLength = 4;

  /// "mascotas" empieza por "mascota"; "gastos" no por "gas" (muy corta).
  static bool _stemOf(String word, String keyword) =>
      keyword.length > _minSuggestLength && word.startsWith(keyword);

  static String _normalize(String text) {
    const from = 'áéíóúüñ';
    const to = 'aeiouun';
    final buffer = StringBuffer();
    for (final char in text.toLowerCase().trim().split('')) {
      final i = from.indexOf(char);
      buffer.write(i < 0 ? char : to[i]);
    }
    return buffer.toString();
  }

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
      _styles[iconKey]?.icon ?? Icons.label_outline;

  static Color color(String? iconKey) => _styles[iconKey]?.color ?? _fallback;
}

/// Icono, color y palabras para buscarlo (en minúscula y sin tildes).
final class _IconSpec {
  const new(this.icon, this.color, this.words);

  final IconData icon;
  final Color color;
  final String words;
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
