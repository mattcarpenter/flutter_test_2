# Design System Documentation

This document outlines the design system components and implementation patterns for the Recipe App. Our design system provides consistent styling, spacing, typography, and color management across the entire application.

## Overview

The design system is built around three core pillars:
- **Colors**: Theme-aware color system with Material Design-inspired swatches
- **Typography**: Semantic text styles for consistent hierarchy and readability
- **Spacing**: Standardized spacing values for layout consistency

## Color System

### Location: `lib/src/theme/colors.dart`

Our color system is built on two main classes that work together to provide theme-aware colors throughout the app.

#### AppColorSwatches

Provides static color swatches with numbered shades (50-950) following Material Design conventions:

```dart
// Usage examples
AppColorSwatches.neutral[50]   // Lightest neutral
AppColorSwatches.neutral[500]  // Base neutral
AppColorSwatches.neutral[950]  // Darkest neutral

AppColorSwatches.primary[500]  // Base primary color
AppColorSwatches.error[600]    // Darker error color
```

**Available Swatches:**
- `neutral` - Warm grays for text, borders, and subtle backgrounds
- `primary` - Coral/salmon red for primary actions and branding
- `secondary` - Deep blue for secondary actions and accents
- `accent` - Vibrant blue for highlights and call-to-actions
- `success` - Green for positive states and confirmations
- `warning` - Orange for cautionary states
- `error` - Red for error states and destructive actions
- `info` - Blue for informational content

#### AppColors (Theme-Aware)

Provides semantic color names that automatically adapt to light/dark mode:

```dart
// Always use this pattern for theme-aware colors
final colors = AppColors.of(context);

// Content text colors (for user content, list items, descriptions)
colors.contentPrimary     // Main content text (ingredient names, step descriptions)
colors.contentSecondary   // Supporting content (section headers in lists)
colors.contentHint        // Content placeholder hints ('e.g. 1 cup flour')

// UI text colors (for interface elements, forms, controls)
colors.uiLabel            // Form field labels, button labels
colors.uiSecondary        // Secondary interface elements (drag handles)
colors.uiHint             // Form field placeholders ('Enter value')

// Base text colors (use content/UI variants when possible)
colors.textPrimary        // Main text (fallback)
colors.textSecondary      // Supporting text (fallback)
colors.textTertiary       // Subtle text (fallback)
colors.textDisabled       // Disabled text

// Surface and interaction colors
colors.surface            // Background surfaces
colors.border             // Borders and dividers
colors.focus              // Focus states
colors.error              // Error states
colors.chipBackground     // Chip/tag backgrounds
```

### Implementation Guidelines

**✅ Do:**
```dart
// Use theme-aware colors
final colors = AppColors.of(context);
Text('Hello', style: TextStyle(color: colors.textPrimary))

// Use appropriate surface levels
Container(
  color: colors.surface,        // For input fields, cards
  child: Text('Input field'),
)

// Modal backgrounds
WoltModalSheetPage(
  backgroundColor: colors.background,  // Same as page background
  child: content,
)

// Use swatches for custom components
Container(color: AppColorSwatches.primary[100])
```

**❌ Don't:**
```dart
// Hard-code colors
Text('Hello', style: TextStyle(color: Colors.black))

// Use Colors.grey instead of neutral swatch
Container(color: Colors.grey[200])

// Mix color systems (e.g., Cupertino + custom)
backgroundColor: CupertinoTheme.of(context).scaffoldBackgroundColor // ❌
```

### Surface Hierarchy & Color Philosophy

Our color system follows a clear surface hierarchy to create visual depth and organization:

#### Surface Levels
1. **Background** (`colors.background`) - Main application background
   - Used for: Page backgrounds, modal backgrounds
   - Philosophy: Modals use the same background as pages since overlay darkening provides hierarchy
   
2. **Surface** (`colors.surface`) - Elevated elements that sit above the background
   - Used for: Input fields, cards, elevated containers, floating buttons
   - Philosophy: Creates clear definition and interaction areas
   
3. **Surface Variant** (`colors.surfaceVariant`) - Secondary surfaces
   - Used for: Disabled states, subtle background variations, section headers

#### Color Relationships
- **Modal backgrounds**: Use `colors.background` (same as page) - overlay provides hierarchy
- **Input fields**: Use `colors.surface` - contrast against background for clear interaction
- **Cards/containers**: Use `colors.surface` - consistent elevation treatment
- **Disabled elements**: Use `colors.surfaceVariant` - visually de-emphasized

This approach ensures visual consistency and clear information hierarchy across all components.

### Dark Mode Support

Colors automatically adapt based on `Theme.of(context).brightness`:
- Light mode uses darker shades for text, lighter shades for backgrounds
- Dark mode uses lighter shades for text, darker shades for backgrounds
- Focus and accent colors remain consistent across modes
- Surface hierarchy maintains consistent relationships in both modes

## Typography System

### Location: `lib/src/theme/typography.dart`

Our typography system provides semantic text styles that create consistent hierarchy and improve readability.

#### Heading Styles

```dart
AppTypography.h1  // 28px, bold - Page titles
AppTypography.h2  // 24px, bold - Major sections
AppTypography.h3  // 20px, w600 - Subsections
AppTypography.h4  // 18px, bold - Modal titles, dialog headers
AppTypography.h5  // 16px, w600 - Section headers, prominent selections
```

#### Body Text Styles

```dart
AppTypography.bodyLarge  // 16px - Important content
AppTypography.body       // 15px - Standard content
AppTypography.bodySmall  // 14px - Supporting content
```

#### UI Text Styles

```dart
AppTypography.input     // 16px - Form inputs
AppTypography.label     // 16px, w500 - UI labels
AppTypography.caption   // 12px - Small supporting text, picker labels
AppTypography.overline  // 11px, w500, spaced - Overline text
```

#### Form-Specific Styles

```dart
AppTypography.fieldInput   // 16px, w400 - Text field content
AppTypography.fieldLabel   // 16px, w300 - Field labels
AppTypography.fieldError   // 12px - Error messages
AppTypography.fieldHelper  // 12px - Helper text
```

### Typography & Color Pairing Guidelines

**Content Text (Recipe Lists, User Content):**
```dart
// Primary content - ingredient names, step descriptions
AppTypography.body.copyWith(color: colors.contentPrimary)

// Secondary content - section headers in lists
AppTypography.bodySmall.copyWith(color: colors.contentSecondary)

// Content hints - placeholder text in content areas
AppTypography.body.copyWith(color: colors.contentHint)
```

**Interface Text (Forms, Controls, Navigation):**
```dart
// Form field labels
AppTypography.fieldLabel.copyWith(color: colors.uiLabel)

// Form input text
AppTypography.fieldInput.copyWith(color: colors.textPrimary)

// Form placeholders
AppTypography.fieldInput.copyWith(color: colors.uiHint)

// Secondary UI elements (drag handles, etc.)
AppTypography.caption.copyWith(color: colors.uiSecondary)
```

### Modal & Dialog Typography Guidelines

For consistent modal and dialog design:

```dart
// Modal titles
AppTypography.h4.copyWith(color: colors.textPrimary)    // Modal headers

// Picker components  
AppTypography.h5.copyWith(color: colors.textPrimary)    // Selected values
AppTypography.bodySmall.copyWith(color: colors.textSecondary)  // Labels

// Modal body content
AppTypography.body.copyWith(color: colors.textPrimary)  // Descriptions
AppTypography.bodySmall.copyWith(color: colors.textSecondary)  // Helper text
```

### Implementation Guidelines

**✅ Do:**
```dart
// Use semantic typography with theme-aware colors
final colors = AppColors.of(context);
Text(
  'Section Title',
  style: AppTypography.h5.copyWith(color: colors.textPrimary),
)

// Use appropriate hierarchy
AppTypography.h2    // Page section
AppTypography.h4    // Modal titles
AppTypography.h5    // Subsection, picker values
AppTypography.body  // Content
AppTypography.bodySmall  // Supporting content, picker labels
```

**❌ Don't:**
```dart
// Hard-code typography
Text('Title', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))

// Use hardcoded colors from typography
Text('Title', style: AppTypography.h5) // Has hardcoded dark color
```

**⚠️ Important:** The typography system has hardcoded colors that don't adapt to dark mode. Always override the color when using typography styles:

```dart
// Required pattern for theme-aware text
style: AppTypography.h5.copyWith(color: colors.textPrimary)
```

## Spacing System

### Location: `lib/src/theme/spacing.dart`

Standardized spacing values ensure consistent layouts and visual rhythm throughout the app.

#### Available Spacing Values

```dart
AppSpacing.xs   // 4px  - Micro adjustments, very tight spacing
AppSpacing.sm   // 8px  - Button groups, related elements  
AppSpacing.md   // 12px - Content-to-action separation
AppSpacing.lg   // 16px - Section internal padding
AppSpacing.xl   // 24px - Major section breaks
AppSpacing.xxl  // 32px - Large layout gaps
```

### Usage Guidelines

**Layout Spacing:**
```dart
// Section separation
SizedBox(height: AppSpacing.xl)

// Component internal padding
Padding(padding: EdgeInsets.all(AppSpacing.lg))

// Related element spacing
SizedBox(width: AppSpacing.sm)
```

**Component Guidelines:**
- Use `AppSpacing.lg` (16px) for component internal padding
- Use `AppSpacing.xl` (24px) between major sections
- Use `AppSpacing.sm` (8px) between related elements
- Use `AppSpacing.xs` (4px) for micro-adjustments

## Component Architecture

### Form Components

Our form components follow consistent patterns:

#### AppTextField & AppTextFieldCondensed
- Theme-aware colors via `AppColors.of(context)`
- Support for grouping (first/last properties for border radius)
- Consistent padding using `AppSpacing` values
- Typography via `AppTypography.fieldInput` and `AppTypography.fieldLabel`

#### Custom Widgets
When creating custom widgets, follow these patterns:

```dart
class CustomWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Text(
        'Content',
        style: AppTypography.body.copyWith(
          color: colors.textPrimary,
        ),
      ),
    );
  }
}
```

### Theme Integration

Components should always integrate with the theme system:

1. **Colors**: Use `AppColors.of(context)` for theme-aware colors
2. **Typography**: Use `AppTypography` styles with color overrides
3. **Spacing**: Use `AppSpacing` constants for consistent layout
4. **Dark Mode**: Test components in both light and dark modes

## Migration Guidelines

### Existing Components

When updating existing components to use the design system:

1. **Replace hardcoded colors:**
   ```dart
   // Before
   color: Colors.grey[200]
   
   // After  
   color: AppColorSwatches.neutral[200]
   // or
   color: colors.surface
   ```

2. **Replace hardcoded spacing:**
   ```dart
   // Before
   padding: EdgeInsets.all(16.0)
   
   // After
   padding: EdgeInsets.all(AppSpacing.lg)
   ```

3. **Update typography:**
   ```dart
   // Before
   style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)
   
   // After
   style: AppTypography.h5.copyWith(color: colors.textPrimary)
   ```

### New Components

When creating new components:

1. Always import the design system:
   ```dart
   import '../theme/colors.dart';
   import '../theme/typography.dart';
   import '../theme/spacing.dart';
   ```

2. Use the established patterns for theme-aware styling
3. Follow semantic naming for colors and typography
4. Test in both light and dark modes

## Best Practices

### Performance
- `AppColors.of(context)` is lightweight - call it in each build method
- Typography styles are const - safe to use frequently
- Spacing values are const - no performance concerns

### Consistency
- Always use semantic color names (`textPrimary`) over specific shades (`neutral[900]`)
- Prefer design system spacing over hardcoded values
- Use appropriate typography hierarchy for content importance

### Accessibility
- Color system provides sufficient contrast ratios for WCAG compliance
- Typography sizes support readability across device sizes
- Dark mode implementation maintains accessibility standards

### Testing
- Test all components in both light and dark modes
- Verify color contrast meets accessibility requirements
- Ensure spacing creates clear visual hierarchy

## Future Considerations

### Planned Improvements
- Migrate typography system to remove hardcoded colors
- Add animation/transition constants
- Expand semantic color vocabulary as needed
- Create component-specific design tokens

### Extension Points
- Additional color swatches can be added to `AppColorSwatches`
- New semantic colors can be added to `AppColors`
- Typography styles can be extended for new use cases
- Spacing system can accommodate new layout patterns