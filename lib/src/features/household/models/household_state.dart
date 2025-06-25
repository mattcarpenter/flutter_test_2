import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../database/database.dart';
import 'household_member.dart';
import 'household_invite.dart';

part 'household_state.freezed.dart';

@freezed
class HouseholdState with _$HouseholdState {
  const factory HouseholdState({
    HouseholdEntry? currentHousehold,
    @Default([]) List<HouseholdMember> members,
    @Default([]) List<HouseholdInvite> outgoingInvites,
    @Default([]) List<HouseholdInvite> incomingInvites,
    @Default(false) bool isLoading,
    String? error,
    @Default(false) bool isCreatingInvite,
    @Default(false) bool isLeavingHousehold,
  }) = _HouseholdState;

  const HouseholdState._();

  bool get hasHousehold => currentHousehold != null;
  bool get hasPendingInvites => incomingInvites.isNotEmpty;
  
  // Helper to get current user's membership
  HouseholdMember? getCurrentUserMembership(String currentUserId) {
    try {
      return members.firstWhere(
        (m) => m.userId == currentUserId,
      );
    } catch (e) {
      return null;
    }
  }
  
  bool isOwner(String currentUserId) {
    final membership = getCurrentUserMembership(currentUserId);
    return membership?.isOwner ?? false;
  }
  
  bool canManageMembers(String currentUserId) {
    final membership = getCurrentUserMembership(currentUserId);
    return membership?.canManageMembers ?? false;
  }
}