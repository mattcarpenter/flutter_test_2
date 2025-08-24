// This file performs setup of the PowerSync database
import 'dart:async';
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

import '../src/managers/upload_queue_manager.dart';
import '../src/repositories/upload_queue_repository.dart';
import '../src/repositories/recipe_repository.dart';

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
  Timer? _proactiveRefreshTimer;
  int _refreshRetryCount = 0;
  static const int _maxRefreshRetries = 3;

  SupabaseConnector() {
    // Start proactive refresh timer
    _startProactiveRefreshTimer();
  }

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

    // Check if token is about to expire (within 5 minutes)
    final expiresAt = session.expiresAt;
    if (expiresAt != null) {
      final expiryTime = DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);
      final now = DateTime.now();
      final timeUntilExpiry = expiryTime.difference(now);
      
      if (timeUntilExpiry.inMinutes < 5) {
        log.info('Token expires in ${timeUntilExpiry.inMinutes} minutes, triggering refresh');
        // Don't await here to avoid blocking
        _triggerTokenRefresh();
      }
    }

    // Use the access token to authenticate against PowerSync
    final token = session.accessToken;

    // userId and expiresAt are for debugging purposes only
    final userId = session.user.id;
    final expiresAtDateTime = expiresAt == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);
    
    log.fine('Providing credentials for user $userId, expires at $expiresAtDateTime');
    
    return PowerSyncCredentials(
        endpoint: AppConfig.powersyncUrl,
        token: token,
        userId: userId,
        expiresAt: expiresAtDateTime);
  }

  @override
  void invalidateCredentials() {
    // Trigger a session refresh if auth fails on PowerSync.
    log.warning('PowerSync auth failed, triggering token refresh');
    _triggerTokenRefresh();
  }

  void _triggerTokenRefresh() {
    if (_refreshFuture != null) {
      log.fine('Token refresh already in progress');
      return;
    }

    _refreshFuture = _refreshWithRetry()
        .then((response) {
          log.info('Token refresh successful');
          _refreshRetryCount = 0;
          _refreshFuture = null;
          // Trigger PowerSync to fetch new credentials
          prefetchCredentials();
        })
        .catchError((error) {
          log.severe('Token refresh failed after retries: $error');
          _refreshFuture = null;
        });
  }

  Future<AuthResponse> _refreshWithRetry() async {
    for (int i = 0; i < _maxRefreshRetries; i++) {
      try {
        // Exponential backoff: 30s, 60s, 120s
        final timeout = Duration(seconds: 30 * (i + 1));
        log.info('Attempting token refresh (attempt ${i + 1}/$_maxRefreshRetries) with ${timeout.inSeconds}s timeout');
        
        final response = await Supabase.instance.client.auth
            .refreshSession()
            .timeout(timeout);
        
        if (response.session != null) {
          return response;
        }
      } catch (e) {
        log.warning('Token refresh attempt ${i + 1} failed: $e');
        if (i < _maxRefreshRetries - 1) {
          // Wait before retry with exponential backoff
          await Future.delayed(Duration(seconds: 2 * (i + 1)));
        }
      }
    }
    throw Exception('Token refresh failed after $_maxRefreshRetries attempts');
  }

  void _startProactiveRefreshTimer() {
    // Cancel any existing timer
    _proactiveRefreshTimer?.cancel();
    
    // Set up timer to refresh token every 45 minutes
    _proactiveRefreshTimer = Timer.periodic(
      const Duration(minutes: 45),
      (timer) async {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          log.info('Proactive token refresh triggered');
          _triggerTokenRefresh();
        }
      },
    );
  }

  void dispose() {
    _proactiveRefreshTimer?.cancel();
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
  print('Opening database at $databasePath');

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
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null && session.expiresAt != null) {
      final expiryTime = DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000);
      log.info('Initial session check - User: $userId, expires at: $expiryTime');
    }
    
    if (userId != null) {
      await _claimOrphanedRecords(userId);
    }
    currentConnector = SupabaseConnector();
    db.connect(connector: currentConnector);
  }

  Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
    final AuthChangeEvent event = data.event;
    final session = data.session;
    
    log.info('Auth state changed: $event');
    if (session != null && session.expiresAt != null) {
      final expiryTime = DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000);
      log.info('Session expires at: $expiryTime');
    }
    
    if (event == AuthChangeEvent.signedIn) {
      // Connect to PowerSync when the user is signed in
      log.info('User signed in, connecting to PowerSync');
      final userId = getUserId();
      if (userId != null) {
        await _claimOrphanedRecords(userId);
      }
      // Dispose old connector if exists
      currentConnector?.dispose();
      currentConnector = SupabaseConnector();
      db.connect(connector: currentConnector!);
    } else if (event == AuthChangeEvent.signedOut) {
      // Sign out - disconnect and clear local data for privacy
      log.info('User signed out, clearing local data');
      currentConnector?.dispose();
      currentConnector = null;
      await db.disconnectAndClear();
    } else if (event == AuthChangeEvent.tokenRefreshed) {
      // Supabase token refreshed - trigger token refresh for PowerSync.
      log.info('Token refreshed by Supabase, updating PowerSync credentials');
      currentConnector?.prefetchCredentials();
    } else if (event == AuthChangeEvent.userUpdated) {
      log.info('User updated event received');
    } else if (event == AuthChangeEvent.passwordRecovery) {
      log.info('Password recovery event received');
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
    
    // Update recipe tags - handle NULL userId
    await (appDb.update(appDb.recipeTags)
      ..where((t) => t.userId.isNull()))
      .write(RecipeTagsCompanion(userId: Value(userId)));
    
    // Update recipe tags - handle empty string userId
    await (appDb.update(appDb.recipeTags)
      ..where((t) => t.userId.equals('')))
      .write(RecipeTagsCompanion(userId: Value(userId)));
    
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
    
    // Populate upload queue for newly claimed recipes with images
    await _populateUploadQueueForClaimedRecipes(userId);
    
    log.info('Successfully claimed orphaned records for user $userId');
  } catch (e) {
    log.severe('Error claiming orphaned records: $e');
    // Don't rethrow - we don't want to block sign-in if this fails
  }
}

/// Populates the upload queue for recipes with images that need uploading.
/// This should be called after claiming orphaned records to ensure images get uploaded.
Future<void> _populateUploadQueueForClaimedRecipes(String userId) async {
  try {
    // Query all recipes belonging to this user that have images
    final recipesWithImages = await (appDb.select(appDb.recipes)
      ..where((r) => r.userId.equals(userId)))
      .get();
    
    // Create upload queue manager and repositories directly
    final uploadQueueRepository = UploadQueueRepository(appDb);
    final recipeRepository = RecipeRepository(appDb);
    final uploadQueueManager = UploadQueueManager(
      repository: uploadQueueRepository,
      db: appDb,
      recipeRepository: recipeRepository,
      supabaseClient: Supabase.instance.client,
    );
    
    // Process each recipe's images
    for (final recipe in recipesWithImages) {
      final images = recipe.images;
      if (images != null && images.isNotEmpty) {
        for (final image in images) {
          // Only queue images that haven't been uploaded yet
          if (image.publicUrl == null) {
            await uploadQueueManager.addToQueue(
              fileName: image.fileName,
              recipeId: recipe.id,
            );
          }
        }
      }
    }
    
    // Process the upload queue immediately
    await uploadQueueManager.processQueue();
    
    log.info('Upload queue populated and processed for user $userId');
  } catch (e) {
    log.warning('Error populating upload queue for claimed recipes: $e');
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
