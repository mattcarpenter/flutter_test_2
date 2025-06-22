# Household Management Implementation Plan

## Executive Summary

This document provides a comprehensive implementation plan for the household management feature based on the architecture requirements in `household_management_architecture.md`. The implementation follows a phased approach covering database schema design, API endpoints, frontend architecture, and security considerations.

## Phase 1: Database Schema Design

### New Tables Required

#### 1. Household Invites Table (household_invites)
```sql
-- New table for managing household invitations
CREATE TABLE household_invites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
    invited_by_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    invite_code UUID NOT NULL DEFAULT gen_random_uuid(),
    email TEXT,  -- nullable for code-based invites
    display_name TEXT NOT NULL,
    invite_type TEXT NOT NULL CHECK (invite_type IN ('email', 'code')),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined', 'revoked')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_sent_at TIMESTAMPTZ,  -- for email resend throttling
    expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '7 days'),
    accepted_at TIMESTAMPTZ,
    accepted_by_user_id UUID REFERENCES auth.users(id)
);

-- Indexes for performance
CREATE INDEX idx_household_invites_household_id ON household_invites(household_id);
CREATE INDEX idx_household_invites_email ON household_invites(email);
CREATE INDEX idx_household_invites_code ON household_invites(invite_code);
CREATE INDEX idx_household_invites_status ON household_invites(status);
```

#### 2. Enhanced Household Members Table
```sql
-- Add role column to existing household_members table
ALTER TABLE household_members ADD COLUMN role TEXT NOT NULL DEFAULT 'member' 
    CHECK (role IN ('owner', 'admin', 'member'));
ADD COLUMN joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
```

### PowerSync Schema Updates

```dart
// Add to schema.dart
class HouseholdInvites extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4()).unique()();
  TextColumn get householdId => text()();
  TextColumn get invitedByUserId => text()();
  TextColumn get inviteCode => text()();
  TextColumn get email => text().nullable()();
  TextColumn get displayName => text()();
  TextColumn get inviteType => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get lastSentAt => integer().nullable()();
  IntColumn get expiresAt => integer()();
  IntColumn get acceptedAt => integer().nullable()();
  TextColumn get acceptedByUserId => text().nullable()();
}
```

### Drift Models Required

```dart
// lib/database/models/household_invites.dart
@DataClassName('HouseholdInviteEntry')
class HouseholdInvites extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4()).unique()();
  TextColumn get householdId => text()();
  TextColumn get invitedByUserId => text()();
  TextColumn get inviteCode => text()();
  TextColumn get email => text().nullable()();
  TextColumn get displayName => text()();
  TextColumn get inviteType => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get lastSentAt => integer().nullable()();
  IntColumn get expiresAt => integer()();
  IntColumn get acceptedAt => integer().nullable()();
  TextColumn get acceptedByUserId => text().nullable()();
}

// Enhanced household_members.dart
@DataClassName('HouseholdMemberEntry')
class HouseholdMembers extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4()).unique()();
  TextColumn get householdId => text()();
  TextColumn get userId => text()();
  IntColumn get isActive => integer().withDefault(const Constant(1))();
  TextColumn get role => text().withDefault(const Constant('member'))();
  IntColumn get joinedAt => integer()();

  @override
  Set<Column> get primaryKey => {householdId, userId};
}
```

## Phase 2: API Endpoints Design

### Backend Service Architecture

#### 1. Controller Layer - HouseholdController
```typescript
// /src/controllers/householdController.ts
export class HouseholdController {
  async createInvite(req: Request, res: Response): Promise<void>
  async resendInvite(req: Request, res: Response): Promise<void>
  async revokeInvite(req: Request, res: Response): Promise<void>
  async acceptInvite(req: Request, res: Response): Promise<void>
  async declineInvite(req: Request, res: Response): Promise<void>
  async removeMember(req: Request, res: Response): Promise<void>
  async leaveHousehold(req: Request, res: Response): Promise<void>
  async transferOwnership(req: Request, res: Response): Promise<void>
}
```

#### 2. Service Layer - HouseholdService
```typescript
// /src/services/householdService.ts
export class HouseholdService {
  async createEmailInvite(householdId: string, email: string, invitedBy: string): Promise<HouseholdInvite>
  async createCodeInvite(householdId: string, displayName: string, invitedBy: string): Promise<HouseholdInvite>
  async sendInviteEmail(invite: HouseholdInvite): Promise<void>
  async validateInvite(inviteCode: string): Promise<HouseholdInvite>
  async acceptInvite(inviteCode: string, userId: string): Promise<void>
  async declineInvite(inviteCode: string, userId: string): Promise<void>
  async removeMember(householdId: string, memberId: string): Promise<void>
  async leaveHousehold(userId: string, householdId: string, newOwnerId?: string): Promise<void>
}
```

#### 3. API Routes
```typescript
// /src/routes/householdRoutes.ts
router.post('/invites', authenticateUser, createInvite);
router.post('/invites/:inviteId/resend', authenticateUser, resendInvite);
router.delete('/invites/:inviteId', authenticateUser, revokeInvite);
router.post('/invites/:inviteCode/accept', authenticateUser, acceptInvite);
router.post('/invites/:inviteCode/decline', authenticateUser, declineInvite);
router.delete('/members/:memberId', authenticateUser, removeMember);
router.post('/leave', authenticateUser, leaveHousehold);
router.post('/transfer-ownership', authenticateUser, transferOwnership);
```

## Phase 3: Frontend Architecture

### Repository Layer Extensions

#### 1. Enhanced HouseholdRepository
```dart
// lib/src/repositories/household_repository.dart
class HouseholdRepository {
  // Existing methods...
  
  // New invitation methods
  Stream<List<HouseholdInviteEntry>> watchHouseholdInvites(String householdId);
  Stream<List<HouseholdInviteEntry>> watchUserInvites(String userId);
  
  // Member management
  Stream<List<HouseholdMemberEntry>> watchHouseholdMembers(String householdId);
  Future<HouseholdMemberEntry?> getCurrentUserMembership(String userId);
  Future<bool> isHouseholdOwner(String userId, String householdId);
}
```

#### 2. New HouseholdInviteRepository
```dart
// lib/src/repositories/household_invite_repository.dart
class HouseholdInviteRepository {
  Future<void> createEmailInvite(String householdId, String email);
  Future<void> createCodeInvite(String householdId, String displayName);
  Future<void> acceptInvite(String inviteCode);
  Future<void> declineInvite(String inviteCode);
  Future<void> revokeInvite(String inviteId);
  Future<void> resendInvite(String inviteId);
}
```

### Service Layer

#### 1. HouseholdManagementService
```dart
// lib/src/services/household_management_service.dart
class HouseholdManagementService {
  final String apiBaseUrl;
  
  Future<void> createEmailInvite(String householdId, String email);
  Future<void> createCodeInvite(String householdId, String displayName);
  Future<void> resendInvite(String inviteId);
  Future<void> revokeInvite(String inviteId);
  Future<void> acceptInvite(String inviteCode);
  Future<void> declineInvite(String inviteCode);
  Future<void> removeMember(String memberId);
  Future<void> leaveHousehold(String householdId, String? newOwnerId);
}
```

### Provider Layer

#### 1. Enhanced HouseholdProvider
```dart
// lib/src/providers/household_provider.dart
class HouseholdProvider extends StateNotifier<HouseholdState> {
  // Current household management
  Future<void> createHousehold(String name);
  Future<void> leaveHousehold(String? newOwnerId);
  
  // Invitation management
  Future<void> createEmailInvite(String email);
  Future<void> createCodeInvite(String displayName);
  Future<void> resendInvite(String inviteId);
  Future<void> revokeInvite(String inviteId);
  
  // Member management
  Future<void> removeMember(String memberId);
  Future<void> acceptInvite(String inviteCode);
  Future<void> declineInvite(String inviteCode);
}
```

#### 2. New State Classes
```dart
// State management classes
class HouseholdState {
  final HouseholdEntry? currentHousehold;
  final List<HouseholdMemberEntry> members;
  final List<HouseholdInviteEntry> invites;
  final List<HouseholdInviteEntry> userInvites;
  final bool isLoading;
  final String? error;
}
```

### UI Layer

#### 1. New Page - HouseholdSharingPage
```dart
// lib/src/features/household/views/household_sharing_page.dart
class HouseholdSharingPage extends ConsumerWidget {
  // Progressive disclosure:
  // - No household: Show Create/Join buttons
  // - Has household: Show members section + invite button + leave button
  // - Has pending invite: Show invite details + accept/decline
}
```

#### 2. Modal Components
```dart
// lib/src/features/household/widgets/
- create_invite_modal.dart (segmented control: email vs code)
- leave_household_modal.dart (owner selection dropdown)
- remove_member_modal.dart (confirmation)
- invite_details_modal.dart (pending invite view)
```

#### 3. Menu Integration
```dart
// Update lib/src/widgets/menu/menu.dart
MenuItem(
  title: 'Household Sharing',
  icon: CupertinoIcons.person_2,
  onTap: (_) => onRouteGo('/household'),
),
```

## Phase 4: Security & RLS Policies

### Row Level Security Policies
```sql
-- Household invites read-only policy
CREATE POLICY "Users can view invites for households they own or are invited to"
ON household_invites FOR SELECT
USING (
  invited_by_user_id = auth.uid() OR 
  email = auth.email() OR
  accepted_by_user_id = auth.uid()
);

-- Prevent direct insert/update on invites (API only)
CREATE POLICY "Block direct invite modifications"
ON household_invites FOR INSERT, UPDATE, DELETE
USING (false);
```

### Backend Authentication
```typescript
// Middleware for request authentication
async function authenticateUser(req: Request, res: Response, next: NextFunction) {
  const token = req.headers.authorization?.replace('Bearer ', '');
  if (!token) {
    return res.status(401).json({ error: 'No token provided' });
  }
  
  const { data: user, error } = await supabase.auth.getUser(token);
  if (error || !user) {
    return res.status(401).json({ error: 'Invalid token' });
  }
  
  req.user = user;
  next();
}
```

## Phase 5: Implementation Sequence

### Sprint 1: Foundation (Week 1)
1. Database schema updates (PostgreSQL + PowerSync)
2. Drift model generation and testing
3. Basic repository layer implementation

### Sprint 2: Backend API (Week 1-2)
1. Household service implementation
2. API endpoints with authentication
3. Email service integration (Amazon SES)
4. Testing with Postman/automated tests

### Sprint 3: Frontend Core (Week 2)
1. Repository and provider layer implementation
2. Service layer for API communication
3. Basic UI components and modals

### Sprint 4: UI Polish & Testing (Week 3)
1. Complete household sharing page
2. Menu integration and routing
3. PowerSync sync rule testing
4. End-to-end testing

### Sprint 5: Edge Cases & Security (Week 3-4)
1. Error handling and edge cases
2. Security audit and penetration testing
3. Performance optimization
4. Documentation and deployment

## Risks & Mitigation

### Technical Risks
1. **PowerSync Sync Issues**: Thorough testing of sync rules and bucket configurations
2. **Email Delivery**: Implement retry logic and delivery status tracking
3. **Invitation Security**: Implement secure code generation and validation

### Business Risks
1. **User Adoption**: Progressive disclosure UX to avoid overwhelming users
2. **Data Conflicts**: Clear ownership rules and conflict resolution UI
3. **Performance**: Pagination for large household member lists

## Success Metrics

1. **Functional**: All user stories from requirements completed
2. **Performance**: Page load times < 2s, API response times < 500ms
3. **Security**: No security vulnerabilities in audit
4. **Quality**: 90%+ code coverage, 0 critical bugs
5. **User Experience**: Intuitive flow with minimal user errors

## Conclusion

This implementation plan provides a comprehensive approach to building the household management feature while maintaining the existing architecture patterns and ensuring security, performance, and user experience standards. The phased approach allows for iterative development and testing while minimizing risks to the existing codebase.