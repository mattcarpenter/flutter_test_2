import 'package:brick_offline_first_with_supabase/brick_offline_first_with_supabase.dart';
import 'package:brick_sqlite/brick_sqlite.dart';
import 'package:brick_supabase/brick_supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase_flutter;
import 'package:uuid/uuid.dart';

@ConnectOfflineFirstWithSupabase(
  supabaseConfig: SupabaseSerializable(tableName: 'recipe_folders', onConflict: 'id'),
  sqliteConfig: SqliteSerializable(),
)
class RecipeFolder extends OfflineFirstWithSupabaseModel {
  final String name;

  @Supabase(unique: true)
  @Sqlite(index: true, unique: true)
  final String id;

  final String? parentId;

  @Supabase(unique: false)
  @Sqlite(index: true)
  final String? userId;

  /// If non-null, indicates that this folder belongs to a household.
  @Supabase(unique: false)
  @Sqlite(index: true)
  final String? householdId;

  /// Soft deletion timestamp.
  @Supabase(unique: false)
  @Sqlite(index: true)
  DateTime? deletedAt;

  RecipeFolder({
    String? id,
    required this.name,
    required this.userId,
    this.parentId,
    this.householdId,
    this.deletedAt,
  }) : this.id = id ?? const Uuid().v4();

  /// Factory method to create a new RecipeFolder.
  factory RecipeFolder.create(String name, {String? parentId, String? householdId}) {
    final userId = supabase_flutter.Supabase.instance.client.auth.currentUser?.id;
    return RecipeFolder(
      name: name,
      parentId: parentId,
      userId: userId,
      householdId: householdId,
      deletedAt: null,
    );
  }

  /// Helper method for updating the model.
  RecipeFolder copyWith({
    String? name,
    String? parentId,
    String? userId,
    String? householdId,
    DateTime? deletedAt,
  }) {
    return RecipeFolder(
      id: id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      userId: userId ?? this.userId,
      householdId: householdId ?? this.householdId,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
