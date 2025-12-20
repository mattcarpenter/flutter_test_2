import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/clippings_provider.dart';
import '../../../repositories/clippings_repository.dart';
import '../../../services/logging/app_logger.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../widgets/adaptive_pull_down/adaptive_menu_item.dart';
import '../../../widgets/adaptive_pull_down/adaptive_pull_down.dart';
import '../../../widgets/app_circle_button.dart';
import '../widgets/link_modal.dart';
import 'clipping_extraction_modal.dart';

class ClippingEditorPage extends ConsumerStatefulWidget {
  final String clippingId;

  const ClippingEditorPage({
    super.key,
    required this.clippingId,
  });

  @override
  ConsumerState<ClippingEditorPage> createState() => _ClippingEditorPageState();
}

class _ClippingEditorPageState extends ConsumerState<ClippingEditorPage>
    with WidgetsBindingObserver {
  late TextEditingController _titleController;
  late quill.QuillController _contentController;
  late FocusNode _titleFocusNode;
  late FocusNode _contentFocusNode;
  late ScrollController _scrollController;

  Timer? _saveDebounceTimer;
  bool _isDirty = false;
  bool _isSaving = false;
  bool _isLoaded = false;

  // Key for the editor to find its render box for scroll calculations
  final GlobalKey _editorKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _titleController = TextEditingController();
    _contentController = quill.QuillController.basic();
    _titleFocusNode = FocusNode();
    _contentFocusNode = FocusNode();
    _scrollController = ScrollController();

    _titleController.addListener(_onTextChanged);
    _contentController.addListener(_onTextChanged);
    _contentController.onSelectionChanged = _onSelectionChanged;

    // Listen to focus changes to update toolbar visibility
    _titleFocusNode.addListener(_onFocusChanged);
    _contentFocusNode.addListener(_onFocusChanged);

    _loadClipping();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveDebounceTimer?.cancel();

    // Save any pending changes before dispose
    if (_isDirty && !_isSaving) {
      _saveChangesSync();
    }

    _titleController.removeListener(_onTextChanged);
    _contentController.removeListener(_onTextChanged);
    _titleFocusNode.removeListener(_onFocusChanged);
    _contentFocusNode.removeListener(_onFocusChanged);

    _titleController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    // Trigger rebuild to update toolbar visibility
    setState(() {});
  }

  void _onSelectionChanged(TextSelection selection) {
    // Scroll to keep cursor visible when selection changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCursor();
    });
  }

  void _scrollToCursor() {
    final editorContext = _editorKey.currentContext;
    if (editorContext == null) return;

    final scrollableState = Scrollable.maybeOf(editorContext);
    if (scrollableState == null) return;

    // Find the editor's render box
    final renderBox = editorContext.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    // Get cursor rectangle from Quill
    final cursorRect = _contentController.selection.isCollapsed
        ? _getCursorRect()
        : null;

    if (cursorRect != null) {
      // Convert cursor position to scroll view coordinates
      final scrollPosition = _scrollController.position;
      final viewportHeight = scrollPosition.viewportDimension;
      final editorOffset = renderBox.localToGlobal(Offset.zero);

      // Calculate cursor position relative to scroll view
      final cursorGlobalY = editorOffset.dy + cursorRect.bottom;
      final scrollViewRenderBox = _scrollController.position.context.storageContext
          .findRenderObject() as RenderBox?;

      if (scrollViewRenderBox != null) {
        final scrollViewOffset = scrollViewRenderBox.localToGlobal(Offset.zero);
        final cursorRelativeY = cursorGlobalY - scrollViewOffset.dy;

        // Add some padding so cursor isn't right at the edge
        const padding = 60.0;

        // Check if cursor is below visible area
        if (cursorRelativeY > viewportHeight - padding) {
          final scrollAmount = cursorRelativeY - (viewportHeight - padding);
          final newOffset = (_scrollController.offset + scrollAmount)
              .clamp(0.0, scrollPosition.maxScrollExtent);
          _scrollController.animateTo(
            newOffset,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
        }
        // Check if cursor is above visible area
        else if (cursorRelativeY < padding) {
          final scrollAmount = padding - cursorRelativeY;
          final newOffset = (_scrollController.offset - scrollAmount)
              .clamp(0.0, scrollPosition.maxScrollExtent);
          _scrollController.animateTo(
            newOffset,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
        }
      }
    }
  }

  Rect? _getCursorRect() {
    // Estimate cursor position based on document length and line height
    // This is a simplified calculation - Quill doesn't expose exact cursor rect easily
    final selection = _contentController.selection;
    if (!selection.isValid || !selection.isCollapsed) return null;

    // Rough estimate: count newlines before cursor to estimate vertical position
    final plainText = _contentController.document.toPlainText();
    final textBeforeCursor = plainText.substring(
      0,
      selection.baseOffset.clamp(0, plainText.length),
    );
    final lineCount = '\n'.allMatches(textBeforeCursor).length;

    // Estimate line height (this should match the editor's line height)
    const estimatedLineHeight = 24.0; // bodyLarge with height 1.5

    return Rect.fromLTWH(
      0,
      lineCount * estimatedLineHeight,
      1,
      estimatedLineHeight,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Save when app goes to background
    if (state == AppLifecycleState.paused && _isDirty) {
      _saveChanges();
    }
  }

  Future<void> _loadClipping() async {
    try {
      final clipping =
          await ref.read(clippingsRepositoryProvider).getClipping(widget.clippingId);
      if (clipping != null && mounted) {
        setState(() {
          _titleController.text = clipping.title ?? '';
          _loadQuillContent(clipping.content);
          _isLoaded = true;
        });
      }
    } catch (e) {
      AppLogger.error('Failed to load clipping', e);
    }
  }

  void _loadQuillContent(String? content) {
    if (content != null && content.isNotEmpty) {
      try {
        final json = jsonDecode(content) as List<dynamic>;
        _contentController = quill.QuillController(
          document: quill.Document.fromJson(json),
          selection: const TextSelection.collapsed(offset: 0),
        );
        _contentController.addListener(_onTextChanged);
        _contentController.onSelectionChanged = _onSelectionChanged;
      } catch (e) {
        AppLogger.debug('Failed to parse Quill delta, treating as plain text: $e');
        // If parsing fails, treat as plain text
        _contentController = quill.QuillController.basic();
        _contentController.document.insert(0, content);
        _contentController.addListener(_onTextChanged);
        _contentController.onSelectionChanged = _onSelectionChanged;
      }
    }
  }

  void _onTextChanged() {
    if (!_isLoaded) return;

    _isDirty = true;
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = Timer(const Duration(milliseconds: 1000), _saveChanges);
  }

  String _extractTitle() {
    final titleText = _titleController.text.trim();
    if (titleText.isNotEmpty) {
      return titleText;
    }
    // Extract from content (first few words)
    final plainText = _contentController.document.toPlainText().trim();
    final words = plainText.split(' ').take(6).join(' ');
    if (words.isEmpty) return '';
    return words.length > 50 ? '${words.substring(0, 50)}...' : words;
  }

  Future<void> _saveChanges() async {
    if (!_isDirty || _isSaving) return;

    _isSaving = true;

    try {
      final title = _extractTitle();
      final deltaJson = _contentController.document.toDelta().toJson();
      final content = jsonEncode(deltaJson);

      await ref.read(clippingsProvider.notifier).updateClipping(
            id: widget.clippingId,
            title: title.isEmpty ? null : title,
            content: content,
          );

      _isDirty = false;
      AppLogger.debug('Auto-saved clipping: ${widget.clippingId}');
    } catch (e) {
      AppLogger.error('Failed to auto-save clipping', e);
    } finally {
      _isSaving = false;
    }
  }

  void _saveChangesSync() {
    // Synchronous save for dispose - best effort
    final title = _extractTitle();
    final deltaJson = _contentController.document.toDelta().toJson();
    final content = jsonEncode(deltaJson);

    ref.read(clippingsProvider.notifier).updateClipping(
          id: widget.clippingId,
          title: title.isEmpty ? null : title,
          content: content,
        );
  }

  void _dismissKeyboard() {
    _titleFocusNode.unfocus();
    _contentFocusNode.unfocus();
  }

  void _deleteClipping() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Clipping'),
        content: const Text('Are you sure you want to delete this clipping?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Delete'),
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(clippingsProvider.notifier).deleteClipping(widget.clippingId);
              context.pop();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showLinkModal(BuildContext context) async {
    // Get current selection info
    final initialTextLink = quill.QuillTextLink.prepare(_contentController);

    final result = await showLinkModal(
      context,
      initialText: initialTextLink.text,
      initialLink: initialTextLink.link,
    );

    if (result != null) {
      result.submit(_contentController);
    }
  }

  /// Returns true if the software keyboard is currently visible
  bool _isKeyboardVisible(BuildContext context) {
    // Register dependency on MediaQuery to trigger rebuilds when keyboard appears/disappears
    // (we don't use this value directly because Scaffold sets viewInsets.bottom to 0)
    MediaQuery.of(context);

    // Get raw system view insets, bypassing Scaffold's MediaQuery modifications
    final viewInsets = MediaQueryData.fromView(View.of(context)).viewInsets;
    return viewInsets.bottom > 0;
  }

  /// Returns true if any text field is focused
  bool get _isAnyFieldFocused => _titleFocusNode.hasFocus || _contentFocusNode.hasFocus;

  @override
  Widget build(BuildContext context) {
    final keyboardVisible = _isKeyboardVisible(context);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        // Wrap in ListenableBuilder to rebuild when content changes
        trailing: ListenableBuilder(
          listenable: _contentController,
          builder: (context, _) => _buildTrailingButton(context, keyboardVisible),
        ),
        backgroundColor: AppColors.of(context).background,
        border: null,
      ),
      backgroundColor: AppColors.of(context).background,
      child: SafeArea(
        child: Material(
          color: Colors.transparent,
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: () {
                        // Tapping empty area focuses content
                        if (!_contentFocusNode.hasFocus && !_titleFocusNode.hasFocus) {
                          _contentFocusNode.requestFocus();
                        }
                      },
                      behavior: HitTestBehavior.opaque,
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        padding: EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title field
                            TextField(
                              controller: _titleController,
                              focusNode: _titleFocusNode,
                              style: AppTypography.h1.copyWith(
                                color: AppColors.of(context).textPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Title',
                                hintStyle: AppTypography.h1.copyWith(
                                  color: AppColors.of(context).textTertiary,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              maxLines: null,
                              keyboardType: TextInputType.text,
                              textInputAction: TextInputAction.next,
                              onSubmitted: (_) {
                                _contentFocusNode.requestFocus();
                              },
                            ),

                            SizedBox(height: AppSpacing.md),

                            // Quill editor - wrap in Theme to override Material defaults
                            Theme(
                              key: _editorKey,
                              data: Theme.of(context).copyWith(
                                iconTheme: IconThemeData(
                                  color: AppColors.of(context).textPrimary,
                                ),
                                checkboxTheme: CheckboxThemeData(
                                  checkColor: WidgetStateProperty.all(AppColors.of(context).background),
                                  fillColor: WidgetStateProperty.resolveWith((states) {
                                    if (states.contains(WidgetState.selected)) {
                                      return AppColors.of(context).textPrimary;
                                    }
                                    return Colors.transparent;
                                  }),
                                  side: BorderSide(
                                    color: AppColors.of(context).textSecondary,
                                    width: 1.5,
                                  ),
                                ),
                                textTheme: Theme.of(context).textTheme.copyWith(
                                  bodyMedium: TextStyle(color: AppColors.of(context).textPrimary),
                                  bodyLarge: TextStyle(color: AppColors.of(context).textPrimary),
                                ),
                              ),
                              child: quill.QuillEditor.basic(
                                controller: _contentController,
                                focusNode: _contentFocusNode,
                                config: quill.QuillEditorConfig(
                                  placeholder: 'Start typing...',
                                  padding: EdgeInsets.zero,
                                  autoFocus: false,
                                  expands: false,
                                  scrollable: false,
                                  requestKeyboardFocusOnCheckListChanged: false,
                                  customStyles: quill.DefaultStyles(
                                    paragraph: quill.DefaultTextBlockStyle(
                                      AppTypography.bodyLarge.copyWith(
                                        color: AppColors.of(context).textPrimary,
                                        height: 1.5,
                                      ),
                                      quill.HorizontalSpacing.zero,
                                      quill.VerticalSpacing.zero,
                                      quill.VerticalSpacing.zero,
                                      null,
                                    ),
                                    lists: quill.DefaultListBlockStyle(
                                      AppTypography.bodyLarge.copyWith(
                                        color: AppColors.of(context).textPrimary,
                                        height: 1.5,
                                      ),
                                      quill.HorizontalSpacing.zero,
                                      quill.VerticalSpacing.zero,
                                      quill.VerticalSpacing.zero,
                                      null,
                                      // Custom checkbox builder to match our theme
                                      _ClippingCheckboxBuilder(AppColors.of(context).textPrimary),
                                    ),
                                    leading: quill.DefaultTextBlockStyle(
                                      AppTypography.bodyLarge.copyWith(
                                        color: AppColors.of(context).textPrimary,
                                        height: 1.5,
                                      ),
                                      quill.HorizontalSpacing.zero,
                                      quill.VerticalSpacing.zero,
                                      quill.VerticalSpacing.zero,
                                      null,
                                    ),
                                    placeHolder: quill.DefaultTextBlockStyle(
                                      AppTypography.bodyLarge.copyWith(
                                        color: AppColors.of(context).textTertiary,
                                        height: 1.5,
                                      ),
                                      quill.HorizontalSpacing.zero,
                                      quill.VerticalSpacing.zero,
                                      quill.VerticalSpacing.zero,
                                      null,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Fade gradient at bottom
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: IgnorePointer(
                        child: Container(
                          height: 32,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.of(context).background.withValues(alpha: 0),
                                AppColors.of(context).background,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Conversion buttons - wrapped in ListenableBuilder to rebuild when content changes
              ListenableBuilder(
                listenable: _contentController,
                builder: (context, child) => _buildConversionButtons(context),
              ),

              // Toolbar (shown when any text field is focused - works with hardware keyboard too)
              if (_isAnyFieldFocused)
                _buildToolbar(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Extracts plain text from the Quill content
  String _getContentAsPlainText() {
    return _contentController.document.toPlainText().trim();
  }

  /// Returns true if the content has meaningful text
  bool _hasContent() {
    return _getContentAsPlainText().isNotEmpty;
  }

  /// Handles the Convert to Recipe button tap
  void _handleConvertToRecipe() {
    final title = _titleController.text;
    final body = _getContentAsPlainText();

    showRecipeExtractionModal(
      context,
      ref,
      title: title,
      body: body,
    );
  }

  /// Handles the To Shopping List button tap
  void _handleAddToShoppingList() {
    final title = _titleController.text;
    final body = _getContentAsPlainText();

    showShoppingListExtractionModal(
      context,
      ref,
      title: title,
      body: body,
    );
  }

  Widget _buildConversionButtons(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final hasContent = _hasContent();

    Widget buttonRow = Row(
      children: [
        Expanded(
          child: _buildConversionButton(
            context: context,
            text: 'Convert to Recipe',
            icon: CupertinoIcons.sparkles,
            onPressed: hasContent ? _handleConvertToRecipe : null,
            enabled: hasContent,
          ),
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: _buildConversionButton(
            context: context,
            text: 'To Shopping List',
            icon: CupertinoIcons.list_bullet,
            onPressed: hasContent ? _handleAddToShoppingList : null,
            enabled: hasContent,
          ),
        ),
      ],
    );

    if (isTablet) {
      buttonRow = Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: buttonRow,
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: AppSpacing.md,
        top: AppSpacing.sm,
      ),
      child: buttonRow,
    );
  }

  Widget _buildConversionButton({
    required BuildContext context,
    required String text,
    required IconData icon,
    VoidCallback? onPressed,
    bool enabled = true,
  }) {
    final colors = AppColors.of(context);
    final borderColor = enabled
        ? colors.textPrimary.withValues(alpha: 0.20)
        : colors.textPrimary.withValues(alpha: 0.10);
    final contentColor = enabled
        ? colors.textPrimary.withValues(alpha: 0.85)
        : colors.textPrimary.withValues(alpha: 0.35);

    final button = Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 16,
            color: contentColor,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: contentColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    if (!enabled || onPressed == null) {
      return button;
    }

    return _PressableButton(
      onPressed: onPressed,
      child: button,
    );
  }

  Widget _buildTrailingButton(BuildContext context, bool keyboardVisible) {
    if (keyboardVisible) {
      // Show "Done" button when software keyboard is visible
      return CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: _dismissKeyboard,
        child: Text(
          'Done',
          style: TextStyle(
            color: AppColors.of(context).primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    } else {
      // Show overflow menu when no software keyboard
      final hasContent = _hasContent();
      return AdaptivePullDownButton(
        items: [
          AdaptiveMenuItem(
            title: 'Convert to Recipe',
            icon: const Icon(CupertinoIcons.sparkles),
            onTap: hasContent ? _handleConvertToRecipe : null,
          ),
          AdaptiveMenuItem(
            title: 'To Shopping List',
            icon: const Icon(CupertinoIcons.list_bullet),
            onTap: hasContent ? _handleAddToShoppingList : null,
          ),
          AdaptiveMenuItem.divider(),
          AdaptiveMenuItem(
            title: 'Delete Clipping',
            icon: const Icon(CupertinoIcons.trash),
            onTap: _deleteClipping,
            isDestructive: true,
          ),
        ],
        child: const AppCircleButton(
          icon: AppCircleButtonIcon.ellipsis,
          variant: AppCircleButtonVariant.neutral,
        ),
      );
    }
  }

  Widget _buildToolbar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.of(context).surfaceElevated,
        border: Border(
          top: BorderSide(
            color: AppColors.of(context).border,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: quill.QuillSimpleToolbar(
          controller: _contentController,
          config: quill.QuillSimpleToolbarConfig(
            showBoldButton: true,
            showItalicButton: true,
            showUnderLineButton: false,
            showStrikeThrough: false,
            showColorButton: false,
            showBackgroundColorButton: false,
            showClearFormat: false,
            showAlignmentButtons: false,
            showHeaderStyle: false,
            showListBullets: true,
            showListNumbers: true,
            showListCheck: true,
            showCodeBlock: false,
            showQuote: false,
            showIndent: false,
            showLink: false,
            showSearchButton: false,
            showSubscript: false,
            showSuperscript: false,
            showInlineCode: false,
            showUndo: false,
            showRedo: false,
            showFontFamily: false,
            showFontSize: false,
            showDividers: true,
            showSmallButton: false,
            showClipboardCopy: false,
            showClipboardCut: false,
            showClipboardPaste: false,
            toolbarIconAlignment: WrapAlignment.start,
            toolbarSectionSpacing: AppSpacing.sm,
            customButtons: [
              quill.QuillToolbarCustomButtonOptions(
                icon: Icon(
                  CupertinoIcons.link,
                  size: 20,
                  color: quill.QuillTextLink.isSelected(_contentController)
                      ? AppColors.of(context).primary
                      : AppColors.of(context).textSecondary,
                ),
                tooltip: 'Add link',
                onPressed: () => _showLinkModal(context),
              ),
            ],
            buttonOptions: quill.QuillSimpleToolbarButtonOptions(
              base: quill.QuillToolbarBaseButtonOptions(
                iconTheme: quill.QuillIconTheme(
                  iconButtonSelectedData: quill.IconButtonData(
                    color: AppColors.of(context).primary,
                    highlightColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(Colors.transparent),
                      overlayColor: WidgetStateProperty.all(Colors.transparent),
                    ),
                  ),
                  iconButtonUnselectedData: quill.IconButtonData(
                    color: AppColors.of(context).textSecondary,
                    highlightColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(Colors.transparent),
                      overlayColor: WidgetStateProperty.all(Colors.transparent),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom checkbox builder that matches our app theme colors
class _ClippingCheckboxBuilder extends quill.QuillCheckboxBuilder {
  final Color color;

  _ClippingCheckboxBuilder(this.color);

  @override
  Widget build({
    required BuildContext context,
    required bool isChecked,
    required ValueChanged<bool> onChanged,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) {}, // Absorb to prevent editor from handling
        onTap: () => onChanged(!isChecked),
        child: Container(
          alignment: AlignmentDirectional.centerEnd,
          padding: const EdgeInsetsDirectional.only(end: 8),
          child: Icon(
            isChecked
                ? CupertinoIcons.checkmark_square_fill
                : CupertinoIcons.square,
            size: 20,
            color: color,
          ),
        ),
      ),
    );
  }
}

/// Simple pressable wrapper that reduces opacity when pressed
class _PressableButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;

  const _PressableButton({
    required this.child,
    required this.onPressed,
  });

  @override
  State<_PressableButton> createState() => _PressableButtonState();
}

class _PressableButtonState extends State<_PressableButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: Opacity(
        opacity: _isPressed ? 0.5 : 1.0,
        child: widget.child,
      ),
    );
  }
}
