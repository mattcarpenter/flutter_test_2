import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase_flutter;

import '../../../providers/recipe_tag_provider.dart';
import '../../../../database/database.dart';

/// Represents a temporary tag created during the modal session
class TemporaryTag {
  final String id;
  final String name;
  final String color;
  
  TemporaryTag({
    required this.id,
    required this.name,
    required this.color,
  });
  
  /// Convert to RecipeTagEntry for display purposes
  RecipeTagEntry toRecipeTagEntry() {
    return RecipeTagEntry(
      id: id,
      name: name,
      color: color,
      userId: supabase_flutter.Supabase.instance.client.auth.currentUser?.id ?? '',
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
  }
}

/// ViewModel for managing tag selection state across modal pages
class TagSelectionViewModel extends ChangeNotifier {
  final WidgetRef ref;
  final List<String> initialTagIds;
  final ValueChanged<List<String>> onTagIdsChanged;
  
  late Set<String> _selectedTagIds;
  final List<TemporaryTag> _temporaryTags = [];
  String? _errorMessage;
  
  TagSelectionViewModel({
    required this.ref,
    required this.initialTagIds,
    required this.onTagIdsChanged,
  }) {
    _selectedTagIds = Set<String>.from(initialTagIds);
  }
  
  // Getters
  Set<String> get selectedTagIds => _selectedTagIds;
  List<TemporaryTag> get temporaryTags => _temporaryTags;
  String? get errorMessage => _errorMessage;
  
  /// Get all tags (existing + temporary) for display
  List<RecipeTagEntry> getAllDisplayTags() {
    final existingTagsAsync = ref.read(recipeTagNotifierProvider);
    final existingTags = existingTagsAsync.value ?? <RecipeTagEntry>[];
    
    // Combine existing tags with temporary tags
    final allTags = <RecipeTagEntry>[
      ...existingTags,
      ..._temporaryTags.map((tempTag) => tempTag.toRecipeTagEntry()),
    ];
    
    return allTags;
  }
  
  /// Toggle selection state of a tag
  void toggleTagSelection(String tagId) {
    if (_selectedTagIds.contains(tagId)) {
      _selectedTagIds.remove(tagId);
    } else {
      _selectedTagIds.add(tagId);
    }
    notifyListeners();
  }
  
  /// Check if a tag is selected
  bool isTagSelected(String tagId) {
    return _selectedTagIds.contains(tagId);
  }
  
  /// Create a temporary tag that will be persisted on save
  String createTemporaryTag(String name, String color) {
    // Clear any previous error
    _errorMessage = null;
    
    // Validate tag name - empty names are now handled by disabled button
    if (name.trim().isEmpty) {
      return '';
    }
    
    // Check for duplicates in existing tags
    final existingTags = getAllDisplayTags();
    final duplicateExists = existingTags.any((tag) => 
      tag.name.toLowerCase() == name.trim().toLowerCase());
    
    if (duplicateExists) {
      _errorMessage = 'A tag with this name already exists';
      notifyListeners();
      return '';
    }
    
    // Create temporary tag
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempTag = TemporaryTag(
      id: tempId,
      name: name.trim(),
      color: color,
    );
    
    _temporaryTags.add(tempTag);
    _selectedTagIds.add(tempId);
    
    notifyListeners();
    return tempId;
  }
  
  /// Remove a temporary tag (if user changes their mind before saving)
  void removeTemporaryTag(String tempId) {
    _temporaryTags.removeWhere((tag) => tag.id == tempId);
    _selectedTagIds.remove(tempId);
    notifyListeners();
  }
  
  /// Clear error message
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }
  
  /// Save all changes - convert temporary tags to real tags and apply selections
  Future<bool> saveAllChanges() async {
    try {
      _errorMessage = null;
      final userId = supabase_flutter.Supabase.instance.client.auth.currentUser?.id;
      
      // Create real tags for all temporary tags
      for (final tempTag in _temporaryTags) {
        final realTagId = await ref.read(recipeTagNotifierProvider.notifier).addTag(
          name: tempTag.name,
          color: tempTag.color,
          userId: userId,
        );
        
        if (realTagId != null) {
          // Replace temporary ID with real ID in selections
          _selectedTagIds.remove(tempTag.id);
          _selectedTagIds.add(realTagId);
        }
      }
      
      // Clear temporary tags after successful creation
      _temporaryTags.clear();
      
      // Notify parent of final tag selections
      onTagIdsChanged(_selectedTagIds.toList());
      
      return true;
    } catch (e) {
      _errorMessage = 'Failed to save tags: $e';
      notifyListeners();
      return false;
    }
  }
  
  /// Cancel all changes - clean up temporary tags
  void cancelAllChanges() {
    _temporaryTags.clear();
    _selectedTagIds = Set<String>.from(initialTagIds);
    _errorMessage = null;
    // Don't notify listeners since modal is closing
  }
}