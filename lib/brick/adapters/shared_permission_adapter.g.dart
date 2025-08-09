// GENERATED CODE DO NOT EDIT
part of '../brick.g.dart';

Future<SharedPermission> _$SharedPermissionFromSupabase(
  Map<String, dynamic> data, {
  required SupabaseProvider provider,
  OfflineFirstWithSupabaseRepository? repository,
}) async {
  return SharedPermission(
    id: data['id'] as String?,
    entityType: data['entity_type'] as String,
    entityId: data['entity_id'] as String,
    ownerId: data['owner_id'] as String,
    targetUserId: data['target_user_id'] as String,
    accessLevel: data['access_level'] as String,
  );
}

Future<Map<String, dynamic>> _$SharedPermissionToSupabase(
  SharedPermission instance, {
  required SupabaseProvider provider,
  OfflineFirstWithSupabaseRepository? repository,
}) async {
  return {
    'id': instance.id,
    'entity_type': instance.entityType,
    'entity_id': instance.entityId,
    'owner_id': instance.ownerId,
    'target_user_id': instance.targetUserId,
    'access_level': instance.accessLevel,
  };
}

Future<SharedPermission> _$SharedPermissionFromSqlite(
  Map<String, dynamic> data, {
  required SqliteProvider provider,
  OfflineFirstWithSupabaseRepository? repository,
}) async {
  return SharedPermission(
    id: data['id'] as String,
    entityType: data['entity_type'] as String,
    entityId: data['entity_id'] as String,
    ownerId: data['owner_id'] as String,
    targetUserId: data['target_user_id'] as String,
    accessLevel: data['access_level'] as String,
  )..primaryKey = data['_brick_id'] as int;
}

Future<Map<String, dynamic>> _$SharedPermissionToSqlite(
  SharedPermission instance, {
  required SqliteProvider provider,
  OfflineFirstWithSupabaseRepository? repository,
}) async {
  return {
    'id': instance.id,
    'entity_type': instance.entityType,
    'entity_id': instance.entityId,
    'owner_id': instance.ownerId,
    'target_user_id': instance.targetUserId,
    'access_level': instance.accessLevel,
  };
}

/// Construct a [SharedPermission]
class SharedPermissionAdapter
    extends OfflineFirstWithSupabaseAdapter<SharedPermission> {
  SharedPermissionAdapter();

  @override
  final supabaseTableName = 'shared_permissions';
  @override
  final defaultToNull = true;
  @override
  final fieldsToSupabaseColumns = {
    'id': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'id',
    ),
    'entityType': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'entity_type',
    ),
    'entityId': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'entity_id',
    ),
    'ownerId': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'owner_id',
    ),
    'targetUserId': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'target_user_id',
    ),
    'accessLevel': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'access_level',
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
    'id': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'id',
      iterable: false,
      type: String,
    ),
    'entityType': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'entity_type',
      iterable: false,
      type: String,
    ),
    'entityId': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'entity_id',
      iterable: false,
      type: String,
    ),
    'ownerId': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'owner_id',
      iterable: false,
      type: String,
    ),
    'targetUserId': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'target_user_id',
      iterable: false,
      type: String,
    ),
    'accessLevel': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'access_level',
      iterable: false,
      type: String,
    ),
  };
  @override
  Future<int?> primaryKeyByUniqueColumns(
    SharedPermission instance,
    DatabaseExecutor executor,
  ) async {
    final results = await executor.rawQuery(
      '''
        SELECT * FROM `SharedPermission` WHERE id = ? LIMIT 1''',
      [instance.id],
    );

    // SQFlite returns [{}] when no results are found
    if (results.isEmpty || (results.length == 1 && results.first.isEmpty)) {
      return null;
    }

    return results.first['_brick_id'] as int;
  }

  @override
  final String tableName = 'SharedPermission';

  @override
  Future<SharedPermission> fromSupabase(
    Map<String, dynamic> input, {
    required provider,
    covariant OfflineFirstWithSupabaseRepository? repository,
  }) async => await _$SharedPermissionFromSupabase(
    input,
    provider: provider,
    repository: repository,
  );
  @override
  Future<Map<String, dynamic>> toSupabase(
    SharedPermission input, {
    required provider,
    covariant OfflineFirstWithSupabaseRepository? repository,
  }) async => await _$SharedPermissionToSupabase(
    input,
    provider: provider,
    repository: repository,
  );
  @override
  Future<SharedPermission> fromSqlite(
    Map<String, dynamic> input, {
    required provider,
    covariant OfflineFirstWithSupabaseRepository? repository,
  }) async => await _$SharedPermissionFromSqlite(
    input,
    provider: provider,
    repository: repository,
  );
  @override
  Future<Map<String, dynamic>> toSqlite(
    SharedPermission input, {
    required provider,
    covariant OfflineFirstWithSupabaseRepository? repository,
  }) async => await _$SharedPermissionToSqlite(
    input,
    provider: provider,
    repository: repository,
  );
}
