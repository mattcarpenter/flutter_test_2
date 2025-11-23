import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase_flutter;

import '../../../providers/recipe_folder_provider.dart';
import '../../../../database/database.dart';

/// Represents a temporary folder created during the modal session
class TemporaryFolder {
  final String id;
  final String name;
  
  TemporaryFolder({
    required this.id,
    required this.name,
  });
  
  /// Convert to RecipeFolderEntry for display purposes
  RecipeFolderEntry toRecipeFolderEntry() {
    return RecipeFolderEntry(
      id: id,
      name: name,
      userId: supabase_flutter.Supabase.instance.client.auth.currentUser?.id ?? '',
      folderType: 0, // Normal folder
      filterLogic: 0, // Default OR logic (not used for normal folders)
    );
  }
}

/// ViewModel for managing folder selection state across modal pages
class FolderSelectionViewModel extends ChangeNotifier {
  final WidgetRef ref;
  final List<String> initialFolderIds;
  final ValueChanged<List<String>> onFolderIdsChanged;
  
  late Set<String> _selectedFolderIds;
  final List<TemporaryFolder> _temporaryFolders = [];
  String? _errorMessage;
  
  FolderSelectionViewModel({
    required this.ref,
    required this.initialFolderIds,
    required this.onFolderIdsChanged,
  }) {
    _selectedFolderIds = Set<String>.from(initialFolderIds);
  }
  
  // Getters
  Set<String> get selectedFolderIds => _selectedFolderIds;
  List<TemporaryFolder> get temporaryFolders => _temporaryFolders;
  String? get errorMessage => _errorMessage;
  
  /// Get all folders (existing + temporary) for display
  /// Filters out smart folders since recipes can only be assigned to normal folders
  List<RecipeFolderEntry> getAllDisplayFolders() {
    final existingFoldersAsync = ref.read(recipeFolderNotifierProvider);
    final existingFolders = existingFoldersAsync.value ?? <RecipeFolderEntry>[];

    // Filter out smart folders (folderType != 0)
    final normalFolders = existingFolders.where((f) => f.folderType == 0).toList();

    // Combine normal folders with temporary folders
    final allFolders = <RecipeFolderEntry>[
      ...normalFolders,
      ..._temporaryFolders.map((tempFolder) => tempFolder.toRecipeFolderEntry()),
    ];

    return allFolders;
  }
  
  /// Toggle selection state of a folder
  void toggleFolderSelection(String folderId) {
    if (_selectedFolderIds.contains(folderId)) {
      _selectedFolderIds.remove(folderId);
    } else {
      _selectedFolderIds.add(folderId);
    }
    notifyListeners();
  }
  
  /// Check if a folder is selected
  bool isFolderSelected(String folderId) {
    return _selectedFolderIds.contains(folderId);
  }
  
  /// Create a temporary folder that will be persisted on save
  String createTemporaryFolder(String name) {
    // Clear any previous error
    _errorMessage = null;
    
    // Validate folder name - empty names are now handled by disabled button
    if (name.trim().isEmpty) {
      return '';
    }
    
    // Check for duplicates in existing folders
    final existingFolders = getAllDisplayFolders();
    final duplicateExists = existingFolders.any((folder) => 
      folder.name.toLowerCase() == name.trim().toLowerCase());
    
    if (duplicateExists) {
      _errorMessage = 'A folder with this name already exists';
      notifyListeners();
      return '';
    }
    
    // Create temporary folder
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempFolder = TemporaryFolder(
      id: tempId,
      name: name.trim(),
    );
    
    _temporaryFolders.add(tempFolder);
    _selectedFolderIds.add(tempId);
    
    notifyListeners();
    return tempId;
  }
  
  /// Remove a temporary folder (if user changes their mind before saving)
  void removeTemporaryFolder(String tempId) {
    _temporaryFolders.removeWhere((folder) => folder.id == tempId);
    _selectedFolderIds.remove(tempId);
    notifyListeners();
  }
  
  /// Clear error message
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }
  
  /// Save all changes - convert temporary folders to real folders and apply selections
  Future<bool> saveAllChanges() async {
    try {
      _errorMessage = null;
      final userId = supabase_flutter.Supabase.instance.client.auth.currentUser?.id;
      
      // Create real folders for all temporary folders
      for (final tempFolder in _temporaryFolders) {
        final realFolderId = await ref.read(recipeFolderNotifierProvider.notifier).addFolder(
          name: tempFolder.name,
          userId: userId,
        );
        
        if (realFolderId != null) {
          // Replace temporary ID with real ID in selections
          _selectedFolderIds.remove(tempFolder.id);
          _selectedFolderIds.add(realFolderId);
        }
      }
      
      // Clear temporary folders after successful creation
      _temporaryFolders.clear();
      
      // Notify parent of final folder selections
      onFolderIdsChanged(_selectedFolderIds.toList());
      
      return true;
    } catch (e) {
      _errorMessage = 'Failed to save folders: $e';
      notifyListeners();
      return false;
    }
  }
  
  /// Cancel all changes - clean up temporary folders
  void cancelAllChanges() {
    _temporaryFolders.clear();
    _selectedFolderIds = Set<String>.from(initialFolderIds);
    _errorMessage = null;
    // Don't notify listeners since modal is closing
  }
}