// GENERATED CODE DO NOT EDIT
part of '../brick.g.dart';

Future<RecipeStep> _$RecipeStepFromSupabase(Map<String, dynamic> data,
    {required SupabaseProvider provider,
    OfflineFirstWithSupabaseRepository? repository}) async {
  return RecipeStep(
      recipe: await RecipeAdapter().fromSupabase(data['recipe'],
          provider: provider, repository: repository),
      position: data['position'] as int,
      entryType: data['entry_type'] as String,
      text: data['text'] as String,
      timerDuration: data['timer_duration'] == null
          ? null
          : data['timer_duration'] as int?,
      id: data['id'] as String?);
}

Future<Map<String, dynamic>> _$RecipeStepToSupabase(RecipeStep instance,
    {required SupabaseProvider provider,
    OfflineFirstWithSupabaseRepository? repository}) async {
  return {
    'recipe': await RecipeAdapter().toSupabase(instance.recipe,
        provider: provider, repository: repository),
    'position': instance.position,
    'entry_type': instance.entryType,
    'text': instance.text,
    'timer_duration': instance.timerDuration,
    'id': instance.id
  };
}

Future<RecipeStep> _$RecipeStepFromSqlite(Map<String, dynamic> data,
    {required SqliteProvider provider,
    OfflineFirstWithSupabaseRepository? repository}) async {
  return RecipeStep(
      recipe: (await repository!.getAssociation<Recipe>(
        Query.where('primaryKey', data['recipe_Recipe_brick_id'] as int,
            limit1: true),
      ))!
          .first,
      position: data['position'] as int,
      entryType: data['entry_type'] as String,
      text: data['text'] as String,
      timerDuration: data['timer_duration'] == null
          ? null
          : data['timer_duration'] as int?,
      id: data['id'] as String)
    ..primaryKey = data['_brick_id'] as int;
}

Future<Map<String, dynamic>> _$RecipeStepToSqlite(RecipeStep instance,
    {required SqliteProvider provider,
    OfflineFirstWithSupabaseRepository? repository}) async {
  return {
    'recipe_Recipe_brick_id': instance.recipe.primaryKey ??
        await provider.upsert<Recipe>(instance.recipe, repository: repository),
    'position': instance.position,
    'entry_type': instance.entryType,
    'text': instance.text,
    'timer_duration': instance.timerDuration,
    'id': instance.id
  };
}

/// Construct a [RecipeStep]
class RecipeStepAdapter extends OfflineFirstWithSupabaseAdapter<RecipeStep> {
  RecipeStepAdapter();

  @override
  final supabaseTableName = 'recipe_steps';
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
    'position': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'position',
    ),
    'entryType': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'entry_type',
    ),
    'text': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'text',
    ),
    'timerDuration': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'timer_duration',
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
    'recipe': const RuntimeSqliteColumnDefinition(
      association: true,
      columnName: 'recipe_Recipe_brick_id',
      iterable: false,
      type: Recipe,
    ),
    'position': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'position',
      iterable: false,
      type: int,
    ),
    'entryType': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'entry_type',
      iterable: false,
      type: String,
    ),
    'text': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'text',
      iterable: false,
      type: String,
    ),
    'timerDuration': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'timer_duration',
      iterable: false,
      type: int,
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
      RecipeStep instance, DatabaseExecutor executor) async {
    final results = await executor.rawQuery('''
        SELECT * FROM `RecipeStep` WHERE id = ? LIMIT 1''', [instance.id]);

    // SQFlite returns [{}] when no results are found
    if (results.isEmpty || (results.length == 1 && results.first.isEmpty)) {
      return null;
    }

    return results.first['_brick_id'] as int;
  }

  @override
  final String tableName = 'RecipeStep';

  @override
  Future<RecipeStep> fromSupabase(Map<String, dynamic> input,
          {required provider,
          covariant OfflineFirstWithSupabaseRepository? repository}) async =>
      await _$RecipeStepFromSupabase(input,
          provider: provider, repository: repository);
  @override
  Future<Map<String, dynamic>> toSupabase(RecipeStep input,
          {required provider,
          covariant OfflineFirstWithSupabaseRepository? repository}) async =>
      await _$RecipeStepToSupabase(input,
          provider: provider, repository: repository);
  @override
  Future<RecipeStep> fromSqlite(Map<String, dynamic> input,
          {required provider,
          covariant OfflineFirstWithSupabaseRepository? repository}) async =>
      await _$RecipeStepFromSqlite(input,
          provider: provider, repository: repository);
  @override
  Future<Map<String, dynamic>> toSqlite(RecipeStep input,
          {required provider,
          covariant OfflineFirstWithSupabaseRepository? repository}) async =>
      await _$RecipeStepToSqlite(input,
          provider: provider, repository: repository);
}
