import 'package:json_annotation/json_annotation.dart';

part 'recipe_folder.g.dart'; // Generated file for serialization logic.

@JsonSerializable(explicitToJson: true)
class RecipeFolder {
  final String? id; // Will be used for Firestore sync later.
  final String name;
  final String? parentId; // ID of the parent folder, if any.

  RecipeFolder({
    this.id,
    required this.name,
    this.parentId,
  });

  // Serialization logic
  factory RecipeFolder.fromJson(Map<String, dynamic> json) =>
      _$RecipeFolderFromJson(json);
  Map<String, dynamic> toJson() => _$RecipeFolderToJson(this);

  // Helper to create a new instance for local-first use
  static RecipeFolder newFolder(String name, {String? parentId}) {
    return RecipeFolder(
      id: null, // No ID for local-first, assigned later when syncing.
      name: name,
      parentId: parentId,
    );
  }
}
