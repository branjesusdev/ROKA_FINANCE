import 'package:meta/meta.dart';

enum CategoryKind { income, expense }

@immutable
final class Category {
  const new({
    required this.id,
    required this.name,
    required this.kind,
    required this.iconKey,
    this.sortOrder = 0,
    this.isArchived = false,
    this.countsAsSaving = false,
    this.isExtraordinary = false,
  });

  final String id;
  final String name;
  final CategoryKind kind;

  /// Clave semántica del icono; la UI la traduce a un `IconData`.
  final String iconKey;
  final int sortOrder;

  /// Las categorías no se borran (tienen movimientos): se archivan.
  final bool isArchived;

  /// Gasto que en realidad es ahorro/inversión: no cuenta como gasto.
  final bool countsAsSaving;

  /// Ingreso que no llega cada mes (prima, cesantías, bonos…): no se cuenta
  /// como dinero disponible de forma permanente.
  final bool isExtraordinary;

  Category copyWith({
    String? name,
    String? iconKey,
    int? sortOrder,
    bool? isArchived,
    bool? countsAsSaving,
    bool? isExtraordinary,
  }) => Category(
    id: id,
    name: name ?? this.name,
    kind: kind,
    iconKey: iconKey ?? this.iconKey,
    sortOrder: sortOrder ?? this.sortOrder,
    isArchived: isArchived ?? this.isArchived,
    countsAsSaving: countsAsSaving ?? this.countsAsSaving,
    isExtraordinary: isExtraordinary ?? this.isExtraordinary,
  );

  @override
  bool operator ==(Object other) =>
      other is Category &&
      other.id == id &&
      other.name == name &&
      other.kind == kind &&
      other.iconKey == iconKey &&
      other.sortOrder == sortOrder &&
      other.isArchived == isArchived &&
      other.countsAsSaving == countsAsSaving &&
      other.isExtraordinary == isExtraordinary;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    kind,
    iconKey,
    sortOrder,
    isArchived,
    countsAsSaving,
    isExtraordinary,
  );
}
