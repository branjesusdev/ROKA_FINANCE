import 'package:finance_app/bootstrap/use_cases.dart';
import 'package:finance_app/core/result.dart';
import 'package:finance_app/presentation/shared/form_widgets.dart';
import 'package:finance_app/presentation/shared/formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Botón aparte para empezar el mes de cero: borra los ingresos y gastos
/// anotados en el ciclo actual, sin tocar los fijos. Pide confirmación y
/// permite deshacer.
class ResetCycleTile extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final error = Theme.of(context).colorScheme.error;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.restart_alt, color: error),
      title: Text('Reiniciar mes', style: TextStyle(color: error)),
      subtitle: const Text(
        'Borra los ingresos y gastos anotados en este ciclo. Los fijos se '
        'conservan.',
      ),
      onTap: () => _reset(context, ref),
    );
  }

  Future<void> _reset(BuildContext context, WidgetRef ref) async {
    final useCase = ref.read(resetCycleMovementsProvider);
    final messenger = ScaffoldMessenger.of(context);
    final preview = await useCase.preview();
    if (!context.mounted) return;
    final data = switch (preview) {
      Ok(:final value) => value,
      Err() => null,
    };
    if (data == null) {
      showResult(context, preview);
      return;
    }
    if (data.removable.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No hay movimientos para borrar.')),
      );
      return;
    }
    final count = data.removable.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded),
        title: const Text('¿Reiniciar el mes?'),
        content: Text(
          'Se borrarán $count ${count == 1 ? 'movimiento' : 'movimientos'} '
          'del ${Formatters.shortDate(data.cycle.start)} al '
          '${Formatters.shortDate(data.cycle.lastDay)}.\n\n'
          'Se conservan los gastos e ingresos fijos, los pagos de deudas y '
          'los apartados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Reiniciar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final result = await useCase();
    switch (result) {
      case Ok(value: final removed):
        messenger.showSnackBar(
          SnackBar(
            content: const Text('Mes reiniciado'),
            action: SnackBarAction(
              label: 'Deshacer',
              onPressed: () => useCase.undo(removed),
            ),
          ),
        );
      case Err(:final failure):
        messenger.showSnackBar(
          SnackBar(content: Text(failureMessage(failure))),
        );
    }
  }
}
