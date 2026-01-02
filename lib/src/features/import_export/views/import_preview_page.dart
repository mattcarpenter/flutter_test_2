import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../localization/l10n_extension.dart';
import '../../../managers/upload_queue_manager.dart';
import '../../../mobile/utils/adaptive_sliver_page.dart';
import '../../../providers/household_provider.dart';
import '../../../providers/recipe_provider.dart';
import '../../../providers/subscription_provider.dart';
import '../../../repositories/recipe_folder_repository.dart';
import '../../../repositories/recipe_repository.dart';
import '../../../repositories/recipe_tag_repository.dart';
import '../../../services/logging/app_logger.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_radio_button_row_condensed.dart';
import '../../settings/widgets/settings_group_condensed.dart';
import '../models/export_recipe.dart';
import '../services/converters/converters.dart' as converters;
import '../services/import_service.dart';
import '../services/parsers/crouton_parser.dart';
import '../services/parsers/paprika_parser.dart';
import '../services/parsers/stockpot_parser.dart';

/// Arguments passed to the import preview page
class ImportPreviewPageArgs {
  final String filePath;
  final ImportSource source;

  ImportPreviewPageArgs({
    required this.filePath,
    required this.source,
  });
}

/// Page that shows a preview of what will be imported
class ImportPreviewPage extends ConsumerStatefulWidget {
  final String filePath;
  final ImportSource source;

  const ImportPreviewPage({
    super.key,
    required this.filePath,
    required this.source,
  });

  @override
  ConsumerState<ImportPreviewPage> createState() => _ImportPreviewPageState();
}

class _ImportPreviewPageState extends ConsumerState<ImportPreviewPage> {
  ImportPreview? _preview;
  bool _isLoading = true;
  String? _error;
  bool _paprikaCategoriesAsTags = true; // For Paprika import

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final file = File(widget.filePath);

      // Parse using appropriate parser and convert to ExportRecipe
      List<ExportRecipe> exportRecipes;

      switch (widget.source) {
        case ImportSource.stockpot:
          final parser = StockpotParser();
          exportRecipes = await parser.parseArchive(file);
          break;

        case ImportSource.paprika:
          final parser = PaprikaParser();
          final paprikaRecipes = await parser.parseArchive(file);
          final converter = converters.PaprikaConverter();
          exportRecipes = _convertToExportRecipes(
            paprikaRecipes.map(converter.convert).toList(),
          );
          break;

        case ImportSource.crouton:
          final parser = CroutonParser();
          final croutonRecipes = await parser.parseArchive(file);
          final converter = converters.CroutonConverter();
          exportRecipes = _convertToExportRecipes(
            croutonRecipes.map(converter.convert).toList(),
          );
          break;
      }

      AppLogger.info('Parsed ${exportRecipes.length} recipes from ${widget.source}');

      // Generate preview using ImportService
      final importService = ImportService(
        recipeRepository: ref.read(recipeRepositoryProvider),
        tagRepository: ref.read(recipeTagRepositoryProvider),
        folderRepository: ref.read(recipeFolderRepositoryProvider),
      );

      final preview = await importService.previewImport(
        recipes: exportRecipes,
        source: widget.source,
      );

      if (mounted) {
        setState(() {
          _preview = preview;
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      AppLogger.error('Failed to load import preview', e, stack);
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// Convert ImportedRecipe (from converters) to ExportRecipe (for import service)
  List<ExportRecipe> _convertToExportRecipes(List<converters.ImportedRecipe> importedRecipes) {
    return importedRecipes.map((imported) {
      return ExportRecipe(
        title: imported.title,
        description: imported.description,
        rating: imported.rating,
        language: imported.language,
        servings: imported.servings,
        prepTime: imported.prepTime,
        cookTime: imported.cookTime,
        totalTime: imported.totalTime,
        source: imported.source,
        nutrition: imported.nutrition,
        generalNotes: imported.generalNotes,
        createdAt: imported.createdAt,
        updatedAt: imported.updatedAt,
        pinned: imported.pinned,
        tagNames: imported.tagNames,
        folderNames: imported.folderNames,
        ingredients: imported.ingredients.map((ing) {
          return ExportIngredient(
            type: ing.type,
            name: ing.name,
            note: ing.note,
            terms: ing.terms?.map((term) {
              return ExportIngredientTerm(
                value: term.value,
                source: term.source,
                sort: term.sort,
              );
            }).toList(),
            isCanonicalised: ing.isCanonicalised,
            category: ing.category,
          );
        }).toList(),
        steps: imported.steps.map((step) {
          return ExportStep(
            type: step.type,
            text: step.text,
            note: step.note,
            timerDurationSeconds: step.timerDurationSeconds,
          );
        }).toList(),
        images: imported.images.map((img) {
          return ExportImage(
            isCover: img.isCover,
            data: img.data,
            publicUrl: img.publicUrl,
          );
        }).toList(),
      );
    }).toList();
  }

  Future<void> _executeImport() async {
    if (_preview == null) return;

    setState(() => _isLoading = true);

    try {
      AppLogger.info('Starting import of ${_preview!.recipeCount} recipes');

      // Get auth context for proper data ownership (both null when logged out)
      final userId = Supabase.instance.client.auth.currentUser?.id;
      final householdId = userId != null
          ? ref.read(householdNotifierProvider).currentHousehold?.id
          : null;

      final importService = ImportService(
        recipeRepository: ref.read(recipeRepositoryProvider),
        tagRepository: ref.read(recipeTagRepositoryProvider),
        folderRepository: ref.read(recipeFolderRepositoryProvider),
      );

      // For Paprika imports where user chose folders instead of tags,
      // swap the tag names to folder names
      List<ImportedRecipe> recipesToImport = _preview!.recipes;
      if (widget.source == ImportSource.paprika && !_paprikaCategoriesAsTags) {
        // Move categories from tags to folders
        recipesToImport = recipesToImport.map((r) {
          return ImportedRecipe(
            recipe: ExportRecipe(
              title: r.recipe.title,
              description: r.recipe.description,
              rating: r.recipe.rating,
              language: r.recipe.language,
              servings: r.recipe.servings,
              prepTime: r.recipe.prepTime,
              cookTime: r.recipe.cookTime,
              totalTime: r.recipe.totalTime,
              source: r.recipe.source,
              nutrition: r.recipe.nutrition,
              generalNotes: r.recipe.generalNotes,
              createdAt: r.recipe.createdAt,
              updatedAt: r.recipe.updatedAt,
              pinned: r.recipe.pinned,
              tagNames: [], // Clear tags
              folderNames: r.tagNames, // Move to folders
              ingredients: r.recipe.ingredients,
              steps: r.recipe.steps,
              images: r.recipe.images,
            ),
            tagNames: [],
            folderNames: r.tagNames,
            images: r.images,
          );
        }).toList();
      }

      // Determine which tag/folder names to create
      final allTagNames = recipesToImport
          .expand((r) => r.tagNames)
          .toSet()
          .toList();
      final allFolderNames = recipesToImport
          .expand((r) => r.folderNames)
          .toSet()
          .toList();

      // Create tags and folders, get name -> ID mappings
      final tagNameToId = await importService.createTagsFromNames(
        allTagNames,
        userId: userId,
      );
      final folderNameToId = await importService.createFoldersFromNames(
        allFolderNames,
        userId: userId,
        householdId: householdId,
      );

      // Get upload queue manager for image uploads (only if user is logged in)
      final uploadQueueManager = userId != null
          ? ref.read(uploadQueueManagerProvider)
          : null;

      // Execute the import
      final result = await importService.executeImport(
        recipes: recipesToImport,
        tagNameToId: tagNameToId,
        folderNameToId: folderNameToId,
        userId: userId,
        householdId: householdId,
        uploadQueueManager: uploadQueueManager,
        onProgress: (current, total) {
          AppLogger.debug('Import progress: $current/$total');
        },
      );

      AppLogger.info('Import complete: ${result.successCount} succeeded, ${result.failureCount} failed');

      if (mounted) {
        // Check subscription status to determine messaging
        final hasPlus = ref.read(effectiveHasPlusProvider);
        final totalUserRecipes = ref.read(userRecipeCountProvider);

        // Calculate how many recipes will be locked after this import
        final willBeLocked = !hasPlus && totalUserRecipes > kFreeRecipeLimit
            ? totalUserRecipes - kFreeRecipeLimit
            : 0;

        // Show result and navigate back
        String title;
        String message;

        if (result.failureCount == 0) {
          title = context.l10n.importComplete;
          if (willBeLocked > 0) {
            // User has more recipes than the limit - show upgrade messaging
            message = context.l10n.importSuccessUpgradeMessage(result.successCount);
          } else {
            message = context.l10n.importSuccessMessage(result.successCount);
          }
        } else {
          title = context.l10n.importFinished;
          message = context.l10n.importPartialMessage(result.successCount, result.failureCount);
          if (willBeLocked > 0) {
            message += ' ${context.l10n.importSuccessUpgradeMessage(result.successCount).split('.').last.trim()}';
          }
        }

        await _showAlert(context, title: title, message: message);

        // Pop back to settings
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.settings.name == '/settings' || route.isFirst);
        }
      }
    } catch (e, stack) {
      AppLogger.error('Import failed', e, stack);
      if (mounted) {
        setState(() => _isLoading = false);
        _showAlert(context, title: context.l10n.importFailed, message: context.l10n.importFailedMessage(e.toString()));
      }
    }
  }

  Future<void> _showAlert(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    return showCupertinoDialog(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.commonOk),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          SizedBox(height: AppSpacing.lg),
          Text(
            context.l10n.importAnalyzing,
            style: AppTypography.body.copyWith(
              color: AppColors.of(context).textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.of(context).error,
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              context.l10n.importParseFailed,
              style: AppTypography.h4.copyWith(
                color: AppColors.of(context).textPrimary,
              ),
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              _error ?? context.l10n.importUnknownError,
              style: AppTypography.body.copyWith(
                color: AppColors.of(context).textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewContent() {
    final preview = _preview;
    if (preview == null) return const SizedBox.shrink();

    final colors = AppColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header text
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Text(
            context.l10n.importReadyFrom(_getSourceDisplayName()),
            style: AppTypography.body.copyWith(
              color: colors.textPrimary,
            ),
          ),
        ),

        // Recipe count
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(
            context.l10n.importRecipeCount(preview.recipeCount),
            style: AppTypography.h3.copyWith(
              color: colors.textPrimary,
            ),
          ),
        ),

        SizedBox(height: AppSpacing.sm),

        // Tags count
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(
            context.l10n.importTagCount(preview.tagNames.length, preview.newTagNames.length, preview.existingTagNames.length),
            style: AppTypography.body.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ),

        SizedBox(height: AppSpacing.sm),

        // Folders count
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(
            context.l10n.importFolderCount(preview.folderNames.length, preview.newFolderNames.length, preview.existingFolderNames.length),
            style: AppTypography.body.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ),

        SizedBox(height: AppSpacing.xl),

        // Paprika categories option (if applicable)
        if (preview.hasPaprikaCategories) ...[
          SettingsGroupCondensed(
            header: context.l10n.importPaprikaCategoriesHeader,
            footer: context.l10n.importPaprikaCategoriesFooter,
            children: [
              AppRadioButtonRowCondensed(
                label: context.l10n.importAsTags,
                selected: _paprikaCategoriesAsTags,
                onTap: () {
                  setState(() {
                    _paprikaCategoriesAsTags = true;
                  });
                },
                first: true,
                last: false,
                grouped: true,
              ),
              AppRadioButtonRowCondensed(
                label: context.l10n.importAsFolders,
                selected: !_paprikaCategoriesAsTags,
                onTap: () {
                  setState(() {
                    _paprikaCategoriesAsTags = false;
                  });
                },
                first: false,
                last: true,
                grouped: true,
              ),
            ],
          ),
          SizedBox(height: AppSpacing.xl),
        ],

        // Extra spacing before button
        SizedBox(height: AppSpacing.xxl),

        // Import button
        Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: AppButtonVariants.primaryFilled(
            text: context.l10n.importButton,
            onPressed: _isLoading ? null : _executeImport,
            size: AppButtonSize.large,
            shape: AppButtonShape.square,
            fullWidth: true,
          ),
        ),

        // Bottom safe area
        SizedBox(height: AppSpacing.xxl),
      ],
    );
  }

  String _getSourceDisplayName() {
    return switch (widget.source) {
      ImportSource.stockpot => 'Stockpot',
      ImportSource.paprika => 'Paprika',
      ImportSource.crouton => 'Crouton',
    };
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveSliverPage(
      title: context.l10n.importPreviewTitle,
      automaticallyImplyLeading: true,
      body: _isLoading
          ? _buildLoadingState()
          : _error != null
              ? _buildErrorState()
              : _buildPreviewContent(),
    );
  }
}
