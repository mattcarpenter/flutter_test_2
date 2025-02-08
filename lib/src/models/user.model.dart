import 'package:brick_offline_first_with_supabase/brick_offline_first_with_supabase.dart';
import 'package:brick_sqlite/brick_sqlite.dart';
import 'package:brick_supabase/brick_supabase.dart';
import 'package:uuid/uuid.dart';
import 'package:recipe_app/src/models/household.model.dart';

@ConnectOfflineFirstWithSupabase(
  supabaseConfig: SupabaseSerializable(tableName: 'users'),
  sqliteConfig: SqliteSerializable(),
)
class User extends OfflineFirstWithSupabaseModel {
  final String name;
  final String email;

  @Supabase(unique: true)
  @Sqlite(index: true, unique: true)
  final String id;

  @Supabase(foreignKey: 'household_id') // Explicitly define FK in Supabase
  final Household? household;

  User({
    String? id,
    required this.name,
    required this.email,
    this.household,
  }) : this.id = id ?? const Uuid().v4();
}
