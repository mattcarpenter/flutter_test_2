# Recipe Image System Documentation

This document provides a comprehensive overview of how recipe images work in the Flutter recipe app, including upload sequences, storage, loading states, and edge cases.

## Overview

The recipe image system is built as an **offline-first** architecture that allows users to add images to recipes without internet connectivity. Images are stored locally first, then uploaded to Supabase Storage when connectivity is available.

## Core Components

### 1. Image Data Model

**File**: `lib/database/models/recipe_images.dart`

```dart
class RecipeImage {
  final String id;          // Unique identifier (nanoid)
  final String fileName;    // UUID-based filename (e.g., "abc123.jpg")
  final bool? isCover;      // Whether this is the cover image
  final String? publicUrl;  // Supabase Storage URL (null until uploaded)
}
```

**Key Features**:
- Dual size support: `large` (original) and `small` (thumbnail)
- Dynamic URL generation: `getPublicUrlForSize()` appends `_small` suffix for thumbnails
- Images stored as JSON array in the `images` column of the `recipes` table
- Uses `RecipeImageListConverter` for JSON serialization

### 2. Upload Queue System

**File**: `lib/src/managers/upload_queue_manager.dart`

The upload queue provides reliable background uploading with retry logic:

```dart
class UploadQueueManager {
  // Constants
  static const Duration baseDelay = Duration(seconds: 2);
  static const int maxRetries = 5;
}
```

**Features**:
- **Exponential backoff**: `baseDelay * 2^retryCount`
- **Connectivity aware**: Auto-processes when network returns
- **Dual upload**: Uploads both full-size and `_small` versions
- **Error handling**: Max 5 retries before marking as failed
- **State tracking**: `pending` → `uploading` → `uploaded` / `failed`

### 3. Image Display Widget

**File**: `lib/src/widgets/local_or_network_image.dart`

Smart widget that prioritizes local files over network URLs:

```dart
class LocalOrNetworkImage extends StatefulWidget {
  final String filePath;  // Local filename
  final String url;       // Network URL
  final BoxFit fit;
  // ... dimensions
}
```

**Display Priority**:
1. **Local file exists**: Show local image immediately
2. **Network URL available**: Show network image with caching
3. **Neither available**: Show fallback icon

## Data Flow Sequences

### 1. Image Selection and Storage

```
1. User selects image (camera/gallery)
   ↓
2. Generate UUID filename (e.g., "abc123.jpg")
   ↓
3. Compress image to two sizes:
   - Large: 1280px at 90% quality → "abc123.jpg"
   - Small: 512px at 90% quality → "abc123_small.jpg"
   ↓
4. Save both to app documents directory
   ↓
5. Create RecipeImage model with fileName (publicUrl = null)
   ↓
6. Update recipe's images array
```

### 2. Upload Queue Processing

```
1. Recipe saved with images (publicUrl = null)
   ↓
2. Add to upload queue for each image
   ↓
3. UploadQueueManager processes queue when:
   - User is logged in (auth.currentUser != null)
   - Network connectivity available
   - Retry backoff period elapsed
   ↓
4. Upload both files to Supabase Storage:
   - Path: {userId}/{filename}
   - Bucket: "recipe_images"
   ↓
5. Update recipe with publicUrl
   ↓
6. Mark queue entry as 'uploaded'
```

### 3. Image Display Resolution

```
1. LocalOrNetworkImage widget renders
   ↓
2. Check if local file exists
   ├─ YES: Display local file (Image.file)
   └─ NO: Continue to network
   ↓
3. Check if publicUrl exists
   ├─ YES: Display network image (CachedNetworkImage)
   └─ NO: Display fallback icon
```

## Loading States and Animations

### 1. Shimmer Loading Effect

**Usage**: Primary loading animation throughout the app

```dart
Shimmer.fromColors(
  baseColor: Colors.grey[300]!,
  highlightColor: Colors.grey[100]!,
  child: Container(
    color: Colors.white,
  ),
)
```

**When shown**:
- Initial file existence check
- Network image loading (via CachedNetworkImage placeholder)

### 2. Network Image Transitions

**Configuration**:
- **fadeInDuration**: 180ms
- **fadeOutDuration**: 180ms  
- **fadeOutCurve**: Curves.easeOut

**Smooth transitions** between loading → loaded states via CachedNetworkImage.

### 3. Error States

- **Network error**: Red error icon (`Icons.error`)
- **No image available**: Grey photography icon (`Icons.no_photography`)
- **File path loading**: CircularProgressIndicator

### 4. Deletion Animations

Recipe tiles with image deletion use:
- **FadeTransition + ScaleTransition**
- **Duration**: 300ms
- **Curve**: easeOutExpo
- **Delay**: 400ms before animation starts

## Storage Configuration

### Supabase Storage

**Bucket**: `recipe_images`

**File Organization**:
```
recipe_images/
├── {userId1}/
│   ├── abc123.jpg          (full size)
│   ├── abc123_small.jpg    (thumbnail)
│   └── def456.jpg
└── {userId2}/
    └── ghi789.jpg
```

**Row-Level Security Policy**:
```sql
((bucket_id = 'recipe_images'::text) AND 
 (( SELECT (auth.uid())::text AS uid) = (storage.foldername(name))[1]))
```

Users can only access images in their own folder.

**Size Strategy**:
- **No external transformation service** (e.g., Cloudinary)
- **Client-side compression** using flutter_image_compress
- **Dual upload approach** for performance optimization
- **Small version naming**: Appends `_small` before file extension

## UI Components

### 1. Recipe Image Gallery

**File**: `lib/src/features/recipes/widgets/recipe_view/recipe_image_gallery.dart`

**Features**:
- **Main image**: 16:9 aspect ratio, large size
- **Thumbnail strip**: Horizontal scrolling, small size
- **Cover image priority**: Auto-selects marked cover image
- **Border highlighting**: Selected thumbnail has colored border
- **Navigation**: Tap thumbnails to switch main image

### 2. Image Picker Section

**File**: `lib/src/features/recipes/widgets/recipe_editor_form/sections/image_picker_section.dart`

**Features**:
- **Platform-specific dialogs**: Cupertino (iOS) vs Material (Android)
- **Sources**: Camera and photo gallery
- **Thumbnail display**: 80x80 horizontal scrolling list
- **Delete confirmation**: Platform-specific alert dialogs
- **Visual feedback**: Red overlay with close icon for deletion

### 3. Recipe Tiles

**File**: `lib/src/features/recipes/widgets/recipe_tile.dart`

**Features**:
- **Cover image display**: Uses small size for performance
- **Dynamic sizing**: Height calculation based on tile dimensions
- **Fallback handling**: Graceful degradation when no image

## Edge Cases and Known Issues

### 1. Offline Recipe Creation Bug

**Problem**: When users create recipes offline then view them after logging in, large images don't display.

**Root Cause**:
1. Recipe created offline with `userId = null`
2. Images saved locally with `publicUrl = null`
3. Upload queue entries created but not processed (no auth)
4. After login, `_claimOrphanedRecords()` updates userId but doesn't trigger upload processing
5. `LocalOrNetworkImage` falls back to network URL (which is null)

**Sequence**:
```
OFFLINE:
User creates recipe → Images saved locally → Upload queue pending

LOGIN:
Auth state changes → Orphaned records claimed → Upload queue NOT processed

VIEW RECIPE:
LocalOrNetworkImage checks local file → File exists ✓
BUT: When viewing recipe page, large image widget may not find local file
```

**Solution**: Add upload queue processing trigger after orphan claiming:

```dart
// In powersync.dart after _claimOrphanedRecords()
await _claimOrphanedRecords(userId);
// Trigger upload queue processing
uploadQueueManager.processQueue();
```

### 2. File Path Resolution

**Issue**: The `LocalOrNetworkImage` widget expects just the filename, but some contexts may pass full paths.

**Current Behavior**:
- Widget calls `File(widget.filePath).exists()`
- Works correctly when `filePath` is just filename
- `RecipeImage.getFullPath()` resolves to full path when needed

### 3. Upload Queue State Management

**Considerations**:
- Queue entries persist across app restarts
- Failed uploads (>5 retries) remain in 'failed' state
- No automatic cleanup of old 'uploaded' entries
- Upload queue doesn't inherit userId from orphan claiming

### 4. Network Connectivity Edge Cases

**Behavior**:
- Connectivity listener only triggers on state changes
- App restart while offline won't process queue until connectivity change
- Users may need to manually trigger sync or restart app

### 5. Image Compression Quality

**Current Settings**:
- **Large**: 1280px at 90% quality
- **Small**: 512px at 90% quality
- **Format**: JPEG only

**Considerations**:
- No PNG support (all converted to JPEG)
- Fixed quality settings (not adaptive)
- No progressive JPEG for better loading experience

## Performance Characteristics

### Local Storage Performance
- **Fast initial display**: Local images show immediately
- **Storage location**: App documents directory (persistent)
- **No caching library needed**: Direct file system access

### Network Performance
- **Caching**: CachedNetworkImage handles HTTP caching
- **Bandwidth optimization**: Small images used in lists/thumbnails
- **Progressive loading**: Shimmer → network image with fade transition

### Memory Usage
- **Image compression**: Reduces file sizes significantly
- **Dual size strategy**: Prevents loading large images unnecessarily
- **Widget optimization**: LocalOrNetworkImage reused throughout app

## Future Considerations for Cloudinary Migration

Based on the current architecture, migrating to Cloudinary would involve:

### 1. Upload Flow Changes
- Replace Supabase Storage with Cloudinary upload API
- Maintain local storage for offline support
- Update upload queue to use Cloudinary endpoints

### 2. URL Generation
- Replace `getPublicUrlForSize()` with Cloudinary transformation URLs
- Enable dynamic sizing instead of pre-generated thumbnails
- Add format optimization (WebP, AVIF support)

### 3. Enhanced Features
- **Automatic optimization**: Quality and format based on device
- **Responsive images**: Multiple sizes for different screen densities
- **Progressive loading**: Better perceived performance
- **Face detection**: Smart cropping for recipe thumbnails

### 4. Migration Strategy
- Keep existing file naming for backward compatibility
- Implement gradual migration for existing images
- Maintain fallback to local images during migration

## Testing Scenarios

### Critical Test Cases

1. **Offline Recipe Creation**:
   - Create recipe offline with images
   - Login and verify large images display correctly
   - Verify upload queue processes after login

2. **Connectivity Changes**:
   - Start upload, lose connectivity, regain connectivity
   - Verify retry logic and eventual success
   - Test exponential backoff timing

3. **Image Display Priority**:
   - Local file exists, no network: Show local
   - Local file missing, network available: Show network
   - Neither available: Show fallback icon

4. **Error Recovery**:
   - Upload fails repeatedly (test max retries)
   - Local file deleted after recipe creation
   - Network image URL becomes invalid

5. **Performance**:
   - Large recipe lists with many images
   - Rapid scrolling through image galleries
   - Memory usage during extended use

This documentation provides a comprehensive understanding of the recipe image system's architecture, helping developers maintain, debug, and enhance the image handling capabilities of the application.