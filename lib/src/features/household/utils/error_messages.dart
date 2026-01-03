import '../../../localization/app_localizations.dart';

class HouseholdErrorMessages {
  static String getDisplayMessage(String error, AppLocalizations l10n) {
    // Handle common API errors
    if (error.contains('404') || error.contains('Invalid invitation ID')) {
      return l10n.householdErrorInviteNotFound;
    }

    if (error.contains('403') || error.contains('Permission denied')) {
      return l10n.householdErrorPermissionDenied;
    }

    if (error.contains('already a member')) {
      return l10n.householdErrorAlreadyMember;
    }

    if (error.contains('already has a household')) {
      return l10n.householdErrorAlreadyHasHousehold;
    }

    if (error.contains('expired')) {
      return l10n.householdErrorInviteExpired;
    }

    if (error.contains('network') || error.contains('Failed host lookup')) {
      return l10n.householdErrorNetwork;
    }

    if (error.contains('timeout')) {
      return l10n.householdErrorTimeout;
    }

    // Default message
    return l10n.householdErrorGeneric;
  }
}
