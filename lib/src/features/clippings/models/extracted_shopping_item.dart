/// Represents a shopping list item extracted and canonicalized from clipping text
class ExtractedShoppingItem {
  final String name;
  final List<String> terms;
  final String category;

  const ExtractedShoppingItem({
    required this.name,
    required this.terms,
    required this.category,
  });

  factory ExtractedShoppingItem.fromJson(Map<String, dynamic> json) {
    return ExtractedShoppingItem(
      name: json['name'] as String,
      terms: (json['terms'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      category: json['category'] as String? ?? 'Other',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'terms': terms,
      'category': category,
    };
  }
}
