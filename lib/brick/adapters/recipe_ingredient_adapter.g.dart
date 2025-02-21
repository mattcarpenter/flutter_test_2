// GENERATED CODE DO NOT EDIT
part of '../brick.g.dart';

Future<RecipeIngredient> _$RecipeIngredientFromSupabase(
    Map<String, dynamic> data,
    {required SupabaseProvider provider,
    OfflineFirstWithSupabaseRepository? repository}) async {
  return RecipeIngredient(
      recipeId: data['recipe_id'] as String,
      position: data['position'] as int,
      entryType: data['entry_type'] as String,
      text: data['text'] as String,
      note: data['note'] == null ? null : data['note'] as String?,
      unit1: data['unit1'] == null ? null : data['unit1'] as String?,
      quantity1:
          data['quantity1'] == null ? null : data['quantity1'] as double?,
      unit2: data['unit2'] == null ? null : data['unit2'] as String?,
      quantity2:
          data['quantity2'] == null ? null : data['quantity2'] as double?,
      totalUnit:
          data['total_unit'] == null ? null : data['total_unit'] as String?,
      totalQuantity: data['total_quantity'] == null
          ? null
          : data['total_quantity'] as double?,
      id: data['id'] as String?);
}

Future<Map<String, dynamic>> _$RecipeIngredientToSupabase(
    RecipeIngredient instance,
    {required SupabaseProvider provider,
    OfflineFirstWithSupabaseRepository? repository}) async {
  return {
    'recipe_id': instance.recipeId,
    'position': instance.position,
    'entry_type': instance.entryType,
    'text': instance.text,
    'note': instance.note,
    'unit1': instance.unit1,
    'quantity1': instance.quantity1,
    'unit2': instance.unit2,
    'quantity2': instance.quantity2,
    'total_unit': instance.totalUnit,
    'total_quantity': instance.totalQuantity,
    'id': instance.id
  };
}

Future<RecipeIngredient> _$RecipeIngredientFromSqlite(Map<String, dynamic> data,
    {required SqliteProvider provider,
    OfflineFirstWithSupabaseRepository? repository}) async {
  return RecipeIngredient(
      recipeId: data['recipe_id'] as String,
      position: data['position'] as int,
      entryType: data['entry_type'] as String,
      text: data['text'] as String,
      note: data['note'] == null ? null : data['note'] as String?,
      unit1: data['unit1'] == null ? null : data['unit1'] as String?,
      quantity1:
          data['quantity1'] == null ? null : data['quantity1'] as double?,
      unit2: data['unit2'] == null ? null : data['unit2'] as String?,
      quantity2:
          data['quantity2'] == null ? null : data['quantity2'] as double?,
      totalUnit:
          data['total_unit'] == null ? null : data['total_unit'] as String?,
      totalQuantity: data['total_quantity'] == null
          ? null
          : data['total_quantity'] as double?,
      id: data['id'] as String)
    ..primaryKey = data['_brick_id'] as int;
}

Future<Map<String, dynamic>> _$RecipeIngredientToSqlite(
    RecipeIngredient instance,
    {required SqliteProvider provider,
    OfflineFirstWithSupabaseRepository? repository}) async {
  return {
    'recipe_id': instance.recipeId,
    'position': instance.position,
    'entry_type': instance.entryType,
    'text': instance.text,
    'note': instance.note,
    'unit1': instance.unit1,
    'quantity1': instance.quantity1,
    'unit2': instance.unit2,
    'quantity2': instance.quantity2,
    'total_unit': instance.totalUnit,
    'total_quantity': instance.totalQuantity,
    'id': instance.id
  };
}

/// Construct a [RecipeIngredient]
class RecipeIngredientAdapter
    extends OfflineFirstWithSupabaseAdapter<RecipeIngredient> {
  RecipeIngredientAdapter();

  @override
  final supabaseTableName = 'recipe_ingredients';
  @override
  final defaultToNull = true;
  @override
  final fieldsToSupabaseColumns = {
    'recipeId': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'recipe_id',
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
    'note': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'note',
    ),
    'unit1': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'unit1',
    ),
    'quantity1': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'quantity1',
    ),
    'unit2': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'unit2',
    ),
    'quantity2': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'quantity2',
    ),
    'totalUnit': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'total_unit',
    ),
    'totalQuantity': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'total_quantity',
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
    'recipeId': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'recipe_id',
      iterable: false,
      type: String,
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
    'note': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'note',
      iterable: false,
      type: String,
    ),
    'unit1': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'unit1',
      iterable: false,
      type: String,
    ),
    'quantity1': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'quantity1',
      iterable: false,
      type: double,
    ),
    'unit2': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'unit2',
      iterable: false,
      type: String,
    ),
    'quantity2': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'quantity2',
      iterable: false,
      type: double,
    ),
    'totalUnit': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'total_unit',
      iterable: false,
      type: String,
    ),
    'totalQuantity': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'total_quantity',
      iterable: false,
      type: double,
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
      RecipeIngredient instance, DatabaseExecutor executor) async {
    final results = await executor.rawQuery('''
        SELECT * FROM `RecipeIngredient` WHERE id = ? LIMIT 1''',
        [instance.id]);

    // SQFlite returns [{}] when no results are found
    if (results.isEmpty || (results.length == 1 && results.first.isEmpty)) {
      return null;
    }

    return results.first['_brick_id'] as int;
  }

  @override
  final String tableName = 'RecipeIngredient';

  @override
  Future<RecipeIngredient> fromSupabase(Map<String, dynamic> input,
          {required provider,
          covariant OfflineFirstWithSupabaseRepository? repository}) async =>
      await _$RecipeIngredientFromSupabase(input,
          provider: provider, repository: repository);
  @override
  Future<Map<String, dynamic>> toSupabase(RecipeIngredient input,
          {required provider,
          covariant OfflineFirstWithSupabaseRepository? repository}) async =>
      await _$RecipeIngredientToSupabase(input,
          provider: provider, repository: repository);
  @override
  Future<RecipeIngredient> fromSqlite(Map<String, dynamic> input,
          {required provider,
          covariant OfflineFirstWithSupabaseRepository? repository}) async =>
      await _$RecipeIngredientFromSqlite(input,
          provider: provider, repository: repository);
  @override
  Future<Map<String, dynamic>> toSqlite(RecipeIngredient input,
          {required provider,
          covariant OfflineFirstWithSupabaseRepository? repository}) async =>
      await _$RecipeIngredientToSqlite(input,
          provider: provider, repository: repository);
}
