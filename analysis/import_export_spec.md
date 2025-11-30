# Recipe Import/Export System Specification

## Overview

This document specifies the design for a recipe import/export system that supports:
- **Export**: Stockpot native format (JSON in ZIP archive)
- **Import**: Stockpot native format, Paprika, and Crouton

The system is designed to be extensible for future format additions.

---

## 1. Data Model Analysis

### 1.1 Stockpot (Our App) Recipe Schema

**Recipe Fields:**
| Field | Type | Description |
|-------|------|-------------|
| `id` | `String` (UUID) | Unique identifier |
| `title` | `String` | Recipe name |
| `description` | `String?` | Optional description |
| `rating` | `int?` | 0-5 rating |
| `language` | `String?` | Language code |
| `servings` | `int?` | Number of servings |
| `prepTime` | `int?` | Prep time in minutes |
| `cookTime` | `int?` | Cook time in minutes |
| `totalTime` | `int?` | Total time in minutes |
| `source` | `String?` | Recipe source name |
| `nutrition` | `String?` | Nutrition info text |
| `generalNotes` | `String?` | General notes |
| `ingredients` | `List<Ingredient>` | Structured ingredients |
| `steps` | `List<Step>` | Structured steps |
| `images` | `List<RecipeImage>` | Images with metadata |
| `folderIds` | `List<String>` | Associated folder UUIDs |
| `tagIds` | `List<String>` | Associated tag UUIDs |
| `pinned` | `int?` | Pin status (0/1) |
| `createdAt` | `int?` | Unix timestamp (ms) |
| `updatedAt` | `int?` | Unix timestamp (ms) |

**Ingredient Structure:**
```json
{
  "id": "uuid",
  "type": "ingredient|section",
  "name": "1 cup sugar",
  "note": "optional note",
  "terms": [{"value": "sugar", "source": "ai", "sort": 0}],
  "isCanonicalised": true,
  "category": "baking",
  "recipeId": null
}
```

*Note: Quantity/unit fields exist in the model but are unused - quantities are embedded in the `name` field (e.g., "1 cup sugar"). The amount fields (`primaryAmount1Value`, etc.) are legacy and always null.*

**Step Structure:**
```json
{
  "id": "uuid",
  "type": "step|section|timer",
  "text": "Step instruction text",
  "note": "optional note",
  "timerDurationSeconds": null
}
```

**RecipeImage Structure:**
```json
{
  "id": "uuid",
  "fileName": "image.jpg",
  "isCover": true,
  "publicUrl": "https://..."
}
```

### 1.2 Paprika Recipe Schema

**File Format:** `.paprikarecipes` is a ZIP containing multiple `.paprikarecipe` files, each is gzip-compressed JSON.

**Recipe Fields:**
| Field | Type | Description |
|-------|------|-------------|
| `uid` | `String` | UUID identifier |
| `name` | `String` | Recipe name |
| `description` | `String` | Description |
| `ingredients` | `String` | Plain text (newline-separated) |
| `directions` | `String` | Plain text (paragraph-separated) |
| `notes` | `String` | Notes text |
| `source` | `String` | Source name |
| `source_url` | `String` | Source URL |
| `prep_time` | `String` | Human-readable (e.g., "15 mins") |
| `cook_time` | `String` | Human-readable |
| `total_time` | `String` | Human-readable |
| `servings` | `String` | Human-readable (e.g., "24") |
| `rating` | `int` | 0-5 rating |
| `nutritional_info` | `String` | Nutrition text |
| `categories` | `List<String>` | Category/folder names |
| `photo` | `String` | Primary photo filename |
| `photo_data` | `String` | Base64-encoded primary image |
| `photo_hash` | `String` | Hash of primary image |
| `photos` | `List<{filename, data}>` | Additional photos |
| `image_url` | `String` | Original image URL |
| `difficulty` | `String` | Difficulty level |
| `created` | `String` | Date string "YYYY-MM-DD HH:MM:SS" |
| `hash` | `String` | Recipe content hash |

**Key Observations:**
- Ingredients and directions are plain text, not structured
- Supports special markdown-like syntax: `[recipe:Name]`, `[link](url)`, `[photo:N]`
- Categories serve as tags/folders
- Images stored as base64 in `photo_data` (primary) and `photos[]` array

### 1.3 Crouton Recipe Schema

**File Format:** `.zip` containing multiple `.crumb` files, each is plain JSON.

**Recipe Fields:**
| Field | Type | Description |
|-------|------|-------------|
| `uuid` | `String` | UUID identifier |
| `name` | `String` | Recipe name |
| `serves` | `int?` | Number of servings |
| `duration` | `int?` | Prep time in seconds |
| `cookingDuration` | `int?` | Cook time in seconds |
| `defaultScale` | `double` | Default scaling factor |
| `webLink` | `String?` | Source URL |
| `notes` | `String?` | Notes text |
| `neutritionalInfo` | `String?` | Nutrition text (note: typo in format) |
| `ingredients` | `List<CroutonIngredient>` | Structured ingredients |
| `steps` | `List<CroutonStep>` | Structured steps |
| `images` | `List<String>` | Base64-encoded images |
| `tags` | `List<String>` | Tag names |
| `folderIDs` | `List<String>` | Folder UUIDs |
| `isPublicRecipe` | `bool` | Public/private flag |

**CroutonIngredient Structure:**
```json
{
  "uuid": "...",
  "order": 0,
  "ingredient": {
    "uuid": "...",
    "name": "Salt"
  },
  "quantity": {
    "amount": 1,
    "quantityType": "TABLESPOON"
  }
}
```

**Known quantityTypes:** `ITEM`, `RECIPE`, `CUP`, `TABLESPOON`, `TEASPOON`, `GRAM`, `KILOGRAM`, `OUNCE`, `POUND`, `MILLILITER`, `LITER`, `PINCH`, etc.

**CroutonStep Structure:**
```json
{
  "uuid": "...",
  "order": 0,
  "step": "Step text",
  "isSection": false
}
```

---

## 2. Stockpot Export Format

### 2.1 Archive Structure

```
stockpot_export_YYYYMMDD_HHMMSS.zip
├── recipe-title-abc123.json
├── another-recipe-def456.json
└── ...
```

**Simplification rationale:**
- No manifest - recipe count derived from file count
- No folders.json - folders created automatically from recipe `folderNames`
- No tags.json - tags created with default color, user can customize after import
- Recipe JSON files at root level (no nested folders)
- On import: match folders/tags by name, create if not found

### 2.2 Recipe JSON Format

Each recipe file contains:

```json
{
  "title": "Recipe Title",
  "description": "Optional description",
  "rating": 5,
  "language": "en",
  "servings": 4,
  "prepTime": 15,
  "cookTime": 30,
  "totalTime": 45,
  "source": "example.com",
  "nutrition": "Nutritional info text",
  "generalNotes": "Notes here",
  "createdAt": 1705312200000,
  "updatedAt": 1705312200000,
  "pinned": false,
  "folderNames": ["Dinner", "Quick Meals"],
  "tagNames": ["vegetarian", "easy"],
  "ingredients": [
    {
      "type": "ingredient",
      "name": "1 cup sugar",
      "note": "optional note",
      "terms": [{"value": "sugar", "source": "ai", "sort": 0}],
      "isCanonicalised": true,
      "category": "baking"
    }
  ],
  "steps": [
    {
      "type": "step",
      "text": "Mix ingredients together",
      "note": null,
      "timerDurationSeconds": null
    }
  ],
  "images": [
    {
      "isCover": true,
      "data": "base64-encoded-image-data",
      "publicUrl": "https://..."
    }
  ]
}
```

**Key Design Decisions:**
- **No IDs exported** - UUIDs are auto-generated on import (IDs are meaningless across accounts)
- Use folder/tag **names** instead of IDs for portability across accounts
- Include ingredient terms for re-import (preserves canonicalization work)
- **Images**: Include `publicUrl` if available. On export:
  - If `publicUrl` exists: include URL only, skip base64 data (reduces file size)
  - If no `publicUrl` (user not logged in): include base64 data
- On import: prefer `publicUrl` if present, fall back to `data`
- Each recipe is a separate file for easier debugging and partial imports
- Filenames: `{sanitized-title}-{short-hash}.json` to ensure uniqueness

---

## 3. Field Mappings

### 3.1 Paprika → Stockpot

| Paprika Field | Stockpot Field | Transformation |
|---------------|----------------|----------------|
| `uid` | `id` | Direct |
| `name` | `title` | Direct |
| `description` | `description` | Direct |
| `ingredients` | `ingredients` | Parse text to structured (see 3.3) |
| `directions` | `steps` | Parse text to structured (see 3.3) |
| `notes` | `generalNotes` | Direct |
| `source` | `source` | Direct |
| `source_url` | — | Could append to `source` or `generalNotes` |
| `prep_time` | `prepTime` | Parse "15 mins" → 15 |
| `cook_time` | `cookTime` | Parse "20 mins" → 20 |
| `total_time` | `totalTime` | Parse or calculate |
| `servings` | `servings` | Parse "24" → 24 |
| `rating` | `rating` | Direct (0-5) |
| `nutritional_info` | `nutrition` | Direct |
| `categories` | `tagNames` | Map to tags (create if needed) |
| `photo_data` | `images[0]` | Decode base64, mark as cover |
| `photos[]` | `images[1+]` | Decode base64 |
| `created` | `createdAt` | Parse date → Unix ms |
| `difficulty` | — | Ignored (no equivalent) |
| `image_url` | — | Ignored (we have actual image) |

### 3.2 Crouton → Stockpot

| Crouton Field | Stockpot Field | Transformation |
|---------------|----------------|----------------|
| `uuid` | `id` | Direct |
| `name` | `title` | Direct |
| `serves` | `servings` | Direct |
| `duration` | `prepTime` | seconds → minutes |
| `cookingDuration` | `cookTime` | seconds → minutes |
| — | `totalTime` | Calculate from prep + cook |
| `webLink` | `source` | Direct |
| `notes` | `generalNotes` | Direct |
| `neutritionalInfo` | `nutrition` | Direct |
| `ingredients[]` | `ingredients` | Map structured (see 3.4) |
| `steps[]` | `steps` | Map structured (see 3.4) |
| `images[]` | `images` | Direct base64, first is cover |
| `tags[]` | `tagNames` | Direct (create tags if needed) |
| `folderIDs` | `folderNames` | — Ignored (IDs meaningless) |
| `defaultScale` | — | Ignored |
| `isPublicRecipe` | — | Ignored |

### 3.3 Paprika Text Parsing

**Ingredients:**
- Split by newlines
- Each line becomes one ingredient
- Attempt to parse quantity/unit from start of line (e.g., "1 cup sugar" → qty: 1, unit: cup, name: sugar)
- Lines starting with special characters could be sections
- Handle `[recipe:Name]` syntax → sub-recipe reference
- Handle `[photo:N]` syntax → ignore (inline photo reference)

**Directions:**
- Split by double newlines (paragraphs) or numbered patterns (1., 2., etc.)
- Each paragraph/number becomes one step
- No structured sections in Paprika

### 3.4 Crouton Structured Mapping

**Ingredients:**
```dart
// Combine quantity + unit + name into a single name string
// e.g., amount=1, quantityType=CUP, name=Sugar → "1 cup Sugar"
String buildIngredientName(CroutonIngredient ing) {
  final amount = ing.quantity.amount;
  final unit = mapCroutonUnit(ing.quantity.quantityType);
  final name = ing.ingredient.name;

  if (unit == null) return '$amount $name';  // "2 Apples"
  return '$amount $unit $name';              // "1 cup Sugar"
}

Ingredient(
  // id auto-generated on insert
  type: 'ingredient',
  name: buildIngredientName(crouton),  // Combined string
  // terms: empty (will need canonicalization)
  isCanonicalised: false,
)
```

**Crouton Unit Mapping:**
```dart
String? mapCroutonUnit(String quantityType) {
  return {
    'ITEM': null,  // no unit, just number
    'CUP': 'cup',
    'TABLESPOON': 'tbsp',
    'TEASPOON': 'tsp',
    'GRAM': 'g',
    'KILOGRAM': 'kg',
    'OUNCE': 'oz',
    'POUND': 'lb',
    'MILLILITER': 'ml',
    'LITER': 'l',
    'PINCH': 'pinch',
    'RECIPE': null,  // sub-recipe reference (handle separately)
  }[quantityType];
}
```

**Steps:**
```dart
Step(
  // id auto-generated on insert
  type: crouton.isSection ? 'section' : 'step',
  text: crouton.step,
)
```

---

## 4. System Architecture

### 4.1 Directory Structure

```
lib/src/features/import_export/
├── models/
│   ├── export_recipe.dart        # Clean export-specific model
│   ├── paprika_recipe.dart       # Paprika JSON model
│   └── crouton_recipe.dart       # Crouton JSON model
├── services/
│   ├── export_service.dart       # Export orchestration
│   ├── import_service.dart       # Import orchestration
│   ├── parsers/
│   │   ├── recipe_parser.dart    # Base parser interface
│   │   ├── stockpot_parser.dart  # Our format parser
│   │   ├── paprika_parser.dart   # Paprika format parser
│   │   └── crouton_parser.dart   # Crouton format parser
│   └── converters/
│       ├── recipe_converter.dart # Base converter interface
│       ├── stockpot_converter.dart
│       ├── paprika_converter.dart
│       └── crouton_converter.dart
├── views/
│   ├── import_page.dart          # Import source selection
│   ├── export_page.dart          # Export options
│   └── import_progress_page.dart # Progress/results
├── widgets/
│   └── import_source_row.dart    # List item widget
└── providers/
    └── import_export_provider.dart
```

### 4.2 Core Interfaces

```dart
/// Parses an archive file into raw recipe data
abstract class RecipeParser<T> {
  /// File extensions this parser handles
  List<String> get supportedExtensions;

  /// Parse archive and extract recipes
  Future<List<T>> parseArchive(File archive);

  /// Parse a single recipe file
  T parseRecipe(List<int> bytes, String filename);
}

/// Converts parsed recipe data to our Stockpot model
abstract class RecipeConverter<T> {
  /// Convert external format to our Recipe model
  Future<ImportedRecipe> convert(T source);

  /// Batch convert with progress callback
  Stream<ImportedRecipe> convertAll(
    List<T> sources,
    void Function(int current, int total)? onProgress,
  );
}

/// Represents a recipe ready for import with resolved dependencies
class ImportedRecipe {
  final RecipeEntry recipe;
  final List<String> tagNames;      // Tags to create/resolve
  final List<String> folderNames;   // Folders to create/resolve
  final List<ImageData> images;     // Decoded image data
}
```

### 4.3 Import Flow

```
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│  Select File │ => │ Parse Archive│ => │   Convert    │
│              │    │   (Parser)   │    │  (Converter) │
└──────────────┘    └──────────────┘    └──────────────┘
                                                │
                                                v
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│   Complete   │ <= │ Save Recipes │ <= │Resolve Deps  │
│              │    │  to Database │    │(Tags/Folders)│
└──────────────┘    └──────────────┘    └──────────────┘
```

**Dependency Resolution:**
1. Collect all unique tag/folder names from imported recipes
2. Match against existing tags/folders by name (case-insensitive)
3. Create new tags/folders for unmatched names
4. Build name→ID mapping
5. Apply IDs to recipes before saving

### 4.4 Export Flow

```
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│ Select Scope │ => │ Load Recipes │ => │ Convert to   │
│ (All/Folder) │    │ & Resolve    │    │Export Format │
└──────────────┘    └──────────────┘    └──────────────┘
                                                │
                                                v
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│   Complete   │ <= │ Share/Save   │ <= │  Build ZIP   │
│              │    │   Archive    │    │   Archive    │
└──────────────┘    └──────────────┘    └──────────────┘
```

---

## 5. Implementation Considerations

### 5.1 File Selection

- Use `file_picker` package for cross-platform file selection
- Filter by supported extensions (`.zip`, `.paprikarecipes`)
- Mobile: Also support import from share intent / document picker

### 5.2 Archive Handling

- Use `archive` package for ZIP reading/writing
- Paprika: Need to gunzip individual `.paprikarecipe` files within the ZIP
- Crouton: Direct JSON files within ZIP

### 5.3 Image Handling

**Import:**
- If `publicUrl` present: store URL reference, download image on-demand
- If `data` present (base64): decode to bytes, save to documents directory
- Generate new UUID for image ID
- Queue for upload to Supabase storage (if user is logged in)

**Export:**
- If recipe has `publicUrl`: include URL only, skip base64 (much smaller export)
- If no `publicUrl` (user not logged in, or image not yet uploaded):
  - Read from local file
  - **Resize**: Scale down to max 1200px width (maintaining aspect ratio)
  - **Compress**: JPEG encoding at ~85% quality
  - Encode to base64 and include as `data`

**Image Processing Rationale:**
- Using `publicUrl` when available keeps exports small and fast
- Base64 fallback ensures exports work for users not logged in
- Resizing to 1200px max width keeps images sharp while reducing file size
- JPEG compression at 85% provides good quality/size tradeoff
- A 4MB photo becomes ~200-400KB after processing

### 5.4 Duplicate Handling

**Recipes:**
- Do NOT auto-detect duplicates by name (user might want duplicates)
- Option: "Skip recipes that already exist (by name)" checkbox
- Default: Import all, create duplicates if names match

**Tags/Folders:**
- Match by name (case-insensitive)
- Reuse existing if found
- Create new if not found

### 5.5 Error Handling

- Continue on individual recipe parse failures
- Collect errors and report at end
- Example: "Imported 45/47 recipes. 2 failed: [list]"

### 5.6 Progress Reporting

- Show progress for:
  - Archive extraction
  - Recipe parsing
  - Image processing
  - Database saves
- Use streams for reactive UI updates

### 5.7 Ingredient Parsing (Paprika)

Best-effort parsing for plain-text ingredients:

```dart
/// Parse "1 1/2 cups all-purpose flour, sifted"
ParsedIngredient parseIngredientLine(String line) {
  // Regex patterns for common formats:
  // - "1 cup sugar"
  // - "1/2 lb butter"
  // - "1 1/2 cups flour"
  // - "2-3 cloves garlic"
  // - "salt to taste" (no quantity)
  // - "For the sauce:" (section header)
}
```

### 5.8 Sub-Recipe Handling

**Paprika:**
- `[recipe:Name]` syntax in ingredients
- On import, search for recipe by name
- If found, create sub-recipe reference
- If not found, create plain ingredient with note

**Crouton:**
- `quantityType: "RECIPE"` indicates sub-recipe
- `ingredient.name` contains referenced recipe name
- Same handling as Paprika

### 5.9 Canonicalization

- Imported recipes will have `isCanonicalised: false`
- Queue for background canonicalization after import
- Terms will be populated async by existing system

---

## 6. UI Design

### 6.1 Import Page

```
┌─────────────────────────────────────┐
│ ← Import Recipes                    │
├─────────────────────────────────────┤
│                                     │
│  Import from:                       │
│                                     │
│  ┌─────────────────────────────────┐│
│  │ 📦  Stockpot Export             ││
│  │     Import from a previous      ││
│  │     Stockpot backup             ││
│  └─────────────────────────────────┘│
│                                     │
│  ┌─────────────────────────────────┐│
│  │ 🌶️  Paprika                     ││
│  │     Import from Paprika         ││
│  │     Recipe Manager              ││
│  └─────────────────────────────────┘│
│                                     │
│  ┌─────────────────────────────────┐│
│  │ 🥐  Crouton                     ││
│  │     Import from Crouton         ││
│  │     recipe app                  ││
│  └─────────────────────────────────┘│
│                                     │
└─────────────────────────────────────┘
```

### 6.2 Import Preview / Confirmation Page

After parsing the archive, show a preview before importing:

```
┌─────────────────────────────────────┐
│ ← Import Preview                    │
├─────────────────────────────────────┤
│                                     │
│  Ready to import from Paprika:      │
│                                     │
│  📄 47 recipes                      │
│  🏷️ 12 tags (8 new, 4 existing)    │
│  📁 0 folders                       │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  Paprika Categories                 │
│  Import as:                         │
│                                     │
│  ○ Tags (recommended)               │
│  ○ Folders                          │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  [        Import Recipes        ]   │
│                                     │
└─────────────────────────────────────┘
```

**Preview Details:**
- Show count of recipes to be imported
- Show count of tags (split into "new" vs "existing" that will be matched)
- Show count of folders (split into "new" vs "existing")
- For Paprika imports: Show option to import categories as Tags or Folders
- For Stockpot imports: No extra options needed
- For Crouton imports: Tags only (folders ignored as explained)

### 6.3 Export Page

```
┌─────────────────────────────────────┐
│ ← Export Recipes                    │
├─────────────────────────────────────┤
│                                     │
│  Export options:                    │
│                                     │
│  ┌─────────────────────────────────┐│
│  │ 📦  Export All Recipes          ││
│  │     Create a backup of all      ││
│  │     your recipes                ││
│  └─────────────────────────────────┘│
│                                     │
│  (Future: Export as HTML, etc.)    │
│                                     │
└─────────────────────────────────────┘
```

### 6.4 Import Progress

```
┌─────────────────────────────────────┐
│ Importing...                        │
├─────────────────────────────────────┤
│                                     │
│  ████████████░░░░░░░░  45/100      │
│                                     │
│  Currently importing:               │
│  "Grandma's Apple Pie"              │
│                                     │
│  ✓ Parsed archive                   │
│  ✓ Created 3 new tags               │
│  ✓ Created 2 new folders            │
│  ⋯ Importing recipes...             │
│                                     │
└─────────────────────────────────────┘
```

---

## 7. Future Extensibility

### 7.1 Adding New Import Sources

1. Create `NewAppRecipe` model in `models/`
2. Create `NewAppParser` implementing `RecipeParser<NewAppRecipe>`
3. Create `NewAppConverter` implementing `RecipeConverter<NewAppRecipe>`
4. Register in `ImportService`
5. Add UI row in import page

### 7.2 Additional Export Formats

- HTML cookbook (printable)
- PDF generation
- Markdown files
- Recipe schema.org JSON-LD
- Other app formats (Paprika, etc.)

---

## 8. Design Decisions (Resolved)

1. **Folder handling on import from Crouton:**
   - ✅ **Decision:** Ignore folders entirely (their `folderIDs` are meaningless without folder data)
   - Tags will be imported normally

2. **Paprika categories → Tags or Folders?**
   - ✅ **Decision:** Let user choose on the import preview screen
   - Default to Tags (recommended), but allow Folders option
   - UI shows radio buttons: "Tags (recommended)" / "Folders"

3. **Import confirmation screen?**
   - ✅ **Decision:** Yes, show preview before importing
   - Display counts: recipes, tags (new/existing), folders (new/existing)
   - For Paprika: include categories→tags/folders option
   - User confirms before import begins

4. **Duplicate recipe names in export filename:**
   - ✅ **Decision:** `{title}-{id-prefix}.json`
   - Ensures uniqueness while being human-readable

5. **Image quality/size limits:**
   - ✅ **Decision:** Resize and compress images during export
   - Max width: 1200px (maintain aspect ratio)
   - JPEG quality: ~85%
   - Significantly reduces export file size while maintaining good viewing quality

---

## 9. Dependencies

**New packages needed:**
- `archive` - ZIP file handling
- `file_picker` - Cross-platform file selection

**Existing packages that will be used:**
- `path_provider` - App directories
- `uuid` - ID generation
- `share_plus` - Share export file

---

## 10. Implementation Order

**Phase 1: Export (simpler, establishes our format)**
1. Define export models
2. Implement export service
3. Build ZIP archive
4. Add export UI
5. Test end-to-end

**Phase 2: Import - Stockpot format**
1. Implement Stockpot parser
2. Implement import service
3. Add import UI
4. Test re-importing exported data

**Phase 3: Import - Third-party formats**
1. Implement Paprika parser + converter
2. Implement Crouton parser + converter
3. Test with sample files
4. Handle edge cases

**Phase 4: Polish**
1. Progress UI
2. Error handling
3. Edge cases
4. Documentation
