/// Lightweight shopping list preview for non-subscribed users.
///
/// Contains only the hasItems flag and first 4 items
/// to give a teaser of the full shopping list.
class ShoppingListPreview {
  final bool hasItems;
  final List<String> previewItems;

  const ShoppingListPreview({
    required this.hasItems,
    required this.previewItems,
  });

  factory ShoppingListPreview.fromJson(Map<String, dynamic> json) {
    return ShoppingListPreview(
      hasItems: json['hasItems'] as bool? ?? false,
      previewItems: (json['previewItems'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}
