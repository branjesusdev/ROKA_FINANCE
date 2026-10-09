import 'package:drift/drift.dart';
import 'package:finance_app/domain/accounts/account.dart';
import 'package:finance_app/domain/categories/category.dart';
import 'package:finance_app/domain/debts/debt.dart';
import 'package:finance_app/domain/debts/interest_rate.dart';
import 'package:finance_app/domain/investments/investment.dart';
import 'package:finance_app/domain/savings/finance_settings.dart';
import 'package:finance_app/domain/savings/savings_goal.dart';
import 'package:finance_app/domain/transactions/transaction.dart';
import 'package:finance_app/domain/wealth/asset.dart';

// Esquema SQLite v2. Montos en centavos (INTEGER), enums como TEXT (nombre),
// porcentajes en puntos básicos. Cambios de esquema = nueva migración.
// v2: movimientos fijos, día de pago y recordatorio diario.
// v5: apartados (pagos que no son mensuales) y vínculo en movimientos.
// v6: vínculo del movimiento con el fijo que lo generó.
// v7: fijos de valor variable (facturas de servicios).
// v8: apariencia clara/oscura.

@DataClassName('CategoryRow')
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get kind => textEnum<CategoryKind>()();
  TextColumn get iconKey => text()();
  IntColumn get sortOrder => integer()();
  BoolColumn get isArchived => boolean()();
  BoolColumn get countsAsSaving => boolean()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('AccountRow')
class Accounts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => textEnum<AccountType>()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('TransactionRow')
@TableIndex(name: 'transactions_date_idx', columns: {#date})
class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get kind => textEnum<TransactionKind>()();
  IntColumn get amountCents => integer()();
  TextColumn get categoryId => text().references(Categories, #id)();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get description => text().nullable()();
  TextColumn get accountId => text().nullable().references(
    Accounts,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get nature => textEnum<ExpenseNature>().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get debtId =>
      text().nullable().references(Debts, #id, onDelete: KeyAction.setNull)();
  // Sin FK: SQLite no deja agregar columnas con referencias en una
  // migración. Al borrar un apartado, el repositorio limpia el vínculo.
  TextColumn get provisionId => text().nullable()();
  // Fijo que lo generó. Sin FK por la misma razón.
  TextColumn get fixedMovementId => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('BudgetLineRow')
class BudgetLines extends Table {
  TextColumn get id => text()();
  IntColumn get year => integer()();
  IntColumn get month => integer()();
  TextColumn get categoryId => text().references(Categories, #id)();
  IntColumn get limitCents => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {year, month, categoryId},
  ];
}

@DataClassName('AssetRow')
class Assets extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => textEnum<AssetType>()();
  IntColumn get currentValueCents => integer()();
  DateTimeColumn get valuedAt => dateTime()();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Las columnas de condiciones del crédito son nulas si el pasivo no tiene
/// `LoanTerms`.
@DataClassName('DebtRow')
class Debts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => textEnum<DebtType>()();
  IntColumn get originalAmountCents => integer()();
  IntColumn get currentBalanceCents => integer()();
  TextColumn get notes => text().nullable()();
  IntColumn get rateBasisPoints => integer().nullable()();
  TextColumn get rateType => textEnum<InterestRateType>().nullable()();
  IntColumn get monthlyPaymentCents => integer().nullable()();
  IntColumn get monthlyFeesCents => integer().nullable()();
  IntColumn get totalInstallments => integer().nullable()();
  IntColumn get paidInstallments => integer().nullable()();
  DateTimeColumn get startDate => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ExtraPaymentRow')
class ExtraPayments extends Table {
  TextColumn get id => text()();
  TextColumn get debtId =>
      text().references(Debts, #id, onDelete: KeyAction.cascade)();
  IntColumn get amountCents => integer()();
  DateTimeColumn get date => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('SavingsGoalRow')
class SavingsGoals extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => textEnum<GoalType>()();
  IntColumn get targetAmountCents => integer()();
  DateTimeColumn get targetDate => dateTime().nullable()();
  IntColumn get desiredMonthlyCents => integer().nullable()();
  IntColumn get essentialMonthlyCents => integer().nullable()();
  IntColumn get emergencyTargetMonths => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('GoalContributionRow')
class GoalContributions extends Table {
  TextColumn get id => text()();
  TextColumn get goalId =>
      text().references(SavingsGoals, #id, onDelete: KeyAction.cascade)();
  IntColumn get amountCents => integer()();
  DateTimeColumn get date => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('InvestmentRow')
class Investments extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => textEnum<InvestmentType>()();
  IntColumn get investedCents => integer()();
  IntColumn get currentValueCents => integer()();
  DateTimeColumn get date => dateTime()();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Fila única (`id` = [singletonId]).
@DataClassName('SettingsRow')
class FinanceSettingsTable extends Table {
  static const singletonId = 1;

  @override
  String get tableName => 'finance_settings';

  IntColumn get id => integer()();
  IntColumn get savingsTargetBasisPoints => integer()();
  IntColumn get warningFromBasisPoints => integer()();
  IntColumn get criticalAboveBasisPoints => integer()();
  IntColumn get smallExpenseThresholdCents => integer()();
  IntColumn get payday =>
      integer().withDefault(const Constant(FinanceSettings.defaultPayday))();
  BoolColumn get dailyReminder => boolean().withDefault(const Constant(true))();
  IntColumn get reminderHour => integer().withDefault(
    const Constant(FinanceSettings.defaultReminderHour),
  )();
  IntColumn get reminderMinute => integer().withDefault(const Constant(0))();
  BoolColumn get smartNotifications =>
      boolean().withDefault(const Constant(true))();
  IntColumn get dependents => integer().withDefault(const Constant(0))();
  BoolColumn get soloProvider => boolean().withDefault(const Constant(false))();
  IntColumn get kidsMonthlyBufferCents =>
      integer().withDefault(const Constant(0))();
  TextColumn get appearance =>
      textEnum<Appearance>().withDefault(Constant(Appearance.system.name))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('FixedMovementRow')
class FixedMovements extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get kind => textEnum<TransactionKind>()();
  IntColumn get amountCents => integer()();
  TextColumn get categoryId => text().references(Categories, #id)();
  IntColumn get dayOfMonth => integer()();
  BoolColumn get isActive => boolean()();
  BoolColumn get isVariable => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastPostedOn => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ProvisionRow')
class Provisions extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get amountCents => integer()();
  IntColumn get everyMonths => integer()();
  DateTimeColumn get nextDue => dateTime()();
  TextColumn get categoryId => text().references(Categories, #id)();
  BoolColumn get isActive => boolean()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
