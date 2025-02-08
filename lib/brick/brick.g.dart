// ignore: unused_import, unused_shown_name, unnecessary_import
import 'package:brick_core/query.dart';
// ignore: unused_import, unused_shown_name, unnecessary_import
import 'package:brick_sqlite/db.dart';
// ignore: unused_import, unused_shown_name, unnecessary_import
import 'package:brick_offline_first_with_supabase/brick_offline_first_with_supabase.dart';
// ignore: unused_import, unused_shown_name, unnecessary_import
import 'package:brick_sqlite/brick_sqlite.dart';
// ignore: unused_import, unused_shown_name, unnecessary_import
import 'package:brick_supabase/brick_supabase.dart';
// ignore: unused_import, unused_shown_name, unnecessary_import
import 'package:uuid/uuid.dart';
// ignore: unused_import, unused_shown_name, unnecessary_import
import 'package:recipe_app/src/models/household.model.dart';
// ignore: unused_import, unused_shown_name, unnecessary_import
import 'package:supabase_flutter/supabase_flutter.dart' as supabase_flutter;// GENERATED CODE DO NOT EDIT
// ignore: unused_import
import 'dart:convert';
import 'package:brick_sqlite/brick_sqlite.dart' show SqliteModel, SqliteAdapter, SqliteModelDictionary, RuntimeSqliteColumnDefinition, SqliteProvider;
import 'package:brick_supabase/brick_supabase.dart' show SupabaseProvider, SupabaseModel, SupabaseAdapter, SupabaseModelDictionary;
// ignore: unused_import, unused_shown_name
import 'package:brick_offline_first/brick_offline_first.dart' show RuntimeOfflineFirstDefinition;
// ignore: unused_import, unused_shown_name
import 'package:sqflite_common/sqlite_api.dart' show DatabaseExecutor;

import '../src/models/user.model.dart';
import '../src/models/household.model.dart';
import '../src/models/shared_permission.model.dart';
import '../src/models/recipe_folder.model.dart';
import '../src/models/recipe.model.dart';

part 'adapters/user_adapter.g.dart';
part 'adapters/household_adapter.g.dart';
part 'adapters/shared_permission_adapter.g.dart';
part 'adapters/recipe_folder_adapter.g.dart';
part 'adapters/recipe_adapter.g.dart';

/// Supabase mappings should only be used when initializing a [SupabaseProvider]
final Map<Type, SupabaseAdapter<SupabaseModel>> supabaseMappings = {
  User: UserAdapter(),
  Household: HouseholdAdapter(),
  SharedPermission: SharedPermissionAdapter(),
  RecipeFolder: RecipeFolderAdapter(),
  Recipe: RecipeAdapter()
};
final supabaseModelDictionary = SupabaseModelDictionary(supabaseMappings);

/// Sqlite mappings should only be used when initializing a [SqliteProvider]
final Map<Type, SqliteAdapter<SqliteModel>> sqliteMappings = {
  User: UserAdapter(),
  Household: HouseholdAdapter(),
  SharedPermission: SharedPermissionAdapter(),
  RecipeFolder: RecipeFolderAdapter(),
  Recipe: RecipeAdapter()
};
final sqliteModelDictionary = SqliteModelDictionary(sqliteMappings);
