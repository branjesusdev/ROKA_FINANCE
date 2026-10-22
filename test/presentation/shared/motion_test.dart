import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/presentation/shared/formatters.dart';
import 'package:finance_app/presentation/shared/motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const amount = Money.pesos(1200000);

  Widget app({required bool reduceMotion}) => MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: const MaterialApp(
      home: Scaffold(
        body: FadeSlideIn(
          index: 3,
          child: AnimatedMoneyText(amount: amount, format: Formatters.money),
        ),
      ),
    ),
  );

  testWidgets('el monto cuenta y termina en el valor real', (tester) async {
    await tester.pumpWidget(app(reduceMotion: false));
    expect(find.text(Formatters.money(amount)), findsNothing);

    await tester.pumpAndSettle();
    expect(find.text(Formatters.money(amount)), findsOneWidget);
  });

  testWidgets('sin animaciones del sistema, todo aparece al instante', (
    tester,
  ) async {
    await tester.pumpWidget(app(reduceMotion: true));

    expect(find.text(Formatters.money(amount)), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('la gráfica de una sección oculta espera y se anima al verla', (
    tester,
  ) async {
    final seen = <double>[];
    Widget section({required bool active}) => MaterialApp(
      home: RevealOnActive(
        active: active,
        child: ChartReveal(
          replayKey: 1,
          builder: (context, progress) {
            seen.add(progress);
            return const SizedBox();
          },
        ),
      ),
    );

    await tester.pumpWidget(section(active: false));
    await tester.pumpAndSettle();
    expect(seen.toSet(), {0.0});

    await tester.pumpWidget(section(active: true));
    await tester.pump(Motion.slow ~/ 2);
    expect(seen.last, inExclusiveRange(0, 1));
    await tester.pumpAndSettle();
    expect(seen.last, 1);
  });
}
