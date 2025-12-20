/// Lightweight recipe preview for non-subscribed users.
///
/// Contains only the title, description, and first 4 ingredients
/// to give a teaser of the full recipe.
class RecipePreview {
  final String title;
  final String description;
  final List<String> previewIngredients;

  const RecipePreview({
    required this.title,
    required this.description,
    required this.previewIngredients,
  });

  factory RecipePreview.fromJson(Map<String, dynamic> json) {
    return RecipePreview(
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      previewIngredients: (json['previewIngredients'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}
