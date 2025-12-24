# YouTube Extractor Implementation Plan

## Problem Statement

YouTube shares from iOS come as a **text item** where `item.type == 'text'` and `item.text` contains the URL (e.g., `https://www.youtube.com/watch?v=...`).

The current `_findExtractableUrl()` only checks `item.isUrl` (where `item.type == 'url'`), so YouTube URLs are never detected and extraction fails.

## Current Architecture

```
ContentExtractor
├── TikTokExtractor      (HTTP + HTML parsing)
├── InstagramExtractor   (HTTP + OG meta tags)
└── WebViewOGExtractor   (WebView fallback)
```

Each extractor extends `SiteExtractor` with:
- `supportedDomains` - list of domains to match
- `canHandle(Uri)` - checks if URL matches
- `extract(Uri)` - performs extraction, returns `OGExtractedContent`
- `getDisplayName(Uri)` - user-friendly name for UI

## Implementation Plan

### 1. Create YouTube Extractor

**File:** `lib/src/services/content_extraction/extractors/youtube_extractor.dart`

```dart
class YouTubeExtractor extends SiteExtractor {
  @override
  List<String> get supportedDomains => ['youtube.com', 'youtu.be'];

  @override
  String? getDisplayName(Uri uri) => 'YouTube';

  @override
  Future<OGExtractedContent?> extract(Uri uri) async {
    // 1. HTTP GET with mobile user agent
    // 2. Find "var ytInitialPlayerResponse = " in HTML
    // 3. Extract JSON using brace-counting parser
    // 4. Parse videoDetails object
    // 5. Return OGExtractedContent
  }
}
```

**Extraction Strategy:**

YouTube embeds video metadata in a script tag:
```javascript
var ytInitialPlayerResponse = {
  "videoDetails": {
    "title": "Video Title",
    "shortDescription": "Full description text...",
    "thumbnail": {
      "thumbnails": [
        { "url": "https://...", "width": 120, "height": 90 },
        { "url": "https://...", "width": 1280, "height": 720 }
      ]
    }
  }
};
```

**JSON Extraction:**

Use brace-counting that tracks string context to handle nested objects:
```dart
String? _extractJsonObject(String html, String marker) {
  final startIndex = html.indexOf(marker);
  if (startIndex == -1) return null;

  final jsonStart = html.indexOf('{', startIndex + marker.length);
  if (jsonStart == -1) return null;

  var depth = 0;
  var inString = false;
  var escaped = false;

  for (var i = jsonStart; i < html.length; i++) {
    final char = html[i];

    if (escaped) { escaped = false; continue; }
    if (char == '\\' && inString) { escaped = true; continue; }
    if (char == '"') { inString = !inString; continue; }

    if (!inString) {
      if (char == '{') depth++;
      if (char == '}') {
        depth--;
        if (depth == 0) {
          return html.substring(jsonStart, i + 1);
        }
      }
    }
  }
  return null;
}
```

**Thumbnail Selection:**

Find largest by width:
```dart
Map<String, dynamic>? _getLargestThumbnail(List<dynamic> thumbnails) {
  if (thumbnails.isEmpty) return null;
  return thumbnails.reduce((a, b) {
    final aWidth = (a['width'] as num?)?.toInt() ?? 0;
    final bWidth = (b['width'] as num?)?.toInt() ?? 0;
    return aWidth > bWidth ? a : b;
  }) as Map<String, dynamic>;
}
```

### 2. Register Extractor

**File:** `lib/src/services/content_extraction/content_extractor.dart`

```dart
import 'extractors/youtube_extractor.dart';

final List<SiteExtractor> _extractors = [
  YouTubeExtractor(),  // NEW
  TikTokExtractor(),
  InstagramExtractor(),
  WebViewOGExtractor(),
];
```

### 3. Update URL Detection in Share Modal

**File:** `lib/src/features/share/views/share_session_modal.dart`

#### `_findExtractableUrl()`

Expand to check text items for URLs:

```dart
Uri? _findExtractableUrl() {
  if (_session == null) return null;

  for (final item in _session!.items) {
    // Check explicit URL items (existing behavior)
    if (item.isUrl && item.url != null) {
      final uri = Uri.tryParse(item.url!);
      if (uri != null && _extractor.isSupported(uri)) {
        return uri;
      }
    }

    // NEW: Check text items that contain URLs (YouTube shares)
    if (item.isText && item.text != null) {
      final text = item.text!.trim();
      if (text.startsWith('http://') || text.startsWith('https://')) {
        final uri = Uri.tryParse(text);
        if (uri != null && _extractor.isSupported(uri)) {
          return uri;
        }
      }
    }
  }
  return null;
}
```

#### `_gatherClippingContent()`

Same pattern for sourceUrl detection:

```dart
// Get URL from share session items
for (final item in _session!.items) {
  if (item.isUrl && item.url != null && item.url!.isNotEmpty) {
    sourceUrl = item.url;
    break;
  }
  // Also check text items for URLs (YouTube shares)
  if (item.isText && item.text != null) {
    final text = item.text!.trim();
    if (text.startsWith('http://') || text.startsWith('https://')) {
      sourceUrl = text;
      break;
    }
  }
}
```

## YouTube URL Patterns

| Pattern | Example |
|---------|---------|
| Standard | `https://www.youtube.com/watch?v=VIDEO_ID` |
| Short | `https://youtu.be/VIDEO_ID` |
| Mobile | `https://m.youtube.com/watch?v=VIDEO_ID` |
| Shorts | `https://www.youtube.com/shorts/VIDEO_ID` |

All matched by `host.contains('youtube.com')` or `host.contains('youtu.be')`.

## Edge Cases

| Case | Handling |
|------|----------|
| `youtu.be` short URLs | Included in `supportedDomains` |
| Mobile URLs (`m.youtube.com`) | `contains('youtube.com')` matches |
| YouTube Shorts | Same extraction logic works |
| Nested JSON braces | Brace-counting with string awareness |
| WebP thumbnails | Just a URL string - works for display |
| Missing `ytInitialPlayerResponse` | Returns null → graceful failure |
| Age-restricted videos | May fail extraction → returns null |
| Private videos | May fail extraction → returns null |

## Files to Modify

1. **Create:** `lib/src/services/content_extraction/extractors/youtube_extractor.dart`
2. **Update:** `lib/src/services/content_extraction/content_extractor.dart`
3. **Update:** `lib/src/features/share/views/share_session_modal.dart`

## Testing Approach

1. Share a YouTube video to the app
2. Verify "Import Recipe" flow works (extraction succeeds)
3. Verify "Save as Clipping" includes the URL
4. Test with different URL formats (youtu.be, shorts, etc.)