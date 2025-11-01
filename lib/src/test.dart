import 'package:flutter/material.dart';
import '../../database/models/pantry_items.dart';
import 'widgets/stock_chip.dart';
import 'theme/colors.dart';
import 'theme/spacing.dart';
import 'theme/typography.dart';

/// Test app to visualize StockChip in different contexts
/// Run with: flutter run lib/src/test.dart
void main() {
  runApp(const StockChipTestApp());
}

class StockChipTestApp extends StatelessWidget {
  const StockChipTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stock Chip Test',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      home: const StockChipTestPage(),
    );
  }
}

class StockChipTestPage extends StatelessWidget {
  const StockChipTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Chip Test'),
        backgroundColor: Colors.grey[200],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Pantry Item Context (white background)
            Text(
              'Pantry Item Context',
              style: AppTypography.h4.copyWith(
                color: AppColors.of(context).textPrimary,
              ),
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              'White background, row layout',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.of(context).textSecondary,
              ),
            ),
            SizedBox(height: AppSpacing.md),

            _buildPantryItemRow(context, 'Olive Oil', StockStatus.inStock),
            SizedBox(height: AppSpacing.xs),
            _buildPantryItemRow(context, 'Chicken Breast', StockStatus.lowStock),
            SizedBox(height: AppSpacing.xs),
            _buildPantryItemRow(context, 'Butter', StockStatus.outOfStock),
            SizedBox(height: AppSpacing.xs),
            _buildPantryItemRow(context, 'Fresh Basil', null, isNew: true),

            SizedBox(height: AppSpacing.xxl),

            // Section 2: Recipe Page Context (rgb 248 244 243)
            Text(
              'Recipe Page Context',
              style: AppTypography.h4.copyWith(
                color: AppColors.of(context).textPrimary,
              ),
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              'Plain background (rgb 248, 244, 243)',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.of(context).textSecondary,
              ),
            ),
            SizedBox(height: AppSpacing.md),

            Container(
              width: double.infinity,
              padding: EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(248, 244, 243, 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRecipeIngredientRow(context, 'Olive oil', StockStatus.inStock),
                  SizedBox(height: AppSpacing.md),
                  _buildRecipeIngredientRow(context, 'Chicken breast', StockStatus.lowStock),
                  SizedBox(height: AppSpacing.md),
                  _buildRecipeIngredientRow(context, 'Butter', StockStatus.outOfStock),
                  SizedBox(height: AppSpacing.md),
                  _buildRecipeIngredientRow(context, 'Fresh basil', null),
                ],
              ),
            ),

            SizedBox(height: AppSpacing.xxl),

            // Section 3: All chips in a row for quick comparison
            Text(
              'All Variants (Quick Comparison)',
              style: AppTypography.h4.copyWith(
                color: AppColors.of(context).textPrimary,
              ),
            ),
            SizedBox(height: AppSpacing.md),

            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('In Stock', style: AppTypography.caption),
                    SizedBox(height: AppSpacing.xs),
                    StockChip(status: StockStatus.inStock),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Low Stock', style: AppTypography.caption),
                    SizedBox(height: AppSpacing.xs),
                    StockChip(status: StockStatus.lowStock),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Out', style: AppTypography.caption),
                    SizedBox(height: AppSpacing.xs),
                    StockChip(status: StockStatus.outOfStock),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('New Item', style: AppTypography.caption),
                    SizedBox(height: AppSpacing.xs),
                    StockChip(isNewItem: true),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a pantry item row (white background, similar to actual pantry list)
  Widget _buildPantryItemRow(BuildContext context, String itemName, StockStatus? status, {bool isNew = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: AppColors.of(context).border,
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Radio button placeholder
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.of(context).border,
                width: 2,
              ),
            ),
          ),

          SizedBox(width: AppSpacing.md),

          // Item name
          Expanded(
            child: Text(
              itemName,
              style: TextStyle(
                color: AppColors.of(context).textPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 17,
              ),
            ),
          ),

          SizedBox(width: AppSpacing.md),

          // Stock chip (only show for Low/Out or if new)
          if (status != StockStatus.inStock || isNew)
            SizedBox(
              width: 85,
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.only(right: AppSpacing.sm),
                  child: isNew
                    ? StockChip(isNewItem: true)
                    : StockChip(status: status),
                ),
              ),
            )
          else
            SizedBox(width: AppSpacing.md),

          // Menu button placeholder
          Icon(
            Icons.more_horiz,
            color: AppColors.of(context).textSecondary,
            size: 24,
          ),
        ],
      ),
    );
  }

  /// Builds a recipe ingredient row (like on recipe page)
  Widget _buildRecipeIngredientRow(BuildContext context, String ingredient, StockStatus? status) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Bullet point
        Text(
          '',
          style: TextStyle(
            fontSize: 16,
            height: 1.0,
            color: AppColors.of(context).contentSecondary,
          ),
        ),
        const SizedBox(width: 8),

        // Ingredient name
        Expanded(
          child: Text(
            ingredient,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.of(context).contentPrimary,
            ),
          ),
        ),

        // Stock chip
        if (status != null)
          StockChip(status: status),
      ],
    );
  }
}
