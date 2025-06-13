import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_app/database/database.dart';
import 'package:recipe_app/src/providers/cook_provider.dart';
import 'package:recipe_app/src/providers/recipe_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../utils/test_household_manager.dart';
import '../../utils/test_user_manager.dart';
import '../../utils/test_utils.dart';

void main() async {
  await initializeTestEnvironment();
  late ProviderContainer container;

  tearDownAll(() async {
    await TestUserManager.logoutTestUser();
  });

  group('Cook Tests', () {
    setUpAll(() async {
      await loadEnvVars();
      await TestUserManager.wipeAlLocalAndRemoteTestUserData();
    });

    setUp(() async {
      container = ProviderContainer();
      await TestUserManager.wipeAlLocalAndRemoteTestUserData();
    });

    tearDown(() async {
      container.dispose();
      await TestUserManager.wipeAlLocalAndRemoteTestUserData();
    });

    Future<String> createRecipe(String title, String userId) async {
      final id = const Uuid().v4();
      await container.read(recipeNotifierProvider.notifier).addRecipe(
        id: id,
        title: title,
        language: 'en',
        userId: userId,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
      return id;
    }

    testWidgets('User sees their cook after signing in again', (tester) async {
      await TestUserManager.createTestUser('owner');
      await withTestUser('owner', () async {
        final ownerId = Supabase.instance.client.auth.currentUser!.id;
        final recipeId = await createRecipe('Recipe A', ownerId);

        await container.read(cookNotifierProvider.notifier).startCook(
          recipeId: recipeId,
          userId: ownerId,
          recipeName: 'Recipe A',
        );

        await waitForProviderValue<List<CookEntry>>(container, cookNotifierProvider, (cooks) => cooks.isNotEmpty);
        final cookId = container.read(cookNotifierProvider).value!.first.id;

        await container.read(cookNotifierProvider.notifier).finishCook(
          cookId: cookId,
          rating: 5,
          notes: 'Saved Cook',
        );

        await waitForProviderValue<List<CookEntry>>(container, cookNotifierProvider, (cooks) =>
            cooks.any((c) => c.notes == 'Saved Cook'));
      });

      await waitForProviderValue<List<CookEntry>>(container, cookNotifierProvider, (cooks) => cooks.isEmpty);

      await withTestUser('owner', () async {
        await waitForProviderValue<List<CookEntry>>(container, cookNotifierProvider, (cooks) =>
            cooks.any((c) => c.notes == 'Saved Cook'));
      });
    });

    testWidgets('Users cannot see other users cooks', (tester) async {
      await TestUserManager.createTestUsers(['owner', 'other']);
      await withTestUser('owner', () async {
        final id = Supabase.instance.client.auth.currentUser!.id;
        final recipeId = await createRecipe('Recipe X', id);

        await container.read(cookNotifierProvider.notifier).startCook(
          recipeId: recipeId,
          userId: id,
          recipeName: 'Recipe X',
        );

        await waitForProviderValue<List<CookEntry>>(container, cookNotifierProvider, (cooks) => cooks.isNotEmpty);
        final cookId = container.read(cookNotifierProvider).value!.first.id;

        await container.read(cookNotifierProvider.notifier).finishCook(
          cookId: cookId,
          notes: 'Private Cook',
        );

        await waitForProviderValue<List<CookEntry>>(container, cookNotifierProvider, (cooks) =>
            cooks.any((c) => c.notes == 'Private Cook'));
      });

      await withTestUser('other', () async {
        await waitForProviderValue<List<CookEntry>>(container, cookNotifierProvider, (cooks) =>
        !cooks.any((c) => c.notes == 'Private Cook'));
      });
    });

    testWidgets('Household member sees owner cook', (tester) async {
      await TestUserManager.createTestUsers(['owner', 'member']);
      String householdId = '';

      await withTestUser('owner', () async {
        final ownerId = Supabase.instance.client.auth.currentUser!.id;
        final household = await TestHouseholdManager.createHousehold('Household', ownerId);
        householdId = household['id'];
        await TestHouseholdManager.addHouseholdMember(householdId, ownerId);

        final recipeId = await createRecipe('Household Recipe', ownerId);

        await container.read(cookNotifierProvider.notifier).startCook(
          recipeId: recipeId,
          userId: ownerId,
          householdId: householdId,
          recipeName: 'Household Recipe',
        );

        await waitForProviderValue<List<CookEntry>>(container, cookNotifierProvider, (cooks) => cooks.isNotEmpty);
        final cookId = container.read(cookNotifierProvider).value!.first.id;

        await container.read(cookNotifierProvider.notifier).finishCook(
          cookId: cookId,
          notes: 'Household Cook',
        );

        await waitForProviderValue<List<CookEntry>>(container, cookNotifierProvider, (cooks) =>
            cooks.any((c) => c.notes == 'Household Cook'));
      });

      await withTestUser('member', () async {
        final memberId = Supabase.instance.client.auth.currentUser!.id;
        await TestHouseholdManager.addHouseholdMember(householdId, memberId);

        await waitForProviderValue<List<CookEntry>>(container, cookNotifierProvider, (cooks) =>
            cooks.any((c) => c.notes == 'Household Cook'));
      });
    });

    testWidgets('Owner sees cook created by household member', (tester) async {
      await TestUserManager.createTestUsers(['owner', 'member']);
      String householdId = '';

      await withTestUser('owner', () async {
        final id = Supabase.instance.client.auth.currentUser!.id;
        final h = await TestHouseholdManager.createHousehold('H', id);
        householdId = h['id'];
        await TestHouseholdManager.addHouseholdMember(householdId, id);
      });

      await withTestUser('member', () async {
        final memberId = Supabase.instance.client.auth.currentUser!.id;
        await TestHouseholdManager.addHouseholdMember(householdId, memberId);

        final recipeId = await createRecipe('Member Recipe', memberId);

        await container.read(cookNotifierProvider.notifier).startCook(
          recipeId: recipeId,
          userId: memberId,
          householdId: householdId,
          recipeName: 'Member Recipe',
        );

        await waitForProviderValue<List<CookEntry>>(container, cookNotifierProvider, (cooks) => cooks.isNotEmpty);
        final cookId = container.read(cookNotifierProvider).value!.first.id;

        await container.read(cookNotifierProvider.notifier).finishCook(
          cookId: cookId,
          notes: 'Member Cook',
        );

        await waitForProviderValue<List<CookEntry>>(container, cookNotifierProvider, (cooks) =>
            cooks.any((c) => c.notes == 'Member Cook'));
      });

      await withTestUser('owner', () async {
        await waitForProviderValue<List<CookEntry>>(container, cookNotifierProvider, (cooks) =>
            cooks.any((c) => c.notes == 'Member Cook'));
      });
    });

    testWidgets('User cannot create cook for recipe they do not have access to', (tester) async {
      await TestUserManager.createTestUsers(['owner', 'intruder']);
      late String recipeId;

      await withTestUser('owner', () async {
        final ownerId = Supabase.instance.client.auth.currentUser!.id;
        recipeId = await createRecipe('Private Recipe', ownerId);
      });

      await withTestUser('intruder', () async {
        final intruderId = Supabase.instance.client.auth.currentUser!.id;

        // Attempt to start cook (will succeed locally)
        await container.read(cookNotifierProvider.notifier).startCook(
          recipeId: recipeId,
          userId: intruderId,
          recipeName: 'Private Recipe',
        );

        // Wait and confirm that no cooks remain after sync fails
        await Future.delayed(const Duration(seconds: 3));
        await waitForProviderValue<List<CookEntry>>(
          container,
          cookNotifierProvider,
              (cooks) => cooks.isEmpty,
        );
      });
    });
  });
}
