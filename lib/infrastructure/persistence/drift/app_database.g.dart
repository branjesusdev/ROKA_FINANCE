// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, CategoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<CategoryKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<CategoryKind>($CategoriesTable.$converterkind);
  static const VerificationMeta _iconKeyMeta = const VerificationMeta(
    'iconKey',
  );
  @override
  late final GeneratedColumn<String> iconKey = GeneratedColumn<String>(
    'icon_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
    ),
  );
  static const VerificationMeta _countsAsSavingMeta = const VerificationMeta(
    'countsAsSaving',
  );
  @override
  late final GeneratedColumn<bool> countsAsSaving = GeneratedColumn<bool>(
    'counts_as_saving',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("counts_as_saving" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    kind,
    iconKey,
    sortOrder,
    isArchived,
    countsAsSaving,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<CategoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('icon_key')) {
      context.handle(
        _iconKeyMeta,
        iconKey.isAcceptableOrUnknown(data['icon_key']!, _iconKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_iconKeyMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    } else if (isInserting) {
      context.missing(_isArchivedMeta);
    }
    if (data.containsKey('counts_as_saving')) {
      context.handle(
        _countsAsSavingMeta,
        countsAsSaving.isAcceptableOrUnknown(
          data['counts_as_saving']!,
          _countsAsSavingMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_countsAsSavingMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CategoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      kind: $CategoriesTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      iconKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_key'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
      countsAsSaving: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}counts_as_saving'],
      )!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<CategoryKind, String, String> $converterkind =
      const EnumNameConverter<CategoryKind>(CategoryKind.values);
}

class CategoryRow extends DataClass implements Insertable<CategoryRow> {
  final String id;
  final String name;
  final CategoryKind kind;
  final String iconKey;
  final int sortOrder;
  final bool isArchived;
  final bool countsAsSaving;
  const CategoryRow({
    required this.id,
    required this.name,
    required this.kind,
    required this.iconKey,
    required this.sortOrder,
    required this.isArchived,
    required this.countsAsSaving,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    {
      map['kind'] = Variable<String>(
        $CategoriesTable.$converterkind.toSql(kind),
      );
    }
    map['icon_key'] = Variable<String>(iconKey);
    map['sort_order'] = Variable<int>(sortOrder);
    map['is_archived'] = Variable<bool>(isArchived);
    map['counts_as_saving'] = Variable<bool>(countsAsSaving);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      name: Value(name),
      kind: Value(kind),
      iconKey: Value(iconKey),
      sortOrder: Value(sortOrder),
      isArchived: Value(isArchived),
      countsAsSaving: Value(countsAsSaving),
    );
  }

  factory CategoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      kind: $CategoriesTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      iconKey: serializer.fromJson<String>(json['iconKey']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      countsAsSaving: serializer.fromJson<bool>(json['countsAsSaving']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'kind': serializer.toJson<String>(
        $CategoriesTable.$converterkind.toJson(kind),
      ),
      'iconKey': serializer.toJson<String>(iconKey),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'isArchived': serializer.toJson<bool>(isArchived),
      'countsAsSaving': serializer.toJson<bool>(countsAsSaving),
    };
  }

  CategoryRow copyWith({
    String? id,
    String? name,
    CategoryKind? kind,
    String? iconKey,
    int? sortOrder,
    bool? isArchived,
    bool? countsAsSaving,
  }) => CategoryRow(
    id: id ?? this.id,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    iconKey: iconKey ?? this.iconKey,
    sortOrder: sortOrder ?? this.sortOrder,
    isArchived: isArchived ?? this.isArchived,
    countsAsSaving: countsAsSaving ?? this.countsAsSaving,
  );
  CategoryRow copyWithCompanion(CategoriesCompanion data) {
    return CategoryRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      kind: data.kind.present ? data.kind.value : this.kind,
      iconKey: data.iconKey.present ? data.iconKey.value : this.iconKey,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      countsAsSaving: data.countsAsSaving.present
          ? data.countsAsSaving.value
          : this.countsAsSaving,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('iconKey: $iconKey, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isArchived: $isArchived, ')
          ..write('countsAsSaving: $countsAsSaving')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    kind,
    iconKey,
    sortOrder,
    isArchived,
    countsAsSaving,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.kind == this.kind &&
          other.iconKey == this.iconKey &&
          other.sortOrder == this.sortOrder &&
          other.isArchived == this.isArchived &&
          other.countsAsSaving == this.countsAsSaving);
}

class CategoriesCompanion extends UpdateCompanion<CategoryRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<CategoryKind> kind;
  final Value<String> iconKey;
  final Value<int> sortOrder;
  final Value<bool> isArchived;
  final Value<bool> countsAsSaving;
  final Value<int> rowid;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.iconKey = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.countsAsSaving = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCompanion.insert({
    required String id,
    required String name,
    required CategoryKind kind,
    required String iconKey,
    required int sortOrder,
    required bool isArchived,
    required bool countsAsSaving,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       kind = Value(kind),
       iconKey = Value(iconKey),
       sortOrder = Value(sortOrder),
       isArchived = Value(isArchived),
       countsAsSaving = Value(countsAsSaving);
  static Insertable<CategoryRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? kind,
    Expression<String>? iconKey,
    Expression<int>? sortOrder,
    Expression<bool>? isArchived,
    Expression<bool>? countsAsSaving,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (kind != null) 'kind': kind,
      if (iconKey != null) 'icon_key': iconKey,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (isArchived != null) 'is_archived': isArchived,
      if (countsAsSaving != null) 'counts_as_saving': countsAsSaving,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<CategoryKind>? kind,
    Value<String>? iconKey,
    Value<int>? sortOrder,
    Value<bool>? isArchived,
    Value<bool>? countsAsSaving,
    Value<int>? rowid,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      iconKey: iconKey ?? this.iconKey,
      sortOrder: sortOrder ?? this.sortOrder,
      isArchived: isArchived ?? this.isArchived,
      countsAsSaving: countsAsSaving ?? this.countsAsSaving,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $CategoriesTable.$converterkind.toSql(kind.value),
      );
    }
    if (iconKey.present) {
      map['icon_key'] = Variable<String>(iconKey.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (countsAsSaving.present) {
      map['counts_as_saving'] = Variable<bool>(countsAsSaving.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('iconKey: $iconKey, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isArchived: $isArchived, ')
          ..write('countsAsSaving: $countsAsSaving, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AccountsTable extends Accounts
    with TableInfo<$AccountsTable, AccountRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<AccountType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<AccountType>($AccountsTable.$convertertype);
  @override
  List<GeneratedColumn> get $columns => [id, name, type];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<AccountRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AccountRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AccountRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: $AccountsTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
    );
  }

  @override
  $AccountsTable createAlias(String alias) {
    return $AccountsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AccountType, String, String> $convertertype =
      const EnumNameConverter<AccountType>(AccountType.values);
}

class AccountRow extends DataClass implements Insertable<AccountRow> {
  final String id;
  final String name;
  final AccountType type;
  const AccountRow({required this.id, required this.name, required this.type});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    {
      map['type'] = Variable<String>($AccountsTable.$convertertype.toSql(type));
    }
    return map;
  }

  AccountsCompanion toCompanion(bool nullToAbsent) {
    return AccountsCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
    );
  }

  factory AccountRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AccountRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      type: $AccountsTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(
        $AccountsTable.$convertertype.toJson(type),
      ),
    };
  }

  AccountRow copyWith({String? id, String? name, AccountType? type}) =>
      AccountRow(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
      );
  AccountRow copyWithCompanion(AccountsCompanion data) {
    return AccountRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AccountRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, type);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AccountRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type);
}

class AccountsCompanion extends UpdateCompanion<AccountRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<AccountType> type;
  final Value<int> rowid;
  const AccountsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccountsCompanion.insert({
    required String id,
    required String name,
    required AccountType type,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       type = Value(type);
  static Insertable<AccountRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccountsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<AccountType>? type,
    Value<int>? rowid,
  }) {
    return AccountsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $AccountsTable.$convertertype.toSql(type.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DebtsTable extends Debts with TableInfo<$DebtsTable, DebtRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DebtsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DebtType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DebtType>($DebtsTable.$convertertype);
  static const VerificationMeta _originalAmountCentsMeta =
      const VerificationMeta('originalAmountCents');
  @override
  late final GeneratedColumn<int> originalAmountCents = GeneratedColumn<int>(
    'original_amount_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currentBalanceCentsMeta =
      const VerificationMeta('currentBalanceCents');
  @override
  late final GeneratedColumn<int> currentBalanceCents = GeneratedColumn<int>(
    'current_balance_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rateBasisPointsMeta = const VerificationMeta(
    'rateBasisPoints',
  );
  @override
  late final GeneratedColumn<int> rateBasisPoints = GeneratedColumn<int>(
    'rate_basis_points',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<InterestRateType?, String>
  rateType = GeneratedColumn<String>(
    'rate_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<InterestRateType?>($DebtsTable.$converterrateTypen);
  static const VerificationMeta _monthlyPaymentCentsMeta =
      const VerificationMeta('monthlyPaymentCents');
  @override
  late final GeneratedColumn<int> monthlyPaymentCents = GeneratedColumn<int>(
    'monthly_payment_cents',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _monthlyFeesCentsMeta = const VerificationMeta(
    'monthlyFeesCents',
  );
  @override
  late final GeneratedColumn<int> monthlyFeesCents = GeneratedColumn<int>(
    'monthly_fees_cents',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalInstallmentsMeta = const VerificationMeta(
    'totalInstallments',
  );
  @override
  late final GeneratedColumn<int> totalInstallments = GeneratedColumn<int>(
    'total_installments',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _paidInstallmentsMeta = const VerificationMeta(
    'paidInstallments',
  );
  @override
  late final GeneratedColumn<int> paidInstallments = GeneratedColumn<int>(
    'paid_installments',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
    'start_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    type,
    originalAmountCents,
    currentBalanceCents,
    notes,
    rateBasisPoints,
    rateType,
    monthlyPaymentCents,
    monthlyFeesCents,
    totalInstallments,
    paidInstallments,
    startDate,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'debts';
  @override
  VerificationContext validateIntegrity(
    Insertable<DebtRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('original_amount_cents')) {
      context.handle(
        _originalAmountCentsMeta,
        originalAmountCents.isAcceptableOrUnknown(
          data['original_amount_cents']!,
          _originalAmountCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalAmountCentsMeta);
    }
    if (data.containsKey('current_balance_cents')) {
      context.handle(
        _currentBalanceCentsMeta,
        currentBalanceCents.isAcceptableOrUnknown(
          data['current_balance_cents']!,
          _currentBalanceCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currentBalanceCentsMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('rate_basis_points')) {
      context.handle(
        _rateBasisPointsMeta,
        rateBasisPoints.isAcceptableOrUnknown(
          data['rate_basis_points']!,
          _rateBasisPointsMeta,
        ),
      );
    }
    if (data.containsKey('monthly_payment_cents')) {
      context.handle(
        _monthlyPaymentCentsMeta,
        monthlyPaymentCents.isAcceptableOrUnknown(
          data['monthly_payment_cents']!,
          _monthlyPaymentCentsMeta,
        ),
      );
    }
    if (data.containsKey('monthly_fees_cents')) {
      context.handle(
        _monthlyFeesCentsMeta,
        monthlyFeesCents.isAcceptableOrUnknown(
          data['monthly_fees_cents']!,
          _monthlyFeesCentsMeta,
        ),
      );
    }
    if (data.containsKey('total_installments')) {
      context.handle(
        _totalInstallmentsMeta,
        totalInstallments.isAcceptableOrUnknown(
          data['total_installments']!,
          _totalInstallmentsMeta,
        ),
      );
    }
    if (data.containsKey('paid_installments')) {
      context.handle(
        _paidInstallmentsMeta,
        paidInstallments.isAcceptableOrUnknown(
          data['paid_installments']!,
          _paidInstallmentsMeta,
        ),
      );
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DebtRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DebtRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: $DebtsTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      originalAmountCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}original_amount_cents'],
      )!,
      currentBalanceCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_balance_cents'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      rateBasisPoints: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rate_basis_points'],
      ),
      rateType: $DebtsTable.$converterrateTypen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}rate_type'],
        ),
      ),
      monthlyPaymentCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}monthly_payment_cents'],
      ),
      monthlyFeesCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}monthly_fees_cents'],
      ),
      totalInstallments: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_installments'],
      ),
      paidInstallments: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}paid_installments'],
      ),
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_date'],
      ),
    );
  }

  @override
  $DebtsTable createAlias(String alias) {
    return $DebtsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<DebtType, String, String> $convertertype =
      const EnumNameConverter<DebtType>(DebtType.values);
  static JsonTypeConverter2<InterestRateType, String, String>
  $converterrateType = const EnumNameConverter<InterestRateType>(
    InterestRateType.values,
  );
  static JsonTypeConverter2<InterestRateType?, String?, String?>
  $converterrateTypen = JsonTypeConverter2.asNullable($converterrateType);
}

class DebtRow extends DataClass implements Insertable<DebtRow> {
  final String id;
  final String name;
  final DebtType type;
  final int originalAmountCents;
  final int currentBalanceCents;
  final String? notes;
  final int? rateBasisPoints;
  final InterestRateType? rateType;
  final int? monthlyPaymentCents;
  final int? monthlyFeesCents;
  final int? totalInstallments;
  final int? paidInstallments;
  final DateTime? startDate;
  const DebtRow({
    required this.id,
    required this.name,
    required this.type,
    required this.originalAmountCents,
    required this.currentBalanceCents,
    this.notes,
    this.rateBasisPoints,
    this.rateType,
    this.monthlyPaymentCents,
    this.monthlyFeesCents,
    this.totalInstallments,
    this.paidInstallments,
    this.startDate,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    {
      map['type'] = Variable<String>($DebtsTable.$convertertype.toSql(type));
    }
    map['original_amount_cents'] = Variable<int>(originalAmountCents);
    map['current_balance_cents'] = Variable<int>(currentBalanceCents);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || rateBasisPoints != null) {
      map['rate_basis_points'] = Variable<int>(rateBasisPoints);
    }
    if (!nullToAbsent || rateType != null) {
      map['rate_type'] = Variable<String>(
        $DebtsTable.$converterrateTypen.toSql(rateType),
      );
    }
    if (!nullToAbsent || monthlyPaymentCents != null) {
      map['monthly_payment_cents'] = Variable<int>(monthlyPaymentCents);
    }
    if (!nullToAbsent || monthlyFeesCents != null) {
      map['monthly_fees_cents'] = Variable<int>(monthlyFeesCents);
    }
    if (!nullToAbsent || totalInstallments != null) {
      map['total_installments'] = Variable<int>(totalInstallments);
    }
    if (!nullToAbsent || paidInstallments != null) {
      map['paid_installments'] = Variable<int>(paidInstallments);
    }
    if (!nullToAbsent || startDate != null) {
      map['start_date'] = Variable<DateTime>(startDate);
    }
    return map;
  }

  DebtsCompanion toCompanion(bool nullToAbsent) {
    return DebtsCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      originalAmountCents: Value(originalAmountCents),
      currentBalanceCents: Value(currentBalanceCents),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      rateBasisPoints: rateBasisPoints == null && nullToAbsent
          ? const Value.absent()
          : Value(rateBasisPoints),
      rateType: rateType == null && nullToAbsent
          ? const Value.absent()
          : Value(rateType),
      monthlyPaymentCents: monthlyPaymentCents == null && nullToAbsent
          ? const Value.absent()
          : Value(monthlyPaymentCents),
      monthlyFeesCents: monthlyFeesCents == null && nullToAbsent
          ? const Value.absent()
          : Value(monthlyFeesCents),
      totalInstallments: totalInstallments == null && nullToAbsent
          ? const Value.absent()
          : Value(totalInstallments),
      paidInstallments: paidInstallments == null && nullToAbsent
          ? const Value.absent()
          : Value(paidInstallments),
      startDate: startDate == null && nullToAbsent
          ? const Value.absent()
          : Value(startDate),
    );
  }

  factory DebtRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DebtRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      type: $DebtsTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
      originalAmountCents: serializer.fromJson<int>(
        json['originalAmountCents'],
      ),
      currentBalanceCents: serializer.fromJson<int>(
        json['currentBalanceCents'],
      ),
      notes: serializer.fromJson<String?>(json['notes']),
      rateBasisPoints: serializer.fromJson<int?>(json['rateBasisPoints']),
      rateType: $DebtsTable.$converterrateTypen.fromJson(
        serializer.fromJson<String?>(json['rateType']),
      ),
      monthlyPaymentCents: serializer.fromJson<int?>(
        json['monthlyPaymentCents'],
      ),
      monthlyFeesCents: serializer.fromJson<int?>(json['monthlyFeesCents']),
      totalInstallments: serializer.fromJson<int?>(json['totalInstallments']),
      paidInstallments: serializer.fromJson<int?>(json['paidInstallments']),
      startDate: serializer.fromJson<DateTime?>(json['startDate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(
        $DebtsTable.$convertertype.toJson(type),
      ),
      'originalAmountCents': serializer.toJson<int>(originalAmountCents),
      'currentBalanceCents': serializer.toJson<int>(currentBalanceCents),
      'notes': serializer.toJson<String?>(notes),
      'rateBasisPoints': serializer.toJson<int?>(rateBasisPoints),
      'rateType': serializer.toJson<String?>(
        $DebtsTable.$converterrateTypen.toJson(rateType),
      ),
      'monthlyPaymentCents': serializer.toJson<int?>(monthlyPaymentCents),
      'monthlyFeesCents': serializer.toJson<int?>(monthlyFeesCents),
      'totalInstallments': serializer.toJson<int?>(totalInstallments),
      'paidInstallments': serializer.toJson<int?>(paidInstallments),
      'startDate': serializer.toJson<DateTime?>(startDate),
    };
  }

  DebtRow copyWith({
    String? id,
    String? name,
    DebtType? type,
    int? originalAmountCents,
    int? currentBalanceCents,
    Value<String?> notes = const Value.absent(),
    Value<int?> rateBasisPoints = const Value.absent(),
    Value<InterestRateType?> rateType = const Value.absent(),
    Value<int?> monthlyPaymentCents = const Value.absent(),
    Value<int?> monthlyFeesCents = const Value.absent(),
    Value<int?> totalInstallments = const Value.absent(),
    Value<int?> paidInstallments = const Value.absent(),
    Value<DateTime?> startDate = const Value.absent(),
  }) => DebtRow(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    originalAmountCents: originalAmountCents ?? this.originalAmountCents,
    currentBalanceCents: currentBalanceCents ?? this.currentBalanceCents,
    notes: notes.present ? notes.value : this.notes,
    rateBasisPoints: rateBasisPoints.present
        ? rateBasisPoints.value
        : this.rateBasisPoints,
    rateType: rateType.present ? rateType.value : this.rateType,
    monthlyPaymentCents: monthlyPaymentCents.present
        ? monthlyPaymentCents.value
        : this.monthlyPaymentCents,
    monthlyFeesCents: monthlyFeesCents.present
        ? monthlyFeesCents.value
        : this.monthlyFeesCents,
    totalInstallments: totalInstallments.present
        ? totalInstallments.value
        : this.totalInstallments,
    paidInstallments: paidInstallments.present
        ? paidInstallments.value
        : this.paidInstallments,
    startDate: startDate.present ? startDate.value : this.startDate,
  );
  DebtRow copyWithCompanion(DebtsCompanion data) {
    return DebtRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      originalAmountCents: data.originalAmountCents.present
          ? data.originalAmountCents.value
          : this.originalAmountCents,
      currentBalanceCents: data.currentBalanceCents.present
          ? data.currentBalanceCents.value
          : this.currentBalanceCents,
      notes: data.notes.present ? data.notes.value : this.notes,
      rateBasisPoints: data.rateBasisPoints.present
          ? data.rateBasisPoints.value
          : this.rateBasisPoints,
      rateType: data.rateType.present ? data.rateType.value : this.rateType,
      monthlyPaymentCents: data.monthlyPaymentCents.present
          ? data.monthlyPaymentCents.value
          : this.monthlyPaymentCents,
      monthlyFeesCents: data.monthlyFeesCents.present
          ? data.monthlyFeesCents.value
          : this.monthlyFeesCents,
      totalInstallments: data.totalInstallments.present
          ? data.totalInstallments.value
          : this.totalInstallments,
      paidInstallments: data.paidInstallments.present
          ? data.paidInstallments.value
          : this.paidInstallments,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DebtRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('originalAmountCents: $originalAmountCents, ')
          ..write('currentBalanceCents: $currentBalanceCents, ')
          ..write('notes: $notes, ')
          ..write('rateBasisPoints: $rateBasisPoints, ')
          ..write('rateType: $rateType, ')
          ..write('monthlyPaymentCents: $monthlyPaymentCents, ')
          ..write('monthlyFeesCents: $monthlyFeesCents, ')
          ..write('totalInstallments: $totalInstallments, ')
          ..write('paidInstallments: $paidInstallments, ')
          ..write('startDate: $startDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    type,
    originalAmountCents,
    currentBalanceCents,
    notes,
    rateBasisPoints,
    rateType,
    monthlyPaymentCents,
    monthlyFeesCents,
    totalInstallments,
    paidInstallments,
    startDate,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DebtRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.originalAmountCents == this.originalAmountCents &&
          other.currentBalanceCents == this.currentBalanceCents &&
          other.notes == this.notes &&
          other.rateBasisPoints == this.rateBasisPoints &&
          other.rateType == this.rateType &&
          other.monthlyPaymentCents == this.monthlyPaymentCents &&
          other.monthlyFeesCents == this.monthlyFeesCents &&
          other.totalInstallments == this.totalInstallments &&
          other.paidInstallments == this.paidInstallments &&
          other.startDate == this.startDate);
}

class DebtsCompanion extends UpdateCompanion<DebtRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<DebtType> type;
  final Value<int> originalAmountCents;
  final Value<int> currentBalanceCents;
  final Value<String?> notes;
  final Value<int?> rateBasisPoints;
  final Value<InterestRateType?> rateType;
  final Value<int?> monthlyPaymentCents;
  final Value<int?> monthlyFeesCents;
  final Value<int?> totalInstallments;
  final Value<int?> paidInstallments;
  final Value<DateTime?> startDate;
  final Value<int> rowid;
  const DebtsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.originalAmountCents = const Value.absent(),
    this.currentBalanceCents = const Value.absent(),
    this.notes = const Value.absent(),
    this.rateBasisPoints = const Value.absent(),
    this.rateType = const Value.absent(),
    this.monthlyPaymentCents = const Value.absent(),
    this.monthlyFeesCents = const Value.absent(),
    this.totalInstallments = const Value.absent(),
    this.paidInstallments = const Value.absent(),
    this.startDate = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DebtsCompanion.insert({
    required String id,
    required String name,
    required DebtType type,
    required int originalAmountCents,
    required int currentBalanceCents,
    this.notes = const Value.absent(),
    this.rateBasisPoints = const Value.absent(),
    this.rateType = const Value.absent(),
    this.monthlyPaymentCents = const Value.absent(),
    this.monthlyFeesCents = const Value.absent(),
    this.totalInstallments = const Value.absent(),
    this.paidInstallments = const Value.absent(),
    this.startDate = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       type = Value(type),
       originalAmountCents = Value(originalAmountCents),
       currentBalanceCents = Value(currentBalanceCents);
  static Insertable<DebtRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<int>? originalAmountCents,
    Expression<int>? currentBalanceCents,
    Expression<String>? notes,
    Expression<int>? rateBasisPoints,
    Expression<String>? rateType,
    Expression<int>? monthlyPaymentCents,
    Expression<int>? monthlyFeesCents,
    Expression<int>? totalInstallments,
    Expression<int>? paidInstallments,
    Expression<DateTime>? startDate,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (originalAmountCents != null)
        'original_amount_cents': originalAmountCents,
      if (currentBalanceCents != null)
        'current_balance_cents': currentBalanceCents,
      if (notes != null) 'notes': notes,
      if (rateBasisPoints != null) 'rate_basis_points': rateBasisPoints,
      if (rateType != null) 'rate_type': rateType,
      if (monthlyPaymentCents != null)
        'monthly_payment_cents': monthlyPaymentCents,
      if (monthlyFeesCents != null) 'monthly_fees_cents': monthlyFeesCents,
      if (totalInstallments != null) 'total_installments': totalInstallments,
      if (paidInstallments != null) 'paid_installments': paidInstallments,
      if (startDate != null) 'start_date': startDate,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DebtsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<DebtType>? type,
    Value<int>? originalAmountCents,
    Value<int>? currentBalanceCents,
    Value<String?>? notes,
    Value<int?>? rateBasisPoints,
    Value<InterestRateType?>? rateType,
    Value<int?>? monthlyPaymentCents,
    Value<int?>? monthlyFeesCents,
    Value<int?>? totalInstallments,
    Value<int?>? paidInstallments,
    Value<DateTime?>? startDate,
    Value<int>? rowid,
  }) {
    return DebtsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      originalAmountCents: originalAmountCents ?? this.originalAmountCents,
      currentBalanceCents: currentBalanceCents ?? this.currentBalanceCents,
      notes: notes ?? this.notes,
      rateBasisPoints: rateBasisPoints ?? this.rateBasisPoints,
      rateType: rateType ?? this.rateType,
      monthlyPaymentCents: monthlyPaymentCents ?? this.monthlyPaymentCents,
      monthlyFeesCents: monthlyFeesCents ?? this.monthlyFeesCents,
      totalInstallments: totalInstallments ?? this.totalInstallments,
      paidInstallments: paidInstallments ?? this.paidInstallments,
      startDate: startDate ?? this.startDate,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $DebtsTable.$convertertype.toSql(type.value),
      );
    }
    if (originalAmountCents.present) {
      map['original_amount_cents'] = Variable<int>(originalAmountCents.value);
    }
    if (currentBalanceCents.present) {
      map['current_balance_cents'] = Variable<int>(currentBalanceCents.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rateBasisPoints.present) {
      map['rate_basis_points'] = Variable<int>(rateBasisPoints.value);
    }
    if (rateType.present) {
      map['rate_type'] = Variable<String>(
        $DebtsTable.$converterrateTypen.toSql(rateType.value),
      );
    }
    if (monthlyPaymentCents.present) {
      map['monthly_payment_cents'] = Variable<int>(monthlyPaymentCents.value);
    }
    if (monthlyFeesCents.present) {
      map['monthly_fees_cents'] = Variable<int>(monthlyFeesCents.value);
    }
    if (totalInstallments.present) {
      map['total_installments'] = Variable<int>(totalInstallments.value);
    }
    if (paidInstallments.present) {
      map['paid_installments'] = Variable<int>(paidInstallments.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DebtsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('originalAmountCents: $originalAmountCents, ')
          ..write('currentBalanceCents: $currentBalanceCents, ')
          ..write('notes: $notes, ')
          ..write('rateBasisPoints: $rateBasisPoints, ')
          ..write('rateType: $rateType, ')
          ..write('monthlyPaymentCents: $monthlyPaymentCents, ')
          ..write('monthlyFeesCents: $monthlyFeesCents, ')
          ..write('totalInstallments: $totalInstallments, ')
          ..write('paidInstallments: $paidInstallments, ')
          ..write('startDate: $startDate, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, TransactionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TransactionKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<TransactionKind>($TransactionsTable.$converterkind);
  static const VerificationMeta _amountCentsMeta = const VerificationMeta(
    'amountCents',
  );
  @override
  late final GeneratedColumn<int> amountCents = GeneratedColumn<int>(
    'amount_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id)',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (id) ON DELETE SET NULL',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<ExpenseNature?, String> nature =
      GeneratedColumn<String>(
        'nature',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<ExpenseNature?>($TransactionsTable.$converternaturen);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _debtIdMeta = const VerificationMeta('debtId');
  @override
  late final GeneratedColumn<String> debtId = GeneratedColumn<String>(
    'debt_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES debts (id) ON DELETE SET NULL',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kind,
    amountCents,
    categoryId,
    date,
    createdAt,
    description,
    accountId,
    nature,
    notes,
    debtId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransactionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('amount_cents')) {
      context.handle(
        _amountCentsMeta,
        amountCents.isAcceptableOrUnknown(
          data['amount_cents']!,
          _amountCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountCentsMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('debt_id')) {
      context.handle(
        _debtIdMeta,
        debtId.isAcceptableOrUnknown(data['debt_id']!, _debtIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransactionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      kind: $TransactionsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      amountCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_cents'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      ),
      nature: $TransactionsTable.$converternaturen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}nature'],
        ),
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      debtId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}debt_id'],
      ),
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TransactionKind, String, String> $converterkind =
      const EnumNameConverter<TransactionKind>(TransactionKind.values);
  static JsonTypeConverter2<ExpenseNature, String, String> $converternature =
      const EnumNameConverter<ExpenseNature>(ExpenseNature.values);
  static JsonTypeConverter2<ExpenseNature?, String?, String?>
  $converternaturen = JsonTypeConverter2.asNullable($converternature);
}

class TransactionRow extends DataClass implements Insertable<TransactionRow> {
  final String id;
  final TransactionKind kind;
  final int amountCents;
  final String categoryId;
  final DateTime date;
  final DateTime createdAt;
  final String? description;
  final String? accountId;
  final ExpenseNature? nature;
  final String? notes;
  final String? debtId;
  const TransactionRow({
    required this.id,
    required this.kind,
    required this.amountCents,
    required this.categoryId,
    required this.date,
    required this.createdAt,
    this.description,
    this.accountId,
    this.nature,
    this.notes,
    this.debtId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    {
      map['kind'] = Variable<String>(
        $TransactionsTable.$converterkind.toSql(kind),
      );
    }
    map['amount_cents'] = Variable<int>(amountCents);
    map['category_id'] = Variable<String>(categoryId);
    map['date'] = Variable<DateTime>(date);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || accountId != null) {
      map['account_id'] = Variable<String>(accountId);
    }
    if (!nullToAbsent || nature != null) {
      map['nature'] = Variable<String>(
        $TransactionsTable.$converternaturen.toSql(nature),
      );
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || debtId != null) {
      map['debt_id'] = Variable<String>(debtId);
    }
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      kind: Value(kind),
      amountCents: Value(amountCents),
      categoryId: Value(categoryId),
      date: Value(date),
      createdAt: Value(createdAt),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      accountId: accountId == null && nullToAbsent
          ? const Value.absent()
          : Value(accountId),
      nature: nature == null && nullToAbsent
          ? const Value.absent()
          : Value(nature),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      debtId: debtId == null && nullToAbsent
          ? const Value.absent()
          : Value(debtId),
    );
  }

  factory TransactionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionRow(
      id: serializer.fromJson<String>(json['id']),
      kind: $TransactionsTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      amountCents: serializer.fromJson<int>(json['amountCents']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      date: serializer.fromJson<DateTime>(json['date']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      description: serializer.fromJson<String?>(json['description']),
      accountId: serializer.fromJson<String?>(json['accountId']),
      nature: $TransactionsTable.$converternaturen.fromJson(
        serializer.fromJson<String?>(json['nature']),
      ),
      notes: serializer.fromJson<String?>(json['notes']),
      debtId: serializer.fromJson<String?>(json['debtId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<String>(
        $TransactionsTable.$converterkind.toJson(kind),
      ),
      'amountCents': serializer.toJson<int>(amountCents),
      'categoryId': serializer.toJson<String>(categoryId),
      'date': serializer.toJson<DateTime>(date),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'description': serializer.toJson<String?>(description),
      'accountId': serializer.toJson<String?>(accountId),
      'nature': serializer.toJson<String?>(
        $TransactionsTable.$converternaturen.toJson(nature),
      ),
      'notes': serializer.toJson<String?>(notes),
      'debtId': serializer.toJson<String?>(debtId),
    };
  }

  TransactionRow copyWith({
    String? id,
    TransactionKind? kind,
    int? amountCents,
    String? categoryId,
    DateTime? date,
    DateTime? createdAt,
    Value<String?> description = const Value.absent(),
    Value<String?> accountId = const Value.absent(),
    Value<ExpenseNature?> nature = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<String?> debtId = const Value.absent(),
  }) => TransactionRow(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    amountCents: amountCents ?? this.amountCents,
    categoryId: categoryId ?? this.categoryId,
    date: date ?? this.date,
    createdAt: createdAt ?? this.createdAt,
    description: description.present ? description.value : this.description,
    accountId: accountId.present ? accountId.value : this.accountId,
    nature: nature.present ? nature.value : this.nature,
    notes: notes.present ? notes.value : this.notes,
    debtId: debtId.present ? debtId.value : this.debtId,
  );
  TransactionRow copyWithCompanion(TransactionsCompanion data) {
    return TransactionRow(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      amountCents: data.amountCents.present
          ? data.amountCents.value
          : this.amountCents,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      date: data.date.present ? data.date.value : this.date,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      description: data.description.present
          ? data.description.value
          : this.description,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      nature: data.nature.present ? data.nature.value : this.nature,
      notes: data.notes.present ? data.notes.value : this.notes,
      debtId: data.debtId.present ? data.debtId.value : this.debtId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionRow(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('amountCents: $amountCents, ')
          ..write('categoryId: $categoryId, ')
          ..write('date: $date, ')
          ..write('createdAt: $createdAt, ')
          ..write('description: $description, ')
          ..write('accountId: $accountId, ')
          ..write('nature: $nature, ')
          ..write('notes: $notes, ')
          ..write('debtId: $debtId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    amountCents,
    categoryId,
    date,
    createdAt,
    description,
    accountId,
    nature,
    notes,
    debtId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionRow &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.amountCents == this.amountCents &&
          other.categoryId == this.categoryId &&
          other.date == this.date &&
          other.createdAt == this.createdAt &&
          other.description == this.description &&
          other.accountId == this.accountId &&
          other.nature == this.nature &&
          other.notes == this.notes &&
          other.debtId == this.debtId);
}

class TransactionsCompanion extends UpdateCompanion<TransactionRow> {
  final Value<String> id;
  final Value<TransactionKind> kind;
  final Value<int> amountCents;
  final Value<String> categoryId;
  final Value<DateTime> date;
  final Value<DateTime> createdAt;
  final Value<String?> description;
  final Value<String?> accountId;
  final Value<ExpenseNature?> nature;
  final Value<String?> notes;
  final Value<String?> debtId;
  final Value<int> rowid;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.amountCents = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.date = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.description = const Value.absent(),
    this.accountId = const Value.absent(),
    this.nature = const Value.absent(),
    this.notes = const Value.absent(),
    this.debtId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionsCompanion.insert({
    required String id,
    required TransactionKind kind,
    required int amountCents,
    required String categoryId,
    required DateTime date,
    required DateTime createdAt,
    this.description = const Value.absent(),
    this.accountId = const Value.absent(),
    this.nature = const Value.absent(),
    this.notes = const Value.absent(),
    this.debtId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       kind = Value(kind),
       amountCents = Value(amountCents),
       categoryId = Value(categoryId),
       date = Value(date),
       createdAt = Value(createdAt);
  static Insertable<TransactionRow> custom({
    Expression<String>? id,
    Expression<String>? kind,
    Expression<int>? amountCents,
    Expression<String>? categoryId,
    Expression<DateTime>? date,
    Expression<DateTime>? createdAt,
    Expression<String>? description,
    Expression<String>? accountId,
    Expression<String>? nature,
    Expression<String>? notes,
    Expression<String>? debtId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (amountCents != null) 'amount_cents': amountCents,
      if (categoryId != null) 'category_id': categoryId,
      if (date != null) 'date': date,
      if (createdAt != null) 'created_at': createdAt,
      if (description != null) 'description': description,
      if (accountId != null) 'account_id': accountId,
      if (nature != null) 'nature': nature,
      if (notes != null) 'notes': notes,
      if (debtId != null) 'debt_id': debtId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionsCompanion copyWith({
    Value<String>? id,
    Value<TransactionKind>? kind,
    Value<int>? amountCents,
    Value<String>? categoryId,
    Value<DateTime>? date,
    Value<DateTime>? createdAt,
    Value<String?>? description,
    Value<String?>? accountId,
    Value<ExpenseNature?>? nature,
    Value<String?>? notes,
    Value<String?>? debtId,
    Value<int>? rowid,
  }) {
    return TransactionsCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      amountCents: amountCents ?? this.amountCents,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
      accountId: accountId ?? this.accountId,
      nature: nature ?? this.nature,
      notes: notes ?? this.notes,
      debtId: debtId ?? this.debtId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $TransactionsTable.$converterkind.toSql(kind.value),
      );
    }
    if (amountCents.present) {
      map['amount_cents'] = Variable<int>(amountCents.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (nature.present) {
      map['nature'] = Variable<String>(
        $TransactionsTable.$converternaturen.toSql(nature.value),
      );
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (debtId.present) {
      map['debt_id'] = Variable<String>(debtId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('amountCents: $amountCents, ')
          ..write('categoryId: $categoryId, ')
          ..write('date: $date, ')
          ..write('createdAt: $createdAt, ')
          ..write('description: $description, ')
          ..write('accountId: $accountId, ')
          ..write('nature: $nature, ')
          ..write('notes: $notes, ')
          ..write('debtId: $debtId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BudgetLinesTable extends BudgetLines
    with TableInfo<$BudgetLinesTable, BudgetLineRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BudgetLinesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _monthMeta = const VerificationMeta('month');
  @override
  late final GeneratedColumn<int> month = GeneratedColumn<int>(
    'month',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id)',
    ),
  );
  static const VerificationMeta _limitCentsMeta = const VerificationMeta(
    'limitCents',
  );
  @override
  late final GeneratedColumn<int> limitCents = GeneratedColumn<int>(
    'limit_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    year,
    month,
    categoryId,
    limitCents,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'budget_lines';
  @override
  VerificationContext validateIntegrity(
    Insertable<BudgetLineRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    } else if (isInserting) {
      context.missing(_yearMeta);
    }
    if (data.containsKey('month')) {
      context.handle(
        _monthMeta,
        month.isAcceptableOrUnknown(data['month']!, _monthMeta),
      );
    } else if (isInserting) {
      context.missing(_monthMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('limit_cents')) {
      context.handle(
        _limitCentsMeta,
        limitCents.isAcceptableOrUnknown(data['limit_cents']!, _limitCentsMeta),
      );
    } else if (isInserting) {
      context.missing(_limitCentsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {year, month, categoryId},
  ];
  @override
  BudgetLineRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BudgetLineRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      )!,
      month: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}month'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      )!,
      limitCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}limit_cents'],
      )!,
    );
  }

  @override
  $BudgetLinesTable createAlias(String alias) {
    return $BudgetLinesTable(attachedDatabase, alias);
  }
}

class BudgetLineRow extends DataClass implements Insertable<BudgetLineRow> {
  final String id;
  final int year;
  final int month;
  final String categoryId;
  final int limitCents;
  const BudgetLineRow({
    required this.id,
    required this.year,
    required this.month,
    required this.categoryId,
    required this.limitCents,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['year'] = Variable<int>(year);
    map['month'] = Variable<int>(month);
    map['category_id'] = Variable<String>(categoryId);
    map['limit_cents'] = Variable<int>(limitCents);
    return map;
  }

  BudgetLinesCompanion toCompanion(bool nullToAbsent) {
    return BudgetLinesCompanion(
      id: Value(id),
      year: Value(year),
      month: Value(month),
      categoryId: Value(categoryId),
      limitCents: Value(limitCents),
    );
  }

  factory BudgetLineRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BudgetLineRow(
      id: serializer.fromJson<String>(json['id']),
      year: serializer.fromJson<int>(json['year']),
      month: serializer.fromJson<int>(json['month']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      limitCents: serializer.fromJson<int>(json['limitCents']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'year': serializer.toJson<int>(year),
      'month': serializer.toJson<int>(month),
      'categoryId': serializer.toJson<String>(categoryId),
      'limitCents': serializer.toJson<int>(limitCents),
    };
  }

  BudgetLineRow copyWith({
    String? id,
    int? year,
    int? month,
    String? categoryId,
    int? limitCents,
  }) => BudgetLineRow(
    id: id ?? this.id,
    year: year ?? this.year,
    month: month ?? this.month,
    categoryId: categoryId ?? this.categoryId,
    limitCents: limitCents ?? this.limitCents,
  );
  BudgetLineRow copyWithCompanion(BudgetLinesCompanion data) {
    return BudgetLineRow(
      id: data.id.present ? data.id.value : this.id,
      year: data.year.present ? data.year.value : this.year,
      month: data.month.present ? data.month.value : this.month,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      limitCents: data.limitCents.present
          ? data.limitCents.value
          : this.limitCents,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BudgetLineRow(')
          ..write('id: $id, ')
          ..write('year: $year, ')
          ..write('month: $month, ')
          ..write('categoryId: $categoryId, ')
          ..write('limitCents: $limitCents')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, year, month, categoryId, limitCents);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BudgetLineRow &&
          other.id == this.id &&
          other.year == this.year &&
          other.month == this.month &&
          other.categoryId == this.categoryId &&
          other.limitCents == this.limitCents);
}

class BudgetLinesCompanion extends UpdateCompanion<BudgetLineRow> {
  final Value<String> id;
  final Value<int> year;
  final Value<int> month;
  final Value<String> categoryId;
  final Value<int> limitCents;
  final Value<int> rowid;
  const BudgetLinesCompanion({
    this.id = const Value.absent(),
    this.year = const Value.absent(),
    this.month = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.limitCents = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BudgetLinesCompanion.insert({
    required String id,
    required int year,
    required int month,
    required String categoryId,
    required int limitCents,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       year = Value(year),
       month = Value(month),
       categoryId = Value(categoryId),
       limitCents = Value(limitCents);
  static Insertable<BudgetLineRow> custom({
    Expression<String>? id,
    Expression<int>? year,
    Expression<int>? month,
    Expression<String>? categoryId,
    Expression<int>? limitCents,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (year != null) 'year': year,
      if (month != null) 'month': month,
      if (categoryId != null) 'category_id': categoryId,
      if (limitCents != null) 'limit_cents': limitCents,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BudgetLinesCompanion copyWith({
    Value<String>? id,
    Value<int>? year,
    Value<int>? month,
    Value<String>? categoryId,
    Value<int>? limitCents,
    Value<int>? rowid,
  }) {
    return BudgetLinesCompanion(
      id: id ?? this.id,
      year: year ?? this.year,
      month: month ?? this.month,
      categoryId: categoryId ?? this.categoryId,
      limitCents: limitCents ?? this.limitCents,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (month.present) {
      map['month'] = Variable<int>(month.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (limitCents.present) {
      map['limit_cents'] = Variable<int>(limitCents.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BudgetLinesCompanion(')
          ..write('id: $id, ')
          ..write('year: $year, ')
          ..write('month: $month, ')
          ..write('categoryId: $categoryId, ')
          ..write('limitCents: $limitCents, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AssetsTable extends Assets with TableInfo<$AssetsTable, AssetRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AssetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<AssetType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<AssetType>($AssetsTable.$convertertype);
  static const VerificationMeta _currentValueCentsMeta = const VerificationMeta(
    'currentValueCents',
  );
  @override
  late final GeneratedColumn<int> currentValueCents = GeneratedColumn<int>(
    'current_value_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valuedAtMeta = const VerificationMeta(
    'valuedAt',
  );
  @override
  late final GeneratedColumn<DateTime> valuedAt = GeneratedColumn<DateTime>(
    'valued_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    type,
    currentValueCents,
    valuedAt,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'assets';
  @override
  VerificationContext validateIntegrity(
    Insertable<AssetRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('current_value_cents')) {
      context.handle(
        _currentValueCentsMeta,
        currentValueCents.isAcceptableOrUnknown(
          data['current_value_cents']!,
          _currentValueCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currentValueCentsMeta);
    }
    if (data.containsKey('valued_at')) {
      context.handle(
        _valuedAtMeta,
        valuedAt.isAcceptableOrUnknown(data['valued_at']!, _valuedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_valuedAtMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AssetRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AssetRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: $AssetsTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      currentValueCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_value_cents'],
      )!,
      valuedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}valued_at'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $AssetsTable createAlias(String alias) {
    return $AssetsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AssetType, String, String> $convertertype =
      const EnumNameConverter<AssetType>(AssetType.values);
}

class AssetRow extends DataClass implements Insertable<AssetRow> {
  final String id;
  final String name;
  final AssetType type;
  final int currentValueCents;
  final DateTime valuedAt;
  final String? notes;
  const AssetRow({
    required this.id,
    required this.name,
    required this.type,
    required this.currentValueCents,
    required this.valuedAt,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    {
      map['type'] = Variable<String>($AssetsTable.$convertertype.toSql(type));
    }
    map['current_value_cents'] = Variable<int>(currentValueCents);
    map['valued_at'] = Variable<DateTime>(valuedAt);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  AssetsCompanion toCompanion(bool nullToAbsent) {
    return AssetsCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      currentValueCents: Value(currentValueCents),
      valuedAt: Value(valuedAt),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory AssetRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AssetRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      type: $AssetsTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
      currentValueCents: serializer.fromJson<int>(json['currentValueCents']),
      valuedAt: serializer.fromJson<DateTime>(json['valuedAt']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(
        $AssetsTable.$convertertype.toJson(type),
      ),
      'currentValueCents': serializer.toJson<int>(currentValueCents),
      'valuedAt': serializer.toJson<DateTime>(valuedAt),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  AssetRow copyWith({
    String? id,
    String? name,
    AssetType? type,
    int? currentValueCents,
    DateTime? valuedAt,
    Value<String?> notes = const Value.absent(),
  }) => AssetRow(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    currentValueCents: currentValueCents ?? this.currentValueCents,
    valuedAt: valuedAt ?? this.valuedAt,
    notes: notes.present ? notes.value : this.notes,
  );
  AssetRow copyWithCompanion(AssetsCompanion data) {
    return AssetRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      currentValueCents: data.currentValueCents.present
          ? data.currentValueCents.value
          : this.currentValueCents,
      valuedAt: data.valuedAt.present ? data.valuedAt.value : this.valuedAt,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AssetRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('currentValueCents: $currentValueCents, ')
          ..write('valuedAt: $valuedAt, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, type, currentValueCents, valuedAt, notes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AssetRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.currentValueCents == this.currentValueCents &&
          other.valuedAt == this.valuedAt &&
          other.notes == this.notes);
}

class AssetsCompanion extends UpdateCompanion<AssetRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<AssetType> type;
  final Value<int> currentValueCents;
  final Value<DateTime> valuedAt;
  final Value<String?> notes;
  final Value<int> rowid;
  const AssetsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.currentValueCents = const Value.absent(),
    this.valuedAt = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AssetsCompanion.insert({
    required String id,
    required String name,
    required AssetType type,
    required int currentValueCents,
    required DateTime valuedAt,
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       type = Value(type),
       currentValueCents = Value(currentValueCents),
       valuedAt = Value(valuedAt);
  static Insertable<AssetRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<int>? currentValueCents,
    Expression<DateTime>? valuedAt,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (currentValueCents != null) 'current_value_cents': currentValueCents,
      if (valuedAt != null) 'valued_at': valuedAt,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AssetsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<AssetType>? type,
    Value<int>? currentValueCents,
    Value<DateTime>? valuedAt,
    Value<String?>? notes,
    Value<int>? rowid,
  }) {
    return AssetsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      currentValueCents: currentValueCents ?? this.currentValueCents,
      valuedAt: valuedAt ?? this.valuedAt,
      notes: notes ?? this.notes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $AssetsTable.$convertertype.toSql(type.value),
      );
    }
    if (currentValueCents.present) {
      map['current_value_cents'] = Variable<int>(currentValueCents.value);
    }
    if (valuedAt.present) {
      map['valued_at'] = Variable<DateTime>(valuedAt.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AssetsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('currentValueCents: $currentValueCents, ')
          ..write('valuedAt: $valuedAt, ')
          ..write('notes: $notes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExtraPaymentsTable extends ExtraPayments
    with TableInfo<$ExtraPaymentsTable, ExtraPaymentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExtraPaymentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _debtIdMeta = const VerificationMeta('debtId');
  @override
  late final GeneratedColumn<String> debtId = GeneratedColumn<String>(
    'debt_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES debts (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _amountCentsMeta = const VerificationMeta(
    'amountCents',
  );
  @override
  late final GeneratedColumn<int> amountCents = GeneratedColumn<int>(
    'amount_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, debtId, amountCents, date];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'extra_payments';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExtraPaymentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('debt_id')) {
      context.handle(
        _debtIdMeta,
        debtId.isAcceptableOrUnknown(data['debt_id']!, _debtIdMeta),
      );
    } else if (isInserting) {
      context.missing(_debtIdMeta);
    }
    if (data.containsKey('amount_cents')) {
      context.handle(
        _amountCentsMeta,
        amountCents.isAcceptableOrUnknown(
          data['amount_cents']!,
          _amountCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountCentsMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExtraPaymentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExtraPaymentRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      debtId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}debt_id'],
      )!,
      amountCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_cents'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
    );
  }

  @override
  $ExtraPaymentsTable createAlias(String alias) {
    return $ExtraPaymentsTable(attachedDatabase, alias);
  }
}

class ExtraPaymentRow extends DataClass implements Insertable<ExtraPaymentRow> {
  final String id;
  final String debtId;
  final int amountCents;
  final DateTime date;
  const ExtraPaymentRow({
    required this.id,
    required this.debtId,
    required this.amountCents,
    required this.date,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['debt_id'] = Variable<String>(debtId);
    map['amount_cents'] = Variable<int>(amountCents);
    map['date'] = Variable<DateTime>(date);
    return map;
  }

  ExtraPaymentsCompanion toCompanion(bool nullToAbsent) {
    return ExtraPaymentsCompanion(
      id: Value(id),
      debtId: Value(debtId),
      amountCents: Value(amountCents),
      date: Value(date),
    );
  }

  factory ExtraPaymentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExtraPaymentRow(
      id: serializer.fromJson<String>(json['id']),
      debtId: serializer.fromJson<String>(json['debtId']),
      amountCents: serializer.fromJson<int>(json['amountCents']),
      date: serializer.fromJson<DateTime>(json['date']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'debtId': serializer.toJson<String>(debtId),
      'amountCents': serializer.toJson<int>(amountCents),
      'date': serializer.toJson<DateTime>(date),
    };
  }

  ExtraPaymentRow copyWith({
    String? id,
    String? debtId,
    int? amountCents,
    DateTime? date,
  }) => ExtraPaymentRow(
    id: id ?? this.id,
    debtId: debtId ?? this.debtId,
    amountCents: amountCents ?? this.amountCents,
    date: date ?? this.date,
  );
  ExtraPaymentRow copyWithCompanion(ExtraPaymentsCompanion data) {
    return ExtraPaymentRow(
      id: data.id.present ? data.id.value : this.id,
      debtId: data.debtId.present ? data.debtId.value : this.debtId,
      amountCents: data.amountCents.present
          ? data.amountCents.value
          : this.amountCents,
      date: data.date.present ? data.date.value : this.date,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExtraPaymentRow(')
          ..write('id: $id, ')
          ..write('debtId: $debtId, ')
          ..write('amountCents: $amountCents, ')
          ..write('date: $date')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, debtId, amountCents, date);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExtraPaymentRow &&
          other.id == this.id &&
          other.debtId == this.debtId &&
          other.amountCents == this.amountCents &&
          other.date == this.date);
}

class ExtraPaymentsCompanion extends UpdateCompanion<ExtraPaymentRow> {
  final Value<String> id;
  final Value<String> debtId;
  final Value<int> amountCents;
  final Value<DateTime> date;
  final Value<int> rowid;
  const ExtraPaymentsCompanion({
    this.id = const Value.absent(),
    this.debtId = const Value.absent(),
    this.amountCents = const Value.absent(),
    this.date = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExtraPaymentsCompanion.insert({
    required String id,
    required String debtId,
    required int amountCents,
    required DateTime date,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       debtId = Value(debtId),
       amountCents = Value(amountCents),
       date = Value(date);
  static Insertable<ExtraPaymentRow> custom({
    Expression<String>? id,
    Expression<String>? debtId,
    Expression<int>? amountCents,
    Expression<DateTime>? date,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (debtId != null) 'debt_id': debtId,
      if (amountCents != null) 'amount_cents': amountCents,
      if (date != null) 'date': date,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExtraPaymentsCompanion copyWith({
    Value<String>? id,
    Value<String>? debtId,
    Value<int>? amountCents,
    Value<DateTime>? date,
    Value<int>? rowid,
  }) {
    return ExtraPaymentsCompanion(
      id: id ?? this.id,
      debtId: debtId ?? this.debtId,
      amountCents: amountCents ?? this.amountCents,
      date: date ?? this.date,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (debtId.present) {
      map['debt_id'] = Variable<String>(debtId.value);
    }
    if (amountCents.present) {
      map['amount_cents'] = Variable<int>(amountCents.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExtraPaymentsCompanion(')
          ..write('id: $id, ')
          ..write('debtId: $debtId, ')
          ..write('amountCents: $amountCents, ')
          ..write('date: $date, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SavingsGoalsTable extends SavingsGoals
    with TableInfo<$SavingsGoalsTable, SavingsGoalRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavingsGoalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<GoalType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<GoalType>($SavingsGoalsTable.$convertertype);
  static const VerificationMeta _targetAmountCentsMeta = const VerificationMeta(
    'targetAmountCents',
  );
  @override
  late final GeneratedColumn<int> targetAmountCents = GeneratedColumn<int>(
    'target_amount_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetDateMeta = const VerificationMeta(
    'targetDate',
  );
  @override
  late final GeneratedColumn<DateTime> targetDate = GeneratedColumn<DateTime>(
    'target_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _desiredMonthlyCentsMeta =
      const VerificationMeta('desiredMonthlyCents');
  @override
  late final GeneratedColumn<int> desiredMonthlyCents = GeneratedColumn<int>(
    'desired_monthly_cents',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _essentialMonthlyCentsMeta =
      const VerificationMeta('essentialMonthlyCents');
  @override
  late final GeneratedColumn<int> essentialMonthlyCents = GeneratedColumn<int>(
    'essential_monthly_cents',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _emergencyTargetMonthsMeta =
      const VerificationMeta('emergencyTargetMonths');
  @override
  late final GeneratedColumn<int> emergencyTargetMonths = GeneratedColumn<int>(
    'emergency_target_months',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    type,
    targetAmountCents,
    targetDate,
    desiredMonthlyCents,
    essentialMonthlyCents,
    emergencyTargetMonths,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'savings_goals';
  @override
  VerificationContext validateIntegrity(
    Insertable<SavingsGoalRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('target_amount_cents')) {
      context.handle(
        _targetAmountCentsMeta,
        targetAmountCents.isAcceptableOrUnknown(
          data['target_amount_cents']!,
          _targetAmountCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetAmountCentsMeta);
    }
    if (data.containsKey('target_date')) {
      context.handle(
        _targetDateMeta,
        targetDate.isAcceptableOrUnknown(data['target_date']!, _targetDateMeta),
      );
    }
    if (data.containsKey('desired_monthly_cents')) {
      context.handle(
        _desiredMonthlyCentsMeta,
        desiredMonthlyCents.isAcceptableOrUnknown(
          data['desired_monthly_cents']!,
          _desiredMonthlyCentsMeta,
        ),
      );
    }
    if (data.containsKey('essential_monthly_cents')) {
      context.handle(
        _essentialMonthlyCentsMeta,
        essentialMonthlyCents.isAcceptableOrUnknown(
          data['essential_monthly_cents']!,
          _essentialMonthlyCentsMeta,
        ),
      );
    }
    if (data.containsKey('emergency_target_months')) {
      context.handle(
        _emergencyTargetMonthsMeta,
        emergencyTargetMonths.isAcceptableOrUnknown(
          data['emergency_target_months']!,
          _emergencyTargetMonthsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SavingsGoalRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavingsGoalRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: $SavingsGoalsTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      targetAmountCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_amount_cents'],
      )!,
      targetDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}target_date'],
      ),
      desiredMonthlyCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}desired_monthly_cents'],
      ),
      essentialMonthlyCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}essential_monthly_cents'],
      ),
      emergencyTargetMonths: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}emergency_target_months'],
      ),
    );
  }

  @override
  $SavingsGoalsTable createAlias(String alias) {
    return $SavingsGoalsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<GoalType, String, String> $convertertype =
      const EnumNameConverter<GoalType>(GoalType.values);
}

class SavingsGoalRow extends DataClass implements Insertable<SavingsGoalRow> {
  final String id;
  final String name;
  final GoalType type;
  final int targetAmountCents;
  final DateTime? targetDate;
  final int? desiredMonthlyCents;
  final int? essentialMonthlyCents;
  final int? emergencyTargetMonths;
  const SavingsGoalRow({
    required this.id,
    required this.name,
    required this.type,
    required this.targetAmountCents,
    this.targetDate,
    this.desiredMonthlyCents,
    this.essentialMonthlyCents,
    this.emergencyTargetMonths,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    {
      map['type'] = Variable<String>(
        $SavingsGoalsTable.$convertertype.toSql(type),
      );
    }
    map['target_amount_cents'] = Variable<int>(targetAmountCents);
    if (!nullToAbsent || targetDate != null) {
      map['target_date'] = Variable<DateTime>(targetDate);
    }
    if (!nullToAbsent || desiredMonthlyCents != null) {
      map['desired_monthly_cents'] = Variable<int>(desiredMonthlyCents);
    }
    if (!nullToAbsent || essentialMonthlyCents != null) {
      map['essential_monthly_cents'] = Variable<int>(essentialMonthlyCents);
    }
    if (!nullToAbsent || emergencyTargetMonths != null) {
      map['emergency_target_months'] = Variable<int>(emergencyTargetMonths);
    }
    return map;
  }

  SavingsGoalsCompanion toCompanion(bool nullToAbsent) {
    return SavingsGoalsCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      targetAmountCents: Value(targetAmountCents),
      targetDate: targetDate == null && nullToAbsent
          ? const Value.absent()
          : Value(targetDate),
      desiredMonthlyCents: desiredMonthlyCents == null && nullToAbsent
          ? const Value.absent()
          : Value(desiredMonthlyCents),
      essentialMonthlyCents: essentialMonthlyCents == null && nullToAbsent
          ? const Value.absent()
          : Value(essentialMonthlyCents),
      emergencyTargetMonths: emergencyTargetMonths == null && nullToAbsent
          ? const Value.absent()
          : Value(emergencyTargetMonths),
    );
  }

  factory SavingsGoalRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavingsGoalRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      type: $SavingsGoalsTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
      targetAmountCents: serializer.fromJson<int>(json['targetAmountCents']),
      targetDate: serializer.fromJson<DateTime?>(json['targetDate']),
      desiredMonthlyCents: serializer.fromJson<int?>(
        json['desiredMonthlyCents'],
      ),
      essentialMonthlyCents: serializer.fromJson<int?>(
        json['essentialMonthlyCents'],
      ),
      emergencyTargetMonths: serializer.fromJson<int?>(
        json['emergencyTargetMonths'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(
        $SavingsGoalsTable.$convertertype.toJson(type),
      ),
      'targetAmountCents': serializer.toJson<int>(targetAmountCents),
      'targetDate': serializer.toJson<DateTime?>(targetDate),
      'desiredMonthlyCents': serializer.toJson<int?>(desiredMonthlyCents),
      'essentialMonthlyCents': serializer.toJson<int?>(essentialMonthlyCents),
      'emergencyTargetMonths': serializer.toJson<int?>(emergencyTargetMonths),
    };
  }

  SavingsGoalRow copyWith({
    String? id,
    String? name,
    GoalType? type,
    int? targetAmountCents,
    Value<DateTime?> targetDate = const Value.absent(),
    Value<int?> desiredMonthlyCents = const Value.absent(),
    Value<int?> essentialMonthlyCents = const Value.absent(),
    Value<int?> emergencyTargetMonths = const Value.absent(),
  }) => SavingsGoalRow(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    targetAmountCents: targetAmountCents ?? this.targetAmountCents,
    targetDate: targetDate.present ? targetDate.value : this.targetDate,
    desiredMonthlyCents: desiredMonthlyCents.present
        ? desiredMonthlyCents.value
        : this.desiredMonthlyCents,
    essentialMonthlyCents: essentialMonthlyCents.present
        ? essentialMonthlyCents.value
        : this.essentialMonthlyCents,
    emergencyTargetMonths: emergencyTargetMonths.present
        ? emergencyTargetMonths.value
        : this.emergencyTargetMonths,
  );
  SavingsGoalRow copyWithCompanion(SavingsGoalsCompanion data) {
    return SavingsGoalRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      targetAmountCents: data.targetAmountCents.present
          ? data.targetAmountCents.value
          : this.targetAmountCents,
      targetDate: data.targetDate.present
          ? data.targetDate.value
          : this.targetDate,
      desiredMonthlyCents: data.desiredMonthlyCents.present
          ? data.desiredMonthlyCents.value
          : this.desiredMonthlyCents,
      essentialMonthlyCents: data.essentialMonthlyCents.present
          ? data.essentialMonthlyCents.value
          : this.essentialMonthlyCents,
      emergencyTargetMonths: data.emergencyTargetMonths.present
          ? data.emergencyTargetMonths.value
          : this.emergencyTargetMonths,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavingsGoalRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('targetAmountCents: $targetAmountCents, ')
          ..write('targetDate: $targetDate, ')
          ..write('desiredMonthlyCents: $desiredMonthlyCents, ')
          ..write('essentialMonthlyCents: $essentialMonthlyCents, ')
          ..write('emergencyTargetMonths: $emergencyTargetMonths')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    type,
    targetAmountCents,
    targetDate,
    desiredMonthlyCents,
    essentialMonthlyCents,
    emergencyTargetMonths,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavingsGoalRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.targetAmountCents == this.targetAmountCents &&
          other.targetDate == this.targetDate &&
          other.desiredMonthlyCents == this.desiredMonthlyCents &&
          other.essentialMonthlyCents == this.essentialMonthlyCents &&
          other.emergencyTargetMonths == this.emergencyTargetMonths);
}

class SavingsGoalsCompanion extends UpdateCompanion<SavingsGoalRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<GoalType> type;
  final Value<int> targetAmountCents;
  final Value<DateTime?> targetDate;
  final Value<int?> desiredMonthlyCents;
  final Value<int?> essentialMonthlyCents;
  final Value<int?> emergencyTargetMonths;
  final Value<int> rowid;
  const SavingsGoalsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.targetAmountCents = const Value.absent(),
    this.targetDate = const Value.absent(),
    this.desiredMonthlyCents = const Value.absent(),
    this.essentialMonthlyCents = const Value.absent(),
    this.emergencyTargetMonths = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SavingsGoalsCompanion.insert({
    required String id,
    required String name,
    required GoalType type,
    required int targetAmountCents,
    this.targetDate = const Value.absent(),
    this.desiredMonthlyCents = const Value.absent(),
    this.essentialMonthlyCents = const Value.absent(),
    this.emergencyTargetMonths = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       type = Value(type),
       targetAmountCents = Value(targetAmountCents);
  static Insertable<SavingsGoalRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<int>? targetAmountCents,
    Expression<DateTime>? targetDate,
    Expression<int>? desiredMonthlyCents,
    Expression<int>? essentialMonthlyCents,
    Expression<int>? emergencyTargetMonths,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (targetAmountCents != null) 'target_amount_cents': targetAmountCents,
      if (targetDate != null) 'target_date': targetDate,
      if (desiredMonthlyCents != null)
        'desired_monthly_cents': desiredMonthlyCents,
      if (essentialMonthlyCents != null)
        'essential_monthly_cents': essentialMonthlyCents,
      if (emergencyTargetMonths != null)
        'emergency_target_months': emergencyTargetMonths,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SavingsGoalsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<GoalType>? type,
    Value<int>? targetAmountCents,
    Value<DateTime?>? targetDate,
    Value<int?>? desiredMonthlyCents,
    Value<int?>? essentialMonthlyCents,
    Value<int?>? emergencyTargetMonths,
    Value<int>? rowid,
  }) {
    return SavingsGoalsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      targetAmountCents: targetAmountCents ?? this.targetAmountCents,
      targetDate: targetDate ?? this.targetDate,
      desiredMonthlyCents: desiredMonthlyCents ?? this.desiredMonthlyCents,
      essentialMonthlyCents:
          essentialMonthlyCents ?? this.essentialMonthlyCents,
      emergencyTargetMonths:
          emergencyTargetMonths ?? this.emergencyTargetMonths,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $SavingsGoalsTable.$convertertype.toSql(type.value),
      );
    }
    if (targetAmountCents.present) {
      map['target_amount_cents'] = Variable<int>(targetAmountCents.value);
    }
    if (targetDate.present) {
      map['target_date'] = Variable<DateTime>(targetDate.value);
    }
    if (desiredMonthlyCents.present) {
      map['desired_monthly_cents'] = Variable<int>(desiredMonthlyCents.value);
    }
    if (essentialMonthlyCents.present) {
      map['essential_monthly_cents'] = Variable<int>(
        essentialMonthlyCents.value,
      );
    }
    if (emergencyTargetMonths.present) {
      map['emergency_target_months'] = Variable<int>(
        emergencyTargetMonths.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavingsGoalsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('targetAmountCents: $targetAmountCents, ')
          ..write('targetDate: $targetDate, ')
          ..write('desiredMonthlyCents: $desiredMonthlyCents, ')
          ..write('essentialMonthlyCents: $essentialMonthlyCents, ')
          ..write('emergencyTargetMonths: $emergencyTargetMonths, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GoalContributionsTable extends GoalContributions
    with TableInfo<$GoalContributionsTable, GoalContributionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GoalContributionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _goalIdMeta = const VerificationMeta('goalId');
  @override
  late final GeneratedColumn<String> goalId = GeneratedColumn<String>(
    'goal_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES savings_goals (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _amountCentsMeta = const VerificationMeta(
    'amountCents',
  );
  @override
  late final GeneratedColumn<int> amountCents = GeneratedColumn<int>(
    'amount_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, goalId, amountCents, date];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'goal_contributions';
  @override
  VerificationContext validateIntegrity(
    Insertable<GoalContributionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('goal_id')) {
      context.handle(
        _goalIdMeta,
        goalId.isAcceptableOrUnknown(data['goal_id']!, _goalIdMeta),
      );
    } else if (isInserting) {
      context.missing(_goalIdMeta);
    }
    if (data.containsKey('amount_cents')) {
      context.handle(
        _amountCentsMeta,
        amountCents.isAcceptableOrUnknown(
          data['amount_cents']!,
          _amountCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountCentsMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GoalContributionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GoalContributionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      goalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}goal_id'],
      )!,
      amountCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_cents'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
    );
  }

  @override
  $GoalContributionsTable createAlias(String alias) {
    return $GoalContributionsTable(attachedDatabase, alias);
  }
}

class GoalContributionRow extends DataClass
    implements Insertable<GoalContributionRow> {
  final String id;
  final String goalId;
  final int amountCents;
  final DateTime date;
  const GoalContributionRow({
    required this.id,
    required this.goalId,
    required this.amountCents,
    required this.date,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['goal_id'] = Variable<String>(goalId);
    map['amount_cents'] = Variable<int>(amountCents);
    map['date'] = Variable<DateTime>(date);
    return map;
  }

  GoalContributionsCompanion toCompanion(bool nullToAbsent) {
    return GoalContributionsCompanion(
      id: Value(id),
      goalId: Value(goalId),
      amountCents: Value(amountCents),
      date: Value(date),
    );
  }

  factory GoalContributionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GoalContributionRow(
      id: serializer.fromJson<String>(json['id']),
      goalId: serializer.fromJson<String>(json['goalId']),
      amountCents: serializer.fromJson<int>(json['amountCents']),
      date: serializer.fromJson<DateTime>(json['date']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'goalId': serializer.toJson<String>(goalId),
      'amountCents': serializer.toJson<int>(amountCents),
      'date': serializer.toJson<DateTime>(date),
    };
  }

  GoalContributionRow copyWith({
    String? id,
    String? goalId,
    int? amountCents,
    DateTime? date,
  }) => GoalContributionRow(
    id: id ?? this.id,
    goalId: goalId ?? this.goalId,
    amountCents: amountCents ?? this.amountCents,
    date: date ?? this.date,
  );
  GoalContributionRow copyWithCompanion(GoalContributionsCompanion data) {
    return GoalContributionRow(
      id: data.id.present ? data.id.value : this.id,
      goalId: data.goalId.present ? data.goalId.value : this.goalId,
      amountCents: data.amountCents.present
          ? data.amountCents.value
          : this.amountCents,
      date: data.date.present ? data.date.value : this.date,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GoalContributionRow(')
          ..write('id: $id, ')
          ..write('goalId: $goalId, ')
          ..write('amountCents: $amountCents, ')
          ..write('date: $date')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, goalId, amountCents, date);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GoalContributionRow &&
          other.id == this.id &&
          other.goalId == this.goalId &&
          other.amountCents == this.amountCents &&
          other.date == this.date);
}

class GoalContributionsCompanion extends UpdateCompanion<GoalContributionRow> {
  final Value<String> id;
  final Value<String> goalId;
  final Value<int> amountCents;
  final Value<DateTime> date;
  final Value<int> rowid;
  const GoalContributionsCompanion({
    this.id = const Value.absent(),
    this.goalId = const Value.absent(),
    this.amountCents = const Value.absent(),
    this.date = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GoalContributionsCompanion.insert({
    required String id,
    required String goalId,
    required int amountCents,
    required DateTime date,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       goalId = Value(goalId),
       amountCents = Value(amountCents),
       date = Value(date);
  static Insertable<GoalContributionRow> custom({
    Expression<String>? id,
    Expression<String>? goalId,
    Expression<int>? amountCents,
    Expression<DateTime>? date,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (goalId != null) 'goal_id': goalId,
      if (amountCents != null) 'amount_cents': amountCents,
      if (date != null) 'date': date,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GoalContributionsCompanion copyWith({
    Value<String>? id,
    Value<String>? goalId,
    Value<int>? amountCents,
    Value<DateTime>? date,
    Value<int>? rowid,
  }) {
    return GoalContributionsCompanion(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      amountCents: amountCents ?? this.amountCents,
      date: date ?? this.date,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (goalId.present) {
      map['goal_id'] = Variable<String>(goalId.value);
    }
    if (amountCents.present) {
      map['amount_cents'] = Variable<int>(amountCents.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GoalContributionsCompanion(')
          ..write('id: $id, ')
          ..write('goalId: $goalId, ')
          ..write('amountCents: $amountCents, ')
          ..write('date: $date, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InvestmentsTable extends Investments
    with TableInfo<$InvestmentsTable, InvestmentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InvestmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<InvestmentType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<InvestmentType>($InvestmentsTable.$convertertype);
  static const VerificationMeta _investedCentsMeta = const VerificationMeta(
    'investedCents',
  );
  @override
  late final GeneratedColumn<int> investedCents = GeneratedColumn<int>(
    'invested_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currentValueCentsMeta = const VerificationMeta(
    'currentValueCents',
  );
  @override
  late final GeneratedColumn<int> currentValueCents = GeneratedColumn<int>(
    'current_value_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    type,
    investedCents,
    currentValueCents,
    date,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'investments';
  @override
  VerificationContext validateIntegrity(
    Insertable<InvestmentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('invested_cents')) {
      context.handle(
        _investedCentsMeta,
        investedCents.isAcceptableOrUnknown(
          data['invested_cents']!,
          _investedCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_investedCentsMeta);
    }
    if (data.containsKey('current_value_cents')) {
      context.handle(
        _currentValueCentsMeta,
        currentValueCents.isAcceptableOrUnknown(
          data['current_value_cents']!,
          _currentValueCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currentValueCentsMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InvestmentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InvestmentRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: $InvestmentsTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      investedCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}invested_cents'],
      )!,
      currentValueCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_value_cents'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $InvestmentsTable createAlias(String alias) {
    return $InvestmentsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<InvestmentType, String, String> $convertertype =
      const EnumNameConverter<InvestmentType>(InvestmentType.values);
}

class InvestmentRow extends DataClass implements Insertable<InvestmentRow> {
  final String id;
  final String name;
  final InvestmentType type;
  final int investedCents;
  final int currentValueCents;
  final DateTime date;
  final String? notes;
  const InvestmentRow({
    required this.id,
    required this.name,
    required this.type,
    required this.investedCents,
    required this.currentValueCents,
    required this.date,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    {
      map['type'] = Variable<String>(
        $InvestmentsTable.$convertertype.toSql(type),
      );
    }
    map['invested_cents'] = Variable<int>(investedCents);
    map['current_value_cents'] = Variable<int>(currentValueCents);
    map['date'] = Variable<DateTime>(date);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  InvestmentsCompanion toCompanion(bool nullToAbsent) {
    return InvestmentsCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      investedCents: Value(investedCents),
      currentValueCents: Value(currentValueCents),
      date: Value(date),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory InvestmentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InvestmentRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      type: $InvestmentsTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
      investedCents: serializer.fromJson<int>(json['investedCents']),
      currentValueCents: serializer.fromJson<int>(json['currentValueCents']),
      date: serializer.fromJson<DateTime>(json['date']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(
        $InvestmentsTable.$convertertype.toJson(type),
      ),
      'investedCents': serializer.toJson<int>(investedCents),
      'currentValueCents': serializer.toJson<int>(currentValueCents),
      'date': serializer.toJson<DateTime>(date),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  InvestmentRow copyWith({
    String? id,
    String? name,
    InvestmentType? type,
    int? investedCents,
    int? currentValueCents,
    DateTime? date,
    Value<String?> notes = const Value.absent(),
  }) => InvestmentRow(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    investedCents: investedCents ?? this.investedCents,
    currentValueCents: currentValueCents ?? this.currentValueCents,
    date: date ?? this.date,
    notes: notes.present ? notes.value : this.notes,
  );
  InvestmentRow copyWithCompanion(InvestmentsCompanion data) {
    return InvestmentRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      investedCents: data.investedCents.present
          ? data.investedCents.value
          : this.investedCents,
      currentValueCents: data.currentValueCents.present
          ? data.currentValueCents.value
          : this.currentValueCents,
      date: data.date.present ? data.date.value : this.date,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InvestmentRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('investedCents: $investedCents, ')
          ..write('currentValueCents: $currentValueCents, ')
          ..write('date: $date, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    type,
    investedCents,
    currentValueCents,
    date,
    notes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InvestmentRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.investedCents == this.investedCents &&
          other.currentValueCents == this.currentValueCents &&
          other.date == this.date &&
          other.notes == this.notes);
}

class InvestmentsCompanion extends UpdateCompanion<InvestmentRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<InvestmentType> type;
  final Value<int> investedCents;
  final Value<int> currentValueCents;
  final Value<DateTime> date;
  final Value<String?> notes;
  final Value<int> rowid;
  const InvestmentsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.investedCents = const Value.absent(),
    this.currentValueCents = const Value.absent(),
    this.date = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InvestmentsCompanion.insert({
    required String id,
    required String name,
    required InvestmentType type,
    required int investedCents,
    required int currentValueCents,
    required DateTime date,
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       type = Value(type),
       investedCents = Value(investedCents),
       currentValueCents = Value(currentValueCents),
       date = Value(date);
  static Insertable<InvestmentRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<int>? investedCents,
    Expression<int>? currentValueCents,
    Expression<DateTime>? date,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (investedCents != null) 'invested_cents': investedCents,
      if (currentValueCents != null) 'current_value_cents': currentValueCents,
      if (date != null) 'date': date,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InvestmentsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<InvestmentType>? type,
    Value<int>? investedCents,
    Value<int>? currentValueCents,
    Value<DateTime>? date,
    Value<String?>? notes,
    Value<int>? rowid,
  }) {
    return InvestmentsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      investedCents: investedCents ?? this.investedCents,
      currentValueCents: currentValueCents ?? this.currentValueCents,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $InvestmentsTable.$convertertype.toSql(type.value),
      );
    }
    if (investedCents.present) {
      map['invested_cents'] = Variable<int>(investedCents.value);
    }
    if (currentValueCents.present) {
      map['current_value_cents'] = Variable<int>(currentValueCents.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InvestmentsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('investedCents: $investedCents, ')
          ..write('currentValueCents: $currentValueCents, ')
          ..write('date: $date, ')
          ..write('notes: $notes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FinanceSettingsTableTable extends FinanceSettingsTable
    with TableInfo<$FinanceSettingsTableTable, SettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FinanceSettingsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _savingsTargetBasisPointsMeta =
      const VerificationMeta('savingsTargetBasisPoints');
  @override
  late final GeneratedColumn<int> savingsTargetBasisPoints =
      GeneratedColumn<int>(
        'savings_target_basis_points',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _warningFromBasisPointsMeta =
      const VerificationMeta('warningFromBasisPoints');
  @override
  late final GeneratedColumn<int> warningFromBasisPoints = GeneratedColumn<int>(
    'warning_from_basis_points',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _criticalAboveBasisPointsMeta =
      const VerificationMeta('criticalAboveBasisPoints');
  @override
  late final GeneratedColumn<int> criticalAboveBasisPoints =
      GeneratedColumn<int>(
        'critical_above_basis_points',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _smallExpenseThresholdCentsMeta =
      const VerificationMeta('smallExpenseThresholdCents');
  @override
  late final GeneratedColumn<int> smallExpenseThresholdCents =
      GeneratedColumn<int>(
        'small_expense_threshold_cents',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _paydayMeta = const VerificationMeta('payday');
  @override
  late final GeneratedColumn<int> payday = GeneratedColumn<int>(
    'payday',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(FinanceSettings.defaultPayday),
  );
  static const VerificationMeta _dailyReminderMeta = const VerificationMeta(
    'dailyReminder',
  );
  @override
  late final GeneratedColumn<bool> dailyReminder = GeneratedColumn<bool>(
    'daily_reminder',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("daily_reminder" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _reminderHourMeta = const VerificationMeta(
    'reminderHour',
  );
  @override
  late final GeneratedColumn<int> reminderHour = GeneratedColumn<int>(
    'reminder_hour',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(FinanceSettings.defaultReminderHour),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    savingsTargetBasisPoints,
    warningFromBasisPoints,
    criticalAboveBasisPoints,
    smallExpenseThresholdCents,
    payday,
    dailyReminder,
    reminderHour,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'finance_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('savings_target_basis_points')) {
      context.handle(
        _savingsTargetBasisPointsMeta,
        savingsTargetBasisPoints.isAcceptableOrUnknown(
          data['savings_target_basis_points']!,
          _savingsTargetBasisPointsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_savingsTargetBasisPointsMeta);
    }
    if (data.containsKey('warning_from_basis_points')) {
      context.handle(
        _warningFromBasisPointsMeta,
        warningFromBasisPoints.isAcceptableOrUnknown(
          data['warning_from_basis_points']!,
          _warningFromBasisPointsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_warningFromBasisPointsMeta);
    }
    if (data.containsKey('critical_above_basis_points')) {
      context.handle(
        _criticalAboveBasisPointsMeta,
        criticalAboveBasisPoints.isAcceptableOrUnknown(
          data['critical_above_basis_points']!,
          _criticalAboveBasisPointsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_criticalAboveBasisPointsMeta);
    }
    if (data.containsKey('small_expense_threshold_cents')) {
      context.handle(
        _smallExpenseThresholdCentsMeta,
        smallExpenseThresholdCents.isAcceptableOrUnknown(
          data['small_expense_threshold_cents']!,
          _smallExpenseThresholdCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_smallExpenseThresholdCentsMeta);
    }
    if (data.containsKey('payday')) {
      context.handle(
        _paydayMeta,
        payday.isAcceptableOrUnknown(data['payday']!, _paydayMeta),
      );
    }
    if (data.containsKey('daily_reminder')) {
      context.handle(
        _dailyReminderMeta,
        dailyReminder.isAcceptableOrUnknown(
          data['daily_reminder']!,
          _dailyReminderMeta,
        ),
      );
    }
    if (data.containsKey('reminder_hour')) {
      context.handle(
        _reminderHourMeta,
        reminderHour.isAcceptableOrUnknown(
          data['reminder_hour']!,
          _reminderHourMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingsRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      savingsTargetBasisPoints: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}savings_target_basis_points'],
      )!,
      warningFromBasisPoints: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}warning_from_basis_points'],
      )!,
      criticalAboveBasisPoints: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}critical_above_basis_points'],
      )!,
      smallExpenseThresholdCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}small_expense_threshold_cents'],
      )!,
      payday: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}payday'],
      )!,
      dailyReminder: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}daily_reminder'],
      )!,
      reminderHour: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_hour'],
      )!,
    );
  }

  @override
  $FinanceSettingsTableTable createAlias(String alias) {
    return $FinanceSettingsTableTable(attachedDatabase, alias);
  }
}

class SettingsRow extends DataClass implements Insertable<SettingsRow> {
  final int id;
  final int savingsTargetBasisPoints;
  final int warningFromBasisPoints;
  final int criticalAboveBasisPoints;
  final int smallExpenseThresholdCents;
  final int payday;
  final bool dailyReminder;
  final int reminderHour;
  const SettingsRow({
    required this.id,
    required this.savingsTargetBasisPoints,
    required this.warningFromBasisPoints,
    required this.criticalAboveBasisPoints,
    required this.smallExpenseThresholdCents,
    required this.payday,
    required this.dailyReminder,
    required this.reminderHour,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['savings_target_basis_points'] = Variable<int>(
      savingsTargetBasisPoints,
    );
    map['warning_from_basis_points'] = Variable<int>(warningFromBasisPoints);
    map['critical_above_basis_points'] = Variable<int>(
      criticalAboveBasisPoints,
    );
    map['small_expense_threshold_cents'] = Variable<int>(
      smallExpenseThresholdCents,
    );
    map['payday'] = Variable<int>(payday);
    map['daily_reminder'] = Variable<bool>(dailyReminder);
    map['reminder_hour'] = Variable<int>(reminderHour);
    return map;
  }

  FinanceSettingsTableCompanion toCompanion(bool nullToAbsent) {
    return FinanceSettingsTableCompanion(
      id: Value(id),
      savingsTargetBasisPoints: Value(savingsTargetBasisPoints),
      warningFromBasisPoints: Value(warningFromBasisPoints),
      criticalAboveBasisPoints: Value(criticalAboveBasisPoints),
      smallExpenseThresholdCents: Value(smallExpenseThresholdCents),
      payday: Value(payday),
      dailyReminder: Value(dailyReminder),
      reminderHour: Value(reminderHour),
    );
  }

  factory SettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingsRow(
      id: serializer.fromJson<int>(json['id']),
      savingsTargetBasisPoints: serializer.fromJson<int>(
        json['savingsTargetBasisPoints'],
      ),
      warningFromBasisPoints: serializer.fromJson<int>(
        json['warningFromBasisPoints'],
      ),
      criticalAboveBasisPoints: serializer.fromJson<int>(
        json['criticalAboveBasisPoints'],
      ),
      smallExpenseThresholdCents: serializer.fromJson<int>(
        json['smallExpenseThresholdCents'],
      ),
      payday: serializer.fromJson<int>(json['payday']),
      dailyReminder: serializer.fromJson<bool>(json['dailyReminder']),
      reminderHour: serializer.fromJson<int>(json['reminderHour']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'savingsTargetBasisPoints': serializer.toJson<int>(
        savingsTargetBasisPoints,
      ),
      'warningFromBasisPoints': serializer.toJson<int>(warningFromBasisPoints),
      'criticalAboveBasisPoints': serializer.toJson<int>(
        criticalAboveBasisPoints,
      ),
      'smallExpenseThresholdCents': serializer.toJson<int>(
        smallExpenseThresholdCents,
      ),
      'payday': serializer.toJson<int>(payday),
      'dailyReminder': serializer.toJson<bool>(dailyReminder),
      'reminderHour': serializer.toJson<int>(reminderHour),
    };
  }

  SettingsRow copyWith({
    int? id,
    int? savingsTargetBasisPoints,
    int? warningFromBasisPoints,
    int? criticalAboveBasisPoints,
    int? smallExpenseThresholdCents,
    int? payday,
    bool? dailyReminder,
    int? reminderHour,
  }) => SettingsRow(
    id: id ?? this.id,
    savingsTargetBasisPoints:
        savingsTargetBasisPoints ?? this.savingsTargetBasisPoints,
    warningFromBasisPoints:
        warningFromBasisPoints ?? this.warningFromBasisPoints,
    criticalAboveBasisPoints:
        criticalAboveBasisPoints ?? this.criticalAboveBasisPoints,
    smallExpenseThresholdCents:
        smallExpenseThresholdCents ?? this.smallExpenseThresholdCents,
    payday: payday ?? this.payday,
    dailyReminder: dailyReminder ?? this.dailyReminder,
    reminderHour: reminderHour ?? this.reminderHour,
  );
  SettingsRow copyWithCompanion(FinanceSettingsTableCompanion data) {
    return SettingsRow(
      id: data.id.present ? data.id.value : this.id,
      savingsTargetBasisPoints: data.savingsTargetBasisPoints.present
          ? data.savingsTargetBasisPoints.value
          : this.savingsTargetBasisPoints,
      warningFromBasisPoints: data.warningFromBasisPoints.present
          ? data.warningFromBasisPoints.value
          : this.warningFromBasisPoints,
      criticalAboveBasisPoints: data.criticalAboveBasisPoints.present
          ? data.criticalAboveBasisPoints.value
          : this.criticalAboveBasisPoints,
      smallExpenseThresholdCents: data.smallExpenseThresholdCents.present
          ? data.smallExpenseThresholdCents.value
          : this.smallExpenseThresholdCents,
      payday: data.payday.present ? data.payday.value : this.payday,
      dailyReminder: data.dailyReminder.present
          ? data.dailyReminder.value
          : this.dailyReminder,
      reminderHour: data.reminderHour.present
          ? data.reminderHour.value
          : this.reminderHour,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingsRow(')
          ..write('id: $id, ')
          ..write('savingsTargetBasisPoints: $savingsTargetBasisPoints, ')
          ..write('warningFromBasisPoints: $warningFromBasisPoints, ')
          ..write('criticalAboveBasisPoints: $criticalAboveBasisPoints, ')
          ..write('smallExpenseThresholdCents: $smallExpenseThresholdCents, ')
          ..write('payday: $payday, ')
          ..write('dailyReminder: $dailyReminder, ')
          ..write('reminderHour: $reminderHour')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    savingsTargetBasisPoints,
    warningFromBasisPoints,
    criticalAboveBasisPoints,
    smallExpenseThresholdCents,
    payday,
    dailyReminder,
    reminderHour,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingsRow &&
          other.id == this.id &&
          other.savingsTargetBasisPoints == this.savingsTargetBasisPoints &&
          other.warningFromBasisPoints == this.warningFromBasisPoints &&
          other.criticalAboveBasisPoints == this.criticalAboveBasisPoints &&
          other.smallExpenseThresholdCents == this.smallExpenseThresholdCents &&
          other.payday == this.payday &&
          other.dailyReminder == this.dailyReminder &&
          other.reminderHour == this.reminderHour);
}

class FinanceSettingsTableCompanion extends UpdateCompanion<SettingsRow> {
  final Value<int> id;
  final Value<int> savingsTargetBasisPoints;
  final Value<int> warningFromBasisPoints;
  final Value<int> criticalAboveBasisPoints;
  final Value<int> smallExpenseThresholdCents;
  final Value<int> payday;
  final Value<bool> dailyReminder;
  final Value<int> reminderHour;
  const FinanceSettingsTableCompanion({
    this.id = const Value.absent(),
    this.savingsTargetBasisPoints = const Value.absent(),
    this.warningFromBasisPoints = const Value.absent(),
    this.criticalAboveBasisPoints = const Value.absent(),
    this.smallExpenseThresholdCents = const Value.absent(),
    this.payday = const Value.absent(),
    this.dailyReminder = const Value.absent(),
    this.reminderHour = const Value.absent(),
  });
  FinanceSettingsTableCompanion.insert({
    this.id = const Value.absent(),
    required int savingsTargetBasisPoints,
    required int warningFromBasisPoints,
    required int criticalAboveBasisPoints,
    required int smallExpenseThresholdCents,
    this.payday = const Value.absent(),
    this.dailyReminder = const Value.absent(),
    this.reminderHour = const Value.absent(),
  }) : savingsTargetBasisPoints = Value(savingsTargetBasisPoints),
       warningFromBasisPoints = Value(warningFromBasisPoints),
       criticalAboveBasisPoints = Value(criticalAboveBasisPoints),
       smallExpenseThresholdCents = Value(smallExpenseThresholdCents);
  static Insertable<SettingsRow> custom({
    Expression<int>? id,
    Expression<int>? savingsTargetBasisPoints,
    Expression<int>? warningFromBasisPoints,
    Expression<int>? criticalAboveBasisPoints,
    Expression<int>? smallExpenseThresholdCents,
    Expression<int>? payday,
    Expression<bool>? dailyReminder,
    Expression<int>? reminderHour,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (savingsTargetBasisPoints != null)
        'savings_target_basis_points': savingsTargetBasisPoints,
      if (warningFromBasisPoints != null)
        'warning_from_basis_points': warningFromBasisPoints,
      if (criticalAboveBasisPoints != null)
        'critical_above_basis_points': criticalAboveBasisPoints,
      if (smallExpenseThresholdCents != null)
        'small_expense_threshold_cents': smallExpenseThresholdCents,
      if (payday != null) 'payday': payday,
      if (dailyReminder != null) 'daily_reminder': dailyReminder,
      if (reminderHour != null) 'reminder_hour': reminderHour,
    });
  }

  FinanceSettingsTableCompanion copyWith({
    Value<int>? id,
    Value<int>? savingsTargetBasisPoints,
    Value<int>? warningFromBasisPoints,
    Value<int>? criticalAboveBasisPoints,
    Value<int>? smallExpenseThresholdCents,
    Value<int>? payday,
    Value<bool>? dailyReminder,
    Value<int>? reminderHour,
  }) {
    return FinanceSettingsTableCompanion(
      id: id ?? this.id,
      savingsTargetBasisPoints:
          savingsTargetBasisPoints ?? this.savingsTargetBasisPoints,
      warningFromBasisPoints:
          warningFromBasisPoints ?? this.warningFromBasisPoints,
      criticalAboveBasisPoints:
          criticalAboveBasisPoints ?? this.criticalAboveBasisPoints,
      smallExpenseThresholdCents:
          smallExpenseThresholdCents ?? this.smallExpenseThresholdCents,
      payday: payday ?? this.payday,
      dailyReminder: dailyReminder ?? this.dailyReminder,
      reminderHour: reminderHour ?? this.reminderHour,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (savingsTargetBasisPoints.present) {
      map['savings_target_basis_points'] = Variable<int>(
        savingsTargetBasisPoints.value,
      );
    }
    if (warningFromBasisPoints.present) {
      map['warning_from_basis_points'] = Variable<int>(
        warningFromBasisPoints.value,
      );
    }
    if (criticalAboveBasisPoints.present) {
      map['critical_above_basis_points'] = Variable<int>(
        criticalAboveBasisPoints.value,
      );
    }
    if (smallExpenseThresholdCents.present) {
      map['small_expense_threshold_cents'] = Variable<int>(
        smallExpenseThresholdCents.value,
      );
    }
    if (payday.present) {
      map['payday'] = Variable<int>(payday.value);
    }
    if (dailyReminder.present) {
      map['daily_reminder'] = Variable<bool>(dailyReminder.value);
    }
    if (reminderHour.present) {
      map['reminder_hour'] = Variable<int>(reminderHour.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FinanceSettingsTableCompanion(')
          ..write('id: $id, ')
          ..write('savingsTargetBasisPoints: $savingsTargetBasisPoints, ')
          ..write('warningFromBasisPoints: $warningFromBasisPoints, ')
          ..write('criticalAboveBasisPoints: $criticalAboveBasisPoints, ')
          ..write('smallExpenseThresholdCents: $smallExpenseThresholdCents, ')
          ..write('payday: $payday, ')
          ..write('dailyReminder: $dailyReminder, ')
          ..write('reminderHour: $reminderHour')
          ..write(')'))
        .toString();
  }
}

class $FixedMovementsTable extends FixedMovements
    with TableInfo<$FixedMovementsTable, FixedMovementRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FixedMovementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TransactionKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<TransactionKind>($FixedMovementsTable.$converterkind);
  static const VerificationMeta _amountCentsMeta = const VerificationMeta(
    'amountCents',
  );
  @override
  late final GeneratedColumn<int> amountCents = GeneratedColumn<int>(
    'amount_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id)',
    ),
  );
  static const VerificationMeta _dayOfMonthMeta = const VerificationMeta(
    'dayOfMonth',
  );
  @override
  late final GeneratedColumn<int> dayOfMonth = GeneratedColumn<int>(
    'day_of_month',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
  );
  static const VerificationMeta _lastPostedOnMeta = const VerificationMeta(
    'lastPostedOn',
  );
  @override
  late final GeneratedColumn<DateTime> lastPostedOn = GeneratedColumn<DateTime>(
    'last_posted_on',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    kind,
    amountCents,
    categoryId,
    dayOfMonth,
    isActive,
    lastPostedOn,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fixed_movements';
  @override
  VerificationContext validateIntegrity(
    Insertable<FixedMovementRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('amount_cents')) {
      context.handle(
        _amountCentsMeta,
        amountCents.isAcceptableOrUnknown(
          data['amount_cents']!,
          _amountCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountCentsMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('day_of_month')) {
      context.handle(
        _dayOfMonthMeta,
        dayOfMonth.isAcceptableOrUnknown(
          data['day_of_month']!,
          _dayOfMonthMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dayOfMonthMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    } else if (isInserting) {
      context.missing(_isActiveMeta);
    }
    if (data.containsKey('last_posted_on')) {
      context.handle(
        _lastPostedOnMeta,
        lastPostedOn.isAcceptableOrUnknown(
          data['last_posted_on']!,
          _lastPostedOnMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FixedMovementRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FixedMovementRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      kind: $FixedMovementsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      amountCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_cents'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      )!,
      dayOfMonth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_of_month'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      lastPostedOn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_posted_on'],
      ),
    );
  }

  @override
  $FixedMovementsTable createAlias(String alias) {
    return $FixedMovementsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TransactionKind, String, String> $converterkind =
      const EnumNameConverter<TransactionKind>(TransactionKind.values);
}

class FixedMovementRow extends DataClass
    implements Insertable<FixedMovementRow> {
  final String id;
  final String name;
  final TransactionKind kind;
  final int amountCents;
  final String categoryId;
  final int dayOfMonth;
  final bool isActive;
  final DateTime? lastPostedOn;
  const FixedMovementRow({
    required this.id,
    required this.name,
    required this.kind,
    required this.amountCents,
    required this.categoryId,
    required this.dayOfMonth,
    required this.isActive,
    this.lastPostedOn,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    {
      map['kind'] = Variable<String>(
        $FixedMovementsTable.$converterkind.toSql(kind),
      );
    }
    map['amount_cents'] = Variable<int>(amountCents);
    map['category_id'] = Variable<String>(categoryId);
    map['day_of_month'] = Variable<int>(dayOfMonth);
    map['is_active'] = Variable<bool>(isActive);
    if (!nullToAbsent || lastPostedOn != null) {
      map['last_posted_on'] = Variable<DateTime>(lastPostedOn);
    }
    return map;
  }

  FixedMovementsCompanion toCompanion(bool nullToAbsent) {
    return FixedMovementsCompanion(
      id: Value(id),
      name: Value(name),
      kind: Value(kind),
      amountCents: Value(amountCents),
      categoryId: Value(categoryId),
      dayOfMonth: Value(dayOfMonth),
      isActive: Value(isActive),
      lastPostedOn: lastPostedOn == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPostedOn),
    );
  }

  factory FixedMovementRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FixedMovementRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      kind: $FixedMovementsTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      amountCents: serializer.fromJson<int>(json['amountCents']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      dayOfMonth: serializer.fromJson<int>(json['dayOfMonth']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      lastPostedOn: serializer.fromJson<DateTime?>(json['lastPostedOn']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'kind': serializer.toJson<String>(
        $FixedMovementsTable.$converterkind.toJson(kind),
      ),
      'amountCents': serializer.toJson<int>(amountCents),
      'categoryId': serializer.toJson<String>(categoryId),
      'dayOfMonth': serializer.toJson<int>(dayOfMonth),
      'isActive': serializer.toJson<bool>(isActive),
      'lastPostedOn': serializer.toJson<DateTime?>(lastPostedOn),
    };
  }

  FixedMovementRow copyWith({
    String? id,
    String? name,
    TransactionKind? kind,
    int? amountCents,
    String? categoryId,
    int? dayOfMonth,
    bool? isActive,
    Value<DateTime?> lastPostedOn = const Value.absent(),
  }) => FixedMovementRow(
    id: id ?? this.id,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    amountCents: amountCents ?? this.amountCents,
    categoryId: categoryId ?? this.categoryId,
    dayOfMonth: dayOfMonth ?? this.dayOfMonth,
    isActive: isActive ?? this.isActive,
    lastPostedOn: lastPostedOn.present ? lastPostedOn.value : this.lastPostedOn,
  );
  FixedMovementRow copyWithCompanion(FixedMovementsCompanion data) {
    return FixedMovementRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      kind: data.kind.present ? data.kind.value : this.kind,
      amountCents: data.amountCents.present
          ? data.amountCents.value
          : this.amountCents,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      dayOfMonth: data.dayOfMonth.present
          ? data.dayOfMonth.value
          : this.dayOfMonth,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      lastPostedOn: data.lastPostedOn.present
          ? data.lastPostedOn.value
          : this.lastPostedOn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FixedMovementRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('amountCents: $amountCents, ')
          ..write('categoryId: $categoryId, ')
          ..write('dayOfMonth: $dayOfMonth, ')
          ..write('isActive: $isActive, ')
          ..write('lastPostedOn: $lastPostedOn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    kind,
    amountCents,
    categoryId,
    dayOfMonth,
    isActive,
    lastPostedOn,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FixedMovementRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.kind == this.kind &&
          other.amountCents == this.amountCents &&
          other.categoryId == this.categoryId &&
          other.dayOfMonth == this.dayOfMonth &&
          other.isActive == this.isActive &&
          other.lastPostedOn == this.lastPostedOn);
}

class FixedMovementsCompanion extends UpdateCompanion<FixedMovementRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<TransactionKind> kind;
  final Value<int> amountCents;
  final Value<String> categoryId;
  final Value<int> dayOfMonth;
  final Value<bool> isActive;
  final Value<DateTime?> lastPostedOn;
  final Value<int> rowid;
  const FixedMovementsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.amountCents = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.dayOfMonth = const Value.absent(),
    this.isActive = const Value.absent(),
    this.lastPostedOn = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FixedMovementsCompanion.insert({
    required String id,
    required String name,
    required TransactionKind kind,
    required int amountCents,
    required String categoryId,
    required int dayOfMonth,
    required bool isActive,
    this.lastPostedOn = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       kind = Value(kind),
       amountCents = Value(amountCents),
       categoryId = Value(categoryId),
       dayOfMonth = Value(dayOfMonth),
       isActive = Value(isActive);
  static Insertable<FixedMovementRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? kind,
    Expression<int>? amountCents,
    Expression<String>? categoryId,
    Expression<int>? dayOfMonth,
    Expression<bool>? isActive,
    Expression<DateTime>? lastPostedOn,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (kind != null) 'kind': kind,
      if (amountCents != null) 'amount_cents': amountCents,
      if (categoryId != null) 'category_id': categoryId,
      if (dayOfMonth != null) 'day_of_month': dayOfMonth,
      if (isActive != null) 'is_active': isActive,
      if (lastPostedOn != null) 'last_posted_on': lastPostedOn,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FixedMovementsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<TransactionKind>? kind,
    Value<int>? amountCents,
    Value<String>? categoryId,
    Value<int>? dayOfMonth,
    Value<bool>? isActive,
    Value<DateTime?>? lastPostedOn,
    Value<int>? rowid,
  }) {
    return FixedMovementsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      amountCents: amountCents ?? this.amountCents,
      categoryId: categoryId ?? this.categoryId,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      isActive: isActive ?? this.isActive,
      lastPostedOn: lastPostedOn ?? this.lastPostedOn,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $FixedMovementsTable.$converterkind.toSql(kind.value),
      );
    }
    if (amountCents.present) {
      map['amount_cents'] = Variable<int>(amountCents.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (dayOfMonth.present) {
      map['day_of_month'] = Variable<int>(dayOfMonth.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (lastPostedOn.present) {
      map['last_posted_on'] = Variable<DateTime>(lastPostedOn.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FixedMovementsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('amountCents: $amountCents, ')
          ..write('categoryId: $categoryId, ')
          ..write('dayOfMonth: $dayOfMonth, ')
          ..write('isActive: $isActive, ')
          ..write('lastPostedOn: $lastPostedOn, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $AccountsTable accounts = $AccountsTable(this);
  late final $DebtsTable debts = $DebtsTable(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $BudgetLinesTable budgetLines = $BudgetLinesTable(this);
  late final $AssetsTable assets = $AssetsTable(this);
  late final $ExtraPaymentsTable extraPayments = $ExtraPaymentsTable(this);
  late final $SavingsGoalsTable savingsGoals = $SavingsGoalsTable(this);
  late final $GoalContributionsTable goalContributions =
      $GoalContributionsTable(this);
  late final $InvestmentsTable investments = $InvestmentsTable(this);
  late final $FinanceSettingsTableTable financeSettingsTable =
      $FinanceSettingsTableTable(this);
  late final $FixedMovementsTable fixedMovements = $FixedMovementsTable(this);
  late final Index transactionsDateIdx = Index(
    'transactions_date_idx',
    'CREATE INDEX transactions_date_idx ON transactions (date)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    categories,
    accounts,
    debts,
    transactions,
    budgetLines,
    assets,
    extraPayments,
    savingsGoals,
    goalContributions,
    investments,
    financeSettingsTable,
    fixedMovements,
    transactionsDateIdx,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'accounts',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('transactions', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'debts',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('transactions', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'debts',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('extra_payments', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'savings_goals',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('goal_contributions', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$CategoriesTableCreateCompanionBuilder = CategoriesCompanion Function({
  required String id,
  required String name,
  required CategoryKind kind,
  required String iconKey,
  required int sortOrder,
  required bool isArchived,
  required bool countsAsSaving,
  Value<int> rowid,
});
typedef $$CategoriesTableUpdateCompanionBuilder = CategoriesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<CategoryKind> kind,
  Value<String> iconKey,
  Value<int> sortOrder,
  Value<bool> isArchived,
  Value<bool> countsAsSaving,
  Value<int> rowid,
});

final class $$CategoriesTableReferences
    extends BaseReferences<_$AppDatabase, $CategoriesTable, CategoryRow> {
  $$CategoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TransactionsTable, List<TransactionRow>>
  _transactionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.transactions,
    aliasName: 'categories__id__transactions__category_id',
  );

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager(
      $_db,
      $_db.transactions,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BudgetLinesTable, List<BudgetLineRow>>
  _budgetLinesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.budgetLines,
    aliasName: 'categories__id__budget_lines__category_id',
  );

  $$BudgetLinesTableProcessedTableManager get budgetLinesRefs {
    final manager = $$BudgetLinesTableTableManager(
      $_db,
      $_db.budgetLines,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_budgetLinesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$FixedMovementsTable, List<FixedMovementRow>>
  _fixedMovementsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.fixedMovements,
    aliasName: 'categories__id__fixed_movements__category_id',
  );

  $$FixedMovementsTableProcessedTableManager get fixedMovementsRefs {
    final manager = $$FixedMovementsTableTableManager(
      $_db,
      $_db.fixedMovements,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_fixedMovementsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<CategoryKind, CategoryKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get iconKey => $composableBuilder(
    column: $table.iconKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get countsAsSaving => $composableBuilder(
    column: $table.countsAsSaving,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> transactionsRefs(
    Expression<bool> Function($$TransactionsTableFilterComposer f) f,
  ) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> budgetLinesRefs(
    Expression<bool> Function($$BudgetLinesTableFilterComposer f) f,
  ) {
    final $$BudgetLinesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.budgetLines,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BudgetLinesTableFilterComposer(
            $db: $db,
            $table: $db.budgetLines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> fixedMovementsRefs(
    Expression<bool> Function($$FixedMovementsTableFilterComposer f) f,
  ) {
    final $$FixedMovementsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.fixedMovements,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FixedMovementsTableFilterComposer(
            $db: $db,
            $table: $db.fixedMovements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconKey => $composableBuilder(
    column: $table.iconKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get countsAsSaving => $composableBuilder(
    column: $table.countsAsSaving,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CategoryKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get iconKey =>
      $composableBuilder(column: $table.iconKey, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get countsAsSaving => $composableBuilder(
    column: $table.countsAsSaving,
    builder: (column) => column,
  );

  Expression<T> transactionsRefs<T extends Object>(
    Expression<T> Function($$TransactionsTableAnnotationComposer a) f,
  ) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> budgetLinesRefs<T extends Object>(
    Expression<T> Function($$BudgetLinesTableAnnotationComposer a) f,
  ) {
    final $$BudgetLinesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.budgetLines,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BudgetLinesTableAnnotationComposer(
            $db: $db,
            $table: $db.budgetLines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> fixedMovementsRefs<T extends Object>(
    Expression<T> Function($$FixedMovementsTableAnnotationComposer a) f,
  ) {
    final $$FixedMovementsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.fixedMovements,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FixedMovementsTableAnnotationComposer(
            $db: $db,
            $table: $db.fixedMovements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTable,
          CategoryRow,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (CategoryRow, $$CategoriesTableReferences),
          CategoryRow,
          PrefetchHooks Function({
            bool transactionsRefs,
            bool budgetLinesRefs,
            bool fixedMovementsRefs,
          })
        > {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<CategoryKind> kind = const Value.absent(),
                Value<String> iconKey = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<bool> countsAsSaving = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                name: name,
                kind: kind,
                iconKey: iconKey,
                sortOrder: sortOrder,
                isArchived: isArchived,
                countsAsSaving: countsAsSaving,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required CategoryKind kind,
                required String iconKey,
                required int sortOrder,
                required bool isArchived,
                required bool countsAsSaving,
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion.insert(
                id: id,
                name: name,
                kind: kind,
                iconKey: iconKey,
                sortOrder: sortOrder,
                isArchived: isArchived,
                countsAsSaving: countsAsSaving,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CategoriesTable, CategoryRow>(table),
                  $$CategoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                transactionsRefs = false,
                budgetLinesRefs = false,
                fixedMovementsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (transactionsRefs) db.transactions,
                    if (budgetLinesRefs) db.budgetLines,
                    if (fixedMovementsRefs) db.fixedMovements,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (transactionsRefs)
                        await $_getPrefetchedData<
                          CategoryRow,
                          $CategoriesTable,
                          TransactionRow
                        >(
                          currentTable: table,
                          referencedTable: $$CategoriesTableReferences
                              ._transactionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).transactionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.categoryId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (budgetLinesRefs)
                        await $_getPrefetchedData<
                          CategoryRow,
                          $CategoriesTable,
                          BudgetLineRow
                        >(
                          currentTable: table,
                          referencedTable: $$CategoriesTableReferences
                              ._budgetLinesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).budgetLinesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.categoryId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (fixedMovementsRefs)
                        await $_getPrefetchedData<
                          CategoryRow,
                          $CategoriesTable,
                          FixedMovementRow
                        >(
                          currentTable: table,
                          referencedTable: $$CategoriesTableReferences
                              ._fixedMovementsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).fixedMovementsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.categoryId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTable,
      CategoryRow,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (CategoryRow, $$CategoriesTableReferences),
      CategoryRow,
      PrefetchHooks Function({
        bool transactionsRefs,
        bool budgetLinesRefs,
        bool fixedMovementsRefs,
      })
    >;
typedef $$AccountsTableCreateCompanionBuilder = AccountsCompanion Function({
  required String id,
  required String name,
  required AccountType type,
  Value<int> rowid,
});
typedef $$AccountsTableUpdateCompanionBuilder = AccountsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<AccountType> type,
  Value<int> rowid,
});

final class $$AccountsTableReferences
    extends BaseReferences<_$AppDatabase, $AccountsTable, AccountRow> {
  $$AccountsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TransactionsTable, List<TransactionRow>>
  _transactionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.transactions,
    aliasName: 'accounts__id__transactions__account_id',
  );

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager(
      $_db,
      $_db.transactions,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AccountsTableFilterComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<AccountType, AccountType, String> get type =>
      $composableBuilder(
        column: $table.type,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  Expression<bool> transactionsRefs(
    Expression<bool> Function($$TransactionsTableFilterComposer f) f,
  ) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AccountType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  Expression<T> transactionsRefs<T extends Object>(
    Expression<T> Function($$TransactionsTableAnnotationComposer a) f,
  ) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AccountsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AccountsTable,
          AccountRow,
          $$AccountsTableFilterComposer,
          $$AccountsTableOrderingComposer,
          $$AccountsTableAnnotationComposer,
          $$AccountsTableCreateCompanionBuilder,
          $$AccountsTableUpdateCompanionBuilder,
          (AccountRow, $$AccountsTableReferences),
          AccountRow,
          PrefetchHooks Function({bool transactionsRefs})
        > {
  $$AccountsTableTableManager(_$AppDatabase db, $AccountsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<AccountType> type = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => AccountsCompanion(id: id, name: name, type: type, rowid: rowid),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required AccountType type,
                Value<int> rowid = const Value.absent(),
              }) => AccountsCompanion.insert(
                id: id,
                name: name,
                type: type,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AccountsTable, AccountRow>(table),
                  $$AccountsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({transactionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (transactionsRefs) db.transactions],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (transactionsRefs)
                    await $_getPrefetchedData<
                      AccountRow,
                      $AccountsTable,
                      TransactionRow
                    >(
                      currentTable: table,
                      referencedTable: $$AccountsTableReferences
                          ._transactionsRefsTable(db),
                      managerFromTypedResult: (p0) => $$AccountsTableReferences(
                        db,
                        table,
                        p0,
                      ).transactionsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.accountId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$AccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AccountsTable,
      AccountRow,
      $$AccountsTableFilterComposer,
      $$AccountsTableOrderingComposer,
      $$AccountsTableAnnotationComposer,
      $$AccountsTableCreateCompanionBuilder,
      $$AccountsTableUpdateCompanionBuilder,
      (AccountRow, $$AccountsTableReferences),
      AccountRow,
      PrefetchHooks Function({bool transactionsRefs})
    >;
typedef $$DebtsTableCreateCompanionBuilder = DebtsCompanion Function({
  required String id,
  required String name,
  required DebtType type,
  required int originalAmountCents,
  required int currentBalanceCents,
  Value<String?> notes,
  Value<int?> rateBasisPoints,
  Value<InterestRateType?> rateType,
  Value<int?> monthlyPaymentCents,
  Value<int?> monthlyFeesCents,
  Value<int?> totalInstallments,
  Value<int?> paidInstallments,
  Value<DateTime?> startDate,
  Value<int> rowid,
});
typedef $$DebtsTableUpdateCompanionBuilder = DebtsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<DebtType> type,
  Value<int> originalAmountCents,
  Value<int> currentBalanceCents,
  Value<String?> notes,
  Value<int?> rateBasisPoints,
  Value<InterestRateType?> rateType,
  Value<int?> monthlyPaymentCents,
  Value<int?> monthlyFeesCents,
  Value<int?> totalInstallments,
  Value<int?> paidInstallments,
  Value<DateTime?> startDate,
  Value<int> rowid,
});

final class $$DebtsTableReferences
    extends BaseReferences<_$AppDatabase, $DebtsTable, DebtRow> {
  $$DebtsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TransactionsTable, List<TransactionRow>>
  _transactionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.transactions,
    aliasName: 'debts__id__transactions__debt_id',
  );

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager(
      $_db,
      $_db.transactions,
    ).filter((f) => f.debtId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ExtraPaymentsTable, List<ExtraPaymentRow>>
  _extraPaymentsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.extraPayments,
    aliasName: 'debts__id__extra_payments__debt_id',
  );

  $$ExtraPaymentsTableProcessedTableManager get extraPaymentsRefs {
    final manager = $$ExtraPaymentsTableTableManager(
      $_db,
      $_db.extraPayments,
    ).filter((f) => f.debtId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_extraPaymentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DebtsTableFilterComposer extends Composer<_$AppDatabase, $DebtsTable> {
  $$DebtsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DebtType, DebtType, String> get type =>
      $composableBuilder(
        column: $table.type,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get originalAmountCents => $composableBuilder(
    column: $table.originalAmountCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentBalanceCents => $composableBuilder(
    column: $table.currentBalanceCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rateBasisPoints => $composableBuilder(
    column: $table.rateBasisPoints,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<InterestRateType?, InterestRateType, String>
  get rateType => $composableBuilder(
    column: $table.rateType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get monthlyPaymentCents => $composableBuilder(
    column: $table.monthlyPaymentCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get monthlyFeesCents => $composableBuilder(
    column: $table.monthlyFeesCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalInstallments => $composableBuilder(
    column: $table.totalInstallments,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get paidInstallments => $composableBuilder(
    column: $table.paidInstallments,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> transactionsRefs(
    Expression<bool> Function($$TransactionsTableFilterComposer f) f,
  ) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.debtId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> extraPaymentsRefs(
    Expression<bool> Function($$ExtraPaymentsTableFilterComposer f) f,
  ) {
    final $$ExtraPaymentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.extraPayments,
      getReferencedColumn: (t) => t.debtId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExtraPaymentsTableFilterComposer(
            $db: $db,
            $table: $db.extraPayments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DebtsTableOrderingComposer
    extends Composer<_$AppDatabase, $DebtsTable> {
  $$DebtsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get originalAmountCents => $composableBuilder(
    column: $table.originalAmountCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentBalanceCents => $composableBuilder(
    column: $table.currentBalanceCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rateBasisPoints => $composableBuilder(
    column: $table.rateBasisPoints,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rateType => $composableBuilder(
    column: $table.rateType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get monthlyPaymentCents => $composableBuilder(
    column: $table.monthlyPaymentCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get monthlyFeesCents => $composableBuilder(
    column: $table.monthlyFeesCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalInstallments => $composableBuilder(
    column: $table.totalInstallments,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get paidInstallments => $composableBuilder(
    column: $table.paidInstallments,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DebtsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DebtsTable> {
  $$DebtsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DebtType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get originalAmountCents => $composableBuilder(
    column: $table.originalAmountCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get currentBalanceCents => $composableBuilder(
    column: $table.currentBalanceCents,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get rateBasisPoints => $composableBuilder(
    column: $table.rateBasisPoints,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<InterestRateType?, String> get rateType =>
      $composableBuilder(column: $table.rateType, builder: (column) => column);

  GeneratedColumn<int> get monthlyPaymentCents => $composableBuilder(
    column: $table.monthlyPaymentCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get monthlyFeesCents => $composableBuilder(
    column: $table.monthlyFeesCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalInstallments => $composableBuilder(
    column: $table.totalInstallments,
    builder: (column) => column,
  );

  GeneratedColumn<int> get paidInstallments => $composableBuilder(
    column: $table.paidInstallments,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  Expression<T> transactionsRefs<T extends Object>(
    Expression<T> Function($$TransactionsTableAnnotationComposer a) f,
  ) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.debtId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> extraPaymentsRefs<T extends Object>(
    Expression<T> Function($$ExtraPaymentsTableAnnotationComposer a) f,
  ) {
    final $$ExtraPaymentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.extraPayments,
      getReferencedColumn: (t) => t.debtId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExtraPaymentsTableAnnotationComposer(
            $db: $db,
            $table: $db.extraPayments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DebtsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DebtsTable,
          DebtRow,
          $$DebtsTableFilterComposer,
          $$DebtsTableOrderingComposer,
          $$DebtsTableAnnotationComposer,
          $$DebtsTableCreateCompanionBuilder,
          $$DebtsTableUpdateCompanionBuilder,
          (DebtRow, $$DebtsTableReferences),
          DebtRow,
          PrefetchHooks Function({
            bool transactionsRefs,
            bool extraPaymentsRefs,
          })
        > {
  $$DebtsTableTableManager(_$AppDatabase db, $DebtsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DebtsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DebtsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DebtsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DebtType> type = const Value.absent(),
                Value<int> originalAmountCents = const Value.absent(),
                Value<int> currentBalanceCents = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int?> rateBasisPoints = const Value.absent(),
                Value<InterestRateType?> rateType = const Value.absent(),
                Value<int?> monthlyPaymentCents = const Value.absent(),
                Value<int?> monthlyFeesCents = const Value.absent(),
                Value<int?> totalInstallments = const Value.absent(),
                Value<int?> paidInstallments = const Value.absent(),
                Value<DateTime?> startDate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DebtsCompanion(
                id: id,
                name: name,
                type: type,
                originalAmountCents: originalAmountCents,
                currentBalanceCents: currentBalanceCents,
                notes: notes,
                rateBasisPoints: rateBasisPoints,
                rateType: rateType,
                monthlyPaymentCents: monthlyPaymentCents,
                monthlyFeesCents: monthlyFeesCents,
                totalInstallments: totalInstallments,
                paidInstallments: paidInstallments,
                startDate: startDate,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required DebtType type,
                required int originalAmountCents,
                required int currentBalanceCents,
                Value<String?> notes = const Value.absent(),
                Value<int?> rateBasisPoints = const Value.absent(),
                Value<InterestRateType?> rateType = const Value.absent(),
                Value<int?> monthlyPaymentCents = const Value.absent(),
                Value<int?> monthlyFeesCents = const Value.absent(),
                Value<int?> totalInstallments = const Value.absent(),
                Value<int?> paidInstallments = const Value.absent(),
                Value<DateTime?> startDate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DebtsCompanion.insert(
                id: id,
                name: name,
                type: type,
                originalAmountCents: originalAmountCents,
                currentBalanceCents: currentBalanceCents,
                notes: notes,
                rateBasisPoints: rateBasisPoints,
                rateType: rateType,
                monthlyPaymentCents: monthlyPaymentCents,
                monthlyFeesCents: monthlyFeesCents,
                totalInstallments: totalInstallments,
                paidInstallments: paidInstallments,
                startDate: startDate,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DebtsTable, DebtRow>(table),
                  $$DebtsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({transactionsRefs = false, extraPaymentsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (transactionsRefs) db.transactions,
                    if (extraPaymentsRefs) db.extraPayments,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (transactionsRefs)
                        await $_getPrefetchedData<
                          DebtRow,
                          $DebtsTable,
                          TransactionRow
                        >(
                          currentTable: table,
                          referencedTable: $$DebtsTableReferences
                              ._transactionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DebtsTableReferences(
                                db,
                                table,
                                p0,
                              ).transactionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.debtId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (extraPaymentsRefs)
                        await $_getPrefetchedData<
                          DebtRow,
                          $DebtsTable,
                          ExtraPaymentRow
                        >(
                          currentTable: table,
                          referencedTable: $$DebtsTableReferences
                              ._extraPaymentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DebtsTableReferences(
                                db,
                                table,
                                p0,
                              ).extraPaymentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.debtId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$DebtsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DebtsTable,
      DebtRow,
      $$DebtsTableFilterComposer,
      $$DebtsTableOrderingComposer,
      $$DebtsTableAnnotationComposer,
      $$DebtsTableCreateCompanionBuilder,
      $$DebtsTableUpdateCompanionBuilder,
      (DebtRow, $$DebtsTableReferences),
      DebtRow,
      PrefetchHooks Function({bool transactionsRefs, bool extraPaymentsRefs})
    >;
typedef $$TransactionsTableCreateCompanionBuilder =
    TransactionsCompanion Function({
      required String id,
      required TransactionKind kind,
      required int amountCents,
      required String categoryId,
      required DateTime date,
      required DateTime createdAt,
      Value<String?> description,
      Value<String?> accountId,
      Value<ExpenseNature?> nature,
      Value<String?> notes,
      Value<String?> debtId,
      Value<int> rowid,
    });
typedef $$TransactionsTableUpdateCompanionBuilder =
    TransactionsCompanion Function({
      Value<String> id,
      Value<TransactionKind> kind,
      Value<int> amountCents,
      Value<String> categoryId,
      Value<DateTime> date,
      Value<DateTime> createdAt,
      Value<String?> description,
      Value<String?> accountId,
      Value<ExpenseNature?> nature,
      Value<String?> notes,
      Value<String?> debtId,
      Value<int> rowid,
    });

final class $$TransactionsTableReferences
    extends BaseReferences<_$AppDatabase, $TransactionsTable, TransactionRow> {
  $$TransactionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias('transactions__category_id__categories__id');

  $$CategoriesTableProcessedTableManager get categoryId {
    final $_column = $_itemColumn<String>('category_id')!;

    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AccountsTable _accountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias('transactions__account_id__accounts__id');

  $$AccountsTableProcessedTableManager? get accountId {
    final $_column = $_itemColumn<String>('account_id');
    if ($_column == null) return null;
    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $DebtsTable _debtIdTable(_$AppDatabase db) =>
      db.debts.createAlias('transactions__debt_id__debts__id');

  $$DebtsTableProcessedTableManager? get debtId {
    final $_column = $_itemColumn<String>('debt_id');
    if ($_column == null) return null;
    final manager = $$DebtsTableTableManager(
      $_db,
      $_db.debts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_debtIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TransactionKind, TransactionKind, String>
  get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ExpenseNature?, ExpenseNature, String>
  get nature => $composableBuilder(
    column: $table.nature,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableFilterComposer get accountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DebtsTableFilterComposer get debtId {
    final $$DebtsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.debtId,
      referencedTable: $db.debts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DebtsTableFilterComposer(
            $db: $db,
            $table: $db.debts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nature => $composableBuilder(
    column: $table.nature,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableOrderingComposer get accountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DebtsTableOrderingComposer get debtId {
    final $$DebtsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.debtId,
      referencedTable: $db.debts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DebtsTableOrderingComposer(
            $db: $db,
            $table: $db.debts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TransactionKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<ExpenseNature?, String> get nature =>
      $composableBuilder(column: $table.nature, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableAnnotationComposer get accountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DebtsTableAnnotationComposer get debtId {
    final $$DebtsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.debtId,
      referencedTable: $db.debts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DebtsTableAnnotationComposer(
            $db: $db,
            $table: $db.debts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionsTable,
          TransactionRow,
          $$TransactionsTableFilterComposer,
          $$TransactionsTableOrderingComposer,
          $$TransactionsTableAnnotationComposer,
          $$TransactionsTableCreateCompanionBuilder,
          $$TransactionsTableUpdateCompanionBuilder,
          (TransactionRow, $$TransactionsTableReferences),
          TransactionRow,
          PrefetchHooks Function({bool categoryId, bool accountId, bool debtId})
        > {
  $$TransactionsTableTableManager(_$AppDatabase db, $TransactionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<TransactionKind> kind = const Value.absent(),
                Value<int> amountCents = const Value.absent(),
                Value<String> categoryId = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> accountId = const Value.absent(),
                Value<ExpenseNature?> nature = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> debtId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion(
                id: id,
                kind: kind,
                amountCents: amountCents,
                categoryId: categoryId,
                date: date,
                createdAt: createdAt,
                description: description,
                accountId: accountId,
                nature: nature,
                notes: notes,
                debtId: debtId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required TransactionKind kind,
                required int amountCents,
                required String categoryId,
                required DateTime date,
                required DateTime createdAt,
                Value<String?> description = const Value.absent(),
                Value<String?> accountId = const Value.absent(),
                Value<ExpenseNature?> nature = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> debtId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion.insert(
                id: id,
                kind: kind,
                amountCents: amountCents,
                categoryId: categoryId,
                date: date,
                createdAt: createdAt,
                description: description,
                accountId: accountId,
                nature: nature,
                notes: notes,
                debtId: debtId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TransactionsTable, TransactionRow>(table),
                  $$TransactionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({categoryId = false, accountId = false, debtId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (categoryId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.categoryId,
                            referencedTable: $$TransactionsTableReferences
                                ._categoryIdTable(db),
                            referencedColumn: $$TransactionsTableReferences
                                ._categoryIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (accountId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.accountId,
                            referencedTable: $$TransactionsTableReferences
                                ._accountIdTable(db),
                            referencedColumn: $$TransactionsTableReferences
                                ._accountIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (debtId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.debtId,
                            referencedTable: $$TransactionsTableReferences
                                ._debtIdTable(db),
                            referencedColumn: $$TransactionsTableReferences
                                ._debtIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$TransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionsTable,
      TransactionRow,
      $$TransactionsTableFilterComposer,
      $$TransactionsTableOrderingComposer,
      $$TransactionsTableAnnotationComposer,
      $$TransactionsTableCreateCompanionBuilder,
      $$TransactionsTableUpdateCompanionBuilder,
      (TransactionRow, $$TransactionsTableReferences),
      TransactionRow,
      PrefetchHooks Function({bool categoryId, bool accountId, bool debtId})
    >;
typedef $$BudgetLinesTableCreateCompanionBuilder =
    BudgetLinesCompanion Function({
      required String id,
      required int year,
      required int month,
      required String categoryId,
      required int limitCents,
      Value<int> rowid,
    });
typedef $$BudgetLinesTableUpdateCompanionBuilder =
    BudgetLinesCompanion Function({
      Value<String> id,
      Value<int> year,
      Value<int> month,
      Value<String> categoryId,
      Value<int> limitCents,
      Value<int> rowid,
    });

final class $$BudgetLinesTableReferences
    extends BaseReferences<_$AppDatabase, $BudgetLinesTable, BudgetLineRow> {
  $$BudgetLinesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias('budget_lines__category_id__categories__id');

  $$CategoriesTableProcessedTableManager get categoryId {
    final $_column = $_itemColumn<String>('category_id')!;

    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BudgetLinesTableFilterComposer
    extends Composer<_$AppDatabase, $BudgetLinesTable> {
  $$BudgetLinesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get limitCents => $composableBuilder(
    column: $table.limitCents,
    builder: (column) => ColumnFilters(column),
  );

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BudgetLinesTableOrderingComposer
    extends Composer<_$AppDatabase, $BudgetLinesTable> {
  $$BudgetLinesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get limitCents => $composableBuilder(
    column: $table.limitCents,
    builder: (column) => ColumnOrderings(column),
  );

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BudgetLinesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BudgetLinesTable> {
  $$BudgetLinesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<int> get month =>
      $composableBuilder(column: $table.month, builder: (column) => column);

  GeneratedColumn<int> get limitCents => $composableBuilder(
    column: $table.limitCents,
    builder: (column) => column,
  );

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BudgetLinesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BudgetLinesTable,
          BudgetLineRow,
          $$BudgetLinesTableFilterComposer,
          $$BudgetLinesTableOrderingComposer,
          $$BudgetLinesTableAnnotationComposer,
          $$BudgetLinesTableCreateCompanionBuilder,
          $$BudgetLinesTableUpdateCompanionBuilder,
          (BudgetLineRow, $$BudgetLinesTableReferences),
          BudgetLineRow,
          PrefetchHooks Function({bool categoryId})
        > {
  $$BudgetLinesTableTableManager(_$AppDatabase db, $BudgetLinesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BudgetLinesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BudgetLinesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BudgetLinesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> year = const Value.absent(),
                Value<int> month = const Value.absent(),
                Value<String> categoryId = const Value.absent(),
                Value<int> limitCents = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BudgetLinesCompanion(
                id: id,
                year: year,
                month: month,
                categoryId: categoryId,
                limitCents: limitCents,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int year,
                required int month,
                required String categoryId,
                required int limitCents,
                Value<int> rowid = const Value.absent(),
              }) => BudgetLinesCompanion.insert(
                id: id,
                year: year,
                month: month,
                categoryId: categoryId,
                limitCents: limitCents,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BudgetLinesTable, BudgetLineRow>(table),
                  $$BudgetLinesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({categoryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (categoryId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.categoryId,
                        referencedTable: $$BudgetLinesTableReferences
                            ._categoryIdTable(db),
                        referencedColumn: $$BudgetLinesTableReferences
                            ._categoryIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$BudgetLinesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BudgetLinesTable,
      BudgetLineRow,
      $$BudgetLinesTableFilterComposer,
      $$BudgetLinesTableOrderingComposer,
      $$BudgetLinesTableAnnotationComposer,
      $$BudgetLinesTableCreateCompanionBuilder,
      $$BudgetLinesTableUpdateCompanionBuilder,
      (BudgetLineRow, $$BudgetLinesTableReferences),
      BudgetLineRow,
      PrefetchHooks Function({bool categoryId})
    >;
typedef $$AssetsTableCreateCompanionBuilder = AssetsCompanion Function({
  required String id,
  required String name,
  required AssetType type,
  required int currentValueCents,
  required DateTime valuedAt,
  Value<String?> notes,
  Value<int> rowid,
});
typedef $$AssetsTableUpdateCompanionBuilder = AssetsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<AssetType> type,
  Value<int> currentValueCents,
  Value<DateTime> valuedAt,
  Value<String?> notes,
  Value<int> rowid,
});

class $$AssetsTableFilterComposer
    extends Composer<_$AppDatabase, $AssetsTable> {
  $$AssetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<AssetType, AssetType, String> get type =>
      $composableBuilder(
        column: $table.type,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get currentValueCents => $composableBuilder(
    column: $table.currentValueCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get valuedAt => $composableBuilder(
    column: $table.valuedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AssetsTableOrderingComposer
    extends Composer<_$AppDatabase, $AssetsTable> {
  $$AssetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentValueCents => $composableBuilder(
    column: $table.currentValueCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get valuedAt => $composableBuilder(
    column: $table.valuedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AssetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AssetsTable> {
  $$AssetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AssetType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get currentValueCents => $composableBuilder(
    column: $table.currentValueCents,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get valuedAt =>
      $composableBuilder(column: $table.valuedAt, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);
}

class $$AssetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AssetsTable,
          AssetRow,
          $$AssetsTableFilterComposer,
          $$AssetsTableOrderingComposer,
          $$AssetsTableAnnotationComposer,
          $$AssetsTableCreateCompanionBuilder,
          $$AssetsTableUpdateCompanionBuilder,
          (AssetRow, BaseReferences<_$AppDatabase, $AssetsTable, AssetRow>),
          AssetRow,
          PrefetchHooks Function()
        > {
  $$AssetsTableTableManager(_$AppDatabase db, $AssetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AssetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AssetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AssetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<AssetType> type = const Value.absent(),
                Value<int> currentValueCents = const Value.absent(),
                Value<DateTime> valuedAt = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AssetsCompanion(
                id: id,
                name: name,
                type: type,
                currentValueCents: currentValueCents,
                valuedAt: valuedAt,
                notes: notes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required AssetType type,
                required int currentValueCents,
                required DateTime valuedAt,
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AssetsCompanion.insert(
                id: id,
                name: name,
                type: type,
                currentValueCents: currentValueCents,
                valuedAt: valuedAt,
                notes: notes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AssetsTable, AssetRow>(table),
                  BaseReferences<_$AppDatabase, $AssetsTable, AssetRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AssetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AssetsTable,
      AssetRow,
      $$AssetsTableFilterComposer,
      $$AssetsTableOrderingComposer,
      $$AssetsTableAnnotationComposer,
      $$AssetsTableCreateCompanionBuilder,
      $$AssetsTableUpdateCompanionBuilder,
      (AssetRow, BaseReferences<_$AppDatabase, $AssetsTable, AssetRow>),
      AssetRow,
      PrefetchHooks Function()
    >;
typedef $$ExtraPaymentsTableCreateCompanionBuilder =
    ExtraPaymentsCompanion Function({
      required String id,
      required String debtId,
      required int amountCents,
      required DateTime date,
      Value<int> rowid,
    });
typedef $$ExtraPaymentsTableUpdateCompanionBuilder =
    ExtraPaymentsCompanion Function({
      Value<String> id,
      Value<String> debtId,
      Value<int> amountCents,
      Value<DateTime> date,
      Value<int> rowid,
    });

final class $$ExtraPaymentsTableReferences
    extends
        BaseReferences<_$AppDatabase, $ExtraPaymentsTable, ExtraPaymentRow> {
  $$ExtraPaymentsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $DebtsTable _debtIdTable(_$AppDatabase db) =>
      db.debts.createAlias('extra_payments__debt_id__debts__id');

  $$DebtsTableProcessedTableManager get debtId {
    final $_column = $_itemColumn<String>('debt_id')!;

    final manager = $$DebtsTableTableManager(
      $_db,
      $_db.debts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_debtIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ExtraPaymentsTableFilterComposer
    extends Composer<_$AppDatabase, $ExtraPaymentsTable> {
  $$ExtraPaymentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  $$DebtsTableFilterComposer get debtId {
    final $$DebtsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.debtId,
      referencedTable: $db.debts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DebtsTableFilterComposer(
            $db: $db,
            $table: $db.debts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExtraPaymentsTableOrderingComposer
    extends Composer<_$AppDatabase, $ExtraPaymentsTable> {
  $$ExtraPaymentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  $$DebtsTableOrderingComposer get debtId {
    final $$DebtsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.debtId,
      referencedTable: $db.debts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DebtsTableOrderingComposer(
            $db: $db,
            $table: $db.debts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExtraPaymentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExtraPaymentsTable> {
  $$ExtraPaymentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  $$DebtsTableAnnotationComposer get debtId {
    final $$DebtsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.debtId,
      referencedTable: $db.debts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DebtsTableAnnotationComposer(
            $db: $db,
            $table: $db.debts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExtraPaymentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExtraPaymentsTable,
          ExtraPaymentRow,
          $$ExtraPaymentsTableFilterComposer,
          $$ExtraPaymentsTableOrderingComposer,
          $$ExtraPaymentsTableAnnotationComposer,
          $$ExtraPaymentsTableCreateCompanionBuilder,
          $$ExtraPaymentsTableUpdateCompanionBuilder,
          (ExtraPaymentRow, $$ExtraPaymentsTableReferences),
          ExtraPaymentRow,
          PrefetchHooks Function({bool debtId})
        > {
  $$ExtraPaymentsTableTableManager(_$AppDatabase db, $ExtraPaymentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExtraPaymentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExtraPaymentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExtraPaymentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> debtId = const Value.absent(),
                Value<int> amountCents = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExtraPaymentsCompanion(
                id: id,
                debtId: debtId,
                amountCents: amountCents,
                date: date,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String debtId,
                required int amountCents,
                required DateTime date,
                Value<int> rowid = const Value.absent(),
              }) => ExtraPaymentsCompanion.insert(
                id: id,
                debtId: debtId,
                amountCents: amountCents,
                date: date,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ExtraPaymentsTable, ExtraPaymentRow>(table),
                  $$ExtraPaymentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({debtId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (debtId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.debtId,
                        referencedTable: $$ExtraPaymentsTableReferences
                            ._debtIdTable(db),
                        referencedColumn: $$ExtraPaymentsTableReferences
                            ._debtIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ExtraPaymentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExtraPaymentsTable,
      ExtraPaymentRow,
      $$ExtraPaymentsTableFilterComposer,
      $$ExtraPaymentsTableOrderingComposer,
      $$ExtraPaymentsTableAnnotationComposer,
      $$ExtraPaymentsTableCreateCompanionBuilder,
      $$ExtraPaymentsTableUpdateCompanionBuilder,
      (ExtraPaymentRow, $$ExtraPaymentsTableReferences),
      ExtraPaymentRow,
      PrefetchHooks Function({bool debtId})
    >;
typedef $$SavingsGoalsTableCreateCompanionBuilder =
    SavingsGoalsCompanion Function({
      required String id,
      required String name,
      required GoalType type,
      required int targetAmountCents,
      Value<DateTime?> targetDate,
      Value<int?> desiredMonthlyCents,
      Value<int?> essentialMonthlyCents,
      Value<int?> emergencyTargetMonths,
      Value<int> rowid,
    });
typedef $$SavingsGoalsTableUpdateCompanionBuilder =
    SavingsGoalsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<GoalType> type,
      Value<int> targetAmountCents,
      Value<DateTime?> targetDate,
      Value<int?> desiredMonthlyCents,
      Value<int?> essentialMonthlyCents,
      Value<int?> emergencyTargetMonths,
      Value<int> rowid,
    });

final class $$SavingsGoalsTableReferences
    extends BaseReferences<_$AppDatabase, $SavingsGoalsTable, SavingsGoalRow> {
  $$SavingsGoalsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$GoalContributionsTable, List<GoalContributionRow>>
  _goalContributionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.goalContributions,
        aliasName: 'savings_goals__id__goal_contributions__goal_id',
      );

  $$GoalContributionsTableProcessedTableManager get goalContributionsRefs {
    final manager = $$GoalContributionsTableTableManager(
      $_db,
      $_db.goalContributions,
    ).filter((f) => f.goalId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _goalContributionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SavingsGoalsTableFilterComposer
    extends Composer<_$AppDatabase, $SavingsGoalsTable> {
  $$SavingsGoalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<GoalType, GoalType, String> get type =>
      $composableBuilder(
        column: $table.type,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get targetAmountCents => $composableBuilder(
    column: $table.targetAmountCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get desiredMonthlyCents => $composableBuilder(
    column: $table.desiredMonthlyCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get essentialMonthlyCents => $composableBuilder(
    column: $table.essentialMonthlyCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get emergencyTargetMonths => $composableBuilder(
    column: $table.emergencyTargetMonths,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> goalContributionsRefs(
    Expression<bool> Function($$GoalContributionsTableFilterComposer f) f,
  ) {
    final $$GoalContributionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.goalContributions,
      getReferencedColumn: (t) => t.goalId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GoalContributionsTableFilterComposer(
            $db: $db,
            $table: $db.goalContributions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SavingsGoalsTableOrderingComposer
    extends Composer<_$AppDatabase, $SavingsGoalsTable> {
  $$SavingsGoalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetAmountCents => $composableBuilder(
    column: $table.targetAmountCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get desiredMonthlyCents => $composableBuilder(
    column: $table.desiredMonthlyCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get essentialMonthlyCents => $composableBuilder(
    column: $table.essentialMonthlyCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get emergencyTargetMonths => $composableBuilder(
    column: $table.emergencyTargetMonths,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SavingsGoalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SavingsGoalsTable> {
  $$SavingsGoalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<GoalType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get targetAmountCents => $composableBuilder(
    column: $table.targetAmountCents,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get desiredMonthlyCents => $composableBuilder(
    column: $table.desiredMonthlyCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get essentialMonthlyCents => $composableBuilder(
    column: $table.essentialMonthlyCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get emergencyTargetMonths => $composableBuilder(
    column: $table.emergencyTargetMonths,
    builder: (column) => column,
  );

  Expression<T> goalContributionsRefs<T extends Object>(
    Expression<T> Function($$GoalContributionsTableAnnotationComposer a) f,
  ) {
    final $$GoalContributionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.goalContributions,
          getReferencedColumn: (t) => t.goalId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$GoalContributionsTableAnnotationComposer(
                $db: $db,
                $table: $db.goalContributions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$SavingsGoalsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SavingsGoalsTable,
          SavingsGoalRow,
          $$SavingsGoalsTableFilterComposer,
          $$SavingsGoalsTableOrderingComposer,
          $$SavingsGoalsTableAnnotationComposer,
          $$SavingsGoalsTableCreateCompanionBuilder,
          $$SavingsGoalsTableUpdateCompanionBuilder,
          (SavingsGoalRow, $$SavingsGoalsTableReferences),
          SavingsGoalRow,
          PrefetchHooks Function({bool goalContributionsRefs})
        > {
  $$SavingsGoalsTableTableManager(_$AppDatabase db, $SavingsGoalsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SavingsGoalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SavingsGoalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SavingsGoalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<GoalType> type = const Value.absent(),
                Value<int> targetAmountCents = const Value.absent(),
                Value<DateTime?> targetDate = const Value.absent(),
                Value<int?> desiredMonthlyCents = const Value.absent(),
                Value<int?> essentialMonthlyCents = const Value.absent(),
                Value<int?> emergencyTargetMonths = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SavingsGoalsCompanion(
                id: id,
                name: name,
                type: type,
                targetAmountCents: targetAmountCents,
                targetDate: targetDate,
                desiredMonthlyCents: desiredMonthlyCents,
                essentialMonthlyCents: essentialMonthlyCents,
                emergencyTargetMonths: emergencyTargetMonths,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required GoalType type,
                required int targetAmountCents,
                Value<DateTime?> targetDate = const Value.absent(),
                Value<int?> desiredMonthlyCents = const Value.absent(),
                Value<int?> essentialMonthlyCents = const Value.absent(),
                Value<int?> emergencyTargetMonths = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SavingsGoalsCompanion.insert(
                id: id,
                name: name,
                type: type,
                targetAmountCents: targetAmountCents,
                targetDate: targetDate,
                desiredMonthlyCents: desiredMonthlyCents,
                essentialMonthlyCents: essentialMonthlyCents,
                emergencyTargetMonths: emergencyTargetMonths,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SavingsGoalsTable, SavingsGoalRow>(table),
                  $$SavingsGoalsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({goalContributionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (goalContributionsRefs) db.goalContributions,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (goalContributionsRefs)
                    await $_getPrefetchedData<
                      SavingsGoalRow,
                      $SavingsGoalsTable,
                      GoalContributionRow
                    >(
                      currentTable: table,
                      referencedTable: $$SavingsGoalsTableReferences
                          ._goalContributionsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$SavingsGoalsTableReferences(
                            db,
                            table,
                            p0,
                          ).goalContributionsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.goalId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SavingsGoalsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SavingsGoalsTable,
      SavingsGoalRow,
      $$SavingsGoalsTableFilterComposer,
      $$SavingsGoalsTableOrderingComposer,
      $$SavingsGoalsTableAnnotationComposer,
      $$SavingsGoalsTableCreateCompanionBuilder,
      $$SavingsGoalsTableUpdateCompanionBuilder,
      (SavingsGoalRow, $$SavingsGoalsTableReferences),
      SavingsGoalRow,
      PrefetchHooks Function({bool goalContributionsRefs})
    >;
typedef $$GoalContributionsTableCreateCompanionBuilder =
    GoalContributionsCompanion Function({
      required String id,
      required String goalId,
      required int amountCents,
      required DateTime date,
      Value<int> rowid,
    });
typedef $$GoalContributionsTableUpdateCompanionBuilder =
    GoalContributionsCompanion Function({
      Value<String> id,
      Value<String> goalId,
      Value<int> amountCents,
      Value<DateTime> date,
      Value<int> rowid,
    });

final class $$GoalContributionsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $GoalContributionsTable,
          GoalContributionRow
        > {
  $$GoalContributionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SavingsGoalsTable _goalIdTable(_$AppDatabase db) => db.savingsGoals
      .createAlias('goal_contributions__goal_id__savings_goals__id');

  $$SavingsGoalsTableProcessedTableManager get goalId {
    final $_column = $_itemColumn<String>('goal_id')!;

    final manager = $$SavingsGoalsTableTableManager(
      $_db,
      $_db.savingsGoals,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_goalIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$GoalContributionsTableFilterComposer
    extends Composer<_$AppDatabase, $GoalContributionsTable> {
  $$GoalContributionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  $$SavingsGoalsTableFilterComposer get goalId {
    final $$SavingsGoalsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.goalId,
      referencedTable: $db.savingsGoals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SavingsGoalsTableFilterComposer(
            $db: $db,
            $table: $db.savingsGoals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GoalContributionsTableOrderingComposer
    extends Composer<_$AppDatabase, $GoalContributionsTable> {
  $$GoalContributionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  $$SavingsGoalsTableOrderingComposer get goalId {
    final $$SavingsGoalsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.goalId,
      referencedTable: $db.savingsGoals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SavingsGoalsTableOrderingComposer(
            $db: $db,
            $table: $db.savingsGoals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GoalContributionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GoalContributionsTable> {
  $$GoalContributionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  $$SavingsGoalsTableAnnotationComposer get goalId {
    final $$SavingsGoalsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.goalId,
      referencedTable: $db.savingsGoals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SavingsGoalsTableAnnotationComposer(
            $db: $db,
            $table: $db.savingsGoals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GoalContributionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GoalContributionsTable,
          GoalContributionRow,
          $$GoalContributionsTableFilterComposer,
          $$GoalContributionsTableOrderingComposer,
          $$GoalContributionsTableAnnotationComposer,
          $$GoalContributionsTableCreateCompanionBuilder,
          $$GoalContributionsTableUpdateCompanionBuilder,
          (GoalContributionRow, $$GoalContributionsTableReferences),
          GoalContributionRow,
          PrefetchHooks Function({bool goalId})
        > {
  $$GoalContributionsTableTableManager(
    _$AppDatabase db,
    $GoalContributionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GoalContributionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GoalContributionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GoalContributionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> goalId = const Value.absent(),
                Value<int> amountCents = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GoalContributionsCompanion(
                id: id,
                goalId: goalId,
                amountCents: amountCents,
                date: date,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String goalId,
                required int amountCents,
                required DateTime date,
                Value<int> rowid = const Value.absent(),
              }) => GoalContributionsCompanion.insert(
                id: id,
                goalId: goalId,
                amountCents: amountCents,
                date: date,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$GoalContributionsTable, GoalContributionRow>(
                    table,
                  ),
                  $$GoalContributionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({goalId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (goalId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.goalId,
                        referencedTable: $$GoalContributionsTableReferences
                            ._goalIdTable(db),
                        referencedColumn: $$GoalContributionsTableReferences
                            ._goalIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$GoalContributionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GoalContributionsTable,
      GoalContributionRow,
      $$GoalContributionsTableFilterComposer,
      $$GoalContributionsTableOrderingComposer,
      $$GoalContributionsTableAnnotationComposer,
      $$GoalContributionsTableCreateCompanionBuilder,
      $$GoalContributionsTableUpdateCompanionBuilder,
      (GoalContributionRow, $$GoalContributionsTableReferences),
      GoalContributionRow,
      PrefetchHooks Function({bool goalId})
    >;
typedef $$InvestmentsTableCreateCompanionBuilder =
    InvestmentsCompanion Function({
      required String id,
      required String name,
      required InvestmentType type,
      required int investedCents,
      required int currentValueCents,
      required DateTime date,
      Value<String?> notes,
      Value<int> rowid,
    });
typedef $$InvestmentsTableUpdateCompanionBuilder =
    InvestmentsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<InvestmentType> type,
      Value<int> investedCents,
      Value<int> currentValueCents,
      Value<DateTime> date,
      Value<String?> notes,
      Value<int> rowid,
    });

class $$InvestmentsTableFilterComposer
    extends Composer<_$AppDatabase, $InvestmentsTable> {
  $$InvestmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<InvestmentType, InvestmentType, String>
  get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get investedCents => $composableBuilder(
    column: $table.investedCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentValueCents => $composableBuilder(
    column: $table.currentValueCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$InvestmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $InvestmentsTable> {
  $$InvestmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get investedCents => $composableBuilder(
    column: $table.investedCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentValueCents => $composableBuilder(
    column: $table.currentValueCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InvestmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $InvestmentsTable> {
  $$InvestmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<InvestmentType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get investedCents => $composableBuilder(
    column: $table.investedCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get currentValueCents => $composableBuilder(
    column: $table.currentValueCents,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);
}

class $$InvestmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InvestmentsTable,
          InvestmentRow,
          $$InvestmentsTableFilterComposer,
          $$InvestmentsTableOrderingComposer,
          $$InvestmentsTableAnnotationComposer,
          $$InvestmentsTableCreateCompanionBuilder,
          $$InvestmentsTableUpdateCompanionBuilder,
          (
            InvestmentRow,
            BaseReferences<_$AppDatabase, $InvestmentsTable, InvestmentRow>,
          ),
          InvestmentRow,
          PrefetchHooks Function()
        > {
  $$InvestmentsTableTableManager(_$AppDatabase db, $InvestmentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InvestmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InvestmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InvestmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<InvestmentType> type = const Value.absent(),
                Value<int> investedCents = const Value.absent(),
                Value<int> currentValueCents = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InvestmentsCompanion(
                id: id,
                name: name,
                type: type,
                investedCents: investedCents,
                currentValueCents: currentValueCents,
                date: date,
                notes: notes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required InvestmentType type,
                required int investedCents,
                required int currentValueCents,
                required DateTime date,
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InvestmentsCompanion.insert(
                id: id,
                name: name,
                type: type,
                investedCents: investedCents,
                currentValueCents: currentValueCents,
                date: date,
                notes: notes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$InvestmentsTable, InvestmentRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $InvestmentsTable,
                    InvestmentRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$InvestmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InvestmentsTable,
      InvestmentRow,
      $$InvestmentsTableFilterComposer,
      $$InvestmentsTableOrderingComposer,
      $$InvestmentsTableAnnotationComposer,
      $$InvestmentsTableCreateCompanionBuilder,
      $$InvestmentsTableUpdateCompanionBuilder,
      (
        InvestmentRow,
        BaseReferences<_$AppDatabase, $InvestmentsTable, InvestmentRow>,
      ),
      InvestmentRow,
      PrefetchHooks Function()
    >;
typedef $$FinanceSettingsTableTableCreateCompanionBuilder =
    FinanceSettingsTableCompanion Function({
      Value<int> id,
      required int savingsTargetBasisPoints,
      required int warningFromBasisPoints,
      required int criticalAboveBasisPoints,
      required int smallExpenseThresholdCents,
      Value<int> payday,
      Value<bool> dailyReminder,
      Value<int> reminderHour,
    });
typedef $$FinanceSettingsTableTableUpdateCompanionBuilder =
    FinanceSettingsTableCompanion Function({
      Value<int> id,
      Value<int> savingsTargetBasisPoints,
      Value<int> warningFromBasisPoints,
      Value<int> criticalAboveBasisPoints,
      Value<int> smallExpenseThresholdCents,
      Value<int> payday,
      Value<bool> dailyReminder,
      Value<int> reminderHour,
    });

class $$FinanceSettingsTableTableFilterComposer
    extends Composer<_$AppDatabase, $FinanceSettingsTableTable> {
  $$FinanceSettingsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get savingsTargetBasisPoints => $composableBuilder(
    column: $table.savingsTargetBasisPoints,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get warningFromBasisPoints => $composableBuilder(
    column: $table.warningFromBasisPoints,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get criticalAboveBasisPoints => $composableBuilder(
    column: $table.criticalAboveBasisPoints,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get smallExpenseThresholdCents => $composableBuilder(
    column: $table.smallExpenseThresholdCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get payday => $composableBuilder(
    column: $table.payday,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get dailyReminder => $composableBuilder(
    column: $table.dailyReminder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reminderHour => $composableBuilder(
    column: $table.reminderHour,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FinanceSettingsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $FinanceSettingsTableTable> {
  $$FinanceSettingsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get savingsTargetBasisPoints => $composableBuilder(
    column: $table.savingsTargetBasisPoints,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get warningFromBasisPoints => $composableBuilder(
    column: $table.warningFromBasisPoints,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get criticalAboveBasisPoints => $composableBuilder(
    column: $table.criticalAboveBasisPoints,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get smallExpenseThresholdCents => $composableBuilder(
    column: $table.smallExpenseThresholdCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get payday => $composableBuilder(
    column: $table.payday,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get dailyReminder => $composableBuilder(
    column: $table.dailyReminder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reminderHour => $composableBuilder(
    column: $table.reminderHour,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FinanceSettingsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $FinanceSettingsTableTable> {
  $$FinanceSettingsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get savingsTargetBasisPoints => $composableBuilder(
    column: $table.savingsTargetBasisPoints,
    builder: (column) => column,
  );

  GeneratedColumn<int> get warningFromBasisPoints => $composableBuilder(
    column: $table.warningFromBasisPoints,
    builder: (column) => column,
  );

  GeneratedColumn<int> get criticalAboveBasisPoints => $composableBuilder(
    column: $table.criticalAboveBasisPoints,
    builder: (column) => column,
  );

  GeneratedColumn<int> get smallExpenseThresholdCents => $composableBuilder(
    column: $table.smallExpenseThresholdCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get payday =>
      $composableBuilder(column: $table.payday, builder: (column) => column);

  GeneratedColumn<bool> get dailyReminder => $composableBuilder(
    column: $table.dailyReminder,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reminderHour => $composableBuilder(
    column: $table.reminderHour,
    builder: (column) => column,
  );
}

class $$FinanceSettingsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FinanceSettingsTableTable,
          SettingsRow,
          $$FinanceSettingsTableTableFilterComposer,
          $$FinanceSettingsTableTableOrderingComposer,
          $$FinanceSettingsTableTableAnnotationComposer,
          $$FinanceSettingsTableTableCreateCompanionBuilder,
          $$FinanceSettingsTableTableUpdateCompanionBuilder,
          (
            SettingsRow,
            BaseReferences<
              _$AppDatabase,
              $FinanceSettingsTableTable,
              SettingsRow
            >,
          ),
          SettingsRow,
          PrefetchHooks Function()
        > {
  $$FinanceSettingsTableTableTableManager(
    _$AppDatabase db,
    $FinanceSettingsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FinanceSettingsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FinanceSettingsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$FinanceSettingsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> savingsTargetBasisPoints = const Value.absent(),
                Value<int> warningFromBasisPoints = const Value.absent(),
                Value<int> criticalAboveBasisPoints = const Value.absent(),
                Value<int> smallExpenseThresholdCents = const Value.absent(),
                Value<int> payday = const Value.absent(),
                Value<bool> dailyReminder = const Value.absent(),
                Value<int> reminderHour = const Value.absent(),
              }) => FinanceSettingsTableCompanion(
                id: id,
                savingsTargetBasisPoints: savingsTargetBasisPoints,
                warningFromBasisPoints: warningFromBasisPoints,
                criticalAboveBasisPoints: criticalAboveBasisPoints,
                smallExpenseThresholdCents: smallExpenseThresholdCents,
                payday: payday,
                dailyReminder: dailyReminder,
                reminderHour: reminderHour,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int savingsTargetBasisPoints,
                required int warningFromBasisPoints,
                required int criticalAboveBasisPoints,
                required int smallExpenseThresholdCents,
                Value<int> payday = const Value.absent(),
                Value<bool> dailyReminder = const Value.absent(),
                Value<int> reminderHour = const Value.absent(),
              }) => FinanceSettingsTableCompanion.insert(
                id: id,
                savingsTargetBasisPoints: savingsTargetBasisPoints,
                warningFromBasisPoints: warningFromBasisPoints,
                criticalAboveBasisPoints: criticalAboveBasisPoints,
                smallExpenseThresholdCents: smallExpenseThresholdCents,
                payday: payday,
                dailyReminder: dailyReminder,
                reminderHour: reminderHour,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FinanceSettingsTableTable, SettingsRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $FinanceSettingsTableTable,
                    SettingsRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FinanceSettingsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FinanceSettingsTableTable,
      SettingsRow,
      $$FinanceSettingsTableTableFilterComposer,
      $$FinanceSettingsTableTableOrderingComposer,
      $$FinanceSettingsTableTableAnnotationComposer,
      $$FinanceSettingsTableTableCreateCompanionBuilder,
      $$FinanceSettingsTableTableUpdateCompanionBuilder,
      (
        SettingsRow,
        BaseReferences<_$AppDatabase, $FinanceSettingsTableTable, SettingsRow>,
      ),
      SettingsRow,
      PrefetchHooks Function()
    >;
typedef $$FixedMovementsTableCreateCompanionBuilder =
    FixedMovementsCompanion Function({
      required String id,
      required String name,
      required TransactionKind kind,
      required int amountCents,
      required String categoryId,
      required int dayOfMonth,
      required bool isActive,
      Value<DateTime?> lastPostedOn,
      Value<int> rowid,
    });
typedef $$FixedMovementsTableUpdateCompanionBuilder =
    FixedMovementsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<TransactionKind> kind,
      Value<int> amountCents,
      Value<String> categoryId,
      Value<int> dayOfMonth,
      Value<bool> isActive,
      Value<DateTime?> lastPostedOn,
      Value<int> rowid,
    });

final class $$FixedMovementsTableReferences
    extends
        BaseReferences<_$AppDatabase, $FixedMovementsTable, FixedMovementRow> {
  $$FixedMovementsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias('fixed_movements__category_id__categories__id');

  $$CategoriesTableProcessedTableManager get categoryId {
    final $_column = $_itemColumn<String>('category_id')!;

    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FixedMovementsTableFilterComposer
    extends Composer<_$AppDatabase, $FixedMovementsTable> {
  $$FixedMovementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TransactionKind, TransactionKind, String>
  get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dayOfMonth => $composableBuilder(
    column: $table.dayOfMonth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastPostedOn => $composableBuilder(
    column: $table.lastPostedOn,
    builder: (column) => ColumnFilters(column),
  );

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FixedMovementsTableOrderingComposer
    extends Composer<_$AppDatabase, $FixedMovementsTable> {
  $$FixedMovementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dayOfMonth => $composableBuilder(
    column: $table.dayOfMonth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastPostedOn => $composableBuilder(
    column: $table.lastPostedOn,
    builder: (column) => ColumnOrderings(column),
  );

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FixedMovementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FixedMovementsTable> {
  $$FixedMovementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TransactionKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dayOfMonth => $composableBuilder(
    column: $table.dayOfMonth,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get lastPostedOn => $composableBuilder(
    column: $table.lastPostedOn,
    builder: (column) => column,
  );

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FixedMovementsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FixedMovementsTable,
          FixedMovementRow,
          $$FixedMovementsTableFilterComposer,
          $$FixedMovementsTableOrderingComposer,
          $$FixedMovementsTableAnnotationComposer,
          $$FixedMovementsTableCreateCompanionBuilder,
          $$FixedMovementsTableUpdateCompanionBuilder,
          (FixedMovementRow, $$FixedMovementsTableReferences),
          FixedMovementRow,
          PrefetchHooks Function({bool categoryId})
        > {
  $$FixedMovementsTableTableManager(
    _$AppDatabase db,
    $FixedMovementsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FixedMovementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FixedMovementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FixedMovementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<TransactionKind> kind = const Value.absent(),
                Value<int> amountCents = const Value.absent(),
                Value<String> categoryId = const Value.absent(),
                Value<int> dayOfMonth = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime?> lastPostedOn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FixedMovementsCompanion(
                id: id,
                name: name,
                kind: kind,
                amountCents: amountCents,
                categoryId: categoryId,
                dayOfMonth: dayOfMonth,
                isActive: isActive,
                lastPostedOn: lastPostedOn,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required TransactionKind kind,
                required int amountCents,
                required String categoryId,
                required int dayOfMonth,
                required bool isActive,
                Value<DateTime?> lastPostedOn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FixedMovementsCompanion.insert(
                id: id,
                name: name,
                kind: kind,
                amountCents: amountCents,
                categoryId: categoryId,
                dayOfMonth: dayOfMonth,
                isActive: isActive,
                lastPostedOn: lastPostedOn,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FixedMovementsTable, FixedMovementRow>(table),
                  $$FixedMovementsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({categoryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (categoryId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.categoryId,
                        referencedTable: $$FixedMovementsTableReferences
                            ._categoryIdTable(db),
                        referencedColumn: $$FixedMovementsTableReferences
                            ._categoryIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$FixedMovementsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FixedMovementsTable,
      FixedMovementRow,
      $$FixedMovementsTableFilterComposer,
      $$FixedMovementsTableOrderingComposer,
      $$FixedMovementsTableAnnotationComposer,
      $$FixedMovementsTableCreateCompanionBuilder,
      $$FixedMovementsTableUpdateCompanionBuilder,
      (FixedMovementRow, $$FixedMovementsTableReferences),
      FixedMovementRow,
      PrefetchHooks Function({bool categoryId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db, _db.accounts);
  $$DebtsTableTableManager get debts =>
      $$DebtsTableTableManager(_db, _db.debts);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$BudgetLinesTableTableManager get budgetLines =>
      $$BudgetLinesTableTableManager(_db, _db.budgetLines);
  $$AssetsTableTableManager get assets =>
      $$AssetsTableTableManager(_db, _db.assets);
  $$ExtraPaymentsTableTableManager get extraPayments =>
      $$ExtraPaymentsTableTableManager(_db, _db.extraPayments);
  $$SavingsGoalsTableTableManager get savingsGoals =>
      $$SavingsGoalsTableTableManager(_db, _db.savingsGoals);
  $$GoalContributionsTableTableManager get goalContributions =>
      $$GoalContributionsTableTableManager(_db, _db.goalContributions);
  $$InvestmentsTableTableManager get investments =>
      $$InvestmentsTableTableManager(_db, _db.investments);
  $$FinanceSettingsTableTableTableManager get financeSettingsTable =>
      $$FinanceSettingsTableTableTableManager(_db, _db.financeSettingsTable);
  $$FixedMovementsTableTableManager get fixedMovements =>
      $$FixedMovementsTableTableManager(_db, _db.fixedMovements);
}
