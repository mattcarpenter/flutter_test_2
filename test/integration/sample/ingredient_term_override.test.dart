import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_app/database/database.dart';
import 'package:recipe_app/src/providers/ingredient_term_override_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../utils/test_user_manager.dart';
import '../../utils/test_utils.dart';

void main() async {
  await initializeTestEnvironment();
  late ProviderContainer container;

  tearDownAll(() async {
    await TestUserManager.logoutTestUser();
  });

  group('Ingredient Term Override Tests', () {
    setUp(() async {
      container = ProviderContainer();
      await TestUserManager.wipeAlLocalAndRemoteTestUserData();
    });

    tearDown(() async {
      container.dispose();
      await TestUserManager.wipeAlLocalAndRemoteTestUserData();
    });

    testWidgets('Add term override', (tester) async {
      await TestUserManager.createTestUser('owner');
      await withTestUser('owner', () async {
        final userId = Supabase.instance.client.auth.currentUser!.id;

        final notifier = container.read(
          ingredientTermOverrideNotifierProvider.notifier,
        );

        const inputTerm = "margarine";
        const mappedTerm = "butter";

        await notifier.addOverride(
          inputTerm: inputTerm,
          mappedTerm: mappedTerm,
          userId: userId,
        );

        final overrides = await waitForProviderValue<List<IngredientTermOverrideEntry>>(
          container,
          ingredientTermOverrideNotifierProvider,
              (overrides) => overrides.any((o) => o.inputTerm == inputTerm),
        );

        expect(overrides.any((o) => o.inputTerm == inputTerm && o.mappedTerm == mappedTerm), isTrue);
      });
    });

    testWidgets('Delete term override', (tester) async {
      await TestUserManager.createTestUser('owner');
      await withTestUser('owner', () async {
        final userId = Supabase.instance.client.auth.currentUser!.id;

        final notifier = container.read(
          ingredientTermOverrideNotifierProvider.notifier,
        );

        const inputTerm = "shortening";
        const mappedTerm = "butter";

        await notifier.addOverride(
          inputTerm: inputTerm,
          mappedTerm: mappedTerm,
          userId: userId,
        );

        final overrides = await waitForProviderValue<List<IngredientTermOverrideEntry>>(
          container,
          ingredientTermOverrideNotifierProvider,
              (overrides) => overrides.any((o) => o.inputTerm == inputTerm),
        );

        final overrideId = overrides.firstWhere((o) => o.inputTerm == inputTerm).id;

        await notifier.deleteOverrideById(overrideId);

        final afterDeleteOverrides = await waitForProviderValue<List<IngredientTermOverrideEntry>>(
          container,
          ingredientTermOverrideNotifierProvider,
              (overrides) => overrides.every((o) => o.inputTerm != inputTerm),
        );

        expect(afterDeleteOverrides.any((o) => o.inputTerm == inputTerm), isFalse);
      });
    });
  });
}
