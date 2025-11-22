# Settings Feature Guidelines

This document provides guidelines for implementing settings pages and items in the app.

## File Structure

Settings-related files are organized under `lib/src/features/settings/`:

```
lib/src/features/settings/
├── views/                    # Full-page settings screens
│   ├── settings_page.dart    # Main settings hub page
│   └── manage_tags_page.dart # Example sub-page
├── widgets/                  # Reusable settings UI components
│   ├── settings_group.dart   # Grouped container for settings rows
│   ├── settings_row.dart     # Individual setting row (tap, toggle, etc.)
│   └── [feature]_row.dart    # Feature-specific row widgets
└── providers/                # State management for settings features
    └── [feature]_provider.dart
```

## Core Widgets

### SettingsGroup

A container that groups related settings items with optional header and footer text.

```dart
SettingsGroup(
  header: 'Section Name',  // Optional uppercase section header
  footer: 'Help text explaining the settings above.',  // Optional footer
  children: [
    SettingsRow(...),
    SettingsRow(...),
  ],
)
```

**Styling:**
- Uses `AppColors.of(context).groupedListBackground` for background
- Uses `AppColors.of(context).groupedListBorder` for borders
- 8px border radius
- Horizontal margin of `AppSpacing.lg` (16px)
- Dividers between rows are inset from the left

### SettingsRow

A tappable row for navigation or action settings. Each row handles its own border/radius via `GroupedListStyling`.

```dart
SettingsRow(
  title: 'Setting Name',
  subtitle: 'Optional description',  // Optional
  leading: Icon(CupertinoIcons.gear, size: 22, color: colors.primary),  // Optional
  trailing: CustomWidget(),  // Optional, overrides chevron
  showChevron: true,  // Default true, shows chevron when onTap is set
  isDestructive: false,  // Red text for destructive actions
  enabled: true,
  isFirst: true,  // First item in group gets top rounded corners
  isLast: true,   // Last item in group gets bottom rounded corners
  onTap: () {},
)
```

**Important**: When multiple rows are in a group, pass `isFirst`/`isLast` appropriately:
```dart
SettingsGroup(
  header: 'Section',
  children: items.indexed.map((indexed) {
    final (index, item) = indexed;
    return SettingsRow(
      title: item.name,
      isFirst: index == 0,
      isLast: index == items.length - 1,
      onTap: () {},
    );
  }).toList(),
)
```

### SettingsToggleRow

A row with a CupertinoSwitch for boolean settings. Also uses `GroupedListStyling` for borders/radius.

```dart
SettingsToggleRow(
  title: 'Enable Feature',
  subtitle: 'Description of what this does',
  leading: Icon(...),
  value: true,
  onChanged: (value) {},
  enabled: true,
  isFirst: true,  // First item in group
  isLast: true,   // Last item in group
)
```

## Creating a Settings Page

### Main Settings Page Pattern

The main settings page uses `AdaptiveSliverPage` with grouped sections:

```dart
class SettingsPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);

    return AdaptiveSliverPage(
      title: 'Settings',
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              SizedBox(height: AppSpacing.xl),

              SettingsGroup(
                header: 'Section Name',
                children: [
                  SettingsRow(
                    title: 'Setting',
                    leading: Icon(CupertinoIcons.icon, size: 22, color: colors.primary),
                    onTap: () => context.push('/settings/sub-page'),
                  ),
                ],
              ),

              SizedBox(height: AppSpacing.xl),

              // More sections...

              SizedBox(height: AppSpacing.xxl),  // Bottom spacing
            ],
          ),
        ),
      ],
    );
  }
}
```

### Sub-Page Pattern

Sub-pages for managing specific settings (like Manage Tags):

```dart
class ManageFeaturePage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(featureProvider);
    final colors = AppColors.of(context);

    return AdaptiveSliverPage(
      title: 'Manage Feature',
      automaticallyImplyLeading: true,  // Shows back button
      slivers: [
        if (state.isLoading)
          const SliverFillRemaining(
            child: Center(child: CupertinoActivityIndicator()),
          )
        else if (state.items.isEmpty)
          SliverFillRemaining(
            child: _buildEmptyState(context, colors),
          )
        else
          SliverToBoxAdapter(
            child: _buildContent(context, state),
          ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, AppColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.icon, size: 64, color: colors.textTertiary),
          SizedBox(height: AppSpacing.lg),
          Text('No Items Yet', style: AppTypography.h4.copyWith(color: colors.textPrimary)),
          SizedBox(height: AppSpacing.sm),
          Text('Description...', style: AppTypography.body.copyWith(color: colors.textSecondary)),
        ],
      ),
    );
  }
}
```

## Styling Guidelines

### Colors

Always use theme-aware colors from `AppColors.of(context)`:

| Element | Color |
|---------|-------|
| Group background | `colors.groupedListBackground` |
| Group border | `colors.groupedListBorder` |
| Primary text | `colors.textPrimary` |
| Secondary text | `colors.textSecondary` |
| Disabled text | `colors.textDisabled` |
| Destructive text | `colors.error` |
| Leading icons | `colors.primary` |
| Chevron icons | `colors.textTertiary` |
| Press highlight | `colors.surfaceVariant` |

### Spacing

Use `AppSpacing` constants:

| Use Case | Value |
|----------|-------|
| Between sections | `AppSpacing.xl` (24px) |
| Horizontal padding | `AppSpacing.lg` (16px) |
| Row vertical padding | `AppSpacing.lg` (16px) or `AppSpacing.md` (12px) with subtitle |
| Between icon and text | `AppSpacing.md` (12px) |
| Bottom page spacing | `AppSpacing.xxl` (32px) |

### Typography

Use `AppTypography` constants:

| Element | Style |
|---------|-------|
| Row title | `AppTypography.body` |
| Row subtitle | `AppTypography.caption` |
| Section header | 13px, uppercase, `colors.textSecondary` |
| Section footer | 13px, `colors.textSecondary` |
| Empty state title | `AppTypography.h4` |
| Empty state description | `AppTypography.body` |

### Icons

- Leading icons: 22px size, `colors.primary` color
- Trailing chevrons: 16px `CupertinoIcons.chevron_right`, `colors.textTertiary`
- Empty state icons: 64px, `colors.textTertiary`
- Action icons (delete, etc.): 20px

## Adding New Settings

### Adding a Row to Existing Section

1. Add `SettingsRow` or `SettingsToggleRow` to the appropriate `SettingsGroup`
2. If navigation, use `context.push('/settings/sub-page')`
3. Add route in `adaptive_app.dart` if needed

### Adding a New Section

1. Add `SizedBox(height: AppSpacing.xl)` before the section
2. Add `SettingsGroup` with header
3. Add `SettingsRow` children

### Adding a New Sub-Page

1. Create page file in `lib/src/features/settings/views/`
2. Follow the sub-page pattern above
3. Add route in `adaptive_app.dart`:
   ```dart
   GoRoute(
     path: 'settings/feature',
     builder: (context, state) => const ManageFeaturePage(),
   ),
   ```
4. Add navigation from settings page

### Custom Row Widgets

For complex settings (like tag management with color picker):

1. Create widget in `lib/src/features/settings/widgets/`
2. Use same padding/spacing as `SettingsRow`
3. Use theme-aware colors
4. Can be used directly in `SettingsGroup.children`

## Example: Adding a New Toggle Setting

```dart
// In settings_page.dart
SettingsGroup(
  header: 'Appearance',
  children: [
    SettingsToggleRow(
      title: 'Dark Mode',
      subtitle: 'Use dark theme throughout the app',
      leading: Icon(CupertinoIcons.moon, size: 22, color: colors.primary),
      value: isDarkMode,
      onChanged: (value) {
        ref.read(themeProvider.notifier).setDarkMode(value);
      },
    ),
  ],
),
```

## Example: Adding a Navigation Setting

```dart
SettingsRow(
  title: 'Notifications',
  subtitle: 'Manage notification preferences',
  leading: Icon(CupertinoIcons.bell, size: 22, color: colors.primary),
  onTap: () => context.push('/settings/notifications'),
),
```
