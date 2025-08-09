import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import '../../../theme/colors.dart';
import '../../../widgets/error_dialog.dart';
import '../../../widgets/success_dialog.dart';
import '../../../widgets/wolt/text/modal_sheet_title.dart';
import '../../../widgets/wolt/button/wolt_elevated_button.dart';
import '../utils/error_messages.dart';

void showCreateHouseholdModal(BuildContext context, Function(String name) onCreateHousehold) {
  WoltModalSheet.show(
    useRootNavigator: true,
    context: context,
    pageListBuilder: (bottomSheetContext) => [
      CreateHouseholdModalPage.build(
        context: bottomSheetContext,
        onCreateHousehold: onCreateHousehold,
      ),
    ],
  );
}

class CreateHouseholdModalPage {
  CreateHouseholdModalPage._();

  static WoltModalSheetPage build({
    required BuildContext context,
    required Function(String name) onCreateHousehold,
  }) {
    return WoltModalSheetPage(
      backgroundColor: AppColors.of(context).background,
      leadingNavBarWidget: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: const Text('Cancel'),
      ),
      pageTitle: const ModalSheetTitle('Create Household'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: CreateHouseholdForm(onCreateHousehold: onCreateHousehold),
      ),
    );
  }
}

class CreateHouseholdForm extends ConsumerStatefulWidget {
  final Function(String name) onCreateHousehold;

  const CreateHouseholdForm({
    super.key,
    required this.onCreateHousehold,
  });

  @override
  ConsumerState<CreateHouseholdForm> createState() => _CreateHouseholdFormState();
}

class _CreateHouseholdFormState extends ConsumerState<CreateHouseholdForm> {
  final _controller = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _createHousehold() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() {
      _isCreating = true;
    });

    try {
      await widget.onCreateHousehold(_controller.text.trim());
      if (mounted) {
        Navigator.of(context).pop();
        // Show success dialog for this major operation
        await SuccessDialog.show(
          context,
          message: 'Household "${_controller.text.trim()}" has been created successfully!',
        );
      }
    } catch (e) {
      if (mounted) {
        await ErrorDialog.show(
          context,
          message: HouseholdErrorMessages.getDisplayMessage(e.toString()),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Enter a name for your household',
          style: TextStyle(
            color: CupertinoColors.secondaryLabel,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        CupertinoTextField(
          controller: _controller,
          placeholder: 'Household name',
          autofocus: true,
          enabled: !_isCreating,
          onSubmitted: (_) => _createHousehold(),
          padding: const EdgeInsets.all(12),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: _isCreating
              ? const CupertinoButton(
                  onPressed: null,
                  child: CupertinoActivityIndicator(color: CupertinoColors.white),
                )
              : WoltElevatedButton(
                  onPressed: _createHousehold,
                  child: const Text('Create Household'),
                ),
        ),
      ],
    );
  }
}