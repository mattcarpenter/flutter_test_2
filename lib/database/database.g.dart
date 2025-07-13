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
      'language', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
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
          .read(DriftSqlType.string, data['${effectivePrefix}language']),
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
          .read(DriftSqlType.string, data['${effectivePrefix}user_id']),
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
  final String? language;
  final int? servings;
  final int? prepTime;
  final int? cookTime;
  final int? totalTime;
  final String? source;
  final String? nutrition;
  final String? generalNotes;
  final String? userId;
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
      this.language,
      this.servings,
      this.prepTime,
      this.cookTime,
      this.totalTime,
      this.source,
      this.nutrition,
      this.generalNotes,
      this.userId,
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
    if (!nullToAbsent || language != null) {
      map['language'] = Variable<String>(language);
    }
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
      language: language == null && nullToAbsent
          ? const Value.absent()
          : Value(language),
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
      language: serializer.fromJson<String?>(json['language']),
      servings: serializer.fromJson<int?>(json['servings']),
      prepTime: serializer.fromJson<int?>(json['prepTime']),
      cookTime: serializer.fromJson<int?>(json['cookTime']),
      totalTime: serializer.fromJson<int?>(json['totalTime']),
      source: serializer.fromJson<String?>(json['source']),
      nutrition: serializer.fromJson<String?>(json['nutrition']),
      generalNotes: serializer.fromJson<String?>(json['generalNotes']),
      userId: serializer.fromJson<String?>(json['userId']),
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
      'language': serializer.toJson<String?>(language),
      'servings': serializer.toJson<int?>(servings),
      'prepTime': serializer.toJson<int?>(prepTime),
      'cookTime': serializer.toJson<int?>(cookTime),
      'totalTime': serializer.toJson<int?>(totalTime),
      'source': serializer.toJson<String?>(source),
      'nutrition': serializer.toJson<String?>(nutrition),
      'generalNotes': serializer.toJson<String?>(generalNotes),
      'userId': serializer.toJson<String?>(userId),
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
          Value<String?> language = const Value.absent(),
          Value<int?> servings = const Value.absent(),
          Value<int?> prepTime = const Value.absent(),
          Value<int?> cookTime = const Value.absent(),
          Value<int?> totalTime = const Value.absent(),
          Value<String?> source = const Value.absent(),
          Value<String?> nutrition = const Value.absent(),
          Value<String?> generalNotes = const Value.absent(),
          Value<String?> userId = const Value.absent(),
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
        language: language.present ? language.value : this.language,
        servings: servings.present ? servings.value : this.servings,
        prepTime: prepTime.present ? prepTime.value : this.prepTime,
        cookTime: cookTime.present ? cookTime.value : this.cookTime,
        totalTime: totalTime.present ? totalTime.value : this.totalTime,
        source: source.present ? source.value : this.source,
        nutrition: nutrition.present ? nutrition.value : this.nutrition,
        generalNotes:
            generalNotes.present ? generalNotes.value : this.generalNotes,
        userId: userId.present ? userId.value : this.userId,
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
  final Value<String?> language;
  final Value<int?> servings;
  final Value<int?> prepTime;
  final Value<int?> cookTime;
  final Value<int?> totalTime;
  final Value<String?> source;
  final Value<String?> nutrition;
  final Value<String?> generalNotes;
  final Value<String?> userId;
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
  }) : title = Value(title);
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
      Value<String?>? language,
      Value<int?>? servings,
      Value<int?>? prepTime,
      Value<int?>? cookTime,
      Value<int?>? totalTime,
      Value<String?>? source,
      Value<String?>? nutrition,
      Value<String?>? generalNotes,
      Value<String?>? userId,
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
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
      'role', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('member'));
  static const VerificationMeta _joinedAtMeta =
      const VerificationMeta('joinedAt');
  @override
  late final GeneratedColumn<int> joinedAt = GeneratedColumn<int>(
      'joined_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, householdId, userId, isActive, role, joinedAt, updatedAt];
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
    if (data.containsKey('role')) {
      context.handle(
          _roleMeta, role.isAcceptableOrUnknown(data['role']!, _roleMeta));
    }
    if (data.containsKey('joined_at')) {
      context.handle(_joinedAtMeta,
          joinedAt.isAcceptableOrUnknown(data['joined_at']!, _joinedAtMeta));
    } else if (isInserting) {
      context.missing(_joinedAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
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
      role: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}role'])!,
      joinedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}joined_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at']),
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
  final String role;
  final int joinedAt;
  final int? updatedAt;
  const HouseholdMemberEntry(
      {required this.id,
      required this.householdId,
      required this.userId,
      required this.isActive,
      required this.role,
      required this.joinedAt,
      this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['household_id'] = Variable<String>(householdId);
    map['user_id'] = Variable<String>(userId);
    map['is_active'] = Variable<int>(isActive);
    map['role'] = Variable<String>(role);
    map['joined_at'] = Variable<int>(joinedAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<int>(updatedAt);
    }
    return map;
  }

  HouseholdMembersCompanion toCompanion(bool nullToAbsent) {
    return HouseholdMembersCompanion(
      id: Value(id),
      householdId: Value(householdId),
      userId: Value(userId),
      isActive: Value(isActive),
      role: Value(role),
      joinedAt: Value(joinedAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
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
      role: serializer.fromJson<String>(json['role']),
      joinedAt: serializer.fromJson<int>(json['joinedAt']),
      updatedAt: serializer.fromJson<int?>(json['updatedAt']),
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
      'role': serializer.toJson<String>(role),
      'joinedAt': serializer.toJson<int>(joinedAt),
      'updatedAt': serializer.toJson<int?>(updatedAt),
    };
  }

  HouseholdMemberEntry copyWith(
          {String? id,
          String? householdId,
          String? userId,
          int? isActive,
          String? role,
          int? joinedAt,
          Value<int?> updatedAt = const Value.absent()}) =>
      HouseholdMemberEntry(
        id: id ?? this.id,
        householdId: householdId ?? this.householdId,
        userId: userId ?? this.userId,
        isActive: isActive ?? this.isActive,
        role: role ?? this.role,
        joinedAt: joinedAt ?? this.joinedAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
      );
  HouseholdMemberEntry copyWithCompanion(HouseholdMembersCompanion data) {
    return HouseholdMemberEntry(
      id: data.id.present ? data.id.value : this.id,
      householdId:
          data.householdId.present ? data.householdId.value : this.householdId,
      userId: data.userId.present ? data.userId.value : this.userId,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      role: data.role.present ? data.role.value : this.role,
      joinedAt: data.joinedAt.present ? data.joinedAt.value : this.joinedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HouseholdMemberEntry(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('userId: $userId, ')
          ..write('isActive: $isActive, ')
          ..write('role: $role, ')
          ..write('joinedAt: $joinedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, householdId, userId, isActive, role, joinedAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HouseholdMemberEntry &&
          other.id == this.id &&
          other.householdId == this.householdId &&
          other.userId == this.userId &&
          other.isActive == this.isActive &&
          other.role == this.role &&
          other.joinedAt == this.joinedAt &&
          other.updatedAt == this.updatedAt);
}

class HouseholdMembersCompanion extends UpdateCompanion<HouseholdMemberEntry> {
  final Value<String> id;
  final Value<String> householdId;
  final Value<String> userId;
  final Value<int> isActive;
  final Value<String> role;
  final Value<int> joinedAt;
  final Value<int?> updatedAt;
  final Value<int> rowid;
  const HouseholdMembersCompanion({
    this.id = const Value.absent(),
    this.householdId = const Value.absent(),
    this.userId = const Value.absent(),
    this.isActive = const Value.absent(),
    this.role = const Value.absent(),
    this.joinedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HouseholdMembersCompanion.insert({
    this.id = const Value.absent(),
    required String householdId,
    required String userId,
    this.isActive = const Value.absent(),
    this.role = const Value.absent(),
    required int joinedAt,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : householdId = Value(householdId),
        userId = Value(userId),
        joinedAt = Value(joinedAt);
  static Insertable<HouseholdMemberEntry> custom({
    Expression<String>? id,
    Expression<String>? householdId,
    Expression<String>? userId,
    Expression<int>? isActive,
    Expression<String>? role,
    Expression<int>? joinedAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (householdId != null) 'household_id': householdId,
      if (userId != null) 'user_id': userId,
      if (isActive != null) 'is_active': isActive,
      if (role != null) 'role': role,
      if (joinedAt != null) 'joined_at': joinedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HouseholdMembersCompanion copyWith(
      {Value<String>? id,
      Value<String>? householdId,
      Value<String>? userId,
      Value<int>? isActive,
      Value<String>? role,
      Value<int>? joinedAt,
      Value<int?>? updatedAt,
      Value<int>? rowid}) {
    return HouseholdMembersCompanion(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      userId: userId ?? this.userId,
      isActive: isActive ?? this.isActive,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (joinedAt.present) {
      map['joined_at'] = Variable<int>(joinedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
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
          ..write('role: $role, ')
          ..write('joinedAt: $joinedAt, ')
          ..write('updatedAt: $updatedAt, ')
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

class $HouseholdInvitesTable extends HouseholdInvites
    with TableInfo<$HouseholdInvitesTable, HouseholdInviteEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HouseholdInvitesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _invitedByUserIdMeta =
      const VerificationMeta('invitedByUserId');
  @override
  late final GeneratedColumn<String> invitedByUserId = GeneratedColumn<String>(
      'invited_by_user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _inviteCodeMeta =
      const VerificationMeta('inviteCode');
  @override
  late final GeneratedColumn<String> inviteCode = GeneratedColumn<String>(
      'invite_code', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
      'email', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _displayNameMeta =
      const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
      'display_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _inviteTypeMeta =
      const VerificationMeta('inviteType');
  @override
  late final GeneratedColumn<String> inviteType = GeneratedColumn<String>(
      'invite_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pending'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _lastSentAtMeta =
      const VerificationMeta('lastSentAt');
  @override
  late final GeneratedColumn<int> lastSentAt = GeneratedColumn<int>(
      'last_sent_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _expiresAtMeta =
      const VerificationMeta('expiresAt');
  @override
  late final GeneratedColumn<int> expiresAt = GeneratedColumn<int>(
      'expires_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _acceptedAtMeta =
      const VerificationMeta('acceptedAt');
  @override
  late final GeneratedColumn<int> acceptedAt = GeneratedColumn<int>(
      'accepted_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _acceptedByUserIdMeta =
      const VerificationMeta('acceptedByUserId');
  @override
  late final GeneratedColumn<String> acceptedByUserId = GeneratedColumn<String>(
      'accepted_by_user_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        householdId,
        invitedByUserId,
        inviteCode,
        email,
        displayName,
        inviteType,
        status,
        createdAt,
        updatedAt,
        lastSentAt,
        expiresAt,
        acceptedAt,
        acceptedByUserId
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'household_invites';
  @override
  VerificationContext validateIntegrity(
      Insertable<HouseholdInviteEntry> instance,
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
    if (data.containsKey('invited_by_user_id')) {
      context.handle(
          _invitedByUserIdMeta,
          invitedByUserId.isAcceptableOrUnknown(
              data['invited_by_user_id']!, _invitedByUserIdMeta));
    } else if (isInserting) {
      context.missing(_invitedByUserIdMeta);
    }
    if (data.containsKey('invite_code')) {
      context.handle(
          _inviteCodeMeta,
          inviteCode.isAcceptableOrUnknown(
              data['invite_code']!, _inviteCodeMeta));
    } else if (isInserting) {
      context.missing(_inviteCodeMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
          _emailMeta, email.isAcceptableOrUnknown(data['email']!, _emailMeta));
    }
    if (data.containsKey('display_name')) {
      context.handle(
          _displayNameMeta,
          displayName.isAcceptableOrUnknown(
              data['display_name']!, _displayNameMeta));
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('invite_type')) {
      context.handle(
          _inviteTypeMeta,
          inviteType.isAcceptableOrUnknown(
              data['invite_type']!, _inviteTypeMeta));
    } else if (isInserting) {
      context.missing(_inviteTypeMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('last_sent_at')) {
      context.handle(
          _lastSentAtMeta,
          lastSentAt.isAcceptableOrUnknown(
              data['last_sent_at']!, _lastSentAtMeta));
    }
    if (data.containsKey('expires_at')) {
      context.handle(_expiresAtMeta,
          expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta));
    } else if (isInserting) {
      context.missing(_expiresAtMeta);
    }
    if (data.containsKey('accepted_at')) {
      context.handle(
          _acceptedAtMeta,
          acceptedAt.isAcceptableOrUnknown(
              data['accepted_at']!, _acceptedAtMeta));
    }
    if (data.containsKey('accepted_by_user_id')) {
      context.handle(
          _acceptedByUserIdMeta,
          acceptedByUserId.isAcceptableOrUnknown(
              data['accepted_by_user_id']!, _acceptedByUserIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  HouseholdInviteEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HouseholdInviteEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      householdId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}household_id'])!,
      invitedByUserId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}invited_by_user_id'])!,
      inviteCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}invite_code'])!,
      email: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}email']),
      displayName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_name'])!,
      inviteType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}invite_type'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
      lastSentAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}last_sent_at']),
      expiresAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}expires_at'])!,
      acceptedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}accepted_at']),
      acceptedByUserId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}accepted_by_user_id']),
    );
  }

  @override
  $HouseholdInvitesTable createAlias(String alias) {
    return $HouseholdInvitesTable(attachedDatabase, alias);
  }
}

class HouseholdInviteEntry extends DataClass
    implements Insertable<HouseholdInviteEntry> {
  final String id;
  final String householdId;
  final String invitedByUserId;
  final String inviteCode;
  final String? email;
  final String displayName;
  final String inviteType;
  final String status;
  final int createdAt;
  final int updatedAt;
  final int? lastSentAt;
  final int expiresAt;
  final int? acceptedAt;
  final String? acceptedByUserId;
  const HouseholdInviteEntry(
      {required this.id,
      required this.householdId,
      required this.invitedByUserId,
      required this.inviteCode,
      this.email,
      required this.displayName,
      required this.inviteType,
      required this.status,
      required this.createdAt,
      required this.updatedAt,
      this.lastSentAt,
      required this.expiresAt,
      this.acceptedAt,
      this.acceptedByUserId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['household_id'] = Variable<String>(householdId);
    map['invited_by_user_id'] = Variable<String>(invitedByUserId);
    map['invite_code'] = Variable<String>(inviteCode);
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    map['display_name'] = Variable<String>(displayName);
    map['invite_type'] = Variable<String>(inviteType);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || lastSentAt != null) {
      map['last_sent_at'] = Variable<int>(lastSentAt);
    }
    map['expires_at'] = Variable<int>(expiresAt);
    if (!nullToAbsent || acceptedAt != null) {
      map['accepted_at'] = Variable<int>(acceptedAt);
    }
    if (!nullToAbsent || acceptedByUserId != null) {
      map['accepted_by_user_id'] = Variable<String>(acceptedByUserId);
    }
    return map;
  }

  HouseholdInvitesCompanion toCompanion(bool nullToAbsent) {
    return HouseholdInvitesCompanion(
      id: Value(id),
      householdId: Value(householdId),
      invitedByUserId: Value(invitedByUserId),
      inviteCode: Value(inviteCode),
      email:
          email == null && nullToAbsent ? const Value.absent() : Value(email),
      displayName: Value(displayName),
      inviteType: Value(inviteType),
      status: Value(status),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      lastSentAt: lastSentAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSentAt),
      expiresAt: Value(expiresAt),
      acceptedAt: acceptedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(acceptedAt),
      acceptedByUserId: acceptedByUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(acceptedByUserId),
    );
  }

  factory HouseholdInviteEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HouseholdInviteEntry(
      id: serializer.fromJson<String>(json['id']),
      householdId: serializer.fromJson<String>(json['householdId']),
      invitedByUserId: serializer.fromJson<String>(json['invitedByUserId']),
      inviteCode: serializer.fromJson<String>(json['inviteCode']),
      email: serializer.fromJson<String?>(json['email']),
      displayName: serializer.fromJson<String>(json['displayName']),
      inviteType: serializer.fromJson<String>(json['inviteType']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      lastSentAt: serializer.fromJson<int?>(json['lastSentAt']),
      expiresAt: serializer.fromJson<int>(json['expiresAt']),
      acceptedAt: serializer.fromJson<int?>(json['acceptedAt']),
      acceptedByUserId: serializer.fromJson<String?>(json['acceptedByUserId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'householdId': serializer.toJson<String>(householdId),
      'invitedByUserId': serializer.toJson<String>(invitedByUserId),
      'inviteCode': serializer.toJson<String>(inviteCode),
      'email': serializer.toJson<String?>(email),
      'displayName': serializer.toJson<String>(displayName),
      'inviteType': serializer.toJson<String>(inviteType),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'lastSentAt': serializer.toJson<int?>(lastSentAt),
      'expiresAt': serializer.toJson<int>(expiresAt),
      'acceptedAt': serializer.toJson<int?>(acceptedAt),
      'acceptedByUserId': serializer.toJson<String?>(acceptedByUserId),
    };
  }

  HouseholdInviteEntry copyWith(
          {String? id,
          String? householdId,
          String? invitedByUserId,
          String? inviteCode,
          Value<String?> email = const Value.absent(),
          String? displayName,
          String? inviteType,
          String? status,
          int? createdAt,
          int? updatedAt,
          Value<int?> lastSentAt = const Value.absent(),
          int? expiresAt,
          Value<int?> acceptedAt = const Value.absent(),
          Value<String?> acceptedByUserId = const Value.absent()}) =>
      HouseholdInviteEntry(
        id: id ?? this.id,
        householdId: householdId ?? this.householdId,
        invitedByUserId: invitedByUserId ?? this.invitedByUserId,
        inviteCode: inviteCode ?? this.inviteCode,
        email: email.present ? email.value : this.email,
        displayName: displayName ?? this.displayName,
        inviteType: inviteType ?? this.inviteType,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        lastSentAt: lastSentAt.present ? lastSentAt.value : this.lastSentAt,
        expiresAt: expiresAt ?? this.expiresAt,
        acceptedAt: acceptedAt.present ? acceptedAt.value : this.acceptedAt,
        acceptedByUserId: acceptedByUserId.present
            ? acceptedByUserId.value
            : this.acceptedByUserId,
      );
  HouseholdInviteEntry copyWithCompanion(HouseholdInvitesCompanion data) {
    return HouseholdInviteEntry(
      id: data.id.present ? data.id.value : this.id,
      householdId:
          data.householdId.present ? data.householdId.value : this.householdId,
      invitedByUserId: data.invitedByUserId.present
          ? data.invitedByUserId.value
          : this.invitedByUserId,
      inviteCode:
          data.inviteCode.present ? data.inviteCode.value : this.inviteCode,
      email: data.email.present ? data.email.value : this.email,
      displayName:
          data.displayName.present ? data.displayName.value : this.displayName,
      inviteType:
          data.inviteType.present ? data.inviteType.value : this.inviteType,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      lastSentAt:
          data.lastSentAt.present ? data.lastSentAt.value : this.lastSentAt,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      acceptedAt:
          data.acceptedAt.present ? data.acceptedAt.value : this.acceptedAt,
      acceptedByUserId: data.acceptedByUserId.present
          ? data.acceptedByUserId.value
          : this.acceptedByUserId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HouseholdInviteEntry(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('invitedByUserId: $invitedByUserId, ')
          ..write('inviteCode: $inviteCode, ')
          ..write('email: $email, ')
          ..write('displayName: $displayName, ')
          ..write('inviteType: $inviteType, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastSentAt: $lastSentAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('acceptedAt: $acceptedAt, ')
          ..write('acceptedByUserId: $acceptedByUserId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      householdId,
      invitedByUserId,
      inviteCode,
      email,
      displayName,
      inviteType,
      status,
      createdAt,
      updatedAt,
      lastSentAt,
      expiresAt,
      acceptedAt,
      acceptedByUserId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HouseholdInviteEntry &&
          other.id == this.id &&
          other.householdId == this.householdId &&
          other.invitedByUserId == this.invitedByUserId &&
          other.inviteCode == this.inviteCode &&
          other.email == this.email &&
          other.displayName == this.displayName &&
          other.inviteType == this.inviteType &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.lastSentAt == this.lastSentAt &&
          other.expiresAt == this.expiresAt &&
          other.acceptedAt == this.acceptedAt &&
          other.acceptedByUserId == this.acceptedByUserId);
}

class HouseholdInvitesCompanion extends UpdateCompanion<HouseholdInviteEntry> {
  final Value<String> id;
  final Value<String> householdId;
  final Value<String> invitedByUserId;
  final Value<String> inviteCode;
  final Value<String?> email;
  final Value<String> displayName;
  final Value<String> inviteType;
  final Value<String> status;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> lastSentAt;
  final Value<int> expiresAt;
  final Value<int?> acceptedAt;
  final Value<String?> acceptedByUserId;
  final Value<int> rowid;
  const HouseholdInvitesCompanion({
    this.id = const Value.absent(),
    this.householdId = const Value.absent(),
    this.invitedByUserId = const Value.absent(),
    this.inviteCode = const Value.absent(),
    this.email = const Value.absent(),
    this.displayName = const Value.absent(),
    this.inviteType = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastSentAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.acceptedAt = const Value.absent(),
    this.acceptedByUserId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HouseholdInvitesCompanion.insert({
    this.id = const Value.absent(),
    required String householdId,
    required String invitedByUserId,
    required String inviteCode,
    this.email = const Value.absent(),
    required String displayName,
    required String inviteType,
    this.status = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.lastSentAt = const Value.absent(),
    required int expiresAt,
    this.acceptedAt = const Value.absent(),
    this.acceptedByUserId = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : householdId = Value(householdId),
        invitedByUserId = Value(invitedByUserId),
        inviteCode = Value(inviteCode),
        displayName = Value(displayName),
        inviteType = Value(inviteType),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt),
        expiresAt = Value(expiresAt);
  static Insertable<HouseholdInviteEntry> custom({
    Expression<String>? id,
    Expression<String>? householdId,
    Expression<String>? invitedByUserId,
    Expression<String>? inviteCode,
    Expression<String>? email,
    Expression<String>? displayName,
    Expression<String>? inviteType,
    Expression<String>? status,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? lastSentAt,
    Expression<int>? expiresAt,
    Expression<int>? acceptedAt,
    Expression<String>? acceptedByUserId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (householdId != null) 'household_id': householdId,
      if (invitedByUserId != null) 'invited_by_user_id': invitedByUserId,
      if (inviteCode != null) 'invite_code': inviteCode,
      if (email != null) 'email': email,
      if (displayName != null) 'display_name': displayName,
      if (inviteType != null) 'invite_type': inviteType,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (lastSentAt != null) 'last_sent_at': lastSentAt,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (acceptedAt != null) 'accepted_at': acceptedAt,
      if (acceptedByUserId != null) 'accepted_by_user_id': acceptedByUserId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HouseholdInvitesCompanion copyWith(
      {Value<String>? id,
      Value<String>? householdId,
      Value<String>? invitedByUserId,
      Value<String>? inviteCode,
      Value<String?>? email,
      Value<String>? displayName,
      Value<String>? inviteType,
      Value<String>? status,
      Value<int>? createdAt,
      Value<int>? updatedAt,
      Value<int?>? lastSentAt,
      Value<int>? expiresAt,
      Value<int?>? acceptedAt,
      Value<String?>? acceptedByUserId,
      Value<int>? rowid}) {
    return HouseholdInvitesCompanion(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      invitedByUserId: invitedByUserId ?? this.invitedByUserId,
      inviteCode: inviteCode ?? this.inviteCode,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      inviteType: inviteType ?? this.inviteType,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSentAt: lastSentAt ?? this.lastSentAt,
      expiresAt: expiresAt ?? this.expiresAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      acceptedByUserId: acceptedByUserId ?? this.acceptedByUserId,
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
    if (invitedByUserId.present) {
      map['invited_by_user_id'] = Variable<String>(invitedByUserId.value);
    }
    if (inviteCode.present) {
      map['invite_code'] = Variable<String>(inviteCode.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (inviteType.present) {
      map['invite_type'] = Variable<String>(inviteType.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (lastSentAt.present) {
      map['last_sent_at'] = Variable<int>(lastSentAt.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<int>(expiresAt.value);
    }
    if (acceptedAt.present) {
      map['accepted_at'] = Variable<int>(acceptedAt.value);
    }
    if (acceptedByUserId.present) {
      map['accepted_by_user_id'] = Variable<String>(acceptedByUserId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HouseholdInvitesCompanion(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('invitedByUserId: $invitedByUserId, ')
          ..write('inviteCode: $inviteCode, ')
          ..write('email: $email, ')
          ..write('displayName: $displayName, ')
          ..write('inviteType: $inviteType, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastSentAt: $lastSentAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('acceptedAt: $acceptedAt, ')
          ..write('acceptedByUserId: $acceptedByUserId, ')
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

class $IngredientTermQueuesTable extends IngredientTermQueues
    with TableInfo<$IngredientTermQueuesTable, IngredientTermQueueEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IngredientTermQueuesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _ingredientIdMeta =
      const VerificationMeta('ingredientId');
  @override
  late final GeneratedColumn<String> ingredientId = GeneratedColumn<String>(
      'ingredient_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _requestTimestampMeta =
      const VerificationMeta('requestTimestamp');
  @override
  late final GeneratedColumn<int> requestTimestamp = GeneratedColumn<int>(
      'request_timestamp', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
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
  static const VerificationMeta _ingredientDataMeta =
      const VerificationMeta('ingredientData');
  @override
  late final GeneratedColumn<String> ingredientData = GeneratedColumn<String>(
      'ingredient_data', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _responseDataMeta =
      const VerificationMeta('responseData');
  @override
  late final GeneratedColumn<String> responseData = GeneratedColumn<String>(
      'response_data', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        recipeId,
        ingredientId,
        requestTimestamp,
        status,
        retryCount,
        lastTryTimestamp,
        ingredientData,
        responseData
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ingredient_term_queues';
  @override
  VerificationContext validateIntegrity(
      Insertable<IngredientTermQueueEntry> instance,
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
    if (data.containsKey('ingredient_id')) {
      context.handle(
          _ingredientIdMeta,
          ingredientId.isAcceptableOrUnknown(
              data['ingredient_id']!, _ingredientIdMeta));
    } else if (isInserting) {
      context.missing(_ingredientIdMeta);
    }
    if (data.containsKey('request_timestamp')) {
      context.handle(
          _requestTimestampMeta,
          requestTimestamp.isAcceptableOrUnknown(
              data['request_timestamp']!, _requestTimestampMeta));
    } else if (isInserting) {
      context.missing(_requestTimestampMeta);
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
    if (data.containsKey('ingredient_data')) {
      context.handle(
          _ingredientDataMeta,
          ingredientData.isAcceptableOrUnknown(
              data['ingredient_data']!, _ingredientDataMeta));
    } else if (isInserting) {
      context.missing(_ingredientDataMeta);
    }
    if (data.containsKey('response_data')) {
      context.handle(
          _responseDataMeta,
          responseData.isAcceptableOrUnknown(
              data['response_data']!, _responseDataMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  IngredientTermQueueEntry map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IngredientTermQueueEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      recipeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}recipe_id'])!,
      ingredientId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ingredient_id'])!,
      requestTimestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}request_timestamp'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      retryCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}retry_count'])!,
      lastTryTimestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}last_try_timestamp']),
      ingredientData: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}ingredient_data'])!,
      responseData: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}response_data']),
    );
  }

  @override
  $IngredientTermQueuesTable createAlias(String alias) {
    return $IngredientTermQueuesTable(attachedDatabase, alias);
  }
}

class IngredientTermQueueEntry extends DataClass
    implements Insertable<IngredientTermQueueEntry> {
  final String id;
  final String recipeId;
  final String ingredientId;
  final int requestTimestamp;
  final String status;
  final int retryCount;
  final int? lastTryTimestamp;
  final String ingredientData;
  final String? responseData;
  const IngredientTermQueueEntry(
      {required this.id,
      required this.recipeId,
      required this.ingredientId,
      required this.requestTimestamp,
      required this.status,
      required this.retryCount,
      this.lastTryTimestamp,
      required this.ingredientData,
      this.responseData});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['recipe_id'] = Variable<String>(recipeId);
    map['ingredient_id'] = Variable<String>(ingredientId);
    map['request_timestamp'] = Variable<int>(requestTimestamp);
    map['status'] = Variable<String>(status);
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || lastTryTimestamp != null) {
      map['last_try_timestamp'] = Variable<int>(lastTryTimestamp);
    }
    map['ingredient_data'] = Variable<String>(ingredientData);
    if (!nullToAbsent || responseData != null) {
      map['response_data'] = Variable<String>(responseData);
    }
    return map;
  }

  IngredientTermQueuesCompanion toCompanion(bool nullToAbsent) {
    return IngredientTermQueuesCompanion(
      id: Value(id),
      recipeId: Value(recipeId),
      ingredientId: Value(ingredientId),
      requestTimestamp: Value(requestTimestamp),
      status: Value(status),
      retryCount: Value(retryCount),
      lastTryTimestamp: lastTryTimestamp == null && nullToAbsent
          ? const Value.absent()
          : Value(lastTryTimestamp),
      ingredientData: Value(ingredientData),
      responseData: responseData == null && nullToAbsent
          ? const Value.absent()
          : Value(responseData),
    );
  }

  factory IngredientTermQueueEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IngredientTermQueueEntry(
      id: serializer.fromJson<String>(json['id']),
      recipeId: serializer.fromJson<String>(json['recipeId']),
      ingredientId: serializer.fromJson<String>(json['ingredientId']),
      requestTimestamp: serializer.fromJson<int>(json['requestTimestamp']),
      status: serializer.fromJson<String>(json['status']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      lastTryTimestamp: serializer.fromJson<int?>(json['lastTryTimestamp']),
      ingredientData: serializer.fromJson<String>(json['ingredientData']),
      responseData: serializer.fromJson<String?>(json['responseData']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'recipeId': serializer.toJson<String>(recipeId),
      'ingredientId': serializer.toJson<String>(ingredientId),
      'requestTimestamp': serializer.toJson<int>(requestTimestamp),
      'status': serializer.toJson<String>(status),
      'retryCount': serializer.toJson<int>(retryCount),
      'lastTryTimestamp': serializer.toJson<int?>(lastTryTimestamp),
      'ingredientData': serializer.toJson<String>(ingredientData),
      'responseData': serializer.toJson<String?>(responseData),
    };
  }

  IngredientTermQueueEntry copyWith(
          {String? id,
          String? recipeId,
          String? ingredientId,
          int? requestTimestamp,
          String? status,
          int? retryCount,
          Value<int?> lastTryTimestamp = const Value.absent(),
          String? ingredientData,
          Value<String?> responseData = const Value.absent()}) =>
      IngredientTermQueueEntry(
        id: id ?? this.id,
        recipeId: recipeId ?? this.recipeId,
        ingredientId: ingredientId ?? this.ingredientId,
        requestTimestamp: requestTimestamp ?? this.requestTimestamp,
        status: status ?? this.status,
        retryCount: retryCount ?? this.retryCount,
        lastTryTimestamp: lastTryTimestamp.present
            ? lastTryTimestamp.value
            : this.lastTryTimestamp,
        ingredientData: ingredientData ?? this.ingredientData,
        responseData:
            responseData.present ? responseData.value : this.responseData,
      );
  IngredientTermQueueEntry copyWithCompanion(
      IngredientTermQueuesCompanion data) {
    return IngredientTermQueueEntry(
      id: data.id.present ? data.id.value : this.id,
      recipeId: data.recipeId.present ? data.recipeId.value : this.recipeId,
      ingredientId: data.ingredientId.present
          ? data.ingredientId.value
          : this.ingredientId,
      requestTimestamp: data.requestTimestamp.present
          ? data.requestTimestamp.value
          : this.requestTimestamp,
      status: data.status.present ? data.status.value : this.status,
      retryCount:
          data.retryCount.present ? data.retryCount.value : this.retryCount,
      lastTryTimestamp: data.lastTryTimestamp.present
          ? data.lastTryTimestamp.value
          : this.lastTryTimestamp,
      ingredientData: data.ingredientData.present
          ? data.ingredientData.value
          : this.ingredientData,
      responseData: data.responseData.present
          ? data.responseData.value
          : this.responseData,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IngredientTermQueueEntry(')
          ..write('id: $id, ')
          ..write('recipeId: $recipeId, ')
          ..write('ingredientId: $ingredientId, ')
          ..write('requestTimestamp: $requestTimestamp, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastTryTimestamp: $lastTryTimestamp, ')
          ..write('ingredientData: $ingredientData, ')
          ..write('responseData: $responseData')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, recipeId, ingredientId, requestTimestamp,
      status, retryCount, lastTryTimestamp, ingredientData, responseData);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IngredientTermQueueEntry &&
          other.id == this.id &&
          other.recipeId == this.recipeId &&
          other.ingredientId == this.ingredientId &&
          other.requestTimestamp == this.requestTimestamp &&
          other.status == this.status &&
          other.retryCount == this.retryCount &&
          other.lastTryTimestamp == this.lastTryTimestamp &&
          other.ingredientData == this.ingredientData &&
          other.responseData == this.responseData);
}

class IngredientTermQueuesCompanion
    extends UpdateCompanion<IngredientTermQueueEntry> {
  final Value<String> id;
  final Value<String> recipeId;
  final Value<String> ingredientId;
  final Value<int> requestTimestamp;
  final Value<String> status;
  final Value<int> retryCount;
  final Value<int?> lastTryTimestamp;
  final Value<String> ingredientData;
  final Value<String?> responseData;
  final Value<int> rowid;
  const IngredientTermQueuesCompanion({
    this.id = const Value.absent(),
    this.recipeId = const Value.absent(),
    this.ingredientId = const Value.absent(),
    this.requestTimestamp = const Value.absent(),
    this.status = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastTryTimestamp = const Value.absent(),
    this.ingredientData = const Value.absent(),
    this.responseData = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IngredientTermQueuesCompanion.insert({
    this.id = const Value.absent(),
    required String recipeId,
    required String ingredientId,
    required int requestTimestamp,
    this.status = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastTryTimestamp = const Value.absent(),
    required String ingredientData,
    this.responseData = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : recipeId = Value(recipeId),
        ingredientId = Value(ingredientId),
        requestTimestamp = Value(requestTimestamp),
        ingredientData = Value(ingredientData);
  static Insertable<IngredientTermQueueEntry> custom({
    Expression<String>? id,
    Expression<String>? recipeId,
    Expression<String>? ingredientId,
    Expression<int>? requestTimestamp,
    Expression<String>? status,
    Expression<int>? retryCount,
    Expression<int>? lastTryTimestamp,
    Expression<String>? ingredientData,
    Expression<String>? responseData,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (recipeId != null) 'recipe_id': recipeId,
      if (ingredientId != null) 'ingredient_id': ingredientId,
      if (requestTimestamp != null) 'request_timestamp': requestTimestamp,
      if (status != null) 'status': status,
      if (retryCount != null) 'retry_count': retryCount,
      if (lastTryTimestamp != null) 'last_try_timestamp': lastTryTimestamp,
      if (ingredientData != null) 'ingredient_data': ingredientData,
      if (responseData != null) 'response_data': responseData,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IngredientTermQueuesCompanion copyWith(
      {Value<String>? id,
      Value<String>? recipeId,
      Value<String>? ingredientId,
      Value<int>? requestTimestamp,
      Value<String>? status,
      Value<int>? retryCount,
      Value<int?>? lastTryTimestamp,
      Value<String>? ingredientData,
      Value<String?>? responseData,
      Value<int>? rowid}) {
    return IngredientTermQueuesCompanion(
      id: id ?? this.id,
      recipeId: recipeId ?? this.recipeId,
      ingredientId: ingredientId ?? this.ingredientId,
      requestTimestamp: requestTimestamp ?? this.requestTimestamp,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      lastTryTimestamp: lastTryTimestamp ?? this.lastTryTimestamp,
      ingredientData: ingredientData ?? this.ingredientData,
      responseData: responseData ?? this.responseData,
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
    if (ingredientId.present) {
      map['ingredient_id'] = Variable<String>(ingredientId.value);
    }
    if (requestTimestamp.present) {
      map['request_timestamp'] = Variable<int>(requestTimestamp.value);
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
    if (ingredientData.present) {
      map['ingredient_data'] = Variable<String>(ingredientData.value);
    }
    if (responseData.present) {
      map['response_data'] = Variable<String>(responseData.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IngredientTermQueuesCompanion(')
          ..write('id: $id, ')
          ..write('recipeId: $recipeId, ')
          ..write('ingredientId: $ingredientId, ')
          ..write('requestTimestamp: $requestTimestamp, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastTryTimestamp: $lastTryTimestamp, ')
          ..write('ingredientData: $ingredientData, ')
          ..write('responseData: $responseData, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PantryItemTermQueuesTable extends PantryItemTermQueues
    with TableInfo<$PantryItemTermQueuesTable, PantryItemTermQueueEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PantryItemTermQueuesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _pantryItemIdMeta =
      const VerificationMeta('pantryItemId');
  @override
  late final GeneratedColumn<String> pantryItemId = GeneratedColumn<String>(
      'pantry_item_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _requestTimestampMeta =
      const VerificationMeta('requestTimestamp');
  @override
  late final GeneratedColumn<int> requestTimestamp = GeneratedColumn<int>(
      'request_timestamp', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _pantryItemDataMeta =
      const VerificationMeta('pantryItemData');
  @override
  late final GeneratedColumn<String> pantryItemData = GeneratedColumn<String>(
      'pantry_item_data', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _retryCountMeta =
      const VerificationMeta('retryCount');
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
      'retry_count', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _lastTryTimestampMeta =
      const VerificationMeta('lastTryTimestamp');
  @override
  late final GeneratedColumn<int> lastTryTimestamp = GeneratedColumn<int>(
      'last_try_timestamp', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _responseDataMeta =
      const VerificationMeta('responseData');
  @override
  late final GeneratedColumn<String> responseData = GeneratedColumn<String>(
      'response_data', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        pantryItemId,
        requestTimestamp,
        pantryItemData,
        status,
        retryCount,
        lastTryTimestamp,
        responseData
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pantry_item_term_queues';
  @override
  VerificationContext validateIntegrity(
      Insertable<PantryItemTermQueueEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('pantry_item_id')) {
      context.handle(
          _pantryItemIdMeta,
          pantryItemId.isAcceptableOrUnknown(
              data['pantry_item_id']!, _pantryItemIdMeta));
    } else if (isInserting) {
      context.missing(_pantryItemIdMeta);
    }
    if (data.containsKey('request_timestamp')) {
      context.handle(
          _requestTimestampMeta,
          requestTimestamp.isAcceptableOrUnknown(
              data['request_timestamp']!, _requestTimestampMeta));
    } else if (isInserting) {
      context.missing(_requestTimestampMeta);
    }
    if (data.containsKey('pantry_item_data')) {
      context.handle(
          _pantryItemDataMeta,
          pantryItemData.isAcceptableOrUnknown(
              data['pantry_item_data']!, _pantryItemDataMeta));
    } else if (isInserting) {
      context.missing(_pantryItemDataMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
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
    if (data.containsKey('response_data')) {
      context.handle(
          _responseDataMeta,
          responseData.isAcceptableOrUnknown(
              data['response_data']!, _responseDataMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PantryItemTermQueueEntry map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PantryItemTermQueueEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      pantryItemId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pantry_item_id'])!,
      requestTimestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}request_timestamp'])!,
      pantryItemData: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}pantry_item_data'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      retryCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}retry_count']),
      lastTryTimestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}last_try_timestamp']),
      responseData: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}response_data']),
    );
  }

  @override
  $PantryItemTermQueuesTable createAlias(String alias) {
    return $PantryItemTermQueuesTable(attachedDatabase, alias);
  }
}

class PantryItemTermQueueEntry extends DataClass
    implements Insertable<PantryItemTermQueueEntry> {
  final String id;
  final String pantryItemId;
  final int requestTimestamp;
  final String pantryItemData;
  final String status;
  final int? retryCount;
  final int? lastTryTimestamp;
  final String? responseData;
  const PantryItemTermQueueEntry(
      {required this.id,
      required this.pantryItemId,
      required this.requestTimestamp,
      required this.pantryItemData,
      required this.status,
      this.retryCount,
      this.lastTryTimestamp,
      this.responseData});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['pantry_item_id'] = Variable<String>(pantryItemId);
    map['request_timestamp'] = Variable<int>(requestTimestamp);
    map['pantry_item_data'] = Variable<String>(pantryItemData);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || retryCount != null) {
      map['retry_count'] = Variable<int>(retryCount);
    }
    if (!nullToAbsent || lastTryTimestamp != null) {
      map['last_try_timestamp'] = Variable<int>(lastTryTimestamp);
    }
    if (!nullToAbsent || responseData != null) {
      map['response_data'] = Variable<String>(responseData);
    }
    return map;
  }

  PantryItemTermQueuesCompanion toCompanion(bool nullToAbsent) {
    return PantryItemTermQueuesCompanion(
      id: Value(id),
      pantryItemId: Value(pantryItemId),
      requestTimestamp: Value(requestTimestamp),
      pantryItemData: Value(pantryItemData),
      status: Value(status),
      retryCount: retryCount == null && nullToAbsent
          ? const Value.absent()
          : Value(retryCount),
      lastTryTimestamp: lastTryTimestamp == null && nullToAbsent
          ? const Value.absent()
          : Value(lastTryTimestamp),
      responseData: responseData == null && nullToAbsent
          ? const Value.absent()
          : Value(responseData),
    );
  }

  factory PantryItemTermQueueEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PantryItemTermQueueEntry(
      id: serializer.fromJson<String>(json['id']),
      pantryItemId: serializer.fromJson<String>(json['pantryItemId']),
      requestTimestamp: serializer.fromJson<int>(json['requestTimestamp']),
      pantryItemData: serializer.fromJson<String>(json['pantryItemData']),
      status: serializer.fromJson<String>(json['status']),
      retryCount: serializer.fromJson<int?>(json['retryCount']),
      lastTryTimestamp: serializer.fromJson<int?>(json['lastTryTimestamp']),
      responseData: serializer.fromJson<String?>(json['responseData']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'pantryItemId': serializer.toJson<String>(pantryItemId),
      'requestTimestamp': serializer.toJson<int>(requestTimestamp),
      'pantryItemData': serializer.toJson<String>(pantryItemData),
      'status': serializer.toJson<String>(status),
      'retryCount': serializer.toJson<int?>(retryCount),
      'lastTryTimestamp': serializer.toJson<int?>(lastTryTimestamp),
      'responseData': serializer.toJson<String?>(responseData),
    };
  }

  PantryItemTermQueueEntry copyWith(
          {String? id,
          String? pantryItemId,
          int? requestTimestamp,
          String? pantryItemData,
          String? status,
          Value<int?> retryCount = const Value.absent(),
          Value<int?> lastTryTimestamp = const Value.absent(),
          Value<String?> responseData = const Value.absent()}) =>
      PantryItemTermQueueEntry(
        id: id ?? this.id,
        pantryItemId: pantryItemId ?? this.pantryItemId,
        requestTimestamp: requestTimestamp ?? this.requestTimestamp,
        pantryItemData: pantryItemData ?? this.pantryItemData,
        status: status ?? this.status,
        retryCount: retryCount.present ? retryCount.value : this.retryCount,
        lastTryTimestamp: lastTryTimestamp.present
            ? lastTryTimestamp.value
            : this.lastTryTimestamp,
        responseData:
            responseData.present ? responseData.value : this.responseData,
      );
  PantryItemTermQueueEntry copyWithCompanion(
      PantryItemTermQueuesCompanion data) {
    return PantryItemTermQueueEntry(
      id: data.id.present ? data.id.value : this.id,
      pantryItemId: data.pantryItemId.present
          ? data.pantryItemId.value
          : this.pantryItemId,
      requestTimestamp: data.requestTimestamp.present
          ? data.requestTimestamp.value
          : this.requestTimestamp,
      pantryItemData: data.pantryItemData.present
          ? data.pantryItemData.value
          : this.pantryItemData,
      status: data.status.present ? data.status.value : this.status,
      retryCount:
          data.retryCount.present ? data.retryCount.value : this.retryCount,
      lastTryTimestamp: data.lastTryTimestamp.present
          ? data.lastTryTimestamp.value
          : this.lastTryTimestamp,
      responseData: data.responseData.present
          ? data.responseData.value
          : this.responseData,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PantryItemTermQueueEntry(')
          ..write('id: $id, ')
          ..write('pantryItemId: $pantryItemId, ')
          ..write('requestTimestamp: $requestTimestamp, ')
          ..write('pantryItemData: $pantryItemData, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastTryTimestamp: $lastTryTimestamp, ')
          ..write('responseData: $responseData')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, pantryItemId, requestTimestamp,
      pantryItemData, status, retryCount, lastTryTimestamp, responseData);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PantryItemTermQueueEntry &&
          other.id == this.id &&
          other.pantryItemId == this.pantryItemId &&
          other.requestTimestamp == this.requestTimestamp &&
          other.pantryItemData == this.pantryItemData &&
          other.status == this.status &&
          other.retryCount == this.retryCount &&
          other.lastTryTimestamp == this.lastTryTimestamp &&
          other.responseData == this.responseData);
}

class PantryItemTermQueuesCompanion
    extends UpdateCompanion<PantryItemTermQueueEntry> {
  final Value<String> id;
  final Value<String> pantryItemId;
  final Value<int> requestTimestamp;
  final Value<String> pantryItemData;
  final Value<String> status;
  final Value<int?> retryCount;
  final Value<int?> lastTryTimestamp;
  final Value<String?> responseData;
  final Value<int> rowid;
  const PantryItemTermQueuesCompanion({
    this.id = const Value.absent(),
    this.pantryItemId = const Value.absent(),
    this.requestTimestamp = const Value.absent(),
    this.pantryItemData = const Value.absent(),
    this.status = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastTryTimestamp = const Value.absent(),
    this.responseData = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PantryItemTermQueuesCompanion.insert({
    required String id,
    required String pantryItemId,
    required int requestTimestamp,
    required String pantryItemData,
    required String status,
    this.retryCount = const Value.absent(),
    this.lastTryTimestamp = const Value.absent(),
    this.responseData = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        pantryItemId = Value(pantryItemId),
        requestTimestamp = Value(requestTimestamp),
        pantryItemData = Value(pantryItemData),
        status = Value(status);
  static Insertable<PantryItemTermQueueEntry> custom({
    Expression<String>? id,
    Expression<String>? pantryItemId,
    Expression<int>? requestTimestamp,
    Expression<String>? pantryItemData,
    Expression<String>? status,
    Expression<int>? retryCount,
    Expression<int>? lastTryTimestamp,
    Expression<String>? responseData,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (pantryItemId != null) 'pantry_item_id': pantryItemId,
      if (requestTimestamp != null) 'request_timestamp': requestTimestamp,
      if (pantryItemData != null) 'pantry_item_data': pantryItemData,
      if (status != null) 'status': status,
      if (retryCount != null) 'retry_count': retryCount,
      if (lastTryTimestamp != null) 'last_try_timestamp': lastTryTimestamp,
      if (responseData != null) 'response_data': responseData,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PantryItemTermQueuesCompanion copyWith(
      {Value<String>? id,
      Value<String>? pantryItemId,
      Value<int>? requestTimestamp,
      Value<String>? pantryItemData,
      Value<String>? status,
      Value<int?>? retryCount,
      Value<int?>? lastTryTimestamp,
      Value<String?>? responseData,
      Value<int>? rowid}) {
    return PantryItemTermQueuesCompanion(
      id: id ?? this.id,
      pantryItemId: pantryItemId ?? this.pantryItemId,
      requestTimestamp: requestTimestamp ?? this.requestTimestamp,
      pantryItemData: pantryItemData ?? this.pantryItemData,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      lastTryTimestamp: lastTryTimestamp ?? this.lastTryTimestamp,
      responseData: responseData ?? this.responseData,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (pantryItemId.present) {
      map['pantry_item_id'] = Variable<String>(pantryItemId.value);
    }
    if (requestTimestamp.present) {
      map['request_timestamp'] = Variable<int>(requestTimestamp.value);
    }
    if (pantryItemData.present) {
      map['pantry_item_data'] = Variable<String>(pantryItemData.value);
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
    if (responseData.present) {
      map['response_data'] = Variable<String>(responseData.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PantryItemTermQueuesCompanion(')
          ..write('id: $id, ')
          ..write('pantryItemId: $pantryItemId, ')
          ..write('requestTimestamp: $requestTimestamp, ')
          ..write('pantryItemData: $pantryItemData, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastTryTimestamp: $lastTryTimestamp, ')
          ..write('responseData: $responseData, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ShoppingListItemTermQueuesTable extends ShoppingListItemTermQueues
    with
        TableInfo<$ShoppingListItemTermQueuesTable,
            ShoppingListItemTermQueueEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShoppingListItemTermQueuesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      clientDefault: () => const Uuid().v4());
  static const VerificationMeta _shoppingListItemIdMeta =
      const VerificationMeta('shoppingListItemId');
  @override
  late final GeneratedColumn<String> shoppingListItemId =
      GeneratedColumn<String>('shopping_list_item_id', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
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
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pending'));
  static const VerificationMeta _retryCountMeta =
      const VerificationMeta('retryCount');
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
      'retry_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _errorMeta = const VerificationMeta('error');
  @override
  late final GeneratedColumn<String> error = GeneratedColumn<String>(
      'error', aliasedName, true,
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
  @override
  List<GeneratedColumn> get $columns => [
        id,
        shoppingListItemId,
        name,
        userId,
        amount,
        unit,
        status,
        retryCount,
        error,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shopping_list_item_term_queues';
  @override
  VerificationContext validateIntegrity(
      Insertable<ShoppingListItemTermQueueEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('shopping_list_item_id')) {
      context.handle(
          _shoppingListItemIdMeta,
          shoppingListItemId.isAcceptableOrUnknown(
              data['shopping_list_item_id']!, _shoppingListItemIdMeta));
    } else if (isInserting) {
      context.missing(_shoppingListItemIdMeta);
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
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    }
    if (data.containsKey('unit')) {
      context.handle(
          _unitMeta, unit.isAcceptableOrUnknown(data['unit']!, _unitMeta));
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
    if (data.containsKey('error')) {
      context.handle(
          _errorMeta, error.isAcceptableOrUnknown(data['error']!, _errorMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ShoppingListItemTermQueueEntry map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShoppingListItemTermQueueEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      shoppingListItemId: attachedDatabase.typeMapping.read(DriftSqlType.string,
          data['${effectivePrefix}shopping_list_item_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id']),
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount']),
      unit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      retryCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}retry_count'])!,
      error: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}error']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at']),
    );
  }

  @override
  $ShoppingListItemTermQueuesTable createAlias(String alias) {
    return $ShoppingListItemTermQueuesTable(attachedDatabase, alias);
  }
}

class ShoppingListItemTermQueueEntry extends DataClass
    implements Insertable<ShoppingListItemTermQueueEntry> {
  final String id;
  final String shoppingListItemId;
  final String name;
  final String? userId;
  final double? amount;
  final String? unit;
  final String status;
  final int retryCount;
  final String? error;
  final int? createdAt;
  final int? updatedAt;
  const ShoppingListItemTermQueueEntry(
      {required this.id,
      required this.shoppingListItemId,
      required this.name,
      this.userId,
      this.amount,
      this.unit,
      required this.status,
      required this.retryCount,
      this.error,
      this.createdAt,
      this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['shopping_list_item_id'] = Variable<String>(shoppingListItemId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    if (!nullToAbsent || amount != null) {
      map['amount'] = Variable<double>(amount);
    }
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    map['status'] = Variable<String>(status);
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || error != null) {
      map['error'] = Variable<String>(error);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<int>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<int>(updatedAt);
    }
    return map;
  }

  ShoppingListItemTermQueuesCompanion toCompanion(bool nullToAbsent) {
    return ShoppingListItemTermQueuesCompanion(
      id: Value(id),
      shoppingListItemId: Value(shoppingListItemId),
      name: Value(name),
      userId:
          userId == null && nullToAbsent ? const Value.absent() : Value(userId),
      amount:
          amount == null && nullToAbsent ? const Value.absent() : Value(amount),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      status: Value(status),
      retryCount: Value(retryCount),
      error:
          error == null && nullToAbsent ? const Value.absent() : Value(error),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory ShoppingListItemTermQueueEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShoppingListItemTermQueueEntry(
      id: serializer.fromJson<String>(json['id']),
      shoppingListItemId:
          serializer.fromJson<String>(json['shoppingListItemId']),
      name: serializer.fromJson<String>(json['name']),
      userId: serializer.fromJson<String?>(json['userId']),
      amount: serializer.fromJson<double?>(json['amount']),
      unit: serializer.fromJson<String?>(json['unit']),
      status: serializer.fromJson<String>(json['status']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      error: serializer.fromJson<String?>(json['error']),
      createdAt: serializer.fromJson<int?>(json['createdAt']),
      updatedAt: serializer.fromJson<int?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'shoppingListItemId': serializer.toJson<String>(shoppingListItemId),
      'name': serializer.toJson<String>(name),
      'userId': serializer.toJson<String?>(userId),
      'amount': serializer.toJson<double?>(amount),
      'unit': serializer.toJson<String?>(unit),
      'status': serializer.toJson<String>(status),
      'retryCount': serializer.toJson<int>(retryCount),
      'error': serializer.toJson<String?>(error),
      'createdAt': serializer.toJson<int?>(createdAt),
      'updatedAt': serializer.toJson<int?>(updatedAt),
    };
  }

  ShoppingListItemTermQueueEntry copyWith(
          {String? id,
          String? shoppingListItemId,
          String? name,
          Value<String?> userId = const Value.absent(),
          Value<double?> amount = const Value.absent(),
          Value<String?> unit = const Value.absent(),
          String? status,
          int? retryCount,
          Value<String?> error = const Value.absent(),
          Value<int?> createdAt = const Value.absent(),
          Value<int?> updatedAt = const Value.absent()}) =>
      ShoppingListItemTermQueueEntry(
        id: id ?? this.id,
        shoppingListItemId: shoppingListItemId ?? this.shoppingListItemId,
        name: name ?? this.name,
        userId: userId.present ? userId.value : this.userId,
        amount: amount.present ? amount.value : this.amount,
        unit: unit.present ? unit.value : this.unit,
        status: status ?? this.status,
        retryCount: retryCount ?? this.retryCount,
        error: error.present ? error.value : this.error,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
      );
  ShoppingListItemTermQueueEntry copyWithCompanion(
      ShoppingListItemTermQueuesCompanion data) {
    return ShoppingListItemTermQueueEntry(
      id: data.id.present ? data.id.value : this.id,
      shoppingListItemId: data.shoppingListItemId.present
          ? data.shoppingListItemId.value
          : this.shoppingListItemId,
      name: data.name.present ? data.name.value : this.name,
      userId: data.userId.present ? data.userId.value : this.userId,
      amount: data.amount.present ? data.amount.value : this.amount,
      unit: data.unit.present ? data.unit.value : this.unit,
      status: data.status.present ? data.status.value : this.status,
      retryCount:
          data.retryCount.present ? data.retryCount.value : this.retryCount,
      error: data.error.present ? data.error.value : this.error,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShoppingListItemTermQueueEntry(')
          ..write('id: $id, ')
          ..write('shoppingListItemId: $shoppingListItemId, ')
          ..write('name: $name, ')
          ..write('userId: $userId, ')
          ..write('amount: $amount, ')
          ..write('unit: $unit, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount, ')
          ..write('error: $error, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, shoppingListItemId, name, userId, amount,
      unit, status, retryCount, error, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShoppingListItemTermQueueEntry &&
          other.id == this.id &&
          other.shoppingListItemId == this.shoppingListItemId &&
          other.name == this.name &&
          other.userId == this.userId &&
          other.amount == this.amount &&
          other.unit == this.unit &&
          other.status == this.status &&
          other.retryCount == this.retryCount &&
          other.error == this.error &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ShoppingListItemTermQueuesCompanion
    extends UpdateCompanion<ShoppingListItemTermQueueEntry> {
  final Value<String> id;
  final Value<String> shoppingListItemId;
  final Value<String> name;
  final Value<String?> userId;
  final Value<double?> amount;
  final Value<String?> unit;
  final Value<String> status;
  final Value<int> retryCount;
  final Value<String?> error;
  final Value<int?> createdAt;
  final Value<int?> updatedAt;
  final Value<int> rowid;
  const ShoppingListItemTermQueuesCompanion({
    this.id = const Value.absent(),
    this.shoppingListItemId = const Value.absent(),
    this.name = const Value.absent(),
    this.userId = const Value.absent(),
    this.amount = const Value.absent(),
    this.unit = const Value.absent(),
    this.status = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.error = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ShoppingListItemTermQueuesCompanion.insert({
    this.id = const Value.absent(),
    required String shoppingListItemId,
    required String name,
    this.userId = const Value.absent(),
    this.amount = const Value.absent(),
    this.unit = const Value.absent(),
    this.status = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.error = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : shoppingListItemId = Value(shoppingListItemId),
        name = Value(name);
  static Insertable<ShoppingListItemTermQueueEntry> custom({
    Expression<String>? id,
    Expression<String>? shoppingListItemId,
    Expression<String>? name,
    Expression<String>? userId,
    Expression<double>? amount,
    Expression<String>? unit,
    Expression<String>? status,
    Expression<int>? retryCount,
    Expression<String>? error,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (shoppingListItemId != null)
        'shopping_list_item_id': shoppingListItemId,
      if (name != null) 'name': name,
      if (userId != null) 'user_id': userId,
      if (amount != null) 'amount': amount,
      if (unit != null) 'unit': unit,
      if (status != null) 'status': status,
      if (retryCount != null) 'retry_count': retryCount,
      if (error != null) 'error': error,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ShoppingListItemTermQueuesCompanion copyWith(
      {Value<String>? id,
      Value<String>? shoppingListItemId,
      Value<String>? name,
      Value<String?>? userId,
      Value<double?>? amount,
      Value<String?>? unit,
      Value<String>? status,
      Value<int>? retryCount,
      Value<String?>? error,
      Value<int?>? createdAt,
      Value<int?>? updatedAt,
      Value<int>? rowid}) {
    return ShoppingListItemTermQueuesCompanion(
      id: id ?? this.id,
      shoppingListItemId: shoppingListItemId ?? this.shoppingListItemId,
      name: name ?? this.name,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      error: error ?? this.error,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (shoppingListItemId.present) {
      map['shopping_list_item_id'] = Variable<String>(shoppingListItemId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (error.present) {
      map['error'] = Variable<String>(error.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShoppingListItemTermQueuesCompanion(')
          ..write('id: $id, ')
          ..write('shoppingListItemId: $shoppingListItemId, ')
          ..write('name: $name, ')
          ..write('userId: $userId, ')
          ..write('amount: $amount, ')
          ..write('unit: $unit, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount, ')
          ..write('error: $error, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
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
  static const VerificationMeta _stockStatusMeta =
      const VerificationMeta('stockStatus');
  @override
  late final GeneratedColumnWithTypeConverter<StockStatus, int> stockStatus =
      GeneratedColumn<int>('stock_status', aliasedName, false,
              type: DriftSqlType.int,
              requiredDuringInsert: false,
              defaultValue: const Constant(2))
          .withConverter<StockStatus>($PantryItemsTable.$converterstockStatus);
  static const VerificationMeta _isStapleMeta =
      const VerificationMeta('isStaple');
  @override
  late final GeneratedColumn<bool> isStaple = GeneratedColumn<bool>(
      'is_staple', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_staple" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isCanonicalisedMeta =
      const VerificationMeta('isCanonicalised');
  @override
  late final GeneratedColumn<bool> isCanonicalised = GeneratedColumn<bool>(
      'is_canonicalised', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_canonicalised" IN (0, 1))'),
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
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
      'unit', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _quantityMeta =
      const VerificationMeta('quantity');
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
      'quantity', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _baseUnitMeta =
      const VerificationMeta('baseUnit');
  @override
  late final GeneratedColumn<String> baseUnit = GeneratedColumn<String>(
      'base_unit', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _baseQuantityMeta =
      const VerificationMeta('baseQuantity');
  @override
  late final GeneratedColumn<double> baseQuantity = GeneratedColumn<double>(
      'base_quantity', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<double> price = GeneratedColumn<double>(
      'price', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
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
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        stockStatus,
        isStaple,
        isCanonicalised,
        userId,
        householdId,
        unit,
        quantity,
        baseUnit,
        baseQuantity,
        price,
        createdAt,
        updatedAt,
        deletedAt,
        terms,
        category
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
    context.handle(_stockStatusMeta, const VerificationResult.success());
    if (data.containsKey('is_staple')) {
      context.handle(_isStapleMeta,
          isStaple.isAcceptableOrUnknown(data['is_staple']!, _isStapleMeta));
    }
    if (data.containsKey('is_canonicalised')) {
      context.handle(
          _isCanonicalisedMeta,
          isCanonicalised.isAcceptableOrUnknown(
              data['is_canonicalised']!, _isCanonicalisedMeta));
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
    if (data.containsKey('unit')) {
      context.handle(
          _unitMeta, unit.isAcceptableOrUnknown(data['unit']!, _unitMeta));
    }
    if (data.containsKey('quantity')) {
      context.handle(_quantityMeta,
          quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta));
    }
    if (data.containsKey('base_unit')) {
      context.handle(_baseUnitMeta,
          baseUnit.isAcceptableOrUnknown(data['base_unit']!, _baseUnitMeta));
    }
    if (data.containsKey('base_quantity')) {
      context.handle(
          _baseQuantityMeta,
          baseQuantity.isAcceptableOrUnknown(
              data['base_quantity']!, _baseQuantityMeta));
    }
    if (data.containsKey('price')) {
      context.handle(
          _priceMeta, price.isAcceptableOrUnknown(data['price']!, _priceMeta));
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
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    }
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
      stockStatus: $PantryItemsTable.$converterstockStatus.fromSql(
          attachedDatabase.typeMapping
              .read(DriftSqlType.int, data['${effectivePrefix}stock_status'])!),
      isStaple: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_staple'])!,
      isCanonicalised: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_canonicalised'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id']),
      householdId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}household_id']),
      unit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit']),
      quantity: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}quantity']),
      baseUnit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}base_unit']),
      baseQuantity: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}base_quantity']),
      price: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}price']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at']),
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}deleted_at']),
      terms: $PantryItemsTable.$convertertermsn.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}terms'])),
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category']),
    );
  }

  @override
  $PantryItemsTable createAlias(String alias) {
    return $PantryItemsTable(attachedDatabase, alias);
  }

  static TypeConverter<StockStatus, int> $converterstockStatus =
      const StockStatusConverter();
  static TypeConverter<List<PantryItemTerm>, String> $converterterms =
      const PantryItemTermListConverter();
  static TypeConverter<List<PantryItemTerm>?, String?> $convertertermsn =
      NullAwareTypeConverter.wrap($converterterms);
}

class PantryItemEntry extends DataClass implements Insertable<PantryItemEntry> {
  final String id;
  final String name;
  final StockStatus stockStatus;
  final bool isStaple;
  final bool isCanonicalised;
  final String? userId;
  final String? householdId;
  final String? unit;
  final double? quantity;
  final String? baseUnit;
  final double? baseQuantity;
  final double? price;
  final int? createdAt;
  final int? updatedAt;
  final int? deletedAt;
  final List<PantryItemTerm>? terms;
  final String? category;
  const PantryItemEntry(
      {required this.id,
      required this.name,
      required this.stockStatus,
      required this.isStaple,
      required this.isCanonicalised,
      this.userId,
      this.householdId,
      this.unit,
      this.quantity,
      this.baseUnit,
      this.baseQuantity,
      this.price,
      this.createdAt,
      this.updatedAt,
      this.deletedAt,
      this.terms,
      this.category});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    {
      map['stock_status'] = Variable<int>(
          $PantryItemsTable.$converterstockStatus.toSql(stockStatus));
    }
    map['is_staple'] = Variable<bool>(isStaple);
    map['is_canonicalised'] = Variable<bool>(isCanonicalised);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    if (!nullToAbsent || householdId != null) {
      map['household_id'] = Variable<String>(householdId);
    }
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    if (!nullToAbsent || quantity != null) {
      map['quantity'] = Variable<double>(quantity);
    }
    if (!nullToAbsent || baseUnit != null) {
      map['base_unit'] = Variable<String>(baseUnit);
    }
    if (!nullToAbsent || baseQuantity != null) {
      map['base_quantity'] = Variable<double>(baseQuantity);
    }
    if (!nullToAbsent || price != null) {
      map['price'] = Variable<double>(price);
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
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    return map;
  }

  PantryItemsCompanion toCompanion(bool nullToAbsent) {
    return PantryItemsCompanion(
      id: Value(id),
      name: Value(name),
      stockStatus: Value(stockStatus),
      isStaple: Value(isStaple),
      isCanonicalised: Value(isCanonicalised),
      userId:
          userId == null && nullToAbsent ? const Value.absent() : Value(userId),
      householdId: householdId == null && nullToAbsent
          ? const Value.absent()
          : Value(householdId),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      quantity: quantity == null && nullToAbsent
          ? const Value.absent()
          : Value(quantity),
      baseUnit: baseUnit == null && nullToAbsent
          ? const Value.absent()
          : Value(baseUnit),
      baseQuantity: baseQuantity == null && nullToAbsent
          ? const Value.absent()
          : Value(baseQuantity),
      price:
          price == null && nullToAbsent ? const Value.absent() : Value(price),
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
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
    );
  }

  factory PantryItemEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PantryItemEntry(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      stockStatus: serializer.fromJson<StockStatus>(json['stockStatus']),
      isStaple: serializer.fromJson<bool>(json['isStaple']),
      isCanonicalised: serializer.fromJson<bool>(json['isCanonicalised']),
      userId: serializer.fromJson<String?>(json['userId']),
      householdId: serializer.fromJson<String?>(json['householdId']),
      unit: serializer.fromJson<String?>(json['unit']),
      quantity: serializer.fromJson<double?>(json['quantity']),
      baseUnit: serializer.fromJson<String?>(json['baseUnit']),
      baseQuantity: serializer.fromJson<double?>(json['baseQuantity']),
      price: serializer.fromJson<double?>(json['price']),
      createdAt: serializer.fromJson<int?>(json['createdAt']),
      updatedAt: serializer.fromJson<int?>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      terms: serializer.fromJson<List<PantryItemTerm>?>(json['terms']),
      category: serializer.fromJson<String?>(json['category']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'stockStatus': serializer.toJson<StockStatus>(stockStatus),
      'isStaple': serializer.toJson<bool>(isStaple),
      'isCanonicalised': serializer.toJson<bool>(isCanonicalised),
      'userId': serializer.toJson<String?>(userId),
      'householdId': serializer.toJson<String?>(householdId),
      'unit': serializer.toJson<String?>(unit),
      'quantity': serializer.toJson<double?>(quantity),
      'baseUnit': serializer.toJson<String?>(baseUnit),
      'baseQuantity': serializer.toJson<double?>(baseQuantity),
      'price': serializer.toJson<double?>(price),
      'createdAt': serializer.toJson<int?>(createdAt),
      'updatedAt': serializer.toJson<int?>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'terms': serializer.toJson<List<PantryItemTerm>?>(terms),
      'category': serializer.toJson<String?>(category),
    };
  }

  PantryItemEntry copyWith(
          {String? id,
          String? name,
          StockStatus? stockStatus,
          bool? isStaple,
          bool? isCanonicalised,
          Value<String?> userId = const Value.absent(),
          Value<String?> householdId = const Value.absent(),
          Value<String?> unit = const Value.absent(),
          Value<double?> quantity = const Value.absent(),
          Value<String?> baseUnit = const Value.absent(),
          Value<double?> baseQuantity = const Value.absent(),
          Value<double?> price = const Value.absent(),
          Value<int?> createdAt = const Value.absent(),
          Value<int?> updatedAt = const Value.absent(),
          Value<int?> deletedAt = const Value.absent(),
          Value<List<PantryItemTerm>?> terms = const Value.absent(),
          Value<String?> category = const Value.absent()}) =>
      PantryItemEntry(
        id: id ?? this.id,
        name: name ?? this.name,
        stockStatus: stockStatus ?? this.stockStatus,
        isStaple: isStaple ?? this.isStaple,
        isCanonicalised: isCanonicalised ?? this.isCanonicalised,
        userId: userId.present ? userId.value : this.userId,
        householdId: householdId.present ? householdId.value : this.householdId,
        unit: unit.present ? unit.value : this.unit,
        quantity: quantity.present ? quantity.value : this.quantity,
        baseUnit: baseUnit.present ? baseUnit.value : this.baseUnit,
        baseQuantity:
            baseQuantity.present ? baseQuantity.value : this.baseQuantity,
        price: price.present ? price.value : this.price,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        terms: terms.present ? terms.value : this.terms,
        category: category.present ? category.value : this.category,
      );
  PantryItemEntry copyWithCompanion(PantryItemsCompanion data) {
    return PantryItemEntry(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      stockStatus:
          data.stockStatus.present ? data.stockStatus.value : this.stockStatus,
      isStaple: data.isStaple.present ? data.isStaple.value : this.isStaple,
      isCanonicalised: data.isCanonicalised.present
          ? data.isCanonicalised.value
          : this.isCanonicalised,
      userId: data.userId.present ? data.userId.value : this.userId,
      householdId:
          data.householdId.present ? data.householdId.value : this.householdId,
      unit: data.unit.present ? data.unit.value : this.unit,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      baseUnit: data.baseUnit.present ? data.baseUnit.value : this.baseUnit,
      baseQuantity: data.baseQuantity.present
          ? data.baseQuantity.value
          : this.baseQuantity,
      price: data.price.present ? data.price.value : this.price,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      terms: data.terms.present ? data.terms.value : this.terms,
      category: data.category.present ? data.category.value : this.category,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PantryItemEntry(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('stockStatus: $stockStatus, ')
          ..write('isStaple: $isStaple, ')
          ..write('isCanonicalised: $isCanonicalised, ')
          ..write('userId: $userId, ')
          ..write('householdId: $householdId, ')
          ..write('unit: $unit, ')
          ..write('quantity: $quantity, ')
          ..write('baseUnit: $baseUnit, ')
          ..write('baseQuantity: $baseQuantity, ')
          ..write('price: $price, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('terms: $terms, ')
          ..write('category: $category')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      name,
      stockStatus,
      isStaple,
      isCanonicalised,
      userId,
      householdId,
      unit,
      quantity,
      baseUnit,
      baseQuantity,
      price,
      createdAt,
      updatedAt,
      deletedAt,
      terms,
      category);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PantryItemEntry &&
          other.id == this.id &&
          other.name == this.name &&
          other.stockStatus == this.stockStatus &&
          other.isStaple == this.isStaple &&
          other.isCanonicalised == this.isCanonicalised &&
          other.userId == this.userId &&
          other.householdId == this.householdId &&
          other.unit == this.unit &&
          other.quantity == this.quantity &&
          other.baseUnit == this.baseUnit &&
          other.baseQuantity == this.baseQuantity &&
          other.price == this.price &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.terms == this.terms &&
          other.category == this.category);
}

class PantryItemsCompanion extends UpdateCompanion<PantryItemEntry> {
  final Value<String> id;
  final Value<String> name;
  final Value<StockStatus> stockStatus;
  final Value<bool> isStaple;
  final Value<bool> isCanonicalised;
  final Value<String?> userId;
  final Value<String?> householdId;
  final Value<String?> unit;
  final Value<double?> quantity;
  final Value<String?> baseUnit;
  final Value<double?> baseQuantity;
  final Value<double?> price;
  final Value<int?> createdAt;
  final Value<int?> updatedAt;
  final Value<int?> deletedAt;
  final Value<List<PantryItemTerm>?> terms;
  final Value<String?> category;
  final Value<int> rowid;
  const PantryItemsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.stockStatus = const Value.absent(),
    this.isStaple = const Value.absent(),
    this.isCanonicalised = const Value.absent(),
    this.userId = const Value.absent(),
    this.householdId = const Value.absent(),
    this.unit = const Value.absent(),
    this.quantity = const Value.absent(),
    this.baseUnit = const Value.absent(),
    this.baseQuantity = const Value.absent(),
    this.price = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.terms = const Value.absent(),
    this.category = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PantryItemsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.stockStatus = const Value.absent(),
    this.isStaple = const Value.absent(),
    this.isCanonicalised = const Value.absent(),
    this.userId = const Value.absent(),
    this.householdId = const Value.absent(),
    this.unit = const Value.absent(),
    this.quantity = const Value.absent(),
    this.baseUnit = const Value.absent(),
    this.baseQuantity = const Value.absent(),
    this.price = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.terms = const Value.absent(),
    this.category = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : name = Value(name);
  static Insertable<PantryItemEntry> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? stockStatus,
    Expression<bool>? isStaple,
    Expression<bool>? isCanonicalised,
    Expression<String>? userId,
    Expression<String>? householdId,
    Expression<String>? unit,
    Expression<double>? quantity,
    Expression<String>? baseUnit,
    Expression<double>? baseQuantity,
    Expression<double>? price,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? terms,
    Expression<String>? category,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (stockStatus != null) 'stock_status': stockStatus,
      if (isStaple != null) 'is_staple': isStaple,
      if (isCanonicalised != null) 'is_canonicalised': isCanonicalised,
      if (userId != null) 'user_id': userId,
      if (householdId != null) 'household_id': householdId,
      if (unit != null) 'unit': unit,
      if (quantity != null) 'quantity': quantity,
      if (baseUnit != null) 'base_unit': baseUnit,
      if (baseQuantity != null) 'base_quantity': baseQuantity,
      if (price != null) 'price': price,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (terms != null) 'terms': terms,
      if (category != null) 'category': category,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PantryItemsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<StockStatus>? stockStatus,
      Value<bool>? isStaple,
      Value<bool>? isCanonicalised,
      Value<String?>? userId,
      Value<String?>? householdId,
      Value<String?>? unit,
      Value<double?>? quantity,
      Value<String?>? baseUnit,
      Value<double?>? baseQuantity,
      Value<double?>? price,
      Value<int?>? createdAt,
      Value<int?>? updatedAt,
      Value<int?>? deletedAt,
      Value<List<PantryItemTerm>?>? terms,
      Value<String?>? category,
      Value<int>? rowid}) {
    return PantryItemsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      stockStatus: stockStatus ?? this.stockStatus,
      isStaple: isStaple ?? this.isStaple,
      isCanonicalised: isCanonicalised ?? this.isCanonicalised,
      userId: userId ?? this.userId,
      householdId: householdId ?? this.householdId,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      baseUnit: baseUnit ?? this.baseUnit,
      baseQuantity: baseQuantity ?? this.baseQuantity,
      price: price ?? this.price,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      terms: terms ?? this.terms,
      category: category ?? this.category,
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
    if (stockStatus.present) {
      map['stock_status'] = Variable<int>(
          $PantryItemsTable.$converterstockStatus.toSql(stockStatus.value));
    }
    if (isStaple.present) {
      map['is_staple'] = Variable<bool>(isStaple.value);
    }
    if (isCanonicalised.present) {
      map['is_canonicalised'] = Variable<bool>(isCanonicalised.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (baseUnit.present) {
      map['base_unit'] = Variable<String>(baseUnit.value);
    }
    if (baseQuantity.present) {
      map['base_quantity'] = Variable<double>(baseQuantity.value);
    }
    if (price.present) {
      map['price'] = Variable<double>(price.value);
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
    if (category.present) {
      map['category'] = Variable<String>(category.value);
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
          ..write('stockStatus: $stockStatus, ')
          ..write('isStaple: $isStaple, ')
          ..write('isCanonicalised: $isCanonicalised, ')
          ..write('userId: $userId, ')
          ..write('householdId: $householdId, ')
          ..write('unit: $unit, ')
          ..write('quantity: $quantity, ')
          ..write('baseUnit: $baseUnit, ')
          ..write('baseQuantity: $baseQuantity, ')
          ..write('price: $price, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('terms: $terms, ')
          ..write('category: $category, ')
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
      'shopping_list_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _termsMeta = const VerificationMeta('terms');
  @override
  late final GeneratedColumnWithTypeConverter<List<String>?, String> terms =
      GeneratedColumn<String>('terms', aliasedName, true,
              type: DriftSqlType.string, requiredDuringInsert: false)
          .withConverter<List<String>?>(
              $ShoppingListItemsTable.$convertertermsn);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
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
        terms,
        category,
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
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    context.handle(_termsMeta, const VerificationResult.success());
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    }
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
          DriftSqlType.string, data['${effectivePrefix}shopping_list_id']),
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      terms: $ShoppingListItemsTable.$convertertermsn.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}terms'])),
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category']),
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

  static TypeConverter<List<String>, String> $converterterms =
      StringListTypeConverter();
  static TypeConverter<List<String>?, String?> $convertertermsn =
      NullAwareTypeConverter.wrap($converterterms);
}

class ShoppingListItemEntry extends DataClass
    implements Insertable<ShoppingListItemEntry> {
  final String id;
  final String? shoppingListId;
  final String name;
  final List<String>? terms;
  final String? category;
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
      this.shoppingListId,
      required this.name,
      this.terms,
      this.category,
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
    if (!nullToAbsent || shoppingListId != null) {
      map['shopping_list_id'] = Variable<String>(shoppingListId);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || terms != null) {
      map['terms'] = Variable<String>(
          $ShoppingListItemsTable.$convertertermsn.toSql(terms));
    }
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
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
      shoppingListId: shoppingListId == null && nullToAbsent
          ? const Value.absent()
          : Value(shoppingListId),
      name: Value(name),
      terms:
          terms == null && nullToAbsent ? const Value.absent() : Value(terms),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
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
      shoppingListId: serializer.fromJson<String?>(json['shoppingListId']),
      name: serializer.fromJson<String>(json['name']),
      terms: serializer.fromJson<List<String>?>(json['terms']),
      category: serializer.fromJson<String?>(json['category']),
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
      'shoppingListId': serializer.toJson<String?>(shoppingListId),
      'name': serializer.toJson<String>(name),
      'terms': serializer.toJson<List<String>?>(terms),
      'category': serializer.toJson<String?>(category),
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
          Value<String?> shoppingListId = const Value.absent(),
          String? name,
          Value<List<String>?> terms = const Value.absent(),
          Value<String?> category = const Value.absent(),
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
        shoppingListId:
            shoppingListId.present ? shoppingListId.value : this.shoppingListId,
        name: name ?? this.name,
        terms: terms.present ? terms.value : this.terms,
        category: category.present ? category.value : this.category,
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
      terms: data.terms.present ? data.terms.value : this.terms,
      category: data.category.present ? data.category.value : this.category,
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
          ..write('terms: $terms, ')
          ..write('category: $category, ')
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
      terms,
      category,
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
          other.terms == this.terms &&
          other.category == this.category &&
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
  final Value<String?> shoppingListId;
  final Value<String> name;
  final Value<List<String>?> terms;
  final Value<String?> category;
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
    this.terms = const Value.absent(),
    this.category = const Value.absent(),
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
    this.shoppingListId = const Value.absent(),
    required String name,
    this.terms = const Value.absent(),
    this.category = const Value.absent(),
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
  }) : name = Value(name);
  static Insertable<ShoppingListItemEntry> custom({
    Expression<String>? id,
    Expression<String>? shoppingListId,
    Expression<String>? name,
    Expression<String>? terms,
    Expression<String>? category,
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
      if (terms != null) 'terms': terms,
      if (category != null) 'category': category,
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
      Value<String?>? shoppingListId,
      Value<String>? name,
      Value<List<String>?>? terms,
      Value<String?>? category,
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
      terms: terms ?? this.terms,
      category: category ?? this.category,
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
    if (terms.present) {
      map['terms'] = Variable<String>(
          $ShoppingListItemsTable.$convertertermsn.toSql(terms.value));
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
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
          ..write('terms: $terms, ')
          ..write('category: $category, ')
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

class $ConvertersTable extends Converters
    with TableInfo<$ConvertersTable, ConverterEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConvertersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      clientDefault: () => const Uuid().v4());
  static const VerificationMeta _termMeta = const VerificationMeta('term');
  @override
  late final GeneratedColumn<String> term = GeneratedColumn<String>(
      'term', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fromUnitMeta =
      const VerificationMeta('fromUnit');
  @override
  late final GeneratedColumn<String> fromUnit = GeneratedColumn<String>(
      'from_unit', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _toBaseUnitMeta =
      const VerificationMeta('toBaseUnit');
  @override
  late final GeneratedColumn<String> toBaseUnit = GeneratedColumn<String>(
      'to_base_unit', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _conversionFactorMeta =
      const VerificationMeta('conversionFactor');
  @override
  late final GeneratedColumn<double> conversionFactor = GeneratedColumn<double>(
      'conversion_factor', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _isApproximateMeta =
      const VerificationMeta('isApproximate');
  @override
  late final GeneratedColumn<bool> isApproximate = GeneratedColumn<bool>(
      'is_approximate', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_approximate" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
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
  List<GeneratedColumn> get $columns => [
        id,
        term,
        fromUnit,
        toBaseUnit,
        conversionFactor,
        isApproximate,
        notes,
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
  static const String $name = 'converters';
  @override
  VerificationContext validateIntegrity(Insertable<ConverterEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('term')) {
      context.handle(
          _termMeta, term.isAcceptableOrUnknown(data['term']!, _termMeta));
    } else if (isInserting) {
      context.missing(_termMeta);
    }
    if (data.containsKey('from_unit')) {
      context.handle(_fromUnitMeta,
          fromUnit.isAcceptableOrUnknown(data['from_unit']!, _fromUnitMeta));
    } else if (isInserting) {
      context.missing(_fromUnitMeta);
    }
    if (data.containsKey('to_base_unit')) {
      context.handle(
          _toBaseUnitMeta,
          toBaseUnit.isAcceptableOrUnknown(
              data['to_base_unit']!, _toBaseUnitMeta));
    } else if (isInserting) {
      context.missing(_toBaseUnitMeta);
    }
    if (data.containsKey('conversion_factor')) {
      context.handle(
          _conversionFactorMeta,
          conversionFactor.isAcceptableOrUnknown(
              data['conversion_factor']!, _conversionFactorMeta));
    } else if (isInserting) {
      context.missing(_conversionFactorMeta);
    }
    if (data.containsKey('is_approximate')) {
      context.handle(
          _isApproximateMeta,
          isApproximate.isAcceptableOrUnknown(
              data['is_approximate']!, _isApproximateMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
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
  ConverterEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConverterEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      term: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}term'])!,
      fromUnit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}from_unit'])!,
      toBaseUnit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}to_base_unit'])!,
      conversionFactor: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}conversion_factor'])!,
      isApproximate: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_approximate'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
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
  $ConvertersTable createAlias(String alias) {
    return $ConvertersTable(attachedDatabase, alias);
  }
}

class ConverterEntry extends DataClass implements Insertable<ConverterEntry> {
  final String id;
  final String term;
  final String fromUnit;
  final String toBaseUnit;
  final double conversionFactor;
  final bool isApproximate;
  final String? notes;
  final String? userId;
  final String? householdId;
  final int? createdAt;
  final int? updatedAt;
  final int? deletedAt;
  const ConverterEntry(
      {required this.id,
      required this.term,
      required this.fromUnit,
      required this.toBaseUnit,
      required this.conversionFactor,
      required this.isApproximate,
      this.notes,
      this.userId,
      this.householdId,
      this.createdAt,
      this.updatedAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['term'] = Variable<String>(term);
    map['from_unit'] = Variable<String>(fromUnit);
    map['to_base_unit'] = Variable<String>(toBaseUnit);
    map['conversion_factor'] = Variable<double>(conversionFactor);
    map['is_approximate'] = Variable<bool>(isApproximate);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
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

  ConvertersCompanion toCompanion(bool nullToAbsent) {
    return ConvertersCompanion(
      id: Value(id),
      term: Value(term),
      fromUnit: Value(fromUnit),
      toBaseUnit: Value(toBaseUnit),
      conversionFactor: Value(conversionFactor),
      isApproximate: Value(isApproximate),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
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

  factory ConverterEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConverterEntry(
      id: serializer.fromJson<String>(json['id']),
      term: serializer.fromJson<String>(json['term']),
      fromUnit: serializer.fromJson<String>(json['fromUnit']),
      toBaseUnit: serializer.fromJson<String>(json['toBaseUnit']),
      conversionFactor: serializer.fromJson<double>(json['conversionFactor']),
      isApproximate: serializer.fromJson<bool>(json['isApproximate']),
      notes: serializer.fromJson<String?>(json['notes']),
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
      'term': serializer.toJson<String>(term),
      'fromUnit': serializer.toJson<String>(fromUnit),
      'toBaseUnit': serializer.toJson<String>(toBaseUnit),
      'conversionFactor': serializer.toJson<double>(conversionFactor),
      'isApproximate': serializer.toJson<bool>(isApproximate),
      'notes': serializer.toJson<String?>(notes),
      'userId': serializer.toJson<String?>(userId),
      'householdId': serializer.toJson<String?>(householdId),
      'createdAt': serializer.toJson<int?>(createdAt),
      'updatedAt': serializer.toJson<int?>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  ConverterEntry copyWith(
          {String? id,
          String? term,
          String? fromUnit,
          String? toBaseUnit,
          double? conversionFactor,
          bool? isApproximate,
          Value<String?> notes = const Value.absent(),
          Value<String?> userId = const Value.absent(),
          Value<String?> householdId = const Value.absent(),
          Value<int?> createdAt = const Value.absent(),
          Value<int?> updatedAt = const Value.absent(),
          Value<int?> deletedAt = const Value.absent()}) =>
      ConverterEntry(
        id: id ?? this.id,
        term: term ?? this.term,
        fromUnit: fromUnit ?? this.fromUnit,
        toBaseUnit: toBaseUnit ?? this.toBaseUnit,
        conversionFactor: conversionFactor ?? this.conversionFactor,
        isApproximate: isApproximate ?? this.isApproximate,
        notes: notes.present ? notes.value : this.notes,
        userId: userId.present ? userId.value : this.userId,
        householdId: householdId.present ? householdId.value : this.householdId,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  ConverterEntry copyWithCompanion(ConvertersCompanion data) {
    return ConverterEntry(
      id: data.id.present ? data.id.value : this.id,
      term: data.term.present ? data.term.value : this.term,
      fromUnit: data.fromUnit.present ? data.fromUnit.value : this.fromUnit,
      toBaseUnit:
          data.toBaseUnit.present ? data.toBaseUnit.value : this.toBaseUnit,
      conversionFactor: data.conversionFactor.present
          ? data.conversionFactor.value
          : this.conversionFactor,
      isApproximate: data.isApproximate.present
          ? data.isApproximate.value
          : this.isApproximate,
      notes: data.notes.present ? data.notes.value : this.notes,
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
    return (StringBuffer('ConverterEntry(')
          ..write('id: $id, ')
          ..write('term: $term, ')
          ..write('fromUnit: $fromUnit, ')
          ..write('toBaseUnit: $toBaseUnit, ')
          ..write('conversionFactor: $conversionFactor, ')
          ..write('isApproximate: $isApproximate, ')
          ..write('notes: $notes, ')
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
      term,
      fromUnit,
      toBaseUnit,
      conversionFactor,
      isApproximate,
      notes,
      userId,
      householdId,
      createdAt,
      updatedAt,
      deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConverterEntry &&
          other.id == this.id &&
          other.term == this.term &&
          other.fromUnit == this.fromUnit &&
          other.toBaseUnit == this.toBaseUnit &&
          other.conversionFactor == this.conversionFactor &&
          other.isApproximate == this.isApproximate &&
          other.notes == this.notes &&
          other.userId == this.userId &&
          other.householdId == this.householdId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class ConvertersCompanion extends UpdateCompanion<ConverterEntry> {
  final Value<String> id;
  final Value<String> term;
  final Value<String> fromUnit;
  final Value<String> toBaseUnit;
  final Value<double> conversionFactor;
  final Value<bool> isApproximate;
  final Value<String?> notes;
  final Value<String?> userId;
  final Value<String?> householdId;
  final Value<int?> createdAt;
  final Value<int?> updatedAt;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const ConvertersCompanion({
    this.id = const Value.absent(),
    this.term = const Value.absent(),
    this.fromUnit = const Value.absent(),
    this.toBaseUnit = const Value.absent(),
    this.conversionFactor = const Value.absent(),
    this.isApproximate = const Value.absent(),
    this.notes = const Value.absent(),
    this.userId = const Value.absent(),
    this.householdId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConvertersCompanion.insert({
    this.id = const Value.absent(),
    required String term,
    required String fromUnit,
    required String toBaseUnit,
    required double conversionFactor,
    this.isApproximate = const Value.absent(),
    this.notes = const Value.absent(),
    this.userId = const Value.absent(),
    this.householdId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : term = Value(term),
        fromUnit = Value(fromUnit),
        toBaseUnit = Value(toBaseUnit),
        conversionFactor = Value(conversionFactor);
  static Insertable<ConverterEntry> custom({
    Expression<String>? id,
    Expression<String>? term,
    Expression<String>? fromUnit,
    Expression<String>? toBaseUnit,
    Expression<double>? conversionFactor,
    Expression<bool>? isApproximate,
    Expression<String>? notes,
    Expression<String>? userId,
    Expression<String>? householdId,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (term != null) 'term': term,
      if (fromUnit != null) 'from_unit': fromUnit,
      if (toBaseUnit != null) 'to_base_unit': toBaseUnit,
      if (conversionFactor != null) 'conversion_factor': conversionFactor,
      if (isApproximate != null) 'is_approximate': isApproximate,
      if (notes != null) 'notes': notes,
      if (userId != null) 'user_id': userId,
      if (householdId != null) 'household_id': householdId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConvertersCompanion copyWith(
      {Value<String>? id,
      Value<String>? term,
      Value<String>? fromUnit,
      Value<String>? toBaseUnit,
      Value<double>? conversionFactor,
      Value<bool>? isApproximate,
      Value<String?>? notes,
      Value<String?>? userId,
      Value<String?>? householdId,
      Value<int?>? createdAt,
      Value<int?>? updatedAt,
      Value<int?>? deletedAt,
      Value<int>? rowid}) {
    return ConvertersCompanion(
      id: id ?? this.id,
      term: term ?? this.term,
      fromUnit: fromUnit ?? this.fromUnit,
      toBaseUnit: toBaseUnit ?? this.toBaseUnit,
      conversionFactor: conversionFactor ?? this.conversionFactor,
      isApproximate: isApproximate ?? this.isApproximate,
      notes: notes ?? this.notes,
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
    if (term.present) {
      map['term'] = Variable<String>(term.value);
    }
    if (fromUnit.present) {
      map['from_unit'] = Variable<String>(fromUnit.value);
    }
    if (toBaseUnit.present) {
      map['to_base_unit'] = Variable<String>(toBaseUnit.value);
    }
    if (conversionFactor.present) {
      map['conversion_factor'] = Variable<double>(conversionFactor.value);
    }
    if (isApproximate.present) {
      map['is_approximate'] = Variable<bool>(isApproximate.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
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
    return (StringBuffer('ConvertersCompanion(')
          ..write('id: $id, ')
          ..write('term: $term, ')
          ..write('fromUnit: $fromUnit, ')
          ..write('toBaseUnit: $toBaseUnit, ')
          ..write('conversionFactor: $conversionFactor, ')
          ..write('isApproximate: $isApproximate, ')
          ..write('notes: $notes, ')
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

class $MealPlansTable extends MealPlans
    with TableInfo<$MealPlansTable, MealPlanEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MealPlansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      clientDefault: () => const Uuid().v4());
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
      'date', aliasedName, false,
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
  static const VerificationMeta _itemsMeta = const VerificationMeta('items');
  @override
  late final GeneratedColumnWithTypeConverter<List<MealPlanItem>?, String>
      items = GeneratedColumn<String>('items', aliasedName, true,
              type: DriftSqlType.string, requiredDuringInsert: false)
          .withConverter<List<MealPlanItem>?>($MealPlansTable.$converteritemsn);
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
      [id, date, userId, householdId, items, createdAt, updatedAt, deletedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meal_plans';
  @override
  VerificationContext validateIntegrity(Insertable<MealPlanEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
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
    context.handle(_itemsMeta, const VerificationResult.success());
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
  MealPlanEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MealPlanEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}date'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id']),
      householdId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}household_id']),
      items: $MealPlansTable.$converteritemsn.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}items'])),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at']),
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $MealPlansTable createAlias(String alias) {
    return $MealPlansTable(attachedDatabase, alias);
  }

  static TypeConverter<List<MealPlanItem>, String> $converteritems =
      const MealPlanItemListConverter();
  static TypeConverter<List<MealPlanItem>?, String?> $converteritemsn =
      NullAwareTypeConverter.wrap($converteritems);
}

class MealPlanEntry extends DataClass implements Insertable<MealPlanEntry> {
  final String id;
  final String date;
  final String? userId;
  final String? householdId;
  final List<MealPlanItem>? items;
  final int? createdAt;
  final int? updatedAt;
  final int? deletedAt;
  const MealPlanEntry(
      {required this.id,
      required this.date,
      this.userId,
      this.householdId,
      this.items,
      this.createdAt,
      this.updatedAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['date'] = Variable<String>(date);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    if (!nullToAbsent || householdId != null) {
      map['household_id'] = Variable<String>(householdId);
    }
    if (!nullToAbsent || items != null) {
      map['items'] =
          Variable<String>($MealPlansTable.$converteritemsn.toSql(items));
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

  MealPlansCompanion toCompanion(bool nullToAbsent) {
    return MealPlansCompanion(
      id: Value(id),
      date: Value(date),
      userId:
          userId == null && nullToAbsent ? const Value.absent() : Value(userId),
      householdId: householdId == null && nullToAbsent
          ? const Value.absent()
          : Value(householdId),
      items:
          items == null && nullToAbsent ? const Value.absent() : Value(items),
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

  factory MealPlanEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MealPlanEntry(
      id: serializer.fromJson<String>(json['id']),
      date: serializer.fromJson<String>(json['date']),
      userId: serializer.fromJson<String?>(json['userId']),
      householdId: serializer.fromJson<String?>(json['householdId']),
      items: serializer.fromJson<List<MealPlanItem>?>(json['items']),
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
      'date': serializer.toJson<String>(date),
      'userId': serializer.toJson<String?>(userId),
      'householdId': serializer.toJson<String?>(householdId),
      'items': serializer.toJson<List<MealPlanItem>?>(items),
      'createdAt': serializer.toJson<int?>(createdAt),
      'updatedAt': serializer.toJson<int?>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  MealPlanEntry copyWith(
          {String? id,
          String? date,
          Value<String?> userId = const Value.absent(),
          Value<String?> householdId = const Value.absent(),
          Value<List<MealPlanItem>?> items = const Value.absent(),
          Value<int?> createdAt = const Value.absent(),
          Value<int?> updatedAt = const Value.absent(),
          Value<int?> deletedAt = const Value.absent()}) =>
      MealPlanEntry(
        id: id ?? this.id,
        date: date ?? this.date,
        userId: userId.present ? userId.value : this.userId,
        householdId: householdId.present ? householdId.value : this.householdId,
        items: items.present ? items.value : this.items,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  MealPlanEntry copyWithCompanion(MealPlansCompanion data) {
    return MealPlanEntry(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      userId: data.userId.present ? data.userId.value : this.userId,
      householdId:
          data.householdId.present ? data.householdId.value : this.householdId,
      items: data.items.present ? data.items.value : this.items,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MealPlanEntry(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('userId: $userId, ')
          ..write('householdId: $householdId, ')
          ..write('items: $items, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, date, userId, householdId, items, createdAt, updatedAt, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MealPlanEntry &&
          other.id == this.id &&
          other.date == this.date &&
          other.userId == this.userId &&
          other.householdId == this.householdId &&
          other.items == this.items &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class MealPlansCompanion extends UpdateCompanion<MealPlanEntry> {
  final Value<String> id;
  final Value<String> date;
  final Value<String?> userId;
  final Value<String?> householdId;
  final Value<List<MealPlanItem>?> items;
  final Value<int?> createdAt;
  final Value<int?> updatedAt;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const MealPlansCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.userId = const Value.absent(),
    this.householdId = const Value.absent(),
    this.items = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MealPlansCompanion.insert({
    this.id = const Value.absent(),
    required String date,
    this.userId = const Value.absent(),
    this.householdId = const Value.absent(),
    this.items = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : date = Value(date);
  static Insertable<MealPlanEntry> custom({
    Expression<String>? id,
    Expression<String>? date,
    Expression<String>? userId,
    Expression<String>? householdId,
    Expression<String>? items,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (userId != null) 'user_id': userId,
      if (householdId != null) 'household_id': householdId,
      if (items != null) 'items': items,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MealPlansCompanion copyWith(
      {Value<String>? id,
      Value<String>? date,
      Value<String?>? userId,
      Value<String?>? householdId,
      Value<List<MealPlanItem>?>? items,
      Value<int?>? createdAt,
      Value<int?>? updatedAt,
      Value<int?>? deletedAt,
      Value<int>? rowid}) {
    return MealPlansCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      userId: userId ?? this.userId,
      householdId: householdId ?? this.householdId,
      items: items ?? this.items,
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
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (items.present) {
      map['items'] =
          Variable<String>($MealPlansTable.$converteritemsn.toSql(items.value));
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
    return (StringBuffer('MealPlansCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('userId: $userId, ')
          ..write('householdId: $householdId, ')
          ..write('items: $items, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserSubscriptionsTable extends UserSubscriptions
    with TableInfo<$UserSubscriptionsTable, UserSubscriptionEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserSubscriptionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      clientDefault: () => const Uuid().v4());
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
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumnWithTypeConverter<SubscriptionStatus, String>
      status = GeneratedColumn<String>('status', aliasedName, false,
              type: DriftSqlType.string,
              requiredDuringInsert: false,
              defaultValue: const Constant('none'))
          .withConverter<SubscriptionStatus>(
              $UserSubscriptionsTable.$converterstatus);
  static const VerificationMeta _entitlementsMeta =
      const VerificationMeta('entitlements');
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String>
      entitlements = GeneratedColumn<String>('entitlements', aliasedName, false,
              type: DriftSqlType.string,
              requiredDuringInsert: false,
              defaultValue: const Constant('[]'))
          .withConverter<List<String>>(
              $UserSubscriptionsTable.$converterentitlements);
  static const VerificationMeta _expiresAtMeta =
      const VerificationMeta('expiresAt');
  @override
  late final GeneratedColumn<int> expiresAt = GeneratedColumn<int>(
      'expires_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _trialEndsAtMeta =
      const VerificationMeta('trialEndsAt');
  @override
  late final GeneratedColumn<int> trialEndsAt = GeneratedColumn<int>(
      'trial_ends_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _cancelledAtMeta =
      const VerificationMeta('cancelledAt');
  @override
  late final GeneratedColumn<int> cancelledAt = GeneratedColumn<int>(
      'cancelled_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _productIdMeta =
      const VerificationMeta('productId');
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
      'product_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _storeMeta = const VerificationMeta('store');
  @override
  late final GeneratedColumn<String> store = GeneratedColumn<String>(
      'store', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _revenuecatCustomerIdMeta =
      const VerificationMeta('revenuecatCustomerId');
  @override
  late final GeneratedColumn<String> revenuecatCustomerId =
      GeneratedColumn<String>('revenuecat_customer_id', aliasedName, true,
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
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        householdId,
        status,
        entitlements,
        expiresAt,
        trialEndsAt,
        cancelledAt,
        productId,
        store,
        revenuecatCustomerId,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_subscriptions';
  @override
  VerificationContext validateIntegrity(
      Insertable<UserSubscriptionEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
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
    context.handle(_statusMeta, const VerificationResult.success());
    context.handle(_entitlementsMeta, const VerificationResult.success());
    if (data.containsKey('expires_at')) {
      context.handle(_expiresAtMeta,
          expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta));
    }
    if (data.containsKey('trial_ends_at')) {
      context.handle(
          _trialEndsAtMeta,
          trialEndsAt.isAcceptableOrUnknown(
              data['trial_ends_at']!, _trialEndsAtMeta));
    }
    if (data.containsKey('cancelled_at')) {
      context.handle(
          _cancelledAtMeta,
          cancelledAt.isAcceptableOrUnknown(
              data['cancelled_at']!, _cancelledAtMeta));
    }
    if (data.containsKey('product_id')) {
      context.handle(_productIdMeta,
          productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta));
    }
    if (data.containsKey('store')) {
      context.handle(
          _storeMeta, store.isAcceptableOrUnknown(data['store']!, _storeMeta));
    }
    if (data.containsKey('revenuecat_customer_id')) {
      context.handle(
          _revenuecatCustomerIdMeta,
          revenuecatCustomerId.isAcceptableOrUnknown(
              data['revenuecat_customer_id']!, _revenuecatCustomerIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserSubscriptionEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserSubscriptionEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      householdId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}household_id']),
      status: $UserSubscriptionsTable.$converterstatus.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!),
      entitlements: $UserSubscriptionsTable.$converterentitlements.fromSql(
          attachedDatabase.typeMapping.read(
              DriftSqlType.string, data['${effectivePrefix}entitlements'])!),
      expiresAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}expires_at']),
      trialEndsAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}trial_ends_at']),
      cancelledAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}cancelled_at']),
      productId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_id']),
      store: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}store']),
      revenuecatCustomerId: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}revenuecat_customer_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at']),
    );
  }

  @override
  $UserSubscriptionsTable createAlias(String alias) {
    return $UserSubscriptionsTable(attachedDatabase, alias);
  }

  static TypeConverter<SubscriptionStatus, String> $converterstatus =
      const SubscriptionStatusConverter();
  static TypeConverter<List<String>, String> $converterentitlements =
      const StringListTypeConverter();
}

class UserSubscriptionEntry extends DataClass
    implements Insertable<UserSubscriptionEntry> {
  final String id;
  final String userId;
  final String? householdId;
  final SubscriptionStatus status;
  final List<String> entitlements;
  final int? expiresAt;
  final int? trialEndsAt;
  final int? cancelledAt;
  final String? productId;
  final String? store;
  final String? revenuecatCustomerId;
  final int? createdAt;
  final int? updatedAt;
  const UserSubscriptionEntry(
      {required this.id,
      required this.userId,
      this.householdId,
      required this.status,
      required this.entitlements,
      this.expiresAt,
      this.trialEndsAt,
      this.cancelledAt,
      this.productId,
      this.store,
      this.revenuecatCustomerId,
      this.createdAt,
      this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || householdId != null) {
      map['household_id'] = Variable<String>(householdId);
    }
    {
      map['status'] = Variable<String>(
          $UserSubscriptionsTable.$converterstatus.toSql(status));
    }
    {
      map['entitlements'] = Variable<String>(
          $UserSubscriptionsTable.$converterentitlements.toSql(entitlements));
    }
    if (!nullToAbsent || expiresAt != null) {
      map['expires_at'] = Variable<int>(expiresAt);
    }
    if (!nullToAbsent || trialEndsAt != null) {
      map['trial_ends_at'] = Variable<int>(trialEndsAt);
    }
    if (!nullToAbsent || cancelledAt != null) {
      map['cancelled_at'] = Variable<int>(cancelledAt);
    }
    if (!nullToAbsent || productId != null) {
      map['product_id'] = Variable<String>(productId);
    }
    if (!nullToAbsent || store != null) {
      map['store'] = Variable<String>(store);
    }
    if (!nullToAbsent || revenuecatCustomerId != null) {
      map['revenuecat_customer_id'] = Variable<String>(revenuecatCustomerId);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<int>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<int>(updatedAt);
    }
    return map;
  }

  UserSubscriptionsCompanion toCompanion(bool nullToAbsent) {
    return UserSubscriptionsCompanion(
      id: Value(id),
      userId: Value(userId),
      householdId: householdId == null && nullToAbsent
          ? const Value.absent()
          : Value(householdId),
      status: Value(status),
      entitlements: Value(entitlements),
      expiresAt: expiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(expiresAt),
      trialEndsAt: trialEndsAt == null && nullToAbsent
          ? const Value.absent()
          : Value(trialEndsAt),
      cancelledAt: cancelledAt == null && nullToAbsent
          ? const Value.absent()
          : Value(cancelledAt),
      productId: productId == null && nullToAbsent
          ? const Value.absent()
          : Value(productId),
      store:
          store == null && nullToAbsent ? const Value.absent() : Value(store),
      revenuecatCustomerId: revenuecatCustomerId == null && nullToAbsent
          ? const Value.absent()
          : Value(revenuecatCustomerId),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory UserSubscriptionEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserSubscriptionEntry(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      householdId: serializer.fromJson<String?>(json['householdId']),
      status: serializer.fromJson<SubscriptionStatus>(json['status']),
      entitlements: serializer.fromJson<List<String>>(json['entitlements']),
      expiresAt: serializer.fromJson<int?>(json['expiresAt']),
      trialEndsAt: serializer.fromJson<int?>(json['trialEndsAt']),
      cancelledAt: serializer.fromJson<int?>(json['cancelledAt']),
      productId: serializer.fromJson<String?>(json['productId']),
      store: serializer.fromJson<String?>(json['store']),
      revenuecatCustomerId:
          serializer.fromJson<String?>(json['revenuecatCustomerId']),
      createdAt: serializer.fromJson<int?>(json['createdAt']),
      updatedAt: serializer.fromJson<int?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'householdId': serializer.toJson<String?>(householdId),
      'status': serializer.toJson<SubscriptionStatus>(status),
      'entitlements': serializer.toJson<List<String>>(entitlements),
      'expiresAt': serializer.toJson<int?>(expiresAt),
      'trialEndsAt': serializer.toJson<int?>(trialEndsAt),
      'cancelledAt': serializer.toJson<int?>(cancelledAt),
      'productId': serializer.toJson<String?>(productId),
      'store': serializer.toJson<String?>(store),
      'revenuecatCustomerId': serializer.toJson<String?>(revenuecatCustomerId),
      'createdAt': serializer.toJson<int?>(createdAt),
      'updatedAt': serializer.toJson<int?>(updatedAt),
    };
  }

  UserSubscriptionEntry copyWith(
          {String? id,
          String? userId,
          Value<String?> householdId = const Value.absent(),
          SubscriptionStatus? status,
          List<String>? entitlements,
          Value<int?> expiresAt = const Value.absent(),
          Value<int?> trialEndsAt = const Value.absent(),
          Value<int?> cancelledAt = const Value.absent(),
          Value<String?> productId = const Value.absent(),
          Value<String?> store = const Value.absent(),
          Value<String?> revenuecatCustomerId = const Value.absent(),
          Value<int?> createdAt = const Value.absent(),
          Value<int?> updatedAt = const Value.absent()}) =>
      UserSubscriptionEntry(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        householdId: householdId.present ? householdId.value : this.householdId,
        status: status ?? this.status,
        entitlements: entitlements ?? this.entitlements,
        expiresAt: expiresAt.present ? expiresAt.value : this.expiresAt,
        trialEndsAt: trialEndsAt.present ? trialEndsAt.value : this.trialEndsAt,
        cancelledAt: cancelledAt.present ? cancelledAt.value : this.cancelledAt,
        productId: productId.present ? productId.value : this.productId,
        store: store.present ? store.value : this.store,
        revenuecatCustomerId: revenuecatCustomerId.present
            ? revenuecatCustomerId.value
            : this.revenuecatCustomerId,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
      );
  UserSubscriptionEntry copyWithCompanion(UserSubscriptionsCompanion data) {
    return UserSubscriptionEntry(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      householdId:
          data.householdId.present ? data.householdId.value : this.householdId,
      status: data.status.present ? data.status.value : this.status,
      entitlements: data.entitlements.present
          ? data.entitlements.value
          : this.entitlements,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      trialEndsAt:
          data.trialEndsAt.present ? data.trialEndsAt.value : this.trialEndsAt,
      cancelledAt:
          data.cancelledAt.present ? data.cancelledAt.value : this.cancelledAt,
      productId: data.productId.present ? data.productId.value : this.productId,
      store: data.store.present ? data.store.value : this.store,
      revenuecatCustomerId: data.revenuecatCustomerId.present
          ? data.revenuecatCustomerId.value
          : this.revenuecatCustomerId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserSubscriptionEntry(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('householdId: $householdId, ')
          ..write('status: $status, ')
          ..write('entitlements: $entitlements, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('trialEndsAt: $trialEndsAt, ')
          ..write('cancelledAt: $cancelledAt, ')
          ..write('productId: $productId, ')
          ..write('store: $store, ')
          ..write('revenuecatCustomerId: $revenuecatCustomerId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      userId,
      householdId,
      status,
      entitlements,
      expiresAt,
      trialEndsAt,
      cancelledAt,
      productId,
      store,
      revenuecatCustomerId,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserSubscriptionEntry &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.householdId == this.householdId &&
          other.status == this.status &&
          other.entitlements == this.entitlements &&
          other.expiresAt == this.expiresAt &&
          other.trialEndsAt == this.trialEndsAt &&
          other.cancelledAt == this.cancelledAt &&
          other.productId == this.productId &&
          other.store == this.store &&
          other.revenuecatCustomerId == this.revenuecatCustomerId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class UserSubscriptionsCompanion
    extends UpdateCompanion<UserSubscriptionEntry> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String?> householdId;
  final Value<SubscriptionStatus> status;
  final Value<List<String>> entitlements;
  final Value<int?> expiresAt;
  final Value<int?> trialEndsAt;
  final Value<int?> cancelledAt;
  final Value<String?> productId;
  final Value<String?> store;
  final Value<String?> revenuecatCustomerId;
  final Value<int?> createdAt;
  final Value<int?> updatedAt;
  final Value<int> rowid;
  const UserSubscriptionsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.householdId = const Value.absent(),
    this.status = const Value.absent(),
    this.entitlements = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.trialEndsAt = const Value.absent(),
    this.cancelledAt = const Value.absent(),
    this.productId = const Value.absent(),
    this.store = const Value.absent(),
    this.revenuecatCustomerId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserSubscriptionsCompanion.insert({
    this.id = const Value.absent(),
    required String userId,
    this.householdId = const Value.absent(),
    this.status = const Value.absent(),
    this.entitlements = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.trialEndsAt = const Value.absent(),
    this.cancelledAt = const Value.absent(),
    this.productId = const Value.absent(),
    this.store = const Value.absent(),
    this.revenuecatCustomerId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : userId = Value(userId);
  static Insertable<UserSubscriptionEntry> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? householdId,
    Expression<String>? status,
    Expression<String>? entitlements,
    Expression<int>? expiresAt,
    Expression<int>? trialEndsAt,
    Expression<int>? cancelledAt,
    Expression<String>? productId,
    Expression<String>? store,
    Expression<String>? revenuecatCustomerId,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (householdId != null) 'household_id': householdId,
      if (status != null) 'status': status,
      if (entitlements != null) 'entitlements': entitlements,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (trialEndsAt != null) 'trial_ends_at': trialEndsAt,
      if (cancelledAt != null) 'cancelled_at': cancelledAt,
      if (productId != null) 'product_id': productId,
      if (store != null) 'store': store,
      if (revenuecatCustomerId != null)
        'revenuecat_customer_id': revenuecatCustomerId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserSubscriptionsCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String?>? householdId,
      Value<SubscriptionStatus>? status,
      Value<List<String>>? entitlements,
      Value<int?>? expiresAt,
      Value<int?>? trialEndsAt,
      Value<int?>? cancelledAt,
      Value<String?>? productId,
      Value<String?>? store,
      Value<String?>? revenuecatCustomerId,
      Value<int?>? createdAt,
      Value<int?>? updatedAt,
      Value<int>? rowid}) {
    return UserSubscriptionsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      householdId: householdId ?? this.householdId,
      status: status ?? this.status,
      entitlements: entitlements ?? this.entitlements,
      expiresAt: expiresAt ?? this.expiresAt,
      trialEndsAt: trialEndsAt ?? this.trialEndsAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      productId: productId ?? this.productId,
      store: store ?? this.store,
      revenuecatCustomerId: revenuecatCustomerId ?? this.revenuecatCustomerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
          $UserSubscriptionsTable.$converterstatus.toSql(status.value));
    }
    if (entitlements.present) {
      map['entitlements'] = Variable<String>($UserSubscriptionsTable
          .$converterentitlements
          .toSql(entitlements.value));
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<int>(expiresAt.value);
    }
    if (trialEndsAt.present) {
      map['trial_ends_at'] = Variable<int>(trialEndsAt.value);
    }
    if (cancelledAt.present) {
      map['cancelled_at'] = Variable<int>(cancelledAt.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (store.present) {
      map['store'] = Variable<String>(store.value);
    }
    if (revenuecatCustomerId.present) {
      map['revenuecat_customer_id'] =
          Variable<String>(revenuecatCustomerId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserSubscriptionsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('householdId: $householdId, ')
          ..write('status: $status, ')
          ..write('entitlements: $entitlements, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('trialEndsAt: $trialEndsAt, ')
          ..write('cancelledAt: $cancelledAt, ')
          ..write('productId: $productId, ')
          ..write('store: $store, ')
          ..write('revenuecatCustomerId: $revenuecatCustomerId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
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
  late final $HouseholdInvitesTable householdInvites =
      $HouseholdInvitesTable(this);
  late final $UploadQueuesTable uploadQueues = $UploadQueuesTable(this);
  late final $IngredientTermQueuesTable ingredientTermQueues =
      $IngredientTermQueuesTable(this);
  late final $PantryItemTermQueuesTable pantryItemTermQueues =
      $PantryItemTermQueuesTable(this);
  late final $ShoppingListItemTermQueuesTable shoppingListItemTermQueues =
      $ShoppingListItemTermQueuesTable(this);
  late final $CooksTable cooks = $CooksTable(this);
  late final $PantryItemsTable pantryItems = $PantryItemsTable(this);
  late final $IngredientTermOverridesTable ingredientTermOverrides =
      $IngredientTermOverridesTable(this);
  late final $ShoppingListItemsTable shoppingListItems =
      $ShoppingListItemsTable(this);
  late final $ShoppingListsTable shoppingLists = $ShoppingListsTable(this);
  late final $ConvertersTable converters = $ConvertersTable(this);
  late final $MealPlansTable mealPlans = $MealPlansTable(this);
  late final $UserSubscriptionsTable userSubscriptions =
      $UserSubscriptionsTable(this);
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
        householdInvites,
        uploadQueues,
        ingredientTermQueues,
        pantryItemTermQueues,
        shoppingListItemTermQueues,
        cooks,
        pantryItems,
        ingredientTermOverrides,
        shoppingListItems,
        shoppingLists,
        converters,
        mealPlans,
        userSubscriptions
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
  Value<String?> language,
  Value<int?> servings,
  Value<int?> prepTime,
  Value<int?> cookTime,
  Value<int?> totalTime,
  Value<String?> source,
  Value<String?> nutrition,
  Value<String?> generalNotes,
  Value<String?> userId,
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
  Value<String?> language,
  Value<int?> servings,
  Value<int?> prepTime,
  Value<int?> cookTime,
  Value<int?> totalTime,
  Value<String?> source,
  Value<String?> nutrition,
  Value<String?> generalNotes,
  Value<String?> userId,
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
            Value<String?> language = const Value.absent(),
            Value<int?> servings = const Value.absent(),
            Value<int?> prepTime = const Value.absent(),
            Value<int?> cookTime = const Value.absent(),
            Value<int?> totalTime = const Value.absent(),
            Value<String?> source = const Value.absent(),
            Value<String?> nutrition = const Value.absent(),
            Value<String?> generalNotes = const Value.absent(),
            Value<String?> userId = const Value.absent(),
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
            Value<String?> language = const Value.absent(),
            Value<int?> servings = const Value.absent(),
            Value<int?> prepTime = const Value.absent(),
            Value<int?> cookTime = const Value.absent(),
            Value<int?> totalTime = const Value.absent(),
            Value<String?> source = const Value.absent(),
            Value<String?> nutrition = const Value.absent(),
            Value<String?> generalNotes = const Value.absent(),
            Value<String?> userId = const Value.absent(),
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
  Value<String> role,
  required int joinedAt,
  Value<int?> updatedAt,
  Value<int> rowid,
});
typedef $$HouseholdMembersTableUpdateCompanionBuilder
    = HouseholdMembersCompanion Function({
  Value<String> id,
  Value<String> householdId,
  Value<String> userId,
  Value<int> isActive,
  Value<String> role,
  Value<int> joinedAt,
  Value<int?> updatedAt,
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

  ColumnFilters<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get joinedAt => $composableBuilder(
      column: $table.joinedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
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

  ColumnOrderings<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get joinedAt => $composableBuilder(
      column: $table.joinedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
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

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<int> get joinedAt =>
      $composableBuilder(column: $table.joinedAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
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
            Value<String> role = const Value.absent(),
            Value<int> joinedAt = const Value.absent(),
            Value<int?> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              HouseholdMembersCompanion(
            id: id,
            householdId: householdId,
            userId: userId,
            isActive: isActive,
            role: role,
            joinedAt: joinedAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            Value<String> id = const Value.absent(),
            required String householdId,
            required String userId,
            Value<int> isActive = const Value.absent(),
            Value<String> role = const Value.absent(),
            required int joinedAt,
            Value<int?> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              HouseholdMembersCompanion.insert(
            id: id,
            householdId: householdId,
            userId: userId,
            isActive: isActive,
            role: role,
            joinedAt: joinedAt,
            updatedAt: updatedAt,
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
typedef $$HouseholdInvitesTableCreateCompanionBuilder
    = HouseholdInvitesCompanion Function({
  Value<String> id,
  required String householdId,
  required String invitedByUserId,
  required String inviteCode,
  Value<String?> email,
  required String displayName,
  required String inviteType,
  Value<String> status,
  required int createdAt,
  required int updatedAt,
  Value<int?> lastSentAt,
  required int expiresAt,
  Value<int?> acceptedAt,
  Value<String?> acceptedByUserId,
  Value<int> rowid,
});
typedef $$HouseholdInvitesTableUpdateCompanionBuilder
    = HouseholdInvitesCompanion Function({
  Value<String> id,
  Value<String> householdId,
  Value<String> invitedByUserId,
  Value<String> inviteCode,
  Value<String?> email,
  Value<String> displayName,
  Value<String> inviteType,
  Value<String> status,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int?> lastSentAt,
  Value<int> expiresAt,
  Value<int?> acceptedAt,
  Value<String?> acceptedByUserId,
  Value<int> rowid,
});

class $$HouseholdInvitesTableFilterComposer
    extends Composer<_$AppDatabase, $HouseholdInvitesTable> {
  $$HouseholdInvitesTableFilterComposer({
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

  ColumnFilters<String> get invitedByUserId => $composableBuilder(
      column: $table.invitedByUserId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get inviteCode => $composableBuilder(
      column: $table.inviteCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get inviteType => $composableBuilder(
      column: $table.inviteType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastSentAt => $composableBuilder(
      column: $table.lastSentAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get expiresAt => $composableBuilder(
      column: $table.expiresAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get acceptedAt => $composableBuilder(
      column: $table.acceptedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get acceptedByUserId => $composableBuilder(
      column: $table.acceptedByUserId,
      builder: (column) => ColumnFilters(column));
}

class $$HouseholdInvitesTableOrderingComposer
    extends Composer<_$AppDatabase, $HouseholdInvitesTable> {
  $$HouseholdInvitesTableOrderingComposer({
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

  ColumnOrderings<String> get invitedByUserId => $composableBuilder(
      column: $table.invitedByUserId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get inviteCode => $composableBuilder(
      column: $table.inviteCode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get inviteType => $composableBuilder(
      column: $table.inviteType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastSentAt => $composableBuilder(
      column: $table.lastSentAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get expiresAt => $composableBuilder(
      column: $table.expiresAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get acceptedAt => $composableBuilder(
      column: $table.acceptedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get acceptedByUserId => $composableBuilder(
      column: $table.acceptedByUserId,
      builder: (column) => ColumnOrderings(column));
}

class $$HouseholdInvitesTableAnnotationComposer
    extends Composer<_$AppDatabase, $HouseholdInvitesTable> {
  $$HouseholdInvitesTableAnnotationComposer({
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

  GeneratedColumn<String> get invitedByUserId => $composableBuilder(
      column: $table.invitedByUserId, builder: (column) => column);

  GeneratedColumn<String> get inviteCode => $composableBuilder(
      column: $table.inviteCode, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => column);

  GeneratedColumn<String> get inviteType => $composableBuilder(
      column: $table.inviteType, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get lastSentAt => $composableBuilder(
      column: $table.lastSentAt, builder: (column) => column);

  GeneratedColumn<int> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  GeneratedColumn<int> get acceptedAt => $composableBuilder(
      column: $table.acceptedAt, builder: (column) => column);

  GeneratedColumn<String> get acceptedByUserId => $composableBuilder(
      column: $table.acceptedByUserId, builder: (column) => column);
}

class $$HouseholdInvitesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $HouseholdInvitesTable,
    HouseholdInviteEntry,
    $$HouseholdInvitesTableFilterComposer,
    $$HouseholdInvitesTableOrderingComposer,
    $$HouseholdInvitesTableAnnotationComposer,
    $$HouseholdInvitesTableCreateCompanionBuilder,
    $$HouseholdInvitesTableUpdateCompanionBuilder,
    (
      HouseholdInviteEntry,
      BaseReferences<_$AppDatabase, $HouseholdInvitesTable,
          HouseholdInviteEntry>
    ),
    HouseholdInviteEntry,
    PrefetchHooks Function()> {
  $$HouseholdInvitesTableTableManager(
      _$AppDatabase db, $HouseholdInvitesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HouseholdInvitesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HouseholdInvitesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HouseholdInvitesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> householdId = const Value.absent(),
            Value<String> invitedByUserId = const Value.absent(),
            Value<String> inviteCode = const Value.absent(),
            Value<String?> email = const Value.absent(),
            Value<String> displayName = const Value.absent(),
            Value<String> inviteType = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<int?> lastSentAt = const Value.absent(),
            Value<int> expiresAt = const Value.absent(),
            Value<int?> acceptedAt = const Value.absent(),
            Value<String?> acceptedByUserId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              HouseholdInvitesCompanion(
            id: id,
            householdId: householdId,
            invitedByUserId: invitedByUserId,
            inviteCode: inviteCode,
            email: email,
            displayName: displayName,
            inviteType: inviteType,
            status: status,
            createdAt: createdAt,
            updatedAt: updatedAt,
            lastSentAt: lastSentAt,
            expiresAt: expiresAt,
            acceptedAt: acceptedAt,
            acceptedByUserId: acceptedByUserId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            Value<String> id = const Value.absent(),
            required String householdId,
            required String invitedByUserId,
            required String inviteCode,
            Value<String?> email = const Value.absent(),
            required String displayName,
            required String inviteType,
            Value<String> status = const Value.absent(),
            required int createdAt,
            required int updatedAt,
            Value<int?> lastSentAt = const Value.absent(),
            required int expiresAt,
            Value<int?> acceptedAt = const Value.absent(),
            Value<String?> acceptedByUserId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              HouseholdInvitesCompanion.insert(
            id: id,
            householdId: householdId,
            invitedByUserId: invitedByUserId,
            inviteCode: inviteCode,
            email: email,
            displayName: displayName,
            inviteType: inviteType,
            status: status,
            createdAt: createdAt,
            updatedAt: updatedAt,
            lastSentAt: lastSentAt,
            expiresAt: expiresAt,
            acceptedAt: acceptedAt,
            acceptedByUserId: acceptedByUserId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$HouseholdInvitesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $HouseholdInvitesTable,
    HouseholdInviteEntry,
    $$HouseholdInvitesTableFilterComposer,
    $$HouseholdInvitesTableOrderingComposer,
    $$HouseholdInvitesTableAnnotationComposer,
    $$HouseholdInvitesTableCreateCompanionBuilder,
    $$HouseholdInvitesTableUpdateCompanionBuilder,
    (
      HouseholdInviteEntry,
      BaseReferences<_$AppDatabase, $HouseholdInvitesTable,
          HouseholdInviteEntry>
    ),
    HouseholdInviteEntry,
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
typedef $$IngredientTermQueuesTableCreateCompanionBuilder
    = IngredientTermQueuesCompanion Function({
  Value<String> id,
  required String recipeId,
  required String ingredientId,
  required int requestTimestamp,
  Value<String> status,
  Value<int> retryCount,
  Value<int?> lastTryTimestamp,
  required String ingredientData,
  Value<String?> responseData,
  Value<int> rowid,
});
typedef $$IngredientTermQueuesTableUpdateCompanionBuilder
    = IngredientTermQueuesCompanion Function({
  Value<String> id,
  Value<String> recipeId,
  Value<String> ingredientId,
  Value<int> requestTimestamp,
  Value<String> status,
  Value<int> retryCount,
  Value<int?> lastTryTimestamp,
  Value<String> ingredientData,
  Value<String?> responseData,
  Value<int> rowid,
});

class $$IngredientTermQueuesTableFilterComposer
    extends Composer<_$AppDatabase, $IngredientTermQueuesTable> {
  $$IngredientTermQueuesTableFilterComposer({
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

  ColumnFilters<String> get ingredientId => $composableBuilder(
      column: $table.ingredientId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get requestTimestamp => $composableBuilder(
      column: $table.requestTimestamp,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastTryTimestamp => $composableBuilder(
      column: $table.lastTryTimestamp,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ingredientData => $composableBuilder(
      column: $table.ingredientData,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get responseData => $composableBuilder(
      column: $table.responseData, builder: (column) => ColumnFilters(column));
}

class $$IngredientTermQueuesTableOrderingComposer
    extends Composer<_$AppDatabase, $IngredientTermQueuesTable> {
  $$IngredientTermQueuesTableOrderingComposer({
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

  ColumnOrderings<String> get ingredientId => $composableBuilder(
      column: $table.ingredientId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get requestTimestamp => $composableBuilder(
      column: $table.requestTimestamp,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastTryTimestamp => $composableBuilder(
      column: $table.lastTryTimestamp,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ingredientData => $composableBuilder(
      column: $table.ingredientData,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get responseData => $composableBuilder(
      column: $table.responseData,
      builder: (column) => ColumnOrderings(column));
}

class $$IngredientTermQueuesTableAnnotationComposer
    extends Composer<_$AppDatabase, $IngredientTermQueuesTable> {
  $$IngredientTermQueuesTableAnnotationComposer({
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

  GeneratedColumn<String> get ingredientId => $composableBuilder(
      column: $table.ingredientId, builder: (column) => column);

  GeneratedColumn<int> get requestTimestamp => $composableBuilder(
      column: $table.requestTimestamp, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => column);

  GeneratedColumn<int> get lastTryTimestamp => $composableBuilder(
      column: $table.lastTryTimestamp, builder: (column) => column);

  GeneratedColumn<String> get ingredientData => $composableBuilder(
      column: $table.ingredientData, builder: (column) => column);

  GeneratedColumn<String> get responseData => $composableBuilder(
      column: $table.responseData, builder: (column) => column);
}

class $$IngredientTermQueuesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $IngredientTermQueuesTable,
    IngredientTermQueueEntry,
    $$IngredientTermQueuesTableFilterComposer,
    $$IngredientTermQueuesTableOrderingComposer,
    $$IngredientTermQueuesTableAnnotationComposer,
    $$IngredientTermQueuesTableCreateCompanionBuilder,
    $$IngredientTermQueuesTableUpdateCompanionBuilder,
    (
      IngredientTermQueueEntry,
      BaseReferences<_$AppDatabase, $IngredientTermQueuesTable,
          IngredientTermQueueEntry>
    ),
    IngredientTermQueueEntry,
    PrefetchHooks Function()> {
  $$IngredientTermQueuesTableTableManager(
      _$AppDatabase db, $IngredientTermQueuesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IngredientTermQueuesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IngredientTermQueuesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IngredientTermQueuesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> recipeId = const Value.absent(),
            Value<String> ingredientId = const Value.absent(),
            Value<int> requestTimestamp = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
            Value<int?> lastTryTimestamp = const Value.absent(),
            Value<String> ingredientData = const Value.absent(),
            Value<String?> responseData = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              IngredientTermQueuesCompanion(
            id: id,
            recipeId: recipeId,
            ingredientId: ingredientId,
            requestTimestamp: requestTimestamp,
            status: status,
            retryCount: retryCount,
            lastTryTimestamp: lastTryTimestamp,
            ingredientData: ingredientData,
            responseData: responseData,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            Value<String> id = const Value.absent(),
            required String recipeId,
            required String ingredientId,
            required int requestTimestamp,
            Value<String> status = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
            Value<int?> lastTryTimestamp = const Value.absent(),
            required String ingredientData,
            Value<String?> responseData = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              IngredientTermQueuesCompanion.insert(
            id: id,
            recipeId: recipeId,
            ingredientId: ingredientId,
            requestTimestamp: requestTimestamp,
            status: status,
            retryCount: retryCount,
            lastTryTimestamp: lastTryTimestamp,
            ingredientData: ingredientData,
            responseData: responseData,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$IngredientTermQueuesTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $IngredientTermQueuesTable,
        IngredientTermQueueEntry,
        $$IngredientTermQueuesTableFilterComposer,
        $$IngredientTermQueuesTableOrderingComposer,
        $$IngredientTermQueuesTableAnnotationComposer,
        $$IngredientTermQueuesTableCreateCompanionBuilder,
        $$IngredientTermQueuesTableUpdateCompanionBuilder,
        (
          IngredientTermQueueEntry,
          BaseReferences<_$AppDatabase, $IngredientTermQueuesTable,
              IngredientTermQueueEntry>
        ),
        IngredientTermQueueEntry,
        PrefetchHooks Function()>;
typedef $$PantryItemTermQueuesTableCreateCompanionBuilder
    = PantryItemTermQueuesCompanion Function({
  required String id,
  required String pantryItemId,
  required int requestTimestamp,
  required String pantryItemData,
  required String status,
  Value<int?> retryCount,
  Value<int?> lastTryTimestamp,
  Value<String?> responseData,
  Value<int> rowid,
});
typedef $$PantryItemTermQueuesTableUpdateCompanionBuilder
    = PantryItemTermQueuesCompanion Function({
  Value<String> id,
  Value<String> pantryItemId,
  Value<int> requestTimestamp,
  Value<String> pantryItemData,
  Value<String> status,
  Value<int?> retryCount,
  Value<int?> lastTryTimestamp,
  Value<String?> responseData,
  Value<int> rowid,
});

class $$PantryItemTermQueuesTableFilterComposer
    extends Composer<_$AppDatabase, $PantryItemTermQueuesTable> {
  $$PantryItemTermQueuesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pantryItemId => $composableBuilder(
      column: $table.pantryItemId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get requestTimestamp => $composableBuilder(
      column: $table.requestTimestamp,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pantryItemData => $composableBuilder(
      column: $table.pantryItemData,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastTryTimestamp => $composableBuilder(
      column: $table.lastTryTimestamp,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get responseData => $composableBuilder(
      column: $table.responseData, builder: (column) => ColumnFilters(column));
}

class $$PantryItemTermQueuesTableOrderingComposer
    extends Composer<_$AppDatabase, $PantryItemTermQueuesTable> {
  $$PantryItemTermQueuesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pantryItemId => $composableBuilder(
      column: $table.pantryItemId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get requestTimestamp => $composableBuilder(
      column: $table.requestTimestamp,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pantryItemData => $composableBuilder(
      column: $table.pantryItemData,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastTryTimestamp => $composableBuilder(
      column: $table.lastTryTimestamp,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get responseData => $composableBuilder(
      column: $table.responseData,
      builder: (column) => ColumnOrderings(column));
}

class $$PantryItemTermQueuesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PantryItemTermQueuesTable> {
  $$PantryItemTermQueuesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get pantryItemId => $composableBuilder(
      column: $table.pantryItemId, builder: (column) => column);

  GeneratedColumn<int> get requestTimestamp => $composableBuilder(
      column: $table.requestTimestamp, builder: (column) => column);

  GeneratedColumn<String> get pantryItemData => $composableBuilder(
      column: $table.pantryItemData, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => column);

  GeneratedColumn<int> get lastTryTimestamp => $composableBuilder(
      column: $table.lastTryTimestamp, builder: (column) => column);

  GeneratedColumn<String> get responseData => $composableBuilder(
      column: $table.responseData, builder: (column) => column);
}

class $$PantryItemTermQueuesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PantryItemTermQueuesTable,
    PantryItemTermQueueEntry,
    $$PantryItemTermQueuesTableFilterComposer,
    $$PantryItemTermQueuesTableOrderingComposer,
    $$PantryItemTermQueuesTableAnnotationComposer,
    $$PantryItemTermQueuesTableCreateCompanionBuilder,
    $$PantryItemTermQueuesTableUpdateCompanionBuilder,
    (
      PantryItemTermQueueEntry,
      BaseReferences<_$AppDatabase, $PantryItemTermQueuesTable,
          PantryItemTermQueueEntry>
    ),
    PantryItemTermQueueEntry,
    PrefetchHooks Function()> {
  $$PantryItemTermQueuesTableTableManager(
      _$AppDatabase db, $PantryItemTermQueuesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PantryItemTermQueuesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PantryItemTermQueuesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PantryItemTermQueuesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> pantryItemId = const Value.absent(),
            Value<int> requestTimestamp = const Value.absent(),
            Value<String> pantryItemData = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int?> retryCount = const Value.absent(),
            Value<int?> lastTryTimestamp = const Value.absent(),
            Value<String?> responseData = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PantryItemTermQueuesCompanion(
            id: id,
            pantryItemId: pantryItemId,
            requestTimestamp: requestTimestamp,
            pantryItemData: pantryItemData,
            status: status,
            retryCount: retryCount,
            lastTryTimestamp: lastTryTimestamp,
            responseData: responseData,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String pantryItemId,
            required int requestTimestamp,
            required String pantryItemData,
            required String status,
            Value<int?> retryCount = const Value.absent(),
            Value<int?> lastTryTimestamp = const Value.absent(),
            Value<String?> responseData = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PantryItemTermQueuesCompanion.insert(
            id: id,
            pantryItemId: pantryItemId,
            requestTimestamp: requestTimestamp,
            pantryItemData: pantryItemData,
            status: status,
            retryCount: retryCount,
            lastTryTimestamp: lastTryTimestamp,
            responseData: responseData,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PantryItemTermQueuesTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $PantryItemTermQueuesTable,
        PantryItemTermQueueEntry,
        $$PantryItemTermQueuesTableFilterComposer,
        $$PantryItemTermQueuesTableOrderingComposer,
        $$PantryItemTermQueuesTableAnnotationComposer,
        $$PantryItemTermQueuesTableCreateCompanionBuilder,
        $$PantryItemTermQueuesTableUpdateCompanionBuilder,
        (
          PantryItemTermQueueEntry,
          BaseReferences<_$AppDatabase, $PantryItemTermQueuesTable,
              PantryItemTermQueueEntry>
        ),
        PantryItemTermQueueEntry,
        PrefetchHooks Function()>;
typedef $$ShoppingListItemTermQueuesTableCreateCompanionBuilder
    = ShoppingListItemTermQueuesCompanion Function({
  Value<String> id,
  required String shoppingListItemId,
  required String name,
  Value<String?> userId,
  Value<double?> amount,
  Value<String?> unit,
  Value<String> status,
  Value<int> retryCount,
  Value<String?> error,
  Value<int?> createdAt,
  Value<int?> updatedAt,
  Value<int> rowid,
});
typedef $$ShoppingListItemTermQueuesTableUpdateCompanionBuilder
    = ShoppingListItemTermQueuesCompanion Function({
  Value<String> id,
  Value<String> shoppingListItemId,
  Value<String> name,
  Value<String?> userId,
  Value<double?> amount,
  Value<String?> unit,
  Value<String> status,
  Value<int> retryCount,
  Value<String?> error,
  Value<int?> createdAt,
  Value<int?> updatedAt,
  Value<int> rowid,
});

class $$ShoppingListItemTermQueuesTableFilterComposer
    extends Composer<_$AppDatabase, $ShoppingListItemTermQueuesTable> {
  $$ShoppingListItemTermQueuesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get shoppingListItemId => $composableBuilder(
      column: $table.shoppingListItemId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get error => $composableBuilder(
      column: $table.error, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$ShoppingListItemTermQueuesTableOrderingComposer
    extends Composer<_$AppDatabase, $ShoppingListItemTermQueuesTable> {
  $$ShoppingListItemTermQueuesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get shoppingListItemId => $composableBuilder(
      column: $table.shoppingListItemId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get error => $composableBuilder(
      column: $table.error, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$ShoppingListItemTermQueuesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShoppingListItemTermQueuesTable> {
  $$ShoppingListItemTermQueuesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get shoppingListItemId => $composableBuilder(
      column: $table.shoppingListItemId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => column);

  GeneratedColumn<String> get error =>
      $composableBuilder(column: $table.error, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ShoppingListItemTermQueuesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ShoppingListItemTermQueuesTable,
    ShoppingListItemTermQueueEntry,
    $$ShoppingListItemTermQueuesTableFilterComposer,
    $$ShoppingListItemTermQueuesTableOrderingComposer,
    $$ShoppingListItemTermQueuesTableAnnotationComposer,
    $$ShoppingListItemTermQueuesTableCreateCompanionBuilder,
    $$ShoppingListItemTermQueuesTableUpdateCompanionBuilder,
    (
      ShoppingListItemTermQueueEntry,
      BaseReferences<_$AppDatabase, $ShoppingListItemTermQueuesTable,
          ShoppingListItemTermQueueEntry>
    ),
    ShoppingListItemTermQueueEntry,
    PrefetchHooks Function()> {
  $$ShoppingListItemTermQueuesTableTableManager(
      _$AppDatabase db, $ShoppingListItemTermQueuesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShoppingListItemTermQueuesTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$ShoppingListItemTermQueuesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShoppingListItemTermQueuesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> shoppingListItemId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> userId = const Value.absent(),
            Value<double?> amount = const Value.absent(),
            Value<String?> unit = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
            Value<String?> error = const Value.absent(),
            Value<int?> createdAt = const Value.absent(),
            Value<int?> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ShoppingListItemTermQueuesCompanion(
            id: id,
            shoppingListItemId: shoppingListItemId,
            name: name,
            userId: userId,
            amount: amount,
            unit: unit,
            status: status,
            retryCount: retryCount,
            error: error,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            Value<String> id = const Value.absent(),
            required String shoppingListItemId,
            required String name,
            Value<String?> userId = const Value.absent(),
            Value<double?> amount = const Value.absent(),
            Value<String?> unit = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
            Value<String?> error = const Value.absent(),
            Value<int?> createdAt = const Value.absent(),
            Value<int?> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ShoppingListItemTermQueuesCompanion.insert(
            id: id,
            shoppingListItemId: shoppingListItemId,
            name: name,
            userId: userId,
            amount: amount,
            unit: unit,
            status: status,
            retryCount: retryCount,
            error: error,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ShoppingListItemTermQueuesTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $ShoppingListItemTermQueuesTable,
        ShoppingListItemTermQueueEntry,
        $$ShoppingListItemTermQueuesTableFilterComposer,
        $$ShoppingListItemTermQueuesTableOrderingComposer,
        $$ShoppingListItemTermQueuesTableAnnotationComposer,
        $$ShoppingListItemTermQueuesTableCreateCompanionBuilder,
        $$ShoppingListItemTermQueuesTableUpdateCompanionBuilder,
        (
          ShoppingListItemTermQueueEntry,
          BaseReferences<_$AppDatabase, $ShoppingListItemTermQueuesTable,
              ShoppingListItemTermQueueEntry>
        ),
        ShoppingListItemTermQueueEntry,
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
  Value<StockStatus> stockStatus,
  Value<bool> isStaple,
  Value<bool> isCanonicalised,
  Value<String?> userId,
  Value<String?> householdId,
  Value<String?> unit,
  Value<double?> quantity,
  Value<String?> baseUnit,
  Value<double?> baseQuantity,
  Value<double?> price,
  Value<int?> createdAt,
  Value<int?> updatedAt,
  Value<int?> deletedAt,
  Value<List<PantryItemTerm>?> terms,
  Value<String?> category,
  Value<int> rowid,
});
typedef $$PantryItemsTableUpdateCompanionBuilder = PantryItemsCompanion
    Function({
  Value<String> id,
  Value<String> name,
  Value<StockStatus> stockStatus,
  Value<bool> isStaple,
  Value<bool> isCanonicalised,
  Value<String?> userId,
  Value<String?> householdId,
  Value<String?> unit,
  Value<double?> quantity,
  Value<String?> baseUnit,
  Value<double?> baseQuantity,
  Value<double?> price,
  Value<int?> createdAt,
  Value<int?> updatedAt,
  Value<int?> deletedAt,
  Value<List<PantryItemTerm>?> terms,
  Value<String?> category,
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

  ColumnWithTypeConverterFilters<StockStatus, StockStatus, int>
      get stockStatus => $composableBuilder(
          column: $table.stockStatus,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<bool> get isStaple => $composableBuilder(
      column: $table.isStaple, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isCanonicalised => $composableBuilder(
      column: $table.isCanonicalised,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get baseUnit => $composableBuilder(
      column: $table.baseUnit, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get baseQuantity => $composableBuilder(
      column: $table.baseQuantity, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get price => $composableBuilder(
      column: $table.price, builder: (column) => ColumnFilters(column));

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

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));
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

  ColumnOrderings<int> get stockStatus => $composableBuilder(
      column: $table.stockStatus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isStaple => $composableBuilder(
      column: $table.isStaple, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isCanonicalised => $composableBuilder(
      column: $table.isCanonicalised,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get baseUnit => $composableBuilder(
      column: $table.baseUnit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get baseQuantity => $composableBuilder(
      column: $table.baseQuantity,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get price => $composableBuilder(
      column: $table.price, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get terms => $composableBuilder(
      column: $table.terms, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));
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

  GeneratedColumnWithTypeConverter<StockStatus, int> get stockStatus =>
      $composableBuilder(
          column: $table.stockStatus, builder: (column) => column);

  GeneratedColumn<bool> get isStaple =>
      $composableBuilder(column: $table.isStaple, builder: (column) => column);

  GeneratedColumn<bool> get isCanonicalised => $composableBuilder(
      column: $table.isCanonicalised, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get baseUnit =>
      $composableBuilder(column: $table.baseUnit, builder: (column) => column);

  GeneratedColumn<double> get baseQuantity => $composableBuilder(
      column: $table.baseQuantity, builder: (column) => column);

  GeneratedColumn<double> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<PantryItemTerm>?, String> get terms =>
      $composableBuilder(column: $table.terms, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);
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
            Value<StockStatus> stockStatus = const Value.absent(),
            Value<bool> isStaple = const Value.absent(),
            Value<bool> isCanonicalised = const Value.absent(),
            Value<String?> userId = const Value.absent(),
            Value<String?> householdId = const Value.absent(),
            Value<String?> unit = const Value.absent(),
            Value<double?> quantity = const Value.absent(),
            Value<String?> baseUnit = const Value.absent(),
            Value<double?> baseQuantity = const Value.absent(),
            Value<double?> price = const Value.absent(),
            Value<int?> createdAt = const Value.absent(),
            Value<int?> updatedAt = const Value.absent(),
            Value<int?> deletedAt = const Value.absent(),
            Value<List<PantryItemTerm>?> terms = const Value.absent(),
            Value<String?> category = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PantryItemsCompanion(
            id: id,
            name: name,
            stockStatus: stockStatus,
            isStaple: isStaple,
            isCanonicalised: isCanonicalised,
            userId: userId,
            householdId: householdId,
            unit: unit,
            quantity: quantity,
            baseUnit: baseUnit,
            baseQuantity: baseQuantity,
            price: price,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            terms: terms,
            category: category,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            Value<String> id = const Value.absent(),
            required String name,
            Value<StockStatus> stockStatus = const Value.absent(),
            Value<bool> isStaple = const Value.absent(),
            Value<bool> isCanonicalised = const Value.absent(),
            Value<String?> userId = const Value.absent(),
            Value<String?> householdId = const Value.absent(),
            Value<String?> unit = const Value.absent(),
            Value<double?> quantity = const Value.absent(),
            Value<String?> baseUnit = const Value.absent(),
            Value<double?> baseQuantity = const Value.absent(),
            Value<double?> price = const Value.absent(),
            Value<int?> createdAt = const Value.absent(),
            Value<int?> updatedAt = const Value.absent(),
            Value<int?> deletedAt = const Value.absent(),
            Value<List<PantryItemTerm>?> terms = const Value.absent(),
            Value<String?> category = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PantryItemsCompanion.insert(
            id: id,
            name: name,
            stockStatus: stockStatus,
            isStaple: isStaple,
            isCanonicalised: isCanonicalised,
            userId: userId,
            householdId: householdId,
            unit: unit,
            quantity: quantity,
            baseUnit: baseUnit,
            baseQuantity: baseQuantity,
            price: price,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            terms: terms,
            category: category,
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
  Value<String?> shoppingListId,
  required String name,
  Value<List<String>?> terms,
  Value<String?> category,
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
  Value<String?> shoppingListId,
  Value<String> name,
  Value<List<String>?> terms,
  Value<String?> category,
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
      get terms => $composableBuilder(
          column: $table.terms,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

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

  ColumnOrderings<String> get terms => $composableBuilder(
      column: $table.terms, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

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

  GeneratedColumnWithTypeConverter<List<String>?, String> get terms =>
      $composableBuilder(column: $table.terms, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

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
            Value<String?> shoppingListId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<List<String>?> terms = const Value.absent(),
            Value<String?> category = const Value.absent(),
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
            terms: terms,
            category: category,
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
            Value<String?> shoppingListId = const Value.absent(),
            required String name,
            Value<List<String>?> terms = const Value.absent(),
            Value<String?> category = const Value.absent(),
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
            terms: terms,
            category: category,
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
typedef $$ConvertersTableCreateCompanionBuilder = ConvertersCompanion Function({
  Value<String> id,
  required String term,
  required String fromUnit,
  required String toBaseUnit,
  required double conversionFactor,
  Value<bool> isApproximate,
  Value<String?> notes,
  Value<String?> userId,
  Value<String?> householdId,
  Value<int?> createdAt,
  Value<int?> updatedAt,
  Value<int?> deletedAt,
  Value<int> rowid,
});
typedef $$ConvertersTableUpdateCompanionBuilder = ConvertersCompanion Function({
  Value<String> id,
  Value<String> term,
  Value<String> fromUnit,
  Value<String> toBaseUnit,
  Value<double> conversionFactor,
  Value<bool> isApproximate,
  Value<String?> notes,
  Value<String?> userId,
  Value<String?> householdId,
  Value<int?> createdAt,
  Value<int?> updatedAt,
  Value<int?> deletedAt,
  Value<int> rowid,
});

class $$ConvertersTableFilterComposer
    extends Composer<_$AppDatabase, $ConvertersTable> {
  $$ConvertersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get term => $composableBuilder(
      column: $table.term, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fromUnit => $composableBuilder(
      column: $table.fromUnit, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get toBaseUnit => $composableBuilder(
      column: $table.toBaseUnit, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get conversionFactor => $composableBuilder(
      column: $table.conversionFactor,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isApproximate => $composableBuilder(
      column: $table.isApproximate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

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

class $$ConvertersTableOrderingComposer
    extends Composer<_$AppDatabase, $ConvertersTable> {
  $$ConvertersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get term => $composableBuilder(
      column: $table.term, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fromUnit => $composableBuilder(
      column: $table.fromUnit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get toBaseUnit => $composableBuilder(
      column: $table.toBaseUnit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get conversionFactor => $composableBuilder(
      column: $table.conversionFactor,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isApproximate => $composableBuilder(
      column: $table.isApproximate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

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

class $$ConvertersTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConvertersTable> {
  $$ConvertersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get term =>
      $composableBuilder(column: $table.term, builder: (column) => column);

  GeneratedColumn<String> get fromUnit =>
      $composableBuilder(column: $table.fromUnit, builder: (column) => column);

  GeneratedColumn<String> get toBaseUnit => $composableBuilder(
      column: $table.toBaseUnit, builder: (column) => column);

  GeneratedColumn<double> get conversionFactor => $composableBuilder(
      column: $table.conversionFactor, builder: (column) => column);

  GeneratedColumn<bool> get isApproximate => $composableBuilder(
      column: $table.isApproximate, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

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

class $$ConvertersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ConvertersTable,
    ConverterEntry,
    $$ConvertersTableFilterComposer,
    $$ConvertersTableOrderingComposer,
    $$ConvertersTableAnnotationComposer,
    $$ConvertersTableCreateCompanionBuilder,
    $$ConvertersTableUpdateCompanionBuilder,
    (
      ConverterEntry,
      BaseReferences<_$AppDatabase, $ConvertersTable, ConverterEntry>
    ),
    ConverterEntry,
    PrefetchHooks Function()> {
  $$ConvertersTableTableManager(_$AppDatabase db, $ConvertersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConvertersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConvertersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConvertersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> term = const Value.absent(),
            Value<String> fromUnit = const Value.absent(),
            Value<String> toBaseUnit = const Value.absent(),
            Value<double> conversionFactor = const Value.absent(),
            Value<bool> isApproximate = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<String?> userId = const Value.absent(),
            Value<String?> householdId = const Value.absent(),
            Value<int?> createdAt = const Value.absent(),
            Value<int?> updatedAt = const Value.absent(),
            Value<int?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ConvertersCompanion(
            id: id,
            term: term,
            fromUnit: fromUnit,
            toBaseUnit: toBaseUnit,
            conversionFactor: conversionFactor,
            isApproximate: isApproximate,
            notes: notes,
            userId: userId,
            householdId: householdId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            Value<String> id = const Value.absent(),
            required String term,
            required String fromUnit,
            required String toBaseUnit,
            required double conversionFactor,
            Value<bool> isApproximate = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<String?> userId = const Value.absent(),
            Value<String?> householdId = const Value.absent(),
            Value<int?> createdAt = const Value.absent(),
            Value<int?> updatedAt = const Value.absent(),
            Value<int?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ConvertersCompanion.insert(
            id: id,
            term: term,
            fromUnit: fromUnit,
            toBaseUnit: toBaseUnit,
            conversionFactor: conversionFactor,
            isApproximate: isApproximate,
            notes: notes,
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

typedef $$ConvertersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ConvertersTable,
    ConverterEntry,
    $$ConvertersTableFilterComposer,
    $$ConvertersTableOrderingComposer,
    $$ConvertersTableAnnotationComposer,
    $$ConvertersTableCreateCompanionBuilder,
    $$ConvertersTableUpdateCompanionBuilder,
    (
      ConverterEntry,
      BaseReferences<_$AppDatabase, $ConvertersTable, ConverterEntry>
    ),
    ConverterEntry,
    PrefetchHooks Function()>;
typedef $$MealPlansTableCreateCompanionBuilder = MealPlansCompanion Function({
  Value<String> id,
  required String date,
  Value<String?> userId,
  Value<String?> householdId,
  Value<List<MealPlanItem>?> items,
  Value<int?> createdAt,
  Value<int?> updatedAt,
  Value<int?> deletedAt,
  Value<int> rowid,
});
typedef $$MealPlansTableUpdateCompanionBuilder = MealPlansCompanion Function({
  Value<String> id,
  Value<String> date,
  Value<String?> userId,
  Value<String?> householdId,
  Value<List<MealPlanItem>?> items,
  Value<int?> createdAt,
  Value<int?> updatedAt,
  Value<int?> deletedAt,
  Value<int> rowid,
});

class $$MealPlansTableFilterComposer
    extends Composer<_$AppDatabase, $MealPlansTable> {
  $$MealPlansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<List<MealPlanItem>?, List<MealPlanItem>,
          String>
      get items => $composableBuilder(
          column: $table.items,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));
}

class $$MealPlansTableOrderingComposer
    extends Composer<_$AppDatabase, $MealPlansTable> {
  $$MealPlansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get items => $composableBuilder(
      column: $table.items, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));
}

class $$MealPlansTableAnnotationComposer
    extends Composer<_$AppDatabase, $MealPlansTable> {
  $$MealPlansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<MealPlanItem>?, String> get items =>
      $composableBuilder(column: $table.items, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$MealPlansTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MealPlansTable,
    MealPlanEntry,
    $$MealPlansTableFilterComposer,
    $$MealPlansTableOrderingComposer,
    $$MealPlansTableAnnotationComposer,
    $$MealPlansTableCreateCompanionBuilder,
    $$MealPlansTableUpdateCompanionBuilder,
    (
      MealPlanEntry,
      BaseReferences<_$AppDatabase, $MealPlansTable, MealPlanEntry>
    ),
    MealPlanEntry,
    PrefetchHooks Function()> {
  $$MealPlansTableTableManager(_$AppDatabase db, $MealPlansTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MealPlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MealPlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MealPlansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> date = const Value.absent(),
            Value<String?> userId = const Value.absent(),
            Value<String?> householdId = const Value.absent(),
            Value<List<MealPlanItem>?> items = const Value.absent(),
            Value<int?> createdAt = const Value.absent(),
            Value<int?> updatedAt = const Value.absent(),
            Value<int?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MealPlansCompanion(
            id: id,
            date: date,
            userId: userId,
            householdId: householdId,
            items: items,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            Value<String> id = const Value.absent(),
            required String date,
            Value<String?> userId = const Value.absent(),
            Value<String?> householdId = const Value.absent(),
            Value<List<MealPlanItem>?> items = const Value.absent(),
            Value<int?> createdAt = const Value.absent(),
            Value<int?> updatedAt = const Value.absent(),
            Value<int?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MealPlansCompanion.insert(
            id: id,
            date: date,
            userId: userId,
            householdId: householdId,
            items: items,
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

typedef $$MealPlansTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MealPlansTable,
    MealPlanEntry,
    $$MealPlansTableFilterComposer,
    $$MealPlansTableOrderingComposer,
    $$MealPlansTableAnnotationComposer,
    $$MealPlansTableCreateCompanionBuilder,
    $$MealPlansTableUpdateCompanionBuilder,
    (
      MealPlanEntry,
      BaseReferences<_$AppDatabase, $MealPlansTable, MealPlanEntry>
    ),
    MealPlanEntry,
    PrefetchHooks Function()>;
typedef $$UserSubscriptionsTableCreateCompanionBuilder
    = UserSubscriptionsCompanion Function({
  Value<String> id,
  required String userId,
  Value<String?> householdId,
  Value<SubscriptionStatus> status,
  Value<List<String>> entitlements,
  Value<int?> expiresAt,
  Value<int?> trialEndsAt,
  Value<int?> cancelledAt,
  Value<String?> productId,
  Value<String?> store,
  Value<String?> revenuecatCustomerId,
  Value<int?> createdAt,
  Value<int?> updatedAt,
  Value<int> rowid,
});
typedef $$UserSubscriptionsTableUpdateCompanionBuilder
    = UserSubscriptionsCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String?> householdId,
  Value<SubscriptionStatus> status,
  Value<List<String>> entitlements,
  Value<int?> expiresAt,
  Value<int?> trialEndsAt,
  Value<int?> cancelledAt,
  Value<String?> productId,
  Value<String?> store,
  Value<String?> revenuecatCustomerId,
  Value<int?> createdAt,
  Value<int?> updatedAt,
  Value<int> rowid,
});

class $$UserSubscriptionsTableFilterComposer
    extends Composer<_$AppDatabase, $UserSubscriptionsTable> {
  $$UserSubscriptionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<SubscriptionStatus, SubscriptionStatus, String>
      get status => $composableBuilder(
          column: $table.status,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
      get entitlements => $composableBuilder(
          column: $table.entitlements,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get expiresAt => $composableBuilder(
      column: $table.expiresAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get trialEndsAt => $composableBuilder(
      column: $table.trialEndsAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get cancelledAt => $composableBuilder(
      column: $table.cancelledAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get productId => $composableBuilder(
      column: $table.productId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get store => $composableBuilder(
      column: $table.store, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get revenuecatCustomerId => $composableBuilder(
      column: $table.revenuecatCustomerId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$UserSubscriptionsTableOrderingComposer
    extends Composer<_$AppDatabase, $UserSubscriptionsTable> {
  $$UserSubscriptionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entitlements => $composableBuilder(
      column: $table.entitlements,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get expiresAt => $composableBuilder(
      column: $table.expiresAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get trialEndsAt => $composableBuilder(
      column: $table.trialEndsAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get cancelledAt => $composableBuilder(
      column: $table.cancelledAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get productId => $composableBuilder(
      column: $table.productId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get store => $composableBuilder(
      column: $table.store, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get revenuecatCustomerId => $composableBuilder(
      column: $table.revenuecatCustomerId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$UserSubscriptionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserSubscriptionsTable> {
  $$UserSubscriptionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SubscriptionStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get entitlements =>
      $composableBuilder(
          column: $table.entitlements, builder: (column) => column);

  GeneratedColumn<int> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  GeneratedColumn<int> get trialEndsAt => $composableBuilder(
      column: $table.trialEndsAt, builder: (column) => column);

  GeneratedColumn<int> get cancelledAt => $composableBuilder(
      column: $table.cancelledAt, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get store =>
      $composableBuilder(column: $table.store, builder: (column) => column);

  GeneratedColumn<String> get revenuecatCustomerId => $composableBuilder(
      column: $table.revenuecatCustomerId, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$UserSubscriptionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UserSubscriptionsTable,
    UserSubscriptionEntry,
    $$UserSubscriptionsTableFilterComposer,
    $$UserSubscriptionsTableOrderingComposer,
    $$UserSubscriptionsTableAnnotationComposer,
    $$UserSubscriptionsTableCreateCompanionBuilder,
    $$UserSubscriptionsTableUpdateCompanionBuilder,
    (
      UserSubscriptionEntry,
      BaseReferences<_$AppDatabase, $UserSubscriptionsTable,
          UserSubscriptionEntry>
    ),
    UserSubscriptionEntry,
    PrefetchHooks Function()> {
  $$UserSubscriptionsTableTableManager(
      _$AppDatabase db, $UserSubscriptionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserSubscriptionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserSubscriptionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserSubscriptionsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String?> householdId = const Value.absent(),
            Value<SubscriptionStatus> status = const Value.absent(),
            Value<List<String>> entitlements = const Value.absent(),
            Value<int?> expiresAt = const Value.absent(),
            Value<int?> trialEndsAt = const Value.absent(),
            Value<int?> cancelledAt = const Value.absent(),
            Value<String?> productId = const Value.absent(),
            Value<String?> store = const Value.absent(),
            Value<String?> revenuecatCustomerId = const Value.absent(),
            Value<int?> createdAt = const Value.absent(),
            Value<int?> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UserSubscriptionsCompanion(
            id: id,
            userId: userId,
            householdId: householdId,
            status: status,
            entitlements: entitlements,
            expiresAt: expiresAt,
            trialEndsAt: trialEndsAt,
            cancelledAt: cancelledAt,
            productId: productId,
            store: store,
            revenuecatCustomerId: revenuecatCustomerId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            Value<String> id = const Value.absent(),
            required String userId,
            Value<String?> householdId = const Value.absent(),
            Value<SubscriptionStatus> status = const Value.absent(),
            Value<List<String>> entitlements = const Value.absent(),
            Value<int?> expiresAt = const Value.absent(),
            Value<int?> trialEndsAt = const Value.absent(),
            Value<int?> cancelledAt = const Value.absent(),
            Value<String?> productId = const Value.absent(),
            Value<String?> store = const Value.absent(),
            Value<String?> revenuecatCustomerId = const Value.absent(),
            Value<int?> createdAt = const Value.absent(),
            Value<int?> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UserSubscriptionsCompanion.insert(
            id: id,
            userId: userId,
            householdId: householdId,
            status: status,
            entitlements: entitlements,
            expiresAt: expiresAt,
            trialEndsAt: trialEndsAt,
            cancelledAt: cancelledAt,
            productId: productId,
            store: store,
            revenuecatCustomerId: revenuecatCustomerId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$UserSubscriptionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $UserSubscriptionsTable,
    UserSubscriptionEntry,
    $$UserSubscriptionsTableFilterComposer,
    $$UserSubscriptionsTableOrderingComposer,
    $$UserSubscriptionsTableAnnotationComposer,
    $$UserSubscriptionsTableCreateCompanionBuilder,
    $$UserSubscriptionsTableUpdateCompanionBuilder,
    (
      UserSubscriptionEntry,
      BaseReferences<_$AppDatabase, $UserSubscriptionsTable,
          UserSubscriptionEntry>
    ),
    UserSubscriptionEntry,
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
  $$HouseholdInvitesTableTableManager get householdInvites =>
      $$HouseholdInvitesTableTableManager(_db, _db.householdInvites);
  $$UploadQueuesTableTableManager get uploadQueues =>
      $$UploadQueuesTableTableManager(_db, _db.uploadQueues);
  $$IngredientTermQueuesTableTableManager get ingredientTermQueues =>
      $$IngredientTermQueuesTableTableManager(_db, _db.ingredientTermQueues);
  $$PantryItemTermQueuesTableTableManager get pantryItemTermQueues =>
      $$PantryItemTermQueuesTableTableManager(_db, _db.pantryItemTermQueues);
  $$ShoppingListItemTermQueuesTableTableManager
      get shoppingListItemTermQueues =>
          $$ShoppingListItemTermQueuesTableTableManager(
              _db, _db.shoppingListItemTermQueues);
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
  $$ConvertersTableTableManager get converters =>
      $$ConvertersTableTableManager(_db, _db.converters);
  $$MealPlansTableTableManager get mealPlans =>
      $$MealPlansTableTableManager(_db, _db.mealPlans);
  $$UserSubscriptionsTableTableManager get userSubscriptions =>
      $$UserSubscriptionsTableTableManager(_db, _db.userSubscriptions);
}
