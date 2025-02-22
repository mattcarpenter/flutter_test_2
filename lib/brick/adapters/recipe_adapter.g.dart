// GENERATED CODE DO NOT EDIT
part of '../brick.g.dart';

Future<Recipe> _$RecipeFromSupabase(Map<String, dynamic> data,
    {required SupabaseProvider provider,
    OfflineFirstWithSupabaseRepository? repository}) async {
  return Recipe(
      title: data['title'] as String,
      description:
          data['description'] == null ? null : data['description'] as String?,
      rating: data['rating'] as int,
      language: data['language'] as String,
      servings: data['servings'] == null ? null : data['servings'] as int?,
      prepTime: data['prep_time'] == null ? null : data['prep_time'] as int?,
      cookTime: data['cook_time'] == null ? null : data['cook_time'] as int?,
      totalTime: data['total_time'] == null ? null : data['total_time'] as int?,
      source: data['source'] == null ? null : data['source'] as String?,
      nutrition:
          data['nutrition'] == null ? null : data['nutrition'] as String?,
      generalNotes: data['general_notes'] == null
          ? null
          : data['general_notes'] as String?,
      userId: data['user_id'] == null ? null : data['user_id'] as String?,
      folder: data['folder'] == null
          ? null
          : await RecipeFolderAdapter().fromSupabase(data['folder'],
              provider: provider, repository: repository),
      household: data['household'] == null
          ? null
          : await HouseholdAdapter().fromSupabase(data['household'],
              provider: provider, repository: repository),
      createdAt: data['created_at'] == null
          ? null
          : data['created_at'] == null
              ? null
              : DateTime.tryParse(data['created_at'] as String),
      updatedAt: data['updated_at'] == null
          ? null
          : data['updated_at'] == null
              ? null
              : DateTime.tryParse(data['updated_at'] as String),
      id: data['id'] as String?);
}

Future<Map<String, dynamic>> _$RecipeToSupabase(Recipe instance,
    {required SupabaseProvider provider,
    OfflineFirstWithSupabaseRepository? repository}) async {
  return {
    'title': instance.title,
    'description': instance.description,
    'rating': instance.rating,
    'language': instance.language,
    'servings': instance.servings,
    'prep_time': instance.prepTime,
    'cook_time': instance.cookTime,
    'total_time': instance.totalTime,
    'source': instance.source,
    'nutrition': instance.nutrition,
    'general_notes': instance.generalNotes,
    'user_id': instance.userId,
    'folder': instance.folder != null
        ? await RecipeFolderAdapter().toSupabase(instance.folder!,
            provider: provider, repository: repository)
        : null,
    'household': instance.household != null
        ? await HouseholdAdapter().toSupabase(instance.household!,
            provider: provider, repository: repository)
        : null,
    'created_at': instance.createdAt?.toIso8601String(),
    'updated_at': instance.updatedAt?.toIso8601String(),
    'id': instance.id
  };
}

Future<Recipe> _$RecipeFromSqlite(Map<String, dynamic> data,
    {required SqliteProvider provider,
    OfflineFirstWithSupabaseRepository? repository}) async {
  return Recipe(
      title: data['title'] as String,
      description:
          data['description'] == null ? null : data['description'] as String?,
      rating: data['rating'] as int,
      language: data['language'] as String,
      servings: data['servings'] == null ? null : data['servings'] as int?,
      prepTime: data['prep_time'] == null ? null : data['prep_time'] as int?,
      cookTime: data['cook_time'] == null ? null : data['cook_time'] as int?,
      totalTime: data['total_time'] == null ? null : data['total_time'] as int?,
      source: data['source'] == null ? null : data['source'] as String?,
      nutrition:
          data['nutrition'] == null ? null : data['nutrition'] as String?,
      generalNotes: data['general_notes'] == null
          ? null
          : data['general_notes'] as String?,
      userId: data['user_id'] == null ? null : data['user_id'] as String?,
      folder: data['folder_RecipeFolder_brick_id'] == null
          ? null
          : (data['folder_RecipeFolder_brick_id'] > -1
              ? (await repository?.getAssociation<RecipeFolder>(
                  Query.where(
                      'primaryKey', data['folder_RecipeFolder_brick_id'] as int,
                      limit1: true),
                ))
                  ?.first
              : null),
      household: data['household_Household_brick_id'] == null
          ? null
          : (data['household_Household_brick_id'] > -1
              ? (await repository?.getAssociation<Household>(
                  Query.where(
                      'primaryKey', data['household_Household_brick_id'] as int,
                      limit1: true),
                ))
                  ?.first
              : null),
      createdAt: data['created_at'] == null
          ? null
          : data['created_at'] == null
              ? null
              : DateTime.tryParse(data['created_at'] as String),
      updatedAt: data['updated_at'] == null
          ? null
          : data['updated_at'] == null
              ? null
              : DateTime.tryParse(data['updated_at'] as String),
      id: data['id'] as String)
    ..primaryKey = data['_brick_id'] as int;
}

Future<Map<String, dynamic>> _$RecipeToSqlite(Recipe instance,
    {required SqliteProvider provider,
    OfflineFirstWithSupabaseRepository? repository}) async {
  return {
    'title': instance.title,
    'description': instance.description,
    'rating': instance.rating,
    'language': instance.language,
    'servings': instance.servings,
    'prep_time': instance.prepTime,
    'cook_time': instance.cookTime,
    'total_time': instance.totalTime,
    'source': instance.source,
    'nutrition': instance.nutrition,
    'general_notes': instance.generalNotes,
    'user_id': instance.userId,
    'folder_RecipeFolder_brick_id': instance.folder != null
        ? instance.folder!.primaryKey ??
            await provider.upsert<RecipeFolder>(instance.folder!,
                repository: repository)
        : null,
    'household_Household_brick_id': instance.household != null
        ? instance.household!.primaryKey ??
            await provider.upsert<Household>(instance.household!,
                repository: repository)
        : null,
    'created_at': instance.createdAt?.toIso8601String(),
    'updated_at': instance.updatedAt?.toIso8601String(),
    'id': instance.id
  };
}

/// Construct a [Recipe]
class RecipeAdapter extends OfflineFirstWithSupabaseAdapter<Recipe> {
  RecipeAdapter();

  @override
  final supabaseTableName = 'recipes';
  @override
  final defaultToNull = true;
  @override
  final fieldsToSupabaseColumns = {
    'title': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'title',
    ),
    'description': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'description',
    ),
    'rating': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'rating',
    ),
    'language': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'language',
    ),
    'servings': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'servings',
    ),
    'prepTime': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'prep_time',
    ),
    'cookTime': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'cook_time',
    ),
    'totalTime': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'total_time',
    ),
    'source': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'source',
    ),
    'nutrition': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'nutrition',
    ),
    'generalNotes': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'general_notes',
    ),
    'userId': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'user_id',
    ),
    'folder': const RuntimeSupabaseColumnDefinition(
      association: true,
      columnName: 'folder',
      associationType: RecipeFolder,
      associationIsNullable: true,
      foreignKey: 'folder_id',
    ),
    'household': const RuntimeSupabaseColumnDefinition(
      association: true,
      columnName: 'household',
      associationType: Household,
      associationIsNullable: true,
      foreignKey: 'household_id',
    ),
    'createdAt': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'created_at',
    ),
    'updatedAt': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'updated_at',
    ),
    'id': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'id',
    )
  };
  @override
  final ignoreDuplicates = false;
  @override
  final onConflict = 'id';
  @override
  final uniqueFields = {'id'};
  @override
  final Map<String, RuntimeSqliteColumnDefinition> fieldsToSqliteColumns = {
    'primaryKey': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: '_brick_id',
      iterable: false,
      type: int,
    ),
    'title': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'title',
      iterable: false,
      type: String,
    ),
    'description': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'description',
      iterable: false,
      type: String,
    ),
    'rating': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'rating',
      iterable: false,
      type: int,
    ),
    'language': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'language',
      iterable: false,
      type: String,
    ),
    'servings': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'servings',
      iterable: false,
      type: int,
    ),
    'prepTime': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'prep_time',
      iterable: false,
      type: int,
    ),
    'cookTime': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'cook_time',
      iterable: false,
      type: int,
    ),
    'totalTime': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'total_time',
      iterable: false,
      type: int,
    ),
    'source': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'source',
      iterable: false,
      type: String,
    ),
    'nutrition': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'nutrition',
      iterable: false,
      type: String,
    ),
    'generalNotes': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'general_notes',
      iterable: false,
      type: String,
    ),
    'userId': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'user_id',
      iterable: false,
      type: String,
    ),
    'folder': const RuntimeSqliteColumnDefinition(
      association: true,
      columnName: 'folder_RecipeFolder_brick_id',
      iterable: false,
      type: RecipeFolder,
    ),
    'household': const RuntimeSqliteColumnDefinition(
      association: true,
      columnName: 'household_Household_brick_id',
      iterable: false,
      type: Household,
    ),
    'createdAt': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'created_at',
      iterable: false,
      type: DateTime,
    ),
    'updatedAt': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'updated_at',
      iterable: false,
      type: DateTime,
    ),
    'id': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'id',
      iterable: false,
      type: String,
    )
  };
  @override
  Future<int?> primaryKeyByUniqueColumns(
      Recipe instance, DatabaseExecutor executor) async {
    final results = await executor.rawQuery('''
        SELECT * FROM `Recipe` WHERE id = ? LIMIT 1''', [instance.id]);

    // SQFlite returns [{}] when no results are found
    if (results.isEmpty || (results.length == 1 && results.first.isEmpty)) {
      return null;
    }

    return results.first['_brick_id'] as int;
  }

  @override
  final String tableName = 'Recipe';

  @override
  Future<Recipe> fromSupabase(Map<String, dynamic> input,
          {required provider,
          covariant OfflineFirstWithSupabaseRepository? repository}) async =>
      await _$RecipeFromSupabase(input,
          provider: provider, repository: repository);
  @override
  Future<Map<String, dynamic>> toSupabase(Recipe input,
          {required provider,
          covariant OfflineFirstWithSupabaseRepository? repository}) async =>
      await _$RecipeToSupabase(input,
          provider: provider, repository: repository);
  @override
  Future<Recipe> fromSqlite(Map<String, dynamic> input,
          {required provider,
          covariant OfflineFirstWithSupabaseRepository? repository}) async =>
      await _$RecipeFromSqlite(input,
          provider: provider, repository: repository);
  @override
  Future<Map<String, dynamic>> toSqlite(Recipe input,
          {required provider,
          covariant OfflineFirstWithSupabaseRepository? repository}) async =>
      await _$RecipeToSqlite(input, provider: provider, repository: repository);
}
