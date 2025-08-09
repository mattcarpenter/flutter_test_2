// GENERATED CODE DO NOT EDIT
part of '../brick.g.dart';

Future<RecipeImage> _$RecipeImageFromSupabase(
  Map<String, dynamic> data, {
  required SupabaseProvider provider,
  OfflineFirstWithSupabaseRepository? repository,
}) async {
  return RecipeImage(
    recipe: await RecipeAdapter().fromSupabase(
      data['recipe'],
      provider: provider,
      repository: repository,
    ),
    imageUrl: data['image_url'] as String,
    isCover: data['is_cover'] as bool,
    id: data['id'] as String?,
  );
}

Future<Map<String, dynamic>> _$RecipeImageToSupabase(
  RecipeImage instance, {
  required SupabaseProvider provider,
  OfflineFirstWithSupabaseRepository? repository,
}) async {
  return {
    'recipe': await RecipeAdapter().toSupabase(
      instance.recipe,
      provider: provider,
      repository: repository,
    ),
    'image_url': instance.imageUrl,
    'is_cover': instance.isCover,
    'id': instance.id,
  };
}

Future<RecipeImage> _$RecipeImageFromSqlite(
  Map<String, dynamic> data, {
  required SqliteProvider provider,
  OfflineFirstWithSupabaseRepository? repository,
}) async {
  return RecipeImage(
    recipe: (await repository!.getAssociation<Recipe>(
      Query.where(
        'primaryKey',
        data['recipe_Recipe_brick_id'] as int,
        limit1: true,
      ),
    ))!.first,
    imageUrl: data['image_url'] as String,
    isCover: data['is_cover'] == 1,
    id: data['id'] as String,
  )..primaryKey = data['_brick_id'] as int;
}

Future<Map<String, dynamic>> _$RecipeImageToSqlite(
  RecipeImage instance, {
  required SqliteProvider provider,
  OfflineFirstWithSupabaseRepository? repository,
}) async {
  return {
    'recipe_Recipe_brick_id':
        instance.recipe.primaryKey ??
        await provider.upsert<Recipe>(instance.recipe, repository: repository),
    'image_url': instance.imageUrl,
    'is_cover': instance.isCover ? 1 : 0,
    'id': instance.id,
  };
}

/// Construct a [RecipeImage]
class RecipeImageAdapter extends OfflineFirstWithSupabaseAdapter<RecipeImage> {
  RecipeImageAdapter();

  @override
  final supabaseTableName = 'recipe_images';
  @override
  final defaultToNull = true;
  @override
  final fieldsToSupabaseColumns = {
    'recipe': const RuntimeSupabaseColumnDefinition(
      association: true,
      columnName: 'recipe',
      associationType: Recipe,
      associationIsNullable: false,
    ),
    'imageUrl': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'image_url',
    ),
    'isCover': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'is_cover',
    ),
    'id': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'id',
    ),
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
    'recipe': const RuntimeSqliteColumnDefinition(
      association: true,
      columnName: 'recipe_Recipe_brick_id',
      iterable: false,
      type: Recipe,
    ),
    'imageUrl': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'image_url',
      iterable: false,
      type: String,
    ),
    'isCover': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'is_cover',
      iterable: false,
      type: bool,
    ),
    'id': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'id',
      iterable: false,
      type: String,
    ),
  };
  @override
  Future<int?> primaryKeyByUniqueColumns(
    RecipeImage instance,
    DatabaseExecutor executor,
  ) async {
    final results = await executor.rawQuery(
      '''
        SELECT * FROM `RecipeImage` WHERE id = ? LIMIT 1''',
      [instance.id],
    );

    // SQFlite returns [{}] when no results are found
    if (results.isEmpty || (results.length == 1 && results.first.isEmpty)) {
      return null;
    }

    return results.first['_brick_id'] as int;
  }

  @override
  final String tableName = 'RecipeImage';

  @override
  Future<RecipeImage> fromSupabase(
    Map<String, dynamic> input, {
    required provider,
    covariant OfflineFirstWithSupabaseRepository? repository,
  }) async => await _$RecipeImageFromSupabase(
    input,
    provider: provider,
    repository: repository,
  );
  @override
  Future<Map<String, dynamic>> toSupabase(
    RecipeImage input, {
    required provider,
    covariant OfflineFirstWithSupabaseRepository? repository,
  }) async => await _$RecipeImageToSupabase(
    input,
    provider: provider,
    repository: repository,
  );
  @override
  Future<RecipeImage> fromSqlite(
    Map<String, dynamic> input, {
    required provider,
    covariant OfflineFirstWithSupabaseRepository? repository,
  }) async => await _$RecipeImageFromSqlite(
    input,
    provider: provider,
    repository: repository,
  );
  @override
  Future<Map<String, dynamic>> toSqlite(
    RecipeImage input, {
    required provider,
    covariant OfflineFirstWithSupabaseRepository? repository,
  }) async => await _$RecipeImageToSqlite(
    input,
    provider: provider,
    repository: repository,
  );
}
