// GENERATED CODE DO NOT EDIT
part of '../brick.g.dart';

Future<RecipeStepImageMapping> _$RecipeStepImageMappingFromSupabase(
    Map<String, dynamic> data,
    {required SupabaseProvider provider,
    OfflineFirstWithSupabaseRepository? repository}) async {
  return RecipeStepImageMapping(
      step: await RecipeStepAdapter().fromSupabase(data['step'],
          provider: provider, repository: repository),
      image: await RecipeImageAdapter().fromSupabase(data['image'],
          provider: provider, repository: repository),
      id: data['id'] as String?);
}

Future<Map<String, dynamic>> _$RecipeStepImageMappingToSupabase(
    RecipeStepImageMapping instance,
    {required SupabaseProvider provider,
    OfflineFirstWithSupabaseRepository? repository}) async {
  return {
    'step': await RecipeStepAdapter()
        .toSupabase(instance.step, provider: provider, repository: repository),
    'image': await RecipeImageAdapter()
        .toSupabase(instance.image, provider: provider, repository: repository),
    'id': instance.id
  };
}

Future<RecipeStepImageMapping> _$RecipeStepImageMappingFromSqlite(
    Map<String, dynamic> data,
    {required SqliteProvider provider,
    OfflineFirstWithSupabaseRepository? repository}) async {
  return RecipeStepImageMapping(
      step: (await repository!.getAssociation<RecipeStep>(
        Query.where('primaryKey', data['step_RecipeStep_brick_id'] as int,
            limit1: true),
      ))!
          .first,
      image: (await repository.getAssociation<RecipeImage>(
        Query.where('primaryKey', data['image_RecipeImage_brick_id'] as int,
            limit1: true),
      ))!
          .first,
      id: data['id'] as String)
    ..primaryKey = data['_brick_id'] as int;
}

Future<Map<String, dynamic>> _$RecipeStepImageMappingToSqlite(
    RecipeStepImageMapping instance,
    {required SqliteProvider provider,
    OfflineFirstWithSupabaseRepository? repository}) async {
  return {
    'step_RecipeStep_brick_id': instance.step.primaryKey ??
        await provider.upsert<RecipeStep>(instance.step,
            repository: repository),
    'image_RecipeImage_brick_id': instance.image.primaryKey ??
        await provider.upsert<RecipeImage>(instance.image,
            repository: repository),
    'id': instance.id
  };
}

/// Construct a [RecipeStepImageMapping]
class RecipeStepImageMappingAdapter
    extends OfflineFirstWithSupabaseAdapter<RecipeStepImageMapping> {
  RecipeStepImageMappingAdapter();

  @override
  final supabaseTableName = 'recipe_step_image_mappings';
  @override
  final defaultToNull = true;
  @override
  final fieldsToSupabaseColumns = {
    'step': const RuntimeSupabaseColumnDefinition(
      association: true,
      columnName: 'step',
      associationType: RecipeStep,
      associationIsNullable: false,
    ),
    'image': const RuntimeSupabaseColumnDefinition(
      association: true,
      columnName: 'image',
      associationType: RecipeImage,
      associationIsNullable: false,
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
    'step': const RuntimeSqliteColumnDefinition(
      association: true,
      columnName: 'step_RecipeStep_brick_id',
      iterable: false,
      type: RecipeStep,
    ),
    'image': const RuntimeSqliteColumnDefinition(
      association: true,
      columnName: 'image_RecipeImage_brick_id',
      iterable: false,
      type: RecipeImage,
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
      RecipeStepImageMapping instance, DatabaseExecutor executor) async {
    final results = await executor.rawQuery('''
        SELECT * FROM `RecipeStepImageMapping` WHERE id = ? LIMIT 1''',
        [instance.id]);

    // SQFlite returns [{}] when no results are found
    if (results.isEmpty || (results.length == 1 && results.first.isEmpty)) {
      return null;
    }

    return results.first['_brick_id'] as int;
  }

  @override
  final String tableName = 'RecipeStepImageMapping';

  @override
  Future<RecipeStepImageMapping> fromSupabase(Map<String, dynamic> input,
          {required provider,
          covariant OfflineFirstWithSupabaseRepository? repository}) async =>
      await _$RecipeStepImageMappingFromSupabase(input,
          provider: provider, repository: repository);
  @override
  Future<Map<String, dynamic>> toSupabase(RecipeStepImageMapping input,
          {required provider,
          covariant OfflineFirstWithSupabaseRepository? repository}) async =>
      await _$RecipeStepImageMappingToSupabase(input,
          provider: provider, repository: repository);
  @override
  Future<RecipeStepImageMapping> fromSqlite(Map<String, dynamic> input,
          {required provider,
          covariant OfflineFirstWithSupabaseRepository? repository}) async =>
      await _$RecipeStepImageMappingFromSqlite(input,
          provider: provider, repository: repository);
  @override
  Future<Map<String, dynamic>> toSqlite(RecipeStepImageMapping input,
          {required provider,
          covariant OfflineFirstWithSupabaseRepository? repository}) async =>
      await _$RecipeStepImageMappingToSqlite(input,
          provider: provider, repository: repository);
}
