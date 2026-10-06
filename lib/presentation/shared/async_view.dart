import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Muestra carga / error / datos de un `AsyncValue`. Al recalcular conserva
/// los datos anteriores para evitar parpadeos.
class AsyncView<T> extends StatelessWidget {
  const new({required this.value, required this.builder, super.key});

  final AsyncValue<T> value;
  final Widget Function(T data) builder;

  @override
  Widget build(BuildContext context) {
    return switch (value) {
      AsyncValue(:final value?) => builder(value),
      AsyncError() => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No se pudieron cargar tus datos. Cierra y vuelve a abrir la app.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}
