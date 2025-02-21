import 'package:brick_offline_first_with_supabase/brick_offline_first_with_supabase.dart';
import 'package:brick_supabase/brick_supabase.dart';
import 'package:brick_sqlite/brick_sqlite.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:recipe_app/src/models/recipe_folder.model.dart';
import 'package:recipe_app/src/models/household.model.dart';
import 'package:recipe_app/src/models/user.model.dart';

@ConnectOfflineFirstWithSupabase(
  supabaseConfig: SupabaseSerializable(tableName: 'recipes', onConflict: 'id'),
  sqliteConfig: SqliteSerializable(),
)
class Recipe extends OfflineFirstWithSupabaseModel {
  @Sqlite()
  @Supabase()
  final String title;

  @Sqlite()
  @Supabase()
  final String? description;

  @Sqlite()
  @Supabase()
  final int rating; // 0 to 5

  @Sqlite()
  @Supabase()
  final String language; // e.g., 'en-US', 'ja-JP'

  @Sqlite()
  @Supabase()
  final int? servings;

  @Sqlite()
  @Supabase()
  final int? prepTime; // in minutes

  @Sqlite()
  @Supabase()
  final int? cookTime;

  @Sqlite()
  @Supabase()
  final int? totalTime;

  @Sqlite()
  @Supabase()
  final String? source;

  @Sqlite()
  @Supabase()
  final String? nutrition;

  @Sqlite()
  @Supabase()
  final String? generalNotes;

  @Supabase(unique: false)
  @Sqlite(index: true)
  final String? userId;

  @Supabase(foreignKey: 'folder_id')
  final RecipeFolder? folder;

  // Association: Optional household.
  @Supabase(foreignKey: 'household_id')
  //@JsonKey(name: 'household_id')
  final Household? household;

  @Sqlite()
  @Supabase()
  final DateTime? createdAt;

  @Sqlite()
  @Supabase()
  final DateTime? updatedAt;

  @Supabase(unique: true)
  @Sqlite(index: true, unique: true)
  final String id;

  Recipe({
    String? id,
    required this.title,
    this.description,
    this.rating = 0,
    required this.language,
    this.servings,
    this.prepTime,
    this.cookTime,
    this.totalTime,
    this.source,
    this.nutrition,
    this.generalNotes,
    required this.userId,
    this.folder,
    this.household,
    this.createdAt,
    this.updatedAt,
  }) : this.id = id ?? const Uuid().v4();
}
