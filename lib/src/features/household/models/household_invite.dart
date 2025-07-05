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
  final bool isAccepting;
  final bool isRevoking;

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
    this.isAccepting = false,
    this.isRevoking = false,
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
      isAccepting: false,
      isRevoking: false,
    );
  }

  HouseholdInvite copyWith({
    String? id,
    String? householdId,
    String? invitedByUserId,
    String? inviteCode,
    String? email,
    String? displayName,
    HouseholdInviteType? inviteType,
    HouseholdInviteStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastSentAt,
    DateTime? expiresAt,
    DateTime? acceptedAt,
    String? acceptedByUserId,
    bool? isAccepting,
    bool? isRevoking,
  }) {
    return HouseholdInvite(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      invitedByUserId: invitedByUserId ?? this.invitedByUserId,
      inviteCode: inviteCode ?? this.inviteCode,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      inviteType: inviteType ?? this.inviteType,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSentAt: lastSentAt ?? this.lastSentAt,
      expiresAt: expiresAt ?? this.expiresAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      acceptedByUserId: acceptedByUserId ?? this.acceptedByUserId,
      isAccepting: isAccepting ?? this.isAccepting,
      isRevoking: isRevoking ?? this.isRevoking,
    );
  }
}