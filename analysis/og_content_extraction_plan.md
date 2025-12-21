# OG Content Extraction Plan

## Overview

When a user taps "Import Recipe" or "Save as Clipping" in the share modal, if the shared content includes a URL from a supported domain (Instagram, future: TikTok), we extract the `og:title` and potentially other Open Graph metadata using a hidden WebView.

## User Flow

```
Share Modal opens
  ↓
User sees two buttons: "Import Recipe" / "Save as Clipping"
  ↓
User taps either button
  ↓
Is there a URL from a supported domain?
  ├─ No  → Proceed to next phase (future implementation)
  └─ Yes → Show spinner in modal
            ↓
           Load URL in hidden WebView (images blocked)
            ↓
           Extract OG content via JavaScript
            ↓
           Replace spinner with extracted content preview (truncated)
            ↓
           (Future: proceed to recipe import or clipping save)
```

## Supported Domains

Initial:
- `instagram.com` (including `www.instagram.com`, subdomains)

Future expansion:
- `tiktok.com`
- `youtube.com`
- `pinterest.com`
- etc.

Domain matching should be generic:
```dart
bool isSupportedDomain(String? host) {
  if (host == null) return false;
  final supportedDomains = ['instagram.com', 'tiktok.com'];
  return supportedDomains.any((domain) => host.contains(domain));
}
```

## Technical Approach

### Package Choice: `flutter_inappwebview`

Prefer `flutter_inappwebview` over `webview_flutter` because:
- Can block resource loading (images, fonts, etc.) for faster extraction
- More control over headless/hidden operation
- Better JavaScript evaluation API
- Cross-platform support

### OG Content Extractor Service

Create a reusable service that:
1. Takes a URL
2. Validates it's from a supported domain
3. Creates a hidden/zero-sized InAppWebView
4. Configures it to block images and unnecessary resources
5. Loads the URL
6. Waits for page load (with timeout)
7. Executes JavaScript to extract OG tags
8. Returns extracted data

```dart
class OGExtractedContent {
  final String? title;       // og:title
  final String? description; // og:description (future)
  final String? imageUrl;    // og:image (future)
  final String? siteName;    // og:site_name (future)

  OGExtractedContent({this.title, this.description, this.imageUrl, this.siteName});
}

class OGContentExtractor {
  static const _timeout = Duration(seconds: 8);

  static const _supportedDomains = ['instagram.com', 'tiktok.com'];

  static bool isSupported(Uri uri) {
    final host = uri.host;
    return _supportedDomains.any((domain) => host.contains(domain));
  }

  Future<OGExtractedContent?> extract(Uri uri) async {
    if (!isSupported(uri)) return null;
    // ... WebView logic
  }
}
```

### JavaScript for OG Extraction

```javascript
(function() {
  const getMeta = (property) => {
    const el = document.querySelector(`meta[property="${property}"]`);
    return el ? el.content : null;
  };
  return JSON.stringify({
    title: getMeta('og:title'),
    description: getMeta('og:description'),
    image: getMeta('og:image'),
    siteName: getMeta('og:site_name')
  });
})();
```

### WebView Configuration (Block Images)

```dart
InAppWebViewSettings(
  // Block images for faster loading
  blockNetworkImage: true,
  // Disable JavaScript popups
  javaScriptCanOpenWindowsAutomatically: false,
  // Disable media autoplay
  mediaPlaybackRequiresUserGesture: true,
  // Other performance optimizations
  cacheEnabled: false,
  clearCache: true,
  // User agent (appear as mobile browser)
  userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) ...',
)
```

### Hidden WebView Strategy

Two options:

**Option A: Zero-sized widget in tree**
```dart
SizedBox(
  width: 0,
  height: 0,
  child: InAppWebView(...),
)
```

**Option B: Offscreen/Headless (if supported)**
```dart
HeadlessInAppWebView(...)
```

Recommend **Option B** (HeadlessInAppWebView) if flutter_inappwebview supports it well, otherwise Option A.

## Modal State Machine

```dart
enum ShareModalState {
  choosingAction,      // Initial: showing two buttons
  extractingContent,   // Spinner while WebView loads
  showingPreview,      // Showing extracted content
  error,               // Extraction failed (show retry or proceed anyway)
}
```

## Updated Modal UI

### State: `choosingAction`
```
┌─────────────────────────────────┐
│  Shared Content            [X] │
├─────────────────────────────────┤
│  ┌─────────────────────────┐   │
│  │ 🍽  Import Recipe        │   │
│  │ Extract and create...   │   │
│  └─────────────────────────┘   │
│  ┌─────────────────────────┐   │
│  │ 📝  Save as Clipping    │   │
│  │ Save for later...       │   │
│  └─────────────────────────┘   │
└─────────────────────────────────┘
```

### State: `extractingContent`
```
┌─────────────────────────────────┐
│  Extracting Content        [X] │
├─────────────────────────────────┤
│                                 │
│         ◌ (spinner)             │
│    Fetching from Instagram...   │
│                                 │
└─────────────────────────────────┘
```

### State: `showingPreview`
```
┌─────────────────────────────────┐
│  Extracted Content         [X] │
├─────────────────────────────────┤
│                                 │
│  "Amazing Pasta Recipe by      │
│   @chef_name - This creamy..." │
│                                 │
│  [Continue] or [Back]          │
│                                 │
└─────────────────────────────────┘
```

## File Structure

```
lib/src/
├── services/
│   └── og_content_extractor.dart    # New: extraction service
├── features/share/
│   ├── views/
│   │   └── share_session_modal.dart # Update: state machine
│   └── models/
│       └── og_extracted_content.dart # New: data model
```

## Implementation Steps

1. **Add dependency**: `flutter_inappwebview` to pubspec.yaml

2. **Create OGExtractedContent model**
   - title, description, imageUrl, siteName fields
   - fromJson factory for JS result parsing

3. **Create OGContentExtractor service**
   - isSupported() static method
   - extract(Uri) async method
   - HeadlessInAppWebView with image blocking
   - JavaScript evaluation
   - Timeout handling (8 seconds)
   - Error handling (return null on failure)

4. **Update ShareSessionModal**
   - Add state enum (choosingAction, extractingContent, showingPreview, error)
   - Track which action user chose (recipe vs clipping)
   - On button tap: check for supported URL, start extraction if applicable
   - Show appropriate UI for each state
   - Store extracted content for use in next phase

5. **Update logging**
   - Log extraction attempts and results
   - Log timing for performance monitoring

## Error Handling

| Scenario | Handling |
|----------|----------|
| No URL in session | Skip extraction, proceed directly |
| URL not from supported domain | Skip extraction, proceed directly |
| WebView fails to load | Show error state with "Continue anyway" option |
| Timeout (8s) | Treat as failure, show error state |
| JS execution fails | Treat as failure, show error state |
| OG tags not found in page | Return empty content, show "No content found" |

## Performance Considerations

1. **Block images**: Major bandwidth/time saver
2. **Block fonts**: If possible, reduces load time
3. **Timeout**: 8 seconds max to avoid hanging
4. **Single extraction**: Don't re-extract if user goes back and forth
5. **Dispose WebView**: Clean up immediately after extraction

## Future Enhancements

1. **More domains**: TikTok, YouTube, Pinterest, Twitter/X
2. **More OG tags**: description, image preview
3. **Caching**: Cache extracted content by URL
4. **Recipe-specific extraction**: For known recipe sites, extract structured data (JSON-LD)
5. **Fallback strategies**: Try multiple selectors if og:title not found

## Questions to Consider

1. Should extraction happen automatically when modal opens (background) or only on button tap?
   - **Recommendation**: On button tap - saves resources if user dismisses

2. Should we show extracted content preview or go straight to next step?
   - **Current plan**: Show preview for validation before proceeding

3. What if extraction succeeds but returns empty/useless content?
   - Show "No content could be extracted" with option to proceed anyway

---

## Approval Checklist

- [ ] Package choice: `flutter_inappwebview`
- [ ] Trigger: On button tap (not auto on modal open)
- [ ] Domains: Start with Instagram only
- [ ] Timeout: 8 seconds
- [ ] Image blocking: Yes
- [ ] Show preview before proceeding: Yes
- [ ] Both paths (recipe + clipping) use same extraction: Yes