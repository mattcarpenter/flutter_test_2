import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recipe_folder.dart';

class RecipeFolderRepository {
  final FirebaseFirestore _firestore;

  RecipeFolderRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Firestore collection reference
  CollectionReference get _collection =>
      _firestore.collection('recipeFolders');

  // Add a new folder
  Future<void> addFolder(RecipeFolder folder) async {
    final doc = _collection.doc();
    await doc.set(folder.toJson()..['id'] = doc.id); // Assign Firestore ID
  }

  // Fetch all folders
  Future<List<RecipeFolder>> getAllFolders() async {
    final querySnapshot = await _collection.get();
    print(querySnapshot);
    return querySnapshot.docs
        .map((doc) => RecipeFolder.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Fetch a folder by ID
  Future<RecipeFolder?> getFolderById(String id) async {
    final doc = await _collection.doc(id).get();
    if (doc.exists) {
      return RecipeFolder.fromJson(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  // Delete a folder
  Future<void> deleteFolder(String id) async {
    await _collection.doc(id).delete();
  }
}
