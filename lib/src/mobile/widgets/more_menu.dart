import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../pages/discover.dart';
import '../pages/meal_plan.dart';
import '../pages/recipes.dart';
import '../pages/shopping_list.dart';

class MoreMenu extends StatelessWidget {
  final void Function(Widget route) onSelect;
  final VoidCallback onClose;
  final bool showCloseButton;

  const MoreMenu({
    super.key,
    required this.onSelect,
    required this.onClose,
    this.showCloseButton = true,
  });

  @override
  Widget build(BuildContext context) {
    // Placeholder active state logic
    final String activePageTitle = 'Recipes'; // Replace with actual logic.

    // Theme Colors
    final Color primaryColor = CupertinoTheme.of(context).primaryColor;
    final Color textColor = CupertinoTheme.of(context)
        .textTheme
        .textStyle
        .color ?? Colors.black;

    return SafeArea(
      child: Column(
        children: [
          // Custom Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: !showCloseButton ? const SizedBox(height: 40) : Row(
              children: [
                GestureDetector(
                  onTap: onClose,
                  child: Icon(
                    CupertinoIcons.clear,
                    color: textColor,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'More',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                // Navigation Items
                _buildNavItem(
                  context,
                  icon: Icons.book,
                  title: 'Recipes',
                  isActive: activePageTitle == 'Recipes',
                  onTap: () => onSelect(
                    const RecipesPage(title: 'Recipes'),
                  ),
                  activeColor: primaryColor,
                  textColor: textColor,
                ),
                _buildNavItem(
                  context,
                  icon: Icons.shopping_cart,
                  title: 'Shopping List',
                  isActive: activePageTitle == 'Shopping List',
                  onTap: () => onSelect(
                    const ShoppingListPage(title: 'Shopping List'),
                  ),
                  activeColor: primaryColor,
                  textColor: textColor,
                ),
                _buildNavItem(
                  context,
                  icon: Icons.calendar_today,
                  title: 'Meal Plans',
                  isActive: activePageTitle == 'Meal Plans',
                  onTap: () => onSelect(
                    const MealPlanPage(title: 'Meal Plans'),
                  ),
                  activeColor: primaryColor,
                  textColor: textColor,
                ),
                _buildNavItem(
                  context,
                  icon: Icons.explore,
                  title: 'Discover',
                  isActive: activePageTitle == 'Discover',
                  onTap: () => onSelect(
                    const DiscoverPage(title: 'Discover'),
                  ),
                  activeColor: primaryColor,
                  textColor: textColor,
                ),
                // Divider between groups
                const Divider(height: 24, thickness: 1),
                // Recipe Folders
                _buildTreeItem(context, 'Folder 1', primaryColor, textColor),
                _buildTreeItem(context, 'Folder 2', primaryColor, textColor),
                _buildTreeItem(context, 'Folder 3', primaryColor, textColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required bool isActive,
        required VoidCallback onTap,
        required Color activeColor,
        required Color textColor,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(
              icon,
              color: activeColor,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTreeItem(
      BuildContext context,
      String folderName,
      Color iconColor,
      Color textColor,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.folder,
            color: iconColor,
          ),
          const SizedBox(width: 16),
          Text(
            folderName,
            style: TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
