import 'package:powersync/powersync.dart';
import 'package:powersync/sqlite3.dart';
import 'package:powersync/sqlite3_common.dart';
import 'package:powersync/sqlite_async.dart';
import 'package:recipe_app/database/fts_helpers.dart';

class CustomOpenFactory extends PowerSyncOpenFactory {
  CustomOpenFactory({required super.path, super.sqliteOptions});

  @override
  CommonDatabase open(SqliteOpenOptions options) {
    final db = super.open(options);

    db.createFunction(
      functionName: 'preprocessFtsText',
      directOnly: false,
      deterministic: true,
      argumentCount: const AllowedArgumentCount(1),
      function: (args) {
        try {
        final input = args[0] as String;
        return preprocessText(input);
        } catch (e) {
          print(e);
          return "";
        }
      },
    );

    return db;
  }
}
