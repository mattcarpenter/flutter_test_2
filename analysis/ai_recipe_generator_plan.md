# AI Recipe Generator Feature - Design Plan

## Overview

This document outlines the complete implementation plan for the "Generate with AI" feature, which allows users to describe what they want to eat and receive AI-generated recipe suggestions.

## User Flow

```
1. User taps "Generate with AI" from recipes menu
   ↓
2. Bottom sheet opens with:
   - Text input (Flutter Quill editor for checkbox support)
   - "Use pantry items" toggle (disabled if pantry empty)
   - "Generate" button
   ↓
3. If toggle ON: Pantry items added as checkable items to editor
   ↓
4. User taps Generate
   ↓
5. Loading state: "Brainstorming recipes..."
   ↓
6. Backend brainstorm-recipes endpoint returns up to 5 ideas
   ↓
7. Results displayed as selectable cards (Page 2 of modal)
   ↓
8. User selects one recipe idea
   ↓
9. Loading state: "Generating recipe..."
   ↓
10. Backend generate-recipe endpoint returns full recipe
    ↓
11. Recipe editor opens with pre-populated data
```

## Subscription & Rate Limiting Strategy

### Idea Generation (Brainstorming)
- **Free users:** 10 ideas per day (client-side tracking via PreviewUsageService)
- **Plus users:** Unlimited
- **When limit reached:** Show generic message + "Upgrade to Plus" button

### Recipe Generation
- **Free users:** Preview only (title, description, first 4 ingredients with fade effect)
- **Plus users:** Full recipe directly to editor
- **Pattern:** Same as clipping/URL import flow

### Error Handling
- Rate limit (429): "Recipe ideas are limited for free users. Upgrade to Plus for unlimited access."
- Generic button: "Upgrade to Plus" to launch paywall

---

## Frontend Implementation

### 1. New Files to Create

```
lib/src/features/recipes/views/
├── ai_recipe_generator_modal.dart      # Main modal entry point
├── ai_recipe_generator_pages.dart      # Page builders for multi-page modal
└── ai_recipe_generator_view_model.dart # ChangeNotifier for cross-page state

lib/src/services/
└── ai_recipe_service.dart              # API client for new endpoints

lib/src/features/clippings/providers/
└── preview_usage_provider.dart         # (UPDATE) Add idea generation quota tracking
```

### 2. Modal Structure

Using WoltModalSheet with **multi-page navigation** (like TagSelectionModal pattern):

```dart
Future<void> showAiRecipeGeneratorModal(
  BuildContext context, {
  required WidgetRef ref,
  String? folderId,
}) async {
  await WoltModalSheet.show<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    modalDecorator: (child) {
      // Wrap in ChangeNotifierProvider for cross-page state
      return provider.ChangeNotifierProvider<AiRecipeGeneratorViewModel>(
        create: (_) => AiRecipeGeneratorViewModel(
          ref: ref,
          folderId: folderId,
        ),
        child: child,
      );
    },
    pageListBuilder: (bottomSheetContext) => [
      AiRecipeGeneratorInputPage.build(bottomSheetContext),  // Page 0
      AiRecipeGeneratorResultsPage.build(bottomSheetContext), // Page 1
    ],
  );
}
```

### 3. ViewModel State Management

```dart
class AiRecipeGeneratorViewModel extends ChangeNotifier {
  final WidgetRef ref;
  final String? folderId;

  // State
  AiGeneratorState _state = AiGeneratorState.inputting;
  String _errorMessage = '';
  bool _isRateLimitError = false;
  bool _usePantryItems = false;
  List<RecipeIdea> _recipeIdeas = [];
  RecipeIdea? _selectedIdea;

  // Quill controller for input
  late quill.QuillController _inputController;

  // Pantry items (cached on init)
  List<PantryItemEntry> _availablePantryItems = [];

  AiRecipeGeneratorViewModel({
    required this.ref,
    this.folderId,
  }) {
    _inputController = quill.QuillController.basic();
    _loadPantryItems();
  }

  Future<void> _loadPantryItems() async {
    final pantryAsync = ref.read(pantryNotifierProvider);
    _availablePantryItems = pantryAsync.whenData((items) {
      // Filter to in-stock and low-stock only
      return items.where((item) =>
        item.stockStatus != StockStatus.outOfStock
      ).toList();
    }).value ?? [];
    notifyListeners();
  }

  bool get hasPantryItems => _availablePantryItems.isNotEmpty;

  void toggleUsePantryItems(bool value) {
    _usePantryItems = value;
    if (value) {
      _appendPantryItemsToEditor();
    } else {
      _removePantryItemsFromEditor();
    }
    notifyListeners();
  }

  // ... additional methods below
}
```

### 4. State Machine

```dart
enum AiGeneratorState {
  inputting,          // User entering prompt
  brainstorming,      // Calling brainstorm-recipes endpoint
  showingResults,     // Displaying 5 recipe ideas
  generatingRecipe,   // Calling generate-recipe endpoint
  showingPreview,     // Showing preview for non-Plus users
  error,              // Error occurred
}
```

### 5. Page 1: Input Page

```dart
class _InputPageContent extends ConsumerStatefulWidget {
  @override
  Widget build(BuildContext context) {
    return provider.Consumer<AiRecipeGeneratorViewModel>(
      builder: (context, viewModel, child) {
        final colors = AppColors.of(context);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              'Generate with AI',
              style: AppTypography.h4.copyWith(
                color: colors.textPrimary,
              ),
            ),
            SizedBox(height: AppSpacing.sm),

            // Subtitle
            Text(
              'Describe what you want to eat',
              style: AppTypography.body.copyWith(
                color: colors.textSecondary,
              ),
            ),
            SizedBox(height: AppSpacing.lg),

            // Quill Editor
            Container(
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: colors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  checkboxTheme: _buildCheckboxTheme(colors),
                ),
                child: quill.QuillEditor.basic(
                  controller: viewModel.inputController,
                  config: quill.QuillEditorConfig(
                    placeholder: 'e.g., "I want a warm soup with chicken"',
                    padding: EdgeInsets.all(AppSpacing.md),
                  ),
                ),
              ),
            ),
            SizedBox(height: AppSpacing.lg),

            // Pantry toggle
            if (viewModel.hasPantryItems) ...[
              _PantryToggle(
                value: viewModel.usePantryItems,
                onChanged: viewModel.toggleUsePantryItems,
                pantryItemCount: viewModel.availablePantryItems.length,
              ),
              SizedBox(height: AppSpacing.lg),
            ],

            // Generate button
            AppButton(
              text: 'Generate Ideas',
              onPressed: viewModel.hasInput ? () {
                viewModel.generateIdeas();
                WoltModalSheet.of(context).showNext();
              } : null,
              style: AppButtonStyle.fill,
              theme: AppButtonTheme.primary,
              size: AppButtonSize.large,
              shape: AppButtonShape.square,
              fullWidth: true,
            ),
          ],
        );
      },
    );
  }
}
```

### 6. Pantry Items Toggle & Insertion

When toggle is enabled, append pantry items as checklist items (all checked by default, users can uncheck individual items they don't want to use):

```dart
void _appendPantryItemsToEditor() {
  final document = _inputController.document;
  final currentLength = document.length;

  // Add header
  document.insert(currentLength - 1, '\n\nAvailable ingredients:\n');

  // Add each pantry item as a checked checklist item
  for (final item in _availablePantryItems) {
    final insertPos = document.length - 1;
    document.insert(insertPos, '${item.name}\n');

    // Apply checklist format - checked by default so users can uncheck items they don't want
    _inputController.formatText(
      insertPos,
      item.name.length + 1,
      quill.Attribute.checked,  // All items checked by default
    );
  }
}

/// Get list of pantry items that are still checked (for sending to API)
List<String> getCheckedPantryItems() {
  final checkedItems = <String>[];
  final document = _inputController.document;

  // Parse document to find checked items
  for (final op in document.toDelta().toList()) {
    if (op.attributes != null && op.attributes!['list'] == 'checked') {
      final text = op.data?.toString().trim();
      if (text != null && text.isNotEmpty) {
        checkedItems.add(text);
      }
    }
  }

  return checkedItems;
}
```

### 7. Page 2: Results Page

```dart
class _ResultsPageContent extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return provider.Consumer<AiRecipeGeneratorViewModel>(
      builder: (context, viewModel, child) {
        return AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: viewModel.isTransitioning ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: _buildContent(context, viewModel),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, AiRecipeGeneratorViewModel viewModel) {
    switch (viewModel.state) {
      case AiGeneratorState.brainstorming:
        return _BrainstormingState();
      case AiGeneratorState.showingResults:
        return _ResultsState(ideas: viewModel.recipeIdeas);
      case AiGeneratorState.generatingRecipe:
        return _GeneratingRecipeState();
      case AiGeneratorState.showingPreview:
        return SizedBox.shrink(); // Preview shown in separate sheet
      case AiGeneratorState.error:
        return _ErrorState(
          message: viewModel.errorMessage,
          isRateLimitError: viewModel.isRateLimitError,
          onUpgrade: () => viewModel.presentPaywall(context),
          onBack: () => WoltModalSheet.of(context).showPrevious(),
        );
      default:
        return SizedBox.shrink();
    }
  }
}
```

### 8. Recipe Ideas Display

```dart
class _ResultsState extends StatelessWidget {
  final List<RecipeIdea> ideas;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recipe Ideas',
              style: AppTypography.h4.copyWith(
                color: colors.textPrimary,
              ),
            ),
            // Back button to refine prompt
            AppCircleButton(
              icon: AppCircleButtonIcon.back,
              variant: AppCircleButtonVariant.neutral,
              size: 32,
              onPressed: () => WoltModalSheet.of(context).showPrevious(),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.lg),

        // Recipe idea cards
        ...ideas.map((idea) => _RecipeIdeaCard(
          idea: idea,
          onTap: () => _selectIdea(context, idea),
        )),
      ],
    );
  }
}

class _RecipeIdeaCard extends StatelessWidget {
  final RecipeIdea idea;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                idea.title,
                style: AppTypography.h5.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                idea.description,
                style: AppTypography.body.copyWith(
                  color: colors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  if (idea.estimatedTime != null) ...[
                    Icon(Icons.access_time, size: 14, color: colors.textSecondary),
                    SizedBox(width: 4),
                    Text(
                      '${idea.estimatedTime} min',
                      style: AppTypography.caption.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    SizedBox(width: AppSpacing.md),
                  ],
                  Icon(Icons.arrow_forward, size: 16, color: colors.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### 9. Loading States

```dart
class _BrainstormingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: AppSpacing.xxl),
        const CupertinoActivityIndicator(radius: 16),
        SizedBox(height: AppSpacing.lg),
        _AnimatedLoadingText(
          messages: [
            'Brainstorming recipes...',
            'Considering your preferences...',
            'Finding delicious ideas...',
          ],
        ),
        SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}

class _GeneratingRecipeState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: AppSpacing.xxl),
        const CupertinoActivityIndicator(radius: 16),
        SizedBox(height: AppSpacing.lg),
        _AnimatedLoadingText(
          messages: [
            'Generating recipe...',
            'Writing ingredients...',
            'Crafting instructions...',
          ],
        ),
        SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}
```

### 10. Error State

```dart
Widget _buildErrorState(BuildContext context, AiRecipeGeneratorViewModel viewModel) {
  final colors = AppColors.of(context);

  return Padding(
    padding: EdgeInsets.all(AppSpacing.xl),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                viewModel.isRateLimitError
                    ? 'Idea Limit Reached'
                    : 'Generation Failed',
                style: AppTypography.h4.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ),
            AppCircleButton(
              icon: AppCircleButtonIcon.close,
              variant: AppCircleButtonVariant.neutral,
              size: 32,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.lg),
        Text(
          viewModel.errorMessage,
          style: AppTypography.body.copyWith(
            color: colors.textSecondary,
          ),
        ),
        SizedBox(height: AppSpacing.xl),
        if (viewModel.isRateLimitError)
          AppButton(
            text: 'Upgrade to Plus',
            onPressed: () => viewModel.presentPaywall(context),
            style: AppButtonStyle.fill,
            theme: AppButtonTheme.primary,
            size: AppButtonSize.large,
            shape: AppButtonShape.square,
            fullWidth: true,
          )
        else
          AppButton(
            text: 'Try Again',
            onPressed: () => WoltModalSheet.of(context).showPrevious(),
            style: AppButtonStyle.fill,
            theme: AppButtonTheme.primary,
            size: AppButtonSize.large,
            shape: AppButtonShape.square,
            fullWidth: true,
          ),
      ],
    ),
  );
}
```

### 11. Menu Item Addition

**File:** `lib/src/features/recipes/views/recipes_root.dart` (line ~117)

```dart
AdaptiveMenuItem(
  title: 'New Recipe',
  icon: const Icon(CupertinoIcons.book),
  onTap: () {
    showRecipeEditorModal(context, ref: ref, folderId: null);
  },
),
// ADD THIS:
AdaptiveMenuItem(
  title: 'Generate with AI',
  icon: const Icon(CupertinoIcons.wand_and_stars),
  onTap: () {
    showAiRecipeGeneratorModal(context, ref: ref);
  },
),
AdaptiveMenuItem.divider(),  // Move divider after AI option
```

**File:** `lib/src/features/recipes/views/recipes_folder_page.dart` (line ~217)

```dart
AdaptiveMenuItem(
  title: 'New Recipe',
  icon: const Icon(CupertinoIcons.book),
  onTap: () {
    final saveFolderId = folderId == kUncategorizedFolderId ? null : folderId;
    showRecipeEditorModal(context, ref: ref, folderId: saveFolderId);
  },
),
// ADD THIS:
AdaptiveMenuItem(
  title: 'Generate with AI',
  icon: const Icon(CupertinoIcons.wand_and_stars),
  onTap: () {
    final saveFolderId = folderId == kUncategorizedFolderId ? null : folderId;
    showAiRecipeGeneratorModal(context, ref: ref, folderId: saveFolderId);
  },
),
```

### 12. Preview Usage Service Update

**File:** `lib/src/services/preview_usage_service.dart`

Add new quota tracking for idea generation:

```dart
// Add new constants
static const _ideaKeyPrefix = 'idea_generation_usage_';
static const int ideaDailyLimit = 10;

// Add new methods
int getIdeaUsageToday() {
  final key = '$_ideaKeyPrefix${_today()}';
  return _prefs.getInt(key) ?? 0;
}

bool hasIdeaGenerationsRemaining() {
  return getIdeaUsageToday() < ideaDailyLimit;
}

Future<void> incrementIdeaUsage() async {
  final key = '$_ideaKeyPrefix${_today()}';
  final current = _prefs.getInt(key) ?? 0;
  await _prefs.setInt(key, current + 1);
  await _cleanupOldEntries(_ideaKeyPrefix);
}
```

---

## Backend Implementation

### 1. New Files to Create

```
src/routes/
└── aiRecipeRoutes.ts          # Route definitions

src/controllers/
└── aiRecipeController.ts      # Request handlers

src/services/
└── aiRecipeService.ts         # OpenAI integration for brainstorming/generation
```

### 2. API Endpoints

#### POST `/v1/ai-recipes/brainstorm`

**Purpose:** Generate 5 recipe ideas based on user prompt and optional pantry items

**Middleware Chain:**
```typescript
verifyApiSignature
→ authenticateUserOptional    // Track user for analytics
→ rateLimitBrainstorm         // 10/day for free, unlimited for Plus
→ validateBrainstormRequest
→ brainstormRecipes
```

**Request Schema:**
```typescript
const BrainstormRequestSchema = z.object({
  prompt: z.string().min(3).max(500),
  pantryItems: z.array(z.string()).optional(),  // Only checked items sent
});
```

**Response:**
```typescript
interface BrainstormResponse {
  success: boolean;
  ideas?: RecipeIdea[];
  message?: string;
}

interface RecipeIdea {
  id: string;           // Generated UUID for selection
  title: string;
  description: string;
  estimatedTime?: number;  // minutes
  difficulty?: 'easy' | 'medium' | 'hard';
  keyIngredients: string[];
}
```

**Rate Limiting:**
- Free users (no auth or no Plus): 10/day
- Plus users: No limit (skip rate limiter)

#### POST `/v1/ai-recipes/generate`

**Purpose:** Generate full recipe from selected idea

**Middleware Chain:**
```typescript
verifyApiSignature
→ authenticateUser            // Required for Plus check
→ verifyPlusEntitlement       // Full generation requires Plus
→ rateLimitGenerate           // 5/min + 100/day
→ validateGenerateRequest
→ generateRecipe
```

**Request Schema:**
```typescript
const GenerateRequestSchema = z.object({
  ideaId: z.string(),
  ideaTitle: z.string(),
  ideaDescription: z.string(),
  originalPrompt: z.string().optional(),
  pantryItems: z.array(z.string()).optional(),
});
```

**Response:**
```typescript
interface GenerateResponse {
  success: boolean;
  recipe?: ExtractedRecipe;
  message?: string;
}
```

#### POST `/v1/ai-recipes/preview-generate`

**Purpose:** Generate preview (partial recipe) for non-Plus users

**Middleware Chain:**
```typescript
verifyApiSignature
→ rateLimitPreview            // 5/day (matches other previews)
→ validateGenerateRequest
→ previewGenerateRecipe
```

**Response:**
```typescript
interface PreviewGenerateResponse {
  success: boolean;
  preview?: RecipePreview;  // Reuse existing model: title, description, first 4 ingredients
  message?: string;
}
```

### 3. Service Implementation

**File:** `src/services/aiRecipeService.ts`

```typescript
import { z } from 'zod';
import { zodResponseFormat } from 'openai/helpers/zod';
import openai from './openaiService';
import { logger } from './logger';
import { v4 as uuidv4 } from 'uuid';

// Schemas for structured outputs
const RecipeIdeaSchema = z.object({
  title: z.string(),
  description: z.string(),
  estimatedTime: z.number().optional(),
  difficulty: z.enum(['easy', 'medium', 'hard']).optional(),
  keyIngredients: z.array(z.string()),
});

const BrainstormOutputSchema = z.object({
  hasIdeas: z.boolean(),
  ideas: z.array(RecipeIdeaSchema),
});

const FullRecipeSchema = z.object({
  hasRecipe: z.boolean(),
  title: z.string(),
  description: z.string().optional(),
  servings: z.number().optional(),
  prepTime: z.number().optional(),
  cookTime: z.number().optional(),
  ingredients: z.array(z.object({
    name: z.string(),
    type: z.enum(['ingredient', 'section']),
  })),
  steps: z.array(z.object({
    text: z.string(),
    type: z.enum(['step', 'section']),
  })),
});

// Brainstorm prompt
const BRAINSTORM_SYSTEM_PROMPT = `You are a creative culinary assistant. Given a user's description of what they want to eat, generate exactly 5 diverse recipe ideas.

Consider:
- The user's stated preferences and cravings
- Available ingredients if provided
- Variety in cuisine types and cooking methods
- Practical home cooking constraints

For each idea, provide:
- A compelling title
- A brief (1-2 sentence) description
- Estimated total time in minutes
- Difficulty level (easy/medium/hard)
- 3-5 key ingredients

If the prompt doesn't relate to food at all, set hasIdeas to false.`;

export async function brainstormRecipes(
  prompt: string,
  pantryItems?: string[]
): Promise<{ hasIdeas: boolean; ideas: RecipeIdea[] }> {
  const userPrompt = pantryItems?.length
    ? `${prompt}\n\nAvailable ingredients:\n${pantryItems.map(i => `- ${i}`).join('\n')}`
    : prompt;

  const response = await openai.chat.completions.create({
    model: 'gpt-4.1',
    messages: [
      { role: 'system', content: BRAINSTORM_SYSTEM_PROMPT },
      { role: 'user', content: userPrompt },
    ],
    temperature: 0.5,  // Balanced creativity
    response_format: zodResponseFormat(BrainstormOutputSchema, 'brainstorm_output'),
  });

  const parsed = JSON.parse(response.choices[0].message.content || '{}');

  // Add UUIDs to each idea
  const ideas = parsed.ideas.map((idea: any) => ({
    ...idea,
    id: uuidv4(),
  }));

  return {
    hasIdeas: parsed.hasIdeas,
    ideas,
  };
}

// Generate full recipe
const GENERATE_SYSTEM_PROMPT = `You are a detailed recipe writer. Given a recipe idea, generate a complete, practical recipe.

Include:
- Accurate title and description
- Reasonable servings (default 4)
- Prep time and cook time in minutes
- Complete ingredient list with quantities and units
- Clear, numbered step-by-step instructions

Use section headers in ingredients (e.g., "For the sauce:") and steps (e.g., "Prepare the filling") when helpful.

Set hasRecipe to true if you can generate a valid recipe.`;

export async function generateFullRecipe(
  ideaTitle: string,
  ideaDescription: string,
  originalPrompt?: string,
  pantryItems?: string[]
): Promise<ExtractedRecipe | null> {
  let userPrompt = `Recipe idea: ${ideaTitle}\n${ideaDescription}`;

  if (originalPrompt) {
    userPrompt += `\n\nOriginal request: ${originalPrompt}`;
  }

  if (pantryItems?.length) {
    userPrompt += `\n\nPreferred ingredients:\n${pantryItems.map(i => `- ${i}`).join('\n')}`;
  }

  const response = await openai.chat.completions.create({
    model: 'gpt-4.1',
    messages: [
      { role: 'system', content: GENERATE_SYSTEM_PROMPT },
      { role: 'user', content: userPrompt },
    ],
    temperature: 0.3,
    response_format: zodResponseFormat(FullRecipeSchema, 'full_recipe'),
  });

  const parsed = JSON.parse(response.choices[0].message.content || '{}');

  if (!parsed.hasRecipe) {
    return null;
  }

  return {
    title: parsed.title,
    description: parsed.description,
    servings: parsed.servings,
    prepTime: parsed.prepTime,
    cookTime: parsed.cookTime,
    ingredients: parsed.ingredients,
    steps: parsed.steps,
  };
}

// Preview generation (cheaper model, limited output)
export async function generateRecipePreview(
  ideaTitle: string,
  ideaDescription: string
): Promise<RecipePreview | null> {
  const PreviewSchema = z.object({
    hasRecipe: z.boolean(),
    title: z.string(),
    description: z.string().optional(),
    previewIngredients: z.array(z.string()).max(4),
  });

  const response = await openai.chat.completions.create({
    model: 'gpt-4.1-mini',  // Cheaper model for previews
    messages: [
      { role: 'system', content: 'Generate a recipe preview with title, brief description, and first 4 ingredients.' },
      { role: 'user', content: `Recipe idea: ${ideaTitle}\n${ideaDescription}` },
    ],
    temperature: 0.3,
    response_format: zodResponseFormat(PreviewSchema, 'recipe_preview'),
  });

  const parsed = JSON.parse(response.choices[0].message.content || '{}');

  if (!parsed.hasRecipe) {
    return null;
  }

  return {
    title: parsed.title,
    description: parsed.description,
    previewIngredients: parsed.previewIngredients,
  };
}
```

### 4. Controller Implementation

**File:** `src/controllers/aiRecipeController.ts`

```typescript
import { Request, Response } from 'express';
import {
  brainstormRecipes,
  generateFullRecipe,
  generateRecipePreview
} from '../services/aiRecipeService';
import { logger } from '../services/logger';

export async function handleBrainstorm(req: Request, res: Response): Promise<void> {
  const { prompt, pantryItems } = req.body;

  try {
    const result = await brainstormRecipes(prompt, pantryItems);

    if (!result.hasIdeas) {
      logger.info('No recipe ideas generated', {
        event: 'BRAINSTORM_NO_IDEAS',
        promptLength: prompt.length,
      });
      res.status(200).json({
        success: false,
        message: "I couldn't think of recipes based on that description. Try being more specific about what you'd like to eat."
      });
      return;
    }

    logger.info('Brainstorm successful', {
      event: 'BRAINSTORM_SUCCESS',
      ideaCount: result.ideas.length,
      promptLength: prompt.length,
      hasPantryItems: !!pantryItems?.length,
    });

    res.status(200).json({ success: true, ideas: result.ideas });
  } catch (error) {
    logger.error('Brainstorm failed', {
      event: 'BRAINSTORM_ERROR',
      error: error instanceof Error ? error.message : String(error),
    });
    res.status(500).json({ error: 'Failed to generate recipe ideas' });
  }
}

export async function handleGenerate(req: Request, res: Response): Promise<void> {
  const { ideaId, ideaTitle, ideaDescription, originalPrompt, pantryItems } = req.body;

  try {
    const recipe = await generateFullRecipe(
      ideaTitle,
      ideaDescription,
      originalPrompt,
      pantryItems
    );

    if (!recipe) {
      logger.info('Recipe generation returned no content', {
        event: 'GENERATE_NO_CONTENT',
        ideaId,
      });
      res.status(200).json({
        success: false,
        message: 'Unable to generate a complete recipe. Please try another idea.'
      });
      return;
    }

    logger.info('Recipe generation successful', {
      event: 'GENERATE_SUCCESS',
      ideaId,
      ingredientCount: recipe.ingredients.length,
      stepCount: recipe.steps.length,
    });

    res.status(200).json({ success: true, recipe });
  } catch (error) {
    logger.error('Recipe generation failed', {
      event: 'GENERATE_ERROR',
      error: error instanceof Error ? error.message : String(error),
      ideaId,
    });
    res.status(500).json({ error: 'Failed to generate recipe' });
  }
}

export async function handlePreviewGenerate(req: Request, res: Response): Promise<void> {
  const { ideaTitle, ideaDescription } = req.body;

  try {
    const preview = await generateRecipePreview(ideaTitle, ideaDescription);

    if (!preview) {
      res.status(200).json({
        success: false,
        message: 'Unable to generate preview.'
      });
      return;
    }

    logger.info('Preview generation successful', {
      event: 'PREVIEW_GENERATE_SUCCESS',
    });

    res.status(200).json({ success: true, preview });
  } catch (error) {
    logger.error('Preview generation failed', {
      event: 'PREVIEW_GENERATE_ERROR',
      error: error instanceof Error ? error.message : String(error),
    });
    res.status(500).json({ error: 'Failed to generate preview' });
  }
}
```

### 5. Route Implementation

**File:** `src/routes/aiRecipeRoutes.ts`

```typescript
import express from 'express';
import rateLimit from 'express-rate-limit';
import {
  handleBrainstorm,
  handleGenerate,
  handlePreviewGenerate
} from '../controllers/aiRecipeController';
import { verifyApiSignature } from '../middleware/apiSignature';
import { authenticateUser, authenticateUserOptional } from '../middleware/auth';
import { verifyPlusEntitlement } from '../middleware/entitlement';

const router = express.Router();

// Rate limiters
const brainstormDailyLimiter = rateLimit({
  windowMs: 24 * 60 * 60 * 1000, // 24 hours
  max: 10,
  standardHeaders: false,
  legacyHeaders: false,
  message: { error: 'Daily idea generation limit reached' },
  skip: (req) => {
    // Skip rate limiting for Plus users
    return req.user?.hasPlus === true;
  },
});

const generateMinuteLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 5,
  standardHeaders: false,
  legacyHeaders: false,
  message: { error: 'Too many requests. Please wait a moment.' },
});

const generateDailyLimiter = rateLimit({
  windowMs: 24 * 60 * 60 * 1000,
  max: 100,
  standardHeaders: false,
  legacyHeaders: false,
  message: { error: 'Daily generation limit reached' },
});

const previewDailyLimiter = rateLimit({
  windowMs: 24 * 60 * 60 * 1000,
  max: 5,
  standardHeaders: false,
  legacyHeaders: false,
  message: { error: 'Daily preview limit reached' },
});

// Brainstorm endpoint (free with limits)
router.post(
  '/brainstorm',
  verifyApiSignature,
  authenticateUserOptional,
  brainstormDailyLimiter,
  handleBrainstorm
);

// Full generation endpoint (Plus only)
router.post(
  '/generate',
  verifyApiSignature,
  authenticateUser,
  verifyPlusEntitlement,
  generateMinuteLimiter,
  generateDailyLimiter,
  handleGenerate
);

// Preview generation endpoint (free with limits)
router.post(
  '/preview-generate',
  verifyApiSignature,
  previewDailyLimiter,
  handlePreviewGenerate
);

export default router;
```

### 6. Mount Routes in index.ts

```typescript
import aiRecipeRoutes from './routes/aiRecipeRoutes';

// In the route mounting section:
app.use('/v1/ai-recipes', aiRecipeRoutes);
```

---

## Data Models

### RecipeIdea (New)

```dart
// lib/src/features/recipes/models/recipe_idea.dart

class RecipeIdea {
  final String id;
  final String title;
  final String description;
  final int? estimatedTime;
  final String? difficulty;
  final List<String> keyIngredients;

  const RecipeIdea({
    required this.id,
    required this.title,
    required this.description,
    this.estimatedTime,
    this.difficulty,
    required this.keyIngredients,
  });

  factory RecipeIdea.fromJson(Map<String, dynamic> json) {
    return RecipeIdea(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      estimatedTime: json['estimatedTime'] as int?,
      difficulty: json['difficulty'] as String?,
      keyIngredients: (json['keyIngredients'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );
  }
}
```

---

## Animation & Transition Patterns

Following established patterns from URL import modal:

### AnimatedSize + AnimatedOpacity Wrapper

```dart
AnimatedSize(
  duration: const Duration(milliseconds: 300),
  curve: Curves.easeOutCubic,
  alignment: Alignment.topCenter,
  child: AnimatedOpacity(
    opacity: _isTransitioning ? 0.0 : 1.0,
    duration: const Duration(milliseconds: 200),
    curve: Curves.easeOut,
    child: _buildCurrentStateContent(),
  ),
)
```

### State Transition Method

```dart
Future<void> _transitionToState(AiGeneratorState newState) async {
  if (_isTransitioning || _state == newState) return;

  _isTransitioning = true;
  notifyListeners();

  await Future.delayed(const Duration(milliseconds: 200)); // Fade-out time

  _state = newState;
  _isTransitioning = false;
  notifyListeners();
}
```

---

## Testing Considerations

### Unit Tests
- ViewModel state transitions
- Pantry item filtering (in-stock/low-stock only)
- Quill delta construction for pantry items
- Preview usage quota tracking

### Integration Tests
- Full flow from input to recipe editor
- Rate limit enforcement
- Subscription-based access control
- Error handling and recovery

### Manual Testing Checklist
- [ ] Empty pantry disables toggle
- [ ] Toggle adds pantry items as checked checkboxes
- [ ] Users can uncheck individual pantry items
- [ ] Only checked pantry items sent to API
- [ ] Toggle off removes pantry items from editor
- [ ] Generate button disabled when input empty
- [ ] Loading states show appropriate messages
- [ ] Back button returns to input page
- [ ] Rate limit shows upgrade prompt
- [ ] Plus users bypass quotas
- [ ] Recipe ideas are selectable
- [ ] Full recipe opens in editor with correct folder assignment
- [ ] Preview shows limited data with subscribe button
- [ ] Smooth animations between states

---

## Implementation Order

### Phase 1: Backend
1. Create `aiRecipeService.ts` with brainstorm and generate functions
2. Create `aiRecipeController.ts` with request handlers
3. Create `aiRecipeRoutes.ts` with middleware chains
4. Mount routes in `index.ts`
5. Test endpoints with curl/Postman

### Phase 2: Flutter - Service Layer
1. Create `RecipeIdea` model
2. Create `AiRecipeService` client (following RecipeApiClient pattern)
3. Update `PreviewUsageService` with idea quota tracking

### Phase 3: Flutter - Modal Infrastructure
1. Create `AiRecipeGeneratorViewModel` (ChangeNotifier)
2. Create modal entry point function
3. Implement Page 1 (input with Quill editor)
4. Implement Page 2 (results)

### Phase 4: Flutter - Integration
1. Add menu items to recipes_root.dart and recipes_folder_page.dart
2. Wire up subscription checks and paywall
3. Connect to recipe editor for final output
4. Test full flow

### Phase 5: Polish
1. Add haptic feedback
2. Fine-tune animations
3. Error message refinement
4. Analytics events

---

## Design Decisions

The following decisions have been confirmed:

| Decision | Choice | Rationale |
|----------|--------|-----------|
| **Creativity slider** | Skip for v1 | Keep UI simple, use fixed temperature (0.5) |
| **Pantry item selection** | Users can uncheck individual items | All items checked by default, but users can deselect ones they don't want to use |
| **Idea caching** | No caching | Keep implementation simple for v1 |
| **Folder assignment** | Auto-assign to current folder | If opened from folder page, recipe is assigned to that folder |
| **Image generation** | Not included | Out of scope for this feature |

---

## Status

**APPROVED** - Ready for implementation following the phased approach.
