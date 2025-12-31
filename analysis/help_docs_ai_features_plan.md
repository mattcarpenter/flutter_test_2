# Help Documentation Plan: AI Features

This document proposes updates to the help documentation (`assets/docs/`) to cover new AI-powered features.

## Writing Style Reference

Based on existing docs:
- **Tone**: Direct, conversational ("you", action-oriented)
- **Length**: 2-5 short paragraphs per topic
- **Structure**: Opening sentence → how-to steps → tips
- **Formatting**: Bold for UI elements, numbered lists for procedures

---

## Proposed New Topics

### Quick Questions Section

#### 1. `import-from-social.md`
**Title**: How do I import from Instagram, TikTok, or YouTube?

**Content outline**:
- Find a recipe video in Instagram, TikTok, or YouTube
- Tap the share button within that app
- Select Stockpot from the share sheet
- Tap "Import Recipe" to add it to your library
- Note: This works best when the post includes the recipe in the description. If the description is incomplete, we'll try to infer missing details.
- Requires Plus subscription

---

#### 2. `import-recipe-from-url.md`
**Title**: How do I import a recipe from a website?

**Content outline**:
- Tap **+** on Recipes tab or **...** menu → "Import from URL"
- Paste the URL and tap Import
- Works with most recipe websites and blogs
- For YouTube, TikTok, or Instagram videos, use the share feature within those apps instead (see "How do I import from Instagram, TikTok, or YouTube?")
- Requires Plus subscription

---

#### 3. `generate-recipe-ai.md`
**Title**: How do I generate a recipe with AI?

**Content outline**:
- Tap **+** or **...** menu → "Generate with AI"
- Describe what you want (e.g., "a warm soup with chicken")
- Optionally include pantry items for suggestions using what you have
- Pick from recipe ideas, then save to your library
- Requires Plus subscription

---

#### 4. `extract-from-clipping.md`
**Title**: How do I turn a clipping into a recipe?

**Content outline**:
- Open a clipping with recipe text
- Tap "Convert to Recipe" button
- AI extracts title, ingredients, and steps automatically
- Review and edit before saving
- Also works for shopping lists ("To Shopping List" button)
- Mention: requires Plus subscription

---

#### 5. `discover-recipes.md`
**Title**: What is the Discover page?

**Content outline**:
- Browse curated recipe websites from the Discover page (in menu)
- Navigate like a regular browser
- When you find a recipe, tap "Import Recipe" to add it to your library
- Browsing is free; importing recipes requires Plus subscription

---

### Learn More Section

#### 6. `ai-features-overview.md`
**Title**: AI Features in Stockpot

**Content outline**:
- Brief intro: AI helps you capture and create recipes faster
- **Import from URL**: Paste any recipe link from a website
- **Import from Social**: Share from Instagram, TikTok, or YouTube directly to Stockpot
- **Generate with AI**: Describe a dish, get recipe ideas
- **Extract from Clippings**: Turn copied text into structured recipes
- **Discover**: Browse recipe sites and import directly
- Note: AI features require Plus subscription

---

### Troubleshooting Section

#### 7. `recipe-import-not-working.md`
**Title**: Recipe import isn't working

**Content outline**:
- Import only works on pages that actually contain a recipe (not homepages or category pages)
- We first try to extract structured recipe data from the page
- If that's not available, we use AI to find and extract the recipe
- If extraction fails: try copying the recipe text and using a clipping instead
- Check your internet connection if nothing loads

---

## Topics NOT Needed

These are adequately covered by the feature UI itself or are self-explanatory:
- Free user experience / preview system (users discover this in-app)
- Specific social platform support details (URL import handles this automatically)
- Detailed subscription benefits (paywall explains this)

---

## File Placement Summary

| File | Section | Priority |
|------|---------|----------|
| `import-from-social.md` | quick-questions | High |
| `import-recipe-from-url.md` | quick-questions | High |
| `generate-recipe-ai.md` | quick-questions | High |
| `extract-from-clipping.md` | quick-questions | Medium |
| `discover-recipes.md` | quick-questions | Medium |
| `ai-features-overview.md` | learn-more | High |
| `recipe-import-not-working.md` | troubleshooting | Medium |

---

## Notes

- **AI features require Plus subscription** - state this clearly but briefly
- Don't mention previews or free user limitations in the docs (users discover this naturally in the app)
- Keep Plus mentions brief and non-salesy (just factual)
- Focus on "how do I do X" rather than feature marketing
- Match existing doc length (~100-200 words per topic)
