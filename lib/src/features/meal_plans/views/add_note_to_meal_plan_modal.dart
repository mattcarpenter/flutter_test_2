import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import '../../../providers/meal_plan_provider.dart';
import '../../../widgets/wolt/text/modal_sheet_title.dart';

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
    final isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode
        ? CupertinoTheme.of(context).barBackgroundColor
        : CupertinoTheme.of(context).scaffoldBackgroundColor;

    return WoltModalSheetPage(
      backgroundColor: backgroundColor,
      leadingNavBarWidget: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      pageTitle: const ModalSheetTitle('Add Note'),
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
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _textFocusNode = FocusNode();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Auto-focus the title field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _titleFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    _titleFocusNode.dispose();
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
      final noteTitle = _titleController.text.trim();
      final noteText = _textController.text.trim();

      await ref.read(mealPlanNotifierProvider.notifier).addNote(
        date: widget.date,
        noteText: noteText,
        noteTitle: noteTitle.isEmpty ? null : noteTitle,
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
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Instructions
          Text(
            'Add a note to your meal plan. This could be cooking tips, reminders, or special instructions.',
            style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
              fontSize: 16,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),

          const SizedBox(height: 24),

          // Title field (optional)
          Text(
            'Title (optional)',
            style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 8),
          CupertinoTextField(
            controller: _titleController,
            focusNode: _titleFocusNode,
            placeholder: 'e.g., Prep ahead, Cooking notes...',
            style: CupertinoTheme.of(context).textTheme.textStyle,
            decoration: BoxDecoration(
              color: CupertinoColors.tertiarySystemGroupedBackground.resolveFrom(context),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: CupertinoColors.separator.resolveFrom(context),
                width: 0.5,
              ),
            ),
            padding: const EdgeInsets.all(12),
            onSubmitted: (_) => _textFocusNode.requestFocus(),
          ),

          const SizedBox(height: 20),

          // Note text field (required)
          Text(
            'Note *',
            style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 8),
          CupertinoTextField(
            controller: _textController,
            focusNode: _textFocusNode,
            placeholder: 'Enter your note here...',
            style: CupertinoTheme.of(context).textTheme.textStyle,
            decoration: BoxDecoration(
              color: CupertinoColors.tertiarySystemGroupedBackground.resolveFrom(context),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: CupertinoColors.separator.resolveFrom(context),
                width: 0.5,
              ),
            ),
            padding: const EdgeInsets.all(12),
            maxLines: 8,
            minLines: 4,
            textInputAction: TextInputAction.newline,
            onChanged: (_) => setState(() {}), // Update button state
          ),

          const SizedBox(height: 24),

          // Add button
          SizedBox(
            width: double.infinity,
            child: CupertinoButton.filled(
              onPressed: _canSubmit ? _handleSubmit : null,
              child: _isSubmitting
                  ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                  : const Text('Add Note'),
            ),
          ),

          const SizedBox(height: 16),

          // Character count helper
          Center(
            child: Text(
              '${_textController.text.length} characters',
              style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                fontSize: 12,
                color: CupertinoColors.tertiaryLabel.resolveFrom(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}