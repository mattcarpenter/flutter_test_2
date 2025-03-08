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
      'rating', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
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
  static const VerificationMeta _ingredientsMeta =
      const VerificationMeta('ingredients');
  @override
  late final GeneratedColumn<String> ingredients = GeneratedColumn<String>(
      'ingredients', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _stepsMeta = const VerificationMeta('steps');
  @override
  late final GeneratedColumn<String> steps = GeneratedColumn<String>(
      'steps', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
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
        ingredients,
        steps
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
    } else if (isInserting) {
      context.missing(_ratingMeta);
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
    if (data.containsKey('ingredients')) {
      context.handle(
          _ingredientsMeta,
          ingredients.isAcceptableOrUnknown(
              data['ingredients']!, _ingredientsMeta));
    }
    if (data.containsKey('steps')) {
      context.handle(
          _stepsMeta, steps.isAcceptableOrUnknown(data['steps']!, _stepsMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
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
          .read(DriftSqlType.int, data['${effectivePrefix}rating'])!,
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
          .read(DriftSqlType.string, data['${effectivePrefix}user_id']),
      householdId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}household_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at']),
      ingredients: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ingredients']),
      steps: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}steps']),
    );
  }

  @override
  $RecipesTable createAlias(String alias) {
    return $RecipesTable(attachedDatabase, alias);
  }
}

class RecipeEntry extends DataClass implements Insertable<RecipeEntry> {
  final String id;
  final String title;
  final String? description;
  final int rating;
  final String language;
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
  final String? ingredients;
  final String? steps;
  const RecipeEntry(
      {required this.id,
      required this.title,
      this.description,
      required this.rating,
      required this.language,
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
      this.ingredients,
      this.steps});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['rating'] = Variable<int>(rating);
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
    if (!nullToAbsent || ingredients != null) {
      map['ingredients'] = Variable<String>(ingredients);
    }
    if (!nullToAbsent || steps != null) {
      map['steps'] = Variable<String>(steps);
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
      rating: Value(rating),
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
      ingredients: ingredients == null && nullToAbsent
          ? const Value.absent()
          : Value(ingredients),
      steps:
          steps == null && nullToAbsent ? const Value.absent() : Value(steps),
    );
  }

  factory RecipeEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecipeEntry(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      rating: serializer.fromJson<int>(json['rating']),
      language: serializer.fromJson<String>(json['language']),
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
      ingredients: serializer.fromJson<String?>(json['ingredients']),
      steps: serializer.fromJson<String?>(json['steps']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'rating': serializer.toJson<int>(rating),
      'language': serializer.toJson<String>(language),
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
      'ingredients': serializer.toJson<String?>(ingredients),
      'steps': serializer.toJson<String?>(steps),
    };
  }

  RecipeEntry copyWith(
          {String? id,
          String? title,
          Value<String?> description = const Value.absent(),
          int? rating,
          String? language,
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
          Value<String?> ingredients = const Value.absent(),
          Value<String?> steps = const Value.absent()}) =>
      RecipeEntry(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description.present ? description.value : this.description,
        rating: rating ?? this.rating,
        language: language ?? this.language,
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
        ingredients: ingredients.present ? ingredients.value : this.ingredients,
        steps: steps.present ? steps.value : this.steps,
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
      ingredients:
          data.ingredients.present ? data.ingredients.value : this.ingredients,
      steps: data.steps.present ? data.steps.value : this.steps,
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
          ..write('ingredients: $ingredients, ')
          ..write('steps: $steps')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
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
      ingredients,
      steps);
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
          other.ingredients == this.ingredients &&
          other.steps == this.steps);
}

class RecipesCompanion extends UpdateCompanion<RecipeEntry> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> description;
  final Value<int> rating;
  final Value<String> language;
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
  final Value<String?> ingredients;
  final Value<String?> steps;
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
    this.ingredients = const Value.absent(),
    this.steps = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecipesCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.description = const Value.absent(),
    required int rating,
    required String language,
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
    this.ingredients = const Value.absent(),
    this.steps = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : title = Value(title),
        rating = Value(rating),
        language = Value(language);
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
    Expression<String>? ingredients,
    Expression<String>? steps,
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
      if (ingredients != null) 'ingredients': ingredients,
      if (steps != null) 'steps': steps,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecipesCompanion copyWith(
      {Value<String>? id,
      Value<String>? title,
      Value<String?>? description,
      Value<int>? rating,
      Value<String>? language,
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
      Value<String?>? ingredients,
      Value<String?>? steps,
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
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
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
    if (ingredients.present) {
      map['ingredients'] = Variable<String>(ingredients.value);
    }
    if (steps.present) {
      map['steps'] = Variable<String>(steps.value);
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
          ..write('ingredients: $ingredients, ')
          ..write('steps: $steps, ')
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

class $RecipeFolderAssignmentsTable extends RecipeFolderAssignments
    with TableInfo<$RecipeFolderAssignmentsTable, RecipeFolderAssignmentEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecipeFolderAssignmentsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _folderIdMeta =
      const VerificationMeta('folderId');
  @override
  late final GeneratedColumn<String> folderId = GeneratedColumn<String>(
      'folder_id', aliasedName, false,
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
  @override
  List<GeneratedColumn> get $columns =>
      [id, recipeId, folderId, householdId, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recipe_folder_assignments';
  @override
  VerificationContext validateIntegrity(
      Insertable<RecipeFolderAssignmentEntry> instance,
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
    if (data.containsKey('folder_id')) {
      context.handle(_folderIdMeta,
          folderId.isAcceptableOrUnknown(data['folder_id']!, _folderIdMeta));
    } else if (isInserting) {
      context.missing(_folderIdMeta);
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  RecipeFolderAssignmentEntry map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecipeFolderAssignmentEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      recipeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}recipe_id'])!,
      folderId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}folder_id'])!,
      householdId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}household_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at']),
    );
  }

  @override
  $RecipeFolderAssignmentsTable createAlias(String alias) {
    return $RecipeFolderAssignmentsTable(attachedDatabase, alias);
  }
}

class RecipeFolderAssignmentEntry extends DataClass
    implements Insertable<RecipeFolderAssignmentEntry> {
  final String id;
  final String recipeId;
  final String folderId;
  final String? householdId;
  final int? createdAt;
  const RecipeFolderAssignmentEntry(
      {required this.id,
      required this.recipeId,
      required this.folderId,
      this.householdId,
      this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['recipe_id'] = Variable<String>(recipeId);
    map['folder_id'] = Variable<String>(folderId);
    if (!nullToAbsent || householdId != null) {
      map['household_id'] = Variable<String>(householdId);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<int>(createdAt);
    }
    return map;
  }

  RecipeFolderAssignmentsCompanion toCompanion(bool nullToAbsent) {
    return RecipeFolderAssignmentsCompanion(
      id: Value(id),
      recipeId: Value(recipeId),
      folderId: Value(folderId),
      householdId: householdId == null && nullToAbsent
          ? const Value.absent()
          : Value(householdId),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory RecipeFolderAssignmentEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecipeFolderAssignmentEntry(
      id: serializer.fromJson<String>(json['id']),
      recipeId: serializer.fromJson<String>(json['recipeId']),
      folderId: serializer.fromJson<String>(json['folderId']),
      householdId: serializer.fromJson<String?>(json['householdId']),
      createdAt: serializer.fromJson<int?>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'recipeId': serializer.toJson<String>(recipeId),
      'folderId': serializer.toJson<String>(folderId),
      'householdId': serializer.toJson<String?>(householdId),
      'createdAt': serializer.toJson<int?>(createdAt),
    };
  }

  RecipeFolderAssignmentEntry copyWith(
          {String? id,
          String? recipeId,
          String? folderId,
          Value<String?> householdId = const Value.absent(),
          Value<int?> createdAt = const Value.absent()}) =>
      RecipeFolderAssignmentEntry(
        id: id ?? this.id,
        recipeId: recipeId ?? this.recipeId,
        folderId: folderId ?? this.folderId,
        householdId: householdId.present ? householdId.value : this.householdId,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
      );
  RecipeFolderAssignmentEntry copyWithCompanion(
      RecipeFolderAssignmentsCompanion data) {
    return RecipeFolderAssignmentEntry(
      id: data.id.present ? data.id.value : this.id,
      recipeId: data.recipeId.present ? data.recipeId.value : this.recipeId,
      folderId: data.folderId.present ? data.folderId.value : this.folderId,
      householdId:
          data.householdId.present ? data.householdId.value : this.householdId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecipeFolderAssignmentEntry(')
          ..write('id: $id, ')
          ..write('recipeId: $recipeId, ')
          ..write('folderId: $folderId, ')
          ..write('householdId: $householdId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, recipeId, folderId, householdId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecipeFolderAssignmentEntry &&
          other.id == this.id &&
          other.recipeId == this.recipeId &&
          other.folderId == this.folderId &&
          other.householdId == this.householdId &&
          other.createdAt == this.createdAt);
}

class RecipeFolderAssignmentsCompanion
    extends UpdateCompanion<RecipeFolderAssignmentEntry> {
  final Value<String> id;
  final Value<String> recipeId;
  final Value<String> folderId;
  final Value<String?> householdId;
  final Value<int?> createdAt;
  final Value<int> rowid;
  const RecipeFolderAssignmentsCompanion({
    this.id = const Value.absent(),
    this.recipeId = const Value.absent(),
    this.folderId = const Value.absent(),
    this.householdId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecipeFolderAssignmentsCompanion.insert({
    this.id = const Value.absent(),
    required String recipeId,
    required String folderId,
    this.householdId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : recipeId = Value(recipeId),
        folderId = Value(folderId);
  static Insertable<RecipeFolderAssignmentEntry> custom({
    Expression<String>? id,
    Expression<String>? recipeId,
    Expression<String>? folderId,
    Expression<String>? householdId,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (recipeId != null) 'recipe_id': recipeId,
      if (folderId != null) 'folder_id': folderId,
      if (householdId != null) 'household_id': householdId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecipeFolderAssignmentsCompanion copyWith(
      {Value<String>? id,
      Value<String>? recipeId,
      Value<String>? folderId,
      Value<String?>? householdId,
      Value<int?>? createdAt,
      Value<int>? rowid}) {
    return RecipeFolderAssignmentsCompanion(
      id: id ?? this.id,
      recipeId: recipeId ?? this.recipeId,
      folderId: folderId ?? this.folderId,
      householdId: householdId ?? this.householdId,
      createdAt: createdAt ?? this.createdAt,
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
    if (folderId.present) {
      map['folder_id'] = Variable<String>(folderId.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecipeFolderAssignmentsCompanion(')
          ..write('id: $id, ')
          ..write('recipeId: $recipeId, ')
          ..write('folderId: $folderId, ')
          ..write('householdId: $householdId, ')
          ..write('createdAt: $createdAt, ')
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
  late final $RecipeFolderAssignmentsTable recipeFolderAssignments =
      $RecipeFolderAssignmentsTable(this);
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
        recipeFolderAssignments
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
  required int rating,
  required String language,
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
  Value<String?> ingredients,
  Value<String?> steps,
  Value<int> rowid,
});
typedef $$RecipesTableUpdateCompanionBuilder = RecipesCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<String?> description,
  Value<int> rating,
  Value<String> language,
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
  Value<String?> ingredients,
  Value<String?> steps,
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

  ColumnFilters<String> get ingredients => $composableBuilder(
      column: $table.ingredients, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get steps => $composableBuilder(
      column: $table.steps, builder: (column) => ColumnFilters(column));
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

  ColumnOrderings<String> get ingredients => $composableBuilder(
      column: $table.ingredients, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get steps => $composableBuilder(
      column: $table.steps, builder: (column) => ColumnOrderings(column));
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

  GeneratedColumn<String> get ingredients => $composableBuilder(
      column: $table.ingredients, builder: (column) => column);

  GeneratedColumn<String> get steps =>
      $composableBuilder(column: $table.steps, builder: (column) => column);
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
            Value<int> rating = const Value.absent(),
            Value<String> language = const Value.absent(),
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
            Value<String?> ingredients = const Value.absent(),
            Value<String?> steps = const Value.absent(),
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
            ingredients: ingredients,
            steps: steps,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            Value<String> id = const Value.absent(),
            required String title,
            Value<String?> description = const Value.absent(),
            required int rating,
            required String language,
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
            Value<String?> ingredients = const Value.absent(),
            Value<String?> steps = const Value.absent(),
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
            ingredients: ingredients,
            steps: steps,
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
typedef $$RecipeFolderAssignmentsTableCreateCompanionBuilder
    = RecipeFolderAssignmentsCompanion Function({
  Value<String> id,
  required String recipeId,
  required String folderId,
  Value<String?> householdId,
  Value<int?> createdAt,
  Value<int> rowid,
});
typedef $$RecipeFolderAssignmentsTableUpdateCompanionBuilder
    = RecipeFolderAssignmentsCompanion Function({
  Value<String> id,
  Value<String> recipeId,
  Value<String> folderId,
  Value<String?> householdId,
  Value<int?> createdAt,
  Value<int> rowid,
});

class $$RecipeFolderAssignmentsTableFilterComposer
    extends Composer<_$AppDatabase, $RecipeFolderAssignmentsTable> {
  $$RecipeFolderAssignmentsTableFilterComposer({
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

  ColumnFilters<String> get folderId => $composableBuilder(
      column: $table.folderId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$RecipeFolderAssignmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecipeFolderAssignmentsTable> {
  $$RecipeFolderAssignmentsTableOrderingComposer({
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

  ColumnOrderings<String> get folderId => $composableBuilder(
      column: $table.folderId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$RecipeFolderAssignmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecipeFolderAssignmentsTable> {
  $$RecipeFolderAssignmentsTableAnnotationComposer({
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

  GeneratedColumn<String> get folderId =>
      $composableBuilder(column: $table.folderId, builder: (column) => column);

  GeneratedColumn<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$RecipeFolderAssignmentsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RecipeFolderAssignmentsTable,
    RecipeFolderAssignmentEntry,
    $$RecipeFolderAssignmentsTableFilterComposer,
    $$RecipeFolderAssignmentsTableOrderingComposer,
    $$RecipeFolderAssignmentsTableAnnotationComposer,
    $$RecipeFolderAssignmentsTableCreateCompanionBuilder,
    $$RecipeFolderAssignmentsTableUpdateCompanionBuilder,
    (
      RecipeFolderAssignmentEntry,
      BaseReferences<_$AppDatabase, $RecipeFolderAssignmentsTable,
          RecipeFolderAssignmentEntry>
    ),
    RecipeFolderAssignmentEntry,
    PrefetchHooks Function()> {
  $$RecipeFolderAssignmentsTableTableManager(
      _$AppDatabase db, $RecipeFolderAssignmentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecipeFolderAssignmentsTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$RecipeFolderAssignmentsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecipeFolderAssignmentsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> recipeId = const Value.absent(),
            Value<String> folderId = const Value.absent(),
            Value<String?> householdId = const Value.absent(),
            Value<int?> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RecipeFolderAssignmentsCompanion(
            id: id,
            recipeId: recipeId,
            folderId: folderId,
            householdId: householdId,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            Value<String> id = const Value.absent(),
            required String recipeId,
            required String folderId,
            Value<String?> householdId = const Value.absent(),
            Value<int?> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RecipeFolderAssignmentsCompanion.insert(
            id: id,
            recipeId: recipeId,
            folderId: folderId,
            householdId: householdId,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RecipeFolderAssignmentsTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $RecipeFolderAssignmentsTable,
        RecipeFolderAssignmentEntry,
        $$RecipeFolderAssignmentsTableFilterComposer,
        $$RecipeFolderAssignmentsTableOrderingComposer,
        $$RecipeFolderAssignmentsTableAnnotationComposer,
        $$RecipeFolderAssignmentsTableCreateCompanionBuilder,
        $$RecipeFolderAssignmentsTableUpdateCompanionBuilder,
        (
          RecipeFolderAssignmentEntry,
          BaseReferences<_$AppDatabase, $RecipeFolderAssignmentsTable,
              RecipeFolderAssignmentEntry>
        ),
        RecipeFolderAssignmentEntry,
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
  $$RecipeFolderAssignmentsTableTableManager get recipeFolderAssignments =>
      $$RecipeFolderAssignmentsTableTableManager(
          _db, _db.recipeFolderAssignments);
}
