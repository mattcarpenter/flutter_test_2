// This file performs setup of the PowerSync database
import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:powersync/powersync.dart';
import 'package:powersync/sqlite3_open.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:powersync_core/src/open_factory/abstract_powersync_open_factory.dart';

import '../app_config.dart';
import 'custom_open_factory.dart';
import 'database.dart';
import 'fts_setup.dart';
import 'supabase.dart';
import 'schema.dart';

import 'package:path/path.dart' as p;

final log = Logger('powersync-supabase');

/// Postgres Response codes that we cannot recover from by retrying.
final List<RegExp> fatalResponseCodes = [
  // Class 22 — Data Exception
  // Examples include data type mismatch.
  RegExp(r'^22...$'),
  // Class 23 — Integrity Constraint Violation.
  // Examples include NOT NULL, FOREIGN KEY and UNIQUE violations.
  RegExp(r'^23...$'),
  // INSUFFICIENT PRIVILEGE - typically a row-level security violation
  RegExp(r'^42501$'),
];

/// Use Supabase for authentication and data upload.
class SupabaseConnector extends PowerSyncBackendConnector {
  Future<void>? _refreshFuture;

  SupabaseConnector();

  /// Get a Supabase token to authenticate against the PowerSync instance.
  @override
  Future<PowerSyncCredentials?> fetchCredentials() async {
    // Wait for pending session refresh if any
    await _refreshFuture;

    // Use Supabase token for PowerSync
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      // Not logged in
      return null;
    }

    // Use the access token to authenticate against PowerSync
    final token = session.accessToken;

    // userId and expiresAt are for debugging purposes only
    final userId = session.user.id;
    final expiresAt = session.expiresAt == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000);
    return PowerSyncCredentials(
        endpoint: AppConfig.powersyncUrl,
        token: token,
        userId: userId,
        expiresAt: expiresAt);
  }

  @override
  void invalidateCredentials() {
    // Trigger a session refresh if auth fails on PowerSync.
    // Generally, sessions should be refreshed automatically by Supabase.
    // However, in some cases it can be a while before the session refresh is
    // retried. We attempt to trigger the refresh as soon as we get an auth
    // failure on PowerSync.
    //
    // This could happen if the device was offline for a while and the session
    // expired, and nothing else attempt to use the session it in the meantime.
    //
    // Timeout the refresh call to avoid waiting for long retries,
    // and ignore any errors. Errors will surface as expired tokens.
    _refreshFuture = Supabase.instance.client.auth
        .refreshSession()
        .timeout(const Duration(seconds: 5))
        .then((response) => null, onError: (error) => null);
  }

  // Upload pending changes to Supabase.
  @override
  Future<void> uploadData(PowerSyncDatabase database) async {
    // This function is called whenever there is data to upload, whether the
    // device is online or offline.
    // If this call throws an error, it is retried periodically.
    final transaction = await database.getNextCrudTransaction();
    if (transaction == null) {
      return;
    }

    final rest = Supabase.instance.client.rest;
    CrudEntry? lastOp;
    try {
      // Note: If transactional consistency is important, use database functions
      // or edge functions to process the entire transaction in a single call.
      for (var op in transaction.crud) {
        lastOp = op;

        final table = rest.from(op.table);
        if (op.op == UpdateType.put) {
          var data = Map<String, dynamic>.of(op.opData!);
          data['id'] = op.id;
          
          // Fallback: ensure userId is set for tables that require it
          if ((data['user_id'] == null || data['user_id'] == '') && _needsUserId(op.table)) {
            final userId = getUserId();
            if (userId != null) {
              data['user_id'] = userId;
              log.warning('Added missing userId to ${op.table} record ${op.id}');
            }
          }
          
          await table.upsert(data);
        } else if (op.op == UpdateType.patch) {
          await table.update(op.opData!).eq('id', op.id);
        } else if (op.op == UpdateType.delete) {
          await table.delete().eq('id', op.id);
        }
      }

      // All operations successful.
      await transaction.complete();
    } on PostgrestException catch (e) {
      if (e.code != null &&
          fatalResponseCodes.any((re) => re.hasMatch(e.code!))) {
        /// Instead of blocking the queue with these errors,
        /// discard the (rest of the) transaction.
        ///
        /// Note that these errors typically indicate a bug in the application.
        /// If protecting against data loss is important, save the failing records
        /// elsewhere instead of discarding, and/or notify the user.
        log.severe('Data upload error - discarding $lastOp', e);
        await transaction.complete();
      } else {
        // Error may be retryable - e.g. network error or temporary server error.
        // Throwing an error here causes this call to be retried after a delay.
        rethrow;
      }
    }
  }
}

/// Global reference to the database
late final PowerSyncDatabase db;
late final AppDatabase appDb;

bool isLoggedIn() {
  return Supabase.instance.client.auth.currentSession?.accessToken != null;
}

/// id of the user currently logged in
String? getUserId() {
  return Supabase.instance.client.auth.currentSession?.user.id;
}

Future<String> getDatabasePath({ bool isTest = false}) async {
  const dbFilename = 'powersync-demo.db';
  // getApplicationSupportDirectory is not supported on Web
  if (kIsWeb) {
    return dbFilename;
  }

  if (isTest) {
    return p.join(Directory.current.path, 'lib', 'database', 'test.db');
  }

  final dir = await getApplicationSupportDirectory();
  return join(dir.path, dbFilename);
}

Future<void> openDatabase({bool isTest = false}) async {

  final databasePath = await getDatabasePath(isTest: isTest);
  print('Opening test database at $databasePath');

  PowerSyncDatabase db;

  if (isTest) {
    db = PowerSyncDatabase.withFactory(CustomOpenFactoryForTest(path: databasePath), schema: schema, logger: attachedLogger);
  } else {
    db = PowerSyncDatabase.withFactory(CustomOpenFactory(path: databasePath), schema: schema, logger: attachedLogger);
  }

  // Open the local database
  //db = PowerSyncDatabase(
  //    schema: schema, path: await getDatabasePath(), logger: attachedLogger);

  await db.initialize();
  // Initialize the Drift database
  appDb = AppDatabase(db);

  await loadSupabase();

  SupabaseConnector? currentConnector;

  if (isLoggedIn()) {
    // If the user is already logged in, connect immediately.
    // Otherwise, connect once logged in.
    final userId = getUserId();
    if (userId != null) {
      await _claimOrphanedRecords(userId);
    }
    currentConnector = SupabaseConnector();
    db.connect(connector: currentConnector);
  }

  Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
    final AuthChangeEvent event = data.event;
    if (event == AuthChangeEvent.signedIn) {
      // Connect to PowerSync when the user is signed in
      final userId = getUserId();
      if (userId != null) {
        await _claimOrphanedRecords(userId);
      }
      currentConnector = SupabaseConnector();
      db.connect(connector: currentConnector!);
    } else if (event == AuthChangeEvent.signedOut) {
      // Implicit sign out - disconnect, but don't delete data
      currentConnector = null;
      if (isTest) {
        await db.disconnectAndClear();
      } else {
        await db.disconnect();
      }
    } else if (event == AuthChangeEvent.tokenRefreshed) {
      // Supabase token refreshed - trigger token refresh for PowerSync.
      currentConnector?.prefetchCredentials();
    }
  });

  // Demo using SQLite Full-Text Search with PowerSync.
  // See https://docs.powersync.com/usage-examples/full-text-search for more details
  await configureFts(db);
}

/// Claims orphaned records (those with NULL or empty string userId) for the specified user.
/// This should be called after sign-in but before connecting to PowerSync.
Future<void> _claimOrphanedRecords(String userId) async {
  try {
    // Update recipes - handle NULL userId
    await (appDb.update(appDb.recipes)
      ..where((r) => r.userId.isNull()))
      .write(RecipesCompanion(userId: Value(userId)));
    
    // Update recipes - handle empty string userId
    await (appDb.update(appDb.recipes)
      ..where((r) => r.userId.equals('')))
      .write(RecipesCompanion(userId: Value(userId)));
    
    // Update meal plans - handle NULL userId
    await (appDb.update(appDb.mealPlans)
      ..where((m) => m.userId.isNull()))
      .write(MealPlansCompanion(userId: Value(userId)));
    
    // Update meal plans - handle empty string userId
    await (appDb.update(appDb.mealPlans)
      ..where((m) => m.userId.equals('')))
      .write(MealPlansCompanion(userId: Value(userId)));
    
    // Update shopping lists - handle NULL userId
    await (appDb.update(appDb.shoppingLists)
      ..where((s) => s.userId.isNull()))
      .write(ShoppingListsCompanion(userId: Value(userId)));
    
    // Update shopping lists - handle empty string userId
    await (appDb.update(appDb.shoppingLists)
      ..where((s) => s.userId.equals('')))
      .write(ShoppingListsCompanion(userId: Value(userId)));
    
    // Update shopping list items - handle NULL userId
    await (appDb.update(appDb.shoppingListItems)
      ..where((s) => s.userId.isNull()))
      .write(ShoppingListItemsCompanion(userId: Value(userId)));
    
    // Update shopping list items - handle empty string userId
    await (appDb.update(appDb.shoppingListItems)
      ..where((s) => s.userId.equals('')))
      .write(ShoppingListItemsCompanion(userId: Value(userId)));
    
    // Update pantry items - handle NULL userId
    await (appDb.update(appDb.pantryItems)
      ..where((p) => p.userId.isNull()))
      .write(PantryItemsCompanion(userId: Value(userId)));
    
    // Update pantry items - handle empty string userId
    await (appDb.update(appDb.pantryItems)
      ..where((p) => p.userId.equals('')))
      .write(PantryItemsCompanion(userId: Value(userId)));
    
    // Update recipe folders - handle NULL userId
    await (appDb.update(appDb.recipeFolders)
      ..where((f) => f.userId.isNull()))
      .write(RecipeFoldersCompanion(userId: Value(userId)));
    
    // Update recipe folders - handle empty string userId
    await (appDb.update(appDb.recipeFolders)
      ..where((f) => f.userId.equals('')))
      .write(RecipeFoldersCompanion(userId: Value(userId)));
    
    // Update cooks - handle NULL userId
    await (appDb.update(appDb.cooks)
      ..where((c) => c.userId.isNull()))
      .write(CooksCompanion(userId: Value(userId)));
    
    // Update cooks - handle empty string userId
    await (appDb.update(appDb.cooks)
      ..where((c) => c.userId.equals('')))
      .write(CooksCompanion(userId: Value(userId)));
    
    // Update ingredient term overrides - handle NULL userId
    await (appDb.update(appDb.ingredientTermOverrides)
      ..where((i) => i.userId.isNull()))
      .write(IngredientTermOverridesCompanion(userId: Value(userId)));
    
    // Update ingredient term overrides - handle empty string userId
    await (appDb.update(appDb.ingredientTermOverrides)
      ..where((i) => i.userId.equals('')))
      .write(IngredientTermOverridesCompanion(userId: Value(userId)));
    
    log.info('Successfully claimed orphaned records for user $userId');
  } catch (e) {
    log.severe('Error claiming orphaned records: $e');
    // Don't rethrow - we don't want to block sign-in if this fails
  }
}

/// Returns true if the given table requires a userId for RLS policies.
bool _needsUserId(String tableName) {
  const tablesRequiringUserId = {
    'recipes',
    'meal_plans',
    'shopping_lists',
    'shopping_list_items',
    'pantry_items',
    'recipe_folders',
    'cooks',
    'ingredient_term_overrides',
    'converters',
  };
  
  return tablesRequiringUserId.contains(tableName);
}
