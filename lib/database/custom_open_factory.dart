import 'package:powersync/powersync.dart';
import 'package:powersync/sqlite3_common.dart';
import 'package:powersync/sqlite_async.dart';

class CustomOpenFactory extends PowerSyncOpenFactory {
  CustomOpenFactory({required super.path, super.sqliteOptions });

  @override
  CommonDatabase open(SqliteOpenOptions options) {
    final db = super.open(options);
    // Define UDF functions here
    return db;
  }
}
