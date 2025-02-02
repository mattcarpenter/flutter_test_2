import 'package:brick_offline_first_with_supabase/brick_offline_first_with_supabase.dart';
import 'package:brick_sqlite/brick_sqlite.dart';
import 'package:brick_supabase/brick_supabase.dart';
import 'package:uuid/uuid.dart';

@ConnectOfflineFirstWithSupabase(
  supabaseConfig: SupabaseSerializable(tableName: 'recipe_folders'),
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

  RecipeFolder({
    String? id,
    required this.name,
    this.parentId,
    this.userId,
  }) : this.id = id ?? const Uuid().v4();

  /// **Factory method to create a new RecipeFolder**
  factory RecipeFolder.create(String name, {String? parentId}) {
    return RecipeFolder(
      name: name,
      parentId: parentId,
      userId: null, // Will be set by Supabase automatically
    );
  }
}
