import 'package:finance_app/application/common/validation.dart';
import 'package:finance_app/core/failure.dart';
import 'package:finance_app/core/result.dart';
import 'package:finance_app/domain/shared/money.dart';
import 'package:finance_app/domain/shared/percentage.dart';
import 'package:finance_app/presentation/shared/formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Abre un formulario en hoja inferior que se ajusta al teclado.
Future<T?> showFormSheet<T>(BuildContext context, Widget child) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => child,
    );

/// Estructura común de los formularios: título, campos y botón principal.
class FormSheet extends StatelessWidget {
  const new({
    required this.title,
    required this.children,
    required this.onSave,
    this.saveLabel = 'Guardar',
    this.extraActions = const [],
    super.key,
  });

  final String title;
  final List<Widget> children;

  /// `null` deshabilita el botón.
  final VoidCallback? onSave;
  final String saveLabel;
  final List<Widget> extraActions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            for (final child in children) ...[
              child,
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 4),
            FilledButton(
              onPressed: onSave,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: Text(saveLabel),
            ),
            ...extraActions,
          ],
        ),
      ),
    );
  }
}

class MoneyField extends StatelessWidget {
  const new({
    required this.controller,
    required this.label,
    this.helperText,
    this.autofocus = false,
    this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final String? helperText;
  final bool autofocus;
  final ValueChanged<String>? onChanged;

  /// Monto escrito, o `null` si el campo está vacío.
  static Money? read(TextEditingController controller) {
    final pesos = PesosInputFormatter.parse(controller.text);
    return pesos == null ? null : Money.pesos(pesos);
  }

  static String initial(Money? money) =>
      money == null ? '' : Formatters.pesos(money.cents ~/ Money.centsPerPeso);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: TextInputType.number,
      inputFormatters: [PesosInputFormatter()],
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        prefixText: r'$ ',
        border: const OutlineInputBorder(),
      ),
    );
  }
}

/// Campo de porcentaje con decimales ("18,5").
class PercentField extends StatelessWidget {
  const new({
    required this.controller,
    required this.label,
    this.helperText,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final String? helperText;

  static Percentage? read(TextEditingController controller) {
    final value = double.tryParse(controller.text.trim().replaceAll(',', '.'));
    return value == null ? null : Percentage.fromFraction(value / 100);
  }

  static String initial(Percentage? percentage) => percentage == null
      ? ''
      : percentage.value
            .toString()
            .replaceAll('.', ',')
            .replaceAll(RegExp(r',0$'), '');

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9.,]'))],
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        suffixText: '%',
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class IntegerField extends StatelessWidget {
  const new({required this.controller, required this.label, super.key});

  final TextEditingController controller;
  final String label;

  static int? read(TextEditingController controller) =>
      int.tryParse(controller.text.trim());

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

/// Selector de fecha opcional en forma de fila.
class DateTile extends StatelessWidget {
  const new({
    required this.label,
    required this.value,
    required this.onChanged,
    this.firstDate,
    this.lastDate,
    super.key,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.event),
      title: Text(label),
      subtitle: Text(value == null ? 'Sin fecha' : Formatters.longDate(value!)),
      trailing: value == null
          ? null
          : IconButton(
              tooltip: 'Quitar fecha',
              icon: const Icon(Icons.clear),
              onPressed: () => onChanged(null),
            ),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? now,
          firstDate: firstDate ?? DateTime(now.year - 30),
          lastDate: lastDate ?? DateTime(now.year + 30),
        );
        if (picked != null) onChanged(picked);
      },
    );
  }
}

/// Muestra el resultado de un caso de uso. Devuelve `true` si fue exitoso.
bool showResult(
  BuildContext context,
  Result<Object?> result, {
  String? success,
}) {
  final messenger = ScaffoldMessenger.of(context);
  switch (result) {
    case Ok():
      if (success != null) {
        messenger.showSnackBar(SnackBar(content: Text(success)));
      }
      return true;
    case Err(:final failure):
      messenger.showSnackBar(SnackBar(content: Text(failureMessage(failure))));
      return false;
  }
}

String failureMessage(Failure failure) => switch (failure) {
  ValidationFailure(:final message) => switch (message) {
    ValidationCodes.nameRequired => 'Escribe un nombre.',
    ValidationCodes.amountMustBePositive => 'El valor debe ser mayor que cero.',
    ValidationCodes.amountMustNotBeNegative =>
      'El valor no puede ser negativo.',
    ValidationCodes.amountMustNotBeZero => 'Escribe un valor.',
    ValidationCodes.rateOutOfRange => 'El porcentaje debe estar entre 1 y 100.',
    ValidationCodes.monthsMustBePositive => 'Elige al menos 1 mes.',
    ValidationCodes.dayOutOfRange => 'Elige un día entre 1 y 31.',
    ValidationCodes.hourOutOfRange => 'Elige una hora válida.',
    ValidationCodes.categoryExists => 'Ya tienes una categoría con ese nombre.',
    ValidationCodes.backupInvalid =>
      'Ese archivo no es una copia de la app o está dañado.',
    ValidationCodes.backupFromNewerVersion =>
      'La copia es de una versión más nueva. Actualiza la app.',
    _ => 'Revisa los datos.',
  },
  NotFoundFailure() => 'No se encontró el registro.',
  StorageFailure() => 'No se pudo guardar. Intenta de nuevo.',
};

/// Confirmación simple antes de eliminar.
Future<bool> confirmDelete(BuildContext context, String what) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('¿Eliminar $what?'),
      content: const Text('Esta acción no se puede deshacer.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Eliminar'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
