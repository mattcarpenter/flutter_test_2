import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:recipe_app/database/database.dart';
import 'package:recipe_app/src/managers/upload_queue_manager.dart';
import 'package:recipe_app/src/repositories/upload_queue_repository.dart';
import 'package:recipe_app/src/repositories/recipe_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fake_async/fake_async.dart';

import 'upload_queue_manager_test.mocks.dart';

@GenerateMocks([
  UploadQueueRepository,
  RecipeRepository,
  AppDatabase,
  SupabaseClient,
  GoTrueClient,
  SupabaseStorageClient,
  StorageFileApi,
])
void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  // Define the connectivity channel.
  const MethodChannel connectivityChannel =
  MethodChannel('dev.fluttercommunity.plus/connectivity');
  binding.defaultBinaryMessenger.setMockMethodCallHandler(
    connectivityChannel,
        (MethodCall call) async {
      if (call.method == 'check') {
        return ['wifi']; // Simulate online connection.
      }
      return null;
    },
  );

  // Declare our mocks and manager.
  late MockUploadQueueRepository mockQueueRepository;
  late MockRecipeRepository mockRecipeRepository;
  late MockAppDatabase mockDb;
  late UploadQueueManager manager;
  late MockSupabaseClient mockSupabaseClient;
  late MockGoTrueClient mockAuth;
  late MockSupabaseStorageClient mockStorageClient;
  late MockStorageFileApi mockBucketApi;

  setUpAll(() async {
    await Supabase.initialize(
      url: 'https://dummy.supabase.co',
      anonKey: 'dummy-anon-key',
    );
  });

  tearDownAll(() {
    binding.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivityChannel, null);
  });

  setUp(() {
    // Initialize repository and database mocks.
    mockQueueRepository = MockUploadQueueRepository();
    mockRecipeRepository = MockRecipeRepository();
    mockDb = MockAppDatabase();

    // Create Supabase chain mocks.
    mockSupabaseClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    when(mockSupabaseClient.auth).thenReturn(mockAuth);
    when(mockAuth.currentUser).thenReturn(
      User(
        id: 'test-user',
        email: 'test@example.com',
        aud: 'authenticated',
        appMetadata: const {"provider": "fake"},
        userMetadata: const {},
        createdAt: DateTime.now().toIso8601String(),
      ),
    );

    mockStorageClient = MockSupabaseStorageClient();
    mockBucketApi = MockStorageFileApi();

    // Stub the storage chain:
    when(mockSupabaseClient.storage).thenReturn(mockStorageClient);
    // Use any() matcher for the bucket name.
    when(mockStorageClient.from(any)).thenReturn(mockBucketApi);
    // Stub upload: simulate a successful upload.
    when(mockBucketApi.upload(any, any))
        .thenAnswer((invocation) async => invocation.positionalArguments[0] as String);
    // Stub getPublicUrl for any argument to return the fake URL.
    when(mockBucketApi.getPublicUrl(any))
        .thenReturn('https://fakeurl.com/test.jpg');

    // Override Supabase.instance.client with our mockSupabaseClient.
    Supabase.instance.client = mockSupabaseClient;

    // Create the manager instance.
    manager = UploadQueueManager(
      repository: mockQueueRepository,
      db: mockDb,
      recipeRepository: mockRecipeRepository,
      supabaseClient: mockSupabaseClient,
    );
  });

  tearDown(() {
    manager.dispose();
  });

  test('addToQueue does not add duplicate entries', () async {
    // Simulate that an entry already exists.
    when(mockQueueRepository.getEntryByFileName('test.jpg')).thenAnswer(
          (_) async => const UploadQueueEntry(
        id: 'dummy',
        fileName: 'test.jpg',
        status: 'pending',
        retryCount: 0,
        lastTryTimestamp: null,
        recipeId: 'recipe-123',
      ),
    );

    final result = await manager.addToQueue(
      fileName: 'test.jpg',
      recipeId: 'recipe-123',
    );

    expect(result, equals(0));
    verifyNever(mockQueueRepository.insertUploadQueueEntry(
        fileName: 'test.jpg', recipeId: 'recipe-123'));
  });

  test('processQueue processes pending entries successfully', () async {
    // Create a fake pending entry.
    const pendingEntry = UploadQueueEntry(
      id: 'entry-1',
      fileName: 'test.jpg',
      status: 'pending',
      retryCount: 0,
      lastTryTimestamp: 0, // allow immediate processing
      recipeId: 'recipe-123',
    );

    // Stub repository methods.
    when(mockQueueRepository.getPendingEntries())
        .thenAnswer((_) async => [pendingEntry]);
    when(mockQueueRepository.resolveFullPath('test.jpg'))
        .thenAnswer((_) async => '/fake/path/test.jpg');
    // When updateEntry is called, return true.
    when(mockQueueRepository.updateEntry(any))
        .thenAnswer((_) async => true);

    // Call processQueue.
    await manager.processQueue();

    // Verify that updateEntry was called with an entry that now has status "uploaded".
    verify(mockQueueRepository.updateEntry(argThat(
      predicate<UploadQueueEntry>((entry) => entry.status == 'uploaded'),
    ))).called(greaterThan(0));

    // Verify that recipeRepository.updateImageForRecipe was called with expected parameters.
    verify(mockRecipeRepository.updateImageForRecipe(
      recipeId: 'recipe-123',
      fileName: 'test.jpg',
      publicUrl: 'https://fakeurl.com/test.jpg',
    )).called(1);
  });

  test('processQueue defers processing when offline', () async {
    // Properly mock the connectivity to simulate offline.
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      connectivityChannel,
          (MethodCall call) async {
        if (call.method == 'check') {
          return ['none']; // <-- use String instead of ConnectivityResult.none
        }
        return null;
      },
    );

    await manager.processQueue();

    // Verify that getPendingEntries is never called when offline.
    verifyNever(mockQueueRepository.getPendingEntries());

    // Reset connectivity to online for subsequent tests.
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      connectivityChannel,
          (MethodCall call) async {
        if (call.method == 'check') {
          return ['wifi'];
        }
        return null;
      },
    );
  });

  test('processQueue sets entry to failed after max retries', () {
    fakeAsync((async) async {
      const baseDelayMillis = 2000; // Must match UploadQueueManager's baseDelay
      const maxRetries = UploadQueueManager.maxRetries;

      var currentEntry = UploadQueueEntry(
        id: 'entry-max-retries',
        fileName: 'retry-test.jpg',
        status: 'pending',
        retryCount: 0,
        lastTryTimestamp: 0,
        recipeId: 'recipe-retry',
      );

      // Always return our mutable entry list.
      when(mockQueueRepository.getPendingEntries()).thenAnswer((_) async {
        if (currentEntry.status == 'pending') return [currentEntry];
        return [];
      });

      when(mockQueueRepository.resolveFullPath('retry-test.jpg'))
          .thenAnswer((_) async => '/fake/path/retry-test.jpg');

      // Always fail the upload to trigger retries.
      when(mockBucketApi.upload(any, any))
          .thenThrow(Exception('Simulated upload failure'));

      // Update the current entry each time `updateEntry` is called.
      when(mockQueueRepository.updateEntry(any)).thenAnswer((invocation) async {
        currentEntry = invocation.positionalArguments.first as UploadQueueEntry;
        return true;
      });

      // Trigger first processing attempt.
      await manager.processQueue();

      // Simulate exponential backoff retries.
      for (var retry = 1; retry <= maxRetries; retry++) {
        // Move time forward past the backoff delay.
        final backoffDelay = UploadQueueManager.baseDelay * (1 << (retry - 1));
        async.elapse(backoffMillis(backoff: retry - 1));
        async.flushMicrotasks();
        await manager.processQueue();
      }

      // Verify entry marked as failed.
      verify(mockQueueRepository.updateEntry(argThat(
        predicate<UploadQueueEntry>(
              (entry) => entry.status == 'failed' && entry.retryCount == UploadQueueManager.maxRetries,
        ),
      ))).called(1);

      // Verify no more uploads attempted after marking failed.
      verifyNever(mockRecipeRepository.updateImageForRecipe(
        recipeId: anyNamed('recipeId'),
        fileName: anyNamed('fileName'),
        publicUrl: anyNamed('publicUrl'),
      ));
    });
  });
}

// Helper to compute exponential backoff milliseconds.
Duration backoffMillis({required int backoff}) {
  return Duration(milliseconds: UploadQueueManager.baseDelay.inMilliseconds * (1 << backoff));
}
