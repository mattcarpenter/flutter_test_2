/// Represents a recipe idea generated from AI brainstorming.
///
/// This is a lightweight representation of a recipe concept, containing
/// just enough information for the user to select which idea they want
/// to develop into a full recipe.
class RecipeIdea {
  /// Unique identifier for this idea (used for selection tracking)
  final String id;

  /// Compelling title for the recipe
  final String title;

  /// Brief (1-2 sentence) description of the dish
  final String description;

  /// Estimated total cooking time in minutes
  final int? estimatedTime;

  /// Difficulty level: 'easy', 'medium', or 'hard'
  final String? difficulty;

  /// 3-5 key ingredients for this recipe
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    if (estimatedTime != null) 'estimatedTime': estimatedTime,
    if (difficulty != null) 'difficulty': difficulty,
    'keyIngredients': keyIngredients,
  };

  /// Returns a formatted time string (e.g., "30 min" or "1 hr 15 min")
  String? get formattedTime {
    if (estimatedTime == null) return null;
    if (estimatedTime! < 60) return '$estimatedTime min';
    final hours = estimatedTime! ~/ 60;
    final mins = estimatedTime! % 60;
    if (mins == 0) return '$hours hr';
    return '$hours hr $mins min';
  }

  /// Returns a user-friendly difficulty label
  String? get difficultyLabel {
    if (difficulty == null) return null;
    switch (difficulty) {
      case 'easy':
        return 'Easy';
      case 'medium':
        return 'Medium';
      case 'hard':
        return 'Hard';
      default:
        return difficulty;
    }
  }
}
