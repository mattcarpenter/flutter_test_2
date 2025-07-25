import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../database/database.dart';
import '../../database/powersync.dart';
import '../repositories/household_repository.dart';
import '../repositories/household_invite_repository.dart';
import '../services/household_management_service.dart';
import '../features/household/models/household_state.dart';
import '../features/household/models/household_member.dart';
import '../features/household/models/household_invite.dart';

class HouseholdNotifier extends StateNotifier<HouseholdState> {
  final HouseholdRepository _householdRepository;
  final HouseholdInviteRepository _inviteRepository;
  final HouseholdManagementService _service;
  final String _currentUserId;
  final String? _currentUserEmail;
  final Ref _ref;

  late final StreamSubscription _householdSubscription;
  StreamSubscription? _membersSubscription;
  StreamSubscription? _invitesSubscription;
  late final StreamSubscription _userInvitesSubscription;

  HouseholdNotifier({
    required HouseholdRepository householdRepository,
    required HouseholdInviteRepository inviteRepository,
    required HouseholdManagementService service,
    required String currentUserId,
    String? currentUserEmail,
    required Ref ref,
  })  : _householdRepository = householdRepository,
        _inviteRepository = inviteRepository,
        _service = service,
        _currentUserId = currentUserId,
        _currentUserEmail = currentUserEmail,
        _ref = ref,
        super(const HouseholdState()) {
    _initializeStreams();
  }

  void _initializeStreams() {
    // Watch current user's household
    _householdSubscription = _householdRepository
        .watchCurrentUserHousehold(_currentUserId)
        .listen((household) {
      print('HOUSEHOLD DEBUG: Stream emitted household: ${household?.name} (id: ${household?.id})');
      state = state.copyWith(currentHousehold: household);
      
      if (household != null) {
        print('HOUSEHOLD DEBUG: Starting to watch household data for: ${household.id}');
        _startWatchingHouseholdData(household.id);
      } else {
        print('HOUSEHOLD DEBUG: No household found, stopping watch');
        _stopWatchingHouseholdData();
      }
    });

    // Watch user's incoming invites by email
    if (_currentUserEmail != null) {
      print('HOUSEHOLD DEBUG: Watching invites for email: $_currentUserEmail');
      _userInvitesSubscription = _inviteRepository
          .watchUserInvites(_currentUserEmail)
          .listen((invites) {
        print('HOUSEHOLD DEBUG: Received ${invites.length} invites from repository:');
        for (var invite in invites) {
          print('  - ID: ${invite.id}');
          print('  - Code: ${invite.inviteCode}');
          print('  - Email: ${invite.email}');
          print('  - Type: ${invite.inviteType}');
          print('  - Status: ${invite.status}');
        }
        state = state.copyWith(
          incomingInvites: invites.map((e) => HouseholdInvite.fromDrift(e)).toList(),
        );
      });
    } else {
      print('HOUSEHOLD DEBUG: No email available, creating empty stream');
      // Create a dummy subscription if no email
      _userInvitesSubscription = Stream<List<HouseholdInviteEntry>>.empty().listen((_) {});
    }
  }

  void _startWatchingHouseholdData(String householdId) {
    // Watch household members
    _membersSubscription = _householdRepository
        .watchHouseholdMembers(householdId)
        .listen((members) {
      state = state.copyWith(
        members: members.map((e) => HouseholdMember.fromDrift(e)).toList(),
      );
    });

    // Watch outgoing invites (only if user is owner/admin)
    _invitesSubscription = _inviteRepository
        .watchHouseholdInvites(householdId)
        .listen((invites) {
      state = state.copyWith(
        outgoingInvites: invites.map((e) => HouseholdInvite.fromDrift(e)).toList(),
      );
    });
  }

  void _stopWatchingHouseholdData() {
    _membersSubscription?.cancel();
    _invitesSubscription?.cancel();
    _membersSubscription = null;
    _invitesSubscription = null;
    state = state.copyWith(
      members: [],
      outgoingInvites: [],
    );
  }

  // Household operations
  Future<void> createHousehold(String name) async {
    state = state.copyWith(isLoading: true);
    
    try {
      // Generate ID explicitly so we can use it for both operations
      final householdId = const Uuid().v4();
      
      final companion = HouseholdsCompanion.insert(
        id: Value(householdId),
        name: name,
        userId: _currentUserId,
      );
      await _householdRepository.addHousehold(companion);
      
      // Add creator as owner member - now we have the ID
      final memberCompanion = HouseholdMembersCompanion.insert(
        householdId: householdId,
        userId: _currentUserId,
        role: const Value('owner'),
        isActive: const Value(1),
        joinedAt: DateTime.now().millisecondsSinceEpoch,
      );
      await _householdRepository.addMember(memberCompanion);
      
      // Data migration is now handled automatically by PostgreSQL triggers
      // when the household_members record is inserted above
      
    } catch (e) {
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  // Invitation operations
  Future<String?> createEmailInvite(String email) async {
    if (state.currentHousehold == null) return null;
    
    state = state.copyWith(isCreatingInvite: true);
    
    try {
      final response = await _service.createEmailInvite(
        state.currentHousehold!.id,
        email,
      );
      return response.invite.id;
    } catch (e) {
      rethrow;
    } finally {
      state = state.copyWith(isCreatingInvite: false);
    }
  }

  Future<String?> createCodeInvite(String displayName) async {
    if (state.currentHousehold == null) return null;
    
    state = state.copyWith(isCreatingInvite: true, error: null);
    
    try {
      print('HOUSEHOLD PROVIDER: Creating code invite for: $displayName');
      final response = await _service.createCodeInvite(
        state.currentHousehold!.id,
        displayName,
      );
      print('HOUSEHOLD PROVIDER: Successfully created invite, URL: ${response.inviteUrl}');
      return response.inviteUrl; // Return the shareable URL
    } catch (e) {
      print('HOUSEHOLD PROVIDER: Error creating invite: $e');
      state = state.copyWith(error: e.toString());
      rethrow; // Re-throw so UI can show error dialog
    } finally {
      state = state.copyWith(isCreatingInvite: false);
    }
  }

  Future<void> resendInvite(String inviteId) async {
    try {
      await _service.resendInvite(inviteId);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> revokeInvite(String inviteId) async {
    // Find the invite and mark it as revoking
    final inviteIndex = state.outgoingInvites.indexWhere(
      (invite) => invite.id == inviteId,
    );
    
    if (inviteIndex != -1) {
      final updatedInvites = [...state.outgoingInvites];
      updatedInvites[inviteIndex] = updatedInvites[inviteIndex].copyWith(isRevoking: true);
      state = state.copyWith(outgoingInvites: updatedInvites);
    }
    
    try {
      await _service.revokeInvite(inviteId);
      // PowerSync will automatically update the invite status and remove it from the list
      
    } catch (e) {
      // Revert the revoking state on error
      if (inviteIndex != -1) {
        final revertedInvites = [...state.outgoingInvites];
        revertedInvites[inviteIndex] = revertedInvites[inviteIndex].copyWith(isRevoking: false);
        state = state.copyWith(outgoingInvites: revertedInvites);
      }
      rethrow;
    }
  }

  Future<void> acceptInvite(String inviteCode) async {
    print('HOUSEHOLD PROVIDER: Accepting invite with code: $inviteCode');
    
    // Find the invite and mark it as accepting
    final inviteIndex = state.incomingInvites.indexWhere(
      (invite) => invite.inviteCode == inviteCode,
    );
    
    if (inviteIndex != -1) {
      final updatedInvites = [...state.incomingInvites];
      updatedInvites[inviteIndex] = updatedInvites[inviteIndex].copyWith(isAccepting: true);
      state = state.copyWith(incomingInvites: updatedInvites);
    }
    
    try {
      print('HOUSEHOLD PROVIDER: Calling service.acceptInvite...');
      await _service.acceptInvite(inviteCode);
      print('HOUSEHOLD PROVIDER: Successfully accepted invite');
      // PowerSync will automatically sync household data to the user's device
      // The invite will be removed from incomingInvites when PowerSync updates
      
    } catch (e) {
      print('HOUSEHOLD PROVIDER: Error accepting invite: $e');
      // Revert the accepting state on error
      if (inviteIndex != -1) {
        final revertedInvites = [...state.incomingInvites];
        revertedInvites[inviteIndex] = revertedInvites[inviteIndex].copyWith(isAccepting: false);
        state = state.copyWith(incomingInvites: revertedInvites);
      }
      rethrow;
    }
  }

  Future<void> declineInvite(String inviteCode) async {
    try {
      await _service.declineInvite(inviteCode);
    } catch (e) {
      rethrow;
    }
  }

  // Member management
  Future<void> removeMember(String memberId) async {
    try {
      await _service.removeMember(memberId);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> leaveHousehold({String? newOwnerId}) async {
    if (state.currentHousehold == null) return;
    
    state = state.copyWith(isLeavingHousehold: true);
    
    try {
      await _service.leaveHousehold(
        state.currentHousehold!.id,
        newOwnerId: newOwnerId,
      );
      // PowerSync will automatically remove household data access
      
    } catch (e) {
      rethrow;
    } finally {
      state = state.copyWith(isLeavingHousehold: false);
    }
  }
  
  Future<void> deleteHousehold(String householdId) async {
    state = state.copyWith(isLeavingHousehold: true);
    
    try {
      await _service.deleteHousehold(householdId);
      // PowerSync will detect membership removal and trigger data cleanup
      
    } catch (e) {
      rethrow;
    } finally {
      state = state.copyWith(isLeavingHousehold: false);
    }
  }

  @override
  void dispose() {
    _householdSubscription.cancel();
    _membersSubscription?.cancel();
    _invitesSubscription?.cancel();
    _userInvitesSubscription.cancel();
    super.dispose();
  }
}

// Provider definitions
final householdNotifierProvider = StateNotifierProvider<HouseholdNotifier, HouseholdState>((ref) {
  final householdRepo = ref.watch(householdRepositoryProvider);
  final inviteRepo = ref.watch(householdInviteRepositoryProvider);
  final service = ref.watch(householdManagementServiceProvider);
  // Get current user info from Supabase auth
  final currentUser = Supabase.instance.client.auth.currentSession?.user;
  
  if (currentUser == null) {
    throw StateError('User must be authenticated to access household features');
  }
  
  return HouseholdNotifier(
    householdRepository: householdRepo,
    inviteRepository: inviteRepo,
    service: service,
    currentUserId: currentUser.id,
    currentUserEmail: currentUser.email,
    ref: ref,
  );
});

final householdRepositoryProvider = Provider<HouseholdRepository>((ref) {
  return HouseholdRepository(appDb);
});
