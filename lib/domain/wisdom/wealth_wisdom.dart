import 'package:meta/meta.dart';

@immutable
final class Quote {
  const new(this.text, this.author);

  final String text;
  final String author;
}

/// Principio para construir riqueza, en lenguaje simple.
@immutable
final class WealthPrinciple {
  const new(this.title, this.detail);

  final String title;
  final String detail;
}

/// Frases de grandes inversionistas y empresarios, y principios básicos.
/// Inspiración, no asesoría.
abstract final class WealthWisdom {
  static const quotes = <Quote>[
    Quote(
      'Regla número 1: nunca pierdas dinero. Regla número 2: nunca olvides '
          'la regla número 1.',
      'Warren Buffett',
    ),
    Quote(
      'No ahorres lo que te queda después de gastar; gasta lo que te queda '
          'después de ahorrar.',
      'Warren Buffett',
    ),
    Quote(
      'El precio es lo que pagas; el valor es lo que recibes.',
      'Warren Buffett',
    ),
    Quote(
      'Sé temeroso cuando otros son codiciosos, y codicioso cuando otros son '
          'temerosos.',
      'Warren Buffett',
    ),
    Quote(
      'El riesgo viene de no saber lo que estás haciendo.',
      'Warren Buffett',
    ),
    Quote(
      'Cuidado con los pequeños gastos: una pequeña fuga hunde un gran '
          'barco.',
      'Benjamin Franklin',
    ),
    Quote(
      'Una inversión en conocimiento paga el mejor interés.',
      'Benjamin Franklin',
    ),
    Quote(
      'El gran dinero no está en comprar o vender, sino en esperar.',
      'Charlie Munger',
    ),
    Quote(
      'No importa cuánto dinero ganas, sino cuánto conservas.',
      'Robert Kiyosaki',
    ),
    Quote(
      'Los ricos compran activos. La clase media compra pasivos que cree que '
          'son activos.',
      'Robert Kiyosaki',
    ),
    Quote(
      'Busca riqueza, no dinero ni estatus. La riqueza son activos que ganan '
          'mientras duermes.',
      'Naval Ravikant',
    ),
    Quote(
      'No te harás rico alquilando tu tiempo. Necesitas ser dueño de una '
          'parte de un negocio.',
      'Naval Ravikant',
    ),
    Quote('Conoce lo que posees y por qué lo posees.', 'Peter Lynch'),
    Quote(
      'En el corto plazo el mercado es una máquina de votar; en el largo '
          'plazo, una balanza.',
      'Benjamin Graham',
    ),
    Quote(
      'La educación formal te dará para vivir; la autoeducación te hará una '
          'fortuna.',
      'Jim Rohn',
    ),
    Quote(
      'La riqueza es lo que no ves: los carros, los relojes y los lujos que '
          'decidiste no comprar.',
      'Morgan Housel',
    ),
    Quote(
      'Tu ahorro es la brecha entre tu ego y tus ingresos.',
      'Morgan Housel',
    ),
    Quote('Tu margen es mi oportunidad.', 'Jeff Bezos'),
    Quote(
      'Una parte de todo lo que ganas es tuya para conservarla.',
      'George S. Clason',
    ),
    Quote(
      'Haz que tu dinero trabaje para ti y se multiplique.',
      'George S. Clason',
    ),
    Quote(
      'La riqueza no consiste en tener grandes posesiones, sino en tener '
          'pocas necesidades.',
      'Epicteto',
    ),
    Quote(
      'El mejor momento para plantar un árbol fue hace 20 años. El segundo '
          'mejor momento es ahora.',
      'Proverbio chino',
    ),
  ];

  static const principles = <WealthPrinciple>[
    WealthPrinciple(
      'Págate primero',
      'Apenas llegue el sueldo, separa tu ahorro. Lo que sobra es para '
          'gastar, no al revés.',
    ),
    WealthPrinciple(
      'Fondo de emergencia',
      'Junta de 3 a 6 meses de gastos esenciales en algo líquido y seguro. '
          'Es lo que te permite invertir sin miedo.',
    ),
    WealthPrinciple(
      'Mata la deuda cara',
      'Una tarjeta al 25% anual cuesta más de lo que casi cualquier '
          'inversión te va a dar. Abonarle es una "inversión" segura.',
    ),
    WealthPrinciple(
      'Regla de las 24 horas',
      'Antes de una compra que no estaba planeada, espera un día. Si al '
          'otro día la sigues queriendo, cómprala sin culpa.',
    ),
    WealthPrinciple(
      'El dinero quieto pierde',
      'Con inflación, la plata en el bolsillo compra menos cada año. Ponla '
          'a rendir aunque sea en algo conservador.',
    ),
    WealthPrinciple(
      'Invierte en lo que entiendes',
      'Si no puedes explicar en una frase cómo gana dinero una empresa, '
          'todavía no es momento de comprarla.',
    ),
    WealthPrinciple(
      'Diversifica',
      'Una base en fondos amplios (muchas empresas) y una parte pequeña en '
          'apuestas temáticas, como IA o robótica.',
    ),
    WealthPrinciple(
      'Varias fuentes de ingreso',
      'Sueldo + algo propio (un servicio, un negocio pequeño, dividendos). '
          'Cada fuente nueva te acerca a la independencia.',
    ),
    WealthPrinciple(
      'Invierte en ti',
      'Una habilidad nueva puede subir tu ingreso más que cualquier acción. '
          'Es el activo que nadie te quita.',
    ),
    WealthPrinciple(
      'Constancia sobre timing',
      'Aportar todos los meses, suba o baje el mercado, le gana casi siempre '
          'a intentar adivinar el mejor momento.',
    ),
  ];

  /// Frase del día: cambia cada día y se repite en orden.
  static Quote quoteFor(DateTime day) {
    final dayNumber =
        DateTime.utc(day.year, day.month, day.day).millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;
    return quotes[dayNumber % quotes.length];
  }
}
