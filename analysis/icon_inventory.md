# Icon Inventory

This document catalogs all icons used in the codebase to facilitate migration to a new icon pack.

## Target Icon Pack: HugeIcons

**Package:** [hugeicons](https://pub.dev/packages/hugeicons) v1.1.4

**Installation:**
```yaml
dependencies:
  hugeicons: ^1.1.4
```

**Usage:**
```dart
import 'package:hugeicons/hugeicons.dart';

// Use with HugeIcon widget for customization
HugeIcon(
  icon: HugeIcons.strokeRoundedHome01,
  color: Colors.red,
  size: 24.0,
  strokeWidth: 1.5,
)

// Or use directly with Icon widget
Icon(HugeIcons.strokeRoundedHome01)
```

**Naming Convention:**
- Website names use kebab-case: `book-01`, `shopping-cart-01`
- Flutter code uses PascalCase: `HugeIcons.strokeRoundedBook01`, `HugeIcons.strokeRoundedShoppingCart01`
- Stroke icons: `HugeIcons.strokeRounded[Name]`
- Solid/filled icons: `HugeIcons.solidRounded[Name]`

**Icon Browser:** https://hugeicons.com/icons

---

## Summary

| Icon Source | Files | Unique Icons | Total Usages |
|-------------|-------|--------------|--------------|
| CupertinoIcons | 86 | ~90 | ~316 |
| Material Icons | 133 | ~165 | ~350 |
| SVG Assets | 2 | 2 | 2 |
| Custom Enum | 1 | 7 | - |

## Icon Packages (pubspec.yaml)

```yaml
cupertino_icons: ^1.0.0  # Line 30
flutter_svg: ^2.0.16     # Line 31
```

No third-party icon packages (FontAwesome, Phosphor, Feather, etc.) are used.

---

## Replacement Mapping Template

Use this section to define your icon replacements:

```
OLD_ICON -> NEW_ICON
```

### CupertinoIcons Replacements

#### High Frequency (10+)
| Current | New | Notes |
|---------|-----|-------|
| `CupertinoIcons.book` | `HugeIcons.strokeRoundedBook01` | 21 usages - recipes/meal plans |
| `CupertinoIcons.check_mark` | `HugeIcons.strokeRoundedCheckmark01` | 15 usages - confirmations |
| `CupertinoIcons.doc_text` | `HugeIcons.strokeRoundedFile01` | 14 usages - documents |
| `CupertinoIcons.trash` | `HugeIcons.strokeRoundedDelete02` | 11 usages - delete |
| `CupertinoIcons.sparkles` | `HugeIcons.strokeRoundedAiMagic` | 11 usages - AI features |
| `CupertinoIcons.list_bullet` | `HugeIcons.strokeRoundedLeftToRightListBullet` | 11 usages - lists |
| `CupertinoIcons.chevron_right` | `HugeIcons.strokeRoundedArrowRight01` | 11 usages - disclosure |
| `CupertinoIcons.checkmark_circle_fill` | `HugeIcons.strokeRoundedCheckmarkCircle02` | 11 usages - selected |
| `CupertinoIcons.line_horizontal_3` | `HugeIcons.strokeRoundedDragDropVertical` | 10 usages - drag handle |

#### Medium Frequency (5-9)
| Current | New | Notes |
|---------|-----|-------|
| `CupertinoIcons.pencil` | `HugeIcons.strokeRoundedPencilEdit01` | 8 usages - edit |
| `CupertinoIcons.wand_stars` | `HugeIcons.strokeRoundedMagicWand01` | 7 usages - AI magic |
| `CupertinoIcons.square` | | 7 usages - empty checkbox |
| `CupertinoIcons.checkmark` | | 7 usages - checkmark |
| `CupertinoIcons.cart` | `HugeIcons.strokeRoundedShoppingCart01` | 7 usages - shopping |
| `CupertinoIcons.bars` | `HugeIcons.strokeRoundedMenu01` | 7 usages - menu |
| `CupertinoIcons.lock_fill` | | 6 usages - premium |
| `CupertinoIcons.circle_fill` | | 6 usages - filled dot |
| `CupertinoIcons.circle` | | 6 usages - empty dot |
| `CupertinoIcons.delete` | `HugeIcons.strokeRoundedDelete02` | 5 usages - delete |

#### Low Frequency (2-4)
| Current | New | Notes |
|---------|-----|-------|
| `CupertinoIcons.sidebar_left` | | 4 usages - sidebar |
| `CupertinoIcons.link` | `HugeIcons.strokeRoundedLink01` | 4 usages - URL |
| `CupertinoIcons.folder` | `HugeIcons.strokeRoundedFolder01` | 4 usages - folder |
| `CupertinoIcons.cart_badge_plus` | `HugeIcons.strokeRoundedShoppingCartAdd01` | 4 usages - add to cart |
| `CupertinoIcons.camera` | `HugeIcons.strokeRoundedCamera01` | 4 usages - camera |
| `CupertinoIcons.calendar` | `HugeIcons.strokeRoundedCalendar01` | 4 usages - calendar |
| `CupertinoIcons.tag` | `HugeIcons.strokeRoundedTag01` | 3 usages - tag |
| `CupertinoIcons.search` | `HugeIcons.strokeRoundedSearch01` | 3 usages - search |
| `CupertinoIcons.photo` | `HugeIcons.strokeRoundedImage01` | 3 usages - photo |
| `CupertinoIcons.person_circle_fill` | `HugeIcons.strokeRoundedUserCircle` | 3 usages - profile |
| `CupertinoIcons.person_circle` | `HugeIcons.strokeRoundedUserCircle` | 3 usages - profile |
| `CupertinoIcons.home` | `HugeIcons.strokeRoundedHome01` | 3 usages - home |
| `CupertinoIcons.globe` | `HugeIcons.strokeRoundedGlobal` | 3 usages - web |
| `CupertinoIcons.exclamationmark_triangle` | | 3 usages - warning |
| `CupertinoIcons.ellipsis` | | 3 usages - more |
| `CupertinoIcons.clear` | `HugeIcons.strokeRoundedCancel01` | 3 usages - clear |
| `CupertinoIcons.chevron_down` | | 3 usages - dropdown |
| `CupertinoIcons.archivebox` | `HugeIcons.strokeRoundedArchive` | 3 usages - pantry |
| `CupertinoIcons.add_circled` | `HugeIcons.strokeRoundedAddCircle` | 3 usages - add |
| `CupertinoIcons.add` | `HugeIcons.strokeRoundedAdd01` | 3 usages - add |
| `CupertinoIcons.xmark_circle_fill` | | 2 usages - dismiss |
| `CupertinoIcons.timer` | `HugeIcons.strokeRoundedTimer01` | 2 usages - timer |
| `CupertinoIcons.plus_circle` | `HugeIcons.strokeRoundedAddCircle` | 2 usages - add |
| `CupertinoIcons.plus` | `HugeIcons.strokeRoundedAdd01` | 2 usages - plus |
| `CupertinoIcons.person_2` | `HugeIcons.strokeRoundedUserGroup` | 2 usages - people |
| `CupertinoIcons.minus` | `HugeIcons.strokeRoundedMinusSign` | 2 usages - minus |
| `CupertinoIcons.mail` | `HugeIcons.strokeRoundedMail01` | 2 usages - email |
| `CupertinoIcons.lightbulb` | `HugeIcons.strokeRoundedIdea01` | 2 usages - idea |
| `CupertinoIcons.house` | `HugeIcons.strokeRoundedHome01` | 2 usages - home |
| `CupertinoIcons.flame_fill` | `HugeIcons.strokeRoundedFire` | 2 usages - trending |
| `CupertinoIcons.doc_text_search` | `HugeIcons.strokeRoundedFileSearch` | 2 usages - search doc |
| `CupertinoIcons.cube_box` | | 2 usages - box |
| `CupertinoIcons.clock` | `HugeIcons.strokeRoundedClock01` | 2 usages - clock |
| `CupertinoIcons.checkmark_alt_circle` | | 2 usages - check |
| `CupertinoIcons.arrow_up_doc` | | 2 usages - upload |
| `CupertinoIcons.arrow_down_doc` | | 2 usages - download |

#### Single Usage (1 each)
| Current | New | Notes |
|---------|-----|-------|
| `CupertinoIcons.xmark` | `HugeIcons.strokeRoundedCancel01` | close |
| `CupertinoIcons.tray` | `HugeIcons.strokeRoundedInbox` | folder |
| `CupertinoIcons.time` | `HugeIcons.strokeRoundedTime01` | time |
| `CupertinoIcons.textformat_size` | `HugeIcons.strokeRoundedTextFont` | text size |
| `CupertinoIcons.star_fill` | `HugeIcons.solidRoundedStar` | favorite |
| `CupertinoIcons.square_arrow_left` | | sign out |
| `CupertinoIcons.square_arrow_down` | | export |
| `CupertinoIcons.sort_up` | | sort asc |
| `CupertinoIcons.sort_down` | | sort desc |
| `CupertinoIcons.shopping_cart` | `HugeIcons.strokeRoundedShoppingCart01` | cart |
| `CupertinoIcons.shield` | `HugeIcons.strokeRoundedShield01` | security |
| `CupertinoIcons.share` | `HugeIcons.strokeRoundedShare01` | share |
| `CupertinoIcons.settings` | `HugeIcons.strokeRoundedSettings01` | settings |
| `CupertinoIcons.refresh` | `HugeIcons.strokeRoundedRefresh` | refresh |
| `CupertinoIcons.question_circle` | `HugeIcons.strokeRoundedHelpCircle` | help |
| `CupertinoIcons.qrcode` | `HugeIcons.strokeRoundedQrCode` | QR code |
| `CupertinoIcons.person_badge_minus` | `HugeIcons.strokeRoundedUserMinus01` | remove member |
| `CupertinoIcons.paintbrush` | `HugeIcons.strokeRoundedPaintBrush01` | appearance |
| `CupertinoIcons.number` | | numbers |
| `CupertinoIcons.minus_circle` | | remove |
| `CupertinoIcons.heart` | `HugeIcons.strokeRoundedFavourite` | like |
| `CupertinoIcons.hand_draw` | `HugeIcons.strokeRoundedEdit01` | manual |
| `CupertinoIcons.flag` | `HugeIcons.strokeRoundedFlag01` | flag |
| `CupertinoIcons.exclamationmark_circle` | | alert |
| `CupertinoIcons.doc_text_fill` | `HugeIcons.solidRoundedFile01` | doc filled |
| `CupertinoIcons.doc_on_clipboard` | | clipboard |
| `CupertinoIcons.compass` | `HugeIcons.strokeRoundedCompass01` | navigation |
| `CupertinoIcons.circle_lefthalf_fill` | | dark mode |
| `CupertinoIcons.chevron_up` | | expand |
| `CupertinoIcons.chevron_left` | | back |
| `CupertinoIcons.checkmark_square_fill` | | checked |
| `CupertinoIcons.check_mark_circled_solid` | | confirm |
| `CupertinoIcons.chat_bubble_2` | `HugeIcons.strokeRoundedMessage01` | feedback |
| `CupertinoIcons.calendar_today` | `HugeIcons.strokeRoundedCalendar01` | today |
| `CupertinoIcons.calendar_badge_plus` | `HugeIcons.strokeRoundedCalendarAdd01` | add event |
| `CupertinoIcons.bookmark_fill` | `HugeIcons.solidRoundedBookmark01` | bookmarked |
| `CupertinoIcons.bookmark` | `HugeIcons.strokeRoundedBookmark01` | bookmark |
| `CupertinoIcons.bolt` | `HugeIcons.strokeRoundedFlash` | power |
| `CupertinoIcons.arrow_up_arrow_down` | | sort |
| `CupertinoIcons.arrow_right_square` | | action |

### Material Icons Replacements

#### High Frequency (5+)
| Current | New | Notes |
|---------|-----|-------|
| `Icons.add` | | 12 usages - add buttons |
| `Icons.delete` | | 10 usages - delete |
| `Icons.close` | | 8 usages - close modal |
| `Icons.keyboard_arrow_down` | | 7 usages - dropdown |
| `Icons.drag_handle` | | 7 usages - reorder |
| `Icons.search` | | 6 usages - search |
| `Icons.more_horiz` | | 6 usages - overflow |
| `Icons.tune` | | 5 usages - filter |
| `Icons.chevron_right` | | 5 usages - disclosure |
| `Icons.check_circle` | | 5 usages - selected |
| `Icons.check` | | 5 usages - checkmark |

#### Medium Frequency (3-4)
| Current | New | Notes |
|---------|-----|-------|
| `Icons.segment` | | 4 usages - divider |
| `Icons.menu` | | 4 usages - menu |
| `Icons.error_outline` | | 4 usages - error |
| `Icons.delete_outline` | | 4 usages - delete |
| `Icons.arrow_drop_down` | | 4 usages - dropdown |
| `Icons.keyboard_arrow_up` | | 3 usages - expand |
| `Icons.home` | | 3 usages - home |
| `Icons.edit` | | 3 usages - edit |
| `Icons.sort` | | 3 usages - sort |

#### Low Frequency (1-2)
| Current | New | Notes |
|---------|-----|-------|
| `Icons.shopping_cart` | | 2 usages - cart |
| `Icons.refresh` | | 2 usages - refresh |
| `Icons.remove` | | 2 usages - remove |
| `Icons.visibility_outlined` | | 2 usages - visibility |
| `Icons.access_time` | | 1 usage - time |
| `Icons.account_circle` | | 1 usage - account |
| `Icons.add_circle_outline` | | 1 usage - add |
| `Icons.add_photo_alternate` | | 1 usage - add photo |
| `Icons.arrow_back` | | 1 usage - back |
| `Icons.arrow_back_rounded` | | 1 usage - back |
| `Icons.arrow_downward` | | 1 usage - down |
| `Icons.arrow_forward` | | 1 usage - forward |
| `Icons.arrow_forward_ios` | | 1 usage - forward |
| `Icons.arrow_upward` | | 1 usage - up |
| `Icons.bar_chart` | | 1 usage - chart |
| `Icons.bookmark` | | 1 usage - bookmark |
| `Icons.bookmark_outline` | | 1 usage - bookmark |
| `Icons.calendar_month` | | 1 usage - calendar |
| `Icons.camera_alt` | | 1 usage - camera |
| `Icons.cancel` | | 1 usage - cancel |
| `Icons.cancel_outlined` | | 1 usage - cancel |
| `Icons.clear` | | 1 usage - clear |
| `Icons.clear_all` | | 1 usage - clear all |
| `Icons.download` | | 1 usage - download |
| `Icons.drive_file_rename_outline` | | 1 usage - rename |
| `Icons.edit_note` | | 1 usage - edit note |
| `Icons.food_bank` | | 1 usage - food |
| `Icons.format_list_bulleted` | | 1 usage - list |
| `Icons.format_list_numbered` | | 1 usage - numbered |
| `Icons.help_outline` | | 1 usage - help |
| `Icons.history` | | 1 usage - history |
| `Icons.info` | | 1 usage - info |
| `Icons.inventory_2_outlined` | | 1 usage - inventory |
| `Icons.kitchen` | | 1 usage - kitchen |
| `Icons.link` | | 1 usage - link |
| `Icons.link_off` | | 1 usage - unlink |
| `Icons.login` | | 1 usage - login |
| `Icons.more_vert` | | 1 usage - more vert |
| `Icons.note_add_outlined` | | 1 usage - add note |
| `Icons.north` | | 1 usage - north |
| `Icons.open_in_new` | | 1 usage - external |
| `Icons.photo_camera_outlined` | | 1 usage - camera |
| `Icons.photo_library` | | 1 usage - photos |
| `Icons.play_arrow` | | 1 usage - play |
| `Icons.restaurant_menu` | | 1 usage - menu |
| `Icons.search_off` | | 1 usage - no results |
| `Icons.settings` | | 1 usage - settings |
| `Icons.south` | | 1 usage - south |
| `Icons.star_outline_rounded` | | 1 usage - star |
| `Icons.star_rounded` | | 1 usage - star filled |
| `Icons.timer` | | 1 usage - timer |

---

## CupertinoIcons Detail

### High Frequency (10+ usages)

#### `CupertinoIcons.book` (21 usages)
Recipe/meal plan item icons
| File | Line | Context |
|------|------|---------|
| `lib/src/features/meal_plans/widgets/meal_plan_item_tile.dart` | 53, 210 | Menu image, return |
| `lib/src/features/meal_plans/widgets/meal_plan_date_header.dart` | 79 | Header icon |
| `lib/src/features/recipes/views/recipes_root.dart` | 124 | Navigation icon |
| `lib/src/mobile/main_page_shell.dart` | 171 | Navigation tab |
| Plus ~16 more in meal plan and recipe features | | |

#### `CupertinoIcons.check_mark` (15 usages)
Confirmation checkmarks
| File | Line | Context |
|------|------|---------|
| `lib/src/features/clippings/widgets/recipe_preview_result.dart` | 294-309 | 4 instances |
| `lib/src/features/share/widgets/share_recipe_preview_result.dart` | 339-354 | 4 instances |
| `lib/src/features/shopping_list/views/manage_shopping_lists_modal.dart` | 164 | Selection |

#### `CupertinoIcons.doc_text` (14 usages)
Document/note icons
| File | Line | Context |
|------|------|---------|
| `lib/src/features/meal_plans/widgets/meal_plan_item_tile.dart` | 212 | Item type |
| `lib/src/features/clippings/views/clippings_root.dart` | 73 | Navigation |
| `lib/src/features/settings/views/settings_page.dart` | 198 | Settings row |

#### `CupertinoIcons.trash` (11 usages)
Delete/removal buttons
| File | Line | Context |
|------|------|---------|
| `lib/src/features/clippings/widgets/clipping_card.dart` | 55 | Card action |
| `lib/src/features/pantry/widgets/pantry_item_list.dart` | 374 | List action |
| `lib/src/features/shopping_list/views/shopping_list_root.dart` | 164 | List action |
| Plus 8 more locations | | |

#### `CupertinoIcons.sparkles` (11 usages)
AI/magic features
| File | Line | Context |
|------|------|---------|
| `lib/src/features/clippings/widgets/recipe_preview_result.dart` | 133 | AI indicator |
| `lib/src/features/clippings/views/clipping_editor_page.dart` | 588 | Enhancement |
| `lib/src/features/share/widgets/share_recipe_preview_result.dart` | 162 | AI indicator |

#### `CupertinoIcons.list_bullet` (11 usages)
List/bullet indicators
| File | Line | Context |
|------|------|---------|
| `lib/src/features/clippings/views/clipping_editor_page.dart` | 598 | List type |
| `lib/src/features/clippings/views/clipping_shopping_list_modal.dart` | 772, 784 | List items |
| `lib/src/features/meal_plans/views/add_to_shopping_list_modal.dart` | 706, 718 | List items |

#### `CupertinoIcons.chevron_right` (11 usages)
Navigation/disclosure
| File | Line | Context |
|------|------|---------|
| `lib/src/features/settings/widgets/settings_row.dart` | 77 | Row disclosure |
| `lib/src/features/import_export/views/import_page.dart` | 188 | Navigation |
| `lib/src/features/recipes/views/add_smart_folder_modal.dart` | 199 | Disclosure |
| `lib/src/features/recipes/views/recipe_creation_menu_modal.dart` | 336 | Option row |

#### `CupertinoIcons.checkmark_circle_fill` (11 usages)
Selected state (filled circles)
| File | Line | Context |
|------|------|---------|
| `lib/src/features/pantry/widgets/pantry_item_list.dart` | 319, 334, 349 | Selection |
| `lib/src/features/recipes/views/add_smart_folder_modal.dart` | 892 | Selection |
| `lib/src/features/recipes/widgets/scale_convert/scale_convert_panel.dart` | 265, 717, 734, 751 | Selection |

#### `CupertinoIcons.line_horizontal_3` (10 usages)
Drag handle/hamburger
| File | Line | Context |
|------|------|---------|
| `lib/src/features/meal_plans/widgets/meal_plan_item_simple_drag.dart` | 120 | Drag handle |
| `lib/src/features/meal_plans/widgets/meal_plan_item_draggable.dart` | 110 | Drag handle |
| `lib/src/features/meal_plans/widgets/meal_plan_item_lifted.dart` | 282, 289 | Drag handle |

### Medium Frequency (5-9 usages)

| Icon | Count | Primary Use |
|------|-------|-------------|
| `CupertinoIcons.pencil` | 8 | Edit buttons |
| `CupertinoIcons.wand_stars` | 7 | AI enhancement |
| `CupertinoIcons.square` | 7 | Empty checkbox |
| `CupertinoIcons.checkmark` | 7 | Checkmark |
| `CupertinoIcons.cart` | 7 | Shopping cart |
| `CupertinoIcons.bars` | 7 | Menu/hamburger |
| `CupertinoIcons.lock_fill` | 6 | Premium/locked |
| `CupertinoIcons.circle_fill` | 6 | Filled circle |
| `CupertinoIcons.circle` | 6 | Empty circle |
| `CupertinoIcons.delete` | 5 | Delete action |

### Low Frequency (2-4 usages)

| Icon | Count | Primary Use |
|------|-------|-------------|
| `CupertinoIcons.sidebar_left` | 4 | Sidebar toggle |
| `CupertinoIcons.link` | 4 | URL/link |
| `CupertinoIcons.folder` | 4 | Folder icon |
| `CupertinoIcons.cart_badge_plus` | 4 | Add to cart |
| `CupertinoIcons.camera` | 4 | Camera/photo |
| `CupertinoIcons.calendar` | 4 | Calendar |
| `CupertinoIcons.tag` | 3 | Tag/label |
| `CupertinoIcons.search` | 3 | Search |
| `CupertinoIcons.photo` | 3 | Photo/image |
| `CupertinoIcons.person_circle_fill` | 3 | User profile |
| `CupertinoIcons.person_circle` | 3 | User profile |
| `CupertinoIcons.home` | 3 | Home |
| `CupertinoIcons.globe` | 3 | Globe/web |
| `CupertinoIcons.exclamationmark_triangle` | 3 | Warning |
| `CupertinoIcons.ellipsis` | 3 | More options |
| `CupertinoIcons.clear` | 3 | Clear/close |
| `CupertinoIcons.chevron_down` | 3 | Dropdown |
| `CupertinoIcons.archivebox` | 3 | Pantry/storage |
| `CupertinoIcons.add_circled` | 3 | Add (circled) |
| `CupertinoIcons.add` | 3 | Add/plus |
| `CupertinoIcons.xmark_circle_fill` | 2 | Dismiss |
| `CupertinoIcons.timer` | 2 | Timer |
| `CupertinoIcons.plus_circle` | 2 | Add (circled) |
| `CupertinoIcons.plus` | 2 | Plus |
| `CupertinoIcons.person_2` | 2 | People |
| `CupertinoIcons.minus` | 2 | Minus |
| `CupertinoIcons.mail` | 2 | Email |
| `CupertinoIcons.lightbulb` | 2 | Idea/help |
| `CupertinoIcons.house` | 2 | House/home |
| `CupertinoIcons.flame_fill` | 2 | Hot/trending |
| `CupertinoIcons.doc_text_search` | 2 | Search doc |
| `CupertinoIcons.cube_box` | 2 | Box/container |
| `CupertinoIcons.clock` | 2 | Clock |
| `CupertinoIcons.checkmark_alt_circle` | 2 | Check (alt) |
| `CupertinoIcons.arrow_up_doc` | 2 | Upload |
| `CupertinoIcons.arrow_down_doc` | 2 | Download |

### Single Usage (1 each)

| Icon | File | Context |
|------|------|---------|
| `CupertinoIcons.xmark` | global_status_bar | Close |
| `CupertinoIcons.tray` | sort_folders | Folder variant |
| `CupertinoIcons.time` | sort_folders | Time |
| `CupertinoIcons.textformat_size` | layout_appearance | Text size |
| `CupertinoIcons.star_fill` | meal_plan_search | Favorite |
| `CupertinoIcons.square_arrow_left` | account_page | Sign out |
| `CupertinoIcons.square_arrow_down` | import_export | Export |
| `CupertinoIcons.sort_up` | sort_folders | Sort asc |
| `CupertinoIcons.sort_down` | sort_folders | Sort desc |
| `CupertinoIcons.shopping_cart` | menu | Cart |
| `CupertinoIcons.shield` | settings | Security |
| `CupertinoIcons.share` | various | Share |
| `CupertinoIcons.settings` | menu | Settings |
| `CupertinoIcons.refresh` | discover | Refresh |
| `CupertinoIcons.question_circle` | settings | Help |
| `CupertinoIcons.qrcode` | household | QR code |
| `CupertinoIcons.person_badge_minus` | household | Remove |
| `CupertinoIcons.paintbrush` | settings | Appearance |
| `CupertinoIcons.number` | scale_convert | Numbers |
| `CupertinoIcons.minus_circle` | household | Remove |
| `CupertinoIcons.heart` | settings | Like |
| `CupertinoIcons.hand_draw` | sort_folders | Manual |
| `CupertinoIcons.flag` | scale_convert | Flag |
| `CupertinoIcons.exclamationmark_circle` | paywall | Alert |
| `CupertinoIcons.doc_text_fill` | clippings | Doc filled |
| `CupertinoIcons.doc_on_clipboard` | household | Clipboard |
| `CupertinoIcons.compass` | menu | Navigation |
| `CupertinoIcons.circle_lefthalf_fill` | layout | Dark mode |
| `CupertinoIcons.chevron_up` | FAB | Expand |
| `CupertinoIcons.chevron_left` | discover | Back |
| `CupertinoIcons.checkmark_square_fill` | clipping_editor | Checked |
| `CupertinoIcons.check_mark_circled_solid` | pantry | Confirm |
| `CupertinoIcons.chat_bubble_2` | settings | Feedback |
| `CupertinoIcons.calendar_today` | menu | Today |
| `CupertinoIcons.calendar_badge_plus` | meal_plan | Add event |
| `CupertinoIcons.bookmark_fill` | recipe | Bookmarked |
| `CupertinoIcons.bookmark` | recipe | Bookmark |
| `CupertinoIcons.bolt` | macos | Power |
| `CupertinoIcons.arrow_up_arrow_down` | layout | Sort |
| `CupertinoIcons.arrow_right_square` | household | Action |

---

## Material Icons Detail

### High Frequency (5+ usages)

#### `Icons.add` (12 usages)
Add buttons throughout app
| File | Line | Context |
|------|------|---------|
| `lib/src/features/pantry/views/pantry_root.dart` | 103 | Add pantry item |
| `lib/src/features/pantry/views/update_pantry_item_modal.dart` | 311 | Add action |
| `lib/src/features/recipes/views/recipes_folder_page.dart` | 392 | Add recipe |
| `lib/src/features/recipes/widgets/recipe_editor_form/sections/ingredients_section.dart` | 168 | Add ingredient |
| `lib/src/features/recipes/widgets/recipe_editor_form/sections/steps_section.dart` | 168 | Add step |
| `lib/src/features/recipes/widgets/folder_selection_pages.dart` | 89 | Add folder |
| `lib/src/features/recipes/widgets/tag_selection_pages.dart` | 91 | Add tag |
| `lib/src/features/shopping_list/views/shopping_list_root.dart` | 298 | Add item |
| `lib/src/widgets/app_circle_button.dart` | 43 | Circle button |

#### `Icons.delete` (10 usages)
Delete actions
| File | Line | Context |
|------|------|---------|
| `lib/src/features/pantry/views/update_pantry_item_modal.dart` | 424 | Delete item |
| `lib/src/features/recipes/widgets/folder_card.dart` | 181 | Delete folder |
| `lib/src/features/recipes/widgets/recipe_tile.dart` | 109 | Delete recipe |
| `lib/src/features/recipes/widgets/recipe_editor_form/items/ingredient_list_item.dart` | 322 | Delete ingredient |

#### `Icons.close` (8 usages)
Close/dismiss modals
| File | Line | Context |
|------|------|---------|
| `lib/src/features/recipes/views/photo_capture_review_modal.dart` | 803 | Close modal |
| `lib/src/features/recipes/widgets/filter_sort/recipe_sort_modal.dart` | 77 | Close modal |
| `lib/src/widgets/wolt/button/wolt_modal_sheet_close_button.dart` | 20 | Close button |
| `lib/src/widgets/wolt/utils/drawer_menu_button.dart` | 19 | Close drawer |

#### `Icons.keyboard_arrow_down` (7 usages)
Dropdown/collapse indicators
| File | Line | Context |
|------|------|---------|
| `lib/src/features/pantry/widgets/filter_sort/unified_pantry_sort_filter_sheet.dart` | 325 | Dropdown |
| `lib/src/features/recipes/widgets/filter_sort/unified_sort_filter_sheet.dart` | 685 | Dropdown |
| `lib/src/features/recipes/widgets/cook_modal/ingredients_sheet.dart` | 162 | Collapse |
| `lib/src/features/shopping_list/views/shopping_list_root.dart` | 281 | Dropdown |

#### `Icons.drag_handle` (7 usages)
Reorderable list handles
| File | Line | Context |
|------|------|---------|
| `lib/src/features/pantry/views/update_pantry_item_modal.dart` | 467 | Reorder |
| `lib/src/features/recipes/views/ingredient_matches_page.dart` | 323 | Reorder |
| `lib/src/features/recipes/widgets/recipe_editor_form/items/ingredient_list_item.dart` | 414 | Reorder |
| `lib/src/features/recipes/widgets/recipe_editor_form/items/step_list_item.dart` | 391 | Reorder |

#### `Icons.search` (6 usages)
Search inputs
| File | Line | Context |
|------|------|---------|
| `lib/src/features/recipes/widgets/recipe_editor_form/items/ingredient_list_item.dart` | 650 | Search |
| `lib/src/features/recipes/widgets/recipe_view/pantry_item_selector_bottom_sheet.dart` | 158 | Search |
| `lib/src/mobile/utils/adaptive_sliver_page.dart` | 275 | Search |

#### `Icons.more_horiz` (6 usages)
Overflow/more actions
| File | Line | Context |
|------|------|---------|
| `lib/src/features/pantry/widgets/pantry_item_list.dart` | 382 | More actions |
| `lib/src/widgets/app_circle_button.dart` | 45 | Circle button |
| `lib/src/widgets/app_overflow_button.dart` | 43 | Overflow menu |

#### `Icons.tune` (5 usages)
Filter/tune buttons
| File | Line | Context |
|------|------|---------|
| `lib/src/features/pantry/views/pantry_root.dart` | 57 | Filter |
| `lib/src/features/recipes/views/recipes_folder_page.dart` | 313, 355 | Filter |
| `lib/src/features/recipes/widgets/folder_card.dart` | 176 | Filter |

#### `Icons.chevron_right` (5 usages)
Navigation disclosure
| File | Line | Context |
|------|------|---------|
| `lib/src/features/recipes/widgets/recipe_editor_form/items/folder_assignment_row.dart` | 92 | Navigate |
| `lib/src/features/recipes/widgets/recipe_view/ingredient_matches_bottom_sheet.dart` | 487, 589, 2363 | Navigate |

#### `Icons.check_circle` (5 usages)
Selected state
| File | Line | Context |
|------|------|---------|
| `lib/src/features/pantry/widgets/filter_sort/unified_pantry_sort_filter_sheet.dart` | 313 | Selected |
| `lib/src/features/recipes/widgets/filter_sort/unified_sort_filter_sheet.dart` | 672 | Selected |
| `lib/src/widgets/tag_selection_row.dart` | 43 | Selected |

#### `Icons.check` (5 usages)
Checkmark
| File | Line | Context |
|------|------|---------|
| `lib/src/features/recipes/widgets/filter_sort/recipe_sort_dropdown.dart` | 73 | Check |
| `lib/src/widgets/app_checkbox.dart` | 102 | Checkbox |
| `lib/src/widgets/app_checkbox_square.dart` | 42 | Checkbox |

### Medium Frequency (3-4 usages)

| Icon | Count | Primary Use |
|------|-------|-------------|
| `Icons.segment` | 4 | Divider options |
| `Icons.menu` | 4 | Menu toggle |
| `Icons.error_outline` | 4 | Error states |
| `Icons.delete_outline` | 4 | Delete (outline) |
| `Icons.arrow_drop_down` | 4 | Dropdown |
| `Icons.keyboard_arrow_up` | 3 | Expand |
| `Icons.home` | 3 | Home nav |
| `Icons.edit` | 3 | Edit action |
| `Icons.sort` | 3 | Sort toggle |

### Low Frequency (1-2 usages)

Many icons with single usage across various features. See source files for complete list.

---

## Custom Icons

### AppCircleButtonIcon Enum
File: `lib/src/widgets/app_circle_button.dart`

| Enum Value | Maps To | Usage |
|------------|---------|-------|
| `plus` | `Icons.add` | Add buttons |
| `ellipsis` | `Icons.more_horiz` | More options |
| `pencil` | `Icons.edit` | Edit buttons |
| `close` | `Icons.close` | Close modals |
| `back` | `Icons.arrow_back_rounded` | Back navigation |
| `list` | `Icons.format_list_bulleted` | List view |
| `info` | Italic "i" text | Info buttons |

---

## SVG Assets

| File | Used In | Purpose |
|------|---------|---------|
| `assets/images/empty_folder.svg` | `lib/src/features/recipes/widgets/folder_tile.dart:155-159` | Empty folder state |
| `assets/images/sidebar.svg` | Not currently used | Sidebar visual |

---

## Icon Usage by Feature Area

| Feature | CupertinoIcons | Material Icons |
|---------|----------------|----------------|
| Recipes | ~35 | ~60 |
| Meal Plans | ~40 | ~15 |
| Shopping List | ~30 | ~25 |
| Pantry | ~20 | ~30 |
| Settings | ~25 | ~15 |
| Clippings | ~20 | ~10 |
| Navigation | ~15 | ~10 |
| Modals/Shared | ~30 | ~40 |

---

## Notes for Migration

1. **Duplicate concepts**: Some icons serve the same purpose but use different variants:
   - Delete: `CupertinoIcons.trash`, `CupertinoIcons.delete`, `Icons.delete`, `Icons.delete_outline`
   - Add: `CupertinoIcons.add`, `CupertinoIcons.add_circled`, `CupertinoIcons.plus`, `CupertinoIcons.plus_circle`, `Icons.add`
   - Checkmarks: `CupertinoIcons.check_mark`, `CupertinoIcons.checkmark`, `Icons.check`, `Icons.check_circle`

2. **Platform consistency**: Currently mixing Cupertino and Material icons. New icon pack should unify this.

3. **AppCircleButton abstraction**: The `AppCircleButtonIcon` enum wraps Material icons. Update this mapping when switching packs.

4. **Size considerations**: Current icons use various sizes (18, 20, 22, 24, 28). New pack should support these sizes or standardize.
