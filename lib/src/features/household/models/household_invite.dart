import '../../../../database/database.dart';

enum HouseholdInviteType { email, code }
enum HouseholdInviteStatus { pending, accepted, declined, revoked }

class HouseholdInvite {
  final String id;
  final String householdId;
  final String invitedByUserId;
  final String inviteCode;
  final String? email;
  final String displayName;
  final HouseholdInviteType inviteType;
  final HouseholdInviteStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastSentAt;
  final DateTime expiresAt;
  final DateTime? acceptedAt;
  final String? acceptedByUserId;

  const HouseholdInvite({
    required this.id,
    required this.householdId,
    required this.invitedByUserId,
    required this.inviteCode,
    this.email,
    required this.displayName,
    required this.inviteType,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.lastSentAt,
    required this.expiresAt,
    this.acceptedAt,
    this.acceptedByUserId,
  });

  factory HouseholdInvite.fromDrift(HouseholdInviteEntry entry) {
    return HouseholdInvite(
      id: entry.id,
      householdId: entry.householdId,
      invitedByUserId: entry.invitedByUserId,
      inviteCode: entry.inviteCode,
      email: entry.email,
      displayName: entry.displayName,
      inviteType: HouseholdInviteType.values.firstWhere(
        (e) => e.name == entry.inviteType,
      ),
      status: HouseholdInviteStatus.values.firstWhere(
        (e) => e.name == entry.status,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(entry.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(entry.updatedAt),
      lastSentAt: entry.lastSentAt != null 
        ? DateTime.fromMillisecondsSinceEpoch(entry.lastSentAt!) 
        : null,
      expiresAt: DateTime.fromMillisecondsSinceEpoch(entry.expiresAt),
      acceptedAt: entry.acceptedAt != null 
        ? DateTime.fromMillisecondsSinceEpoch(entry.acceptedAt!) 
        : null,
      acceptedByUserId: entry.acceptedByUserId,
    );
  }
}