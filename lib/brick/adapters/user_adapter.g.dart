// GENERATED CODE DO NOT EDIT
part of '../brick.g.dart';

Future<User> _$UserFromSupabase(
  Map<String, dynamic> data, {
  required SupabaseProvider provider,
  OfflineFirstWithSupabaseRepository? repository,
}) async {
  return User(
    name: data['name'] as String,
    email: data['email'] as String,
    id: data['id'] as String?,
    household: data['household'] == null
        ? null
        : await HouseholdAdapter().fromSupabase(
            data['household'],
            provider: provider,
            repository: repository,
          ),
  );
}

Future<Map<String, dynamic>> _$UserToSupabase(
  User instance, {
  required SupabaseProvider provider,
  OfflineFirstWithSupabaseRepository? repository,
}) async {
  return {
    'name': instance.name,
    'email': instance.email,
    'id': instance.id,
    'household': instance.household != null
        ? await HouseholdAdapter().toSupabase(
            instance.household!,
            provider: provider,
            repository: repository,
          )
        : null,
  };
}

Future<User> _$UserFromSqlite(
  Map<String, dynamic> data, {
  required SqliteProvider provider,
  OfflineFirstWithSupabaseRepository? repository,
}) async {
  return User(
    name: data['name'] as String,
    email: data['email'] as String,
    id: data['id'] as String,
    household: data['household_Household_brick_id'] == null
        ? null
        : (data['household_Household_brick_id'] > -1
              ? (await repository?.getAssociation<Household>(
                  Query.where(
                    'primaryKey',
                    data['household_Household_brick_id'] as int,
                    limit1: true,
                  ),
                ))?.first
              : null),
  )..primaryKey = data['_brick_id'] as int;
}

Future<Map<String, dynamic>> _$UserToSqlite(
  User instance, {
  required SqliteProvider provider,
  OfflineFirstWithSupabaseRepository? repository,
}) async {
  return {
    'name': instance.name,
    'email': instance.email,
    'id': instance.id,
    'household_Household_brick_id': instance.household != null
        ? instance.household!.primaryKey ??
              await provider.upsert<Household>(
                instance.household!,
                repository: repository,
              )
        : null,
  };
}

/// Construct a [User]
class UserAdapter extends OfflineFirstWithSupabaseAdapter<User> {
  UserAdapter();

  @override
  final supabaseTableName = 'users';
  @override
  final defaultToNull = true;
  @override
  final fieldsToSupabaseColumns = {
    'name': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'name',
    ),
    'email': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'email',
    ),
    'id': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'id',
    ),
    'household': const RuntimeSupabaseColumnDefinition(
      association: true,
      columnName: 'household',
      associationType: Household,
      associationIsNullable: true,
      foreignKey: 'household_id',
    ),
  };
  @override
  final ignoreDuplicates = false;
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
    'email': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'email',
      iterable: false,
      type: String,
    ),
    'id': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'id',
      iterable: false,
      type: String,
    ),
    'household': const RuntimeSqliteColumnDefinition(
      association: true,
      columnName: 'household_Household_brick_id',
      iterable: false,
      type: Household,
    ),
  };
  @override
  Future<int?> primaryKeyByUniqueColumns(
    User instance,
    DatabaseExecutor executor,
  ) async {
    final results = await executor.rawQuery(
      '''
        SELECT * FROM `User` WHERE id = ? LIMIT 1''',
      [instance.id],
    );

    // SQFlite returns [{}] when no results are found
    if (results.isEmpty || (results.length == 1 && results.first.isEmpty)) {
      return null;
    }

    return results.first['_brick_id'] as int;
  }

  @override
  final String tableName = 'User';

  @override
  Future<User> fromSupabase(
    Map<String, dynamic> input, {
    required provider,
    covariant OfflineFirstWithSupabaseRepository? repository,
  }) async => await _$UserFromSupabase(
    input,
    provider: provider,
    repository: repository,
  );
  @override
  Future<Map<String, dynamic>> toSupabase(
    User input, {
    required provider,
    covariant OfflineFirstWithSupabaseRepository? repository,
  }) async =>
      await _$UserToSupabase(input, provider: provider, repository: repository);
  @override
  Future<User> fromSqlite(
    Map<String, dynamic> input, {
    required provider,
    covariant OfflineFirstWithSupabaseRepository? repository,
  }) async =>
      await _$UserFromSqlite(input, provider: provider, repository: repository);
  @override
  Future<Map<String, dynamic>> toSqlite(
    User input, {
    required provider,
    covariant OfflineFirstWithSupabaseRepository? repository,
  }) async =>
      await _$UserToSqlite(input, provider: provider, repository: repository);
}
