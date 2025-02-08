// GENERATED CODE DO NOT EDIT
part of '../brick.g.dart';

Future<Recipe> _$RecipeFromSupabase(Map<String, dynamic> data,
    {required SupabaseProvider provider,
    OfflineFirstWithSupabaseRepository? repository}) async {
  return Recipe(
      title: data['title'] as String,
      content: data['content'] as String,
      id: data['id'] as String?,
      folderId: data['folder_id'] == null ? null : data['folder_id'] as String?,
      userId: data['user_id'] == null ? null : data['user_id'] as String?,
      householdId:
          data['household_id'] == null ? null : data['household_id'] as String?,
      deletedAt: data['deleted_at'] == null
          ? null
          : data['deleted_at'] == null
              ? null
              : DateTime.tryParse(data['deleted_at'] as String));
}

Future<Map<String, dynamic>> _$RecipeToSupabase(Recipe instance,
    {required SupabaseProvider provider,
    OfflineFirstWithSupabaseRepository? repository}) async {
  return {
    'title': instance.title,
    'content': instance.content,
    'id': instance.id,
    'folder_id': instance.folderId,
    'user_id': instance.userId,
    'household_id': instance.householdId,
    'deleted_at': instance.deletedAt?.toIso8601String()
  };
}

Future<Recipe> _$RecipeFromSqlite(Map<String, dynamic> data,
    {required SqliteProvider provider,
    OfflineFirstWithSupabaseRepository? repository}) async {
  return Recipe(
      title: data['title'] as String,
      content: data['content'] as String,
      id: data['id'] as String,
      folderId: data['folder_id'] == null ? null : data['folder_id'] as String?,
      userId: data['user_id'] == null ? null : data['user_id'] as String?,
      householdId:
          data['household_id'] == null ? null : data['household_id'] as String?,
      deletedAt: data['deleted_at'] == null
          ? null
          : data['deleted_at'] == null
              ? null
              : DateTime.tryParse(data['deleted_at'] as String))
    ..primaryKey = data['_brick_id'] as int;
}

Future<Map<String, dynamic>> _$RecipeToSqlite(Recipe instance,
    {required SqliteProvider provider,
    OfflineFirstWithSupabaseRepository? repository}) async {
  return {
    'title': instance.title,
    'content': instance.content,
    'id': instance.id,
    'folder_id': instance.folderId,
    'user_id': instance.userId,
    'household_id': instance.householdId,
    'deleted_at': instance.deletedAt?.toIso8601String()
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
    'content': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'content',
    ),
    'id': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'id',
    ),
    'folderId': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'folder_id',
    ),
    'userId': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'user_id',
    ),
    'householdId': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'household_id',
    ),
    'deletedAt': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'deleted_at',
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
    'content': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'content',
      iterable: false,
      type: String,
    ),
    'id': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'id',
      iterable: false,
      type: String,
    ),
    'folderId': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'folder_id',
      iterable: false,
      type: String,
    ),
    'userId': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'user_id',
      iterable: false,
      type: String,
    ),
    'householdId': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'household_id',
      iterable: false,
      type: String,
    ),
    'deletedAt': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'deleted_at',
      iterable: false,
      type: DateTime,
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
