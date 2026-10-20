import 'package:meta/meta.dart';

@immutable
final class Quote {
  const new(this.text, this.author, {this.book, this.today});

  final String text;
  final String author;

  /// Libro de donde viene la idea (`null` si es una frase suelta).
  final String? book;

  /// Qué hacer hoy con esta idea, en una frase.
  final String? today;

  /// "Robert Kiyosaki, Padre Rico, Padre Pobre".
  String get source => book == null ? author : '$author, $book';
}

/// Principio para construir riqueza, en lenguaje simple.
@immutable
final class WealthPrinciple {
  const new(this.title, this.detail);

  final String title;
  final String detail;
}

/// Frases de libros de dinero (Padre Rico, Padre Pobre; El hombre más
/// rico de Babilonia; Piense y hágase rico; La psicología del dinero…) y
/// de grandes inversionistas, cada una con qué hacer hoy, y principios
/// básicos.
/// Inspiración, no asesoría.
abstract final class WealthWisdom {
  static const quotes = <Quote>[
    Quote(
      'Los ricos no trabajan por dinero: hacen que el dinero trabaje '
          'para ellos.',
      'Robert Kiyosaki',
      book: 'Padre Rico, Padre Pobre',
      today:
          'Identifica algo que te pague sin trabajar (aunque sea pequeño) '
          'y anótalo como meta.',
    ),
    Quote(
      'Un activo pone dinero en tu bolsillo. Un pasivo saca dinero de '
          'tu bolsillo.',
      'Robert Kiyosaki',
      book: 'Padre Rico, Padre Pobre',
      today:
          'Antes de comprar algo, pregúntate: ¿esto me pone o me saca '
          'plata cada mes?',
    ),
    Quote(
      'Los ricos compran activos. La clase media compra pasivos que '
          'cree que son activos.',
      'Robert Kiyosaki',
      book: 'Padre Rico, Padre Pobre',
      today: 'Revisa en Tu Cashflow qué de lo que tienes te cuesta cada mes.',
    ),
    Quote(
      'No importa cuánto dinero ganas, sino cuánto conservas.',
      'Robert Kiyosaki',
      book: 'Padre Rico, Padre Pobre',
      today: 'Mira lo que te sobró el ciclo pasado y decide hoy a dónde va.',
    ),
    Quote(
      'No digas «no puedo pagarlo»; pregúntate «¿cómo puedo pagarlo?».',
      'Robert Kiyosaki',
      book: 'Padre Rico, Padre Pobre',
      today:
          'Si hoy quieres algo, busca cómo generar ese dinero extra en '
          'vez de sacarlo del sueldo.',
    ),
    Quote(
      'Págate primero a ti mismo.',
      'Robert Kiyosaki',
      book: 'Padre Rico, Padre Pobre',
      today:
          'Apenas llegue el sueldo, aparta tu ahorro antes de pagar '
          'cualquier otra cosa.',
    ),
    Quote(
      'La principal causa de la pobreza es el miedo y la ignorancia, '
          'no la economía.',
      'Robert Kiyosaki',
      book: 'Padre Rico, Padre Pobre',
      today: 'Dedica 15 minutos a aprender algo de dinero hoy.',
    ),
    Quote(
      'La educación financiera es más poderosa que el dinero.',
      'Robert Kiyosaki',
      book: 'Padre Rico, Padre Pobre',
      today: 'Lee un capítulo de un libro de finanzas o escucha un episodio.',
    ),
    Quote(
      'El que vive de un sueldo cambia su tiempo por dinero; el dueño '
          'de un sistema, no.',
      'Robert Kiyosaki',
      book: 'El cuadrante del flujo de dinero',
      today:
          'Piensa en una habilidad tuya que podrías vender sin cambiar '
          'horas por plata.',
    ),
    Quote(
      'Una parte de todo lo que ganas es tuya para conservarla.',
      'George S. Clason',
      book: 'El hombre más rico de Babilonia',
      today: 'Guarda hoy al menos el 10% de lo que te entró, aunque sea poco.',
    ),
    Quote(
      'Controla tus gastos: no confundas tus deseos con tus necesidades.',
      'George S. Clason',
      book: 'El hombre más rico de Babilonia',
      today: 'Antes de cada gasto de hoy pregúntate: ¿lo necesito o lo quiero?',
    ),
    Quote(
      'Haz que tu oro trabaje y se multiplique.',
      'George S. Clason',
      book: 'El hombre más rico de Babilonia',
      today: 'Revisa si tu ahorro está quieto o rindiendo algo.',
    ),
    Quote(
      'Protege tu tesoro de las pérdidas: no inviertas en lo que no entiendes.',
      'George S. Clason',
      book: 'El hombre más rico de Babilonia',
      today:
          'Si alguien te ofrece una inversión, pide que te la explique en '
          'una frase.',
    ),
    Quote(
      'Asegura un ingreso para el futuro.',
      'George S. Clason',
      book: 'El hombre más rico de Babilonia',
      today: 'Calcula cuántos meses aguantarías hoy sin sueldo.',
    ),
    Quote(
      'Aumenta tu habilidad para ganar.',
      'George S. Clason',
      book: 'El hombre más rico de Babilonia',
      today:
          'Anota una habilidad que subiría tu sueldo y el primer paso '
          'para aprenderla.',
    ),
    Quote(
      'Donde existe la determinación, siempre se encuentra el camino.',
      'George S. Clason',
      book: 'El hombre más rico de Babilonia',
      today: 'Escribe tu meta de dinero del año y la fecha en que la quieres.',
    ),
    Quote(
      'Todo lo que la mente puede concebir y creer, lo puede lograr.',
      'Napoleon Hill',
      book: 'Piense y hágase rico',
      today: 'Escribe cuánto quieres tener, para cuándo y qué darás a cambio.',
    ),
    Quote(
      'El deseo es el punto de partida de todo logro.',
      'Napoleon Hill',
      book: 'Piense y hágase rico',
      today: 'Lee tu meta en voz alta al levantarte y antes de dormir.',
    ),
    Quote(
      'La persistencia es al carácter lo que el carbono es al acero.',
      'Napoleon Hill',
      book: 'Piense y hágase rico',
      today:
          'Registra hoy todos tus gastos, aunque sea aburrido: así se '
          'construye.',
    ),
    Quote(
      'Los que triunfan deciden rápido y cambian de opinión despacio.',
      'Napoleon Hill',
      book: 'Piense y hágase rico',
      today: 'Toma hoy esa decisión de dinero que vienes aplazando.',
    ),
    Quote(
      'La riqueza es lo que no ves: los carros, los relojes y los '
          'lujos que decidiste no comprar.',
      'Morgan Housel',
      book: 'La psicología del dinero',
      today: 'Deja pasar hoy una compra que era solo para impresionar.',
    ),
    Quote(
      'Tu ahorro es la brecha entre tu ego y tus ingresos.',
      'Morgan Housel',
      book: 'La psicología del dinero',
      today: 'Fíjate hoy si algún gasto es para que otros te vean.',
    ),
    Quote(
      'Gastar dinero para mostrar cuánto tienes es la forma más '
          'rápida de tener menos.',
      'Morgan Housel',
      book: 'La psicología del dinero',
      today: 'Compara lo que gastas en imagen con lo que ahorras.',
    ),
    Quote(
      'La mayor forma de riqueza es poder levantarte y decir: hoy '
          'hago lo que quiero.',
      'Morgan Housel',
      book: 'La psicología del dinero',
      today: 'Calcula cuántos meses de libertad te da tu ahorro actual.',
    ),
    Quote(
      'No ahorres lo que te queda después de gastar; gasta lo que te '
          'queda después de ahorrar.',
      'Warren Buffett',
      today: 'Programa tu ahorro para el día del sueldo.',
    ),
    Quote(
      'Regla número 1: nunca pierdas dinero. Regla número 2: nunca '
          'olvides la regla número 1.',
      'Warren Buffett',
      today: 'No pongas plata en nada que no puedas explicar.',
    ),
    Quote(
      'El precio es lo que pagas; el valor es lo que recibes.',
      'Warren Buffett',
      today:
          'Antes de comprar algo caro, piensa cuántas horas de trabajo te '
          'cuesta.',
    ),
    Quote(
      'Si compras cosas que no necesitas, pronto venderás cosas que necesitas.',
      'Warren Buffett',
      today: 'Revisa tus suscripciones y cancela una que no uses.',
    ),
    Quote(
      'Sé temeroso cuando otros son codiciosos, y codicioso cuando '
          'otros son temerosos.',
      'Warren Buffett',
      today:
          'No tomes decisiones de inversión por lo que todos están comprando.',
    ),
    Quote(
      'El riesgo viene de no saber lo que estás haciendo.',
      'Warren Buffett',
      today: 'Aprende hoy qué es un fondo indexado.',
    ),
    Quote(
      'El gran dinero no está en comprar o vender, sino en esperar.',
      'Charlie Munger',
      today: 'No muevas tu inversión por una noticia de hoy.',
    ),
    Quote(
      'La primera regla del interés compuesto: nunca lo interrumpas '
          'sin necesidad.',
      'Charlie Munger',
      today: 'No saques tu ahorro de largo plazo para un gusto.',
    ),
    Quote(
      'Cuidado con los pequeños gastos: una pequeña fuga hunde un gran barco.',
      'Benjamin Franklin',
      today: 'Suma hoy tus gastos pequeños: tintos, domicilios, antojos.',
    ),
    Quote(
      'Una inversión en conocimiento paga el mejor interés.',
      'Benjamin Franklin',
      today: 'Invierte hoy una hora en aprender algo que te haga ganar más.',
    ),
    Quote(
      'No busques la aguja en el pajar: compra el pajar.',
      'John C. Bogle',
      book: 'El pequeño libro para invertir con sentido común',
      today: 'Si inviertes, prefiere fondos amplios y de bajo costo.',
    ),
    Quote(
      'En inversión, obtienes aquello por lo que no pagas: los costos '
          'importan.',
      'John C. Bogle',
      book: 'El pequeño libro para invertir con sentido común',
      today: 'Revisa cuánto te cobran de comisión tu banco y tus fondos.',
    ),
    Quote(
      'En el corto plazo el mercado es una máquina de votar; en el '
          'largo plazo, una balanza.',
      'Benjamin Graham',
      book: 'El inversor inteligente',
      today: 'Mira tu inversión en años, no en días.',
    ),
    Quote(
      'El principal problema del inversionista, e incluso su peor '
          'enemigo, suele ser él mismo.',
      'Benjamin Graham',
      book: 'El inversor inteligente',
      today: 'Escribe tu regla para no vender por pánico.',
    ),
    Quote(
      'Si tus ingresos internos no crecen, tus ingresos externos tampoco.',
      'T. Harv Eker',
      book: 'Los secretos de la mente millonaria',
      today: 'Anota una creencia sobre el dinero que te frena.',
    ),
    Quote(
      'Los ricos administran bien su dinero; los pobres administran '
          'mal el suyo.',
      'T. Harv Eker',
      book: 'Los secretos de la mente millonaria',
      today: 'Registra cada gasto de hoy en la app.',
    ),
    Quote(
      'Compramos cosas que no necesitamos, con dinero que no tenemos, '
          'para impresionar a gente que no nos cae bien.',
      'Dave Ramsey',
      book: 'La transformación total de su dinero',
      today:
          'Antes de pagar con tarjeta, pregúntate si lo comprarías de contado.',
    ),
    Quote(
      'Si vives como nadie vive hoy, después podrás vivir como nadie vive.',
      'Dave Ramsey',
      book: 'La transformación total de su dinero',
      today: 'Recorta un gasto este mes y mándalo a tu deuda más cara.',
    ),
    Quote(
      'Ponle a cada peso un trabajo antes de que empiece el mes.',
      'Dave Ramsey',
      book: 'La transformación total de su dinero',
      today: 'Revisa tu presupuesto del ciclo y asigna lo que queda libre.',
    ),
    Quote(
      'La mayoría de los millonarios viven por debajo de sus posibilidades.',
      'Thomas J. Stanley',
      book: 'El millonario de al lado',
      today: 'Elige una cosa barata que te dé el mismo gusto que una cara.',
    ),
    Quote(
      'El dinero es algo por lo que cambias tu energía vital.',
      'Vicki Robin',
      book: 'La bolsa o la vida',
      today: 'Divide tu próximo gasto grande entre lo que ganas por hora.',
    ),
    Quote(
      'Gasta sin culpa en lo que amas y recorta sin piedad en lo que no.',
      'Ramit Sethi',
      book: 'Te enseñaré a ser rico',
      today: 'Escoge tus dos gastos favoritos y recorta uno que no te importe.',
    ),
    Quote(
      'Los hábitos son el interés compuesto de la superación personal.',
      'James Clear',
      book: 'Hábitos atómicos',
      today: 'Anota un gasto apenas lo hagas: un hábito de 5 segundos.',
    ),
    Quote(
      'No subes al nivel de tus metas; caes al nivel de tus sistemas.',
      'James Clear',
      book: 'Hábitos atómicos',
      today: 'Automatiza un ahorro, aunque sea pequeño, el día del sueldo.',
    ),
    Quote(
      'Busca riqueza, no dinero ni estatus. La riqueza son activos '
          'que ganan mientras duermes.',
      'Naval Ravikant',
      today: 'Piensa qué podrías construir una vez y cobrar muchas veces.',
    ),
    Quote(
      'No te harás rico alquilando tu tiempo. Necesitas ser dueño de '
          'una parte de un negocio.',
      'Naval Ravikant',
      today:
          'Averigua cómo comprar una pequeña parte de muchas empresas (un '
          'fondo).',
    ),
    Quote(
      'Conoce lo que posees y por qué lo posees.',
      'Peter Lynch',
      today: 'Escribe por qué tienes cada inversión que tienes.',
    ),
    Quote(
      'La educación formal te dará para vivir; la autoeducación te '
          'hará una fortuna.',
      'Jim Rohn',
      today: 'Cambia hoy 20 minutos de redes por lectura.',
    ),
    Quote(
      'La riqueza no consiste en tener grandes posesiones, sino en '
          'tener pocas necesidades.',
      'Epicteto',
      today: 'Pasa hoy un día sin compras que no sean necesarias.',
    ),
    Quote(
      'No es pobre el que tiene poco, sino el que mucho desea.',
      'Séneca',
      today: 'Agradece tres cosas que ya tienes antes de desear una nueva.',
    ),
    Quote(
      'Tu margen es mi oportunidad.',
      'Jeff Bezos',
      today: 'Busca un gasto fijo que puedas negociar más barato.',
    ),
    Quote(
      'El mejor momento para plantar un árbol fue hace 20 años. El '
          'segundo mejor momento es ahora.',
      'Proverbio chino',
      today: 'Empieza hoy tu ahorro, aunque sea con lo mínimo.',
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
