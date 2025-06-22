# Household Management API Specification

## Overview

This document defines the REST API endpoints for household management functionality, including invitation management and member operations.

## Authentication

All endpoints require Bearer token authentication using Supabase JWT tokens.

```
Authorization: Bearer <supabase-jwt-token>
```

## Base URL

```
https://api.recipeapp.com/v1/household
```

## Data Models

### HouseholdInvite
```typescript
interface HouseholdInvite {
  id: string;
  householdId: string;
  invitedByUserId: string;
  inviteCode: string;
  email?: string;
  displayName: string;
  inviteType: 'email' | 'code';
  status: 'pending' | 'accepted' | 'declined' | 'revoked';
  createdAt: string; // ISO 8601
  updatedAt: string; // ISO 8601
  lastSentAt?: string; // ISO 8601
  expiresAt: string; // ISO 8601
  acceptedAt?: string; // ISO 8601
  acceptedByUserId?: string;
}
```

### HouseholdMember
```typescript
interface HouseholdMember {
  id: string;
  householdId: string;
  userId: string;
  role: 'owner' | 'admin' | 'member';
  isActive: boolean;
  joinedAt: string; // ISO 8601
}
```

### Household
```typescript
interface Household {
  id: string;
  name: string;
  userId: string; // owner
  createdAt: string; // ISO 8601
  updatedAt: string; // ISO 8601
}
```

## API Endpoints

### 1. Create Invitation

Creates a new household invitation (email or code-based).

**Endpoint:** `POST /invites`

**Request Body:**
```typescript
// Email invitation
interface CreateEmailInviteRequest {
  householdId: string;
  email: string;
  inviteType: 'email';
}

// Code invitation  
interface CreateCodeInviteRequest {
  householdId: string;
  displayName: string;
  inviteType: 'code';
}
```

**Response:**
```typescript
interface CreateInviteResponse {
  invite: HouseholdInvite;
  inviteUrl?: string; // for code invites
}
```

**Status Codes:**
- `201` - Invitation created successfully
- `400` - Invalid request data
- `401` - Unauthorized (not authenticated)
- `403` - Forbidden (not household owner/admin)
- `409` - Conflict (user already invited or is member)
- `429` - Too many requests (rate limiting)

**Example:**
```bash
curl -X POST https://api.recipeapp.com/v1/household/invites \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "householdId": "550e8400-e29b-41d4-a716-446655440000",
    "email": "user@example.com",
    "inviteType": "email"
  }'
```

### 2. Resend Invitation

Resends an email invitation (throttled to prevent spam).

**Endpoint:** `POST /invites/{inviteId}/resend`

**Response:**
```typescript
interface ResendInviteResponse {
  success: boolean;
  lastSentAt: string; // ISO 8601
  nextAllowedAt?: string; // ISO 8601 if throttled
}
```

**Status Codes:**
- `200` - Email resent successfully
- `400` - Invalid invite ID or not email type
- `401` - Unauthorized
- `403` - Forbidden (not household owner/admin)
- `404` - Invite not found
- `429` - Too many requests (throttled)

### 3. Revoke Invitation

Revokes a pending invitation.

**Endpoint:** `DELETE /invites/{inviteId}`

**Response:**
```typescript
interface RevokeInviteResponse {
  success: boolean;
  revokedAt: string; // ISO 8601
}
```

**Status Codes:**
- `200` - Invitation revoked successfully
- `401` - Unauthorized
- `403` - Forbidden (not household owner/admin)
- `404` - Invite not found
- `409` - Conflict (invite already accepted/declined)

### 4. Accept Invitation

Accepts a household invitation.

**Endpoint:** `POST /invites/{inviteCode}/accept`

**Response:**
```typescript
interface AcceptInviteResponse {
  success: boolean;
  household: Household;
  membership: HouseholdMember;
}
```

**Status Codes:**
- `200` - Invitation accepted successfully
- `400` - Invalid invite code
- `401` - Unauthorized
- `404` - Invite not found or expired
- `409` - Conflict (user already in household or invite already used)

### 5. Decline Invitation

Declines a household invitation.

**Endpoint:** `POST /invites/{inviteCode}/decline`

**Response:**
```typescript
interface DeclineInviteResponse {
  success: boolean;
  declinedAt: string; // ISO 8601
}
```

**Status Codes:**
- `200` - Invitation declined successfully
- `401` - Unauthorized
- `404` - Invite not found or expired
- `409` - Conflict (invite already used)

### 6. Remove Member

Removes a member from the household.

**Endpoint:** `DELETE /members/{memberId}`

**Response:**
```typescript
interface RemoveMemberResponse {
  success: boolean;
  removedAt: string; // ISO 8601
}
```

**Status Codes:**
- `200` - Member removed successfully
- `401` - Unauthorized
- `403` - Forbidden (not household owner/admin, or trying to remove owner)
- `404` - Member not found
- `409` - Conflict (cannot remove household owner without transfer)

### 7. Leave Household

Allows a member to leave a household. Owner must transfer ownership first.

**Endpoint:** `POST /leave`

**Request Body:**
```typescript
interface LeaveHouseholdRequest {
  householdId: string;
  newOwnerId?: string; // required if current user is owner
}
```

**Response:**
```typescript
interface LeaveHouseholdResponse {
  success: boolean;
  leftAt: string; // ISO 8601
  ownershipTransferred?: boolean;
}
```

**Status Codes:**
- `200` - Left household successfully
- `400` - Invalid request (owner without new owner specified)
- `401` - Unauthorized
- `403` - Forbidden (not a member)
- `404` - Household not found

### 8. Transfer Ownership

Transfers household ownership to another member.

**Endpoint:** `POST /transfer-ownership`

**Request Body:**
```typescript
interface TransferOwnershipRequest {
  householdId: string;
  newOwnerId: string;
}
```

**Response:**
```typescript
interface TransferOwnershipResponse {
  success: boolean;
  transferredAt: string; // ISO 8601
  newOwner: HouseholdMember;
  previousOwner: HouseholdMember;
}
```

**Status Codes:**
- `200` - Ownership transferred successfully
- `400` - Invalid request data
- `401` - Unauthorized
- `403` - Forbidden (not current owner)
- `404` - Household or new owner not found


## Error Handling

All endpoints return consistent error responses:

```typescript
interface ApiError {
  error: string;
  message: string;
  statusCode: number;
  details?: any;
  timestamp: string; // ISO 8601
  requestId: string;
}
```

## Rate Limiting

- Email invitations: 5 per minute per user
- Code invitations: 10 per minute per user
- Resend email: 1 per 15 minutes per invite
- Other operations: 60 per minute per user

Rate limit headers:
```
X-RateLimit-Limit: 5
X-RateLimit-Remaining: 4
X-RateLimit-Reset: 1640995200
```

## Security Considerations

### Input Validation
- All user inputs are sanitized and validated
- Email addresses validated against RFC 5322
- UUIDs validated for proper format
- SQL injection protection through parameterized queries

### Authorization
- JWT token validation on every request
- Household ownership/membership verification
- Resource-level access control (can only modify own households)

### Data Protection
- Invite codes are cryptographically secure UUIDs
- Email addresses are normalized and stored securely
- Audit logging for all sensitive operations

### Rate Limiting
- Prevents spam invitations
- Protects against brute force attacks
- Per-user and per-IP limits

## Data Synchronization

### PowerSync Automatic Sync
When users join or leave households, PowerSync automatically handles data synchronization:

1. **Join Household**: PowerSync sync rules automatically include household data on member devices
2. **Leave Household**: PowerSync removes access to household data from the user's device
3. **Create Data**: New data created with householdId is automatically synced to all members
4. **Personal Data**: Users' existing personal data (householdId = null) remains personal

### No Data Migration Required
- Users start fresh when joining households
- Any new data they create will have the householdId automatically set
- PowerSync handles all synchronization based on membership status
- No complex migration processes needed

## Testing Endpoints

### Health Check
**Endpoint:** `GET /health`

**Response:**
```typescript
interface HealthResponse {
  status: 'healthy' | 'degraded' | 'unhealthy';
  timestamp: string;
  services: {
    database: 'healthy' | 'degraded' | 'unhealthy';
    email: 'healthy' | 'degraded' | 'unhealthy';
    supabase: 'healthy' | 'degraded' | 'unhealthy';
  };
}
```

### Test Authentication
**Endpoint:** `GET /auth-test`

**Response:**
```typescript
interface AuthTestResponse {
  authenticated: boolean;
  user: {
    id: string;
    email: string;
  };
  households: Household[];
}
```

## Implementation Notes

### Email Templates
- Welcome email for new invitations
- Reminder emails for pending invitations
- Confirmation emails for accepted invitations

### Logging
- All API calls logged with request/response
- Sensitive data (emails, tokens) masked in logs
- Error tracking with stack traces

### Monitoring
- API response time metrics
- Error rate monitoring
- Rate limit hit tracking
- Invitation acceptance rates

### Deployment
- Blue-green deployment for zero downtime
- Database migration scripts
- Environment-specific configuration
- Load balancing and auto-scaling