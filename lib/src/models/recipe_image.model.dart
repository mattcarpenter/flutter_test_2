import 'package:brick_offline_first_with_supabase/brick_offline_first_with_supabase.dart';
import 'package:brick_supabase/brick_supabase.dart';
import 'package:brick_sqlite/brick_sqlite.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:recipe_app/src/models/recipe.model.dart';

@ConnectOfflineFirstWithSupabase(
  supabaseConfig: SupabaseSerializable(tableName: 'recipe_images', onConflict: 'id'),
  sqliteConfig: SqliteSerializable(),
)
class RecipeImage extends OfflineFirstWithSupabaseModel {
  final Recipe recipe;

  @Sqlite()
  @Supabase()
  final String imageUrl;

  @Sqlite()
  @Supabase()
  final bool isCover;

  @Supabase(unique: true)
  @Sqlite(index: true, unique: true)
  final String id;

  RecipeImage({
    String? id,
    required this.recipe,
    required this.imageUrl,
    this.isCover = false,
  }) : this.id = id ?? const Uuid().v4();
}
