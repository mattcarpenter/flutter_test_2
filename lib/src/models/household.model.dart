import 'package:brick_offline_first_with_supabase/brick_offline_first_with_supabase.dart';
import 'package:brick_sqlite/brick_sqlite.dart';
import 'package:brick_supabase/brick_supabase.dart';
import 'package:uuid/uuid.dart';

@ConnectOfflineFirstWithSupabase(
  supabaseConfig: SupabaseSerializable(tableName: 'households'),
  sqliteConfig: SqliteSerializable(),
)
class Household extends OfflineFirstWithSupabaseModel {
  final String name;

  @Supabase(unique: true)
  @Sqlite(index: true, unique: true)
  final String id;

  Household({
    String? id,
    required this.name,
  }) : this.id = id ?? const Uuid().v4();
}
