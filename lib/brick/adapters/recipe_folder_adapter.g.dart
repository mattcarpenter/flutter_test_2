// GENERATED CODE DO NOT EDIT
part of '../brick.g.dart';

Future<RecipeFolder> _$RecipeFolderFromSupabase(Map<String, dynamic> data,
    {required SupabaseProvider provider,
    OfflineFirstWithSupabaseRepository? repository}) async {
  return RecipeFolder(
      name: data['name'] as String,
      id: data['id'] as String?,
      parentId: data['parent_id'] == null ? null : data['parent_id'] as String?,
      userId: data['user_id'] == null ? null : data['user_id'] as String?,
      deletedAt: data['deleted_at'] == null
          ? null
          : data['deleted_at'] == null
              ? null
              : DateTime.tryParse(data['deleted_at'] as String));
}

Future<Map<String, dynamic>> _$RecipeFolderToSupabase(RecipeFolder instance,
    {required SupabaseProvider provider,
    OfflineFirstWithSupabaseRepository? repository}) async {
  return {
    'name': instance.name,
    'id': instance.id,
    'parent_id': instance.parentId,
    'user_id': instance.userId,
    'deleted_at': instance.deletedAt?.toIso8601String()
  };
}

Future<RecipeFolder> _$RecipeFolderFromSqlite(Map<String, dynamic> data,
    {required SqliteProvider provider,
    OfflineFirstWithSupabaseRepository? repository}) async {
  return RecipeFolder(
      name: data['name'] as String,
      id: data['id'] as String,
      parentId: data['parent_id'] == null ? null : data['parent_id'] as String?,
      userId: data['user_id'] == null ? null : data['user_id'] as String?,
      deletedAt: data['deleted_at'] == null
          ? null
          : data['deleted_at'] == null
              ? null
              : DateTime.tryParse(data['deleted_at'] as String))
    ..primaryKey = data['_brick_id'] as int;
}

Future<Map<String, dynamic>> _$RecipeFolderToSqlite(RecipeFolder instance,
    {required SqliteProvider provider,
    OfflineFirstWithSupabaseRepository? repository}) async {
  return {
    'name': instance.name,
    'id': instance.id,
    'parent_id': instance.parentId,
    'user_id': instance.userId,
    'deleted_at': instance.deletedAt?.toIso8601String()
  };
}

/// Construct a [RecipeFolder]
class RecipeFolderAdapter
    extends OfflineFirstWithSupabaseAdapter<RecipeFolder> {
  RecipeFolderAdapter();

  @override
  final supabaseTableName = 'recipe_folders';
  @override
  final defaultToNull = true;
  @override
  final fieldsToSupabaseColumns = {
    'name': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'name',
    ),
    'id': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'id',
    ),
    'parentId': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'parent_id',
    ),
    'userId': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'user_id',
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
    'name': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'name',
      iterable: false,
      type: String,
    ),
    'id': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'id',
      iterable: false,
      type: String,
    ),
    'parentId': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'parent_id',
      iterable: false,
      type: String,
    ),
    'userId': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'user_id',
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
      RecipeFolder instance, DatabaseExecutor executor) async {
    final results = await executor.rawQuery('''
        SELECT * FROM `RecipeFolder` WHERE id = ? LIMIT 1''', [instance.id]);

    // SQFlite returns [{}] when no results are found
    if (results.isEmpty || (results.length == 1 && results.first.isEmpty)) {
      return null;
    }

    return results.first['_brick_id'] as int;
  }

  @override
  final String tableName = 'RecipeFolder';

  @override
  Future<RecipeFolder> fromSupabase(Map<String, dynamic> input,
          {required provider,
          covariant OfflineFirstWithSupabaseRepository? repository}) async =>
      await _$RecipeFolderFromSupabase(input,
          provider: provider, repository: repository);
  @override
  Future<Map<String, dynamic>> toSupabase(RecipeFolder input,
          {required provider,
          covariant OfflineFirstWithSupabaseRepository? repository}) async =>
      await _$RecipeFolderToSupabase(input,
          provider: provider, repository: repository);
  @override
  Future<RecipeFolder> fromSqlite(Map<String, dynamic> input,
          {required provider,
          covariant OfflineFirstWithSupabaseRepository? repository}) async =>
      await _$RecipeFolderFromSqlite(input,
          provider: provider, repository: repository);
  @override
  Future<Map<String, dynamic>> toSqlite(RecipeFolder input,
          {required provider,
          covariant OfflineFirstWithSupabaseRepository? repository}) async =>
      await _$RecipeFolderToSqlite(input,
          provider: provider, repository: repository);
}
