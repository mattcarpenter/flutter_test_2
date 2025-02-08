import 'package:brick_offline_first_with_supabase/brick_offline_first_with_supabase.dart';
import 'package:brick_sqlite/brick_sqlite.dart';
import 'package:brick_supabase/brick_supabase.dart';
import 'package:uuid/uuid.dart';

@ConnectOfflineFirstWithSupabase(
  supabaseConfig: SupabaseSerializable(tableName: 'shared_permissions', onConflict: 'id'),
  sqliteConfig: SqliteSerializable(),
)
class SharedPermission extends OfflineFirstWithSupabaseModel {
  @Supabase(unique: true)
  @Sqlite(index: true, unique: true)
  final String id;

  /// The type of entity being shared (e.g., 'recipe_folder' or 'recipe').
  final String entityType;

  /// The ID of the entity being shared.
  final String entityId;

  /// The owner (sharer) of the entity.
  @Supabase(unique: false)
  @Sqlite(index: true)
  final String ownerId;

  /// The target user who is granted access.
  @Supabase(unique: false)
  @Sqlite(index: true)
  final String targetUserId;

  /// The access level, e.g., 'read-only' or 'read-write'.
  final String accessLevel;

  SharedPermission({
    String? id,
    required this.entityType,
    required this.entityId,
    required this.ownerId,
    required this.targetUserId,
    required this.accessLevel,
  }) : this.id = id ?? const Uuid().v4();
}
