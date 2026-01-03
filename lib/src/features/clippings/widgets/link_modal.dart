import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import '../../../localization/l10n_extension.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_circle_button.dart';
import '../../../widgets/app_text_field_simple.dart';

/// Shows a Wolt modal for adding/editing a link in the Quill editor.
///
/// Returns the [quill.QuillTextLink] if the user submits, or null if cancelled.
Future<quill.QuillTextLink?> showLinkModal(
  BuildContext context, {
  required String initialText,
  String? initialLink,
}) {
  return WoltModalSheet.show<quill.QuillTextLink?>(
    context: context,
    modalTypeBuilder: (_) => WoltModalType.bottomSheet(),
    pageListBuilder: (modalContext) => [
      _buildPage(
        context: modalContext,
        initialText: initialText,
        initialLink: initialLink,
      ),
    ],
  );
}

WoltModalSheetPage _buildPage({
  required BuildContext context,
  required String initialText,
  String? initialLink,
}) {
  return WoltModalSheetPage(
    navBarHeight: 55,
    backgroundColor: AppColors.of(context).background,
    surfaceTintColor: Colors.transparent,
    hasTopBarLayer: false,
    isTopBarLayerAlwaysVisible: false,
    trailingNavBarWidget: Padding(
      padding: EdgeInsets.only(right: AppSpacing.lg),
      child: AppCircleButton(
        icon: AppCircleButtonIcon.close,
        variant: AppCircleButtonVariant.neutral,
        onPressed: () => Navigator.of(context).pop(),
      ),
    ),
    child: _LinkModalContent(
      initialText: initialText,
      initialLink: initialLink,
    ),
  );
}

class _LinkModalContent extends StatefulWidget {
  final String initialText;
  final String? initialLink;

  const _LinkModalContent({
    required this.initialText,
    this.initialLink,
  });

  @override
  State<_LinkModalContent> createState() => _LinkModalContentState();
}

class _LinkModalContentState extends State<_LinkModalContent> {
  late final TextEditingController _textController;
  late final TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialText);
    _urlController = TextEditingController(text: widget.initialLink ?? '');
  }

  @override
  void dispose() {
    _textController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    final text = _textController.text.trim();
    final url = _urlController.text.trim();
    return text.isNotEmpty && url.isNotEmpty;
  }

  void _submit() {
    if (!_canSubmit) return;

    final text = _textController.text.trim();
    final url = _urlController.text.trim();

    // Ensure URL has a protocol
    String finalUrl = url;
    if (!url.contains('://') && !url.startsWith('mailto:') && !url.startsWith('tel:')) {
      finalUrl = 'https://$url';
    }

    final textLink = quill.QuillTextLink(text, finalUrl);
    Navigator.of(context).pop(textLink);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.initialLink != null ? context.l10n.clippingsLinkEditTitle : context.l10n.clippingsLinkAddTitle,
            style: AppTypography.h4.copyWith(
              color: colors.textPrimary,
            ),
          ),
          SizedBox(height: AppSpacing.lg),

          // Text field
          Text(
            context.l10n.clippingsLinkTextLabel,
            style: AppTypography.caption.copyWith(
              color: colors.textSecondary,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          AppTextFieldSimple(
            controller: _textController,
            placeholder: context.l10n.clippingsLinkTextPlaceholder,
            autofocus: widget.initialText.isEmpty,
            onChanged: (_) => setState(() {}),
          ),

          SizedBox(height: AppSpacing.md),

          // URL field
          Text(
            context.l10n.clippingsLinkUrlLabel,
            style: AppTypography.caption.copyWith(
              color: colors.textSecondary,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          AppTextFieldSimple(
            controller: _urlController,
            placeholder: context.l10n.clippingsLinkUrlPlaceholder,
            autofocus: widget.initialText.isNotEmpty,
            keyboardType: TextInputType.url,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(),
          ),

          SizedBox(height: AppSpacing.xl),

          // Submit button
          AppButtonVariants.primaryFilled(
            text: context.l10n.commonDone,
            size: AppButtonSize.large,
            shape: AppButtonShape.square,
            fullWidth: true,
            onPressed: _canSubmit ? _submit : null,
          ),
        ],
      ),
    );
  }
}
