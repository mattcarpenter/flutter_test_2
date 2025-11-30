import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:recipe_app/database/database.dart';
import 'package:recipe_app/src/features/import_export/models/export_recipe.dart';
import 'package:recipe_app/src/features/import_export/services/import_service.dart';
import 'package:recipe_app/src/repositories/recipe_repository.dart';
import 'package:recipe_app/src/repositories/recipe_tag_repository.dart';
import 'package:recipe_app/src/repositories/recipe_folder_repository.dart';

import 'import_service_test.mocks.dart';

@GenerateMocks([
  RecipeRepository,
  RecipeTagRepository,
  RecipeFolderRepository,
])
void main() {
  late MockRecipeRepository mockRecipeRepo;
  late MockRecipeTagRepository mockTagRepo;
  late MockRecipeFolderRepository mockFolderRepo;
  late ImportService importService;

  setUp(() {
    mockRecipeRepo = MockRecipeRepository();
    mockTagRepo = MockRecipeTagRepository();
    mockFolderRepo = MockRecipeFolderRepository();

    importService = ImportService(
      recipeRepository: mockRecipeRepo,
      tagRepository: mockTagRepo,
      folderRepository: mockFolderRepo,
    );
  });

  group('ImportService - previewImport', () {
    test('should generate preview for Stockpot recipes', () async {
      // Arrange
      final recipes = [
        ExportRecipe(
          title: 'Test Recipe',
          tagNames: ['vegetarian', 'easy'],
          folderNames: ['Dinner'],
        ),
      ];

      when(mockTagRepo.watchTags()).thenAnswer((_) => Stream.value([]));
      when(mockFolderRepo.watchFolders()).thenAnswer((_) => Stream.value([]));

      // Act
      final preview = await importService.previewImport(
        recipes: recipes,
        source: ImportSource.stockpot,
      );

      // Assert
      expect(preview.recipeCount, 1);
      expect(preview.tagNames, containsAll(['vegetarian', 'easy']));
      expect(preview.folderNames, contains('Dinner'));
      expect(preview.existingTagNames, isEmpty);
      expect(preview.newTagNames, containsAll(['vegetarian', 'easy']));
      expect(preview.hasPaprikaCategories, false);
    });

    test('should identify existing tags and folders', () async {
      // Arrange
      final recipes = [
        ExportRecipe(
          title: 'Test Recipe',
          tagNames: ['vegetarian'],
          folderNames: ['Dinner'],
        ),
      ];

      final existingTag = RecipeTagEntry(
        id: 'tag-1',
        name: 'vegetarian',
        color: '#4285F4',
        userId: 'user-1',
        householdId: null,
        createdAt: 123456,
        updatedAt: 123456,
        deletedAt: null,
      );

      final existingFolder = RecipeFolderEntry(
        id: 'folder-1',
        name: 'Dinner',
        userId: 'user-1',
        householdId: null,
        deletedAt: null,
        folderType: 0,
        filterLogic: 0,
        smartFilterTags: null,
        smartFilterTerms: null,
      );

      when(mockTagRepo.watchTags()).thenAnswer((_) => Stream.value([existingTag]));
      when(mockFolderRepo.watchFolders()).thenAnswer((_) => Stream.value([existingFolder]));

      // Act
      final preview = await importService.previewImport(
        recipes: recipes,
        source: ImportSource.stockpot,
      );

      // Assert
      expect(preview.existingTagNames, contains('vegetarian'));
      expect(preview.newTagNames, isEmpty);
      expect(preview.existingFolderNames, contains('Dinner'));
      expect(preview.newFolderNames, isEmpty);
    });

    test('should mark Paprika imports with categories', () async {
      // Arrange
      final recipes = [
        ExportRecipe(
          title: 'Test Recipe',
          tagNames: ['Desserts'],
        ),
      ];

      when(mockTagRepo.watchTags()).thenAnswer((_) => Stream.value([]));
      when(mockFolderRepo.watchFolders()).thenAnswer((_) => Stream.value([]));

      // Act
      final preview = await importService.previewImport(
        recipes: recipes,
        source: ImportSource.paprika,
      );

      // Assert
      expect(preview.hasPaprikaCategories, true);
    });

    test('should not mark Paprika imports without categories', () async {
      // Arrange
      final recipes = [
        ExportRecipe(
          title: 'Test Recipe',
          tagNames: [],
        ),
      ];

      when(mockTagRepo.watchTags()).thenAnswer((_) => Stream.value([]));
      when(mockFolderRepo.watchFolders()).thenAnswer((_) => Stream.value([]));

      // Act
      final preview = await importService.previewImport(
        recipes: recipes,
        source: ImportSource.paprika,
      );

      // Assert
      expect(preview.hasPaprikaCategories, false);
    });

    test('should handle case-insensitive matching of tags and folders', () async {
      // Arrange
      final recipes = [
        ExportRecipe(
          title: 'Test Recipe',
          tagNames: ['VEGETARIAN'],
          folderNames: ['DINNER'],
        ),
      ];

      final existingTag = RecipeTagEntry(
        id: 'tag-1',
        name: 'vegetarian',
        color: '#4285F4',
        userId: 'user-1',
        householdId: null,
        createdAt: 123456,
        updatedAt: 123456,
        deletedAt: null,
      );

      final existingFolder = RecipeFolderEntry(
        id: 'folder-1',
        name: 'dinner',
        userId: 'user-1',
        householdId: null,
        deletedAt: null,
        folderType: 0,
        filterLogic: 0,
        smartFilterTags: null,
        smartFilterTerms: null,
      );

      when(mockTagRepo.watchTags()).thenAnswer((_) => Stream.value([existingTag]));
      when(mockFolderRepo.watchFolders()).thenAnswer((_) => Stream.value([existingFolder]));

      // Act
      final preview = await importService.previewImport(
        recipes: recipes,
        source: ImportSource.stockpot,
      );

      // Assert
      expect(preview.existingTagNames, contains('VEGETARIAN'));
      expect(preview.newTagNames, isEmpty);
      expect(preview.existingFolderNames, contains('DINNER'));
      expect(preview.newFolderNames, isEmpty);
    });
  });

  group('ImportService - executeImport', () {
    test('should import recipe successfully', () async {
      // Arrange
      final importedRecipe = ImportedRecipe(
        recipe: ExportRecipe(
          title: 'Test Recipe',
          ingredients: [
            ExportIngredient(
              type: 'ingredient',
              name: '1 cup sugar',
            ),
          ],
          steps: [
            ExportStep(
              type: 'step',
              text: 'Mix ingredients',
            ),
          ],
        ),
        tagNames: [],
        folderNames: [],
        images: [],
      );

      when(mockRecipeRepo.addRecipe(any)).thenAnswer((_) async => 1);

      // Act
      final result = await importService.executeImport(
        recipes: [importedRecipe],
        tagNameToId: {},
        folderNameToId: {},
      );

      // Assert
      expect(result.successCount, 1);
      expect(result.failureCount, 0);
      expect(result.errors, isEmpty);
      verify(mockRecipeRepo.addRecipe(any)).called(1);
    });

    test('should handle errors and continue importing', () async {
      // Arrange
      final recipe1 = ImportedRecipe(
        recipe: ExportRecipe(title: 'Recipe 1'),
        tagNames: [],
        folderNames: [],
        images: [],
      );

      final recipe2 = ImportedRecipe(
        recipe: ExportRecipe(title: 'Recipe 2'),
        tagNames: [],
        folderNames: [],
        images: [],
      );

      when(mockRecipeRepo.addRecipe(any))
          .thenAnswer((_) async => throw Exception('Database error'));

      // Act
      final result = await importService.executeImport(
        recipes: [recipe1, recipe2],
        tagNameToId: {},
        folderNameToId: {},
      );

      // Assert
      expect(result.successCount, 0);
      expect(result.failureCount, 2);
      expect(result.errors, hasLength(2));
      expect(result.errors[0], contains('Recipe 1'));
      expect(result.errors[1], contains('Recipe 2'));
    });

    test('should call progress callback', () async {
      // Arrange
      final recipes = [
        ImportedRecipe(
          recipe: ExportRecipe(title: 'Recipe 1'),
          tagNames: [],
          folderNames: [],
          images: [],
        ),
        ImportedRecipe(
          recipe: ExportRecipe(title: 'Recipe 2'),
          tagNames: [],
          folderNames: [],
          images: [],
        ),
      ];

      when(mockRecipeRepo.addRecipe(any)).thenAnswer((_) async => 1);

      final progressCalls = <List<int>>[];

      // Act
      await importService.executeImport(
        recipes: recipes,
        tagNameToId: {},
        folderNameToId: {},
        onProgress: (current, total) {
          progressCalls.add([current, total]);
        },
      );

      // Assert
      expect(progressCalls, hasLength(2));
      expect(progressCalls[0], [1, 2]);
      expect(progressCalls[1], [2, 2]);
    });
  });

  group('ImportService - createTagsFromNames', () {
    test('should create new tags', () async {
      // Arrange
      when(mockTagRepo.watchTags()).thenAnswer((_) => Stream.value([]));

      final newTag = RecipeTagEntry(
        id: 'tag-1',
        name: 'vegetarian',
        color: '#4285F4',
        userId: 'user-1',
        householdId: null,
        createdAt: 123456,
        updatedAt: 123456,
        deletedAt: null,
      );

      when(mockTagRepo.addTag(
        name: 'vegetarian',
        color: '#4285F4',
        userId: null,
      )).thenAnswer((_) async => newTag);

      // Act
      final result = await importService.createTagsFromNames(['vegetarian']);

      // Assert
      expect(result['vegetarian'], 'tag-1');
      verify(mockTagRepo.addTag(
        name: 'vegetarian',
        color: '#4285F4',
        userId: null,
      )).called(1);
    });

    test('should reuse existing tags', () async {
      // Arrange
      final existingTag = RecipeTagEntry(
        id: 'tag-1',
        name: 'vegetarian',
        color: '#4285F4',
        userId: 'user-1',
        householdId: null,
        createdAt: 123456,
        updatedAt: 123456,
        deletedAt: null,
      );

      when(mockTagRepo.watchTags()).thenAnswer((_) => Stream.value([existingTag]));

      // Act
      final result = await importService.createTagsFromNames(['vegetarian']);

      // Assert
      expect(result['vegetarian'], 'tag-1');
      verifyNever(mockTagRepo.addTag(
        name: anyNamed('name'),
        color: anyNamed('color'),
        userId: anyNamed('userId'),
      ));
    });
  });

  group('ImportService - createFoldersFromNames', () {
    test('should create new folders', () async {
      // Arrange
      when(mockFolderRepo.watchFolders()).thenAnswer((_) => Stream.value([]));

      final newFolder = RecipeFolderEntry(
        id: 'folder-1',
        name: 'Dinner',
        userId: 'user-1',
        householdId: null,
        deletedAt: null,
        folderType: 0,
        filterLogic: 0,
        smartFilterTags: null,
        smartFilterTerms: null,
      );

      when(mockFolderRepo.addFolder(
        name: 'Dinner',
        userId: null,
        householdId: null,
      )).thenAnswer((_) async => newFolder);

      // Act
      final result = await importService.createFoldersFromNames(['Dinner']);

      // Assert
      expect(result['dinner'], 'folder-1');
      verify(mockFolderRepo.addFolder(
        name: 'Dinner',
        userId: null,
        householdId: null,
      )).called(1);
    });

    test('should reuse existing folders', () async {
      // Arrange
      final existingFolder = RecipeFolderEntry(
        id: 'folder-1',
        name: 'Dinner',
        userId: 'user-1',
        householdId: null,
        deletedAt: null,
        folderType: 0,
        filterLogic: 0,
        smartFilterTags: null,
        smartFilterTerms: null,
      );

      when(mockFolderRepo.watchFolders()).thenAnswer((_) => Stream.value([existingFolder]));

      // Act
      final result = await importService.createFoldersFromNames(['Dinner']);

      // Assert
      expect(result['dinner'], 'folder-1');
      verifyNever(mockFolderRepo.addFolder(
        name: anyNamed('name'),
        userId: anyNamed('userId'),
        householdId: anyNamed('householdId'),
      ));
    });
  });
}
