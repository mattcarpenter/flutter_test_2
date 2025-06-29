import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/household_membership_monitor.dart';
import '../services/household_data_cleanup_service.dart';
import '../repositories/household_repository.dart';
import '../../database/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provider for the HouseholdDataCleanupService
final householdDataCleanupServiceProvider = Provider<HouseholdDataCleanupService>((ref) {
  return HouseholdDataCleanupService(appDb);
});

/// Provider for the HouseholdMembershipMonitor
final householdMembershipMonitorProvider = Provider<HouseholdMembershipMonitor>((ref) {
  final repository = ref.watch(householdRepositoryProvider);
  final cleanupService = ref.watch(householdDataCleanupServiceProvider);
  
  return HouseholdMembershipMonitor(repository, cleanupService);
});

/// Provider that manages the lifecycle of household membership monitoring
final householdMonitoringProvider = Provider<void>((ref) {
  final monitor = ref.watch(householdMembershipMonitorProvider);
  final currentUser = Supabase.instance.client.auth.currentUser;
  
  if (currentUser != null) {
    monitor.startMonitoring(currentUser.id);
  }
  
  // Clean up when provider is disposed
  ref.onDispose(() {
    monitor.dispose();
  });
});