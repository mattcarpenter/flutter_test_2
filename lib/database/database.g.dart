// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $RecipeFoldersTable extends RecipeFolders
    with TableInfo<$RecipeFoldersTable, RecipeFolderEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecipeFoldersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
      clientDefault: () => const Uuid().v4());
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _parentIdMeta =
      const VerificationMeta('parentId');
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
      'parent_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _householdIdMeta =
      const VerificationMeta('householdId');
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
      'household_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, userId, parentId, householdId, deletedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recipe_folders';
  @override
  VerificationContext validateIntegrity(Insertable<RecipeFolderEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    }
    if (data.containsKey('parent_id')) {
      context.handle(_parentIdMeta,
          parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta));
    }
    if (data.containsKey('household_id')) {
      context.handle(
          _householdIdMeta,
          householdId.isAcceptableOrUnknown(
              data['household_id']!, _householdIdMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  RecipeFolderEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecipeFolderEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id']),
      parentId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}parent_id']),
      householdId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}household_id']),
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $RecipeFoldersTable createAlias(String alias) {
    return $RecipeFoldersTable(attachedDatabase, alias);
  }
}

class RecipeFolderEntry extends DataClass
    implements Insertable<RecipeFolderEntry> {
  final String id;
  final String name;
  final String? userId;
  final String? parentId;
  final String? householdId;
  final int? deletedAt;
  const RecipeFolderEntry(
      {required this.id,
      required this.name,
      this.userId,
      this.parentId,
      this.householdId,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    if (!nullToAbsent || householdId != null) {
      map['household_id'] = Variable<String>(householdId);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  RecipeFoldersCompanion toCompanion(bool nullToAbsent) {
    return RecipeFoldersCompanion(
      id: Value(id),
      name: Value(name),
      userId:
          userId == null && nullToAbsent ? const Value.absent() : Value(userId),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      householdId: householdId == null && nullToAbsent
          ? const Value.absent()
          : Value(householdId),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory RecipeFolderEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecipeFolderEntry(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      userId: serializer.fromJson<String?>(json['userId']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      householdId: serializer.fromJson<String?>(json['householdId']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'userId': serializer.toJson<String?>(userId),
      'parentId': serializer.toJson<String?>(parentId),
      'householdId': serializer.toJson<String?>(householdId),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  RecipeFolderEntry copyWith(
          {String? id,
          String? name,
          Value<String?> userId = const Value.absent(),
          Value<String?> parentId = const Value.absent(),
          Value<String?> householdId = const Value.absent(),
          Value<int?> deletedAt = const Value.absent()}) =>
      RecipeFolderEntry(
        id: id ?? this.id,
        name: name ?? this.name,
        userId: userId.present ? userId.value : this.userId,
        parentId: parentId.present ? parentId.value : this.parentId,
        householdId: householdId.present ? householdId.value : this.householdId,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  RecipeFolderEntry copyWithCompanion(RecipeFoldersCompanion data) {
    return RecipeFolderEntry(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      userId: data.userId.present ? data.userId.value : this.userId,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      householdId:
          data.householdId.present ? data.householdId.value : this.householdId,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecipeFolderEntry(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('userId: $userId, ')
          ..write('parentId: $parentId, ')
          ..write('householdId: $householdId, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, userId, parentId, householdId, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecipeFolderEntry &&
          other.id == this.id &&
          other.name == this.name &&
          other.userId == this.userId &&
          other.parentId == this.parentId &&
          other.householdId == this.householdId &&
          other.deletedAt == this.deletedAt);
}

class RecipeFoldersCompanion extends UpdateCompanion<RecipeFolderEntry> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> userId;
  final Value<String?> parentId;
  final Value<String?> householdId;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const RecipeFoldersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.userId = const Value.absent(),
    this.parentId = const Value.absent(),
    this.householdId = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecipeFoldersCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.userId = const Value.absent(),
    this.parentId = const Value.absent(),
    this.householdId = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : name = Value(name);
  static Insertable<RecipeFolderEntry> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? userId,
    Expression<String>? parentId,
    Expression<String>? householdId,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (userId != null) 'user_id': userId,
      if (parentId != null) 'parent_id': parentId,
      if (householdId != null) 'household_id': householdId,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecipeFoldersCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String?>? userId,
      Value<String?>? parentId,
      Value<String?>? householdId,
      Value<int?>? deletedAt,
      Value<int>? rowid}) {
    return RecipeFoldersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      userId: userId ?? this.userId,
      parentId: parentId ?? this.parentId,
      householdId: householdId ?? this.householdId,
      deletedAt: deletedAt ?? this.deletedAt,
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
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecipeFoldersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('userId: $userId, ')
          ..write('parentId: $parentId, ')
          ..write('householdId: $householdId, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $RecipeFoldersTable recipeFolders = $RecipeFoldersTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [recipeFolders];
}

typedef $$RecipeFoldersTableCreateCompanionBuilder = RecipeFoldersCompanion
    Function({
  Value<String> id,
  required String name,
  Value<String?> userId,
  Value<String?> parentId,
  Value<String?> householdId,
  Value<int?> deletedAt,
  Value<int> rowid,
});
typedef $$RecipeFoldersTableUpdateCompanionBuilder = RecipeFoldersCompanion
    Function({
  Value<String> id,
  Value<String> name,
  Value<String?> userId,
  Value<String?> parentId,
  Value<String?> householdId,
  Value<int?> deletedAt,
  Value<int> rowid,
});

class $$RecipeFoldersTableFilterComposer
    extends Composer<_$AppDatabase, $RecipeFoldersTable> {
  $$RecipeFoldersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get parentId => $composableBuilder(
      column: $table.parentId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));
}

class $$RecipeFoldersTableOrderingComposer
    extends Composer<_$AppDatabase, $RecipeFoldersTable> {
  $$RecipeFoldersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get parentId => $composableBuilder(
      column: $table.parentId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));
}

class $$RecipeFoldersTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecipeFoldersTable> {
  $$RecipeFoldersTableAnnotationComposer({
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

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$RecipeFoldersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RecipeFoldersTable,
    RecipeFolderEntry,
    $$RecipeFoldersTableFilterComposer,
    $$RecipeFoldersTableOrderingComposer,
    $$RecipeFoldersTableAnnotationComposer,
    $$RecipeFoldersTableCreateCompanionBuilder,
    $$RecipeFoldersTableUpdateCompanionBuilder,
    (
      RecipeFolderEntry,
      BaseReferences<_$AppDatabase, $RecipeFoldersTable, RecipeFolderEntry>
    ),
    RecipeFolderEntry,
    PrefetchHooks Function()> {
  $$RecipeFoldersTableTableManager(_$AppDatabase db, $RecipeFoldersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecipeFoldersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecipeFoldersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecipeFoldersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> userId = const Value.absent(),
            Value<String?> parentId = const Value.absent(),
            Value<String?> householdId = const Value.absent(),
            Value<int?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RecipeFoldersCompanion(
            id: id,
            name: name,
            userId: userId,
            parentId: parentId,
            householdId: householdId,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            Value<String> id = const Value.absent(),
            required String name,
            Value<String?> userId = const Value.absent(),
            Value<String?> parentId = const Value.absent(),
            Value<String?> householdId = const Value.absent(),
            Value<int?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RecipeFoldersCompanion.insert(
            id: id,
            name: name,
            userId: userId,
            parentId: parentId,
            householdId: householdId,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RecipeFoldersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RecipeFoldersTable,
    RecipeFolderEntry,
    $$RecipeFoldersTableFilterComposer,
    $$RecipeFoldersTableOrderingComposer,
    $$RecipeFoldersTableAnnotationComposer,
    $$RecipeFoldersTableCreateCompanionBuilder,
    $$RecipeFoldersTableUpdateCompanionBuilder,
    (
      RecipeFolderEntry,
      BaseReferences<_$AppDatabase, $RecipeFoldersTable, RecipeFolderEntry>
    ),
    RecipeFolderEntry,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$RecipeFoldersTableTableManager get recipeFolders =>
      $$RecipeFoldersTableTableManager(_db, _db.recipeFolders);
}
