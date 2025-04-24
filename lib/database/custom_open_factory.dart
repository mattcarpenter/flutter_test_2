import 'dart:ffi' show DynamicLibrary;

import 'package:powersync/powersync.dart';
import 'package:powersync/sqlite3_common.dart';
import 'package:powersync/sqlite_async.dart';
import 'package:sqlite3/src/ffi/load_library.dart' as load_library_open;

class CustomOpenFactory extends PowerSyncOpenFactory {
  CustomOpenFactory({required super.path, super.sqliteOptions });

  @override
  CommonDatabase open(SqliteOpenOptions options) {
    final db = super.open(options);
    // Define UDF functions here
    return db;
  }
}

class CustomOpenFactoryForTest extends PowerSyncOpenFactory {
  CustomOpenFactoryForTest({required super.path, super.sqliteOptions });

  @override
  CommonDatabase open(SqliteOpenOptions options) {
    load_library_open.open.overrideForAll(() => DynamicLibrary.open('/Users/matt/repos/sqlite-src-3490100/libsqlite3.dylib'));
    final db = super.open(options);
    // Define UDF functions here
    return db;
  }
}

