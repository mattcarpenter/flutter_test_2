import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:super_context_menu/super_context_menu.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import '../../../../../../database/models/ingredients.dart';
import '../../../../../../database/database.dart';
import '../../../../../providers/recipe_provider.dart' as recipe_provider;
import '../../../../../services/ingredient_parser_service.dart';
import '../../../../../widgets/ingredient_text_editing_controller.dart';
import '../utils/context_menu_utils.dart';

class IngredientListItem extends ConsumerStatefulWidget {
  final int index;
  final Ingredient ingredient;
  final bool autoFocus;
  final bool isDragging;
  final VoidCallback onRemove;
  final Function(Ingredient) onUpdate;
  final VoidCallback onAddNext;
  final Function(bool) onFocus;

  const IngredientListItem({
    Key? key,
    required this.index,
    required this.ingredient,
    required this.autoFocus,
    required this.isDragging,
    required this.onRemove,
    required this.onUpdate,
    required this.onAddNext,
    required this.onFocus,
  }) : super(key: key);

  @override
  ConsumerState<IngredientListItem> createState() => _IngredientListItemState();
}

class _IngredientListItemState extends ConsumerState<IngredientListItem> {
  late IngredientTextEditingController _ingredientController;
  late FocusNode _focusNode;

  bool get isSection => widget.ingredient.type == 'section';

  final GlobalKey _dragHandleKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _ingredientController = IngredientTextEditingController(
      parser: IngredientParserService(),
      text: widget.ingredient.name,
    );
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      widget.onFocus(_focusNode.hasFocus);
      setState(() {}); // update background color
    });
    if (widget.autoFocus) {
      _focusNode.requestFocus();
    }
  }

  @override
  void didUpdateWidget(covariant IngredientListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ingredient.name != widget.ingredient.name &&
        _ingredientController.text != widget.ingredient.name) {
      _ingredientController.text = widget.ingredient.name;
    }

    // Handle autofocus change
    if (!oldWidget.autoFocus && widget.autoFocus) {
      _focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _ingredientController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool _contextMenuIsAllowed(Offset location) {
    return isLocationOutsideKey(location, _dragHandleKey);
  }

  void _showRecipeSelector(BuildContext context) {
    WoltModalSheet.show(
      useRootNavigator: true,
      context: context,
      modalTypeBuilder: (_) => WoltModalType.bottomSheet(),
      pageListBuilder: (modalContext) {
        return [
          WoltModalSheetPage(
            hasTopBarLayer: true,
            isTopBarLayerAlwaysVisible: true,
            topBarTitle: const Text('Link to Recipe'),
            leadingNavBarWidget: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                Navigator.of(modalContext).pop();
              },
            ),
            child: RecipeSelectorContent(
              onRecipeSelected: (recipe) {
                widget.onUpdate(widget.ingredient.copyWith(recipeId: recipe.id));
                Navigator.of(modalContext).pop();
              },
            ),
          ),
        ];
      },
      onModalDismissedWithBarrierTap: () {
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Colors.white;

    if (isSection) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          leading: const Icon(Icons.segment),
          title: Focus(
            focusNode: _focusNode,
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Section name',
                border: InputBorder.none,
              ),
              controller: _ingredientController,
              style: const TextStyle(fontWeight: FontWeight.bold),
              onChanged: (value) {
                widget.onUpdate(widget.ingredient.copyWith(name: value));
              },
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: widget.onRemove,
              ),
              SizedBox(
                width: 40,
                child: ReorderableDragStartListener(
                  index: widget.index,
                  child: const Icon(Icons.drag_handle),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Slidable(
        enabled: !widget.isDragging,
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          extentRatio: 0.2,
          children: [
            Expanded(
              child: Center(
                child: GestureDetector(
                  onTap: widget.onRemove,
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
        child: ContextMenuWidget(
        contextMenuIsAllowed: _contextMenuIsAllowed,
        menuProvider: (_) {
          return Menu(
            children: [
              MenuAction(
                title: 'Convert to section',
                image: MenuImage.icon(Icons.segment),
                callback: () {
                  // Convert the ingredient to a section
                  widget.onUpdate(widget.ingredient.copyWith(
                    type: 'section',
                    name: widget.ingredient.name.isEmpty ? 'New Section' : widget.ingredient.name,
                    primaryAmount1Value: null,
                    primaryAmount1Unit: null,
                    primaryAmount1Type: null,
                  ));
                },
              ),
              MenuAction(
                title: widget.ingredient.recipeId == null 
                    ? 'Link to Existing Recipe' 
                    : 'Change Linked Recipe',
                image: MenuImage.icon(Icons.link),
                callback: () {
                  _showRecipeSelector(context);
                },
              ),
              if (widget.ingredient.recipeId != null)
                MenuAction(
                  title: 'Remove Recipe Link',
                  image: MenuImage.icon(Icons.link_off),
                  callback: () {
                    widget.onUpdate(widget.ingredient.copyWith(recipeId: ''));
                  },
                ),
            ],
          );
        },
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: backgroundColor,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12), // Add some left padding
                  Expanded(
                    child: Focus(
                      focusNode: _focusNode,
                      child: TextField(
                        controller: _ingredientController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. 1 cup flour',
                          border: InputBorder.none,
                        ),
                        onChanged: (value) {
                          widget.onUpdate(widget.ingredient.copyWith(name: value));
                        },
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => widget.onAddNext(),
                      ),
                    ),
                  ),
                  if (widget.ingredient.recipeId != null) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.link,
                      size: 16,
                      color: Theme.of(context).primaryColor,
                    ),
                  ],
                  const SizedBox(width: 48), // Space for the drag handle
                ],
              ),
            ),
            // Position the drag handle on top so it's clickable
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: SizedBox(
                width: 40,
                child: ReorderableDragStartListener(
                  key: _dragHandleKey,
                  index: widget.index,
                  child: const Icon(Icons.drag_handle),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

class RecipeSelectorContent extends ConsumerStatefulWidget {
  final Function(RecipeEntry) onRecipeSelected;

  const RecipeSelectorContent({
    Key? key,
    required this.onRecipeSelected,
  }) : super(key: key);

  @override
  ConsumerState<RecipeSelectorContent> createState() => _RecipeSelectorContentState();
}

class _RecipeSelectorContentState extends ConsumerState<RecipeSelectorContent> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Clear any previous search results and request focus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Reset the search state to empty to show all recipes
      ref.read(recipe_provider.cookModalRecipeSearchProvider.notifier).search('');
      // Focus the search input
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    ref.read(recipe_provider.cookModalRecipeSearchProvider.notifier).search(query);
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(recipe_provider.cookModalRecipeSearchProvider);

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search box
            TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Search recipes...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
              ),
              onChanged: _onSearchChanged,
            ),

            const SizedBox(height: 20),

            // Search results
            Expanded(
              child: searchState.results.isEmpty && !searchState.isLoading
                  ? const Center(
                      child: Text('Search for recipes to link to this ingredient'),
                    )
                  : ListView.builder(
                      itemCount: searchState.results.length,
                      itemBuilder: (context, index) {
                        final recipe = searchState.results[index];
                        return ListTile(
                          title: Text(recipe.title),
                          subtitle: recipe.description != null 
                              ? Text(recipe.description!, maxLines: 1, overflow: TextOverflow.ellipsis)
                              : null,
                          onTap: () => widget.onRecipeSelected(recipe),
                          trailing: const Icon(Icons.arrow_forward_ios),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
