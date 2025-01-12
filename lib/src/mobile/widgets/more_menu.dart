import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../color_theme.dart';
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
        required Color textColor,
      }) {
    final isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;
    final sidebarColor = isDarkMode ? AppColors.sidebarDark : AppColors.sidebarLight;

// Adjust the sidebar color for the active state
    final activeColor = isActive
        ? (isDarkMode
        ? _lightenColor(sidebarColor, 0.2) // Make it 20% lighter in dark mode
        : _darkenColor(sidebarColor, 0.03)) // Make it 10% darker in light mode
        : Colors.transparent;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Container(
          decoration: BoxDecoration(
            color: activeColor,
            borderRadius: BorderRadius.circular(8.0),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                icon,
                color: CupertinoTheme.of(context).primaryColor,
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
      ),
    );
  }

  Widget _buildTreeItem(
      BuildContext context,
      String folderName,
      Color iconColor,
      Color textColor,
      ) {
    final isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;
    final sidebarColor = isDarkMode ? AppColors.sidebarDark : AppColors.sidebarLight;

    // Slightly adjust the sidebar color for consistency
    final activeBackgroundColor = isDarkMode
        ? sidebarColor.withOpacity(0.8) // Slightly lighter in dark mode
        : sidebarColor.withOpacity(0.9); // Slightly darker in light mode

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: activeBackgroundColor,
          borderRadius: BorderRadius.circular(8.0),
        ),
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
      ),
    );
  }

  // Lighten a color by [amount] (0.0 to 1.0)
  Color _lightenColor(Color color, double amount) {
    assert(amount >= 0 && amount <= 1, 'Amount must be between 0 and 1');
    final hsl = HSLColor.fromColor(color);
    final lightened = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
    return lightened.toColor();
  }

// Darken a color by [amount] (0.0 to 1.0)
  Color _darkenColor(Color color, double amount) {
    assert(amount >= 0 && amount <= 1, 'Amount must be between 0 and 1');
    final hsl = HSLColor.fromColor(color);
    final darkened = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return darkened.toColor();
  }
}
