import 'package:brick_offline_first_with_supabase/brick_offline_first_with_supabase.dart';
import 'package:brick_supabase/brick_supabase.dart';
import 'package:brick_sqlite/brick_sqlite.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:recipe_app/src/models/recipe.model.dart';

@ConnectOfflineFirstWithSupabase(
  supabaseConfig: SupabaseSerializable(tableName: 'recipe_steps', onConflict: 'id'),
  sqliteConfig: SqliteSerializable(),
)
class RecipeStep extends OfflineFirstWithSupabaseModel {
  final Recipe recipe;

  @Sqlite()
  @Supabase()
  final int position;

  @Sqlite()
  @Supabase()
  final String entryType; // 'step', 'section', or 'timer'

  @Sqlite()
  @Supabase()
  final String text;

  @Sqlite()
  @Supabase()
  final int? timerDuration; // in seconds (for timer steps)

  @Supabase(unique: true)
  @Sqlite(index: true, unique: true)
  final String id;

  RecipeStep({
    String? id,
    required this.recipe,
    required this.position,
    required this.entryType,
    required this.text,
    this.timerDuration,
  }) : this.id = id ?? const Uuid().v4();
}
