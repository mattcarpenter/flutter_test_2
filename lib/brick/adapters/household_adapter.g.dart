// GENERATED CODE DO NOT EDIT
part of '../brick.g.dart';

Future<Household> _$HouseholdFromSupabase(Map<String, dynamic> data,
    {required SupabaseProvider provider,
    OfflineFirstWithSupabaseRepository? repository}) async {
  return Household(name: data['name'] as String, id: data['id'] as String?);
}

Future<Map<String, dynamic>> _$HouseholdToSupabase(Household instance,
    {required SupabaseProvider provider,
    OfflineFirstWithSupabaseRepository? repository}) async {
  return {'name': instance.name, 'id': instance.id};
}

Future<Household> _$HouseholdFromSqlite(Map<String, dynamic> data,
    {required SqliteProvider provider,
    OfflineFirstWithSupabaseRepository? repository}) async {
  return Household(name: data['name'] as String, id: data['id'] as String)
    ..primaryKey = data['_brick_id'] as int;
}

Future<Map<String, dynamic>> _$HouseholdToSqlite(Household instance,
    {required SqliteProvider provider,
    OfflineFirstWithSupabaseRepository? repository}) async {
  return {'name': instance.name, 'id': instance.id};
}

/// Construct a [Household]
class HouseholdAdapter extends OfflineFirstWithSupabaseAdapter<Household> {
  HouseholdAdapter();

  @override
  final supabaseTableName = 'households';
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
    )
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
    'id': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'id',
      iterable: false,
      type: String,
    )
  };
  @override
  Future<int?> primaryKeyByUniqueColumns(
      Household instance, DatabaseExecutor executor) async {
    final results = await executor.rawQuery('''
        SELECT * FROM `Household` WHERE id = ? LIMIT 1''', [instance.id]);

    // SQFlite returns [{}] when no results are found
    if (results.isEmpty || (results.length == 1 && results.first.isEmpty)) {
      return null;
    }

    return results.first['_brick_id'] as int;
  }

  @override
  final String tableName = 'Household';

  @override
  Future<Household> fromSupabase(Map<String, dynamic> input,
          {required provider,
          covariant OfflineFirstWithSupabaseRepository? repository}) async =>
      await _$HouseholdFromSupabase(input,
          provider: provider, repository: repository);
  @override
  Future<Map<String, dynamic>> toSupabase(Household input,
          {required provider,
          covariant OfflineFirstWithSupabaseRepository? repository}) async =>
      await _$HouseholdToSupabase(input,
          provider: provider, repository: repository);
  @override
  Future<Household> fromSqlite(Map<String, dynamic> input,
          {required provider,
          covariant OfflineFirstWithSupabaseRepository? repository}) async =>
      await _$HouseholdFromSqlite(input,
          provider: provider, repository: repository);
  @override
  Future<Map<String, dynamic>> toSqlite(Household input,
          {required provider,
          covariant OfflineFirstWithSupabaseRepository? repository}) async =>
      await _$HouseholdToSqlite(input,
          provider: provider, repository: repository);
}
