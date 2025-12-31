import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart' as compress;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:nanoid/nanoid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import '../../../../database/database.dart';
import '../../../../database/models/ingredients.dart';
import '../../../../database/models/recipe_images.dart';
import '../../../../database/models/steps.dart' as db;
import '../../../mobile/adaptive_app.dart' show globalRootNavigatorKey;
import '../../../providers/subscription_provider.dart';
import '../../../services/content_extraction/generic_web_extractor.dart';
import '../../../services/logging/app_logger.dart';
import '../../../services/web_extraction_service.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../widgets/app_circle_button.dart';
import '../../clippings/models/extracted_recipe.dart';
import '../../clippings/models/recipe_preview.dart';
import '../../clippings/providers/preview_usage_provider.dart';
import '../../recipes/views/add_recipe_modal.dart';
import '../../share/widgets/share_recipe_preview_result.dart';

/// Default URL for the Discover browser
const String _defaultUrl = 'https://stockpot.app/discover/';

/// Discover page with embedded browser for recipe discovery
class DiscoverPage extends ConsumerStatefulWidget {
  final VoidCallback? onMenuPressed;

  const DiscoverPage({
    super.key,
    this.onMenuPressed,
  });

  @override
  ConsumerState<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends ConsumerState<DiscoverPage> {
  InAppWebViewController? _webViewController;
  int _loadingProgress = 100;
  bool _canGoBack = false;
  bool _canGoForward = false;
  bool _isImporting = false;

  // Address bar controller
  late TextEditingController _urlController;
  final FocusNode _urlFocusNode = FocusNode();

  // Extraction tools
  final _genericExtractor = GenericWebExtractor();

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: _defaultUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    _urlFocusNode.dispose();
    super.dispose();
  }

  void _updateUrlBar(String url) {
    // Only update controller if not focused (user isn't typing)
    if (!_urlFocusNode.hasFocus) {
      _urlController.text = url;
    }
  }

  void _navigateToUrl(String input) {
    var url = input.trim();
    if (url.isEmpty) return;

    // Add https:// if no protocol specified
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      // Check if it looks like a URL or a search query
      if (url.contains('.') && !url.contains(' ')) {
        url = 'https://$url';
      } else {
        // Treat as search query
        url = 'https://www.google.com/search?q=${Uri.encodeComponent(url)}';
      }
    }

    _webViewController?.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
    _urlFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Discover'),
        leading: isTablet
            ? null
            : GestureDetector(
                onTap: widget.onMenuPressed,
                child: const Icon(CupertinoIcons.bars),
              ),
        backgroundColor: colors.background,
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Address bar
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: colors.background,
                border: Border(
                  bottom: BorderSide(
                    color: colors.border,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: CupertinoTextField(
                      controller: _urlController,
                      focusNode: _urlFocusNode,
                      placeholder: 'Enter URL or search',
                      prefix: Padding(
                        padding: EdgeInsets.only(left: AppSpacing.sm),
                        child: Icon(
                          CupertinoIcons.globe,
                          size: 16,
                          color: colors.textSecondary,
                        ),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      style: AppTypography.bodySmall.copyWith(
                        color: colors.textPrimary,
                      ),
                      placeholderStyle: AppTypography.bodySmall.copyWith(
                        color: colors.textSecondary,
                      ),
                      keyboardType: TextInputType.url,
                      textInputAction: TextInputAction.go,
                      autocorrect: false,
                      onSubmitted: _navigateToUrl,
                      onTap: () {
                        // Select all text when tapped for easy replacement
                        _urlController.selection = TextSelection(
                          baseOffset: 0,
                          extentOffset: _urlController.text.length,
                        );
                      },
                    ),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  GestureDetector(
                    onTap: () => _webViewController?.reload(),
                    child: Icon(
                      CupertinoIcons.refresh,
                      color: CupertinoTheme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),

            // WebView
            Expanded(
              child: InAppWebView(
                initialUrlRequest: URLRequest(url: WebUri(_defaultUrl)),
                initialSettings: InAppWebViewSettings(
                  javaScriptEnabled: true,
                  allowsBackForwardNavigationGestures: true,
                  userAgent:
                      'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) '
                      'AppleWebKit/605.1.15 (KHTML, like Gecko) '
                      'Version/17.0 Mobile/15E148 Safari/604.1',
                ),
                onWebViewCreated: (controller) {
                  _webViewController = controller;
                },
                onLoadStart: (controller, url) {
                  setState(() {
                    _loadingProgress = 0;
                    if (url != null) {
                      _updateUrlBar(url.toString());
                    }
                  });
                },
                onLoadStop: (controller, url) async {
                  setState(() {
                    _loadingProgress = 100;
                    if (url != null) {
                      _updateUrlBar(url.toString());
                    }
                  });
                  await _updateNavigationState();
                },
                onProgressChanged: (controller, progress) {
                  setState(() {
                    _loadingProgress = progress;
                  });
                },
                onUpdateVisitedHistory: (controller, url, androidIsReload) async {
                  if (url != null) {
                    setState(() {
                      _updateUrlBar(url.toString());
                    });
                  }
                  await _updateNavigationState();
                },
              ),
            ),

            // Bottom bar
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: colors.background,
                border: Border(
                  top: BorderSide(
                    color: colors.border,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Back button
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _canGoBack ? _goBack : null,
                      child: Icon(
                        CupertinoIcons.chevron_left,
                        size: 28,
                        color: _canGoBack
                            ? CupertinoTheme.of(context).primaryColor
                            : colors.textSecondary.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  // Forward button
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _canGoForward ? _goForward : null,
                      child: Icon(
                        CupertinoIcons.chevron_right,
                        size: 28,
                        color: _canGoForward
                            ? CupertinoTheme.of(context).primaryColor
                            : colors.textSecondary.withValues(alpha: 0.5),
                      ),
                    ),
                  ),

                  // Progress bar in the middle
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: _loadingProgress < 100
                          ? LinearProgressIndicator(
                              value: _loadingProgress / 100,
                              backgroundColor: colors.border,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                CupertinoTheme.of(context).primaryColor,
                              ),
                              minHeight: 2,
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),

                  // Import Recipe button
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _isImporting ? null : _onImportRecipe,
                    child: _isImporting
                        ? const CupertinoActivityIndicator(radius: 12)
                        : Text(
                            'Import Recipe',
                            style: AppTypography.bodyLarge.copyWith(
                              color: CupertinoTheme.of(context).primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateNavigationState() async {
    if (_webViewController == null) return;

    final canGoBack = await _webViewController!.canGoBack();
    final canGoForward = await _webViewController!.canGoForward();

    if (mounted) {
      setState(() {
        _canGoBack = canGoBack;
        _canGoForward = canGoForward;
      });
    }
  }

  Future<void> _goBack() async {
    await _webViewController?.goBack();
    // Small delay to let navigation complete before checking state
    await Future.delayed(const Duration(milliseconds: 100));
    await _updateNavigationState();
  }

  Future<void> _goForward() async {
    await _webViewController?.goForward();
    // Small delay to let navigation complete before checking state
    await Future.delayed(const Duration(milliseconds: 100));
    await _updateNavigationState();
  }

  /// Handle Import Recipe button tap
  Future<void> _onImportRecipe() async {
    if (_webViewController == null) return;

    setState(() {
      _isImporting = true;
    });

    try {
      // Check connectivity first
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        if (mounted) {
          _showError('You\'re offline. Please check your internet connection and try again.');
        }
        return;
      }

      // Get HTML and URL from webview
      final html = await _webViewController!.getHtml();
      final url = await _webViewController!.getUrl();

      if (html == null || html.isEmpty) {
        if (mounted) {
          _showError('Could not read page content. Please try again.');
        }
        return;
      }

      final sourceUrl = url?.toString();
      AppLogger.info('Discover: Extracting recipe from ${sourceUrl ?? 'unknown URL'}');

      // Try JSON-LD extraction first (free, local)
      final result = await _genericExtractor.extractFromHtml(
        html,
        sourceUrl: sourceUrl,
      );

      if (!mounted) return;

      if (result.recipe != null && result.isFromJsonLd) {
        // JSON-LD recipe found
        AppLogger.info('Discover: JSON-LD recipe found');
        await _handleJsonLdRecipe(result);
      } else if (result.hasHtml) {
        // No JSON-LD - need backend extraction
        AppLogger.info('Discover: No JSON-LD, using backend extraction');
        await _handleBackendExtraction(result);
      } else {
        _showError('No content available to extract.');
      }
    } catch (e, stack) {
      AppLogger.error('Discover: Import failed', e, stack);
      if (mounted) {
        _showError('Something went wrong while importing.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }

  /// Handle JSON-LD extracted recipe (free for all users)
  ///
  /// JSON-LD extraction is completely free since it's local parsing with no API cost.
  /// All users can import these directly without subscription check.
  Future<void> _handleJsonLdRecipe(WebExtractionResult result) async {
    AppLogger.info('Discover: JSON-LD recipe - opening editor (free for all users)');
    await _openRecipeEditor(result.recipe!, result.imageUrl);
  }

  /// Handle backend extraction (requires Plus or preview)
  Future<void> _handleBackendExtraction(WebExtractionResult result) async {
    final hasPlus = ref.read(effectiveHasPlusProvider);

    if (hasPlus) {
      // Plus user - full extraction
      await _performFullExtraction(result);
    } else {
      // Free user - check preview limit
      final usageService = await ref.read(previewUsageServiceProvider.future);

      if (!usageService.hasShareRecipePreviewsRemaining()) {
        // Limit exceeded - show paywall
        if (!mounted) return;
        final purchased = await ref.read(subscriptionProvider.notifier).presentPaywall(context);
        if (purchased && mounted) {
          await _performFullExtraction(result);
        }
        return;
      }

      // Show preview
      await _performPreviewExtraction(result);
    }
  }

  /// Perform full backend extraction for Plus users
  Future<void> _performFullExtraction(WebExtractionResult result) async {
    if (!result.hasHtml) {
      _showError('No content available to extract.');
      return;
    }

    try {
      final service = ref.read(webExtractionServiceProvider);
      final recipe = await service.extractRecipe(
        html: result.html!,
        sourceUrl: result.sourceUrl,
      );

      if (!mounted) return;

      if (recipe == null) {
        _showError('This page doesn\'t appear to contain recipe information.\n\nTry navigating to a recipe page.');
        return;
      }

      await _openRecipeEditor(recipe, result.imageUrl);
    } on WebExtractionException catch (e) {
      if (mounted) {
        _showError(e.message);
      }
    }
  }

  /// Perform preview extraction for non-Plus users
  Future<void> _performPreviewExtraction(WebExtractionResult result) async {
    if (!result.hasHtml) {
      _showError('This page requires Plus subscription for recipe extraction.');
      return;
    }

    try {
      final service = ref.read(webExtractionServiceProvider);
      final preview = await service.previewRecipe(
        html: result.html!,
        sourceUrl: result.sourceUrl,
      );

      if (!mounted) return;

      if (preview == null) {
        _showError('This page doesn\'t appear to contain recipe information.\n\nTry navigating to a recipe page.');
        return;
      }

      // Increment usage counter
      final usageService = await ref.read(previewUsageServiceProvider.future);
      await usageService.incrementShareRecipeUsage();

      if (mounted) {
        _showPreviewSheet(preview, result);
      }
    } on WebExtractionException catch (e) {
      if (mounted) {
        _showError(e.message);
      }
    }
  }

  /// Show preview sheet for non-Plus users
  void _showPreviewSheet(RecipePreview preview, WebExtractionResult result) {
    WoltModalSheet.show<void>(
      context: context,
      useRootNavigator: true,
      useSafeArea: false,
      pageListBuilder: (sheetContext) => [
        WoltModalSheetPage(
          navBarHeight: 55,
          backgroundColor: AppColors.of(sheetContext).background,
          surfaceTintColor: Colors.transparent,
          hasTopBarLayer: false,
          isTopBarLayerAlwaysVisible: false,
          trailingNavBarWidget: Padding(
            padding: EdgeInsets.only(right: AppSpacing.lg),
            child: AppCircleButton(
              icon: AppCircleButtonIcon.close,
              variant: AppCircleButtonVariant.neutral,
              size: 32,
              onPressed: () {
                Navigator.of(sheetContext, rootNavigator: true).pop();
              },
            ),
          ),
          child: ShareRecipePreviewResultContent(
            preview: preview,
            onSubscribe: () async {
              if (!context.mounted) return;

              final purchased = await ref
                  .read(subscriptionProvider.notifier)
                  .presentPaywall(context);

              if (purchased && context.mounted) {
                // Close preview sheet
                if (sheetContext.mounted) {
                  Navigator.of(sheetContext, rootNavigator: true).pop();
                }

                // Check if we have JSON-LD recipe or need backend
                if (result.recipe != null && result.isFromJsonLd) {
                  await _openRecipeEditor(result.recipe!, result.imageUrl);
                } else {
                  // Need to get HTML again and do backend extraction
                  final rootContext = globalRootNavigatorKey.currentContext;
                  if (rootContext != null && rootContext.mounted) {
                    await _performPostSubscriptionExtraction(rootContext, result);
                  }
                }
              }
            },
          ),
        ),
      ],
    );
  }

  /// Perform extraction after user subscribes from preview
  Future<void> _performPostSubscriptionExtraction(
    BuildContext context,
    WebExtractionResult originalResult,
  ) async {
    // State for the extraction modal
    var isExtracting = true;
    String? errorMessage;

    if (!context.mounted) return;

    await WoltModalSheet.show<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      modalTypeBuilder: (_) => WoltModalType.alertDialog(),
      pageListBuilder: (modalContext) => [
        WoltModalSheetPage(
          navBarHeight: 0,
          hasTopBarLayer: false,
          backgroundColor: AppColors.of(modalContext).background,
          surfaceTintColor: Colors.transparent,
          child: StatefulBuilder(
            builder: (builderContext, setModalState) {
              if (isExtracting && errorMessage == null) {
                Future.microtask(() async {
                  try {
                    final service = ref.read(webExtractionServiceProvider);
                    final recipe = await service.extractRecipe(
                      html: originalResult.html!,
                      sourceUrl: originalResult.sourceUrl,
                    );

                    if (!modalContext.mounted) return;

                    if (recipe == null) {
                      setModalState(() {
                        isExtracting = false;
                        errorMessage = 'No recipe found on this page.';
                      });
                      return;
                    }

                    // Download image if available
                    RecipeImage? coverImage;
                    final imageUrl = originalResult.imageUrl;
                    if (imageUrl != null && imageUrl.isNotEmpty) {
                      coverImage = await _downloadAndSaveImage(imageUrl);
                    }

                    if (!modalContext.mounted) return;

                    Navigator.of(modalContext, rootNavigator: true).pop();

                    if (context.mounted) {
                      final recipeEntry = _convertToRecipeEntry(
                        recipe,
                        coverImage: coverImage,
                      );
                      showRecipeEditorModal(
                        context,
                        ref: ref,
                        recipe: recipeEntry,
                        isEditing: false,
                      );
                    }
                  } on WebExtractionException catch (e) {
                    if (modalContext.mounted) {
                      setModalState(() {
                        isExtracting = false;
                        errorMessage = e.message;
                      });
                    }
                  } catch (e) {
                    AppLogger.error('Post-subscription extraction failed', e);
                    if (modalContext.mounted) {
                      setModalState(() {
                        isExtracting = false;
                        errorMessage = 'Failed to extract recipe. Please try again.';
                      });
                    }
                  }
                });
              }

              if (isExtracting && errorMessage == null) {
                return Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Importing Recipe',
                            style: AppTypography.h4.copyWith(
                              color: AppColors.of(builderContext).textPrimary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.xxl),
                      const CupertinoActivityIndicator(radius: 16),
                      SizedBox(height: AppSpacing.lg),
                      Text(
                        'Extracting recipe...',
                        style: AppTypography.body.copyWith(
                          color: AppColors.of(builderContext).textSecondary,
                        ),
                      ),
                      SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                );
              } else {
                // Error state
                return Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Extraction Failed',
                            style: AppTypography.h4.copyWith(
                              color: AppColors.of(builderContext).textPrimary,
                            ),
                          ),
                          AppCircleButton(
                            icon: AppCircleButtonIcon.close,
                            variant: AppCircleButtonVariant.neutral,
                            size: 32,
                            onPressed: () => Navigator.of(
                              modalContext,
                              rootNavigator: true,
                            ).pop(),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.lg),
                      Text(
                        errorMessage ?? 'An error occurred.',
                        style: AppTypography.body.copyWith(
                          color: AppColors.of(builderContext).textSecondary,
                        ),
                      ),
                      SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  /// Open recipe editor with extracted recipe
  Future<void> _openRecipeEditor(ExtractedRecipe recipe, String? imageUrl) async {
    // Download image if available
    RecipeImage? coverImage;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      AppLogger.info('Discover: Downloading image from $imageUrl');
      coverImage = await _downloadAndSaveImage(imageUrl);
    }

    if (!mounted) return;

    final recipeEntry = _convertToRecipeEntry(recipe, coverImage: coverImage);
    showRecipeEditorModal(
      context,
      ref: ref,
      recipe: recipeEntry,
      isEditing: false,
    );
  }

  /// Show error message
  void _showError(String message) {
    if (!mounted) return;

    WoltModalSheet.show<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      modalTypeBuilder: (_) => WoltModalType.alertDialog(),
      pageListBuilder: (modalContext) => [
        WoltModalSheetPage(
          navBarHeight: 0,
          hasTopBarLayer: false,
          backgroundColor: AppColors.of(modalContext).background,
          surfaceTintColor: Colors.transparent,
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Import Failed',
                      style: AppTypography.h4.copyWith(
                        color: AppColors.of(modalContext).textPrimary,
                      ),
                    ),
                    AppCircleButton(
                      icon: AppCircleButtonIcon.close,
                      variant: AppCircleButtonVariant.neutral,
                      size: 32,
                      onPressed: () => Navigator.of(
                        modalContext,
                        rootNavigator: true,
                      ).pop(),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.lg),
                Text(
                  message,
                  style: AppTypography.body.copyWith(
                    color: AppColors.of(modalContext).textSecondary,
                  ),
                ),
                SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ],
    ).then((_) {
      // Workaround for iOS 18.x bug where WebView taps stop working after modal
      // See: https://github.com/pichillilorenzo/flutter_inappwebview/issues/2415
      _webViewController?.reload();
    });
  }

  /// Compress an image file to the specified size
  Future<File> _compressImage(File file, String fileName, {int size = 1280}) async {
    final directory = await getTemporaryDirectory();
    final targetPath = '${directory.path}/compressed_$fileName';

    final compressedFile = await compress.FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 90,
      minWidth: size,
      minHeight: size,
      format: compress.CompressFormat.jpeg,
    );

    return compressedFile != null ? File(compressedFile.path) : file;
  }

  /// Download an image from URL, compress it, and save locally
  Future<RecipeImage?> _downloadAndSaveImage(String imageUrl) async {
    try {
      final uri = Uri.parse(imageUrl);
      AppLogger.info('Downloading image from ${uri.host}');

      final response = await http.get(uri).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Image download timed out');
        },
      );
      if (response.statusCode != 200) {
        AppLogger.warning('Failed to download image: HTTP ${response.statusCode}');
        return null;
      }

      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.startsWith('image/')) {
        AppLogger.warning('URL returned non-image content: $contentType');
        return null;
      }

      if (response.bodyBytes.isEmpty) {
        AppLogger.warning('URL returned empty response');
        return null;
      }

      // Save to temp file
      final tempDir = await getTemporaryDirectory();
      final imageUuid = const Uuid().v4();
      final tempFile = File('${tempDir.path}/$imageUuid.jpg');
      await tempFile.writeAsBytes(response.bodyBytes);

      // Compress
      final fullFileName = '$imageUuid.jpg';
      final smallFileName = '${imageUuid}_small.jpg';

      final compressedFull = await _compressImage(tempFile, fullFileName);
      final compressedSmall = await _compressImage(tempFile, smallFileName, size: 512);

      // Save to documents directory
      final docsDir = await getApplicationDocumentsDirectory();
      final fullPath = '${docsDir.path}/$fullFileName';
      final smallPath = '${docsDir.path}/$smallFileName';
      await compressedFull.copy(fullPath);
      await compressedSmall.copy(smallPath);

      // Clean up temp files
      try {
        if (await tempFile.exists()) await tempFile.delete();
        if (await compressedFull.exists()) await compressedFull.delete();
        if (await compressedSmall.exists()) await compressedSmall.delete();
      } catch (_) {}

      AppLogger.info('Image saved locally: $fullFileName');

      return RecipeImage(
        id: nanoid(10),
        fileName: fullFileName,
        isCover: true,
      );
    } catch (e, stack) {
      AppLogger.warning('Failed to download image: $e', e, stack);
      return null;
    }
  }

  /// Convert ExtractedRecipe to RecipeEntry for the editor
  RecipeEntry _convertToRecipeEntry(
    ExtractedRecipe extracted, {
    RecipeImage? coverImage,
  }) {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    const uuid = Uuid();

    final ingredients = extracted.ingredients.map((e) {
      return Ingredient(
        id: uuid.v4(),
        type: e.type,
        name: e.name,
        isCanonicalised: false,
      );
    }).toList();

    final steps = extracted.steps.map((e) {
      return db.Step(
        id: uuid.v4(),
        type: e.type,
        text: e.text,
      );
    }).toList();

    return RecipeEntry(
      id: uuid.v4(),
      title: extracted.title,
      description: extracted.description,
      language: 'en',
      userId: userId,
      servings: extracted.servings,
      prepTime: extracted.prepTime,
      cookTime: extracted.cookTime,
      source: extracted.source,
      ingredients: ingredients,
      steps: steps,
      images: coverImage != null ? [coverImage] : null,
      folderIds: [],
      pinned: 0,
      pinnedAt: null,
    );
  }
}
