import '../../../../database/database.dart';

enum HouseholdRole { owner, member }

class HouseholdMember {
  final String id;
  final String householdId;
  final String userId;
  final HouseholdRole role;
  final bool isActive;
  final DateTime joinedAt;
  final String? userName; // from user profile lookup
  final String? userEmail; // from user profile lookup

  const HouseholdMember({
    required this.id,
    required this.householdId,
    required this.userId,
    required this.role,
    required this.isActive,
    required this.joinedAt,
    this.userName,
    this.userEmail,
  });

  factory HouseholdMember.fromDrift(HouseholdMemberEntry entry) {
    return HouseholdMember(
      id: entry.id,
      householdId: entry.householdId,
      userId: entry.userId,
      role: HouseholdRole.values.firstWhere(
        (e) => e.name == entry.role,
      ),
      isActive: entry.isActive == 1,
      joinedAt: DateTime.fromMillisecondsSinceEpoch(entry.joinedAt),
    );
  }

  bool get isOwner => role == HouseholdRole.owner;
  bool get canManageMembers => isOwner;

  HouseholdMember copyWith({
    String? id,
    String? householdId,
    String? userId,
    HouseholdRole? role,
    bool? isActive,
    DateTime? joinedAt,
    String? userName,
    String? userEmail,
  }) {
    return HouseholdMember(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      joinedAt: joinedAt ?? this.joinedAt,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
    );
  }
}