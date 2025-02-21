import 'package:brick_offline_first_with_supabase/brick_offline_first_with_supabase.dart';
import 'package:brick_sqlite/brick_sqlite.dart';
import 'package:brick_supabase/brick_supabase.dart';
import 'package:uuid/uuid.dart';

@ConnectOfflineFirstWithSupabase(
  supabaseConfig: SupabaseSerializable(tableName: 'recipe_ingredients', onConflict: 'id'),
  sqliteConfig: SqliteSerializable(),
)
class RecipeIngredient extends OfflineFirstWithSupabaseModel {
  final String recipeId;
  final int position;
  final String entryType; // 'ingredient' or 'section'
  final String text;
  final String? note;

  // Denormalized quantity fields
  final String? unit1;
  final double? quantity1;
  final String? unit2;
  final double? quantity2;
  final String? totalUnit;      // computed total unit (if applicable)
  final double? totalQuantity;  // computed sum of quantities

  @Supabase(unique: true)
  @Sqlite(index: true, unique: true)
  final String id;

  RecipeIngredient({
    String? id,
    required this.recipeId,
    required this.position,
    required this.entryType,
    required this.text,
    this.note,
    this.unit1,
    this.quantity1,
    this.unit2,
    this.quantity2,
    this.totalUnit,
    this.totalQuantity,
  }) : this.id = id ?? const Uuid().v4();
}
