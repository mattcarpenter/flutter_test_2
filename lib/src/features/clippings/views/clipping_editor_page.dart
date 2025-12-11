import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:super_context_menu/super_context_menu.dart';
import '../../../providers/clippings_provider.dart';
import '../../../repositories/clippings_repository.dart';
import '../../../services/logging/app_logger.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';

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

  Timer? _saveDebounceTimer;
  bool _isDirty = false;
  bool _isSaving = false;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _titleController = TextEditingController();
    _contentController = quill.QuillController.basic();
    _titleFocusNode = FocusNode();
    _contentFocusNode = FocusNode();

    _titleController.addListener(_onTextChanged);
    _contentController.addListener(_onTextChanged);

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
    super.dispose();
  }

  void _onFocusChanged() {
    // Trigger rebuild to update toolbar visibility
    setState(() {});
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
      } catch (e) {
        AppLogger.debug('Failed to parse Quill delta, treating as plain text: $e');
        // If parsing fails, treat as plain text
        _contentController = quill.QuillController.basic();
        _contentController.document.insert(0, content);
        _contentController.addListener(_onTextChanged);
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
        trailing: _buildTrailingButton(context, keyboardVisible),
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
                child: GestureDetector(
                onTap: () {
                  // Tapping empty area focuses content
                  if (!_contentFocusNode.hasFocus && !_titleFocusNode.hasFocus) {
                    _contentFocusNode.requestFocus();
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: SingleChildScrollView(
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
      return ContextMenuWidget(
        menuProvider: (_) => Menu(
          children: [
            MenuAction(
              title: 'Delete',
              image: MenuImage.icon(CupertinoIcons.trash),
              attributes: const MenuActionAttributes(destructive: true),
              callback: _deleteClipping,
            ),
          ],
        ),
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: null,
          child: Icon(
            CupertinoIcons.ellipsis,
            color: AppColors.of(context).textPrimary,
          ),
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
            showListCheck: false,
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
