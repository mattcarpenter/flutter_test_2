# Household Management Frontend Architecture

## Overview

This document outlines the complete frontend architecture for household management features, following the established patterns in the Flutter recipe app. The architecture follows the feature-based organization with clear separation between data, business logic, and presentation layers.

## Directory Structure

```
lib/src/features/household/
├── models/
│   ├── household_invite.dart
│   ├── household_member.dart
│   └── household_state.dart
├── views/
│   ├── household_sharing_page.dart
│   └── invite_details_page.dart
├── widgets/
│   ├── create_invite_modal.dart
│   ├── leave_household_modal.dart
│   ├── remove_member_modal.dart
│   ├── household_member_tile.dart
│   ├── household_invite_tile.dart
│   └── invite_code_display.dart
├── providers/
│   ├── household_provider.dart
│   └── household_invite_provider.dart
├── services/
│   └── household_management_service.dart
└── repositories/
    ├── household_repository.dart
    └── household_invite_repository.dart
```

## Data Models

### 1. Domain Models

```dart
// lib/src/features/household/models/household_invite.dart
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

enum HouseholdInviteType { email, code }
enum HouseholdInviteStatus { pending, accepted, declined, revoked }
```

```dart
// lib/src/features/household/models/household_member.dart
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
  bool get isAdmin => role == HouseholdRole.admin;
  bool get canManageMembers => isOwner || isAdmin;
}

enum HouseholdRole { owner, admin, member }
```

### 2. State Models

```dart
// lib/src/features/household/models/household_state.dart
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
  bool get isOwner => members.any((m) => m.isOwner && m.userId == currentUserId);
  HouseholdMember? get currentUserMembership => 
    members.firstWhereOrNull((m) => m.userId == currentUserId);
}

```

## Repository Layer

### 1. Enhanced Household Repository

```dart
// lib/src/features/household/repositories/household_repository.dart
class HouseholdRepository {
  final AppDatabase _db;

  HouseholdRepository(this._db);

  // Existing methods (from current implementation)
  Stream<List<HouseholdEntry>> watchHouseholds() {
    return _db.select(_db.households).watch();
  }

  Future<int> addHousehold(HouseholdsCompanion household) {
    return _db.into(_db.households).insert(household);
  }

  Future<int> deleteHousehold(String id) {
    return (_db.delete(_db.households)
      ..where((tbl) => tbl.id.equals(id))
    ).go();
  }

  // New methods for household management
  Stream<HouseholdEntry?> watchCurrentUserHousehold(String userId) {
    return (_db.select(_db.households)
      ..join([
        leftOuterJoin(
          _db.householdMembers,
          _db.householdMembers.householdId.equalsExp(_db.households.id),
        )
      ])
      ..where(_db.householdMembers.userId.equals(userId) & 
              _db.householdMembers.isActive.equals(1))
    ).map((row) => row.readTable(_db.households)).watchSingleOrNull();
  }

  Stream<List<HouseholdMember>> watchHouseholdMembers(String householdId) {
    return (_db.select(_db.householdMembers)
      ..where((tbl) => tbl.householdId.equals(householdId) & 
                       tbl.isActive.equals(1))
    ).watch().map((entries) => 
      entries.map((e) => HouseholdMember.fromDrift(e)).toList()
    );
  }

  Future<HouseholdMember?> getCurrentUserMembership(String userId) async {
    final result = await (_db.select(_db.householdMembers)
      ..where((tbl) => tbl.userId.equals(userId) & 
                       tbl.isActive.equals(1))
    ).getSingleOrNull();
    
    return result != null ? HouseholdMember.fromDrift(result) : null;
  }

  Future<bool> isHouseholdOwner(String userId, String householdId) async {
    final result = await (_db.select(_db.householdMembers)
      ..where((tbl) => tbl.userId.equals(userId) & 
                       tbl.householdId.equals(householdId) &
                       tbl.role.equals('owner') &
                       tbl.isActive.equals(1))
    ).getSingleOrNull();
    
    return result != null;
  }

  Future<void> addMember(HouseholdMembersCompanion member) {
    return _db.into(_db.householdMembers).insert(member);
  }

  Future<void> removeMember(String memberId) {
    return (_db.update(_db.householdMembers)
      ..where((tbl) => tbl.id.equals(memberId))
    ).write(HouseholdMembersCompanion(isActive: const Value(0)));
  }

  Future<void> updateMemberRole(String memberId, HouseholdRole role) {
    return (_db.update(_db.householdMembers)
      ..where((tbl) => tbl.id.equals(memberId))
    ).write(HouseholdMembersCompanion(role: Value(role.name)));
  }
}
```

### 2. Household Invite Repository

```dart
// lib/src/features/household/repositories/household_invite_repository.dart
class HouseholdInviteRepository {
  final AppDatabase _db;

  HouseholdInviteRepository(this._db);

  // READ OPERATIONS ONLY - Repository pattern for local database access
  
  Stream<List<HouseholdInvite>> watchHouseholdInvites(String householdId) {
    return (_db.select(_db.householdInvites)
      ..where((tbl) => tbl.householdId.equals(householdId) &
                       tbl.status.equals('pending'))
    ).watch().map((entries) => 
      entries.map((e) => HouseholdInvite.fromDrift(e)).toList()
    );
  }

  Stream<List<HouseholdInvite>> watchUserInvites(String userEmail) {
    // Watch invites for current user's email address
    return (_db.select(_db.householdInvites)
      ..where((tbl) => tbl.email.equals(userEmail) &
                       tbl.status.equals('pending') &
                       tbl.expiresAt.isBiggerThan(
                         Variable(DateTime.now().millisecondsSinceEpoch)
                       ))
    ).watch().map((entries) => 
      entries.map((e) => HouseholdInvite.fromDrift(e)).toList()
    );
  }

  Future<HouseholdInvite?> getInviteByCode(String inviteCode) async {
    final result = await (_db.select(_db.householdInvites)
      ..where((tbl) => tbl.inviteCode.equals(inviteCode) &
                       tbl.status.equals('pending'))
    ).getSingleOrNull();
    
    return result != null ? HouseholdInvite.fromDrift(result) : null;
  }

  Future<List<HouseholdInvite>> getPendingInvitesForHousehold(String householdId) async {
    final results = await (_db.select(_db.householdInvites)
      ..where((tbl) => tbl.householdId.equals(householdId) &
                       tbl.status.equals('pending'))
    ).get();
    
    return results.map((e) => HouseholdInvite.fromDrift(e)).toList();
  }

  // Internal methods for PowerSync updates (not called by UI)
  Future<void> updateInviteStatus(String inviteId, HouseholdInviteStatus status) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (_db.update(_db.householdInvites)
      ..where((tbl) => tbl.id.equals(inviteId))
    ).write(HouseholdInvitesCompanion(
      status: Value(status.name),
      updatedAt: Value(now),
      acceptedAt: status == HouseholdInviteStatus.accepted 
        ? Value(now) 
        : const Value.absent(),
    ));
  }
}
```

## Service Layer

### 1. Household Management Service

```dart
// lib/src/features/household/services/household_management_service.dart
class HouseholdManagementService {
  final String apiBaseUrl;
  final String Function() getAuthToken;

  HouseholdManagementService({
    required this.apiBaseUrl,
    required this.getAuthToken,
  });

  Future<CreateInviteResponse> createEmailInvite(
    String householdId, 
    String email,
  ) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/v1/household/invites'),
      headers: {
        'Authorization': 'Bearer ${getAuthToken()}',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'householdId': householdId,
        'email': email,
        'inviteType': 'email',
      }),
    );

    if (response.statusCode == 201) {
      return CreateInviteResponse.fromJson(json.decode(response.body));
    } else {
      throw HouseholdApiException.fromResponse(response);
    }
  }

  Future<CreateInviteResponse> createCodeInvite(
    String householdId,
    String displayName,
  ) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/v1/household/invites'),
      headers: {
        'Authorization': 'Bearer ${getAuthToken()}',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'householdId': householdId,
        'displayName': displayName,
        'inviteType': 'code',
      }),
    );

    if (response.statusCode == 201) {
      return CreateInviteResponse.fromJson(json.decode(response.body));
    } else {
      throw HouseholdApiException.fromResponse(response);
    }
  }

  Future<void> resendInvite(String inviteId) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/v1/household/invites/$inviteId/resend'),
      headers: {
        'Authorization': 'Bearer ${getAuthToken()}',
      },
    );

    if (response.statusCode != 200) {
      throw HouseholdApiException.fromResponse(response);
    }
  }

  Future<void> revokeInvite(String inviteId) async {
    final response = await http.delete(
      Uri.parse('$apiBaseUrl/v1/household/invites/$inviteId'),
      headers: {
        'Authorization': 'Bearer ${getAuthToken()}',
      },
    );

    if (response.statusCode != 200) {
      throw HouseholdApiException.fromResponse(response);
    }
  }

  Future<AcceptInviteResponse> acceptInvite(String inviteCode) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/v1/household/invites/$inviteCode/accept'),
      headers: {
        'Authorization': 'Bearer ${getAuthToken()}',
      },
    );

    if (response.statusCode == 200) {
      return AcceptInviteResponse.fromJson(json.decode(response.body));
    } else {
      throw HouseholdApiException.fromResponse(response);
    }
  }

  Future<void> declineInvite(String inviteCode) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/v1/household/invites/$inviteCode/decline'),
      headers: {
        'Authorization': 'Bearer ${getAuthToken()}',
      },
    );

    if (response.statusCode != 200) {
      throw HouseholdApiException.fromResponse(response);
    }
  }

  Future<void> removeMember(String memberId) async {
    final response = await http.delete(
      Uri.parse('$apiBaseUrl/v1/household/members/$memberId'),
      headers: {
        'Authorization': 'Bearer ${getAuthToken()}',
      },
    );

    if (response.statusCode != 200) {
      throw HouseholdApiException.fromResponse(response);
    }
  }

  Future<LeaveHouseholdResponse> leaveHousehold(
    String householdId, {
    String? newOwnerId,
  }) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/v1/household/leave'),
      headers: {
        'Authorization': 'Bearer ${getAuthToken()}',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'householdId': householdId,
        if (newOwnerId != null) 'newOwnerId': newOwnerId,
      }),
    );

    if (response.statusCode == 200) {
      return LeaveHouseholdResponse.fromJson(json.decode(response.body));
    } else {
      throw HouseholdApiException.fromResponse(response);
    }
  }
}

// API Response Models
class CreateInviteResponse {
  final HouseholdInvite invite;
  final String? inviteUrl;

  CreateInviteResponse({required this.invite, this.inviteUrl});

  factory CreateInviteResponse.fromJson(Map<String, dynamic> json) {
    return CreateInviteResponse(
      invite: HouseholdInvite.fromJson(json['invite']),
      inviteUrl: json['inviteUrl'],
    );
  }
}

class AcceptInviteResponse {
  final bool success;
  final HouseholdEntry household;
  final HouseholdMember membership;

  AcceptInviteResponse({
    required this.success,
    required this.household,
    required this.membership,
  });

  factory AcceptInviteResponse.fromJson(Map<String, dynamic> json) {
    return AcceptInviteResponse(
      success: json['success'],
      household: HouseholdEntry.fromJson(json['household']),
      membership: HouseholdMember.fromJson(json['membership']),
    );
  }
}

class LeaveHouseholdResponse {
  final bool success;
  final String leftAt;
  final bool? ownershipTransferred;

  LeaveHouseholdResponse({
    required this.success,
    required this.leftAt,
    this.ownershipTransferred,
  });

  factory LeaveHouseholdResponse.fromJson(Map<String, dynamic> json) {
    return LeaveHouseholdResponse(
      success: json['success'],
      leftAt: json['leftAt'],
      ownershipTransferred: json['ownershipTransferred'],
    );
  }
}

class HouseholdApiException implements Exception {
  final int statusCode;
  final String message;
  final String? details;

  HouseholdApiException({
    required this.statusCode,
    required this.message,
    this.details,
  });

  factory HouseholdApiException.fromResponse(http.Response response) {
    final body = json.decode(response.body);
    return HouseholdApiException(
      statusCode: response.statusCode,
      message: body['message'] ?? 'Unknown error',
      details: body['details']?.toString(),
    );
  }

  @override
  String toString() => 'HouseholdApiException: $message (HTTP $statusCode)';
}
```

## Provider Layer

### 1. Household Provider

```dart
// lib/src/features/household/providers/household_provider.dart
class HouseholdNotifier extends StateNotifier<HouseholdState> {
  final HouseholdRepository _householdRepository;
  final HouseholdInviteRepository _inviteRepository;
  final HouseholdManagementService _service;
  final String _currentUserId;

  late final StreamSubscription _householdSubscription;
  late final StreamSubscription _membersSubscription;
  late final StreamSubscription _invitesSubscription;
  late final StreamSubscription _userInvitesSubscription;

  HouseholdNotifier({
    required HouseholdRepository householdRepository,
    required HouseholdInviteRepository inviteRepository,
    required HouseholdManagementService service,
    required String currentUserId,
  })  : _householdRepository = householdRepository,
        _inviteRepository = inviteRepository,
        _service = service,
        _currentUserId = currentUserId,
        super(const HouseholdState()) {
    _initializeStreams();
  }

  void _initializeStreams() {
    // Watch current user's household
    _householdSubscription = _householdRepository
        .watchCurrentUserHousehold(_currentUserId)
        .listen((household) {
      state = state.copyWith(currentHousehold: household);
      
      if (household != null) {
        _startWatchingHouseholdData(household.id);
      } else {
        _stopWatchingHouseholdData();
      }
    });

    // Watch user's incoming invites
    _userInvitesSubscription = _inviteRepository
        .watchUserInvites(_currentUserId)
        .listen((invites) {
      state = state.copyWith(incomingInvites: invites);
    });
  }

  void _startWatchingHouseholdData(String householdId) {
    // Watch household members
    _membersSubscription = _householdRepository
        .watchHouseholdMembers(householdId)
        .listen((members) {
      state = state.copyWith(members: members);
    });

    // Watch outgoing invites (only if user is owner/admin)
    _invitesSubscription = _inviteRepository
        .watchHouseholdInvites(householdId)
        .listen((invites) {
      state = state.copyWith(outgoingInvites: invites);
    });
  }

  void _stopWatchingHouseholdData() {
    _membersSubscription.cancel();
    _invitesSubscription.cancel();
    state = state.copyWith(
      members: [],
      outgoingInvites: [],
    );
  }

  // Household operations
  Future<void> createHousehold(String name) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final companion = HouseholdsCompanion.insert(
        name: name,
        userId: _currentUserId,
      );
      await _householdRepository.addHousehold(companion);
      
      // Add creator as owner member
      final memberCompanion = HouseholdMembersCompanion.insert(
        householdId: companion.id.value,
        userId: _currentUserId,
        role: const Value('owner'),
        joinedAt: Value(DateTime.now().millisecondsSinceEpoch),
      );
      await _householdRepository.addMember(memberCompanion);
      
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  // Invitation operations
  Future<String?> createEmailInvite(String email) async {
    if (state.currentHousehold == null) return null;
    
    state = state.copyWith(isCreatingInvite: true, error: null);
    
    try {
      final response = await _service.createEmailInvite(
        state.currentHousehold!.id,
        email,
      );
      return response.invite.id;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    } finally {
      state = state.copyWith(isCreatingInvite: false);
    }
  }

  Future<String?> createCodeInvite(String displayName) async {
    if (state.currentHousehold == null) return null;
    
    state = state.copyWith(isCreatingInvite: true, error: null);
    
    try {
      final response = await _service.createCodeInvite(
        state.currentHousehold!.id,
        displayName,
      );
      return response.inviteUrl; // Return the shareable URL
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    } finally {
      state = state.copyWith(isCreatingInvite: false);
    }
  }

  Future<void> resendInvite(String inviteId) async {
    try {
      await _service.resendInvite(inviteId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> revokeInvite(String inviteId) async {
    try {
      await _service.revokeInvite(inviteId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> acceptInvite(String inviteCode) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _service.acceptInvite(inviteCode);
      // PowerSync will automatically sync household data to the user's device
      
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> declineInvite(String inviteCode) async {
    try {
      await _service.declineInvite(inviteCode);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // Member management
  Future<void> removeMember(String memberId) async {
    try {
      await _service.removeMember(memberId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> leaveHousehold({String? newOwnerId}) async {
    if (state.currentHousehold == null) return;
    
    state = state.copyWith(isLeavingHousehold: true, error: null);
    
    try {
      await _service.leaveHousehold(
        state.currentHousehold!.id,
        newOwnerId: newOwnerId,
      );
      // PowerSync will automatically remove household data access
      
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isLeavingHousehold: false);
    }
  }

  @override
  void dispose() {
    _householdSubscription.cancel();
    _membersSubscription.cancel();
    _invitesSubscription.cancel();
    _userInvitesSubscription.cancel();
    super.dispose();
  }
}

// Provider definitions
final householdNotifierProvider = StateNotifierProvider<HouseholdNotifier, HouseholdState>((ref) {
  final householdRepo = ref.watch(householdRepositoryProvider);
  final inviteRepo = ref.watch(householdInviteRepositoryProvider);
  final service = ref.watch(householdManagementServiceProvider);
  final currentUserId = ref.watch(currentUserProvider).id;
  
  return HouseholdNotifier(
    householdRepository: householdRepo,
    inviteRepository: inviteRepo,
    service: service,
    currentUserId: currentUserId,
  );
});

final householdRepositoryProvider = Provider<HouseholdRepository>((ref) {
  return HouseholdRepository(appDb);
});

final householdInviteRepositoryProvider = Provider<HouseholdInviteRepository>((ref) {
  return HouseholdInviteRepository(appDb);
});

final householdManagementServiceProvider = Provider<HouseholdManagementService>((ref) {
  return HouseholdManagementService(
    apiBaseUrl: AppConfig.ingredientApiUrl, // Reuse existing API base URL
    getAuthToken: () => ref.read(authProvider).currentUser?.accessToken ?? '',
  );
});
```

## UI Layer

### 1. Main Household Sharing Page

```dart
// lib/src/features/household/views/household_sharing_page.dart
class HouseholdSharingPage extends ConsumerWidget {
  const HouseholdSharingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final householdState = ref.watch(householdNotifierProvider);
    
    return AdaptiveSliverPage(
      title: 'Household Sharing',
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildContent(context, ref, householdState),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, HouseholdState state) {
    // Progressive disclosure based on state
    if (state.hasPendingInvites) {
      return _buildPendingInvitesSection(context, ref, state);
    } else if (state.hasHousehold) {
      return _buildHouseholdManagementSection(context, ref, state);
    } else {
      return _buildCreateJoinSection(context, ref);
    }
  }

  Widget _buildPendingInvitesSection(BuildContext context, WidgetRef ref, HouseholdState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Household Invitations',
          style: CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle,
        ),
        const SizedBox(height: 16),
        ...state.incomingInvites.map((invite) => HouseholdInviteTile(
          invite: invite,
          onAccept: () => ref.read(householdNotifierProvider.notifier)
              .acceptInvite(invite.inviteCode),
          onDecline: () => ref.read(householdNotifierProvider.notifier)
              .declineInvite(invite.inviteCode),
        )),
      ],
    );
  }

  Widget _buildHouseholdManagementSection(BuildContext context, WidgetRef ref, HouseholdState state) {
    final isOwner = state.currentUserMembership?.isOwner ?? false;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Household info section
        _buildHouseholdInfoSection(context, state),
        const SizedBox(height: 24),
        
        // Members section
        _buildMembersSection(context, ref, state),
        const SizedBox(height: 24),
        
        // Invites section (owners/admins only)
        if (state.currentUserMembership?.canManageMembers ?? false) ...[
          _buildInvitesSection(context, ref, state),
          const SizedBox(height: 24),
        ],
        
        // Actions section
        _buildActionsSection(context, ref, state),
      ],
    );
  }

  Widget _buildCreateJoinSection(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        CupertinoButton.filled(
          child: const Text('Create Household'),
          onPressed: () => _showCreateHouseholdModal(context, ref),
        ),
        const SizedBox(height: 16),
        CupertinoButton(
          child: const Text('Join with Code'),
          onPressed: () => _showJoinWithCodeModal(context, ref),
        ),
      ],
    );
  }

  // Modal methods
  void _showCreateHouseholdModal(BuildContext context, WidgetRef ref) {
    showCupertinoModalBottomSheet(
      context: context,
      builder: (context) => const CreateHouseholdModal(),
    );
  }

  void _showJoinWithCodeModal(BuildContext context, WidgetRef ref) {
    showCupertinoModalBottomSheet(
      context: context,
      builder: (context) => const JoinWithCodeModal(),
    );
  }
}
```

This architecture provides a comprehensive, scalable foundation for the household management feature that follows established patterns in the app while introducing the necessary new functionality for collaborative household management.

## Integration Points

### 1. Menu Integration
- Add "Household Sharing" option to the existing Menu widget
- Add route configuration in the main router

### 2. Auth Integration
- Use existing Supabase auth for API authentication
- Integrate with current user provider for user ID access

### 3. Notification Integration
- Show snackbars/toasts for operation feedback
- Display loading states during API operations

### 4. Error Handling
- Consistent error display patterns
- Graceful degradation for network issues
- User-friendly error messages

This architecture ensures maintainable, testable code that integrates seamlessly with the existing app structure while providing all the functionality outlined in the requirements document.