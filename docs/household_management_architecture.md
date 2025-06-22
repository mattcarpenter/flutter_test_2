# Household Management Feature Architecture

## Executive Summary

This document provides comprehensive architectural guidance for implementing household creation and member management features in the recipe app. The analysis covers current data behavior, UX patterns, technical implementation approaches, and critical edge cases around data ownership and migration.

## Current State Analysis

### Data Architecture

The app currently supports household sharing through a dual-ownership model:

- **Personal Data**: `userId=A, householdId=null`
- **Household Data**: `userId=A, householdId=B`
- **Data Access**: Repository methods filter by EXACT match on both parameters

### Critical Discovery: No Automatic Data Migration

**The current implementation does NOT automatically share existing personal data when a user joins a household.** Data is only accessible via household sharing if it was originally created with a specific `householdId`.

### Existing Implementation

#### Database Schema
```sql
-- Households table
households: id (UUID), name (text), user_id (UUID owner)

-- Membership table  
household_members: id (UUID), household_id (FK), user_id (FK), is_active (integer)
-- Primary key: {household_id, user_id}

-- Data tables all follow pattern:
recipes: ..., user_id (UUID), household_id (UUID nullable), ...
```

#### Access Control
- **PowerSync Sync Rules**: Sync data where user is active household member
- **RLS Policies**: `is_household_member(household_id, auth.uid())` function checks active membership
- **Local Filtering**: Repository methods require exact `userId` AND `householdId` match

#### Current Code Assets
- Basic household CRUD: `HouseholdRepository`, `HouseholdNotifier`
- Missing: Household member management, invitation system, data migration

## UX Architecture & Patterns

### Best Practice Patterns

#### 1. Progressive Disclosure Approach
```
Personal Recipes → Create/Join Household → Choose What to Share → Collaborative Mode
```

#### 2. Three-Tier Permission Model
- **View Only**: See household data, cannot edit
- **Member**: View and edit household data, cannot manage members  
- **Admin**: Full control including member management

#### 3. Invitation Flow Patterns
**Pattern A: Email/Code Invitation**
- Household admin generates invitation code/link
- Invitee enters code or follows link
- Preview household contents before joining
- Choose data sharing level during onboarding

**Pattern B: User Search**
- Search by email/username (if privacy allows)
- Send join request
- Approval workflow

### Recommended UX Flow

#### Creating a Household
1. **Trigger**: "Create Household" button in settings/profile
2. **Form**: Household name, optional description
3. **Automatic**: Creator becomes admin, first member
4. **Migration Prompt**: "Share your existing recipes with household?" with selective options

#### Joining a Household  
1. **Invitation Method**: 
   - QR code/link sharing (preferred for families)
   - Email invitation with Supabase auth integration
2. **Preview**: Show household name, member count, sample content
3. **Data Sharing Choice**: 
   - "Keep personal data private"
   - "Share all my recipes" 
   - "Choose what to share" (selective migration)
4. **Welcome Tour**: Highlight household features

#### Managing Members
1. **Member List**: Avatar, name, role, status (pending/active)
2. **Admin Actions**: Promote/demote, remove members
3. **Invitation Management**: Active invitations, resend/revoke
4. **Leave Household**: Clear warning about data implications

### Navigation Integration

#### Settings Integration
```
Settings
├── Account
├── Household ←── New section
│   ├── Overview (name, members, your role)
│   ├── Members (if admin: add/remove, if member: view only)
│   ├── Data Sharing (what you've shared, what others shared)
│   └── Leave Household
└── Privacy
```

#### Recipe Management Integration
- Household filter toggle in recipe list
- "Share with household" option in recipe actions
- Visual indicators for household vs personal recipes

## Technical Implementation Architecture

### Phase 1: Core Infrastructure

#### 1.1 Household Members Repository
```dart
class HouseholdMemberRepository {
  // Core operations
  Future<void> addMember(String householdId, String userId, {bool isActive = true});
  Future<void> removeMember(String householdId, String userId);
  Future<void> updateMemberStatus(String householdId, String userId, bool isActive);
  
  // Queries
  Stream<List<HouseholdMemberEntry>> watchHouseholdMembers(String householdId);
  Future<List<String>> getUserHouseholds(String userId);
  Future<bool> isActiveMember(String householdId, String userId);
}
```

#### 1.2 Invitation System
```dart
class HouseholdInvitation {
  String id;
  String householdId;
  String invitedBy;
  String? invitedEmail;  // Optional: for email-based invites
  String? inviteeUserId; // Set when user accepts
  InvitationStatus status; // pending, accepted, expired, revoked
  DateTime createdAt;
  DateTime? expiresAt;
  String? invitationCode; // For code-based invites
}
```

#### 1.3 Data Migration Service
```dart
class HouseholdDataMigrationService {
  // Share existing personal data with household
  Future<MigrationResult> migrateUserDataToHousehold({
    required String userId,
    required String householdId,
    required DataMigrationOptions options,
  });
  
  // Remove data from household (when leaving)
  Future<MigrationResult> removeUserDataFromHousehold({
    required String userId,
    required String householdId,
    required bool transferOwnership, // to household or delete
  });
}
```

### Phase 2: Data Migration Strategy

#### Migration Options Model
```dart
class DataMigrationOptions {
  bool shareRecipes;
  bool shareFolders;
  bool sharePantryItems;
  bool shareShoppingLists;
  bool shareMealPlans;
  bool shareConverters;
  
  // Selective options
  List<String>? specificRecipeIds;
  List<String>? specificFolderIds;
  // ... etc
}
```

#### Migration Implementation
```dart
Future<MigrationResult> migrateUserDataToHousehold({
  required String userId,
  required String householdId,
  required DataMigrationOptions options,
}) async {
  return await _db.transaction(() async {
    try {
      if (options.shareRecipes) {
        await _migrateRecipes(userId, householdId, options.specificRecipeIds);
      }
      if (options.shareFolders) {
        await _migrateFolders(userId, householdId, options.specificFolderIds);
      }
      // ... continue for each data type
      
      return MigrationResult.success();
    } catch (e) {
      // Transaction will rollback automatically
      return MigrationResult.failure(e.toString());
    }
  });
}

Future<void> _migrateRecipes(String userId, String householdId, List<String>? specificIds) async {
  var query = _db.update(_db.recipes)
    ..where((r) => r.userId.equals(userId))
    ..where((r) => r.householdId.isNull());
  
  if (specificIds != null) {
    query = query..where((r) => r.id.isIn(specificIds));
  }
  
  await query.write(RecipesCompanion(householdId: Value(householdId)));
}
```

### Phase 3: Advanced Features

#### 3.1 Conflict Resolution
When multiple users have similar data (e.g., both have "Chicken Soup" recipe):
1. **Automatic Deduplication**: Compare by title + ingredients similarity
2. **Manual Resolution UI**: Side-by-side comparison with merge options
3. **Keep Both**: Rename conflicting items (e.g., "Chicken Soup (from John)")

#### 3.2 Permission System
```dart
enum HouseholdRole { member, admin, owner }

class HouseholdPermissions {
  static bool canManageMembers(HouseholdRole role) => role == HouseholdRole.admin || role == HouseholdRole.owner;
  static bool canDeleteHousehold(HouseholdRole role) => role == HouseholdRole.owner;
  static bool canEditSharedData(HouseholdRole role) => true; // All members can edit shared data
}
```

## Edge Cases & Data Ownership Scenarios

### Critical Scenarios

#### 1. Household Creator Leaves
**Problem**: Owner of household wants to leave. Who becomes the new owner?

**Solutions**:
- **A. Transfer Ownership**: Must designate another admin before leaving
- **B. Household Dissolution**: All members get prompted to export their contributed data
- **C. Automatic Succession**: Longest-tenured admin becomes owner

**Recommendation**: Option A with fallback to C.

```dart
Future<void> leaveHousehold(String householdId, String userId) async {
  final household = await getHousehold(householdId);
  final leavingMember = await getHouseholdMember(householdId, userId);
  
  if (household.userId == userId) {
    // Owner is leaving
    final otherAdmins = await getHouseholdAdmins(householdId, excludeUserId: userId);
    if (otherAdmins.isEmpty) {
      throw Exception('Cannot leave: Must transfer ownership to another admin first');
    }
    // Transfer to longest-tenured admin
    await transferOwnership(householdId, otherAdmins.first.userId);
  }
  
  // Proceed with data cleanup
  await _handleDataOwnershipOnLeave(householdId, userId);
  await removeMember(householdId, userId);
}
```

#### 2. Data Ownership When Member Leaves
**Question**: If User A shared recipes with household, then leaves, do the recipes stay in household?

**Current Behavior**: Based on RLS policies, User A retains ownership but data becomes inaccessible to household.

**Design Options**:
- **A. Creator Retains**: Data goes back to personal (current behavior)
- **B. Household Retains**: Data ownership transfers to household 
- **C. User Choice**: Prompt during leave flow

**Recommendation**: Option C with clear explanation of implications.

```dart
enum DataOwnershipChoice { 
  keepPersonal,    // Remove householdId, data becomes personal again
  transferToHousehold,  // Transfer ownership to household owner
  deleteFromHousehold   // Remove from household, keep personal copy
}
```

#### 3. Inactive Member Access
**Scenario**: User A is marked `is_active = 0` in household but still has data with that `householdId`.

**Current Behavior**: RLS policies prevent access to household data, but data still has household reference.

**Solution**: Cleanup job or migration when membership status changes.

#### 4. Concurrent Data Modification
**Problem**: Two household members editing same recipe simultaneously.

**Current Protection**: Drift transactions and PowerSync conflict resolution.

**Enhancement**: Optimistic locking with user-friendly conflict resolution UI.

#### 5. User Already in Another Household
**Question**: Can users be in multiple households?

**Current Schema**: Yes, no constraints prevent it.

**Recommendation**: 
- **For families**: Single household model (simpler UX)
- **For power users**: Multiple households with clear switching UI

### Data Consistency Considerations

#### Migration Atomicity
```dart
// All-or-nothing migration
await _db.transaction(() async {
  await _migrateRecipes(userId, householdId, options.specificRecipeIds);
  await _migrateFolders(userId, householdId, options.specificFolderIds);
  await _migratePantryItems(userId, householdId);
  // If any step fails, all changes are rolled back
});
```

#### Sync Race Conditions
**Problem**: User migrates data to household while PowerSync is syncing.

**Solution**: 
1. Disable PowerSync during migration operations
2. Use exclusive locks on affected tables
3. Clear validation after migration completes

## Implementation Roadmap

### Phase 1: Foundation (Week 1-2)
- [ ] HouseholdMemberRepository implementation
- [ ] Basic invitation system (code-based)
- [ ] Household creation/join UI
- [ ] Member list management

### Phase 2: Data Migration (Week 3-4)  
- [ ] Data migration service implementation
- [ ] Selective sharing UI
- [ ] Migration confirmation dialogs
- [ ] Rollback mechanisms

### Phase 3: Advanced UX (Week 5-6)
- [ ] Email invitation integration with Supabase Auth
- [ ] Conflict resolution UI
- [ ] Advanced permission system
- [ ] Leave household flow with data choice

### Phase 4: Polish & Edge Cases (Week 7-8)
- [ ] Ownership transfer flows
- [ ] Inactive member cleanup
- [ ] Migration progress indicators
- [ ] Error handling and recovery

## Risk Mitigation

### Data Loss Prevention
1. **Backup before migration**: Store user data snapshot before household operations
2. **Reversible operations**: All migrations should be undoable within 24-48 hours
3. **Dry-run validation**: Preview migration effects before execution

### User Experience Risks
1. **Confusion about data ownership**: Clear visual indicators and explanations
2. **Accidental data sharing**: Explicit confirmation steps for sensitive operations
3. **Household member conflicts**: Clear roles and permissions communication

### Technical Risks
1. **PowerSync sync conflicts**: Thorough testing of concurrent operations
2. **Database deadlocks**: Careful transaction ordering and timeouts
3. **Partial migration failures**: Robust rollback and recovery mechanisms

## Security Considerations

### Access Control
- RLS policies already provide row-level security
- Additional validation in service layer
- Audit logging for household membership changes

### Privacy
- Users should understand data sharing implications
- Option to export personal data before sharing
- Clear data deletion policies when leaving households

### Authentication
- Leverage Supabase Auth for invitation verification
- Rate limiting on invitation generation
- Invitation expiration and revocation

## Success Metrics

### Technical Metrics
- Migration success rate (target: >99%)
- Operation completion time (target: <5 seconds for typical migrations)
- Zero data loss incidents

### User Experience Metrics
- Household creation completion rate
- Member invitation acceptance rate
- User retention after joining households
- Support ticket volume related to household features

---

## Conclusion

The household management feature requires careful consideration of data ownership, migration strategies, and user experience patterns. The current architecture provides a solid foundation, but requires significant enhancement for production-ready household management.

Key implementation priorities:
1. **Data Migration Safety**: Robust, atomic operations with rollback capability
2. **Clear UX**: Transparent data ownership and sharing implications
3. **Edge Case Handling**: Comprehensive scenarios for member lifecycle events
4. **Performance**: Efficient migration operations that don't impact app responsiveness

The phased approach allows for iterative development while maintaining system stability and user trust.