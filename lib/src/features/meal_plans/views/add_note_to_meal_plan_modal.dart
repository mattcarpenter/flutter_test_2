import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import '../../../providers/meal_plan_provider.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_circle_button.dart';
import '../../../widgets/app_text_field_simple.dart';

void showAddNoteToMealPlanModal(BuildContext context, String date) {
  WoltModalSheet.show(
    useRootNavigator: true,
    context: context,
    pageListBuilder: (modalContext) => [
      AddNoteToMealPlanModalPage.build(
        context: modalContext,
        date: date,
      ),
    ],
  );
}

class AddNoteToMealPlanModalPage {
  AddNoteToMealPlanModalPage._();

  static WoltModalSheetPage build({
    required BuildContext context,
    required String date,
  }) {
    return WoltModalSheetPage(
      navBarHeight: 55,
      backgroundColor: AppColors.of(context).background,
      surfaceTintColor: CupertinoColors.transparent,
      hasTopBarLayer: false,
      isTopBarLayerAlwaysVisible: false,
      trailingNavBarWidget: Padding(
        padding: EdgeInsets.only(right: AppSpacing.lg),
        child: AppCircleButton(
          icon: AppCircleButtonIcon.close,
          variant: AppCircleButtonVariant.neutral,
          size: 32,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      child: AddNoteToMealPlanContent(
        date: date,
        modalContext: context,
      ),
    );
  }
}

class AddNoteToMealPlanContent extends ConsumerStatefulWidget {
  final String date;
  final BuildContext modalContext;

  const AddNoteToMealPlanContent({
    super.key,
    required this.date,
    required this.modalContext,
  });

  @override
  ConsumerState<AddNoteToMealPlanContent> createState() => _AddNoteToMealPlanContentState();
}

class _AddNoteToMealPlanContentState extends ConsumerState<AddNoteToMealPlanContent> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Auto-focus the note field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _textFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _textFocusNode.dispose();
    super.dispose();
  }

  bool get _canSubmit => _textController.text.trim().isNotEmpty && !_isSubmitting;

  void _handleSubmit() async {
    if (!_canSubmit) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final noteText = _textController.text.trim();

      await ref.read(mealPlanNotifierProvider.notifier).addNote(
        date: widget.date,
        noteText: noteText,
        noteTitle: null,
        userId: null, // TODO: Pass actual user info
        householdId: null, // TODO: Pass actual household info
      );

      // Close the modal once added
      if (mounted) {
        Navigator.of(widget.modalContext).pop();
      }
    } catch (error) {
      setState(() {
        _isSubmitting = false;
      });
      _showError(error.toString());
    }
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text('Failed to add note: $message'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Modal title
          Text(
            'Add Note',
            style: AppTypography.h4.copyWith(
              color: AppColors.of(context).textPrimary,
            ),
          ),
          SizedBox(height: AppSpacing.lg),

          // Note text field
          AppTextFieldSimple(
            controller: _textController,
            focusNode: _textFocusNode,
            placeholder: 'Enter your note...',
            autofocus: true,
            enabled: !_isSubmitting,
            multiline: true,
            keyboardType: TextInputType.multiline,
            maxLines: 8,
            minLines: 4,
            textInputAction: TextInputAction.newline,
            onChanged: (_) => setState(() {}), // Update button state
          ),

          SizedBox(height: AppSpacing.lg),

          // Add button
          AppButtonVariants.primaryFilled(
            text: 'Add Note',
            size: AppButtonSize.large,
            shape: AppButtonShape.square,
            onPressed: _canSubmit ? _handleSubmit : null,
            loading: _isSubmitting,
            fullWidth: true,
          ),

          SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}