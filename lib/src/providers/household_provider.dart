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

  late final StreamSubscription _householdSubscription;
  StreamSubscription? _membersSubscription;
  StreamSubscription? _invitesSubscription;
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

    // Watch user's incoming invites
    _userInvitesSubscription = _inviteRepository
        .watchUserInvites(_currentUserId)
        .listen((invites) {
      state = state.copyWith(
        incomingInvites: invites.map((e) => HouseholdInvite.fromDrift(e)).toList(),
      );
    });
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
    state = state.copyWith(isLoading: true, error: null);
    
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
      await _service.acceptInvite(inviteCode);
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
  // Get current user ID from Supabase auth
  final currentUserId = Supabase.instance.client.auth.currentSession?.user.id;
  
  if (currentUserId == null) {
    throw StateError('User must be authenticated to access household features');
  }
  
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
