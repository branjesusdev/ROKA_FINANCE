import 'package:finance_app/bootstrap/use_cases.dart';
import 'package:finance_app/core/result.dart';
import 'package:finance_app/presentation/shared/form_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Exportar e importar todo en un archivo (para cambiar de teléfono o
/// guardar un respaldo). El archivo queda donde el usuario elija.
class BackupSection extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<BackupSection> createState() => _BackupSectionState();
}

class _BackupSectionState extends ConsumerState<BackupSection> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.upload_file),
          title: const Text('Exportar copia'),
          subtitle: const Text(
            'Todo en un archivo: gastos e ingresos de todos los meses, fijos, '
            'deudas, metas, apartados, patrimonio y ajustes.',
          ),
          enabled: !_busy,
          onTap: _export,
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.download),
          title: const Text('Importar copia'),
          subtitle: const Text(
            'Agrega lo que no tengas. Lo que ya existe no se duplica.',
          ),
          trailing: _busy
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
          enabled: !_busy,
          onTap: _import,
        ),
      ],
    );
  }

  Future<void> _export() async {
    setState(() => _busy = true);
    final result = await ref.read(exportBackupProvider).call();
    if (!mounted) return;
    setState(() => _busy = false);
    if (result case Ok(value: false)) return;
    showResult(
      context,
      result,
      success: 'Copia guardada. Guárdala en un lugar seguro: tiene tus datos.',
    );
  }

  Future<void> _import() async {
    setState(() => _busy = true);
    final result = await ref.read(importBackupProvider).call();
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case Ok(value: null):
        return;
      case Ok(value: final report?):
        final movements = report.movementsAdded;
        final movementsLabel = movements == 1 ? 'movimiento' : 'movimientos';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              report.added == 0
                  ? 'Ya tenías todo: no se agregó nada.'
                  : 'Listo: ${report.added} registros agregados '
                        '($movements $movementsLabel). '
                        '${report.skipped} ya existían.',
            ),
          ),
        );
      case Err():
        showResult(context, result);
    }
  }
}
