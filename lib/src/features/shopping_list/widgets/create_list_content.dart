import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../providers/shopping_list_provider.dart';
import '../../../services/logging/app_logger.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_text_field_simple.dart';

/// Reusable widget for creating a new shopping list
/// Can be used in different contexts (selection modal, manage lists page, etc.)
class CreateListContent extends ConsumerStatefulWidget {
  /// Called when a list is successfully created
  final VoidCallback onCreated;

  /// Whether to autofocus the text field
  final bool autofocus;

  const CreateListContent({
    super.key,
    required this.onCreated,
    this.autofocus = true,
  });

  @override
  ConsumerState<CreateListContent> createState() => _CreateListContentState();
}

class _CreateListContentState extends ConsumerState<CreateListContent> {
  final TextEditingController _nameController = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createList() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() {
      _isCreating = true;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;

      await ref.read(shoppingListsProvider.notifier).createList(
            name: name,
            userId: userId,
          );

      if (mounted) {
        // Clear form
        _nameController.clear();
        // Notify parent
        widget.onCreated();
      }
    } catch (e) {
      AppLogger.error('Error creating shopping list', e);
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // List name input label
        Text(
          'List Name',
          style: AppTypography.label.copyWith(
            color: colors.textPrimary,
          ),
        ),
        SizedBox(height: AppSpacing.sm),

        // List name input field
        AppTextFieldSimple(
          controller: _nameController,
          placeholder: 'Enter list name',
          onChanged: (_) {
            setState(() {}); // Rebuild to update button state
          },
          autofocus: widget.autofocus,
          enabled: !_isCreating,
          onSubmitted: (_) => _createList(),
        ),
        SizedBox(height: AppSpacing.xl),

        // Create button
        AppButtonVariants.primaryFilled(
          text: 'Create List',
          size: AppButtonSize.large,
          shape: AppButtonShape.square,
          fullWidth: true,
          onPressed: _nameController.text.trim().isEmpty || _isCreating
              ? null
              : _createList,
        ),
        SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}
