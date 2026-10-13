import 'dart:async';

import 'package:finance_app/application/advisor/ai_ports.dart';
import 'package:finance_app/application/reminders/reminder_scheduler.dart';
import 'package:finance_app/application/voice/speech_input.dart';
import 'package:finance_app/core/storage_exception.dart';
import 'package:finance_app/domain/advisor/ai_review.dart';
import 'package:finance_app/domain/savings/finance_settings.dart';
import 'package:finance_app/domain/savings/settings_repository.dart';
import 'package:finance_app/domain/shared/clock.dart';
import 'package:finance_app/domain/shared/date_range.dart';
import 'package:finance_app/domain/shared/id_generator.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:finance_app/domain/transactions/transaction_repository.dart';

final class FixedClock implements Clock {
  new(this.value);

  DateTime value;

  @override
  DateTime now() => value;
}

final class SequentialIds implements IdGenerator {
  int _next = 1;

  @override
  String next() => 'id-${_next++}';
}

/// Repositorio en memoria. Con [failing] simula un fallo de almacenamiento.
final class FakeTransactionRepository implements TransactionRepository {
  final saved = <String, Transaction>{};
  bool failing = false;

  @override
  Future<void> save(Transaction transaction) async {
    if (failing) throw const StorageException('fake.save');
    saved[transaction.id] = transaction;
  }

  @override
  Future<void> delete(String id) async => saved.remove(id);

  @override
  Future<void> deleteAll(Iterable<String> ids) async {
    if (failing) throw const StorageException('fake.deleteAll');
    ids.forEach(saved.remove);
  }

  @override
  Future<Transaction?> getById(String id) async => saved[id];

  @override
  Future<List<Transaction>> getByPeriod(DateRange period) async =>
      saved.values.where((t) => period.contains(t.date)).toList();

  @override
  Stream<List<Transaction>> watchByPeriod(DateRange period) =>
      Stream.fromFuture(getByPeriod(period));

  @override
  Future<List<Transaction>> getRecent({required int limit}) async =>
      saved.values.take(limit).toList();

  @override
  Stream<List<Transaction>> watchRecent({required int limit}) =>
      Stream.fromFuture(getRecent(limit: limit));

  @override
  Future<List<Transaction>> getLinkedToProvision(String provisionId) async =>
      saved.values.where((t) => t.provisionId == provisionId).toList();

  @override
  Future<List<Transaction>> getLinkedToFixed(
    String fixedMovementId, {
    required int limit,
  }) async =>
      (saved.values.where((t) => t.fixedMovementId == fixedMovementId).toList()
            ..sort((a, b) => b.date.compareTo(a.date)))
          .take(limit)
          .toList();

  @override
  Stream<List<Transaction>> watchLinkedToProvisions() =>
      Stream.value(saved.values.where((t) => t.provisionId != null).toList());
}

/// Avisos sin plataforma: registra lo programado.
final class FakeReminderScheduler implements ReminderScheduler {
  List<Reminder> scheduled = [];
  final shown = <Reminder>[];
  bool granted = true;

  /// Hora del recordatorio diario programado (id 1), si hay.
  int? get scheduledHour =>
      scheduled.where((r) => r.id == 1).firstOrNull?.at.hour;

  @override
  Future<bool> requestPermission() async => granted;

  @override
  Future<void> replaceAll(List<Reminder> reminders) async =>
      scheduled = [...reminders];

  @override
  Future<void> add(Reminder reminder) async => scheduled.add(reminder);

  @override
  Future<void> showNow(Reminder reminder) async => shown.add(reminder);

  @override
  Future<ReminderDiagnostics> diagnostics() async => ReminderDiagnostics(
    notificationsEnabled: granted,
    exactAlarms: true,
    pending: scheduled.length,
  );
}

/// Dictado simulado: emite [phrase] como resultado final.
final class FakeSpeechInput implements SpeechInput {
  new([this.phrase = '']);

  String phrase;

  @override
  bool usesInternet = false;

  @override
  Stream<SpeechChunk> listen({bool? online}) {
    if (online != null) usesInternet = online;
    return Stream.value(SpeechChunk(text: phrase, isFinal: true));
  }

  @override
  Future<void> stop() async {}

  @override
  Future<String?> listenWithSystemDialog() async => phrase;

  @override
  Future<String> diagnostics() async => '';
}

/// IA falsa: devuelve [response] o lanza [error]. Guarda lo que recibió.
final class FakeAiAdvisor implements AiAdvisor {
  String response = '{}';
  AiAdvisorException? error;
  final prompts = <String>[];

  @override
  Future<String> complete({
    required String apiKey,
    required String system,
    required String prompt,
    bool json = false,
  }) async {
    prompts.add(prompt);
    if (error case final error?) throw error;
    return response;
  }
}

final class FakeAiKeyStore implements AiKeyStore {
  new([this.key]);

  String? key;

  @override
  Future<String?> read() async => key;

  @override
  Future<void> save(String? key) async => this.key = key;

  @override
  Stream<bool> watchHasKey() => Stream.value(key != null);
}

final class FakeAiReviewRepository implements AiReviewRepository {
  final saved = <AiReview>[];

  @override
  Future<AiReview?> latest() async => saved.lastOrNull;

  @override
  Future<void> save(AiReview review) async => saved.add(review);

  @override
  Stream<AiReview?> watchLatest() => Stream.value(saved.lastOrNull);
}

final class FakeSettingsRepository implements SettingsRepository {
  new([this.value = const FinanceSettings()]);

  FinanceSettings value;

  @override
  Future<FinanceSettings> get() async => value;

  @override
  Future<void> save(FinanceSettings settings) async => value = settings;

  @override
  Stream<FinanceSettings> watch() => Stream.value(value);
}
