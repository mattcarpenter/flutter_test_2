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
      [id, name, userId, householdId, deletedAt];
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
  final String? householdId;
  final int? deletedAt;
  const RecipeFolderEntry(
      {required this.id,
      required this.name,
      this.userId,
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
      'householdId': serializer.toJson<String?>(householdId),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  RecipeFolderEntry copyWith(
          {String? id,
          String? name,
          Value<String?> userId = const Value.absent(),
          Value<String?> householdId = const Value.absent(),
          Value<int?> deletedAt = const Value.absent()}) =>
      RecipeFolderEntry(
        id: id ?? this.id,
        name: name ?? this.name,
        userId: userId.present ? userId.value : this.userId,
        householdId: householdId.present ? householdId.value : this.householdId,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  RecipeFolderEntry copyWithCompanion(RecipeFoldersCompanion data) {
    return RecipeFolderEntry(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      userId: data.userId.present ? data.userId.value : this.userId,
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
          ..write('householdId: $householdId, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, userId, householdId, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecipeFolderEntry &&
          other.id == this.id &&
          other.name == this.name &&
          other.userId == this.userId &&
          other.householdId == this.householdId &&
          other.deletedAt == this.deletedAt);
}

class RecipeFoldersCompanion extends UpdateCompanion<RecipeFolderEntry> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> userId;
  final Value<String?> householdId;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const RecipeFoldersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.userId = const Value.absent(),
    this.householdId = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecipeFoldersCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.userId = const Value.absent(),
    this.householdId = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : name = Value(name);
  static Insertable<RecipeFolderEntry> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? userId,
    Expression<String>? householdId,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (userId != null) 'user_id': userId,
      if (householdId != null) 'household_id': householdId,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecipeFoldersCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String?>? userId,
      Value<String?>? householdId,
      Value<int?>? deletedAt,
      Value<int>? rowid}) {
    return RecipeFoldersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      userId: userId ?? this.userId,
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
          ..write('householdId: $householdId, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecipesTable extends Recipes with TableInfo<$RecipesTable, RecipeEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecipesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
      clientDefault: () => const Uuid().v4());
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<int> rating = GeneratedColumn<int>(
      'rating', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _languageMeta =
      const VerificationMeta('language');
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
      'language', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _servingsMeta =
      const VerificationMeta('servings');
  @override
  late final GeneratedColumn<int> servings = GeneratedColumn<int>(
      'servings', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _prepTimeMeta =
      const VerificationMeta('prepTime');
  @override
  late final GeneratedColumn<int> prepTime = GeneratedColumn<int>(
      'prep_time', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _cookTimeMeta =
      const VerificationMeta('cookTime');
  @override
  late final GeneratedColumn<int> cookTime = GeneratedColumn<int>(
      'cook_time', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _totalTimeMeta =
      const VerificationMeta('totalTime');
  @override
  late final GeneratedColumn<int> totalTime = GeneratedColumn<int>(
      'total_time', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _nutritionMeta =
      const VerificationMeta('nutrition');
  @override
  late final GeneratedColumn<String> nutrition = GeneratedColumn<String>(
      'nutrition', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _generalNotesMeta =
      const VerificationMeta('generalNotes');
  @override
  late final GeneratedColumn<String> generalNotes = GeneratedColumn<String>(
      'general_notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _householdIdMeta =
      const VerificationMeta('householdId');
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
      'household_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _ingredientsMeta =
      const VerificationMeta('ingredients');
  @override
  late final GeneratedColumnWithTypeConverter<List<Ingredient>?, String>
      ingredients = GeneratedColumn<String>('ingredients', aliasedName, true,
              type: DriftSqlType.string, requiredDuringInsert: false)
          .withConverter<List<Ingredient>?>(
              $RecipesTable.$converteringredientsn);
  static const VerificationMeta _stepsMeta = const VerificationMeta('steps');
  @override
  late final GeneratedColumnWithTypeConverter<List<Step>?, String> steps =
      GeneratedColumn<String>('steps', aliasedName, true,
              type: DriftSqlType.string, requiredDuringInsert: false)
          .withConverter<List<Step>?>($RecipesTable.$converterstepsn);
  static const VerificationMeta _folderIdsMeta =
      const VerificationMeta('folderIds');
  @override
  late final GeneratedColumnWithTypeConverter<List<String>?, String> folderIds =
      GeneratedColumn<String>('folder_ids', aliasedName, true,
              type: DriftSqlType.string, requiredDuringInsert: false)
          .withConverter<List<String>?>($RecipesTable.$converterfolderIdsn);
  static const VerificationMeta _imagesMeta = const VerificationMeta('images');
  @override
  late final GeneratedColumnWithTypeConverter<List<RecipeImage>?, String>
      images = GeneratedColumn<String>('images', aliasedName, true,
              type: DriftSqlType.string, requiredDuringInsert: false)
          .withConverter<List<RecipeImage>?>($RecipesTable.$converterimagesn);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        description,
        rating,
        language,
        servings,
        prepTime,
        cookTime,
        totalTime,
        source,
        nutrition,
        generalNotes,
        userId,
        householdId,
        createdAt,
        updatedAt,
        deletedAt,
        ingredients,
        steps,
        folderIds,
        images
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recipes';
  @override
  VerificationContext validateIntegrity(Insertable<RecipeEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('rating')) {
      context.handle(_ratingMeta,
          rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta));
    }
    if (data.containsKey('language')) {
      context.handle(_languageMeta,
          language.isAcceptableOrUnknown(data['language']!, _languageMeta));
    } else if (isInserting) {
      context.missing(_languageMeta);
    }
    if (data.containsKey('servings')) {
      context.handle(_servingsMeta,
          servings.isAcceptableOrUnknown(data['servings']!, _servingsMeta));
    }
    if (data.containsKey('prep_time')) {
      context.handle(_prepTimeMeta,
          prepTime.isAcceptableOrUnknown(data['prep_time']!, _prepTimeMeta));
    }
    if (data.containsKey('cook_time')) {
      context.handle(_cookTimeMeta,
          cookTime.isAcceptableOrUnknown(data['cook_time']!, _cookTimeMeta));
    }
    if (data.containsKey('total_time')) {
      context.handle(_totalTimeMeta,
          totalTime.isAcceptableOrUnknown(data['total_time']!, _totalTimeMeta));
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    }
    if (data.containsKey('nutrition')) {
      context.handle(_nutritionMeta,
          nutrition.isAcceptableOrUnknown(data['nutrition']!, _nutritionMeta));
    }
    if (data.containsKey('general_notes')) {
      context.handle(
          _generalNotesMeta,
          generalNotes.isAcceptableOrUnknown(
              data['general_notes']!, _generalNotesMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('household_id')) {
      context.handle(
          _householdIdMeta,
          householdId.isAcceptableOrUnknown(
              data['household_id']!, _householdIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    context.handle(_ingredientsMeta, const VerificationResult.success());
    context.handle(_stepsMeta, const VerificationResult.success());
    context.handle(_folderIdsMeta, const VerificationResult.success());
    context.handle(_imagesMeta, const VerificationResult.success());
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecipeEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecipeEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      rating: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}rating']),
      language: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}language'])!,
      servings: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}servings']),
      prepTime: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}prep_time']),
      cookTime: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}cook_time']),
      totalTime: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_time']),
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source']),
      nutrition: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}nutrition']),
      generalNotes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}general_notes']),
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      householdId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}household_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at']),
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}deleted_at']),
      ingredients: $RecipesTable.$converteringredientsn.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ingredients'])),
      steps: $RecipesTable.$converterstepsn.fromSql(attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}steps'])),
      folderIds: $RecipesTable.$converterfolderIdsn.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}folder_ids'])),
      images: $RecipesTable.$converterimagesn.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}images'])),
    );
  }

  @override
  $RecipesTable createAlias(String alias) {
    return $RecipesTable(attachedDatabase, alias);
  }

  static TypeConverter<List<Ingredient>, String> $converteringredients =
      const IngredientListConverter();
  static TypeConverter<List<Ingredient>?, String?> $converteringredientsn =
      NullAwareTypeConverter.wrap($converteringredients);
  static TypeConverter<List<Step>, String> $convertersteps =
      const StepListConverter();
  static TypeConverter<List<Step>?, String?> $converterstepsn =
      NullAwareTypeConverter.wrap($convertersteps);
  static TypeConverter<List<String>, String> $converterfolderIds =
      StringListTypeConverter();
  static TypeConverter<List<String>?, String?> $converterfolderIdsn =
      NullAwareTypeConverter.wrap($converterfolderIds);
  static TypeConverter<List<RecipeImage>, String> $converterimages =
      const RecipeImageListConverter();
  static TypeConverter<List<RecipeImage>?, String?> $converterimagesn =
      NullAwareTypeConverter.wrap($converterimages);
}

class RecipeEntry extends DataClass implements Insertable<RecipeEntry> {
  final String id;
  final String title;
  final String? description;
  final int? rating;
  final String language;
  final int? servings;
  final int? prepTime;
  final int? cookTime;
  final int? totalTime;
  final String? source;
  final String? nutrition;
  final String? generalNotes;
  final String userId;
  final String? householdId;
  final int? createdAt;
  final int? updatedAt;
  final int? deletedAt;
  final List<Ingredient>? ingredients;
  final List<Step>? steps;
  final List<String>? folderIds;
  final List<RecipeImage>? images;
  const RecipeEntry(
      {required this.id,
      required this.title,
      this.description,
      this.rating,
      required this.language,
      this.servings,
      this.prepTime,
      this.cookTime,
      this.totalTime,
      this.source,
      this.nutrition,
      this.generalNotes,
      required this.userId,
      this.householdId,
      this.createdAt,
      this.updatedAt,
      this.deletedAt,
      this.ingredients,
      this.steps,
      this.folderIds,
      this.images});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || rating != null) {
      map['rating'] = Variable<int>(rating);
    }
    map['language'] = Variable<String>(language);
    if (!nullToAbsent || servings != null) {
      map['servings'] = Variable<int>(servings);
    }
    if (!nullToAbsent || prepTime != null) {
      map['prep_time'] = Variable<int>(prepTime);
    }
    if (!nullToAbsent || cookTime != null) {
      map['cook_time'] = Variable<int>(cookTime);
    }
    if (!nullToAbsent || totalTime != null) {
      map['total_time'] = Variable<int>(totalTime);
    }
    if (!nullToAbsent || source != null) {
      map['source'] = Variable<String>(source);
    }
    if (!nullToAbsent || nutrition != null) {
      map['nutrition'] = Variable<String>(nutrition);
    }
    if (!nullToAbsent || generalNotes != null) {
      map['general_notes'] = Variable<String>(generalNotes);
    }
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || householdId != null) {
      map['household_id'] = Variable<String>(householdId);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<int>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<int>(updatedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    if (!nullToAbsent || ingredients != null) {
      map['ingredients'] = Variable<String>(
          $RecipesTable.$converteringredientsn.toSql(ingredients));
    }
    if (!nullToAbsent || steps != null) {
      map['steps'] =
          Variable<String>($RecipesTable.$converterstepsn.toSql(steps));
    }
    if (!nullToAbsent || folderIds != null) {
      map['folder_ids'] =
          Variable<String>($RecipesTable.$converterfolderIdsn.toSql(folderIds));
    }
    if (!nullToAbsent || images != null) {
      map['images'] =
          Variable<String>($RecipesTable.$converterimagesn.toSql(images));
    }
    return map;
  }

  RecipesCompanion toCompanion(bool nullToAbsent) {
    return RecipesCompanion(
      id: Value(id),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      rating:
          rating == null && nullToAbsent ? const Value.absent() : Value(rating),
      language: Value(language),
      servings: servings == null && nullToAbsent
          ? const Value.absent()
          : Value(servings),
      prepTime: prepTime == null && nullToAbsent
          ? const Value.absent()
          : Value(prepTime),
      cookTime: cookTime == null && nullToAbsent
          ? const Value.absent()
          : Value(cookTime),
      totalTime: totalTime == null && nullToAbsent
          ? const Value.absent()
          : Value(totalTime),
      source:
          source == null && nullToAbsent ? const Value.absent() : Value(source),
      nutrition: nutrition == null && nullToAbsent
          ? const Value.absent()
          : Value(nutrition),
      generalNotes: generalNotes == null && nullToAbsent
          ? const Value.absent()
          : Value(generalNotes),
      userId: Value(userId),
      householdId: householdId == null && nullToAbsent
          ? const Value.absent()
          : Value(householdId),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      ingredients: ingredients == null && nullToAbsent
          ? const Value.absent()
          : Value(ingredients),
      steps:
          steps == null && nullToAbsent ? const Value.absent() : Value(steps),
      folderIds: folderIds == null && nullToAbsent
          ? const Value.absent()
          : Value(folderIds),
      images:
          images == null && nullToAbsent ? const Value.absent() : Value(images),
    );
  }

  factory RecipeEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecipeEntry(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      rating: serializer.fromJson<int?>(json['rating']),
      language: serializer.fromJson<String>(json['language']),
      servings: serializer.fromJson<int?>(json['servings']),
      prepTime: serializer.fromJson<int?>(json['prepTime']),
      cookTime: serializer.fromJson<int?>(json['cookTime']),
      totalTime: serializer.fromJson<int?>(json['totalTime']),
      source: serializer.fromJson<String?>(json['source']),
      nutrition: serializer.fromJson<String?>(json['nutrition']),
      generalNotes: serializer.fromJson<String?>(json['generalNotes']),
      userId: serializer.fromJson<String>(json['userId']),
      householdId: serializer.fromJson<String?>(json['householdId']),
      createdAt: serializer.fromJson<int?>(json['createdAt']),
      updatedAt: serializer.fromJson<int?>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      ingredients: serializer.fromJson<List<Ingredient>?>(json['ingredients']),
      steps: serializer.fromJson<List<Step>?>(json['steps']),
      folderIds: serializer.fromJson<List<String>?>(json['folderIds']),
      images: serializer.fromJson<List<RecipeImage>?>(json['images']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'rating': serializer.toJson<int?>(rating),
      'language': serializer.toJson<String>(language),
      'servings': serializer.toJson<int?>(servings),
      'prepTime': serializer.toJson<int?>(prepTime),
      'cookTime': serializer.toJson<int?>(cookTime),
      'totalTime': serializer.toJson<int?>(totalTime),
      'source': serializer.toJson<String?>(source),
      'nutrition': serializer.toJson<String?>(nutrition),
      'generalNotes': serializer.toJson<String?>(generalNotes),
      'userId': serializer.toJson<String>(userId),
      'householdId': serializer.toJson<String?>(householdId),
      'createdAt': serializer.toJson<int?>(createdAt),
      'updatedAt': serializer.toJson<int?>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'ingredients': serializer.toJson<List<Ingredient>?>(ingredients),
      'steps': serializer.toJson<List<Step>?>(steps),
      'folderIds': serializer.toJson<List<String>?>(folderIds),
      'images': serializer.toJson<List<RecipeImage>?>(images),
    };
  }

  RecipeEntry copyWith(
          {String? id,
          String? title,
          Value<String?> description = const Value.absent(),
          Value<int?> rating = const Value.absent(),
          String? language,
          Value<int?> servings = const Value.absent(),
          Value<int?> prepTime = const Value.absent(),
          Value<int?> cookTime = const Value.absent(),
          Value<int?> totalTime = const Value.absent(),
          Value<String?> source = const Value.absent(),
          Value<String?> nutrition = const Value.absent(),
          Value<String?> generalNotes = const Value.absent(),
          String? userId,
          Value<String?> householdId = const Value.absent(),
          Value<int?> createdAt = const Value.absent(),
          Value<int?> updatedAt = const Value.absent(),
          Value<int?> deletedAt = const Value.absent(),
          Value<List<Ingredient>?> ingredients = const Value.absent(),
          Value<List<Step>?> steps = const Value.absent(),
          Value<List<String>?> folderIds = const Value.absent(),
          Value<List<RecipeImage>?> images = const Value.absent()}) =>
      RecipeEntry(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description.present ? description.value : this.description,
        rating: rating.present ? rating.value : this.rating,
        language: language ?? this.language,
        servings: servings.present ? servings.value : this.servings,
        prepTime: prepTime.present ? prepTime.value : this.prepTime,
        cookTime: cookTime.present ? cookTime.value : this.cookTime,
        totalTime: totalTime.present ? totalTime.value : this.totalTime,
        source: source.present ? source.value : this.source,
        nutrition: nutrition.present ? nutrition.value : this.nutrition,
        generalNotes:
            generalNotes.present ? generalNotes.value : this.generalNotes,
        userId: userId ?? this.userId,
        householdId: householdId.present ? householdId.value : this.householdId,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        ingredients: ingredients.present ? ingredients.value : this.ingredients,
        steps: steps.present ? steps.value : this.steps,
        folderIds: folderIds.present ? folderIds.value : this.folderIds,
        images: images.present ? images.value : this.images,
      );
  RecipeEntry copyWithCompanion(RecipesCompanion data) {
    return RecipeEntry(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      description:
          data.description.present ? data.description.value : this.description,
      rating: data.rating.present ? data.rating.value : this.rating,
      language: data.language.present ? data.language.value : this.language,
      servings: data.servings.present ? data.servings.value : this.servings,
      prepTime: data.prepTime.present ? data.prepTime.value : this.prepTime,
      cookTime: data.cookTime.present ? data.cookTime.value : this.cookTime,
      totalTime: data.totalTime.present ? data.totalTime.value : this.totalTime,
      source: data.source.present ? data.source.value : this.source,
      nutrition: data.nutrition.present ? data.nutrition.value : this.nutrition,
      generalNotes: data.generalNotes.present
          ? data.generalNotes.value
          : this.generalNotes,
      userId: data.userId.present ? data.userId.value : this.userId,
      householdId:
          data.householdId.present ? data.householdId.value : this.householdId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      ingredients:
          data.ingredients.present ? data.ingredients.value : this.ingredients,
      steps: data.steps.present ? data.steps.value : this.steps,
      folderIds: data.folderIds.present ? data.folderIds.value : this.folderIds,
      images: data.images.present ? data.images.value : this.images,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecipeEntry(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('rating: $rating, ')
          ..write('language: $language, ')
          ..write('servings: $servings, ')
          ..write('prepTime: $prepTime, ')
          ..write('cookTime: $cookTime, ')
          ..write('totalTime: $totalTime, ')
          ..write('source: $source, ')
          ..write('nutrition: $nutrition, ')
          ..write('generalNotes: $generalNotes, ')
          ..write('userId: $userId, ')
          ..write('householdId: $householdId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('ingredients: $ingredients, ')
          ..write('steps: $steps, ')
          ..write('folderIds: $folderIds, ')
          ..write('images: $images')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        title,
        description,
        rating,
        language,
        servings,
        prepTime,
        cookTime,
        totalTime,
        source,
        nutrition,
        generalNotes,
        userId,
        householdId,
        createdAt,
        updatedAt,
        deletedAt,
        ingredients,
        steps,
        folderIds,
        images
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecipeEntry &&
          other.id == this.id &&
          other.title == this.title &&
          other.description == this.description &&
          other.rating == this.rating &&
          other.language == this.language &&
          other.servings == this.servings &&
          other.prepTime == this.prepTime &&
          other.cookTime == this.cookTime &&
          other.totalTime == this.totalTime &&
          other.source == this.source &&
          other.nutrition == this.nutrition &&
          other.generalNotes == this.generalNotes &&
          other.userId == this.userId &&
          other.householdId == this.householdId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.ingredients == this.ingredients &&
          other.steps == this.steps &&
          other.folderIds == this.folderIds &&
          other.images == this.images);
}

class RecipesCompanion extends UpdateCompanion<RecipeEntry> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> description;
  final Value<int?> rating;
  final Value<String> language;
  final Value<int?> servings;
  final Value<int?> prepTime;
  final Value<int?> cookTime;
  final Value<int?> totalTime;
  final Value<String?> source;
  final Value<String?> nutrition;
  final Value<String?> generalNotes;
  final Value<String> userId;
  final Value<String?> householdId;
  final Value<int?> createdAt;
  final Value<int?> updatedAt;
  final Value<int?> deletedAt;
  final Value<List<Ingredient>?> ingredients;
  final Value<List<Step>?> steps;
  final Value<List<String>?> folderIds;
  final Value<List<RecipeImage>?> images;
  final Value<int> rowid;
  const RecipesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.rating = const Value.absent(),
    this.language = const Value.absent(),
    this.servings = const Value.absent(),
    this.prepTime = const Value.absent(),
    this.cookTime = const Value.absent(),
    this.totalTime = const Value.absent(),
    this.source = const Value.absent(),
    this.nutrition = const Value.absent(),
    this.generalNotes = const Value.absent(),
    this.userId = const Value.absent(),
    this.householdId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.ingredients = const Value.absent(),
    this.steps = const Value.absent(),
    this.folderIds = const Value.absent(),
    this.images = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecipesCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.description = const Value.absent(),
    this.rating = const Value.absent(),
    required String language,
    this.servings = const Value.absent(),
    this.prepTime = const Value.absent(),
    this.cookTime = const Value.absent(),
    this.totalTime = const Value.absent(),
    this.source = const Value.absent(),
    this.nutrition = const Value.absent(),
    this.generalNotes = const Value.absent(),
    required String userId,
    this.householdId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.ingredients = const Value.absent(),
    this.steps = const Value.absent(),
    this.folderIds = const Value.absent(),
    this.images = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : title = Value(title),
        language = Value(language),
        userId = Value(userId);
  static Insertable<RecipeEntry> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? description,
    Expression<int>? rating,
    Expression<String>? language,
    Expression<int>? servings,
    Expression<int>? prepTime,
    Expression<int>? cookTime,
    Expression<int>? totalTime,
    Expression<String>? source,
    Expression<String>? nutrition,
    Expression<String>? generalNotes,
    Expression<String>? userId,
    Expression<String>? householdId,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? ingredients,
    Expression<String>? steps,
    Expression<String>? folderIds,
    Expression<String>? images,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (rating != null) 'rating': rating,
      if (language != null) 'language': language,
      if (servings != null) 'servings': servings,
      if (prepTime != null) 'prep_time': prepTime,
      if (cookTime != null) 'cook_time': cookTime,
      if (totalTime != null) 'total_time': totalTime,
      if (source != null) 'source': source,
      if (nutrition != null) 'nutrition': nutrition,
      if (generalNotes != null) 'general_notes': generalNotes,
      if (userId != null) 'user_id': userId,
      if (householdId != null) 'household_id': householdId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (ingredients != null) 'ingredients': ingredients,
      if (steps != null) 'steps': steps,
      if (folderIds != null) 'folder_ids': folderIds,
      if (images != null) 'images': images,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecipesCompanion copyWith(
      {Value<String>? id,
      Value<String>? title,
      Value<String?>? description,
      Value<int?>? rating,
      Value<String>? language,
      Value<int?>? servings,
      Value<int?>? prepTime,
      Value<int?>? cookTime,
      Value<int?>? totalTime,
      Value<String?>? source,
      Value<String?>? nutrition,
      Value<String?>? generalNotes,
      Value<String>? userId,
      Value<String?>? householdId,
      Value<int?>? createdAt,
      Value<int?>? updatedAt,
      Value<int?>? deletedAt,
      Value<List<Ingredient>?>? ingredients,
      Value<List<Step>?>? steps,
      Value<List<String>?>? folderIds,
      Value<List<RecipeImage>?>? images,
      Value<int>? rowid}) {
    return RecipesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      rating: rating ?? this.rating,
      language: language ?? this.language,
      servings: servings ?? this.servings,
      prepTime: prepTime ?? this.prepTime,
      cookTime: cookTime ?? this.cookTime,
      totalTime: totalTime ?? this.totalTime,
      source: source ?? this.source,
      nutrition: nutrition ?? this.nutrition,
      generalNotes: generalNotes ?? this.generalNotes,
      userId: userId ?? this.userId,
      householdId: householdId ?? this.householdId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
      folderIds: folderIds ?? this.folderIds,
      images: images ?? this.images,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (rating.present) {
      map['rating'] = Variable<int>(rating.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (servings.present) {
      map['servings'] = Variable<int>(servings.value);
    }
    if (prepTime.present) {
      map['prep_time'] = Variable<int>(prepTime.value);
    }
    if (cookTime.present) {
      map['cook_time'] = Variable<int>(cookTime.value);
    }
    if (totalTime.present) {
      map['total_time'] = Variable<int>(totalTime.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (nutrition.present) {
      map['nutrition'] = Variable<String>(nutrition.value);
    }
    if (generalNotes.present) {
      map['general_notes'] = Variable<String>(generalNotes.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (ingredients.present) {
      map['ingredients'] = Variable<String>(
          $RecipesTable.$converteringredientsn.toSql(ingredients.value));
    }
    if (steps.present) {
      map['steps'] =
          Variable<String>($RecipesTable.$converterstepsn.toSql(steps.value));
    }
    if (folderIds.present) {
      map['folder_ids'] = Variable<String>(
          $RecipesTable.$converterfolderIdsn.toSql(folderIds.value));
    }
    if (images.present) {
      map['images'] =
          Variable<String>($RecipesTable.$converterimagesn.toSql(images.value));
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecipesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('rating: $rating, ')
          ..write('language: $language, ')
          ..write('servings: $servings, ')
          ..write('prepTime: $prepTime, ')
          ..write('cookTime: $cookTime, ')
          ..write('totalTime: $totalTime, ')
          ..write('source: $source, ')
          ..write('nutrition: $nutrition, ')
          ..write('generalNotes: $generalNotes, ')
          ..write('userId: $userId, ')
          ..write('householdId: $householdId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('ingredients: $ingredients, ')
          ..write('steps: $steps, ')
          ..write('folderIds: $folderIds, ')
          ..write('images: $images, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecipeSharesTable extends RecipeShares
    with TableInfo<$RecipeSharesTable, RecipeShareEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecipeSharesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
      clientDefault: () => const Uuid().v4());
  static const VerificationMeta _recipeIdMeta =
      const VerificationMeta('recipeId');
  @override
  late final GeneratedColumn<String> recipeId = GeneratedColumn<String>(
      'recipe_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _householdIdMeta =
      const VerificationMeta('householdId');
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
      'household_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _canEditMeta =
      const VerificationMeta('canEdit');
  @override
  late final GeneratedColumn<int> canEdit = GeneratedColumn<int>(
      'can_edit', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns =>
      [id, recipeId, householdId, userId, canEdit];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recipe_shares';
  @override
  VerificationContext validateIntegrity(Insertable<RecipeShareEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('recipe_id')) {
      context.handle(_recipeIdMeta,
          recipeId.isAcceptableOrUnknown(data['recipe_id']!, _recipeIdMeta));
    } else if (isInserting) {
      context.missing(_recipeIdMeta);
    }
    if (data.containsKey('household_id')) {
      context.handle(
          _householdIdMeta,
          householdId.isAcceptableOrUnknown(
              data['household_id']!, _householdIdMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    }
    if (data.containsKey('can_edit')) {
      context.handle(_canEditMeta,
          canEdit.isAcceptableOrUnknown(data['can_edit']!, _canEditMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  RecipeShareEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecipeShareEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      recipeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}recipe_id'])!,
      householdId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}household_id']),
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id']),
      canEdit: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}can_edit'])!,
    );
  }

  @override
  $RecipeSharesTable createAlias(String alias) {
    return $RecipeSharesTable(attachedDatabase, alias);
  }
}

class RecipeShareEntry extends DataClass
    implements Insertable<RecipeShareEntry> {
  final String id;
  final String recipeId;
  final String? householdId;
  final String? userId;
  final int canEdit;
  const RecipeShareEntry(
      {required this.id,
      required this.recipeId,
      this.householdId,
      this.userId,
      required this.canEdit});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['recipe_id'] = Variable<String>(recipeId);
    if (!nullToAbsent || householdId != null) {
      map['household_id'] = Variable<String>(householdId);
    }
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    map['can_edit'] = Variable<int>(canEdit);
    return map;
  }

  RecipeSharesCompanion toCompanion(bool nullToAbsent) {
    return RecipeSharesCompanion(
      id: Value(id),
      recipeId: Value(recipeId),
      householdId: householdId == null && nullToAbsent
          ? const Value.absent()
          : Value(householdId),
      userId:
          userId == null && nullToAbsent ? const Value.absent() : Value(userId),
      canEdit: Value(canEdit),
    );
  }

  factory RecipeShareEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecipeShareEntry(
      id: serializer.fromJson<String>(json['id']),
      recipeId: serializer.fromJson<String>(json['recipeId']),
      householdId: serializer.fromJson<String?>(json['householdId']),
      userId: serializer.fromJson<String?>(json['userId']),
      canEdit: serializer.fromJson<int>(json['canEdit']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'recipeId': serializer.toJson<String>(recipeId),
      'householdId': serializer.toJson<String?>(householdId),
      'userId': serializer.toJson<String?>(userId),
      'canEdit': serializer.toJson<int>(canEdit),
    };
  }

  RecipeShareEntry copyWith(
          {String? id,
          String? recipeId,
          Value<String?> householdId = const Value.absent(),
          Value<String?> userId = const Value.absent(),
          int? canEdit}) =>
      RecipeShareEntry(
        id: id ?? this.id,
        recipeId: recipeId ?? this.recipeId,
        householdId: householdId.present ? householdId.value : this.householdId,
        userId: userId.present ? userId.value : this.userId,
        canEdit: canEdit ?? this.canEdit,
      );
  RecipeShareEntry copyWithCompanion(RecipeSharesCompanion data) {
    return RecipeShareEntry(
      id: data.id.present ? data.id.value : this.id,
      recipeId: data.recipeId.present ? data.recipeId.value : this.recipeId,
      householdId:
          data.householdId.present ? data.householdId.value : this.householdId,
      userId: data.userId.present ? data.userId.value : this.userId,
      canEdit: data.canEdit.present ? data.canEdit.value : this.canEdit,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecipeShareEntry(')
          ..write('id: $id, ')
          ..write('recipeId: $recipeId, ')
          ..write('householdId: $householdId, ')
          ..write('userId: $userId, ')
          ..write('canEdit: $canEdit')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, recipeId, householdId, userId, canEdit);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecipeShareEntry &&
          other.id == this.id &&
          other.recipeId == this.recipeId &&
          other.householdId == this.householdId &&
          other.userId == this.userId &&
          other.canEdit == this.canEdit);
}

class RecipeSharesCompanion extends UpdateCompanion<RecipeShareEntry> {
  final Value<String> id;
  final Value<String> recipeId;
  final Value<String?> householdId;
  final Value<String?> userId;
  final Value<int> canEdit;
  final Value<int> rowid;
  const RecipeSharesCompanion({
    this.id = const Value.absent(),
    this.recipeId = const Value.absent(),
    this.householdId = const Value.absent(),
    this.userId = const Value.absent(),
    this.canEdit = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecipeSharesCompanion.insert({
    this.id = const Value.absent(),
    required String recipeId,
    this.householdId = const Value.absent(),
    this.userId = const Value.absent(),
    this.canEdit = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : recipeId = Value(recipeId);
  static Insertable<RecipeShareEntry> custom({
    Expression<String>? id,
    Expression<String>? recipeId,
    Expression<String>? householdId,
    Expression<String>? userId,
    Expression<int>? canEdit,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (recipeId != null) 'recipe_id': recipeId,
      if (householdId != null) 'household_id': householdId,
      if (userId != null) 'user_id': userId,
      if (canEdit != null) 'can_edit': canEdit,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecipeSharesCompanion copyWith(
      {Value<String>? id,
      Value<String>? recipeId,
      Value<String?>? householdId,
      Value<String?>? userId,
      Value<int>? canEdit,
      Value<int>? rowid}) {
    return RecipeSharesCompanion(
      id: id ?? this.id,
      recipeId: recipeId ?? this.recipeId,
      householdId: householdId ?? this.householdId,
      userId: userId ?? this.userId,
      canEdit: canEdit ?? this.canEdit,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (recipeId.present) {
      map['recipe_id'] = Variable<String>(recipeId.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (canEdit.present) {
      map['can_edit'] = Variable<int>(canEdit.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecipeSharesCompanion(')
          ..write('id: $id, ')
          ..write('recipeId: $recipeId, ')
          ..write('householdId: $householdId, ')
          ..write('userId: $userId, ')
          ..write('canEdit: $canEdit, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HouseholdMembersTable extends HouseholdMembers
    with TableInfo<$HouseholdMembersTable, HouseholdMemberEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HouseholdMembersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
      clientDefault: () => const Uuid().v4());
  static const VerificationMeta _householdIdMeta =
      const VerificationMeta('householdId');
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
      'household_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<int> isActive = GeneratedColumn<int>(
      'is_active', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  @override
  List<GeneratedColumn> get $columns => [id, householdId, userId, isActive];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'household_members';
  @override
  VerificationContext validateIntegrity(
      Insertable<HouseholdMemberEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('household_id')) {
      context.handle(
          _householdIdMeta,
          householdId.isAcceptableOrUnknown(
              data['household_id']!, _householdIdMeta));
    } else if (isInserting) {
      context.missing(_householdIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {householdId, userId};
  @override
  HouseholdMemberEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HouseholdMemberEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      householdId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}household_id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}is_active'])!,
    );
  }

  @override
  $HouseholdMembersTable createAlias(String alias) {
    return $HouseholdMembersTable(attachedDatabase, alias);
  }
}

class HouseholdMemberEntry extends DataClass
    implements Insertable<HouseholdMemberEntry> {
  final String id;
  final String householdId;
  final String userId;
  final int isActive;
  const HouseholdMemberEntry(
      {required this.id,
      required this.householdId,
      required this.userId,
      required this.isActive});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['household_id'] = Variable<String>(householdId);
    map['user_id'] = Variable<String>(userId);
    map['is_active'] = Variable<int>(isActive);
    return map;
  }

  HouseholdMembersCompanion toCompanion(bool nullToAbsent) {
    return HouseholdMembersCompanion(
      id: Value(id),
      householdId: Value(householdId),
      userId: Value(userId),
      isActive: Value(isActive),
    );
  }

  factory HouseholdMemberEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HouseholdMemberEntry(
      id: serializer.fromJson<String>(json['id']),
      householdId: serializer.fromJson<String>(json['householdId']),
      userId: serializer.fromJson<String>(json['userId']),
      isActive: serializer.fromJson<int>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'householdId': serializer.toJson<String>(householdId),
      'userId': serializer.toJson<String>(userId),
      'isActive': serializer.toJson<int>(isActive),
    };
  }

  HouseholdMemberEntry copyWith(
          {String? id, String? householdId, String? userId, int? isActive}) =>
      HouseholdMemberEntry(
        id: id ?? this.id,
        householdId: householdId ?? this.householdId,
        userId: userId ?? this.userId,
        isActive: isActive ?? this.isActive,
      );
  HouseholdMemberEntry copyWithCompanion(HouseholdMembersCompanion data) {
    return HouseholdMemberEntry(
      id: data.id.present ? data.id.value : this.id,
      householdId:
          data.householdId.present ? data.householdId.value : this.householdId,
      userId: data.userId.present ? data.userId.value : this.userId,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HouseholdMemberEntry(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('userId: $userId, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, householdId, userId, isActive);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HouseholdMemberEntry &&
          other.id == this.id &&
          other.householdId == this.householdId &&
          other.userId == this.userId &&
          other.isActive == this.isActive);
}

class HouseholdMembersCompanion extends UpdateCompanion<HouseholdMemberEntry> {
  final Value<String> id;
  final Value<String> householdId;
  final Value<String> userId;
  final Value<int> isActive;
  final Value<int> rowid;
  const HouseholdMembersCompanion({
    this.id = const Value.absent(),
    this.householdId = const Value.absent(),
    this.userId = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HouseholdMembersCompanion.insert({
    this.id = const Value.absent(),
    required String householdId,
    required String userId,
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : householdId = Value(householdId),
        userId = Value(userId);
  static Insertable<HouseholdMemberEntry> custom({
    Expression<String>? id,
    Expression<String>? householdId,
    Expression<String>? userId,
    Expression<int>? isActive,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (householdId != null) 'household_id': householdId,
      if (userId != null) 'user_id': userId,
      if (isActive != null) 'is_active': isActive,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HouseholdMembersCompanion copyWith(
      {Value<String>? id,
      Value<String>? householdId,
      Value<String>? userId,
      Value<int>? isActive,
      Value<int>? rowid}) {
    return HouseholdMembersCompanion(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      userId: userId ?? this.userId,
      isActive: isActive ?? this.isActive,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<int>(isActive.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HouseholdMembersCompanion(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('userId: $userId, ')
          ..write('isActive: $isActive, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HouseholdsTable extends Households
    with TableInfo<$HouseholdsTable, HouseholdEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HouseholdsTable(this.attachedDatabase, [this._alias]);
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
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, name, userId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'households';
  @override
  VerificationContext validateIntegrity(Insertable<HouseholdEntry> instance,
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
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  HouseholdEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HouseholdEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
    );
  }

  @override
  $HouseholdsTable createAlias(String alias) {
    return $HouseholdsTable(attachedDatabase, alias);
  }
}

class HouseholdEntry extends DataClass implements Insertable<HouseholdEntry> {
  final String id;
  final String name;
  final String userId;
  const HouseholdEntry(
      {required this.id, required this.name, required this.userId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['user_id'] = Variable<String>(userId);
    return map;
  }

  HouseholdsCompanion toCompanion(bool nullToAbsent) {
    return HouseholdsCompanion(
      id: Value(id),
      name: Value(name),
      userId: Value(userId),
    );
  }

  factory HouseholdEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HouseholdEntry(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      userId: serializer.fromJson<String>(json['userId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'userId': serializer.toJson<String>(userId),
    };
  }

  HouseholdEntry copyWith({String? id, String? name, String? userId}) =>
      HouseholdEntry(
        id: id ?? this.id,
        name: name ?? this.name,
        userId: userId ?? this.userId,
      );
  HouseholdEntry copyWithCompanion(HouseholdsCompanion data) {
    return HouseholdEntry(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      userId: data.userId.present ? data.userId.value : this.userId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HouseholdEntry(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('userId: $userId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, userId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HouseholdEntry &&
          other.id == this.id &&
          other.name == this.name &&
          other.userId == this.userId);
}

class HouseholdsCompanion extends UpdateCompanion<HouseholdEntry> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> userId;
  final Value<int> rowid;
  const HouseholdsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.userId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HouseholdsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String userId,
    this.rowid = const Value.absent(),
  })  : name = Value(name),
        userId = Value(userId);
  static Insertable<HouseholdEntry> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? userId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (userId != null) 'user_id': userId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HouseholdsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? userId,
      Value<int>? rowid}) {
    return HouseholdsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      userId: userId ?? this.userId,
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
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HouseholdsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('userId: $userId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UploadQueuesTable extends UploadQueues
    with TableInfo<$UploadQueuesTable, UploadQueueEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UploadQueuesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
      clientDefault: () => const Uuid().v4());
  static const VerificationMeta _fileNameMeta =
      const VerificationMeta('fileName');
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
      'file_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: Constant('pending'));
  static const VerificationMeta _retryCountMeta =
      const VerificationMeta('retryCount');
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
      'retry_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: Constant(0));
  static const VerificationMeta _lastTryTimestampMeta =
      const VerificationMeta('lastTryTimestamp');
  @override
  late final GeneratedColumn<int> lastTryTimestamp = GeneratedColumn<int>(
      'last_try_timestamp', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _recipeIdMeta =
      const VerificationMeta('recipeId');
  @override
  late final GeneratedColumn<String> recipeId = GeneratedColumn<String>(
      'recipe_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, fileName, status, retryCount, lastTryTimestamp, recipeId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'upload_queues';
  @override
  VerificationContext validateIntegrity(Insertable<UploadQueueEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('file_name')) {
      context.handle(_fileNameMeta,
          fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta));
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('retry_count')) {
      context.handle(
          _retryCountMeta,
          retryCount.isAcceptableOrUnknown(
              data['retry_count']!, _retryCountMeta));
    }
    if (data.containsKey('last_try_timestamp')) {
      context.handle(
          _lastTryTimestampMeta,
          lastTryTimestamp.isAcceptableOrUnknown(
              data['last_try_timestamp']!, _lastTryTimestampMeta));
    }
    if (data.containsKey('recipe_id')) {
      context.handle(_recipeIdMeta,
          recipeId.isAcceptableOrUnknown(data['recipe_id']!, _recipeIdMeta));
    } else if (isInserting) {
      context.missing(_recipeIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UploadQueueEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UploadQueueEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      fileName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_name'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      retryCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}retry_count'])!,
      lastTryTimestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}last_try_timestamp']),
      recipeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}recipe_id'])!,
    );
  }

  @override
  $UploadQueuesTable createAlias(String alias) {
    return $UploadQueuesTable(attachedDatabase, alias);
  }
}

class UploadQueueEntry extends DataClass
    implements Insertable<UploadQueueEntry> {
  final String id;
  final String fileName;
  final String status;
  final int retryCount;
  final int? lastTryTimestamp;
  final String recipeId;
  const UploadQueueEntry(
      {required this.id,
      required this.fileName,
      required this.status,
      required this.retryCount,
      this.lastTryTimestamp,
      required this.recipeId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['file_name'] = Variable<String>(fileName);
    map['status'] = Variable<String>(status);
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || lastTryTimestamp != null) {
      map['last_try_timestamp'] = Variable<int>(lastTryTimestamp);
    }
    map['recipe_id'] = Variable<String>(recipeId);
    return map;
  }

  UploadQueuesCompanion toCompanion(bool nullToAbsent) {
    return UploadQueuesCompanion(
      id: Value(id),
      fileName: Value(fileName),
      status: Value(status),
      retryCount: Value(retryCount),
      lastTryTimestamp: lastTryTimestamp == null && nullToAbsent
          ? const Value.absent()
          : Value(lastTryTimestamp),
      recipeId: Value(recipeId),
    );
  }

  factory UploadQueueEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UploadQueueEntry(
      id: serializer.fromJson<String>(json['id']),
      fileName: serializer.fromJson<String>(json['fileName']),
      status: serializer.fromJson<String>(json['status']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      lastTryTimestamp: serializer.fromJson<int?>(json['lastTryTimestamp']),
      recipeId: serializer.fromJson<String>(json['recipeId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'fileName': serializer.toJson<String>(fileName),
      'status': serializer.toJson<String>(status),
      'retryCount': serializer.toJson<int>(retryCount),
      'lastTryTimestamp': serializer.toJson<int?>(lastTryTimestamp),
      'recipeId': serializer.toJson<String>(recipeId),
    };
  }

  UploadQueueEntry copyWith(
          {String? id,
          String? fileName,
          String? status,
          int? retryCount,
          Value<int?> lastTryTimestamp = const Value.absent(),
          String? recipeId}) =>
      UploadQueueEntry(
        id: id ?? this.id,
        fileName: fileName ?? this.fileName,
        status: status ?? this.status,
        retryCount: retryCount ?? this.retryCount,
        lastTryTimestamp: lastTryTimestamp.present
            ? lastTryTimestamp.value
            : this.lastTryTimestamp,
        recipeId: recipeId ?? this.recipeId,
      );
  UploadQueueEntry copyWithCompanion(UploadQueuesCompanion data) {
    return UploadQueueEntry(
      id: data.id.present ? data.id.value : this.id,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      status: data.status.present ? data.status.value : this.status,
      retryCount:
          data.retryCount.present ? data.retryCount.value : this.retryCount,
      lastTryTimestamp: data.lastTryTimestamp.present
          ? data.lastTryTimestamp.value
          : this.lastTryTimestamp,
      recipeId: data.recipeId.present ? data.recipeId.value : this.recipeId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UploadQueueEntry(')
          ..write('id: $id, ')
          ..write('fileName: $fileName, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastTryTimestamp: $lastTryTimestamp, ')
          ..write('recipeId: $recipeId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, fileName, status, retryCount, lastTryTimestamp, recipeId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UploadQueueEntry &&
          other.id == this.id &&
          other.fileName == this.fileName &&
          other.status == this.status &&
          other.retryCount == this.retryCount &&
          other.lastTryTimestamp == this.lastTryTimestamp &&
          other.recipeId == this.recipeId);
}

class UploadQueuesCompanion extends UpdateCompanion<UploadQueueEntry> {
  final Value<String> id;
  final Value<String> fileName;
  final Value<String> status;
  final Value<int> retryCount;
  final Value<int?> lastTryTimestamp;
  final Value<String> recipeId;
  final Value<int> rowid;
  const UploadQueuesCompanion({
    this.id = const Value.absent(),
    this.fileName = const Value.absent(),
    this.status = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastTryTimestamp = const Value.absent(),
    this.recipeId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UploadQueuesCompanion.insert({
    this.id = const Value.absent(),
    required String fileName,
    this.status = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastTryTimestamp = const Value.absent(),
    required String recipeId,
    this.rowid = const Value.absent(),
  })  : fileName = Value(fileName),
        recipeId = Value(recipeId);
  static Insertable<UploadQueueEntry> custom({
    Expression<String>? id,
    Expression<String>? fileName,
    Expression<String>? status,
    Expression<int>? retryCount,
    Expression<int>? lastTryTimestamp,
    Expression<String>? recipeId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fileName != null) 'file_name': fileName,
      if (status != null) 'status': status,
      if (retryCount != null) 'retry_count': retryCount,
      if (lastTryTimestamp != null) 'last_try_timestamp': lastTryTimestamp,
      if (recipeId != null) 'recipe_id': recipeId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UploadQueuesCompanion copyWith(
      {Value<String>? id,
      Value<String>? fileName,
      Value<String>? status,
      Value<int>? retryCount,
      Value<int?>? lastTryTimestamp,
      Value<String>? recipeId,
      Value<int>? rowid}) {
    return UploadQueuesCompanion(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      lastTryTimestamp: lastTryTimestamp ?? this.lastTryTimestamp,
      recipeId: recipeId ?? this.recipeId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (lastTryTimestamp.present) {
      map['last_try_timestamp'] = Variable<int>(lastTryTimestamp.value);
    }
    if (recipeId.present) {
      map['recipe_id'] = Variable<String>(recipeId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UploadQueuesCompanion(')
          ..write('id: $id, ')
          ..write('fileName: $fileName, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastTryTimestamp: $lastTryTimestamp, ')
          ..write('recipeId: $recipeId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CooksTable extends Cooks with TableInfo<$CooksTable, CookEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CooksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
      clientDefault: () => const Uuid().v4());
  static const VerificationMeta _recipeIdMeta =
      const VerificationMeta('recipeId');
  @override
  late final GeneratedColumn<String> recipeId = GeneratedColumn<String>(
      'recipe_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _householdIdMeta =
      const VerificationMeta('householdId');
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
      'household_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _currentStepIndexMeta =
      const VerificationMeta('currentStepIndex');
  @override
  late final GeneratedColumn<int> currentStepIndex = GeneratedColumn<int>(
      'current_step_index', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumnWithTypeConverter<CookStatus, String> status =
      GeneratedColumn<String>('status', aliasedName, false,
              type: DriftSqlType.string,
              requiredDuringInsert: false,
              defaultValue: const Constant('in_progress'))
          .withConverter<CookStatus>($CooksTable.$converterstatus);
  static const VerificationMeta _startedAtMeta =
      const VerificationMeta('startedAt');
  @override
  late final GeneratedColumn<int> startedAt = GeneratedColumn<int>(
      'started_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _finishedAtMeta =
      const VerificationMeta('finishedAt');
  @override
  late final GeneratedColumn<int> finishedAt = GeneratedColumn<int>(
      'finished_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<int> rating = GeneratedColumn<int>(
      'rating', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _recipeNameMeta =
      const VerificationMeta('recipeName');
  @override
  late final GeneratedColumn<String> recipeName = GeneratedColumn<String>(
      'recipe_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        recipeId,
        userId,
        householdId,
        currentStepIndex,
        status,
        startedAt,
        finishedAt,
        updatedAt,
        rating,
        recipeName,
        notes
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cooks';
  @override
  VerificationContext validateIntegrity(Insertable<CookEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('recipe_id')) {
      context.handle(_recipeIdMeta,
          recipeId.isAcceptableOrUnknown(data['recipe_id']!, _recipeIdMeta));
    } else if (isInserting) {
      context.missing(_recipeIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    }
    if (data.containsKey('household_id')) {
      context.handle(
          _householdIdMeta,
          householdId.isAcceptableOrUnknown(
              data['household_id']!, _householdIdMeta));
    }
    if (data.containsKey('current_step_index')) {
      context.handle(
          _currentStepIndexMeta,
          currentStepIndex.isAcceptableOrUnknown(
              data['current_step_index']!, _currentStepIndexMeta));
    }
    context.handle(_statusMeta, const VerificationResult.success());
    if (data.containsKey('started_at')) {
      context.handle(_startedAtMeta,
          startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta));
    }
    if (data.containsKey('finished_at')) {
      context.handle(
          _finishedAtMeta,
          finishedAt.isAcceptableOrUnknown(
              data['finished_at']!, _finishedAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('rating')) {
      context.handle(_ratingMeta,
          rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta));
    }
    if (data.containsKey('recipe_name')) {
      context.handle(
          _recipeNameMeta,
          recipeName.isAcceptableOrUnknown(
              data['recipe_name']!, _recipeNameMeta));
    } else if (isInserting) {
      context.missing(_recipeNameMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CookEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CookEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      recipeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}recipe_id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id']),
      householdId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}household_id']),
      currentStepIndex: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}current_step_index'])!,
      status: $CooksTable.$converterstatus.fromSql(attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!),
      startedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}started_at']),
      finishedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}finished_at']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at']),
      rating: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}rating']),
      recipeName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}recipe_name'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
    );
  }

  @override
  $CooksTable createAlias(String alias) {
    return $CooksTable(attachedDatabase, alias);
  }

  static TypeConverter<CookStatus, String> $converterstatus =
      const CookStatusConverter();
}

class CookEntry extends DataClass implements Insertable<CookEntry> {
  final String id;
  final String recipeId;
  final String? userId;
  final String? householdId;
  final int currentStepIndex;
  final CookStatus status;
  final int? startedAt;
  final int? finishedAt;
  final int? updatedAt;
  final int? rating;
  final String recipeName;
  final String? notes;
  const CookEntry(
      {required this.id,
      required this.recipeId,
      this.userId,
      this.householdId,
      required this.currentStepIndex,
      required this.status,
      this.startedAt,
      this.finishedAt,
      this.updatedAt,
      this.rating,
      required this.recipeName,
      this.notes});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['recipe_id'] = Variable<String>(recipeId);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    if (!nullToAbsent || householdId != null) {
      map['household_id'] = Variable<String>(householdId);
    }
    map['current_step_index'] = Variable<int>(currentStepIndex);
    {
      map['status'] =
          Variable<String>($CooksTable.$converterstatus.toSql(status));
    }
    if (!nullToAbsent || startedAt != null) {
      map['started_at'] = Variable<int>(startedAt);
    }
    if (!nullToAbsent || finishedAt != null) {
      map['finished_at'] = Variable<int>(finishedAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<int>(updatedAt);
    }
    if (!nullToAbsent || rating != null) {
      map['rating'] = Variable<int>(rating);
    }
    map['recipe_name'] = Variable<String>(recipeName);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  CooksCompanion toCompanion(bool nullToAbsent) {
    return CooksCompanion(
      id: Value(id),
      recipeId: Value(recipeId),
      userId:
          userId == null && nullToAbsent ? const Value.absent() : Value(userId),
      householdId: householdId == null && nullToAbsent
          ? const Value.absent()
          : Value(householdId),
      currentStepIndex: Value(currentStepIndex),
      status: Value(status),
      startedAt: startedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(startedAt),
      finishedAt: finishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(finishedAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      rating:
          rating == null && nullToAbsent ? const Value.absent() : Value(rating),
      recipeName: Value(recipeName),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
    );
  }

  factory CookEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CookEntry(
      id: serializer.fromJson<String>(json['id']),
      recipeId: serializer.fromJson<String>(json['recipeId']),
      userId: serializer.fromJson<String?>(json['userId']),
      householdId: serializer.fromJson<String?>(json['householdId']),
      currentStepIndex: serializer.fromJson<int>(json['currentStepIndex']),
      status: serializer.fromJson<CookStatus>(json['status']),
      startedAt: serializer.fromJson<int?>(json['startedAt']),
      finishedAt: serializer.fromJson<int?>(json['finishedAt']),
      updatedAt: serializer.fromJson<int?>(json['updatedAt']),
      rating: serializer.fromJson<int?>(json['rating']),
      recipeName: serializer.fromJson<String>(json['recipeName']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'recipeId': serializer.toJson<String>(recipeId),
      'userId': serializer.toJson<String?>(userId),
      'householdId': serializer.toJson<String?>(householdId),
      'currentStepIndex': serializer.toJson<int>(currentStepIndex),
      'status': serializer.toJson<CookStatus>(status),
      'startedAt': serializer.toJson<int?>(startedAt),
      'finishedAt': serializer.toJson<int?>(finishedAt),
      'updatedAt': serializer.toJson<int?>(updatedAt),
      'rating': serializer.toJson<int?>(rating),
      'recipeName': serializer.toJson<String>(recipeName),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  CookEntry copyWith(
          {String? id,
          String? recipeId,
          Value<String?> userId = const Value.absent(),
          Value<String?> householdId = const Value.absent(),
          int? currentStepIndex,
          CookStatus? status,
          Value<int?> startedAt = const Value.absent(),
          Value<int?> finishedAt = const Value.absent(),
          Value<int?> updatedAt = const Value.absent(),
          Value<int?> rating = const Value.absent(),
          String? recipeName,
          Value<String?> notes = const Value.absent()}) =>
      CookEntry(
        id: id ?? this.id,
        recipeId: recipeId ?? this.recipeId,
        userId: userId.present ? userId.value : this.userId,
        householdId: householdId.present ? householdId.value : this.householdId,
        currentStepIndex: currentStepIndex ?? this.currentStepIndex,
        status: status ?? this.status,
        startedAt: startedAt.present ? startedAt.value : this.startedAt,
        finishedAt: finishedAt.present ? finishedAt.value : this.finishedAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
        rating: rating.present ? rating.value : this.rating,
        recipeName: recipeName ?? this.recipeName,
        notes: notes.present ? notes.value : this.notes,
      );
  CookEntry copyWithCompanion(CooksCompanion data) {
    return CookEntry(
      id: data.id.present ? data.id.value : this.id,
      recipeId: data.recipeId.present ? data.recipeId.value : this.recipeId,
      userId: data.userId.present ? data.userId.value : this.userId,
      householdId:
          data.householdId.present ? data.householdId.value : this.householdId,
      currentStepIndex: data.currentStepIndex.present
          ? data.currentStepIndex.value
          : this.currentStepIndex,
      status: data.status.present ? data.status.value : this.status,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      finishedAt:
          data.finishedAt.present ? data.finishedAt.value : this.finishedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      rating: data.rating.present ? data.rating.value : this.rating,
      recipeName:
          data.recipeName.present ? data.recipeName.value : this.recipeName,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CookEntry(')
          ..write('id: $id, ')
          ..write('recipeId: $recipeId, ')
          ..write('userId: $userId, ')
          ..write('householdId: $householdId, ')
          ..write('currentStepIndex: $currentStepIndex, ')
          ..write('status: $status, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rating: $rating, ')
          ..write('recipeName: $recipeName, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      recipeId,
      userId,
      householdId,
      currentStepIndex,
      status,
      startedAt,
      finishedAt,
      updatedAt,
      rating,
      recipeName,
      notes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CookEntry &&
          other.id == this.id &&
          other.recipeId == this.recipeId &&
          other.userId == this.userId &&
          other.householdId == this.householdId &&
          other.currentStepIndex == this.currentStepIndex &&
          other.status == this.status &&
          other.startedAt == this.startedAt &&
          other.finishedAt == this.finishedAt &&
          other.updatedAt == this.updatedAt &&
          other.rating == this.rating &&
          other.recipeName == this.recipeName &&
          other.notes == this.notes);
}

class CooksCompanion extends UpdateCompanion<CookEntry> {
  final Value<String> id;
  final Value<String> recipeId;
  final Value<String?> userId;
  final Value<String?> householdId;
  final Value<int> currentStepIndex;
  final Value<CookStatus> status;
  final Value<int?> startedAt;
  final Value<int?> finishedAt;
  final Value<int?> updatedAt;
  final Value<int?> rating;
  final Value<String> recipeName;
  final Value<String?> notes;
  final Value<int> rowid;
  const CooksCompanion({
    this.id = const Value.absent(),
    this.recipeId = const Value.absent(),
    this.userId = const Value.absent(),
    this.householdId = const Value.absent(),
    this.currentStepIndex = const Value.absent(),
    this.status = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rating = const Value.absent(),
    this.recipeName = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CooksCompanion.insert({
    this.id = const Value.absent(),
    required String recipeId,
    this.userId = const Value.absent(),
    this.householdId = const Value.absent(),
    this.currentStepIndex = const Value.absent(),
    this.status = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rating = const Value.absent(),
    required String recipeName,
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : recipeId = Value(recipeId),
        recipeName = Value(recipeName);
  static Insertable<CookEntry> custom({
    Expression<String>? id,
    Expression<String>? recipeId,
    Expression<String>? userId,
    Expression<String>? householdId,
    Expression<int>? currentStepIndex,
    Expression<String>? status,
    Expression<int>? startedAt,
    Expression<int>? finishedAt,
    Expression<int>? updatedAt,
    Expression<int>? rating,
    Expression<String>? recipeName,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (recipeId != null) 'recipe_id': recipeId,
      if (userId != null) 'user_id': userId,
      if (householdId != null) 'household_id': householdId,
      if (currentStepIndex != null) 'current_step_index': currentStepIndex,
      if (status != null) 'status': status,
      if (startedAt != null) 'started_at': startedAt,
      if (finishedAt != null) 'finished_at': finishedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rating != null) 'rating': rating,
      if (recipeName != null) 'recipe_name': recipeName,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CooksCompanion copyWith(
      {Value<String>? id,
      Value<String>? recipeId,
      Value<String?>? userId,
      Value<String?>? householdId,
      Value<int>? currentStepIndex,
      Value<CookStatus>? status,
      Value<int?>? startedAt,
      Value<int?>? finishedAt,
      Value<int?>? updatedAt,
      Value<int?>? rating,
      Value<String>? recipeName,
      Value<String?>? notes,
      Value<int>? rowid}) {
    return CooksCompanion(
      id: id ?? this.id,
      recipeId: recipeId ?? this.recipeId,
      userId: userId ?? this.userId,
      householdId: householdId ?? this.householdId,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rating: rating ?? this.rating,
      recipeName: recipeName ?? this.recipeName,
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
    if (recipeId.present) {
      map['recipe_id'] = Variable<String>(recipeId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (currentStepIndex.present) {
      map['current_step_index'] = Variable<int>(currentStepIndex.value);
    }
    if (status.present) {
      map['status'] =
          Variable<String>($CooksTable.$converterstatus.toSql(status.value));
    }
    if (startedAt.present) {
      map['started_at'] = Variable<int>(startedAt.value);
    }
    if (finishedAt.present) {
      map['finished_at'] = Variable<int>(finishedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rating.present) {
      map['rating'] = Variable<int>(rating.value);
    }
    if (recipeName.present) {
      map['recipe_name'] = Variable<String>(recipeName.value);
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
    return (StringBuffer('CooksCompanion(')
          ..write('id: $id, ')
          ..write('recipeId: $recipeId, ')
          ..write('userId: $userId, ')
          ..write('householdId: $householdId, ')
          ..write('currentStepIndex: $currentStepIndex, ')
          ..write('status: $status, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rating: $rating, ')
          ..write('recipeName: $recipeName, ')
          ..write('notes: $notes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PantryItemsTable extends PantryItems
    with TableInfo<$PantryItemsTable, PantryItemEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PantryItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      clientDefault: () => const Uuid().v4());
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _inStockMeta =
      const VerificationMeta('inStock');
  @override
  late final GeneratedColumn<bool> inStock = GeneratedColumn<bool>(
      'in_stock', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("in_stock" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _householdIdMeta =
      const VerificationMeta('householdId');
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
      'household_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _termsMeta = const VerificationMeta('terms');
  @override
  late final GeneratedColumnWithTypeConverter<List<PantryItemTerm>?, String>
      terms = GeneratedColumn<String>('terms', aliasedName, true,
              type: DriftSqlType.string, requiredDuringInsert: false)
          .withConverter<List<PantryItemTerm>?>(
              $PantryItemsTable.$convertertermsn);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        inStock,
        userId,
        householdId,
        createdAt,
        updatedAt,
        deletedAt,
        terms
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pantry_items';
  @override
  VerificationContext validateIntegrity(Insertable<PantryItemEntry> instance,
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
    if (data.containsKey('in_stock')) {
      context.handle(_inStockMeta,
          inStock.isAcceptableOrUnknown(data['in_stock']!, _inStockMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    }
    if (data.containsKey('household_id')) {
      context.handle(
          _householdIdMeta,
          householdId.isAcceptableOrUnknown(
              data['household_id']!, _householdIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    context.handle(_termsMeta, const VerificationResult.success());
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PantryItemEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PantryItemEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      inStock: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}in_stock'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id']),
      householdId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}household_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at']),
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}deleted_at']),
      terms: $PantryItemsTable.$convertertermsn.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}terms'])),
    );
  }

  @override
  $PantryItemsTable createAlias(String alias) {
    return $PantryItemsTable(attachedDatabase, alias);
  }

  static TypeConverter<List<PantryItemTerm>, String> $converterterms =
      const PantryItemTermListConverter();
  static TypeConverter<List<PantryItemTerm>?, String?> $convertertermsn =
      NullAwareTypeConverter.wrap($converterterms);
}

class PantryItemEntry extends DataClass implements Insertable<PantryItemEntry> {
  final String id;
  final String name;
  final bool inStock;
  final String? userId;
  final String? householdId;
  final int? createdAt;
  final int? updatedAt;
  final int? deletedAt;
  final List<PantryItemTerm>? terms;
  const PantryItemEntry(
      {required this.id,
      required this.name,
      required this.inStock,
      this.userId,
      this.householdId,
      this.createdAt,
      this.updatedAt,
      this.deletedAt,
      this.terms});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['in_stock'] = Variable<bool>(inStock);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    if (!nullToAbsent || householdId != null) {
      map['household_id'] = Variable<String>(householdId);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<int>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<int>(updatedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    if (!nullToAbsent || terms != null) {
      map['terms'] =
          Variable<String>($PantryItemsTable.$convertertermsn.toSql(terms));
    }
    return map;
  }

  PantryItemsCompanion toCompanion(bool nullToAbsent) {
    return PantryItemsCompanion(
      id: Value(id),
      name: Value(name),
      inStock: Value(inStock),
      userId:
          userId == null && nullToAbsent ? const Value.absent() : Value(userId),
      householdId: householdId == null && nullToAbsent
          ? const Value.absent()
          : Value(householdId),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      terms:
          terms == null && nullToAbsent ? const Value.absent() : Value(terms),
    );
  }

  factory PantryItemEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PantryItemEntry(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      inStock: serializer.fromJson<bool>(json['inStock']),
      userId: serializer.fromJson<String?>(json['userId']),
      householdId: serializer.fromJson<String?>(json['householdId']),
      createdAt: serializer.fromJson<int?>(json['createdAt']),
      updatedAt: serializer.fromJson<int?>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      terms: serializer.fromJson<List<PantryItemTerm>?>(json['terms']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'inStock': serializer.toJson<bool>(inStock),
      'userId': serializer.toJson<String?>(userId),
      'householdId': serializer.toJson<String?>(householdId),
      'createdAt': serializer.toJson<int?>(createdAt),
      'updatedAt': serializer.toJson<int?>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'terms': serializer.toJson<List<PantryItemTerm>?>(terms),
    };
  }

  PantryItemEntry copyWith(
          {String? id,
          String? name,
          bool? inStock,
          Value<String?> userId = const Value.absent(),
          Value<String?> householdId = const Value.absent(),
          Value<int?> createdAt = const Value.absent(),
          Value<int?> updatedAt = const Value.absent(),
          Value<int?> deletedAt = const Value.absent(),
          Value<List<PantryItemTerm>?> terms = const Value.absent()}) =>
      PantryItemEntry(
        id: id ?? this.id,
        name: name ?? this.name,
        inStock: inStock ?? this.inStock,
        userId: userId.present ? userId.value : this.userId,
        householdId: householdId.present ? householdId.value : this.householdId,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        terms: terms.present ? terms.value : this.terms,
      );
  PantryItemEntry copyWithCompanion(PantryItemsCompanion data) {
    return PantryItemEntry(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      inStock: data.inStock.present ? data.inStock.value : this.inStock,
      userId: data.userId.present ? data.userId.value : this.userId,
      householdId:
          data.householdId.present ? data.householdId.value : this.householdId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      terms: data.terms.present ? data.terms.value : this.terms,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PantryItemEntry(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('inStock: $inStock, ')
          ..write('userId: $userId, ')
          ..write('householdId: $householdId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('terms: $terms')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, inStock, userId, householdId,
      createdAt, updatedAt, deletedAt, terms);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PantryItemEntry &&
          other.id == this.id &&
          other.name == this.name &&
          other.inStock == this.inStock &&
          other.userId == this.userId &&
          other.householdId == this.householdId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.terms == this.terms);
}

class PantryItemsCompanion extends UpdateCompanion<PantryItemEntry> {
  final Value<String> id;
  final Value<String> name;
  final Value<bool> inStock;
  final Value<String?> userId;
  final Value<String?> householdId;
  final Value<int?> createdAt;
  final Value<int?> updatedAt;
  final Value<int?> deletedAt;
  final Value<List<PantryItemTerm>?> terms;
  final Value<int> rowid;
  const PantryItemsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.inStock = const Value.absent(),
    this.userId = const Value.absent(),
    this.householdId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.terms = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PantryItemsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.inStock = const Value.absent(),
    this.userId = const Value.absent(),
    this.householdId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.terms = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : name = Value(name);
  static Insertable<PantryItemEntry> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<bool>? inStock,
    Expression<String>? userId,
    Expression<String>? householdId,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? terms,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (inStock != null) 'in_stock': inStock,
      if (userId != null) 'user_id': userId,
      if (householdId != null) 'household_id': householdId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (terms != null) 'terms': terms,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PantryItemsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<bool>? inStock,
      Value<String?>? userId,
      Value<String?>? householdId,
      Value<int?>? createdAt,
      Value<int?>? updatedAt,
      Value<int?>? deletedAt,
      Value<List<PantryItemTerm>?>? terms,
      Value<int>? rowid}) {
    return PantryItemsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      inStock: inStock ?? this.inStock,
      userId: userId ?? this.userId,
      householdId: householdId ?? this.householdId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      terms: terms ?? this.terms,
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
    if (inStock.present) {
      map['in_stock'] = Variable<bool>(inStock.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (terms.present) {
      map['terms'] = Variable<String>(
          $PantryItemsTable.$convertertermsn.toSql(terms.value));
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PantryItemsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('inStock: $inStock, ')
          ..write('userId: $userId, ')
          ..write('householdId: $householdId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('terms: $terms, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $IngredientTermOverridesTable extends IngredientTermOverrides
    with TableInfo<$IngredientTermOverridesTable, IngredientTermOverrideEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IngredientTermOverridesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
      clientDefault: () => const Uuid().v4());
  static const VerificationMeta _inputTermMeta =
      const VerificationMeta('inputTerm');
  @override
  late final GeneratedColumn<String> inputTerm = GeneratedColumn<String>(
      'input_term', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _mappedTermMeta =
      const VerificationMeta('mappedTerm');
  @override
  late final GeneratedColumn<String> mappedTerm = GeneratedColumn<String>(
      'mapped_term', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _householdIdMeta =
      const VerificationMeta('householdId');
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
      'household_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, inputTerm, mappedTerm, userId, householdId, createdAt, deletedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ingredient_term_overrides';
  @override
  VerificationContext validateIntegrity(
      Insertable<IngredientTermOverrideEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('input_term')) {
      context.handle(_inputTermMeta,
          inputTerm.isAcceptableOrUnknown(data['input_term']!, _inputTermMeta));
    } else if (isInserting) {
      context.missing(_inputTermMeta);
    }
    if (data.containsKey('mapped_term')) {
      context.handle(
          _mappedTermMeta,
          mappedTerm.isAcceptableOrUnknown(
              data['mapped_term']!, _mappedTermMeta));
    } else if (isInserting) {
      context.missing(_mappedTermMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    }
    if (data.containsKey('household_id')) {
      context.handle(
          _householdIdMeta,
          householdId.isAcceptableOrUnknown(
              data['household_id']!, _householdIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
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
  IngredientTermOverrideEntry map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IngredientTermOverrideEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      inputTerm: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}input_term'])!,
      mappedTerm: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mapped_term'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id']),
      householdId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}household_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at']),
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $IngredientTermOverridesTable createAlias(String alias) {
    return $IngredientTermOverridesTable(attachedDatabase, alias);
  }
}

class IngredientTermOverrideEntry extends DataClass
    implements Insertable<IngredientTermOverrideEntry> {
  final String id;
  final String inputTerm;
  final String mappedTerm;
  final String? userId;
  final String? householdId;
  final int? createdAt;
  final int? deletedAt;
  const IngredientTermOverrideEntry(
      {required this.id,
      required this.inputTerm,
      required this.mappedTerm,
      this.userId,
      this.householdId,
      this.createdAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['input_term'] = Variable<String>(inputTerm);
    map['mapped_term'] = Variable<String>(mappedTerm);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    if (!nullToAbsent || householdId != null) {
      map['household_id'] = Variable<String>(householdId);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<int>(createdAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  IngredientTermOverridesCompanion toCompanion(bool nullToAbsent) {
    return IngredientTermOverridesCompanion(
      id: Value(id),
      inputTerm: Value(inputTerm),
      mappedTerm: Value(mappedTerm),
      userId:
          userId == null && nullToAbsent ? const Value.absent() : Value(userId),
      householdId: householdId == null && nullToAbsent
          ? const Value.absent()
          : Value(householdId),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory IngredientTermOverrideEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IngredientTermOverrideEntry(
      id: serializer.fromJson<String>(json['id']),
      inputTerm: serializer.fromJson<String>(json['inputTerm']),
      mappedTerm: serializer.fromJson<String>(json['mappedTerm']),
      userId: serializer.fromJson<String?>(json['userId']),
      householdId: serializer.fromJson<String?>(json['householdId']),
      createdAt: serializer.fromJson<int?>(json['createdAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'inputTerm': serializer.toJson<String>(inputTerm),
      'mappedTerm': serializer.toJson<String>(mappedTerm),
      'userId': serializer.toJson<String?>(userId),
      'householdId': serializer.toJson<String?>(householdId),
      'createdAt': serializer.toJson<int?>(createdAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  IngredientTermOverrideEntry copyWith(
          {String? id,
          String? inputTerm,
          String? mappedTerm,
          Value<String?> userId = const Value.absent(),
          Value<String?> householdId = const Value.absent(),
          Value<int?> createdAt = const Value.absent(),
          Value<int?> deletedAt = const Value.absent()}) =>
      IngredientTermOverrideEntry(
        id: id ?? this.id,
        inputTerm: inputTerm ?? this.inputTerm,
        mappedTerm: mappedTerm ?? this.mappedTerm,
        userId: userId.present ? userId.value : this.userId,
        householdId: householdId.present ? householdId.value : this.householdId,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  IngredientTermOverrideEntry copyWithCompanion(
      IngredientTermOverridesCompanion data) {
    return IngredientTermOverrideEntry(
      id: data.id.present ? data.id.value : this.id,
      inputTerm: data.inputTerm.present ? data.inputTerm.value : this.inputTerm,
      mappedTerm:
          data.mappedTerm.present ? data.mappedTerm.value : this.mappedTerm,
      userId: data.userId.present ? data.userId.value : this.userId,
      householdId:
          data.householdId.present ? data.householdId.value : this.householdId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IngredientTermOverrideEntry(')
          ..write('id: $id, ')
          ..write('inputTerm: $inputTerm, ')
          ..write('mappedTerm: $mappedTerm, ')
          ..write('userId: $userId, ')
          ..write('householdId: $householdId, ')
          ..write('createdAt: $createdAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, inputTerm, mappedTerm, userId, householdId, createdAt, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IngredientTermOverrideEntry &&
          other.id == this.id &&
          other.inputTerm == this.inputTerm &&
          other.mappedTerm == this.mappedTerm &&
          other.userId == this.userId &&
          other.householdId == this.householdId &&
          other.createdAt == this.createdAt &&
          other.deletedAt == this.deletedAt);
}

class IngredientTermOverridesCompanion
    extends UpdateCompanion<IngredientTermOverrideEntry> {
  final Value<String> id;
  final Value<String> inputTerm;
  final Value<String> mappedTerm;
  final Value<String?> userId;
  final Value<String?> householdId;
  final Value<int?> createdAt;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const IngredientTermOverridesCompanion({
    this.id = const Value.absent(),
    this.inputTerm = const Value.absent(),
    this.mappedTerm = const Value.absent(),
    this.userId = const Value.absent(),
    this.householdId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IngredientTermOverridesCompanion.insert({
    this.id = const Value.absent(),
    required String inputTerm,
    required String mappedTerm,
    this.userId = const Value.absent(),
    this.householdId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : inputTerm = Value(inputTerm),
        mappedTerm = Value(mappedTerm);
  static Insertable<IngredientTermOverrideEntry> custom({
    Expression<String>? id,
    Expression<String>? inputTerm,
    Expression<String>? mappedTerm,
    Expression<String>? userId,
    Expression<String>? householdId,
    Expression<int>? createdAt,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (inputTerm != null) 'input_term': inputTerm,
      if (mappedTerm != null) 'mapped_term': mappedTerm,
      if (userId != null) 'user_id': userId,
      if (householdId != null) 'household_id': householdId,
      if (createdAt != null) 'created_at': createdAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IngredientTermOverridesCompanion copyWith(
      {Value<String>? id,
      Value<String>? inputTerm,
      Value<String>? mappedTerm,
      Value<String?>? userId,
      Value<String?>? householdId,
      Value<int?>? createdAt,
      Value<int?>? deletedAt,
      Value<int>? rowid}) {
    return IngredientTermOverridesCompanion(
      id: id ?? this.id,
      inputTerm: inputTerm ?? this.inputTerm,
      mappedTerm: mappedTerm ?? this.mappedTerm,
      userId: userId ?? this.userId,
      householdId: householdId ?? this.householdId,
      createdAt: createdAt ?? this.createdAt,
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
    if (inputTerm.present) {
      map['input_term'] = Variable<String>(inputTerm.value);
    }
    if (mappedTerm.present) {
      map['mapped_term'] = Variable<String>(mappedTerm.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
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
    return (StringBuffer('IngredientTermOverridesCompanion(')
          ..write('id: $id, ')
          ..write('inputTerm: $inputTerm, ')
          ..write('mappedTerm: $mappedTerm, ')
          ..write('userId: $userId, ')
          ..write('householdId: $householdId, ')
          ..write('createdAt: $createdAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ShoppingListItemsTable extends ShoppingListItems
    with TableInfo<$ShoppingListItemsTable, ShoppingListItemEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShoppingListItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      clientDefault: () => const Uuid().v4());
  static const VerificationMeta _shoppingListIdMeta =
      const VerificationMeta('shoppingListId');
  @override
  late final GeneratedColumn<String> shoppingListId = GeneratedColumn<String>(
      'shopping_list_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _normalizedTermsMeta =
      const VerificationMeta('normalizedTerms');
  @override
  late final GeneratedColumnWithTypeConverter<List<String>?, String>
      normalizedTerms = GeneratedColumn<String>(
              'normalized_terms', aliasedName, true,
              type: DriftSqlType.string, requiredDuringInsert: false)
          .withConverter<List<String>?>(
              $ShoppingListItemsTable.$converternormalizedTermsn);
  static const VerificationMeta _sourceRecipeIdMeta =
      const VerificationMeta('sourceRecipeId');
  @override
  late final GeneratedColumn<String> sourceRecipeId = GeneratedColumn<String>(
      'source_recipe_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
      'unit', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _boughtMeta = const VerificationMeta('bought');
  @override
  late final GeneratedColumn<bool> bought = GeneratedColumn<bool>(
      'bought', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("bought" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _householdIdMeta =
      const VerificationMeta('householdId');
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
      'household_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        shoppingListId,
        name,
        normalizedTerms,
        sourceRecipeId,
        amount,
        unit,
        bought,
        userId,
        householdId,
        createdAt,
        updatedAt,
        deletedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shopping_list_items';
  @override
  VerificationContext validateIntegrity(
      Insertable<ShoppingListItemEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('shopping_list_id')) {
      context.handle(
          _shoppingListIdMeta,
          shoppingListId.isAcceptableOrUnknown(
              data['shopping_list_id']!, _shoppingListIdMeta));
    } else if (isInserting) {
      context.missing(_shoppingListIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    context.handle(_normalizedTermsMeta, const VerificationResult.success());
    if (data.containsKey('source_recipe_id')) {
      context.handle(
          _sourceRecipeIdMeta,
          sourceRecipeId.isAcceptableOrUnknown(
              data['source_recipe_id']!, _sourceRecipeIdMeta));
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    }
    if (data.containsKey('unit')) {
      context.handle(
          _unitMeta, unit.isAcceptableOrUnknown(data['unit']!, _unitMeta));
    }
    if (data.containsKey('bought')) {
      context.handle(_boughtMeta,
          bought.isAcceptableOrUnknown(data['bought']!, _boughtMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    }
    if (data.containsKey('household_id')) {
      context.handle(
          _householdIdMeta,
          householdId.isAcceptableOrUnknown(
              data['household_id']!, _householdIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ShoppingListItemEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShoppingListItemEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      shoppingListId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}shopping_list_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      normalizedTerms: $ShoppingListItemsTable.$converternormalizedTermsn
          .fromSql(attachedDatabase.typeMapping.read(
              DriftSqlType.string, data['${effectivePrefix}normalized_terms'])),
      sourceRecipeId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}source_recipe_id']),
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount']),
      unit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit']),
      bought: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}bought'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id']),
      householdId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}household_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at']),
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $ShoppingListItemsTable createAlias(String alias) {
    return $ShoppingListItemsTable(attachedDatabase, alias);
  }

  static TypeConverter<List<String>, String> $converternormalizedTerms =
      StringListTypeConverter();
  static TypeConverter<List<String>?, String?> $converternormalizedTermsn =
      NullAwareTypeConverter.wrap($converternormalizedTerms);
}

class ShoppingListItemEntry extends DataClass
    implements Insertable<ShoppingListItemEntry> {
  final String id;
  final String shoppingListId;
  final String name;
  final List<String>? normalizedTerms;
  final String? sourceRecipeId;
  final double? amount;
  final String? unit;
  final bool bought;
  final String? userId;
  final String? householdId;
  final int? createdAt;
  final int? updatedAt;
  final int? deletedAt;
  const ShoppingListItemEntry(
      {required this.id,
      required this.shoppingListId,
      required this.name,
      this.normalizedTerms,
      this.sourceRecipeId,
      this.amount,
      this.unit,
      required this.bought,
      this.userId,
      this.householdId,
      this.createdAt,
      this.updatedAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['shopping_list_id'] = Variable<String>(shoppingListId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || normalizedTerms != null) {
      map['normalized_terms'] = Variable<String>($ShoppingListItemsTable
          .$converternormalizedTermsn
          .toSql(normalizedTerms));
    }
    if (!nullToAbsent || sourceRecipeId != null) {
      map['source_recipe_id'] = Variable<String>(sourceRecipeId);
    }
    if (!nullToAbsent || amount != null) {
      map['amount'] = Variable<double>(amount);
    }
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    map['bought'] = Variable<bool>(bought);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    if (!nullToAbsent || householdId != null) {
      map['household_id'] = Variable<String>(householdId);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<int>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<int>(updatedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  ShoppingListItemsCompanion toCompanion(bool nullToAbsent) {
    return ShoppingListItemsCompanion(
      id: Value(id),
      shoppingListId: Value(shoppingListId),
      name: Value(name),
      normalizedTerms: normalizedTerms == null && nullToAbsent
          ? const Value.absent()
          : Value(normalizedTerms),
      sourceRecipeId: sourceRecipeId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceRecipeId),
      amount:
          amount == null && nullToAbsent ? const Value.absent() : Value(amount),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      bought: Value(bought),
      userId:
          userId == null && nullToAbsent ? const Value.absent() : Value(userId),
      householdId: householdId == null && nullToAbsent
          ? const Value.absent()
          : Value(householdId),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory ShoppingListItemEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShoppingListItemEntry(
      id: serializer.fromJson<String>(json['id']),
      shoppingListId: serializer.fromJson<String>(json['shoppingListId']),
      name: serializer.fromJson<String>(json['name']),
      normalizedTerms:
          serializer.fromJson<List<String>?>(json['normalizedTerms']),
      sourceRecipeId: serializer.fromJson<String?>(json['sourceRecipeId']),
      amount: serializer.fromJson<double?>(json['amount']),
      unit: serializer.fromJson<String?>(json['unit']),
      bought: serializer.fromJson<bool>(json['bought']),
      userId: serializer.fromJson<String?>(json['userId']),
      householdId: serializer.fromJson<String?>(json['householdId']),
      createdAt: serializer.fromJson<int?>(json['createdAt']),
      updatedAt: serializer.fromJson<int?>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'shoppingListId': serializer.toJson<String>(shoppingListId),
      'name': serializer.toJson<String>(name),
      'normalizedTerms': serializer.toJson<List<String>?>(normalizedTerms),
      'sourceRecipeId': serializer.toJson<String?>(sourceRecipeId),
      'amount': serializer.toJson<double?>(amount),
      'unit': serializer.toJson<String?>(unit),
      'bought': serializer.toJson<bool>(bought),
      'userId': serializer.toJson<String?>(userId),
      'householdId': serializer.toJson<String?>(householdId),
      'createdAt': serializer.toJson<int?>(createdAt),
      'updatedAt': serializer.toJson<int?>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  ShoppingListItemEntry copyWith(
          {String? id,
          String? shoppingListId,
          String? name,
          Value<List<String>?> normalizedTerms = const Value.absent(),
          Value<String?> sourceRecipeId = const Value.absent(),
          Value<double?> amount = const Value.absent(),
          Value<String?> unit = const Value.absent(),
          bool? bought,
          Value<String?> userId = const Value.absent(),
          Value<String?> householdId = const Value.absent(),
          Value<int?> createdAt = const Value.absent(),
          Value<int?> updatedAt = const Value.absent(),
          Value<int?> deletedAt = const Value.absent()}) =>
      ShoppingListItemEntry(
        id: id ?? this.id,
        shoppingListId: shoppingListId ?? this.shoppingListId,
        name: name ?? this.name,
        normalizedTerms: normalizedTerms.present
            ? normalizedTerms.value
            : this.normalizedTerms,
        sourceRecipeId:
            sourceRecipeId.present ? sourceRecipeId.value : this.sourceRecipeId,
        amount: amount.present ? amount.value : this.amount,
        unit: unit.present ? unit.value : this.unit,
        bought: bought ?? this.bought,
        userId: userId.present ? userId.value : this.userId,
        householdId: householdId.present ? householdId.value : this.householdId,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  ShoppingListItemEntry copyWithCompanion(ShoppingListItemsCompanion data) {
    return ShoppingListItemEntry(
      id: data.id.present ? data.id.value : this.id,
      shoppingListId: data.shoppingListId.present
          ? data.shoppingListId.value
          : this.shoppingListId,
      name: data.name.present ? data.name.value : this.name,
      normalizedTerms: data.normalizedTerms.present
          ? data.normalizedTerms.value
          : this.normalizedTerms,
      sourceRecipeId: data.sourceRecipeId.present
          ? data.sourceRecipeId.value
          : this.sourceRecipeId,
      amount: data.amount.present ? data.amount.value : this.amount,
      unit: data.unit.present ? data.unit.value : this.unit,
      bought: data.bought.present ? data.bought.value : this.bought,
      userId: data.userId.present ? data.userId.value : this.userId,
      householdId:
          data.householdId.present ? data.householdId.value : this.householdId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShoppingListItemEntry(')
          ..write('id: $id, ')
          ..write('shoppingListId: $shoppingListId, ')
          ..write('name: $name, ')
          ..write('normalizedTerms: $normalizedTerms, ')
          ..write('sourceRecipeId: $sourceRecipeId, ')
          ..write('amount: $amount, ')
          ..write('unit: $unit, ')
          ..write('bought: $bought, ')
          ..write('userId: $userId, ')
          ..write('householdId: $householdId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      shoppingListId,
      name,
      normalizedTerms,
      sourceRecipeId,
      amount,
      unit,
      bought,
      userId,
      householdId,
      createdAt,
      updatedAt,
      deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShoppingListItemEntry &&
          other.id == this.id &&
          other.shoppingListId == this.shoppingListId &&
          other.name == this.name &&
          other.normalizedTerms == this.normalizedTerms &&
          other.sourceRecipeId == this.sourceRecipeId &&
          other.amount == this.amount &&
          other.unit == this.unit &&
          other.bought == this.bought &&
          other.userId == this.userId &&
          other.householdId == this.householdId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class ShoppingListItemsCompanion
    extends UpdateCompanion<ShoppingListItemEntry> {
  final Value<String> id;
  final Value<String> shoppingListId;
  final Value<String> name;
  final Value<List<String>?> normalizedTerms;
  final Value<String?> sourceRecipeId;
  final Value<double?> amount;
  final Value<String?> unit;
  final Value<bool> bought;
  final Value<String?> userId;
  final Value<String?> householdId;
  final Value<int?> createdAt;
  final Value<int?> updatedAt;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const ShoppingListItemsCompanion({
    this.id = const Value.absent(),
    this.shoppingListId = const Value.absent(),
    this.name = const Value.absent(),
    this.normalizedTerms = const Value.absent(),
    this.sourceRecipeId = const Value.absent(),
    this.amount = const Value.absent(),
    this.unit = const Value.absent(),
    this.bought = const Value.absent(),
    this.userId = const Value.absent(),
    this.householdId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ShoppingListItemsCompanion.insert({
    this.id = const Value.absent(),
    required String shoppingListId,
    required String name,
    this.normalizedTerms = const Value.absent(),
    this.sourceRecipeId = const Value.absent(),
    this.amount = const Value.absent(),
    this.unit = const Value.absent(),
    this.bought = const Value.absent(),
    this.userId = const Value.absent(),
    this.householdId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : shoppingListId = Value(shoppingListId),
        name = Value(name);
  static Insertable<ShoppingListItemEntry> custom({
    Expression<String>? id,
    Expression<String>? shoppingListId,
    Expression<String>? name,
    Expression<String>? normalizedTerms,
    Expression<String>? sourceRecipeId,
    Expression<double>? amount,
    Expression<String>? unit,
    Expression<bool>? bought,
    Expression<String>? userId,
    Expression<String>? householdId,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (shoppingListId != null) 'shopping_list_id': shoppingListId,
      if (name != null) 'name': name,
      if (normalizedTerms != null) 'normalized_terms': normalizedTerms,
      if (sourceRecipeId != null) 'source_recipe_id': sourceRecipeId,
      if (amount != null) 'amount': amount,
      if (unit != null) 'unit': unit,
      if (bought != null) 'bought': bought,
      if (userId != null) 'user_id': userId,
      if (householdId != null) 'household_id': householdId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ShoppingListItemsCompanion copyWith(
      {Value<String>? id,
      Value<String>? shoppingListId,
      Value<String>? name,
      Value<List<String>?>? normalizedTerms,
      Value<String?>? sourceRecipeId,
      Value<double?>? amount,
      Value<String?>? unit,
      Value<bool>? bought,
      Value<String?>? userId,
      Value<String?>? householdId,
      Value<int?>? createdAt,
      Value<int?>? updatedAt,
      Value<int?>? deletedAt,
      Value<int>? rowid}) {
    return ShoppingListItemsCompanion(
      id: id ?? this.id,
      shoppingListId: shoppingListId ?? this.shoppingListId,
      name: name ?? this.name,
      normalizedTerms: normalizedTerms ?? this.normalizedTerms,
      sourceRecipeId: sourceRecipeId ?? this.sourceRecipeId,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      bought: bought ?? this.bought,
      userId: userId ?? this.userId,
      householdId: householdId ?? this.householdId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
    if (shoppingListId.present) {
      map['shopping_list_id'] = Variable<String>(shoppingListId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (normalizedTerms.present) {
      map['normalized_terms'] = Variable<String>($ShoppingListItemsTable
          .$converternormalizedTermsn
          .toSql(normalizedTerms.value));
    }
    if (sourceRecipeId.present) {
      map['source_recipe_id'] = Variable<String>(sourceRecipeId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (bought.present) {
      map['bought'] = Variable<bool>(bought.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
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
    return (StringBuffer('ShoppingListItemsCompanion(')
          ..write('id: $id, ')
          ..write('shoppingListId: $shoppingListId, ')
          ..write('name: $name, ')
          ..write('normalizedTerms: $normalizedTerms, ')
          ..write('sourceRecipeId: $sourceRecipeId, ')
          ..write('amount: $amount, ')
          ..write('unit: $unit, ')
          ..write('bought: $bought, ')
          ..write('userId: $userId, ')
          ..write('householdId: $householdId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ShoppingListsTable extends ShoppingLists
    with TableInfo<$ShoppingListsTable, ShoppingListEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShoppingListsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      clientDefault: () => const Uuid().v4());
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _householdIdMeta =
      const VerificationMeta('householdId');
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
      'household_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, userId, householdId, createdAt, updatedAt, deletedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shopping_lists';
  @override
  VerificationContext validateIntegrity(Insertable<ShoppingListEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    }
    if (data.containsKey('household_id')) {
      context.handle(
          _householdIdMeta,
          householdId.isAcceptableOrUnknown(
              data['household_id']!, _householdIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ShoppingListEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShoppingListEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name']),
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id']),
      householdId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}household_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at']),
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $ShoppingListsTable createAlias(String alias) {
    return $ShoppingListsTable(attachedDatabase, alias);
  }
}

class ShoppingListEntry extends DataClass
    implements Insertable<ShoppingListEntry> {
  final String id;
  final String? name;
  final String? userId;
  final String? householdId;
  final int? createdAt;
  final int? updatedAt;
  final int? deletedAt;
  const ShoppingListEntry(
      {required this.id,
      this.name,
      this.userId,
      this.householdId,
      this.createdAt,
      this.updatedAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    if (!nullToAbsent || householdId != null) {
      map['household_id'] = Variable<String>(householdId);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<int>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<int>(updatedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  ShoppingListsCompanion toCompanion(bool nullToAbsent) {
    return ShoppingListsCompanion(
      id: Value(id),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      userId:
          userId == null && nullToAbsent ? const Value.absent() : Value(userId),
      householdId: householdId == null && nullToAbsent
          ? const Value.absent()
          : Value(householdId),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory ShoppingListEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShoppingListEntry(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String?>(json['name']),
      userId: serializer.fromJson<String?>(json['userId']),
      householdId: serializer.fromJson<String?>(json['householdId']),
      createdAt: serializer.fromJson<int?>(json['createdAt']),
      updatedAt: serializer.fromJson<int?>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String?>(name),
      'userId': serializer.toJson<String?>(userId),
      'householdId': serializer.toJson<String?>(householdId),
      'createdAt': serializer.toJson<int?>(createdAt),
      'updatedAt': serializer.toJson<int?>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  ShoppingListEntry copyWith(
          {String? id,
          Value<String?> name = const Value.absent(),
          Value<String?> userId = const Value.absent(),
          Value<String?> householdId = const Value.absent(),
          Value<int?> createdAt = const Value.absent(),
          Value<int?> updatedAt = const Value.absent(),
          Value<int?> deletedAt = const Value.absent()}) =>
      ShoppingListEntry(
        id: id ?? this.id,
        name: name.present ? name.value : this.name,
        userId: userId.present ? userId.value : this.userId,
        householdId: householdId.present ? householdId.value : this.householdId,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  ShoppingListEntry copyWithCompanion(ShoppingListsCompanion data) {
    return ShoppingListEntry(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      userId: data.userId.present ? data.userId.value : this.userId,
      householdId:
          data.householdId.present ? data.householdId.value : this.householdId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShoppingListEntry(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('userId: $userId, ')
          ..write('householdId: $householdId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, name, userId, householdId, createdAt, updatedAt, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShoppingListEntry &&
          other.id == this.id &&
          other.name == this.name &&
          other.userId == this.userId &&
          other.householdId == this.householdId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class ShoppingListsCompanion extends UpdateCompanion<ShoppingListEntry> {
  final Value<String> id;
  final Value<String?> name;
  final Value<String?> userId;
  final Value<String?> householdId;
  final Value<int?> createdAt;
  final Value<int?> updatedAt;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const ShoppingListsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.userId = const Value.absent(),
    this.householdId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ShoppingListsCompanion.insert({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.userId = const Value.absent(),
    this.householdId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  static Insertable<ShoppingListEntry> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? userId,
    Expression<String>? householdId,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (userId != null) 'user_id': userId,
      if (householdId != null) 'household_id': householdId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ShoppingListsCompanion copyWith(
      {Value<String>? id,
      Value<String?>? name,
      Value<String?>? userId,
      Value<String?>? householdId,
      Value<int?>? createdAt,
      Value<int?>? updatedAt,
      Value<int?>? deletedAt,
      Value<int>? rowid}) {
    return ShoppingListsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      userId: userId ?? this.userId,
      householdId: householdId ?? this.householdId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
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
    return (StringBuffer('ShoppingListsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('userId: $userId, ')
          ..write('householdId: $householdId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
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
  late final $RecipesTable recipes = $RecipesTable(this);
  late final $RecipeSharesTable recipeShares = $RecipeSharesTable(this);
  late final $HouseholdMembersTable householdMembers =
      $HouseholdMembersTable(this);
  late final $HouseholdsTable households = $HouseholdsTable(this);
  late final $UploadQueuesTable uploadQueues = $UploadQueuesTable(this);
  late final $CooksTable cooks = $CooksTable(this);
  late final $PantryItemsTable pantryItems = $PantryItemsTable(this);
  late final $IngredientTermOverridesTable ingredientTermOverrides =
      $IngredientTermOverridesTable(this);
  late final $ShoppingListItemsTable shoppingListItems =
      $ShoppingListItemsTable(this);
  late final $ShoppingListsTable shoppingLists = $ShoppingListsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        recipeFolders,
        recipes,
        recipeShares,
        householdMembers,
        households,
        uploadQueues,
        cooks,
        pantryItems,
        ingredientTermOverrides,
        shoppingListItems,
        shoppingLists
      ];
}

typedef $$RecipeFoldersTableCreateCompanionBuilder = RecipeFoldersCompanion
    Function({
  Value<String> id,
  required String name,
  Value<String?> userId,
  Value<String?> householdId,
  Value<int?> deletedAt,
  Value<int> rowid,
});
typedef $$RecipeFoldersTableUpdateCompanionBuilder = RecipeFoldersCompanion
    Function({
  Value<String> id,
  Value<String> name,
  Value<String?> userId,
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
            Value<String?> householdId = const Value.absent(),
            Value<int?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RecipeFoldersCompanion(
            id: id,
            name: name,
            userId: userId,
            householdId: householdId,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            Value<String> id = const Value.absent(),
            required String name,
            Value<String?> userId = const Value.absent(),
            Value<String?> householdId = const Value.absent(),
            Value<int?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RecipeFoldersCompanion.insert(
            id: id,
            name: name,
            userId: userId,
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
typedef $$RecipesTableCreateCompanionBuilder = RecipesCompanion Function({
  Value<String> id,
  required String title,
  Value<String?> description,
  Value<int?> rating,
  required String language,
  Value<int?> servings,
  Value<int?> prepTime,
  Value<int?> cookTime,
  Value<int?> totalTime,
  Value<String?> source,
  Value<String?> nutrition,
  Value<String?> generalNotes,
  required String userId,
  Value<String?> householdId,
  Value<int?> createdAt,
  Value<int?> updatedAt,
  Value<int?> deletedAt,
  Value<List<Ingredient>?> ingredients,
  Value<List<Step>?> steps,
  Value<List<String>?> folderIds,
  Value<List<RecipeImage>?> images,
  Value<int> rowid,
});
typedef $$RecipesTableUpdateCompanionBuilder = RecipesCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<String?> description,
  Value<int?> rating,
  Value<String> language,
  Value<int?> servings,
  Value<int?> prepTime,
  Value<int?> cookTime,
  Value<int?> totalTime,
  Value<String?> source,
  Value<String?> nutrition,
  Value<String?> generalNotes,
  Value<String> userId,
  Value<String?> householdId,
  Value<int?> createdAt,
  Value<int?> updatedAt,
  Value<int?> deletedAt,
  Value<List<Ingredient>?> ingredients,
  Value<List<Step>?> steps,
  Value<List<String>?> folderIds,
  Value<List<RecipeImage>?> images,
  Value<int> rowid,
});

class $$RecipesTableFilterComposer
    extends Composer<_$AppDatabase, $RecipesTable> {
  $$RecipesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get rating => $composableBuilder(
      column: $table.rating, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get language => $composableBuilder(
      column: $table.language, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get servings => $composableBuilder(
      column: $table.servings, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get prepTime => $composableBuilder(
      column: $table.prepTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get cookTime => $composableBuilder(
      column: $table.cookTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalTime => $composableBuilder(
      column: $table.totalTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nutrition => $composableBuilder(
      column: $table.nutrition, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get generalNotes => $composableBuilder(
      column: $table.generalNotes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<List<Ingredient>?, List<Ingredient>, String>
      get ingredients => $composableBuilder(
          column: $table.ingredients,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<List<Step>?, List<Step>, String> get steps =>
      $composableBuilder(
          column: $table.steps,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<List<String>?, List<String>, String>
      get folderIds => $composableBuilder(
          column: $table.folderIds,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<List<RecipeImage>?, List<RecipeImage>, String>
      get images => $composableBuilder(
          column: $table.images,
          builder: (column) => ColumnWithTypeConverterFilters(column));
}

class $$RecipesTableOrderingComposer
    extends Composer<_$AppDatabase, $RecipesTable> {
  $$RecipesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get rating => $composableBuilder(
      column: $table.rating, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get language => $composableBuilder(
      column: $table.language, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get servings => $composableBuilder(
      column: $table.servings, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get prepTime => $composableBuilder(
      column: $table.prepTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get cookTime => $composableBuilder(
      column: $table.cookTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalTime => $composableBuilder(
      column: $table.totalTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nutrition => $composableBuilder(
      column: $table.nutrition, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get generalNotes => $composableBuilder(
      column: $table.generalNotes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ingredients => $composableBuilder(
      column: $table.ingredients, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get steps => $composableBuilder(
      column: $table.steps, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get folderIds => $composableBuilder(
      column: $table.folderIds, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get images => $composableBuilder(
      column: $table.images, builder: (column) => ColumnOrderings(column));
}

class $$RecipesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecipesTable> {
  $$RecipesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<int> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<int> get servings =>
      $composableBuilder(column: $table.servings, builder: (column) => column);

  GeneratedColumn<int> get prepTime =>
      $composableBuilder(column: $table.prepTime, builder: (column) => column);

  GeneratedColumn<int> get cookTime =>
      $composableBuilder(column: $table.cookTime, builder: (column) => column);

  GeneratedColumn<int> get totalTime =>
      $composableBuilder(column: $table.totalTime, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get nutrition =>
      $composableBuilder(column: $table.nutrition, builder: (column) => column);

  GeneratedColumn<String> get generalNotes => $composableBuilder(
      column: $table.generalNotes, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<Ingredient>?, String> get ingredients =>
      $composableBuilder(
          column: $table.ingredients, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<Step>?, String> get steps =>
      $composableBuilder(column: $table.steps, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>?, String> get folderIds =>
      $composableBuilder(column: $table.folderIds, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<RecipeImage>?, String> get images =>
      $composableBuilder(column: $table.images, builder: (column) => column);
}

class $$RecipesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RecipesTable,
    RecipeEntry,
    $$RecipesTableFilterComposer,
    $$RecipesTableOrderingComposer,
    $$RecipesTableAnnotationComposer,
    $$RecipesTableCreateCompanionBuilder,
    $$RecipesTableUpdateCompanionBuilder,
    (RecipeEntry, BaseReferences<_$AppDatabase, $RecipesTable, RecipeEntry>),
    RecipeEntry,
    PrefetchHooks Function()> {
  $$RecipesTableTableManager(_$AppDatabase db, $RecipesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecipesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecipesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecipesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<int?> rating = const Value.absent(),
            Value<String> language = const Value.absent(),
            Value<int?> servings = const Value.absent(),
            Value<int?> prepTime = const Value.absent(),
            Value<int?> cookTime = const Value.absent(),
            Value<int?> totalTime = const Value.absent(),
            Value<String?> source = const Value.absent(),
            Value<String?> nutrition = const Value.absent(),
            Value<String?> generalNotes = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String?> householdId = const Value.absent(),
            Value<int?> createdAt = const Value.absent(),
            Value<int?> updatedAt = const Value.absent(),
            Value<int?> deletedAt = const Value.absent(),
            Value<List<Ingredient>?> ingredients = const Value.absent(),
            Value<List<Step>?> steps = const Value.absent(),
            Value<List<String>?> folderIds = const Value.absent(),
            Value<List<RecipeImage>?> images = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RecipesCompanion(
            id: id,
            title: title,
            description: description,
            rating: rating,
            language: language,
            servings: servings,
            prepTime: prepTime,
            cookTime: cookTime,
            totalTime: totalTime,
            source: source,
            nutrition: nutrition,
            generalNotes: generalNotes,
            userId: userId,
            householdId: householdId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            ingredients: ingredients,
            steps: steps,
            folderIds: folderIds,
            images: images,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            Value<String> id = const Value.absent(),
            required String title,
            Value<String?> description = const Value.absent(),
            Value<int?> rating = const Value.absent(),
            required String language,
            Value<int?> servings = const Value.absent(),
            Value<int?> prepTime = const Value.absent(),
            Value<int?> cookTime = const Value.absent(),
            Value<int?> totalTime = const Value.absent(),
            Value<String?> source = const Value.absent(),
            Value<String?> nutrition = const Value.absent(),
            Value<String?> generalNotes = const Value.absent(),
            required String userId,
            Value<String?> householdId = const Value.absent(),
            Value<int?> createdAt = const Value.absent(),
            Value<int?> updatedAt = const Value.absent(),
            Value<int?> deletedAt = const Value.absent(),
            Value<List<Ingredient>?> ingredients = const Value.absent(),
            Value<List<Step>?> steps = const Value.absent(),
            Value<List<String>?> folderIds = const Value.absent(),
            Value<List<RecipeImage>?> images = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RecipesCompanion.insert(
            id: id,
            title: title,
            description: description,
            rating: rating,
            language: language,
            servings: servings,
            prepTime: prepTime,
            cookTime: cookTime,
            totalTime: totalTime,
            source: source,
            nutrition: nutrition,
            generalNotes: generalNotes,
            userId: userId,
            householdId: householdId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            ingredients: ingredients,
            steps: steps,
            folderIds: folderIds,
            images: images,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RecipesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RecipesTable,
    RecipeEntry,
    $$RecipesTableFilterComposer,
    $$RecipesTableOrderingComposer,
    $$RecipesTableAnnotationComposer,
    $$RecipesTableCreateCompanionBuilder,
    $$RecipesTableUpdateCompanionBuilder,
    (RecipeEntry, BaseReferences<_$AppDatabase, $RecipesTable, RecipeEntry>),
    RecipeEntry,
    PrefetchHooks Function()>;
typedef $$RecipeSharesTableCreateCompanionBuilder = RecipeSharesCompanion
    Function({
  Value<String> id,
  required String recipeId,
  Value<String?> householdId,
  Value<String?> userId,
  Value<int> canEdit,
  Value<int> rowid,
});
typedef $$RecipeSharesTableUpdateCompanionBuilder = RecipeSharesCompanion
    Function({
  Value<String> id,
  Value<String> recipeId,
  Value<String?> householdId,
  Value<String?> userId,
  Value<int> canEdit,
  Value<int> rowid,
});

class $$RecipeSharesTableFilterComposer
    extends Composer<_$AppDatabase, $RecipeSharesTable> {
  $$RecipeSharesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get recipeId => $composableBuilder(
      column: $table.recipeId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get canEdit => $composableBuilder(
      column: $table.canEdit, builder: (column) => ColumnFilters(column));
}

class $$RecipeSharesTableOrderingComposer
    extends Composer<_$AppDatabase, $RecipeSharesTable> {
  $$RecipeSharesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get recipeId => $composableBuilder(
      column: $table.recipeId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get canEdit => $composableBuilder(
      column: $table.canEdit, builder: (column) => ColumnOrderings(column));
}

class $$RecipeSharesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecipeSharesTable> {
  $$RecipeSharesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get recipeId =>
      $composableBuilder(column: $table.recipeId, builder: (column) => column);

  GeneratedColumn<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<int> get canEdit =>
      $composableBuilder(column: $table.canEdit, builder: (column) => column);
}

class $$RecipeSharesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RecipeSharesTable,
    RecipeShareEntry,
    $$RecipeSharesTableFilterComposer,
    $$RecipeSharesTableOrderingComposer,
    $$RecipeSharesTableAnnotationComposer,
    $$RecipeSharesTableCreateCompanionBuilder,
    $$RecipeSharesTableUpdateCompanionBuilder,
    (
      RecipeShareEntry,
      BaseReferences<_$AppDatabase, $RecipeSharesTable, RecipeShareEntry>
    ),
    RecipeShareEntry,
    PrefetchHooks Function()> {
  $$RecipeSharesTableTableManager(_$AppDatabase db, $RecipeSharesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecipeSharesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecipeSharesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecipeSharesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> recipeId = const Value.absent(),
            Value<String?> householdId = const Value.absent(),
            Value<String?> userId = const Value.absent(),
            Value<int> canEdit = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RecipeSharesCompanion(
            id: id,
            recipeId: recipeId,
            householdId: householdId,
            userId: userId,
            canEdit: canEdit,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            Value<String> id = const Value.absent(),
            required String recipeId,
            Value<String?> householdId = const Value.absent(),
            Value<String?> userId = const Value.absent(),
            Value<int> canEdit = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RecipeSharesCompanion.insert(
            id: id,
            recipeId: recipeId,
            householdId: householdId,
            userId: userId,
            canEdit: canEdit,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RecipeSharesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RecipeSharesTable,
    RecipeShareEntry,
    $$RecipeSharesTableFilterComposer,
    $$RecipeSharesTableOrderingComposer,
    $$RecipeSharesTableAnnotationComposer,
    $$RecipeSharesTableCreateCompanionBuilder,
    $$RecipeSharesTableUpdateCompanionBuilder,
    (
      RecipeShareEntry,
      BaseReferences<_$AppDatabase, $RecipeSharesTable, RecipeShareEntry>
    ),
    RecipeShareEntry,
    PrefetchHooks Function()>;
typedef $$HouseholdMembersTableCreateCompanionBuilder
    = HouseholdMembersCompanion Function({
  Value<String> id,
  required String householdId,
  required String userId,
  Value<int> isActive,
  Value<int> rowid,
});
typedef $$HouseholdMembersTableUpdateCompanionBuilder
    = HouseholdMembersCompanion Function({
  Value<String> id,
  Value<String> householdId,
  Value<String> userId,
  Value<int> isActive,
  Value<int> rowid,
});

class $$HouseholdMembersTableFilterComposer
    extends Composer<_$AppDatabase, $HouseholdMembersTable> {
  $$HouseholdMembersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));
}

class $$HouseholdMembersTableOrderingComposer
    extends Composer<_$AppDatabase, $HouseholdMembersTable> {
  $$HouseholdMembersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));
}

class $$HouseholdMembersTableAnnotationComposer
    extends Composer<_$AppDatabase, $HouseholdMembersTable> {
  $$HouseholdMembersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<int> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);
}

class $$HouseholdMembersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $HouseholdMembersTable,
    HouseholdMemberEntry,
    $$HouseholdMembersTableFilterComposer,
    $$HouseholdMembersTableOrderingComposer,
    $$HouseholdMembersTableAnnotationComposer,
    $$HouseholdMembersTableCreateCompanionBuilder,
    $$HouseholdMembersTableUpdateCompanionBuilder,
    (
      HouseholdMemberEntry,
      BaseReferences<_$AppDatabase, $HouseholdMembersTable,
          HouseholdMemberEntry>
    ),
    HouseholdMemberEntry,
    PrefetchHooks Function()> {
  $$HouseholdMembersTableTableManager(
      _$AppDatabase db, $HouseholdMembersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HouseholdMembersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HouseholdMembersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HouseholdMembersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> householdId = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<int> isActive = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              HouseholdMembersCompanion(
            id: id,
            householdId: householdId,
            userId: userId,
            isActive: isActive,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            Value<String> id = const Value.absent(),
            required String householdId,
            required String userId,
            Value<int> isActive = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              HouseholdMembersCompanion.insert(
            id: id,
            householdId: householdId,
            userId: userId,
            isActive: isActive,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$HouseholdMembersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $HouseholdMembersTable,
    HouseholdMemberEntry,
    $$HouseholdMembersTableFilterComposer,
    $$HouseholdMembersTableOrderingComposer,
    $$HouseholdMembersTableAnnotationComposer,
    $$HouseholdMembersTableCreateCompanionBuilder,
    $$HouseholdMembersTableUpdateCompanionBuilder,
    (
      HouseholdMemberEntry,
      BaseReferences<_$AppDatabase, $HouseholdMembersTable,
          HouseholdMemberEntry>
    ),
    HouseholdMemberEntry,
    PrefetchHooks Function()>;
typedef $$HouseholdsTableCreateCompanionBuilder = HouseholdsCompanion Function({
  Value<String> id,
  required String name,
  required String userId,
  Value<int> rowid,
});
typedef $$HouseholdsTableUpdateCompanionBuilder = HouseholdsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> userId,
  Value<int> rowid,
});

class $$HouseholdsTableFilterComposer
    extends Composer<_$AppDatabase, $HouseholdsTable> {
  $$HouseholdsTableFilterComposer({
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
}

class $$HouseholdsTableOrderingComposer
    extends Composer<_$AppDatabase, $HouseholdsTable> {
  $$HouseholdsTableOrderingComposer({
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
}

class $$HouseholdsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HouseholdsTable> {
  $$HouseholdsTableAnnotationComposer({
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
}

class $$HouseholdsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $HouseholdsTable,
    HouseholdEntry,
    $$HouseholdsTableFilterComposer,
    $$HouseholdsTableOrderingComposer,
    $$HouseholdsTableAnnotationComposer,
    $$HouseholdsTableCreateCompanionBuilder,
    $$HouseholdsTableUpdateCompanionBuilder,
    (
      HouseholdEntry,
      BaseReferences<_$AppDatabase, $HouseholdsTable, HouseholdEntry>
    ),
    HouseholdEntry,
    PrefetchHooks Function()> {
  $$HouseholdsTableTableManager(_$AppDatabase db, $HouseholdsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HouseholdsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HouseholdsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HouseholdsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              HouseholdsCompanion(
            id: id,
            name: name,
            userId: userId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            Value<String> id = const Value.absent(),
            required String name,
            required String userId,
            Value<int> rowid = const Value.absent(),
          }) =>
              HouseholdsCompanion.insert(
            id: id,
            name: name,
            userId: userId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$HouseholdsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $HouseholdsTable,
    HouseholdEntry,
    $$HouseholdsTableFilterComposer,
    $$HouseholdsTableOrderingComposer,
    $$HouseholdsTableAnnotationComposer,
    $$HouseholdsTableCreateCompanionBuilder,
    $$HouseholdsTableUpdateCompanionBuilder,
    (
      HouseholdEntry,
      BaseReferences<_$AppDatabase, $HouseholdsTable, HouseholdEntry>
    ),
    HouseholdEntry,
    PrefetchHooks Function()>;
typedef $$UploadQueuesTableCreateCompanionBuilder = UploadQueuesCompanion
    Function({
  Value<String> id,
  required String fileName,
  Value<String> status,
  Value<int> retryCount,
  Value<int?> lastTryTimestamp,
  required String recipeId,
  Value<int> rowid,
});
typedef $$UploadQueuesTableUpdateCompanionBuilder = UploadQueuesCompanion
    Function({
  Value<String> id,
  Value<String> fileName,
  Value<String> status,
  Value<int> retryCount,
  Value<int?> lastTryTimestamp,
  Value<String> recipeId,
  Value<int> rowid,
});

class $$UploadQueuesTableFilterComposer
    extends Composer<_$AppDatabase, $UploadQueuesTable> {
  $$UploadQueuesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fileName => $composableBuilder(
      column: $table.fileName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastTryTimestamp => $composableBuilder(
      column: $table.lastTryTimestamp,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get recipeId => $composableBuilder(
      column: $table.recipeId, builder: (column) => ColumnFilters(column));
}

class $$UploadQueuesTableOrderingComposer
    extends Composer<_$AppDatabase, $UploadQueuesTable> {
  $$UploadQueuesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fileName => $composableBuilder(
      column: $table.fileName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastTryTimestamp => $composableBuilder(
      column: $table.lastTryTimestamp,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get recipeId => $composableBuilder(
      column: $table.recipeId, builder: (column) => ColumnOrderings(column));
}

class $$UploadQueuesTableAnnotationComposer
    extends Composer<_$AppDatabase, $UploadQueuesTable> {
  $$UploadQueuesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => column);

  GeneratedColumn<int> get lastTryTimestamp => $composableBuilder(
      column: $table.lastTryTimestamp, builder: (column) => column);

  GeneratedColumn<String> get recipeId =>
      $composableBuilder(column: $table.recipeId, builder: (column) => column);
}

class $$UploadQueuesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UploadQueuesTable,
    UploadQueueEntry,
    $$UploadQueuesTableFilterComposer,
    $$UploadQueuesTableOrderingComposer,
    $$UploadQueuesTableAnnotationComposer,
    $$UploadQueuesTableCreateCompanionBuilder,
    $$UploadQueuesTableUpdateCompanionBuilder,
    (
      UploadQueueEntry,
      BaseReferences<_$AppDatabase, $UploadQueuesTable, UploadQueueEntry>
    ),
    UploadQueueEntry,
    PrefetchHooks Function()> {
  $$UploadQueuesTableTableManager(_$AppDatabase db, $UploadQueuesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UploadQueuesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UploadQueuesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UploadQueuesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> fileName = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
            Value<int?> lastTryTimestamp = const Value.absent(),
            Value<String> recipeId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UploadQueuesCompanion(
            id: id,
            fileName: fileName,
            status: status,
            retryCount: retryCount,
            lastTryTimestamp: lastTryTimestamp,
            recipeId: recipeId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            Value<String> id = const Value.absent(),
            required String fileName,
            Value<String> status = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
            Value<int?> lastTryTimestamp = const Value.absent(),
            required String recipeId,
            Value<int> rowid = const Value.absent(),
          }) =>
              UploadQueuesCompanion.insert(
            id: id,
            fileName: fileName,
            status: status,
            retryCount: retryCount,
            lastTryTimestamp: lastTryTimestamp,
            recipeId: recipeId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$UploadQueuesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $UploadQueuesTable,
    UploadQueueEntry,
    $$UploadQueuesTableFilterComposer,
    $$UploadQueuesTableOrderingComposer,
    $$UploadQueuesTableAnnotationComposer,
    $$UploadQueuesTableCreateCompanionBuilder,
    $$UploadQueuesTableUpdateCompanionBuilder,
    (
      UploadQueueEntry,
      BaseReferences<_$AppDatabase, $UploadQueuesTable, UploadQueueEntry>
    ),
    UploadQueueEntry,
    PrefetchHooks Function()>;
typedef $$CooksTableCreateCompanionBuilder = CooksCompanion Function({
  Value<String> id,
  required String recipeId,
  Value<String?> userId,
  Value<String?> householdId,
  Value<int> currentStepIndex,
  Value<CookStatus> status,
  Value<int?> startedAt,
  Value<int?> finishedAt,
  Value<int?> updatedAt,
  Value<int?> rating,
  required String recipeName,
  Value<String?> notes,
  Value<int> rowid,
});
typedef $$CooksTableUpdateCompanionBuilder = CooksCompanion Function({
  Value<String> id,
  Value<String> recipeId,
  Value<String?> userId,
  Value<String?> householdId,
  Value<int> currentStepIndex,
  Value<CookStatus> status,
  Value<int?> startedAt,
  Value<int?> finishedAt,
  Value<int?> updatedAt,
  Value<int?> rating,
  Value<String> recipeName,
  Value<String?> notes,
  Value<int> rowid,
});

class $$CooksTableFilterComposer extends Composer<_$AppDatabase, $CooksTable> {
  $$CooksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get recipeId => $composableBuilder(
      column: $table.recipeId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get currentStepIndex => $composableBuilder(
      column: $table.currentStepIndex,
      builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<CookStatus, CookStatus, String> get status =>
      $composableBuilder(
          column: $table.status,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get finishedAt => $composableBuilder(
      column: $table.finishedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get rating => $composableBuilder(
      column: $table.rating, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get recipeName => $composableBuilder(
      column: $table.recipeName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));
}

class $$CooksTableOrderingComposer
    extends Composer<_$AppDatabase, $CooksTable> {
  $$CooksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get recipeId => $composableBuilder(
      column: $table.recipeId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get currentStepIndex => $composableBuilder(
      column: $table.currentStepIndex,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get finishedAt => $composableBuilder(
      column: $table.finishedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get rating => $composableBuilder(
      column: $table.rating, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get recipeName => $composableBuilder(
      column: $table.recipeName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));
}

class $$CooksTableAnnotationComposer
    extends Composer<_$AppDatabase, $CooksTable> {
  $$CooksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get recipeId =>
      $composableBuilder(column: $table.recipeId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => column);

  GeneratedColumn<int> get currentStepIndex => $composableBuilder(
      column: $table.currentStepIndex, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CookStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<int> get finishedAt => $composableBuilder(
      column: $table.finishedAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<String> get recipeName => $composableBuilder(
      column: $table.recipeName, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);
}

class $$CooksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CooksTable,
    CookEntry,
    $$CooksTableFilterComposer,
    $$CooksTableOrderingComposer,
    $$CooksTableAnnotationComposer,
    $$CooksTableCreateCompanionBuilder,
    $$CooksTableUpdateCompanionBuilder,
    (CookEntry, BaseReferences<_$AppDatabase, $CooksTable, CookEntry>),
    CookEntry,
    PrefetchHooks Function()> {
  $$CooksTableTableManager(_$AppDatabase db, $CooksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CooksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CooksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CooksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> recipeId = const Value.absent(),
            Value<String?> userId = const Value.absent(),
            Value<String?> householdId = const Value.absent(),
            Value<int> currentStepIndex = const Value.absent(),
            Value<CookStatus> status = const Value.absent(),
            Value<int?> startedAt = const Value.absent(),
            Value<int?> finishedAt = const Value.absent(),
            Value<int?> updatedAt = const Value.absent(),
            Value<int?> rating = const Value.absent(),
            Value<String> recipeName = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CooksCompanion(
            id: id,
            recipeId: recipeId,
            userId: userId,
            householdId: householdId,
            currentStepIndex: currentStepIndex,
            status: status,
            startedAt: startedAt,
            finishedAt: finishedAt,
            updatedAt: updatedAt,
            rating: rating,
            recipeName: recipeName,
            notes: notes,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            Value<String> id = const Value.absent(),
            required String recipeId,
            Value<String?> userId = const Value.absent(),
            Value<String?> householdId = const Value.absent(),
            Value<int> currentStepIndex = const Value.absent(),
            Value<CookStatus> status = const Value.absent(),
            Value<int?> startedAt = const Value.absent(),
            Value<int?> finishedAt = const Value.absent(),
            Value<int?> updatedAt = const Value.absent(),
            Value<int?> rating = const Value.absent(),
            required String recipeName,
            Value<String?> notes = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CooksCompanion.insert(
            id: id,
            recipeId: recipeId,
            userId: userId,
            householdId: householdId,
            currentStepIndex: currentStepIndex,
            status: status,
            startedAt: startedAt,
            finishedAt: finishedAt,
            updatedAt: updatedAt,
            rating: rating,
            recipeName: recipeName,
            notes: notes,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CooksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CooksTable,
    CookEntry,
    $$CooksTableFilterComposer,
    $$CooksTableOrderingComposer,
    $$CooksTableAnnotationComposer,
    $$CooksTableCreateCompanionBuilder,
    $$CooksTableUpdateCompanionBuilder,
    (CookEntry, BaseReferences<_$AppDatabase, $CooksTable, CookEntry>),
    CookEntry,
    PrefetchHooks Function()>;
typedef $$PantryItemsTableCreateCompanionBuilder = PantryItemsCompanion
    Function({
  Value<String> id,
  required String name,
  Value<bool> inStock,
  Value<String?> userId,
  Value<String?> householdId,
  Value<int?> createdAt,
  Value<int?> updatedAt,
  Value<int?> deletedAt,
  Value<List<PantryItemTerm>?> terms,
  Value<int> rowid,
});
typedef $$PantryItemsTableUpdateCompanionBuilder = PantryItemsCompanion
    Function({
  Value<String> id,
  Value<String> name,
  Value<bool> inStock,
  Value<String?> userId,
  Value<String?> householdId,
  Value<int?> createdAt,
  Value<int?> updatedAt,
  Value<int?> deletedAt,
  Value<List<PantryItemTerm>?> terms,
  Value<int> rowid,
});

class $$PantryItemsTableFilterComposer
    extends Composer<_$AppDatabase, $PantryItemsTable> {
  $$PantryItemsTableFilterComposer({
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

  ColumnFilters<bool> get inStock => $composableBuilder(
      column: $table.inStock, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<List<PantryItemTerm>?, List<PantryItemTerm>,
          String>
      get terms => $composableBuilder(
          column: $table.terms,
          builder: (column) => ColumnWithTypeConverterFilters(column));
}

class $$PantryItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $PantryItemsTable> {
  $$PantryItemsTableOrderingComposer({
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

  ColumnOrderings<bool> get inStock => $composableBuilder(
      column: $table.inStock, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get terms => $composableBuilder(
      column: $table.terms, builder: (column) => ColumnOrderings(column));
}

class $$PantryItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PantryItemsTable> {
  $$PantryItemsTableAnnotationComposer({
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

  GeneratedColumn<bool> get inStock =>
      $composableBuilder(column: $table.inStock, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<PantryItemTerm>?, String> get terms =>
      $composableBuilder(column: $table.terms, builder: (column) => column);
}

class $$PantryItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PantryItemsTable,
    PantryItemEntry,
    $$PantryItemsTableFilterComposer,
    $$PantryItemsTableOrderingComposer,
    $$PantryItemsTableAnnotationComposer,
    $$PantryItemsTableCreateCompanionBuilder,
    $$PantryItemsTableUpdateCompanionBuilder,
    (
      PantryItemEntry,
      BaseReferences<_$AppDatabase, $PantryItemsTable, PantryItemEntry>
    ),
    PantryItemEntry,
    PrefetchHooks Function()> {
  $$PantryItemsTableTableManager(_$AppDatabase db, $PantryItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PantryItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PantryItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PantryItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<bool> inStock = const Value.absent(),
            Value<String?> userId = const Value.absent(),
            Value<String?> householdId = const Value.absent(),
            Value<int?> createdAt = const Value.absent(),
            Value<int?> updatedAt = const Value.absent(),
            Value<int?> deletedAt = const Value.absent(),
            Value<List<PantryItemTerm>?> terms = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PantryItemsCompanion(
            id: id,
            name: name,
            inStock: inStock,
            userId: userId,
            householdId: householdId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            terms: terms,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            Value<String> id = const Value.absent(),
            required String name,
            Value<bool> inStock = const Value.absent(),
            Value<String?> userId = const Value.absent(),
            Value<String?> householdId = const Value.absent(),
            Value<int?> createdAt = const Value.absent(),
            Value<int?> updatedAt = const Value.absent(),
            Value<int?> deletedAt = const Value.absent(),
            Value<List<PantryItemTerm>?> terms = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PantryItemsCompanion.insert(
            id: id,
            name: name,
            inStock: inStock,
            userId: userId,
            householdId: householdId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            terms: terms,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PantryItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PantryItemsTable,
    PantryItemEntry,
    $$PantryItemsTableFilterComposer,
    $$PantryItemsTableOrderingComposer,
    $$PantryItemsTableAnnotationComposer,
    $$PantryItemsTableCreateCompanionBuilder,
    $$PantryItemsTableUpdateCompanionBuilder,
    (
      PantryItemEntry,
      BaseReferences<_$AppDatabase, $PantryItemsTable, PantryItemEntry>
    ),
    PantryItemEntry,
    PrefetchHooks Function()>;
typedef $$IngredientTermOverridesTableCreateCompanionBuilder
    = IngredientTermOverridesCompanion Function({
  Value<String> id,
  required String inputTerm,
  required String mappedTerm,
  Value<String?> userId,
  Value<String?> householdId,
  Value<int?> createdAt,
  Value<int?> deletedAt,
  Value<int> rowid,
});
typedef $$IngredientTermOverridesTableUpdateCompanionBuilder
    = IngredientTermOverridesCompanion Function({
  Value<String> id,
  Value<String> inputTerm,
  Value<String> mappedTerm,
  Value<String?> userId,
  Value<String?> householdId,
  Value<int?> createdAt,
  Value<int?> deletedAt,
  Value<int> rowid,
});

class $$IngredientTermOverridesTableFilterComposer
    extends Composer<_$AppDatabase, $IngredientTermOverridesTable> {
  $$IngredientTermOverridesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get inputTerm => $composableBuilder(
      column: $table.inputTerm, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mappedTerm => $composableBuilder(
      column: $table.mappedTerm, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));
}

class $$IngredientTermOverridesTableOrderingComposer
    extends Composer<_$AppDatabase, $IngredientTermOverridesTable> {
  $$IngredientTermOverridesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get inputTerm => $composableBuilder(
      column: $table.inputTerm, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mappedTerm => $composableBuilder(
      column: $table.mappedTerm, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));
}

class $$IngredientTermOverridesTableAnnotationComposer
    extends Composer<_$AppDatabase, $IngredientTermOverridesTable> {
  $$IngredientTermOverridesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get inputTerm =>
      $composableBuilder(column: $table.inputTerm, builder: (column) => column);

  GeneratedColumn<String> get mappedTerm => $composableBuilder(
      column: $table.mappedTerm, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$IngredientTermOverridesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $IngredientTermOverridesTable,
    IngredientTermOverrideEntry,
    $$IngredientTermOverridesTableFilterComposer,
    $$IngredientTermOverridesTableOrderingComposer,
    $$IngredientTermOverridesTableAnnotationComposer,
    $$IngredientTermOverridesTableCreateCompanionBuilder,
    $$IngredientTermOverridesTableUpdateCompanionBuilder,
    (
      IngredientTermOverrideEntry,
      BaseReferences<_$AppDatabase, $IngredientTermOverridesTable,
          IngredientTermOverrideEntry>
    ),
    IngredientTermOverrideEntry,
    PrefetchHooks Function()> {
  $$IngredientTermOverridesTableTableManager(
      _$AppDatabase db, $IngredientTermOverridesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IngredientTermOverridesTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$IngredientTermOverridesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IngredientTermOverridesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> inputTerm = const Value.absent(),
            Value<String> mappedTerm = const Value.absent(),
            Value<String?> userId = const Value.absent(),
            Value<String?> householdId = const Value.absent(),
            Value<int?> createdAt = const Value.absent(),
            Value<int?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              IngredientTermOverridesCompanion(
            id: id,
            inputTerm: inputTerm,
            mappedTerm: mappedTerm,
            userId: userId,
            householdId: householdId,
            createdAt: createdAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            Value<String> id = const Value.absent(),
            required String inputTerm,
            required String mappedTerm,
            Value<String?> userId = const Value.absent(),
            Value<String?> householdId = const Value.absent(),
            Value<int?> createdAt = const Value.absent(),
            Value<int?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              IngredientTermOverridesCompanion.insert(
            id: id,
            inputTerm: inputTerm,
            mappedTerm: mappedTerm,
            userId: userId,
            householdId: householdId,
            createdAt: createdAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$IngredientTermOverridesTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $IngredientTermOverridesTable,
        IngredientTermOverrideEntry,
        $$IngredientTermOverridesTableFilterComposer,
        $$IngredientTermOverridesTableOrderingComposer,
        $$IngredientTermOverridesTableAnnotationComposer,
        $$IngredientTermOverridesTableCreateCompanionBuilder,
        $$IngredientTermOverridesTableUpdateCompanionBuilder,
        (
          IngredientTermOverrideEntry,
          BaseReferences<_$AppDatabase, $IngredientTermOverridesTable,
              IngredientTermOverrideEntry>
        ),
        IngredientTermOverrideEntry,
        PrefetchHooks Function()>;
typedef $$ShoppingListItemsTableCreateCompanionBuilder
    = ShoppingListItemsCompanion Function({
  Value<String> id,
  required String shoppingListId,
  required String name,
  Value<List<String>?> normalizedTerms,
  Value<String?> sourceRecipeId,
  Value<double?> amount,
  Value<String?> unit,
  Value<bool> bought,
  Value<String?> userId,
  Value<String?> householdId,
  Value<int?> createdAt,
  Value<int?> updatedAt,
  Value<int?> deletedAt,
  Value<int> rowid,
});
typedef $$ShoppingListItemsTableUpdateCompanionBuilder
    = ShoppingListItemsCompanion Function({
  Value<String> id,
  Value<String> shoppingListId,
  Value<String> name,
  Value<List<String>?> normalizedTerms,
  Value<String?> sourceRecipeId,
  Value<double?> amount,
  Value<String?> unit,
  Value<bool> bought,
  Value<String?> userId,
  Value<String?> householdId,
  Value<int?> createdAt,
  Value<int?> updatedAt,
  Value<int?> deletedAt,
  Value<int> rowid,
});

class $$ShoppingListItemsTableFilterComposer
    extends Composer<_$AppDatabase, $ShoppingListItemsTable> {
  $$ShoppingListItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get shoppingListId => $composableBuilder(
      column: $table.shoppingListId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<List<String>?, List<String>, String>
      get normalizedTerms => $composableBuilder(
          column: $table.normalizedTerms,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get sourceRecipeId => $composableBuilder(
      column: $table.sourceRecipeId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get bought => $composableBuilder(
      column: $table.bought, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));
}

class $$ShoppingListItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $ShoppingListItemsTable> {
  $$ShoppingListItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get shoppingListId => $composableBuilder(
      column: $table.shoppingListId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get normalizedTerms => $composableBuilder(
      column: $table.normalizedTerms,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceRecipeId => $composableBuilder(
      column: $table.sourceRecipeId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get bought => $composableBuilder(
      column: $table.bought, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));
}

class $$ShoppingListItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShoppingListItemsTable> {
  $$ShoppingListItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get shoppingListId => $composableBuilder(
      column: $table.shoppingListId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>?, String> get normalizedTerms =>
      $composableBuilder(
          column: $table.normalizedTerms, builder: (column) => column);

  GeneratedColumn<String> get sourceRecipeId => $composableBuilder(
      column: $table.sourceRecipeId, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<bool> get bought =>
      $composableBuilder(column: $table.bought, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$ShoppingListItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ShoppingListItemsTable,
    ShoppingListItemEntry,
    $$ShoppingListItemsTableFilterComposer,
    $$ShoppingListItemsTableOrderingComposer,
    $$ShoppingListItemsTableAnnotationComposer,
    $$ShoppingListItemsTableCreateCompanionBuilder,
    $$ShoppingListItemsTableUpdateCompanionBuilder,
    (
      ShoppingListItemEntry,
      BaseReferences<_$AppDatabase, $ShoppingListItemsTable,
          ShoppingListItemEntry>
    ),
    ShoppingListItemEntry,
    PrefetchHooks Function()> {
  $$ShoppingListItemsTableTableManager(
      _$AppDatabase db, $ShoppingListItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShoppingListItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShoppingListItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShoppingListItemsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> shoppingListId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<List<String>?> normalizedTerms = const Value.absent(),
            Value<String?> sourceRecipeId = const Value.absent(),
            Value<double?> amount = const Value.absent(),
            Value<String?> unit = const Value.absent(),
            Value<bool> bought = const Value.absent(),
            Value<String?> userId = const Value.absent(),
            Value<String?> householdId = const Value.absent(),
            Value<int?> createdAt = const Value.absent(),
            Value<int?> updatedAt = const Value.absent(),
            Value<int?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ShoppingListItemsCompanion(
            id: id,
            shoppingListId: shoppingListId,
            name: name,
            normalizedTerms: normalizedTerms,
            sourceRecipeId: sourceRecipeId,
            amount: amount,
            unit: unit,
            bought: bought,
            userId: userId,
            householdId: householdId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            Value<String> id = const Value.absent(),
            required String shoppingListId,
            required String name,
            Value<List<String>?> normalizedTerms = const Value.absent(),
            Value<String?> sourceRecipeId = const Value.absent(),
            Value<double?> amount = const Value.absent(),
            Value<String?> unit = const Value.absent(),
            Value<bool> bought = const Value.absent(),
            Value<String?> userId = const Value.absent(),
            Value<String?> householdId = const Value.absent(),
            Value<int?> createdAt = const Value.absent(),
            Value<int?> updatedAt = const Value.absent(),
            Value<int?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ShoppingListItemsCompanion.insert(
            id: id,
            shoppingListId: shoppingListId,
            name: name,
            normalizedTerms: normalizedTerms,
            sourceRecipeId: sourceRecipeId,
            amount: amount,
            unit: unit,
            bought: bought,
            userId: userId,
            householdId: householdId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ShoppingListItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ShoppingListItemsTable,
    ShoppingListItemEntry,
    $$ShoppingListItemsTableFilterComposer,
    $$ShoppingListItemsTableOrderingComposer,
    $$ShoppingListItemsTableAnnotationComposer,
    $$ShoppingListItemsTableCreateCompanionBuilder,
    $$ShoppingListItemsTableUpdateCompanionBuilder,
    (
      ShoppingListItemEntry,
      BaseReferences<_$AppDatabase, $ShoppingListItemsTable,
          ShoppingListItemEntry>
    ),
    ShoppingListItemEntry,
    PrefetchHooks Function()>;
typedef $$ShoppingListsTableCreateCompanionBuilder = ShoppingListsCompanion
    Function({
  Value<String> id,
  Value<String?> name,
  Value<String?> userId,
  Value<String?> householdId,
  Value<int?> createdAt,
  Value<int?> updatedAt,
  Value<int?> deletedAt,
  Value<int> rowid,
});
typedef $$ShoppingListsTableUpdateCompanionBuilder = ShoppingListsCompanion
    Function({
  Value<String> id,
  Value<String?> name,
  Value<String?> userId,
  Value<String?> householdId,
  Value<int?> createdAt,
  Value<int?> updatedAt,
  Value<int?> deletedAt,
  Value<int> rowid,
});

class $$ShoppingListsTableFilterComposer
    extends Composer<_$AppDatabase, $ShoppingListsTable> {
  $$ShoppingListsTableFilterComposer({
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

  ColumnFilters<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));
}

class $$ShoppingListsTableOrderingComposer
    extends Composer<_$AppDatabase, $ShoppingListsTable> {
  $$ShoppingListsTableOrderingComposer({
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

  ColumnOrderings<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));
}

class $$ShoppingListsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShoppingListsTable> {
  $$ShoppingListsTableAnnotationComposer({
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

  GeneratedColumn<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$ShoppingListsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ShoppingListsTable,
    ShoppingListEntry,
    $$ShoppingListsTableFilterComposer,
    $$ShoppingListsTableOrderingComposer,
    $$ShoppingListsTableAnnotationComposer,
    $$ShoppingListsTableCreateCompanionBuilder,
    $$ShoppingListsTableUpdateCompanionBuilder,
    (
      ShoppingListEntry,
      BaseReferences<_$AppDatabase, $ShoppingListsTable, ShoppingListEntry>
    ),
    ShoppingListEntry,
    PrefetchHooks Function()> {
  $$ShoppingListsTableTableManager(_$AppDatabase db, $ShoppingListsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShoppingListsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShoppingListsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShoppingListsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String?> name = const Value.absent(),
            Value<String?> userId = const Value.absent(),
            Value<String?> householdId = const Value.absent(),
            Value<int?> createdAt = const Value.absent(),
            Value<int?> updatedAt = const Value.absent(),
            Value<int?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ShoppingListsCompanion(
            id: id,
            name: name,
            userId: userId,
            householdId: householdId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String?> name = const Value.absent(),
            Value<String?> userId = const Value.absent(),
            Value<String?> householdId = const Value.absent(),
            Value<int?> createdAt = const Value.absent(),
            Value<int?> updatedAt = const Value.absent(),
            Value<int?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ShoppingListsCompanion.insert(
            id: id,
            name: name,
            userId: userId,
            householdId: householdId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ShoppingListsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ShoppingListsTable,
    ShoppingListEntry,
    $$ShoppingListsTableFilterComposer,
    $$ShoppingListsTableOrderingComposer,
    $$ShoppingListsTableAnnotationComposer,
    $$ShoppingListsTableCreateCompanionBuilder,
    $$ShoppingListsTableUpdateCompanionBuilder,
    (
      ShoppingListEntry,
      BaseReferences<_$AppDatabase, $ShoppingListsTable, ShoppingListEntry>
    ),
    ShoppingListEntry,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$RecipeFoldersTableTableManager get recipeFolders =>
      $$RecipeFoldersTableTableManager(_db, _db.recipeFolders);
  $$RecipesTableTableManager get recipes =>
      $$RecipesTableTableManager(_db, _db.recipes);
  $$RecipeSharesTableTableManager get recipeShares =>
      $$RecipeSharesTableTableManager(_db, _db.recipeShares);
  $$HouseholdMembersTableTableManager get householdMembers =>
      $$HouseholdMembersTableTableManager(_db, _db.householdMembers);
  $$HouseholdsTableTableManager get households =>
      $$HouseholdsTableTableManager(_db, _db.households);
  $$UploadQueuesTableTableManager get uploadQueues =>
      $$UploadQueuesTableTableManager(_db, _db.uploadQueues);
  $$CooksTableTableManager get cooks =>
      $$CooksTableTableManager(_db, _db.cooks);
  $$PantryItemsTableTableManager get pantryItems =>
      $$PantryItemsTableTableManager(_db, _db.pantryItems);
  $$IngredientTermOverridesTableTableManager get ingredientTermOverrides =>
      $$IngredientTermOverridesTableTableManager(
          _db, _db.ingredientTermOverrides);
  $$ShoppingListItemsTableTableManager get shoppingListItems =>
      $$ShoppingListItemsTableTableManager(_db, _db.shoppingListItems);
  $$ShoppingListsTableTableManager get shoppingLists =>
      $$ShoppingListsTableTableManager(_db, _db.shoppingLists);
}
