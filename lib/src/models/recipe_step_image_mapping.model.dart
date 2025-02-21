import 'package:brick_offline_first_with_supabase/brick_offline_first_with_supabase.dart';
import 'package:brick_supabase/brick_supabase.dart';
import 'package:brick_sqlite/brick_sqlite.dart';
import 'package:recipe_app/src/models/recipe_image.model.dart';
import 'package:recipe_app/src/models/recipe_step.model.dart';
import 'package:uuid/uuid.dart';

@ConnectOfflineFirstWithSupabase(
  supabaseConfig: SupabaseSerializable(tableName: 'recipe_step_image_mappings', onConflict: 'id'),
  sqliteConfig: SqliteSerializable(),
)
class RecipeStepImageMapping extends OfflineFirstWithSupabaseModel {
  // Association to RecipeStep.
  final RecipeStep step;

  // Association to RecipeImage.
  final RecipeImage image;

  @Supabase(unique: true)
  @Sqlite(index: true, unique: true)
  final String id;

  RecipeStepImageMapping({
    String? id,
    required this.step,
    required this.image,
  }) : this.id = id ?? const Uuid().v4();
}
