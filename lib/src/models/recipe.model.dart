import 'package:brick_offline_first_with_supabase/brick_offline_first_with_supabase.dart';
import 'package:brick_sqlite/brick_sqlite.dart';
import 'package:brick_supabase/brick_supabase.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase_flutter;

@ConnectOfflineFirstWithSupabase(
  supabaseConfig: SupabaseSerializable(tableName: 'recipes', onConflict: 'id'),
  sqliteConfig: SqliteSerializable(),
)
class Recipe extends OfflineFirstWithSupabaseModel {
  final String title;
  final String content;

  @Supabase(unique: true)
  @Sqlite(index: true, unique: true)
  final String id;

  /// Optional reference to a RecipeFolder.
  @Supabase(unique: false)
  @Sqlite(index: true)
  final String? folderId;

  /// The user who originally created this recipe.
  @Supabase(unique: false)
  @Sqlite(index: true)
  final String? userId;

  /// If non-null, indicates that this recipe belongs to a household.
  @Supabase(unique: false)
  @Sqlite(index: true)
  final String? householdId;

  /// Soft deletion timestamp.
  @Supabase(unique: false)
  @Sqlite(index: true)
  DateTime? deletedAt;

  Recipe({
    String? id,
    required this.title,
    required this.content,
    this.folderId,
    this.userId,
    this.householdId,
    this.deletedAt,
  }) : this.id = id ?? const Uuid().v4();

  factory Recipe.create(String title, String content, {String? folderId, String? householdId}) {
    final userId = supabase_flutter.Supabase.instance.client.auth.currentUser?.id;
    return Recipe(
      title: title,
      content: content,
      folderId: folderId,
      userId: userId,
      householdId: householdId,
      deletedAt: null,
    );
  }

  Recipe copyWith({
    String? title,
    String? content,
    String? folderId,
    String? userId,
    String? householdId,
    DateTime? deletedAt,
  }) {
    return Recipe(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      folderId: folderId ?? this.folderId,
      userId: userId ?? this.userId,
      householdId: householdId ?? this.householdId,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
