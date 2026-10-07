import 'package:meta/meta.dart';

enum WatchKind {
  /// Fondo amplio (miles de empresas): la base de una cartera.
  broadFund,

  /// Fondo temático (robótica, IA): diversifica dentro del tema.
  thematicFund,

  /// Empresa individual: más riesgo y más volatilidad.
  company,
}

/// Instrumento que vale la pena seguir. No es una recomendación de compra.
@immutable
final class WatchItem {
  const new({
    required this.symbol,
    required this.name,
    required this.why,
    required this.kind,
  });

  /// Símbolo público (Yahoo Finance): `NVDA`, `6324.T`…
  final String symbol;
  final String name;

  /// En qué negocio está, en una frase.
  final String why;
  final WatchKind kind;
}

/// Lista de tecnología, IA y robótica para seguir (y aprender de ella).
abstract final class TechWatchlist {
  static const items = <WatchItem>[
    WatchItem(
      symbol: 'VT',
      name: 'Vanguard Total World',
      why: 'Unas 9.000 empresas del mundo en un solo fondo. La base.',
      kind: WatchKind.broadFund,
    ),
    WatchItem(
      symbol: 'BOTZ',
      name: 'Global X Robotics & AI',
      why: 'Fondo de robótica e IA: reparte el riesgo entre decenas.',
      kind: WatchKind.thematicFund,
    ),
    WatchItem(
      symbol: 'ROBO',
      name: 'ROBO Global Robotics',
      why: 'Fondo de automatización y robótica con más empresas medianas.',
      kind: WatchKind.thematicFund,
    ),
    WatchItem(
      symbol: 'NVDA',
      name: 'NVIDIA',
      why: 'Chips que entrenan y ejecutan la inteligencia artificial.',
      kind: WatchKind.company,
    ),
    WatchItem(
      symbol: 'TSM',
      name: 'TSMC',
      why: 'Fabrica los chips más avanzados del mundo (incluidos los de IA).',
      kind: WatchKind.company,
    ),
    WatchItem(
      symbol: 'NVEC',
      name: 'NVE Corp',
      why: 'Sensores espintrónicos para equipos médicos e industriales.',
      kind: WatchKind.company,
    ),
    WatchItem(
      symbol: 'NOVT',
      name: 'Novanta',
      why: 'Fotónica y control de movimiento de precisión para robots.',
      kind: WatchKind.company,
    ),
    WatchItem(
      symbol: '6324.T',
      name: 'Harmonic Drive Systems',
      why: 'Reductores de precisión para las articulaciones de robots.',
      kind: WatchKind.company,
    ),
    WatchItem(
      symbol: 'ISRG',
      name: 'Intuitive Surgical',
      why: 'Robots quirúrgicos da Vinci.',
      kind: WatchKind.company,
    ),
    WatchItem(
      symbol: 'TER',
      name: 'Teradyne',
      why: 'Dueña de Universal Robots (robots colaborativos).',
      kind: WatchKind.company,
    ),
    WatchItem(
      symbol: '6954.T',
      name: 'Fanuc',
      why: 'Uno de los mayores fabricantes de robots industriales.',
      kind: WatchKind.company,
    ),
    WatchItem(
      symbol: 'ROK',
      name: 'Rockwell Automation',
      why: 'Automatización de fábricas.',
      kind: WatchKind.company,
    ),
    WatchItem(
      symbol: 'SYM',
      name: 'Symbotic',
      why: 'Robots que automatizan bodegas. Muy volátil.',
      kind: WatchKind.company,
    ),
  ];
}
