# Photo Recipe Import Implementation Plan

## Overview

Add the ability to import recipes from photos via two paths:
1. **Share Extension**: Share image(s) from another app (iOS Photos, etc.)
2. **In-App**: Pick or capture photos from within the app

### Key Requirements
- Max 2 photos per extraction (for cookbook multi-page scenarios)
- 2 extractions per day limit (separate from 5/day web preview quota)
- Always requires API call (no local fallback like JSON-LD)
- Supports two use cases:
  - Extract/structure a photo of an actual recipe
  - Generate a recipe from a photo of a food dish
- Plus subscription required for full extraction; preview for free users

---

## Architecture Summary

### Existing Patterns to Follow

| Component | Location | Pattern |
|-----------|----------|---------|
| Share session modal | `lib/src/features/share/views/share_session_modal.dart` | State machine, subscription gating, preview flow |
| Share extraction service | `lib/src/services/share_extraction_service.dart` | HMAC-signed API calls, preview/extract endpoints |
| Preview usage tracking | `lib/src/services/preview_usage_service.dart` | Client-side quota optimization |
| Backend routes | `src/routes/shareRoutes.ts` | Rate limiting, auth middleware |
| Backend controller | `src/controllers/shareController.ts` | Logging, error handling |
| Backend extraction | `src/services/clippingExtractionService.ts` | OpenAI structured outputs with Zod |
| Image picker | `lib/src/features/recipes/widgets/recipe_editor_form/sections/image_picker_section.dart` | ImagePicker usage, compression |

---

## Frontend Implementation

### 1. Share Session Image Handling

**File**: `lib/src/features/share/views/share_session_modal.dart`

The share session already detects image types via `ShareSessionItem.isImage`. Currently images are likely ignored or treated as unsupported.

#### Changes Required:

1. **Add image import action in `_buildChoosingActionContent()`**:
   - When session contains images (`session.hasImages`), show "Import Recipe from Photo" button
   - Take first 2 images only, ignore rest

2. **Add new handler `_handleImageImport()`**:
   - Read image files from share session path (`${session.sessionPath}/${item.fileName}`)
   - Check subscription status (`effectiveHasPlusProvider`)
   - If Plus: Call full extraction API
   - If not Plus: Check photo preview quota, call preview API or show paywall

3. **Add state transitions**:
   - `_ModalState.extractingFromImage` - while processing
   - `_ModalState.showingPhotoPreview` - showing preview result

4. **Add photo-specific preview sheet** (or reuse `_showWebPreviewBottomSheet` with modifications)

### 2. Photo Extraction Service (New File)

**File**: `lib/src/services/photo_extraction_service.dart`

```dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../features/clippings/models/extracted_recipe.dart';
import '../features/clippings/models/recipe_preview.dart';
import 'api_signer.dart';
import 'logging/app_logger.dart';

class PhotoExtractionException implements Exception {
  final String message;
  final int? statusCode;
  PhotoExtractionException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class PhotoExtractionService {
  final String _baseUrl;
  final ApiSigner _signer;

  PhotoExtractionService(this._baseUrl, this._signer);

  /// Extracts recipe from photos (requires Plus subscription)
  Future<ExtractedRecipe?> extractRecipe({
    required List<Uint8List> images,
    String? hint,
    required String authToken,
  }) async {
    return _sendRequest(
      endpoint: '/v1/photo/extract-recipe',
      images: images,
      hint: hint,
      authToken: authToken,
      parseResponse: (data) {
        if (data['success'] != true) return null;
        return ExtractedRecipe.fromJson(data['recipe']);
      },
    );
  }

  /// Preview extraction (for non-subscribers)
  Future<RecipePreview?> previewRecipe({
    required List<Uint8List> images,
    String? hint,
  }) async {
    return _sendRequest(
      endpoint: '/v1/photo/preview-recipe',
      images: images,
      hint: hint,
      authToken: null,
      parseResponse: (data) {
        if (data['success'] != true) return null;
        return RecipePreview.fromJson(data['preview']);
      },
    );
  }

  Future<T?> _sendRequest<T>({
    required String endpoint,
    required List<Uint8List> images,
    String? hint,
    String? authToken,
    required T? Function(Map<String, dynamic>) parseResponse,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final request = http.MultipartRequest('POST', uri);

      // Add images as multipart files
      for (var i = 0; i < images.length; i++) {
        request.files.add(http.MultipartFile.fromBytes(
          'images',
          images[i],
          filename: 'image_$i.jpg',
        ));
      }

      // Add hint if provided
      if (hint != null) {
        request.fields['hint'] = hint;
      }

      // Add HMAC signature headers for multipart (uses MULTIPART placeholder instead of body hash)
      final signatureHeaders = _signer.getMultipartSignatureHeaders('POST', endpoint);
      request.headers.addAll(signatureHeaders);

      // Add auth header if provided
      if (authToken != null) {
        request.headers['Authorization'] = 'Bearer $authToken';
      }

      AppLogger.info('Photo extraction request: endpoint=$endpoint, imageCount=${images.length}');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      AppLogger.info('Photo extraction response: statusCode=${response.statusCode}');

      if (response.statusCode == 429) {
        throw PhotoExtractionException(
          'Daily photo import limit reached. Subscribe to Plus for unlimited access.',
          statusCode: 429,
        );
      }

      if (response.statusCode == 403) {
        throw PhotoExtractionException(
          'Plus subscription required',
          statusCode: 403,
        );
      }

      if (response.statusCode != 200) {
        throw PhotoExtractionException(
          'Failed to process photo: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return parseResponse(data);
    } catch (e) {
      if (e is PhotoExtractionException) rethrow;
      AppLogger.error('Photo extraction failed', e);
      throw PhotoExtractionException('Failed to process photo. Please try again.');
    }
  }
}

/// Provider for the PhotoExtractionService
final photoExtractionServiceProvider = Provider<PhotoExtractionService>((ref) {
  final baseUrl = AppConfig.ingredientApiUrl;
  final signer = ApiSigner();
  return PhotoExtractionService(baseUrl, signer);
});
```

### 3. Preview Usage Service Update

**File**: `lib/src/services/preview_usage_service.dart`

Add new quota tracking for photo extractions:

```dart
static const _photoRecipeKeyPrefix = 'photo_recipe_preview_usage_';
static const int photoPreviewDailyLimit = 2; // Stricter limit

int getPhotoRecipeUsageToday() { ... }
bool hasPhotoRecipePreviewsRemaining() {
  return getPhotoRecipeUsageToday() < photoPreviewDailyLimit;
}
Future<void> incrementPhotoRecipeUsage() async { ... }
```

### 4. In-App Photo Import

#### 4.1 Recipes Root Page Menu

**File**: `lib/src/features/recipes/views/recipes_root.dart`

Add to the `...` menu (`AdaptivePullDownButton` at line 97):

```dart
AdaptiveMenuItem(
  title: 'Choose Photo',
  icon: const Icon(CupertinoIcons.photo),
  onTap: () => _showPhotoImportModal(context, ref, source: ImageSource.gallery, folderId: null),
),
AdaptiveMenuItem(
  title: 'Take Photo',
  icon: const Icon(CupertinoIcons.camera),
  onTap: () => _showPhotoImportModal(context, ref, source: ImageSource.camera, folderId: null),
),
```

#### 4.2 Folder Page Menu

**File**: `lib/src/features/recipes/views/recipes_folder_page.dart`

Add to the `...` menu (`AdaptivePullDownButton` at line 210):

```dart
AdaptiveMenuItem(
  title: 'Choose Photo',
  icon: const Icon(CupertinoIcons.photo),
  onTap: () => _showPhotoImportModal(context, ref, source: ImageSource.gallery, folderId: folderId),
),
AdaptiveMenuItem(
  title: 'Take Photo',
  icon: const Icon(CupertinoIcons.camera),
  onTap: () => _showPhotoImportModal(context, ref, source: ImageSource.camera, folderId: folderId),
),
```

### 5. Photo Import Modal (New File)

**File**: `lib/src/features/recipes/views/photo_import_modal.dart`

A new modal/sheet for the in-app photo import flow:

```dart
Future<void> showPhotoImportModal(
  BuildContext context, {
  required WidgetRef ref,
  String? folderId,
  ImageSource source, // camera or gallery
}) async {
  // Opens WoltModalSheet with PhotoImportModalContent
}

class PhotoImportModalContent extends ConsumerStatefulWidget {
  final String? folderId;
  final ImageSource initialSource;
  final VoidCallback onClose;
  // ...
}

class _PhotoImportModalContentState extends ConsumerState<PhotoImportModalContent> {
  List<File> _selectedImages = [];
  _ModalState _state = _ModalState.selectingImages;

  // States: selectingImages, processing, showingPreview, error
}
```

#### Image Preview UI (follows `image_picker_section.dart` pattern)

```dart
Widget _buildImagePreview() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Selected Photos', style: AppTypography.h5),
      SizedBox(height: AppSpacing.md),

      // Image thumbnails row
      SizedBox(
        height: 143,
        child: Row(
          children: [
            // Show selected images with X remove button
            for (var i = 0; i < _selectedImages.length; i++)
              _buildImageThumbnail(_selectedImages[i], i),

            // "Add another image" button (only if < 2 images)
            if (_selectedImages.length < 2)
              _buildAddAnotherButton(),
          ],
        ),
      ),

      SizedBox(height: AppSpacing.xl),

      // Import button
      AppButton(
        text: 'Import Recipe',
        style: AppButtonStyle.primaryFilled,
        size: AppButtonSize.large,
        shape: AppButtonShape.square,
        fullWidth: true,
        onPressed: _selectedImages.isNotEmpty ? _handleImport : null,
      ),
    ],
  );
}

Widget _buildImageThumbnail(File image, int index) {
  return Stack(
    children: [
      Padding(
        padding: const EdgeInsets.all(4.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            image,
            height: 135,
            width: 135,
            fit: BoxFit.cover,
          ),
        ),
      ),
      // X button to remove (matches image_picker_section.dart pattern)
      Positioned(
        top: 8,
        right: 8,
        child: GestureDetector(
          onTap: () => _removeImage(index),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.8),
            ),
            child: const Icon(Icons.close, size: 20, color: Colors.black),
          ),
        ),
      ),
    ],
  );
}

Widget _buildAddAnotherButton() {
  return Padding(
    padding: const EdgeInsets.all(4.0),
    child: GestureDetector(
      onTap: _pickAnotherImage,
      child: Container(
        width: 135,
        height: 135,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.of(context).border,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.plus,
              color: AppColors.of(context).textSecondary,
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              'Add page',
              style: AppTypography.caption.copyWith(
                color: AppColors.of(context).textSecondary,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void _removeImage(int index) {
  setState(() {
    _selectedImages.removeAt(index);
  });
}

Future<void> _pickAnotherImage() async {
  final picker = ImagePicker();
  final XFile? image = await picker.pickImage(source: widget.initialSource);
  if (image != null) {
    setState(() {
      _selectedImages.add(File(image.path));
    });
  }
}
```

#### Modal States

| State | UI |
|-------|-----|
| `selectingImages` | Image picker opens immediately, then shows preview |
| `processing` | Standard loader with "Analyzing photo..." text |
| `showingPreview` | Recipe preview (non-Plus) with unlock button |
| `error` | Error message with retry button |

### 6. Image Utilities (New or Extend Existing)

**File**: `lib/src/utils/image_utils.dart` (new)

```dart
/// Compresses and prepares images for upload
/// Returns base64 or Uint8List suitable for API
Future<List<Uint8List>> prepareImagesForUpload(List<File> images) async {
  // Compress to reasonable size for API (e.g., 1024px max dimension)
  // Convert to JPEG
  // Return as bytes
}

/// Reads image files from share session path
Future<List<File>> getImagesFromShareSession(ShareSession session) async {
  return session.items
    .where((item) => item.isImage)
    .take(2)
    .map((item) => File('${session.sessionPath}/${item.fileName}'))
    .toList();
}
```

---

## Backend Implementation

### 1. Photo Routes (New File)

**File**: `src/routes/photoRoutes.ts`

```typescript
import express, { Request, Response, NextFunction } from 'express';
import rateLimit from 'express-rate-limit';
import multer from 'multer';
import { extractRecipeFromPhoto, previewRecipeFromPhoto } from '../controllers/photoController';
import { verifyApiSignature } from '../middleware/apiSignature';
import { authenticateUser } from '../middleware/auth';
import { verifyPlusEntitlement } from '../middleware/entitlement';
import logger from '../services/logger';

const router = express.Router();

// Configure multer for image uploads (in-memory storage)
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB per file
    files: 2, // Max 2 files
  },
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Only image files are allowed'));
    }
  },
});

// Rate limiter for photo previews: 2 per day per IP (stricter than web)
const photoPreviewDailyLimiter = rateLimit({
  windowMs: 24 * 60 * 60 * 1000, // 24 hours
  max: 2,
  standardHeaders: false,
  legacyHeaders: false,
  message: { error: 'Photo preview limit exceeded', code: 'PHOTO_PREVIEW_LIMIT_EXCEEDED' },
});

// Standard rate limiters for full extraction (Plus users)
const minuteLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 5,
  standardHeaders: false,
  legacyHeaders: false,
});

const dailyLimiter = rateLimit({
  windowMs: 24 * 60 * 60 * 1000,
  max: 50, // Lower than web since images are more expensive
  standardHeaders: false,
  legacyHeaders: false,
});

// POST /v1/photo/extract-recipe (Plus required)
router.post(
  '/extract-recipe',
  verifyApiSignature,
  authenticateUser,
  verifyPlusEntitlement,
  upload.array('images', 2),
  minuteLimiter,
  dailyLimiter,
  extractRecipeFromPhoto
);

// POST /v1/photo/preview-recipe (No auth, strict rate limit)
router.post(
  '/preview-recipe',
  verifyApiSignature,
  upload.array('images', 2),
  photoPreviewDailyLimiter,
  previewRecipeFromPhoto
);

export default router;
```

### 2. Photo Controller (New File)

**File**: `src/controllers/photoController.ts`

```typescript
import { Request, Response } from 'express';
import { extractRecipeFromImages, extractPhotoRecipePreview } from '../services/photoExtractionService';
import logger from '../services/logger';

export async function extractRecipeFromPhoto(req: Request, res: Response): Promise<void> {
  const files = req.files as Express.Multer.File[];
  const hint = req.body?.hint as string | undefined; // 'recipe' or 'dish'

  if (!files || files.length === 0) {
    res.status(400).json({ error: 'At least one image is required' });
    return;
  }

  logger.info('Extracting recipe from photo', {
    event: 'PHOTO_RECIPE_EXTRACTION_START',
    imageCount: files.length,
    totalSize: files.reduce((sum, f) => sum + f.size, 0),
    hint,
    ip: req.ip,
  });

  try {
    const imageBuffers = files.map(f => f.buffer);
    const recipe = await extractRecipeFromImages(imageBuffers, hint);

    if (!recipe) {
      logger.info('No recipe found in photo', {
        event: 'PHOTO_RECIPE_EXTRACTION_NO_CONTENT',
        imageCount: files.length,
        ip: req.ip,
      });

      res.status(200).json({
        success: false,
        message: 'Unable to extract a recipe from the photo. Please try a clearer image.',
      });
      return;
    }

    logger.info('Recipe extracted from photo', {
      event: 'PHOTO_RECIPE_EXTRACTION_SUCCESS',
      ingredientCount: recipe.ingredients.length,
      stepCount: recipe.steps.length,
      ip: req.ip,
    });

    res.status(200).json({
      success: true,
      recipe,
    });
  } catch (error) {
    logger.error('Photo recipe extraction failed', {
      event: 'PHOTO_RECIPE_EXTRACTION_ERROR',
      error: error instanceof Error ? error.message : String(error),
      ip: req.ip,
    });

    res.status(500).json({ error: 'Internal server error' });
  }
}

export async function previewRecipeFromPhoto(req: Request, res: Response): Promise<void> {
  const files = req.files as Express.Multer.File[];
  const hint = req.body?.hint as string | undefined;

  if (!files || files.length === 0) {
    res.status(400).json({ error: 'At least one image is required' });
    return;
  }

  try {
    const imageBuffers = files.map(f => f.buffer);
    const preview = await extractPhotoRecipePreview(imageBuffers, hint);

    if (!preview) {
      res.status(200).json({
        success: false,
        message: 'Unable to detect a recipe in the photo.',
      });
      return;
    }

    logger.info('Photo recipe preview extracted', {
      event: 'PHOTO_RECIPE_PREVIEW_SUCCESS',
      ingredientCount: preview.previewIngredients.length,
      ip: req.ip,
    });

    res.status(200).json({
      success: true,
      preview,
    });
  } catch (error) {
    logger.error('Photo recipe preview failed', {
      event: 'PHOTO_RECIPE_PREVIEW_ERROR',
      error: error instanceof Error ? error.message : String(error),
      ip: req.ip,
    });

    res.status(500).json({ error: 'Internal server error' });
  }
}
```

### 3. Photo Extraction Service (New File)

**File**: `src/services/photoExtractionService.ts`

```typescript
import { OpenAI } from 'openai';
import { zodResponseFormat } from 'openai/helpers/zod';
import { z } from 'zod';
import dotenv from 'dotenv';
import logger from './logger';
import { RecipePreview } from '../types';

dotenv.config();

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

// ============================================================================
// Types
// ============================================================================

export interface ExtractedRecipe {
  title: string;
  description?: string;
  servings?: number;
  prepTime?: number;
  cookTime?: number;
  ingredients: Array<{ name: string; type: 'ingredient' | 'section' }>;
  steps: Array<{ text: string; type: 'step' | 'section' }>;
  source?: string;
}

// ============================================================================
// Zod Schemas
// ============================================================================

const ExtractedIngredientSchema = z.object({
  name: z.string(),
  type: z.enum(['ingredient', 'section']),
});

const ExtractedStepSchema = z.object({
  text: z.string(),
  type: z.enum(['step', 'section']),
});

const ExtractedRecipeSchema = z.object({
  hasRecipe: z.boolean().describe('Whether the image contains recipe-like content or food'),
  title: z.string().optional(),
  description: z.string().optional(),
  servings: z.number().optional(),
  prepTime: z.number().optional(),
  cookTime: z.number().optional(),
  ingredients: z.array(ExtractedIngredientSchema),
  steps: z.array(ExtractedStepSchema),
});

const RecipePreviewSchema = z.object({
  hasRecipe: z.boolean(),
  title: z.string(),
  description: z.string(),
  firstFourIngredients: z.array(z.string()),
});

// ============================================================================
// Prompts
// ============================================================================

const PHOTO_EXTRACTION_SYSTEM_PROMPT = `You are a culinary assistant that extracts or generates recipes from photos.

You can handle two scenarios:
1. A photo of a written/printed recipe - extract the recipe faithfully
2. A photo of a prepared dish - generate a reasonable recipe for what you see

Always produce a complete, usable recipe with title, ingredients, and steps.
If multiple pages are provided, treat them as a single recipe spanning pages.`;

const PHOTO_EXTRACTION_USER_PROMPT = `Analyze the provided image(s) and create a structured recipe:

- If this is a photo of a written/printed recipe: Extract it faithfully
- If this is a photo of food: Generate a reasonable recipe for the dish

Output:
- Recipe title
- Brief description
- Servings (if visible or reasonable estimate)
- Prep time in minutes (if visible or estimate)
- Cook time in minutes (if visible or estimate)
- Ingredients list with quantities
- Ordered cooking steps

Guidelines:
- Set hasRecipe to false ONLY if the image contains no food or recipe content
- Preserve ingredient quantities exactly as written (for recipe photos)
- For food photos, estimate reasonable quantities
- Steps should be individual instructions
- Use sections only for complex multi-component recipes

If multiple images are provided, they likely represent consecutive pages of the same recipe - combine them into a single complete recipe.`;

const PHOTO_PREVIEW_SYSTEM_PROMPT = `You are a culinary assistant that identifies recipes from photos.`;

const PHOTO_PREVIEW_USER_PROMPT = `Analyze the provided image(s) and extract basic recipe information:
- Determine if it contains a recipe or food (set hasRecipe accordingly)
- Extract or generate a recipe title
- Write a one-sentence description (max 100 characters)
- List the FIRST 4 ingredients only

If no recipe/food content is found, set hasRecipe to false.`;

// ============================================================================
// Main Functions
// ============================================================================

/**
 * Extracts or generates a recipe from photo(s) using GPT-4 Vision
 */
export async function extractRecipeFromImages(
  imageBuffers: Buffer[],
  hint?: string
): Promise<ExtractedRecipe | null> {
  try {
    // Build image content array for the vision API
    const imageContent = imageBuffers.map(buffer => ({
      type: 'image_url' as const,
      image_url: {
        url: `data:image/jpeg;base64,${buffer.toString('base64')}`,
        detail: 'high' as const,
      },
    }));

    const hintText = hint === 'dish'
      ? '\n\nNote: The user indicated this is a photo of a dish - please generate a recipe for it.'
      : hint === 'recipe'
      ? '\n\nNote: The user indicated this is a photo of a written recipe - please extract it.'
      : '';

    const response = await openai.chat.completions.create({
      model: 'gpt-4o', // Vision-capable model
      messages: [
        { role: 'system', content: PHOTO_EXTRACTION_SYSTEM_PROMPT },
        {
          role: 'user',
          content: [
            { type: 'text', text: PHOTO_EXTRACTION_USER_PROMPT + hintText },
            ...imageContent,
          ],
        },
      ],
      temperature: 0.3,
      response_format: zodResponseFormat(ExtractedRecipeSchema, 'extract_recipe'),
      max_tokens: 4096,
    });

    const content = response.choices[0].message.content;
    if (!content) {
      logger.warn('OpenAI returned empty response for photo recipe extraction');
      return null;
    }

    const parsed = JSON.parse(content);

    if (!parsed.hasRecipe) {
      return null;
    }

    if (!parsed.title && !parsed.ingredients?.length && !parsed.steps?.length) {
      return null;
    }

    return {
      title: parsed.title || 'Recipe from Photo',
      description: parsed.description,
      servings: parsed.servings,
      prepTime: parsed.prepTime,
      cookTime: parsed.cookTime,
      ingredients: parsed.ingredients || [],
      steps: parsed.steps || [],
    };
  } catch (error) {
    logger.error('Error extracting recipe from photo', { error });
    throw error;
  }
}

/**
 * Extracts preview from photo(s) - lightweight version for non-subscribers
 */
export async function extractPhotoRecipePreview(
  imageBuffers: Buffer[],
  hint?: string
): Promise<RecipePreview | null> {
  try {
    const imageContent = imageBuffers.map(buffer => ({
      type: 'image_url' as const,
      image_url: {
        url: `data:image/jpeg;base64,${buffer.toString('base64')}`,
        detail: 'low' as const, // Lower detail for preview (cheaper)
      },
    }));

    const response = await openai.chat.completions.create({
      model: 'gpt-4o-mini', // Cheaper model for preview
      messages: [
        { role: 'system', content: PHOTO_PREVIEW_SYSTEM_PROMPT },
        {
          role: 'user',
          content: [
            { type: 'text', text: PHOTO_PREVIEW_USER_PROMPT },
            ...imageContent,
          ],
        },
      ],
      temperature: 0.3,
      response_format: zodResponseFormat(RecipePreviewSchema, 'recipe_preview'),
      max_tokens: 500,
    });

    const content = response.choices[0].message.content;
    if (!content) return null;

    const parsed = JSON.parse(content);

    if (!parsed.hasRecipe) {
      return null;
    }

    return {
      title: parsed.title || 'Recipe from Photo',
      description: parsed.description || '',
      previewIngredients: parsed.firstFourIngredients || [],
    };
  } catch (error) {
    logger.error('Error extracting photo recipe preview', { error });
    throw error;
  }
}
```

### 4. Register Routes

**File**: `src/index.ts`

Add the new photo routes:

```typescript
import photoRoutes from './routes/photoRoutes';

// ... existing setup ...

app.use('/v1/photo', photoRoutes);
```

### 5. Add multer Dependency

```bash
cd /Users/matt/repos/recipe_app_server
npm install multer @types/multer
```

### 6. Update API Signature Middleware for Multipart

**Issue**: The current `verifyApiSignature` middleware requires `req.rawBody` which is set by `express.json()`. Multipart requests (handled by multer) bypass this, so we need a different approach.

**Solution**: For multipart photo uploads, sign based on metadata only (no body hash). This is acceptable because:
1. Images are binary data - tampering is unlikely
2. The timestamp prevents replay attacks
3. Photos go through AI processing anyway - garbage in = garbage out

**File**: `src/middleware/apiSignature.ts`

Add a new variant for multipart:

```typescript
/**
 * Middleware to verify HMAC-SHA256 signatures on multipart requests.
 *
 * For multipart uploads, we sign: METHOD\nPATH\nTIMESTAMP\nMULTIPART
 * (no body hash since body is streamed)
 */
export function verifyApiSignatureMultipart(req: Request, res: Response, next: NextFunction): void {
  if (!SIGNING_KEY) {
    logger.error('API_SIGNING_KEY not configured', { event: 'API_SIGNATURE_CONFIG_ERROR' });
    res.status(500).json({ error: 'Server configuration error' });
    return;
  }

  const apiKey = req.header('X-Api-Key');
  const timestampStr = req.header('X-Timestamp');
  const signature = req.header('X-Signature');

  if (!apiKey || !timestampStr || !signature) {
    logger.error('Missing authentication headers', { event: 'API_SIGNATURE_MISSING_HEADERS' });
    res.status(401).json({ error: 'Missing required authentication headers' });
    return;
  }

  const timestamp = parseInt(timestampStr, 10);
  if (isNaN(timestamp)) {
    res.status(401).json({ error: 'Invalid timestamp' });
    return;
  }

  const now = Math.floor(Date.now() / 1000);
  if (Math.abs(now - timestamp) > TIMESTAMP_TOLERANCE_SECONDS) {
    logger.error('Request timestamp expired', { event: 'API_SIGNATURE_EXPIRED' });
    res.status(401).json({ error: 'Request expired' });
    return;
  }

  // For multipart, use fixed placeholder instead of body hash
  const fullPath = req.originalUrl.split('?')[0];
  const canonical = `${req.method}\n${fullPath}\n${timestamp}\nMULTIPART`;

  const expectedSignature = crypto
    .createHmac('sha256', SIGNING_KEY)
    .update(canonical)
    .digest('hex');

  const signatureBuffer = Buffer.from(signature, 'hex');
  const expectedBuffer = Buffer.from(expectedSignature, 'hex');

  if (signatureBuffer.length !== expectedBuffer.length ||
      !crypto.timingSafeEqual(signatureBuffer, expectedBuffer)) {
    logger.error('Invalid signature', { event: 'API_SIGNATURE_INVALID' });
    res.status(401).json({ error: 'Invalid signature' });
    return;
  }

  next();
}
```

**Update Flutter ApiSigner** to use 'MULTIPART' placeholder for photo requests:

```dart
// In api_signer.dart - add method for multipart signing
Map<String, String> getMultipartSignatureHeaders(String method, String path) {
  final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final canonical = '$method\n$path\n$timestamp\nMULTIPART';
  final signature = _hmacSha256(canonical, _signingKey);

  return {
    'X-Api-Key': _apiKey,
    'X-Timestamp': timestamp.toString(),
    'X-Signature': signature,
  };
}
```

**Update photoRoutes.ts** to use the multipart signature verification:

```typescript
import { verifyApiSignatureMultipart } from '../middleware/apiSignature';

// In routes, use verifyApiSignatureMultipart instead of verifyApiSignature
router.post(
  '/extract-recipe',
  verifyApiSignatureMultipart,  // <-- Changed
  authenticateUser,
  verifyPlusEntitlement,
  upload.array('images', 2),
  // ...
);
```

---

## Rate Limiting Summary

| Endpoint | Limit | Who |
|----------|-------|-----|
| `/v1/photo/preview-recipe` | 2/day per IP | Non-Plus users |
| `/v1/photo/extract-recipe` | 5/min, 50/day per IP | Plus users |
| `/v1/share/preview-recipe` | 5/day per IP | Non-Plus users |
| `/v1/web/preview-recipe` | 5/day per IP | Non-Plus users |

---

## User Flow Diagrams

### Share Extension Path

```
User shares image(s) from Photos app
         │
         ▼
   Share Extension
   captures images
         │
         ▼
   App opens with
   share session
         │
         ▼
  Share Session Modal
  detects image items
         │
         ▼
  Shows "Import Recipe
   from Photo" button
         │
         ▼
  User taps Import
         │
         ▼
  ┌──────┴──────┐
  │             │
 Plus?        No Plus?
  │             │
  ▼             ▼
Full         Check quota
extract      (2/day)
  │             │
  │      ┌──────┴──────┐
  │      │             │
  │    Quota OK     Exhausted
  │      │             │
  │      ▼             ▼
  │   Preview       Paywall
  │   request       (no API)
  │      │             │
  │      ▼             │
  │   Show            │
  │   Preview         │
  │      │             │
  │      ├─────────────┘
  │      ▼
  │   Unlock?
  │      │
  │      ├──► Paywall
  │      │      │
  │      │      ▼
  │      │   Purchase
  │      │      │
  ▼      ▼      ▼
Full extraction
(API call)
         │
         ▼
  Recipe Editor
  (pre-populated)
```

### In-App Path

```
User on Recipes Root or Folder Page
         │
         ▼
  Taps "..." menu
         │
         ▼
  ┌──────┴──────┐
  │             │
"Import      "Capture
 from         Recipe"
 Photo"          │
  │              ▼
  ▼           Camera
Gallery       opens
picker           │
  │              │
  ├──────────────┘
  ▼
Selects/captures
1-2 images
         │
         ▼
  Photo Import Modal
  opens
         │
         ▼
  (Same flow as share
   extension from here)
```

---

## Implementation Order

### Phase 1: Backend (Day 1)
1. Add multer dependency
2. Create `photoExtractionService.ts`
3. Create `photoController.ts`
4. Create `photoRoutes.ts`
5. Register routes in `index.ts`
6. Test with curl/Postman

### Phase 2: Frontend Service Layer (Day 2)
1. Create `photo_extraction_service.dart`
2. Update `preview_usage_service.dart` with photo quota
3. Create `image_utils.dart` for compression/preparation

### Phase 3: Share Extension Integration (Day 2-3)
1. Add image detection in `share_session_modal.dart`
2. Add `_handleImageImport()` handler
3. Add photo preview flow
4. Test end-to-end with share extension

### Phase 4: In-App Integration (Day 3)
1. Create `photo_import_modal.dart`
2. Add menu items to `recipes_root.dart`
3. Add menu items to `recipes_folder_page.dart`
4. Test camera and gallery flows

### Phase 5: Polish & Testing (Day 4)
1. Error handling edge cases
2. Loading states and progress indicators
3. Analytics events
4. Edge case testing (large images, corrupt files, etc.)

---

## Testing Checklist

### Share Extension
- [ ] Single image share works
- [ ] Two images share works
- [ ] More than 2 images takes only first 2
- [ ] Non-image items are ignored
- [ ] Plus user gets full extraction
- [ ] Non-Plus user sees preview
- [ ] Preview quota enforced (2/day)
- [ ] Paywall flow works
- [ ] Post-purchase extraction works

### In-App - Gallery
- [ ] Gallery picker opens
- [ ] Single image selection works
- [ ] Multiple image selection works (max 2)
- [ ] Large images are compressed
- [ ] Works on recipes_root
- [ ] Works on folder page (with correct folderId)

### In-App - Camera
- [ ] Camera opens
- [ ] Photo capture works
- [ ] Multiple captures work (max 2)
- [ ] Works on recipes_root
- [ ] Works on folder page

### Recipe Extraction
- [ ] Recipe photo extracts correctly
- [ ] Food photo generates recipe
- [ ] Multi-page recipe combines correctly
- [ ] Non-recipe photo returns error gracefully
- [ ] Recipe opens in editor with data populated

### Error Handling
- [ ] Network error shows appropriate message
- [ ] Rate limit error shows paywall
- [ ] Server error shows retry option
- [ ] Invalid image format handled

---

## Design Decisions (Resolved)

1. **Hint selection**: Let AI figure out if it's a recipe photo or dish photo. No upfront question needed.

2. **Progress indication**: Use standard loader - no upload progress percentage needed.

3. **Image preview**: Yes - show preview before submitting with ability to remove images.

4. **Multi-page flow**: Show "Add another image" button under the image preview. When user adds second image, show both thumbnails with X button in corner to remove (following existing pattern from `image_picker_section.dart`).

---

## Dependencies

### Backend
- `multer` - Multipart form handling for image uploads
- `@types/multer` - TypeScript types

### Frontend
- `image_picker` - Already installed
- `flutter_image_compress` - Already installed

---

## Cost Considerations

OpenAI Vision API costs (as of late 2024):
- GPT-4o with images: ~$0.01-0.03 per image (depending on detail level)
- GPT-4o-mini: ~$0.001-0.003 per image

With 2/day limit for non-Plus previews:
- Worst case: 2 * $0.003 = $0.006/user/day for tire-kickers
- Plus users with full extraction: ~$0.02-0.06 per extraction

The strict 2/day limit for photos (vs 5/day for text) reflects the higher API cost of vision models.
