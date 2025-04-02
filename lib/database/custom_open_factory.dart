import 'package:powersync/powersync.dart';
import 'package:powersync/sqlite3.dart';
import 'package:powersync/sqlite3_common.dart';
import 'package:powersync/sqlite_async.dart';
import 'package:recipe_app/database/fts_helpers.dart';

import '../utils/mecab_wrapper.dart';

class CustomOpenFactory extends PowerSyncOpenFactory {
  final String? dictPath;
  CustomOpenFactory({required super.path, super.sqliteOptions, this.dictPath});

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
        MecabWrapper().syncInitialize(dictPath);
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
