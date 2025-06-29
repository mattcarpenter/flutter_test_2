import 'package:drift/drift.dart';
import 'package:logging/logging.dart';
import '../../database/database.dart';

class HouseholdDataCleanupService {
  final AppDatabase _db;
  final _logger = Logger('HouseholdDataCleanupService');
  
  HouseholdDataCleanupService(this._db);
  
  /// Automatically migrate ALL personal data when joining household
  Future<void> migrateAllPersonalDataToHousehold(String userId, String householdId) async {
    _logger.info('Starting migration of personal data to household: $householdId');
    
    try {
      await _db.transaction(() async {
        // Migrate all entity types
        await _updateRecipes(userId, null, householdId);
        await _updateRecipeFolders(userId, null, householdId);
        await _updateMealPlans(userId, null, householdId);
        await _updatePantryItems(userId, null, householdId);
        await _updateShoppingListsAndItems(userId, null, householdId);
        await _updateCooks(userId, null, householdId);
        await _updateConverters(userId, null, householdId);
        await _updateTermOverrides(userId, null, householdId);
      });
      
      _logger.info('Successfully migrated all personal data to household: $householdId');
    } catch (e) {
      _logger.severe('Failed to migrate data to household: $e');
      rethrow;
    }
  }
  
  /// Move household data back to personal when leaving/removed
  Future<void> cleanupDataForHousehold(String userId, String householdId) async {
    _logger.info('Starting cleanup of household data: $householdId');
    
    try {
      await _db.transaction(() async {
        // Move all entity types back to personal
        await _updateRecipes(userId, householdId, null);
        await _updateRecipeFolders(userId, householdId, null);
        await _updateMealPlans(userId, householdId, null);
        await _updatePantryItems(userId, householdId, null);
        await _updateShoppingListsAndItems(userId, householdId, null);
        await _updateCooks(userId, householdId, null);
        await _updateConverters(userId, householdId, null);
        await _updateTermOverrides(userId, householdId, null);
      });
      
      _logger.info('Successfully cleaned up data for household: $householdId');
    } catch (e) {
      _logger.severe('Failed to cleanup household data: $e');
      rethrow;
    }
  }
  
  /// Check if user has any unmigrated personal data
  Future<bool> hasUnmigratedPersonalData(String userId) async {
    // Check recipes as a representative sample
    final query = _db.selectOnly(_db.recipes)
      ..addColumns([_db.recipes.id.count()])
      ..where(_db.recipes.userId.equals(userId) & _db.recipes.householdId.isNull());
    
    final result = await query.getSingle();
    final count = result.read(_db.recipes.id.count()) ?? 0;
    
    return count > 0;
  }
  
  // Entity update methods
  
  Future<void> _updateRecipes(String userId, String? fromHouseholdId, String? toHouseholdId) async {
    final query = _db.update(_db.recipes)
      ..where((tbl) => tbl.userId.equals(userId));
    
    if (fromHouseholdId != null) {
      query.where((tbl) => tbl.householdId.equals(fromHouseholdId));
    } else {
      query.where((tbl) => tbl.householdId.isNull());
    }
    
    await query.write(RecipesCompanion(
      householdId: Value(toHouseholdId),
      updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
    ));
  }
  
  Future<void> _updateRecipeFolders(String userId, String? fromHouseholdId, String? toHouseholdId) async {
    final query = _db.update(_db.recipeFolders)
      ..where((tbl) => tbl.userId.equals(userId));
    
    if (fromHouseholdId != null) {
      query.where((tbl) => tbl.householdId.equals(fromHouseholdId));
    } else {
      query.where((tbl) => tbl.householdId.isNull());
    }
    
    await query.write(RecipeFoldersCompanion(
      householdId: Value(toHouseholdId),
    ));
  }
  
  Future<void> _updateMealPlans(String userId, String? fromHouseholdId, String? toHouseholdId) async {
    final query = _db.update(_db.mealPlans)
      ..where((tbl) => tbl.userId.equals(userId));
    
    if (fromHouseholdId != null) {
      query.where((tbl) => tbl.householdId.equals(fromHouseholdId));
    } else {
      query.where((tbl) => tbl.householdId.isNull());
    }
    
    await query.write(MealPlansCompanion(
      householdId: Value(toHouseholdId),
      updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
    ));
  }
  
  Future<void> _updatePantryItems(String userId, String? fromHouseholdId, String? toHouseholdId) async {
    final query = _db.update(_db.pantryItems)
      ..where((tbl) => tbl.userId.equals(userId));
    
    if (fromHouseholdId != null) {
      query.where((tbl) => tbl.householdId.equals(fromHouseholdId));
    } else {
      query.where((tbl) => tbl.householdId.isNull());
    }
    
    await query.write(PantryItemsCompanion(
      householdId: Value(toHouseholdId),
      updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
    ));
  }
  
  /// Special handling for shopping lists and their items
  Future<void> _updateShoppingListsAndItems(String userId, String? fromHouseholdId, String? toHouseholdId) async {
    // First get list IDs that will be migrated
    final selectQuery = _db.select(_db.shoppingLists)
      ..where((tbl) => tbl.userId.equals(userId));
    
    if (fromHouseholdId != null) {
      selectQuery.where((tbl) => tbl.householdId.equals(fromHouseholdId));
    } else {
      selectQuery.where((tbl) => tbl.householdId.isNull());
    }
    
    final lists = await selectQuery.get();
    final listIds = lists.map((l) => l.id).toList();
    
    // Update the shopping lists
    final listsQuery = _db.update(_db.shoppingLists)
      ..where((tbl) => tbl.userId.equals(userId));
    
    if (fromHouseholdId != null) {
      listsQuery.where((tbl) => tbl.householdId.equals(fromHouseholdId));
    } else {
      listsQuery.where((tbl) => tbl.householdId.isNull());
    }
    
    await listsQuery.write(ShoppingListsCompanion(
      householdId: Value(toHouseholdId),
      updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
    ));
    
    // Update items belonging to these lists
    if (listIds.isNotEmpty) {
      await (_db.update(_db.shoppingListItems)
        ..where((tbl) => tbl.shoppingListId.isIn(listIds))
      ).write(ShoppingListItemsCompanion(
        householdId: Value(toHouseholdId),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ));
    }
  }
  
  Future<void> _updateCooks(String userId, String? fromHouseholdId, String? toHouseholdId) async {
    final query = _db.update(_db.cooks)
      ..where((tbl) => tbl.userId.equals(userId));
    
    if (fromHouseholdId != null) {
      query.where((tbl) => tbl.householdId.equals(fromHouseholdId));
    } else {
      query.where((tbl) => tbl.householdId.isNull());
    }
    
    await query.write(CooksCompanion(
      householdId: Value(toHouseholdId),
      updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
    ));
  }
  
  Future<void> _updateConverters(String userId, String? fromHouseholdId, String? toHouseholdId) async {
    final query = _db.update(_db.converters)
      ..where((tbl) => tbl.userId.equals(userId));
    
    if (fromHouseholdId != null) {
      query.where((tbl) => tbl.householdId.equals(fromHouseholdId));
    } else {
      query.where((tbl) => tbl.householdId.isNull());
    }
    
    await query.write(ConvertersCompanion(
      householdId: Value(toHouseholdId),
      updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
    ));
  }
  
  Future<void> _updateTermOverrides(String userId, String? fromHouseholdId, String? toHouseholdId) async {
    final query = _db.update(_db.ingredientTermOverrides)
      ..where((tbl) => tbl.userId.equals(userId));
    
    if (fromHouseholdId != null) {
      query.where((tbl) => tbl.householdId.equals(fromHouseholdId));
    } else {
      query.where((tbl) => tbl.householdId.isNull());
    }
    
    await query.write(IngredientTermOverridesCompanion(
      householdId: Value(toHouseholdId),
    ));
  }
}