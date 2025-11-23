import '../../database/database.dart';

extension RecipeFolderEntryExtension on RecipeFolderEntry {
  bool get isNormalFolder => folderType == 0;
  bool get isSmartTagFolder => folderType == 1;
  bool get isSmartIngredientFolder => folderType == 2;
  bool get isSmartFolder => folderType != 0;

  String get folderTypeLabel {
    switch (folderType) {
      case 1: return 'Smart (Tags)';
      case 2: return 'Smart (Ingredients)';
      default: return 'Folder';
    }
  }
}
