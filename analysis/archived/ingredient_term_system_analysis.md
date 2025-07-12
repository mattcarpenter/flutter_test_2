# Ingredient Term System Analysis

## Overview of Term-Based Matching

The recipe app implements a term-based matching system to identify when recipe ingredients correspond to items in a user's pantry. This document analyzes the current implementation and considers potential optimizations.

## Core Components

### 1. Term System

Both recipe ingredients and pantry items have associated "terms":

- **Recipe Ingredient Terms**: Each ingredient can have multiple terms stored in its JSON data
- **Pantry Item Terms**: Each pantry item also has multiple terms
- **Matching Logic**: An ingredient matches a pantry item if at least one term from each side matches

The terms are denormalized into dedicated tables for query performance:
- `recipe_ingredient_terms` table 
- `pantry_item_terms` table

### 2. Term Overrides System

A separate system called "ingredient term overrides" creates global mappings between terms:

```
inputTerm: "margarine" → mappedTerm: "butter"
```

This system is implemented in:
- `ingredient_term_overrides` table
- `ingredient_term_overrides_flattened` table (denormalized version)

## Technical Implementation

### SQL Query Logic

The matching system works through SQL queries that:

1. First apply any term overrides: 
   ```sql
   COALESCE(ito.mapped_term, rit.term) AS effective_term
   ```

2. Then join with pantry items:
   ```sql
   FROM ingredient_terms_with_mapping itwm
   INNER JOIN pantry_item_terms pit
     ON LOWER(itwm.effective_term) = LOWER(pit.term)
   ```

### Triggers

Database triggers keep the denormalized tables in sync:
- When recipes or pantry items are updated, their terms are extracted and stored in the respective terms tables
- When term overrides are created/updated, they are flattened to the optimized table

## Functional Analysis

### Redundancy Considerations

There is functional overlap between:
1. Adding terms directly to pantry items
2. Creating global mappings via term overrides

For example:
- Adding "scallions" as a term to a "green onions" pantry item
- Creating a term override mapping "scallions" → "green onions"

Both approaches would allow recipes calling for scallions to match with green onions in the pantry.

### Potential Advantages of Term Overrides

1. **Global Application**: One mapping applies across all recipes
2. **Persistence**: Survives pantry item modifications/deletions
3. **Standardization**: Creates a consistent vocabulary
4. **Efficiency**: One rule instead of updating multiple pantry items
5. **Directional**: Can specify one-way mappings if needed

### Redundancy Assessment

From our discussion, it appears that having both systems might be redundant for most use cases:

- Both systems ultimately attempt to solve the matching problem
- The additional complexity of maintaining two systems might not justify the marginal benefits
- User mental model might be clearer with a single approach

## Recommendation

Consider consolidating to a single approach:

1. **Option A: Enhance Pantry Item Terms**
   - Add UI for managing terms directly on pantry items
   - Simplify the database schema by removing the overrides system
   - More intuitive for users ("my pantry item is also known as X")

2. **Option B: Focus on Term Overrides**
   - Position as a "substitutions dictionary"
   - More powerful for power users
   - Works across pantry changes

3. **Option C: Keep Both but Clarify Use Cases**
   - Pantry Terms: For alternate names of specific items
   - Term Overrides: For cooking substitution knowledge

## Technical Design Considerations

If consolidating systems:
- Ensure database migrations preserve existing matching capabilities
- Update UI to maintain or improve user experience
- Consider performance impacts of any schema changes

## Historical Context

The term system was likely implemented first as a direct approach to matching, while the overrides system may have been added later to address limitations or add more powerful features. However, the practical benefits of maintaining both systems may be outweighed by the complexity they introduce.