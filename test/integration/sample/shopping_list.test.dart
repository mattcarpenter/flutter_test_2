// test/integration/shopping_list_test.dart

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:recipe_app/database/database.dart';
import 'package:recipe_app/src/providers/shopping_list_provider.dart';
import 'package:recipe_app/src/providers/recipe_provider.dart';
import '../../utils/test_user_manager.dart';
import '../../utils/test_household_manager.dart';
import '../../utils/test_utils.dart';

void main() async {
  await initializeTestEnvironment();
  late ProviderContainer container;

  tearDownAll(() async {
    await TestUserManager.logoutTestUser();
  });

  group('Shopping List Tests', () {
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

    testWidgets('User sees their lists after signing in again', (tester) async {
      await TestUserManager.createTestUser('owner');

      await withTestUser('owner', () async {
        final ownerId = Supabase.instance.client.auth.currentUser!.id;
        await container.read(shoppingListsProvider.notifier).createList(
          userId: ownerId,
          name: 'Groceries',
        );

        await waitForProviderValue<List<ShoppingListEntry>>(
          container,
          shoppingListsProvider,
              (lists) =>
          lists.length == 1 && lists.any((l) => l.name == 'Groceries'),
        );
      });

      // After sign-out, local DB clears
      await waitForProviderValue<List<ShoppingListEntry>>(
        container,
        shoppingListsProvider,
            (lists) => lists.isEmpty,
      );

      // Sign back in
      await withTestUser('owner', () async {
        await waitForProviderValue<List<ShoppingListEntry>>(
          container,
          shoppingListsProvider,
              (lists) =>
          lists.length == 1 && lists.any((l) => l.name == 'Groceries'),
        );
      });
    });

    testWidgets('Users cannot see other users shopping lists', (tester) async {
      await TestUserManager.createTestUsers(['owner', 'other']);

      await withTestUser('owner', () async {
        final ownerId = Supabase.instance.client.auth.currentUser!.id;
        await container.read(shoppingListsProvider.notifier).createList(
          userId: ownerId,
          name: 'Owner List',
        );

        await waitForProviderValue<List<ShoppingListEntry>>(
          container,
          shoppingListsProvider,
              (lists) => lists.any((l) => l.name == 'Owner List'),
        );
      });

      await withTestUser('other', () async {
        await waitForProviderValue<List<ShoppingListEntry>>(
          container,
          shoppingListsProvider,
              (lists) => !lists.any((l) => l.name == 'Owner List'),
        );

        final otherId = Supabase.instance.client.auth.currentUser!.id;
        await container.read(shoppingListsProvider.notifier).createList(
          userId: otherId,
          name: 'Other List',
        );

        await waitForProviderValue<List<ShoppingListEntry>>(
          container,
          shoppingListsProvider,
              (lists) => lists.any((l) => l.name == 'Other List'),
        );
      });

      await withTestUser('owner', () async {
        await waitForProviderValue<List<ShoppingListEntry>>(
          container,
          shoppingListsProvider,
              (lists) => lists.any((l) => l.name == 'Owner List') &&
              !lists.any((l) => l.name == 'Other List'),
        );
      });
    });

    testWidgets('Household member sees owner shopping lists', (tester) async {
      await TestUserManager.createTestUsers(['owner', 'member']);
      String householdId = '';

      await withTestUser('owner', () async {
        final ownerId = Supabase.instance.client.auth.currentUser!.id;
        final household =
        await TestHouseholdManager.createHousehold('H', ownerId);
        householdId = household['id'];
        await TestHouseholdManager.addHouseholdMember(householdId, ownerId);

        await container.read(shoppingListsProvider.notifier).createList(
          userId: ownerId,
          householdId: householdId,
          name: 'Household List',
        );

        await waitForProviderValue<List<ShoppingListEntry>>(
          container,
          shoppingListsProvider,
              (lists) => lists.any((l) => l.name == 'Household List'),
        );
      });

      await withTestUser('member', () async {
        final memberId = Supabase.instance.client.auth.currentUser!.id;
        await TestHouseholdManager.addHouseholdMember(householdId, memberId);

        await waitForProviderValue<List<ShoppingListEntry>>(
          container,
          shoppingListsProvider,
              (lists) => lists.any((l) => l.name == 'Household List'),
        );
      });
    });

    testWidgets('Owner sees shopping list created by member', (tester) async {
      await TestUserManager.createTestUsers(['owner', 'member']);
      String householdId = '';

      await withTestUser('owner', () async {
        final ownerId = Supabase.instance.client.auth.currentUser!.id;
        final household =
        await TestHouseholdManager.createHousehold('H', ownerId);
        householdId = household['id'];
        await TestHouseholdManager.addHouseholdMember(householdId, ownerId);
      });

      await withTestUser('member', () async {
        final memberId = Supabase.instance.client.auth.currentUser!.id;
        await TestHouseholdManager.addHouseholdMember(householdId, memberId);

        await container.read(shoppingListsProvider.notifier).createList(
          userId: memberId,
          householdId: householdId,
          name: 'Member List',
        );

        await waitForProviderValue<List<ShoppingListEntry>>(
          container,
          shoppingListsProvider,
              (lists) => lists.any((l) => l.name == 'Member List'),
        );
      });

      await withTestUser('owner', () async {
        await waitForProviderValue<List<ShoppingListEntry>>(
          container,
          shoppingListsProvider,
              (lists) => lists.any((l) => l.name == 'Member List'),
        );
      });
    });
  });

  group('Shopping List Items Tests', () {
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

    Future<String> createList() async {
      final id = const Uuid().v4();
      await container.read(shoppingListsProvider.notifier).createList(
        userId: Supabase.instance.client.auth.currentUser!.id,
        name: 'Test List',
      );
      await waitForProviderValue<List<ShoppingListEntry>>(
        container,
        shoppingListsProvider,
            (lists) => lists.any((l) => l.name == 'Test List'),
      );
      return container
          .read(shoppingListsProvider)
          .value!
          .firstWhere((l) => l.name == 'Test List')
          .id;
    }

    testWidgets('Add, update, delete shopping list items', (tester) async {
      await TestUserManager.createTestUser('owner');
      await withTestUser('owner', () async {
        final listId = await createList();

        // Add item with userId
        final itemId = await container
            .read(shoppingListItemsProvider(listId).notifier)
            .addItem(
          name: 'Onion',
          amount: 2,
          unit: 'pcs',
          userId: Supabase.instance.client.auth.currentUser!.id,
        );
        await waitForProviderValue<List<ShoppingListItemEntry>>(
          container,
          shoppingListItemsProvider(listId),
              (items) => items.length == 1 && items.first.name == 'Onion',
        );

        // Update item
        await container
            .read(shoppingListItemsProvider(listId).notifier)
            .updateItem(itemId: itemId, name: 'Red Onion');
        await waitForProviderValue<List<ShoppingListItemEntry>>(
          container,
          shoppingListItemsProvider(listId),
              (items) => items.first.name == 'Red Onion',
        );

        // Delete item
        await container
            .read(shoppingListItemsProvider(listId).notifier)
            .deleteItem(itemId);
        await waitForProviderValue<List<ShoppingListItemEntry>>(
          container,
          shoppingListItemsProvider(listId),
              (items) => items.isEmpty,
        );
      });
    });

    testWidgets('Mark item as bought/unbought', (tester) async {
      await TestUserManager.createTestUser('owner');
      await withTestUser('owner', () async {
        final listId = await createList();

        // Add item with userId
        final itemId = await container
            .read(shoppingListItemsProvider(listId).notifier)
            .addItem(
          name: 'Tomato',
          userId: Supabase.instance.client.auth.currentUser!.id,
        );
        await waitForProviderValue<List<ShoppingListItemEntry>>(
          container,
          shoppingListItemsProvider(listId),
              (items) => items.length == 1 && !items.first.bought,
        );

        // Mark bought
        await container
            .read(shoppingListItemsProvider(listId).notifier)
            .markBought(itemId, bought: true);
        await waitForProviderValue<List<ShoppingListItemEntry>>(
          container,
          shoppingListItemsProvider(listId),
              (items) => items.first.bought,
        );

        // Unmark
        await container
            .read(shoppingListItemsProvider(listId).notifier)
            .markBought(itemId, bought: false);
        await waitForProviderValue<List<ShoppingListItemEntry>>(
          container,
          shoppingListItemsProvider(listId),
              (items) => !items.first.bought,
        );
      });
    });
  });
}
