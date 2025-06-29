import 'dart:async';
import 'package:logging/logging.dart';
import '../repositories/household_repository.dart';
import 'household_data_cleanup_service.dart';
import '../../database/database.dart';

class HouseholdMembershipMonitor {
  final HouseholdRepository _repository;
  final HouseholdDataCleanupService _cleanupService;
  final _logger = Logger('HouseholdMembershipMonitor');
  
  StreamSubscription? _subscription;
  Map<String, bool> _previousMemberships = {};
  final _pendingMigrations = <String>{};
  final _pendingCleanups = <String>{};
  
  HouseholdMembershipMonitor(this._repository, this._cleanupService);
  
  /// Start monitoring membership changes for a user
  void startMonitoring(String userId) {
    _logger.info('Starting household membership monitoring for user: $userId');
    
    // Cancel any existing subscription
    _subscription?.cancel();
    
    _subscription = _repository.watchUserMemberships(userId).listen(
      (memberships) {
        _processMembershipChanges(memberships, userId);
      },
      onError: (error) {
        _logger.severe('Error monitoring memberships: $error');
      },
    );
    
    // Check for any pending migrations on startup
    _checkPendingMigrationsOnStartup(userId);
  }
  
  void _processMembershipChanges(List<HouseholdMemberEntry> memberships, String userId) {
    final currentMemberships = Map.fromEntries(
      memberships.map((m) => MapEntry(m.householdId, m.isActive == 1))
    );
    
    for (final entry in currentMemberships.entries) {
      final householdId = entry.key;
      final isActive = entry.value;
      final wasActive = _previousMemberships[householdId] ?? false;
      
      // Detect new household membership
      if (isActive && !wasActive) {
        _handleMembershipAdded(householdId, userId);
      }
      
      // Detect removed household membership
      if (!isActive && wasActive) {
        _handleMembershipRemoved(householdId, userId);
      }
    }
    
    _previousMemberships = currentMemberships;
  }
  
  /// Handle when user joins a household
  Future<void> _handleMembershipAdded(String householdId, String userId) async {
    if (_pendingMigrations.contains(householdId)) return;
    
    _logger.info('Detected new membership for household: $householdId');
    _pendingMigrations.add(householdId);
    
    try {
      await _cleanupService.migrateAllPersonalDataToHousehold(userId, householdId);
      _logger.info('Successfully migrated data to household: $householdId');
    } catch (e) {
      _logger.severe('Migration failed for household $householdId: $e');
      // Will retry on next app launch via startup check
    } finally {
      _pendingMigrations.remove(householdId);
    }
  }
  
  /// Handle when user leaves/removed from household
  Future<void> _handleMembershipRemoved(String householdId, String userId) async {
    if (_pendingCleanups.contains(householdId)) return;
    
    _logger.info('Detected removal from household: $householdId');
    _pendingCleanups.add(householdId);
    
    try {
      await _cleanupService.cleanupDataForHousehold(userId, householdId);
      _logger.info('Successfully cleaned up data for household: $householdId');
    } catch (e) {
      _logger.severe('Cleanup failed for household $householdId: $e');
      // Will retry on next app launch via startup check
    } finally {
      _pendingCleanups.remove(householdId);
    }
  }
  
  /// Check for pending migrations on app startup
  Future<void> _checkPendingMigrationsOnStartup(String userId) async {
    try {
      final memberships = await _repository.getActiveUserMemberships(userId);
      
      for (final membership in memberships) {
        final hasPersonalData = await _cleanupService.hasUnmigratedPersonalData(userId);
        
        if (hasPersonalData) {
          _logger.info('Found unmigrated personal data for active household: ${membership.householdId}');
          await _handleMembershipAdded(membership.householdId, userId);
        }
      }
    } catch (e) {
      _logger.severe('Error checking pending migrations: $e');
    }
  }
  
  /// Manually trigger migration for a specific household (used after household creation)
  Future<void> triggerMigrationForHousehold(String householdId, String userId) async {
    _logger.info('Manually triggering migration for household: $householdId');
    await _handleMembershipAdded(householdId, userId);
  }
  
  void dispose() {
    _subscription?.cancel();
  }
}