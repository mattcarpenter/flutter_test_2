class HouseholdErrorMessages {
  static String getDisplayMessage(String error) {
    // Handle common API errors
    if (error.contains('404') || error.contains('Invalid invitation ID')) {
      return 'The invitation was not found. It may have been cancelled or expired.';
    }
    
    if (error.contains('403') || error.contains('Permission denied')) {
      return 'You don\'t have permission to perform this action.';
    }
    
    if (error.contains('already a member')) {
      return 'You are already a member of this household.';
    }
    
    if (error.contains('already has a household')) {
      return 'You already belong to a household. Please leave your current household first.';
    }
    
    if (error.contains('expired')) {
      return 'This invitation has expired. Please request a new one.';
    }
    
    if (error.contains('network') || error.contains('Failed host lookup')) {
      return 'Network error. Please check your internet connection and try again.';
    }
    
    if (error.contains('timeout')) {
      return 'The request timed out. Please try again.';
    }
    
    // Default message
    return 'Something went wrong. Please try again.';
  }
}