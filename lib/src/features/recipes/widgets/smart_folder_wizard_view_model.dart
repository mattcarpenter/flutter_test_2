import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase_flutter;

import '../../../providers/recipe_folder_provider.dart';

/// ViewModel for the Smart Folder creation wizard.
/// Manages state across multiple pages of the wizard.
class SmartFolderWizardViewModel extends ChangeNotifier {
  final WidgetRef ref;

  SmartFolderWizardViewModel({required this.ref});

  // Page 1: Folder type selection
  // 1 = tags, 2 = ingredients
  int? _folderType;
  int? get folderType => _folderType;

  void setFolderType(int type) {
    _folderType = type;
    notifyListeners();
  }

  // Page 2: Configuration
  // For tag-based folders
  final Set<String> _selectedTagNames = {};
  Set<String> get selectedTagNames => _selectedTagNames;

  void toggleTag(String tagName) {
    if (_selectedTagNames.contains(tagName)) {
      _selectedTagNames.remove(tagName);
    } else {
      _selectedTagNames.add(tagName);
    }
    notifyListeners();
  }

  bool isTagSelected(String tagName) => _selectedTagNames.contains(tagName);

  // For ingredient-based folders
  final List<String> _selectedTerms = [];
  List<String> get selectedTerms => List.unmodifiable(_selectedTerms);

  void addTerm(String term) {
    if (!_selectedTerms.contains(term)) {
      _selectedTerms.add(term);
      notifyListeners();
    }
  }

  void removeTerm(String term) {
    _selectedTerms.remove(term);
    notifyListeners();
  }

  bool isTermSelected(String term) => _selectedTerms.contains(term);

  // Match logic: false = Any (OR), true = All (AND)
  bool _matchAll = false;
  bool get matchAll => _matchAll;

  void setMatchAll(bool value) {
    _matchAll = value;
    notifyListeners();
  }

  // Page 3: Folder name
  String _folderName = '';
  String get folderName => _folderName;

  void setFolderName(String name) {
    _folderName = name;
    notifyListeners();
  }

  // Validation
  bool get canProceedFromPage2 {
    if (_folderType == 1) {
      return _selectedTagNames.isNotEmpty;
    } else if (_folderType == 2) {
      return _selectedTerms.isNotEmpty;
    }
    return false;
  }

  bool get canCreate {
    return _folderName.trim().isNotEmpty && canProceedFromPage2;
  }

  // State
  bool _isCreating = false;
  bool get isCreating => _isCreating;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Create the smart folder
  Future<String?> createSmartFolder() async {
    if (!canCreate || _isCreating) return null;

    _isCreating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userId = supabase_flutter.Supabase.instance.client.auth.currentUser?.id;

      await ref.read(recipeFolderNotifierProvider.notifier).addSmartFolder(
        name: _folderName.trim(),
        folderType: _folderType!,
        filterLogic: _matchAll ? 1 : 0,
        tags: _folderType == 1 ? _selectedTagNames.toList() : null,
        terms: _folderType == 2 ? _selectedTerms : null,
        userId: userId,
      );

      _isCreating = false;
      notifyListeners();
      return _folderName.trim();
    } catch (e) {
      _errorMessage = 'Failed to create folder: $e';
      _isCreating = false;
      notifyListeners();
      return null;
    }
  }

  // Reset state
  void reset() {
    _folderType = null;
    _selectedTagNames.clear();
    _selectedTerms.clear();
    _matchAll = false;
    _folderName = '';
    _isCreating = false;
    _errorMessage = null;
    notifyListeners();
  }
}
