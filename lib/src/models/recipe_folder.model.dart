import 'package:brick_offline_first_with_supabase/brick_offline_first_with_supabase.dart';
import 'package:brick_sqlite/brick_sqlite.dart';
import 'package:brick_supabase/brick_supabase.dart';
import 'package:uuid/uuid.dart';

@ConnectOfflineFirstWithSupabase(
  supabaseConfig: SupabaseSerializable(tableName: 'recipe_folders'),
)
class RecipeFolder extends OfflineFirstWithSupabaseModel {
  final String name;

  // Unique ID using UUID
  @Supabase(unique: true)
  @Sqlite(index: true, unique: true)
  final String id;

  // Optional parent folder ID (for hierarchy support)
  final String? parentId;

  RecipeFolder({
    String? id,
    required this.name,
    this.parentId,
  }) : this.id = id ?? const Uuid().v4();

  /// **Factory constructor to create a new RecipeFolder**
  factory RecipeFolder.create(String name, {String? parentId}) {
    return RecipeFolder(
      id: null, // Will be assigned when synced with Supabase
      name: name,
      parentId: parentId,
    );
  }
}
