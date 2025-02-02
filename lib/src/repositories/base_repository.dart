import 'package:brick_offline_first_with_supabase/brick_offline_first_with_supabase.dart';
import 'package:brick_sqlite/brick_sqlite.dart';
import 'package:brick_sqlite/memory_cache_provider.dart';
import 'package:brick_supabase/brick_supabase.dart' hide Supabase;
import 'package:sqflite_common/sqlite_api.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../brick/brick.g.dart';
import '../../brick/db/schema.g.dart';

class BaseRepository extends OfflineFirstWithSupabaseRepository {
  static BaseRepository? _instance;

  BaseRepository._({
    required super.supabaseProvider,
    required super.sqliteProvider,
    required super.migrations,
    required super.offlineRequestQueue,
    super.memoryCacheProvider,
  });

  factory BaseRepository() => _instance!;

  static Future<void> configure(DatabaseFactory databaseFactory) async {
    final (client, queue) = OfflineFirstWithSupabaseRepository.clientQueue(
      databaseFactory: databaseFactory,
    );

    await Supabase.initialize(
      url: 'https://ekodhfnrvdovejiblnwe.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVrb2RoZm5ydmRvdmVqaWJsbndlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzgyMjQ1ODcsImV4cCI6MjA1MzgwMDU4N30.ZlLSvOd4fgmGCmUqxwsFwA7ceSH80slwtf17Zq2fas0',
      httpClient: client,
      debug:true
    );

    final provider = SupabaseProvider(
      Supabase.instance.client,
      modelDictionary: supabaseModelDictionary,
    );

    _instance = BaseRepository._(
      supabaseProvider: provider,
      sqliteProvider: SqliteProvider(
        'app_database.sqlite',
        databaseFactory: databaseFactory,
        modelDictionary: sqliteModelDictionary,
      ),
      migrations: migrations,
      memoryCacheProvider: MemoryCacheProvider(),
      offlineRequestQueue: queue,
    );
  }

  // Generic method to fetch all records of any type
  Future<List<T>> getAll<T extends OfflineFirstWithSupabaseModel>() async {
    return await get<T>();
  }

  // Generic method to insert or update any model
  Future<void> add<T extends OfflineFirstWithSupabaseModel>(T model) async {
    await upsert(model);
  }
}
